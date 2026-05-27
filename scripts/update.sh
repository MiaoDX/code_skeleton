#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKIP_CODEX_RUNNING_CHECK=false
UPDATE_LOCK_DIR="${TMPDIR:-/tmp}/intuitive-flow-update.lock.d"
UPDATE_LOCK_PID_FILE="$UPDATE_LOCK_DIR/pid"
UPDATE_LOCK_HELD=false
NPM_REGISTRY_MODE="${NPM_REGISTRY_MODE:-mirror-first}"

usage() {
    echo "Usage: ${0##*/} [--tmp-fix] [--skip-codex-running-check] [--no-npm-mirror]"
}

codex_running_hint() {
    echo "Hint: If you only want to update versions and do not care whether existing Codex sessions overwrite status-line config on exit, rerun with:"
    echo "  ${0##*/} --skip-codex-running-check"
}

print_npm_source() {
    case "$NPM_REGISTRY_MODE" in
        direct)
            echo "  ✓ npm registry mode: direct ($NPM_FALLBACK_REGISTRY)"
            ;;
        mirror-first)
            echo "  ✓ npm registry mode: mirror-first ($NPM_MIRROR_REGISTRY; fallback $NPM_FALLBACK_REGISTRY)"
            ;;
        *)
            echo "  ! unknown NPM_REGISTRY_MODE=$NPM_REGISTRY_MODE; using mirror-first selector"
            ;;
    esac
}

active_legacy_update_runs() {
    local project_dir pid cwd command

    project_dir=$(cd "$SCRIPT_DIR/.." && pwd)
    while IFS= read -r pid; do
        [ -n "$pid" ] || continue
        [ "$pid" != "$$" ] || continue
        [ "$pid" != "${BASHPID:-}" ] || continue
        cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)
        [ "$cwd" = "$project_dir" ] || continue
        command=$(ps -o command= -p "$pid" 2>/dev/null || true)
        [[ "$command" == *"/bin/bash "*"scripts/update.sh"* || "$command" == bash\ *"scripts/update.sh"* ]] || continue
        ps -o pid=,etime=,command= -p "$pid"
    done < <(pgrep -f '(^|[[:space:]])([^[:space:]]*/)?scripts/update\.sh([[:space:]]|$)' 2>/dev/null || true)
}

cleanup_update_lock() {
    [ "$UPDATE_LOCK_HELD" = true ] || return 0
    [ "$(cat "$UPDATE_LOCK_PID_FILE" 2>/dev/null || true)" = "$$" ] || return 0
    rm -rf "$UPDATE_LOCK_DIR"
}

update_lock_pid_is_active() {
    local pid="$1"
    local project_dir cwd command

    [[ "$pid" =~ ^[0-9]+$ ]] || return 1
    [ "$pid" != "$$" ] || return 1
    [ "$pid" != "${BASHPID:-}" ] || return 1
    [ -d "/proc/$pid" ] || return 1

    project_dir=$(cd "$SCRIPT_DIR/.." && pwd)
    cwd=$(readlink -f "/proc/$pid/cwd" 2>/dev/null || true)
    [ "$cwd" = "$project_dir" ] || return 1

    command=$(ps -o command= -p "$pid" 2>/dev/null || true)
    [[ "$command" == *"/bin/bash "*"scripts/update.sh"* || "$command" == bash\ *"scripts/update.sh"* ]]
}

acquire_update_lock() {
    local lock_pid

    if mkdir "$UPDATE_LOCK_DIR" 2>/dev/null; then
        printf '%s\n' "$$" > "$UPDATE_LOCK_PID_FILE"
        UPDATE_LOCK_HELD=true
        trap cleanup_update_lock EXIT
        return 0
    fi

    lock_pid=$(cat "$UPDATE_LOCK_PID_FILE" 2>/dev/null || true)
    if update_lock_pid_is_active "$lock_pid"; then
        echo "Another update.sh run is already active:"
        ps -o pid=,etime=,command= -p "$lock_pid"
        exit 1
    fi

    echo "  ! removing stale update lock: $UPDATE_LOCK_DIR"
    rm -rf "$UPDATE_LOCK_DIR"
    if ! mkdir "$UPDATE_LOCK_DIR" 2>/dev/null; then
        echo "Another update.sh run may have started."
        echo "Inspect it with:"
        echo "  ps -eo pid,ppid,pgid,etime,command | grep '[s]cripts/update.sh'"
        exit 1
    fi

    printf '%s\n' "$$" > "$UPDATE_LOCK_PID_FILE"
    UPDATE_LOCK_HELD=true
    trap cleanup_update_lock EXIT
}

# --tmp-fix → run only the dirty-patch script (scripts/support/tmp-fix.sh) and exit.
# Used to repair upstream-version drift (e.g. codex schema changes) without
# re-running the full update. Drop fixes from tmp-fix.sh when upstream catches up.
for arg in "$@"; do
    case "$arg" in
        --tmp-fix)
            exec "$SCRIPT_DIR/support/tmp-fix.sh"
            ;;
        --skip-codex-running-check)
            SKIP_CODEX_RUNNING_CHECK=true
            ;;
        --no-npm-mirror)
            NPM_REGISTRY_MODE=direct
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

source "$SCRIPT_DIR/lib/npm-registry.sh"
export NPM_REGISTRY_MODE
print_npm_source

acquire_update_lock

legacy_runs=$(active_legacy_update_runs)
if [ -n "$legacy_runs" ]; then
    echo "Another update.sh run is already active:"
    echo "$legacy_runs"
    exit 1
fi

# Source nvm if available (needed when running from bash but nvm is configured in zsh)
if [ -n "${NVM_DIR:-}" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
    # Activate node if not in PATH (e.g., default version was uninstalled)
    if ! command -v node >/dev/null 2>&1; then
        nvm use --lts >/dev/null 2>&1 || nvm use node >/dev/null 2>&1 || true
    fi
fi

source "$SCRIPT_DIR/lib/ensure-no-running-codex.sh"
source "$SCRIPT_DIR/lib/ensure-clean-env.sh"
source "$SCRIPT_DIR/lib/task-runner.sh"
source "$SCRIPT_DIR/tasks/update-cli.sh"
source "$SCRIPT_DIR/tasks/update-agent-deck.sh"
source "$SCRIPT_DIR/tasks/update-skills.sh"
source "$SCRIPT_DIR/tasks/update-gstack.sh"
source "$SCRIPT_DIR/tasks/sync-local-commands-skills.sh"

TASK_RUNNER_EXTRA_CLEANUP=cleanup_update_lock

ensure_clean_env
if [ "$SKIP_CODEX_RUNNING_CHECK" = true ]; then
    echo "  ! Skipping Codex running-process check by request."
else
    if ! ensure_no_running_codex; then
        echo
        usage
        codex_running_hint
        exit 1
    fi
fi

task_init

# ── Phase 1: independent tasks in parallel ───────────────────────────
task_run "Global CLI tools" run_global_cli_tools --hint print_npm_failure_hint
task_run "GSD workflow"     run_gsd_workflow

# Codex config runs sequentially after GSD workflow — both rewrite
# ~/.codex/config.toml, so racing them can clobber feature and [tui] updates.

skills_names=()

# ── Collect results, gating downstream tasks on CLI success ──────────
task_await "Global CLI tools"

if task_succeeded "Global CLI tools"; then
    task_run "MCP: fetch"     run_mcp_fetch
    task_run "Claude plugins" run_claude_plugins
    task_await "MCP: fetch"
    task_await "Claude plugins"
else
    task_skip "MCP: fetch"     "skipped because Global CLI tools failed"
    task_skip "Claude plugins" "skipped because Global CLI tools failed"
fi

task_await "GSD workflow"

task_run "Codex config" run_codex_config
task_await "Codex config"

# Agent Deck installs Codex notify hooks, so run it after Codex hooks are enabled.
task_run "Agent Deck" run_agent_deck
task_await "Agent Deck"

task_run "GStack State" run_gstack_state
task_await "GStack State"

if task_succeeded "Global CLI tools"; then
    task_run "GStack" run_gstack --hint print_gstack_failure_hint
    task_await "GStack"
else
    task_skip "GStack" "skipped because Global CLI tools failed"
fi

# GSD scans ~/.codex/skills, and GStack rewrites the gstack skill links there.
# Keep those phases ahead of the remaining skill installers so home-level skill
# updates do not overlap.
for agent in claude-code codex; do
    n="skills-anthro-$agent";     skills_names+=("$n"); task_run "$n" run_skills_anthro     "$agent"
    n="skills-codex-$agent";      skills_names+=("$n"); task_run "$n" run_skills_codex      "$agent"
    n="skills-mattpocock-$agent"; skills_names+=("$n"); task_run "$n" run_skills_mattpocock "$agent"
done
task_await_group "Skills" "${skills_names[@]}"

# Local command/skill sync also writes to ~/.codex/skills. Run it last so local
# skill overrides win deterministically.
task_run "Local commands & skills" run_sync_local_commands_skills
task_await "Local commands & skills"

task_summary
