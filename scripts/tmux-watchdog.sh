#!/usr/bin/env bash

# tmux-watchdog.sh
#
# 每 5 分钟由 cron 或 while 循环调用，自动扫描所有 tmux pane，
# 检测到 AI agent（Claude Code / Codex）卡在 rate limit 时发送 "keep going"。
#
# 用法 A（前台循环）: ./tmux-watchdog.sh
# 用法 B（cron）:     */5 * * * * /path/to/tmux-watchdog.sh --once
#
# 可通过环境变量自定义：
# WATCHDOG_INTERVAL=300                          轮询间隔（秒），仅前台循环模式
# WATCHDOG_PROMPT="keep going"                   卡住时发送的内容
# WATCHDOG_LINES=80                              检查 pane 最后多少行
# WATCHDOG_LOG=~/.tmux-watchdog.log              日志路径
# WATCHDOG_SESSION_PATTERN='.*'                  只处理匹配这些 session 名的 pane
# WATCHDOG_DIRECT_AGENT_COMMAND_PATTERN='^(codex|claude|claude-code)$'
#                                               直接以前台命令识别 agent 的模式
# WATCHDOG_WRAPPED_AGENT_COMMAND_PATTERN='^(node)$'
#                                               对 node 包裹的 agent 做二次识别
# WATCHDOG_AGENT_OUTPUT_PATTERN='OpenAI Codex|azure_openai/|Claude Code|claude-code|tab to queue message|context left'
#                                               输出中出现这些特征才认为是 agent pane
# WATCHDOG_READY_PROMPT_PATTERN='^[[:space:]]*[›>][[:space:]]'
#                                               只有出现可输入 prompt 才会发送 keep going
# WATCHDOG_READY_WINDOW_LINES=12                 只在 pane 底部这些可见行里识别 prompt
# WATCHDOG_BUSY_TITLE_PATTERN='^[⠁-⣿][[:space:]]'
#                                               pane 标题命中这个模式时认为 agent 正在工作
# WATCHDOG_COOLDOWN=900                          同一 pane 两次发送间隔（秒）
# WATCHDOG_STATE_DIR=~/.tmux-watchdog-state      冷却状态目录
# WATCHDOG_SEND_SETTLE_SECONDS=2                 发送后等待 UI 刷新的时间

set -euo pipefail

INTERVAL="${WATCHDOG_INTERVAL:-300}"
PROMPT="${WATCHDOG_PROMPT:-keep going}"
LINES_TO_CHECK="${WATCHDOG_LINES:-80}"
LOG_FILE="${WATCHDOG_LOG:-$HOME/.tmux-watchdog.log}"
SESSION_PATTERN="${WATCHDOG_SESSION_PATTERN:-.*}"
DIRECT_AGENT_COMMAND_PATTERN="${WATCHDOG_DIRECT_AGENT_COMMAND_PATTERN:-^(codex|claude|claude-code)$}"
WRAPPED_AGENT_COMMAND_PATTERN="${WATCHDOG_WRAPPED_AGENT_COMMAND_PATTERN:-^(node)$}"
AGENT_OUTPUT_PATTERN="${WATCHDOG_AGENT_OUTPUT_PATTERN:-OpenAI Codex|azure_openai/|Claude Code|claude-code|tab to queue message|context left}"
READY_PROMPT_PATTERN="${WATCHDOG_READY_PROMPT_PATTERN:-^[[:space:]]*[›>][[:space:]]}"
READY_WINDOW_LINES="${WATCHDOG_READY_WINDOW_LINES:-12}"
BUSY_TITLE_PATTERN="${WATCHDOG_BUSY_TITLE_PATTERN:-^[⠁-⣿][[:space:]]}"
COOLDOWN_SECONDS="${WATCHDOG_COOLDOWN:-900}"
STATE_DIR="${WATCHDOG_STATE_DIR:-$HOME/.tmux-watchdog-state}"
SEND_SETTLE_SECONDS="${WATCHDOG_SEND_SETTLE_SECONDS:-2}"

STUCK_PATTERNS=(
  "rate limit"
  "usage limit"
  "rate_limit_error"
  "resets at"
  "overloaded_error"
  "529"
  "too many requests"
  "quota exceeded"
  "server error"
  "timed out"
  "Connection timed out"
  "connection reset"
  "failed: Connection reset by peer"
  "ECONNRESET"
  "socket hang up"
  "API error"
  "stream disconnected before completion"
)

build_pattern() {
  local IFS='|'
  printf '%s' "${STUCK_PATTERNS[*]}"
}

PATTERN="$(build_pattern)"

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

pane_session_name() {
  tmux display-message -p -t "$1" '#{session_name}' 2>/dev/null
}

pane_current_command() {
  tmux display-message -p -t "$1" '#{pane_current_command}' 2>/dev/null
}

pane_title() {
  tmux display-message -p -t "$1" '#{pane_title}' 2>/dev/null
}

capture_recent_output() {
  tmux capture-pane -p -t "$1" -S "-${LINES_TO_CHECK}" 2>/dev/null
}

capture_visible_output() {
  tmux capture-pane -p -t "$1" 2>/dev/null
}

last_visible_prompt_line() {
  local output="$1"
  printf '%s\n' "$output" | tail -n "$READY_WINDOW_LINES" | grep -E -- "$READY_PROMPT_PATTERN" | tail -n 1 || true
}

normalize_prompt_line() {
  sed -E 's/^[[:space:]]*[›>][[:space:]]*//; s/[[:space:]]+$//'
}

prompt_buffer_text() {
  local output="$1"
  local prompt_line

  prompt_line="$(last_visible_prompt_line "$output")"
  [[ -n "$prompt_line" ]] || return 1
  printf '%s\n' "$prompt_line" | normalize_prompt_line
}

matches_session() {
  local pane="$1"
  local session_name

  session_name="$(pane_session_name "$pane")" || return 1
  [[ "$session_name" =~ $SESSION_PATTERN ]]
}

looks_like_agent_pane() {
  local current_command="$1"
  local output="$2"

  if [[ "$current_command" =~ $DIRECT_AGENT_COMMAND_PATTERN ]]; then
    return 0
  fi

  if [[ "$current_command" =~ $WRAPPED_AGENT_COMMAND_PATTERN ]] &&
    printf '%s\n' "$output" | grep -qiE -- "$AGENT_OUTPUT_PATTERN"; then
    return 0
  fi

  return 1
}

prompt_is_still_buffered() {
  local output="$1"
  local prompt_line

  prompt_line="$(last_visible_prompt_line "$output")"
  [[ -n "$prompt_line" ]] || return 1
  [[ "$(printf '%s\n' "$prompt_line" | normalize_prompt_line)" == "$PROMPT" ]]
}

prompt_has_manual_input() {
  local output="$1"
  local prompt_text

  prompt_text="$(prompt_buffer_text "$output")" || return 1
  [[ -n "$prompt_text" && "$prompt_text" != "$PROMPT" ]]
}

has_stuck_pattern() {
  local output="$1"
  printf '%s\n' "$output" | grep -qiE -- "$PATTERN"
}

pane_is_busy() {
  local pane="$1"
  local title

  title="$(pane_title "$pane")" || return 1
  [[ "$title" =~ $BUSY_TITLE_PATTERN ]]
}

pane_state_file() {
  printf '%s/%s.last_sent' "$STATE_DIR" "$(printf '%s' "$1" | tr ':./' '___')"
}

recently_prompted() {
  local pane="$1"
  local state_file last_sent now

  state_file="$(pane_state_file "$pane")"
  [[ -f "$state_file" ]] || return 1
  read -r last_sent < "$state_file" || return 1
  [[ "$last_sent" =~ ^[0-9]+$ ]] || return 1

  now="$(date +%s)"
  (( now - last_sent < COOLDOWN_SECONDS ))
}

mark_prompt_sent() {
  local pane="$1"
  local state_file

  state_file="$(pane_state_file "$pane")"
  mkdir -p "$STATE_DIR"
  date +%s > "$state_file"
}

press_enter() {
  tmux send-keys -t "$1" Enter
}

clear_prompt_buffer() {
  tmux send-keys -t "$1" C-u
}

submit_buffered_prompt() {
  local pane="$1"
  local output_after_send

  press_enter "$pane"
  sleep "$SEND_SETTLE_SECONDS"
  output_after_send="$(capture_visible_output "$pane")" || return 1

  if prompt_is_still_buffered "$output_after_send"; then
    log "WARN: $pane - 补发 Enter 后 prompt 仍停留在输入框"
    return 1
  fi

  return 0
}

send_prompt() {
  local pane="$1"
  local replace_buffer="${2:-false}"
  local output_after_send

  if [[ "$replace_buffer" == "true" ]]; then
    clear_prompt_buffer "$pane"
  fi

  tmux send-keys -t "$pane" -l "$PROMPT"
  press_enter "$pane"

  sleep "$SEND_SETTLE_SECONDS"
  output_after_send="$(capture_visible_output "$pane")" || return 1
  if prompt_is_still_buffered "$output_after_send"; then
    log "RETRY: $pane - prompt 仍停留在输入框，补发一次 Enter"
    if ! submit_buffered_prompt "$pane"; then
      return 1
    fi
  fi

  return 0
}

scan_all_panes() {
  local pane_list
  if ! pane_list="$(tmux list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)"; then
    log "WARN: tmux 未运行或无 session"
    return
  fi

  while IFS= read -r pane; do
    [[ -z "$pane" ]] && continue
    if ! matches_session "$pane"; then
      continue
    fi

    local current_command output visible_output
    current_command="$(pane_current_command "$pane")" || continue
    output="$(capture_recent_output "$pane")" || continue
    visible_output="$(capture_visible_output "$pane")" || continue
    [[ -z "$output" ]] && continue

    if ! looks_like_agent_pane "$current_command" "$output"; then
      continue
    fi

    if prompt_is_still_buffered "$visible_output"; then
      if pane_is_busy "$pane"; then
        log "SKIP: $pane - prompt 已在输入框，但 agent 仍忙"
        continue
      fi

      log "RESUME: $pane - prompt 已在输入框，补发 Enter"
      if submit_buffered_prompt "$pane"; then
        mark_prompt_sent "$pane"
      fi
      continue
    fi

    if has_stuck_pattern "$output"; then
      if recently_prompted "$pane"; then
        log "SKIP: $pane - 冷却中，暂不重复发送"
        continue
      fi

      log "STUCK: $pane - 命中错误，强制发送 \"$PROMPT\""
      if send_prompt "$pane" true; then
        mark_prompt_sent "$pane"
      fi
      continue
    fi

    if prompt_has_manual_input "$visible_output"; then
      log "SKIP: $pane - 输入框已有未提交内容，不注入 watchdog prompt"
      continue
    fi
  done <<< "$pane_list"
}

main() {
  log "=== tmux-watchdog 启动 ==="
  log "    检测间隔: ${INTERVAL}s | 检查行数: ${LINES_TO_CHECK} | prompt: \"${PROMPT}\""
  log "    session 过滤: ${SESSION_PATTERN}"
  log "    直接命令过滤: ${DIRECT_AGENT_COMMAND_PATTERN}"
  log "    包装命令过滤: ${WRAPPED_AGENT_COMMAND_PATTERN}"
  log "    agent 输出特征: ${AGENT_OUTPUT_PATTERN}"
  log "    ready prompt 特征: ${READY_PROMPT_PATTERN}"
  log "    ready prompt 可见窗口: 底部 ${READY_WINDOW_LINES} 行"
  log "    busy title 特征: ${BUSY_TITLE_PATTERN}"
  log "    冷却时间: ${COOLDOWN_SECONDS}s | 状态目录: ${STATE_DIR}"
  log "    发送后等待: ${SEND_SETTLE_SECONDS}s"
  log "    报错 pattern: ${PATTERN}"

  if [[ "${1:-}" == "--once" ]]; then
    scan_all_panes
    return
  fi

  while true; do
    scan_all_panes
    sleep "$INTERVAL"
  done
}

main "$@"
