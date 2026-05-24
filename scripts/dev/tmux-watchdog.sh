#!/usr/bin/env bash

# tmux-watchdog.sh
#
# 默认每 1 分钟在前台循环中自动扫描默认 tmux 和 Agent Deck tmux pane，
# 检测到 AI agent（Claude Code / Codex）卡在 rate limit 时发送 "keep going"。
#
# 用法（从仓库根目录）:
#   ./scripts/dev/tmux-watchdog.sh
#   ./scripts/dev/tmux-watchdog.sh monitor agent-deck
#   ./scripts/dev/tmux-watchdog.sh --agent-deck
#   ./scripts/dev/tmux-watchdog.sh --tmux-socket-name agent-deck
#
# 可通过环境变量自定义：
# WATCHDOG_INTERVAL=60                           轮询间隔（秒），仅前台循环模式
# WATCHDOG_PROMPT="keep going"                   卡住时发送的内容
# WATCHDOG_LINES=80                              检查 pane 最后多少行
# WATCHDOG_LOG=~/.tmux-watchdog.log              日志路径
# WATCHDOG_TMUX_TARGETS='default agent-deck'     默认扫描的 tmux 目标列表
# WATCHDOG_TMUX_SOCKET_NAME=agent-deck           使用 tmux -L 指定 tmux socket 名
# WATCHDOG_TMUX_SOCKET_PATH=/tmp/tmux.sock       使用 tmux -S 指定 tmux socket 路径
# WATCHDOG_AGENT_DECK_TMUX_SOCKET_NAME=agent-deck
#                                               agent-deck 快捷目标对应的 tmux socket 名
# WATCHDOG_SESSION_PATTERN='.*'                  只处理匹配这些 session 名的 pane
# WATCHDOG_DIRECT_AGENT_COMMAND_PATTERN='^(codex|claude|claude-code)$'
#                                               直接以前台命令识别 agent 的模式
# WATCHDOG_WRAPPED_AGENT_COMMAND_PATTERN='^(node)$'
#                                               对 node 包裹的 agent 做二次识别
# WATCHDOG_AGENT_PROCESS_PATTERN='(^|/)(codex|claude|claude-code)([[:space:]]|$)|@openai/codex|claude-code'
#                                               从 pane 进程树识别 agent 的兜底模式
# WATCHDOG_AGENT_OUTPUT_PATTERN='OpenAI Codex|azure_openai/|Claude Code|claude-code|tab to queue message|context left'
#                                               输出中出现这些特征才认为是 agent pane
# WATCHDOG_READY_PROMPT_PATTERN='^[[:space:]]*[›>]([[:space:]].*)?$'
#                                               只有出现可输入 prompt 才会发送 keep going
# WATCHDOG_READY_WINDOW_LINES=12                 只在 pane 底部这些可见行里识别 prompt
# WATCHDOG_STUCK_WINDOW_LINES=20                 只在 pane 底部这些行里识别可续跑错误，避免任务完成后的旧日志误触发
# WATCHDOG_BUSY_TITLE_PATTERN='^[⠁-⣿][[:space:]]'
#                                               pane 标题命中这个模式时认为 agent 正在工作
# WATCHDOG_COOLDOWN=60                           同一 pane 两次发送间隔（秒）
# WATCHDOG_STATE_DIR=~/.tmux-watchdog-state      冷却状态目录
# WATCHDOG_SEND_SETTLE_SECONDS=2                 发送后等待 UI 刷新的时间

set -euo pipefail

INTERVAL="${WATCHDOG_INTERVAL:-60}"
PROMPT="${WATCHDOG_PROMPT:-keep going}"
LINES_TO_CHECK="${WATCHDOG_LINES:-80}"
LOG_FILE="${WATCHDOG_LOG:-$HOME/.tmux-watchdog.log}"
TMUX_TARGETS_TEXT="${WATCHDOG_TMUX_TARGETS:-}"
ENV_TMUX_SOCKET_NAME="${WATCHDOG_TMUX_SOCKET_NAME:-}"
ENV_TMUX_SOCKET_PATH="${WATCHDOG_TMUX_SOCKET_PATH:-}"
TMUX_SOCKET_NAME=""
TMUX_SOCKET_PATH=""
TMUX_TARGET_LABEL="default"
AGENT_DECK_TMUX_SOCKET_NAME="${WATCHDOG_AGENT_DECK_TMUX_SOCKET_NAME:-agent-deck}"
SESSION_PATTERN="${WATCHDOG_SESSION_PATTERN:-.*}"
DIRECT_AGENT_COMMAND_PATTERN="${WATCHDOG_DIRECT_AGENT_COMMAND_PATTERN:-^(codex|claude|claude-code)$}"
WRAPPED_AGENT_COMMAND_PATTERN="${WATCHDOG_WRAPPED_AGENT_COMMAND_PATTERN:-^(node)$}"
AGENT_PROCESS_PATTERN="${WATCHDOG_AGENT_PROCESS_PATTERN:-(^|/)(codex|claude|claude-code)([[:space:]]|$)|@openai/codex|claude-code}"
AGENT_OUTPUT_PATTERN="${WATCHDOG_AGENT_OUTPUT_PATTERN:-OpenAI Codex|azure_openai/|Claude Code|claude-code|tab to queue message|context left}"
READY_PROMPT_PATTERN="${WATCHDOG_READY_PROMPT_PATTERN:-^[[:space:]]*[›>]([[:space:]].*)?$}"
READY_WINDOW_LINES="${WATCHDOG_READY_WINDOW_LINES:-12}"
STUCK_WINDOW_LINES="${WATCHDOG_STUCK_WINDOW_LINES:-20}"
BUSY_TITLE_PATTERN="${WATCHDOG_BUSY_TITLE_PATTERN:-^[⠁-⣿][[:space:]]}"
COOLDOWN_SECONDS="${WATCHDOG_COOLDOWN:-60}"
STATE_DIR="${WATCHDOG_STATE_DIR:-$HOME/.tmux-watchdog-state}"
SEND_SETTLE_SECONDS="${WATCHDOG_SEND_SETTLE_SECONDS:-2}"
SHOW_HELP=false
declare -a TMUX_CMD=(tmux)
declare -a TMUX_TARGETS=()

STUCK_PATTERNS=(
  "rate limit"
  "usage limit"
  "rate_limit_error"
  "resets at"
  "overloaded_error"
  "529"
  "too many requests"
  "quota exceeded"
  "Connection timed out"
  "connection reset"
  "failed: Connection reset by peer"
  "ECONNRESET"
  "socket hang up"
  "Request Error"
  "stream disconnected before completion"
  "prematurely closed"
)

build_pattern() {
  local IFS='|'
  printf '%s' "${STUCK_PATTERNS[*]}"
}

PATTERN="$(build_pattern)"

usage() {
  cat <<EOF
Usage:
  ${0##*/} [monitor] [default|agent-deck|both]
  ${0##*/} [--agent-deck]
  ${0##*/} [--tmux-socket-name NAME]
  ${0##*/} [--tmux-socket-path PATH]

Examples:
  ${0##*/}                         # monitor the default and Agent Deck tmux servers
  ${0##*/} monitor agent-deck       # monitor Agent Deck's tmux -L agent-deck server
  WATCHDOG_TMUX_SOCKET_NAME=agent-deck ${0##*/}
EOF
}

add_tmux_target() {
  local target="$1"
  local existing

  for existing in ${TMUX_TARGETS[@]+"${TMUX_TARGETS[@]}"}; do
    [[ "$existing" == "$target" ]] && return 0
  done

  TMUX_TARGETS+=("$target")
}

add_named_tmux_target() {
  case "$1" in
    default)
      add_tmux_target default
      ;;
    agent-deck)
      add_tmux_target agent-deck
      ;;
    both | all)
      add_tmux_target default
      add_tmux_target agent-deck
      ;;
    *)
      printf 'ERROR: unknown tmux target: %s\n' "$1" >&2
      usage >&2
      return 1
      ;;
  esac
}

parse_tmux_targets_text() {
  local target_text="${1//,/ }"
  local target

  for target in $target_text; do
    add_named_tmux_target "$target" || return 1
  done
}

add_default_tmux_targets() {
  if [[ -n "$ENV_TMUX_SOCKET_NAME" && -n "$ENV_TMUX_SOCKET_PATH" ]]; then
    printf 'ERROR: set only one of WATCHDOG_TMUX_SOCKET_NAME or WATCHDOG_TMUX_SOCKET_PATH.\n' >&2
    return 1
  fi

  if [[ -n "$ENV_TMUX_SOCKET_NAME" ]]; then
    add_tmux_target "name:$ENV_TMUX_SOCKET_NAME"
    return 0
  fi

  if [[ -n "$ENV_TMUX_SOCKET_PATH" ]]; then
    add_tmux_target "path:$ENV_TMUX_SOCKET_PATH"
    return 0
  fi

  if [[ -n "$TMUX_TARGETS_TEXT" ]]; then
    parse_tmux_targets_text "$TMUX_TARGETS_TEXT"
    return $?
  fi

  add_tmux_target default
  add_tmux_target agent-deck
}

configure_tmux_command() {
  local target="${1:-default}"
  local socket_value

  TMUX_CMD=(tmux)
  TMUX_SOCKET_NAME=""
  TMUX_SOCKET_PATH=""
  TMUX_TARGET_LABEL="default"

  case "$target" in
    default)
      return 0
      ;;
    agent-deck)
      TMUX_SOCKET_NAME="$AGENT_DECK_TMUX_SOCKET_NAME"
      TMUX_TARGET_LABEL="agent-deck"
      TMUX_CMD+=(-L "$TMUX_SOCKET_NAME")
      return 0
      ;;
    name:*)
      socket_value="${target#name:}"
      TMUX_SOCKET_NAME="$socket_value"
      if [[ "$socket_value" == "$AGENT_DECK_TMUX_SOCKET_NAME" ]]; then
        TMUX_TARGET_LABEL="agent-deck"
      else
        TMUX_TARGET_LABEL="socket-name:$socket_value"
      fi
      TMUX_CMD+=(-L "$TMUX_SOCKET_NAME")
      return 0
      ;;
    path:*)
      socket_value="${target#path:}"
      TMUX_SOCKET_PATH="$socket_value"
      TMUX_TARGET_LABEL="socket-path:$socket_value"
      TMUX_CMD+=(-S "$TMUX_SOCKET_PATH")
      return 0
      ;;
    *)
      printf 'ERROR: unknown tmux target: %s\n' "$target" >&2
      return 1
      ;;
  esac
}

parse_args() {
  local arg

  SHOW_HELP=false
  TMUX_TARGETS=()

  while (($# > 0)); do
    arg="$1"
    shift

    case "$arg" in
      -h | --help)
        SHOW_HELP=true
        return 0
        ;;
      monitor)
        ;;
      default | agent-deck | both | all)
        add_named_tmux_target "$arg" || return 1
        ;;
      --agent-deck)
        add_named_tmux_target agent-deck || return 1
        ;;
      -L | --tmux-socket-name | --socket-name)
        if (($# == 0)); then
          printf 'ERROR: %s requires a socket name.\n' "$arg" >&2
          usage >&2
          return 1
        fi
        add_tmux_target "name:$1"
        shift
        ;;
      -S | --tmux-socket-path | --socket-path)
        if (($# == 0)); then
          printf 'ERROR: %s requires a socket path.\n' "$arg" >&2
          usage >&2
          return 1
        fi
        add_tmux_target "path:$1"
        shift
        ;;
      *)
        printf 'ERROR: unknown argument: %s\n' "$arg" >&2
        usage >&2
        return 1
        ;;
    esac
  done

  if ((${#TMUX_TARGETS[@]} == 0)); then
    add_default_tmux_targets || return 1
  fi

  if ((${#TMUX_TARGETS[@]} == 0)); then
    printf 'ERROR: no tmux targets configured.\n' >&2
    usage >&2
    return 1
  fi

  configure_tmux_command "${TMUX_TARGETS[0]}"
}

tmux_command_display() {
  local index

  printf '%q' "${TMUX_CMD[0]}"
  for ((index = 1; index < ${#TMUX_CMD[@]}; index++)); do
    printf ' %q' "${TMUX_CMD[$index]}"
  done
}

tmux_targets_display() {
  local index target

  for ((index = 0; index < ${#TMUX_TARGETS[@]}; index++)); do
    target="${TMUX_TARGETS[$index]}"
    configure_tmux_command "$target" || return 1
    ((index > 0)) && printf ', '
    printf '%s' "$(tmux_command_display)"
  done

  if ((${#TMUX_TARGETS[@]} > 0)); then
    configure_tmux_command "${TMUX_TARGETS[0]}" || return 1
  fi
}

tmux_call() {
  "${TMUX_CMD[@]}" "$@"
}

pane_log_label() {
  printf '%s/%s' "$TMUX_TARGET_LABEL" "$1"
}

scan_all_targets() {
  local target

  for target in ${TMUX_TARGETS[@]+"${TMUX_TARGETS[@]}"}; do
    configure_tmux_command "$target" || return 1
    scan_all_panes
  done
}

log() {
  printf '[%s] %s\n' "$(date '+%Y-%m-%d %H:%M:%S')" "$*" | tee -a "$LOG_FILE"
}

pane_session_name() {
  tmux_call display-message -p -t "$1" '#{session_name}' 2>/dev/null
}

pane_current_command() {
  tmux_call display-message -p -t "$1" '#{pane_current_command}' 2>/dev/null
}

pane_pid() {
  tmux_call display-message -p -t "$1" '#{pane_pid}' 2>/dev/null
}

pane_title() {
  tmux_call display-message -p -t "$1" '#{pane_title}' 2>/dev/null
}

capture_recent_output() {
  tmux_call capture-pane -p -t "$1" -S "-${LINES_TO_CHECK}" 2>/dev/null
}

capture_visible_output() {
  tmux_call capture-pane -p -t "$1" 2>/dev/null
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

pane_has_ready_prompt() {
  local output="$1"
  [[ -n "$(last_visible_prompt_line "$output")" ]]
}

matches_session() {
  local pane="$1"
  local session_name

  session_name="$(pane_session_name "$pane")" || return 1
  [[ "$session_name" =~ $SESSION_PATTERN ]]
}

pane_process_snapshot() {
  local pane="$1"
  local root_pid pid child
  local -a queue=()

  root_pid="$(pane_pid "$pane")" || return 1
  [[ "$root_pid" =~ ^[0-9]+$ ]] || return 1

  queue=("$root_pid")
  while ((${#queue[@]} > 0)); do
    pid="${queue[0]}"
    queue=("${queue[@]:1}")

    ps -o pid=,comm=,args= -p "$pid" 2>/dev/null | sed -E 's/^[[:space:]]+//'
    while IFS= read -r child; do
      child="$(printf '%s' "$child" | tr -d '[:space:]')"
      [[ -n "$child" ]] || continue
      queue+=("$child")
    done < <(ps -o pid= --ppid "$pid" 2>/dev/null)
  done
}

looks_like_agent_process_tree() {
  local pane="$1"
  local process_snapshot

  process_snapshot="$(pane_process_snapshot "$pane")" || return 1
  [[ -n "$process_snapshot" ]] || return 1
  printf '%s\n' "$process_snapshot" | grep -qiE -- "$AGENT_PROCESS_PATTERN"
}

looks_like_agent_pane() {
  local pane="$1"
  local current_command="$2"
  local output="$3"

  if [[ "$current_command" =~ $DIRECT_AGENT_COMMAND_PATTERN ]]; then
    return 0
  fi

  if [[ "$current_command" =~ $WRAPPED_AGENT_COMMAND_PATTERN ]] &&
    printf '%s\n' "$output" | grep -qiE -- "$AGENT_OUTPUT_PATTERN"; then
    return 0
  fi

  if looks_like_agent_process_tree "$pane"; then
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
  local prompt_text

  prompt_text="$(prompt_buffer_text "$1")" || return 1
  [[ -n "$prompt_text" && "$prompt_text" != "$PROMPT" ]]
}

has_stuck_pattern() {
  local output="$1"
  printf '%s\n' "$output" | tail -n "$STUCK_WINDOW_LINES" | grep -qiE -- "$PATTERN"
}

pane_is_busy() {
  local pane="$1"
  local title

  title="$(pane_title "$pane")" || return 1
  [[ "$title" =~ $BUSY_TITLE_PATTERN ]]
}

pane_state_file() {
  local server_key pane_key

  if [[ -n "$TMUX_SOCKET_NAME" ]]; then
    server_key="socket_name_$(printf '%s' "$TMUX_SOCKET_NAME" | tr -c '[:alnum:]_-' '_')"
  elif [[ -n "$TMUX_SOCKET_PATH" ]]; then
    server_key="socket_path_$(printf '%s' "$TMUX_SOCKET_PATH" | tr -c '[:alnum:]_-' '_')"
  else
    server_key="default"
  fi

  pane_key="$(printf '%s' "$1" | tr ':./' '___')"
  printf '%s/%s__%s.last_sent' "$STATE_DIR" "$server_key" "$pane_key"
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
  tmux_call send-keys -t "$1" C-m
}

clear_prompt_buffer() {
  tmux_call send-keys -t "$1" C-u
}

submit_buffered_prompt() {
  local pane="$1"
  local output_after_send

  press_enter "$pane"
  sleep "$SEND_SETTLE_SECONDS"
  output_after_send="$(capture_visible_output "$pane")" || return 1

  if prompt_is_still_buffered "$output_after_send"; then
    log "WARN: $(pane_log_label "$pane") - 补发 Enter 后 prompt 仍停留在输入框"
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

  tmux_call send-keys -t "$pane" -l "$PROMPT"
  press_enter "$pane"

  sleep "$SEND_SETTLE_SECONDS"
  output_after_send="$(capture_visible_output "$pane")" || return 1
  if prompt_is_still_buffered "$output_after_send"; then
    log "RETRY: $(pane_log_label "$pane") - prompt 仍停留在输入框，补发一次 Enter"
    if ! submit_buffered_prompt "$pane"; then
      return 1
    fi
  fi

  return 0
}

scan_all_panes() {
  local pane_list
  if ! pane_list="$(tmux_call list-panes -a -F '#{session_name}:#{window_index}.#{pane_index}' 2>/dev/null)"; then
    log "WARN: ${TMUX_TARGET_LABEL} ($(tmux_command_display)) 未运行或无 session"
    return
  fi

  while IFS= read -r pane; do
    [[ -z "$pane" ]] && continue
    local pane_label
    pane_label="$(pane_log_label "$pane")"

    if ! matches_session "$pane"; then
      continue
    fi

    local current_command output visible_output
    current_command="$(pane_current_command "$pane")" || continue
    output="$(capture_recent_output "$pane")" || continue
    [[ -z "$output" ]] && continue

    if ! looks_like_agent_pane "$pane" "$current_command" "$output"; then
      continue
    fi

    visible_output="$(capture_visible_output "$pane")" || continue

    if prompt_is_still_buffered "$visible_output"; then
      if pane_is_busy "$pane"; then
        log "SKIP: $pane_label - prompt 已在输入框，但 agent 仍忙"
        continue
      fi

      log "RESUME: $pane_label - prompt 已在输入框，补发 Enter"
      if submit_buffered_prompt "$pane"; then
        mark_prompt_sent "$pane"
      fi
      continue
    fi

    if prompt_has_manual_input "$visible_output"; then
      log "SKIP: $pane_label - 输入框已有未提交内容，不注入 watchdog prompt"
      continue
    fi

    if has_stuck_pattern "$output"; then
      if pane_is_busy "$pane"; then
        log "SKIP: $pane_label - 命中错误，但 agent 仍忙"
        continue
      fi

      if ! pane_has_ready_prompt "$visible_output"; then
        log "SKIP: $pane_label - 命中错误，但当前无可输入 prompt"
        continue
      fi

      if recently_prompted "$pane"; then
        log "SKIP: $pane_label - 冷却中，暂不重复发送"
        continue
      fi

      log "STUCK: $pane_label - 命中错误，强制发送 \"$PROMPT\""
      if send_prompt "$pane" true; then
        mark_prompt_sent "$pane"
      fi
      continue
    fi
  done <<< "$pane_list"
}

main() {
  if ! parse_args "$@"; then
    return 1
  fi

  if [[ "$SHOW_HELP" == true ]]; then
    usage
    return 0
  fi

  log "=== tmux-watchdog 启动 ==="
  log "    tmux 目标: $(tmux_targets_display)"
  log "    检测间隔: ${INTERVAL}s | 检查行数: ${LINES_TO_CHECK} | prompt: \"${PROMPT}\""
  log "    session 过滤: ${SESSION_PATTERN}"
  log "    直接命令过滤: ${DIRECT_AGENT_COMMAND_PATTERN}"
  log "    包装命令过滤: ${WRAPPED_AGENT_COMMAND_PATTERN}"
  log "    进程树 agent 过滤: ${AGENT_PROCESS_PATTERN}"
  log "    agent 输出特征: ${AGENT_OUTPUT_PATTERN}"
  log "    ready prompt 特征: ${READY_PROMPT_PATTERN}"
  log "    ready prompt 可见窗口: 底部 ${READY_WINDOW_LINES} 行"
  log "    stuck pattern 可见窗口: 底部 ${STUCK_WINDOW_LINES} 行"
  log "    busy title 特征: ${BUSY_TITLE_PATTERN}"
  log "    冷却时间: ${COOLDOWN_SECONDS}s | 状态目录: ${STATE_DIR}"
  log "    发送后等待: ${SEND_SETTLE_SECONDS}s"
  log "    报错 pattern: ${PATTERN}"

  while true; do
    scan_all_targets
    sleep "$INTERVAL"
  done
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
  main "$@"
fi
