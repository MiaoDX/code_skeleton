#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)

source "$SCRIPT_DIR/lib/ensure-no-running-codex.sh"

section() { echo ""; echo "══ $1 ══"; }
LOGDIR=$(mktemp -d)
trap 'rm -rf "$LOGDIR"' EXIT

ensure_no_running_codex

source "$SCRIPT_DIR/tasks/update-cli.sh"
source "$SCRIPT_DIR/tasks/update-skills.sh"
source "$SCRIPT_DIR/tasks/update-gstack.sh"

# Run a task in the background, capturing output to a log file.
# Usage: bg_task <name> <command...>
bg_task() {
    local name="$1"; shift
    "$@" >"$LOGDIR/$name.log" 2>&1 &
    BG_TASK_PID=$!
}

print_npm_failure_hint() {
    local log_file="$1"
    local path dest npm_log

    path=$(sed -n 's/^npm error path //p' "$log_file" | tail -1)
    dest=$(sed -n 's/^npm error dest //p' "$log_file" | tail -1)
    npm_log=$(sed -n 's/^npm error A complete log of this run can be found in: //p' "$log_file" | tail -1)

    if grep -q '^npm error ENOTEMPTY: directory not empty, rename ' "$log_file" && [ -n "$dest" ]; then
        echo "  ! npm could not move the existing package out of the way because this path already exists:"
        echo "    $dest"
        if [ -n "$path" ]; then
            echo "  ! It was trying to update:"
            echo "    $path"
        fi
        echo "  ! Inspect that leftover path and, if it is stale, move or remove it manually, then rerun update.sh."
        echo "  ! Example:"
        echo "    ls -la \"$(dirname "$dest")\""
        echo "    mv \"$dest\" \"${dest}.bak.$(date +%Y%m%d_%H%M%S)\""
    fi

    if [ -n "$npm_log" ]; then
        echo "  ! npm log: $npm_log"
    fi
}

print_gstack_failure_hint() {
    local log_file="$1"
    local repo_dir

    repo_dir=$(sed -n 's/^gstack install path exists but is not a git repo: //p' "$log_file" | tail -1)

    if [ -n "$repo_dir" ]; then
        echo "  ! That path already exists but is not a gstack git checkout:"
        echo "    $repo_dir"
        echo "  ! Move it aside or rerun update.sh with GSTACK_REPO_DIR pointing at a clean checkout path."
    fi
}

print_failure_hint() {
    local name="$1" log_file="$2"

    case "$name" in
        "Global CLI tools")
            print_npm_failure_hint "$log_file"
            ;;
        "GStack")
            print_gstack_failure_hint "$log_file"
            ;;
    esac
}

# Wait for a pid and print its captured output under a section header.
await_task() {
    local name="$1" pid="$2" status=0
    local log_file="$LOGDIR/$name.log"

    if ! wait "$pid"; then
        status=$?
    fi

    section "$name"
    cat "$log_file"

    if [ "$status" -ne 0 ]; then
        print_failure_hint "$name" "$log_file"
    fi

    return "$status"
}

failed_sections=()
record_failure() {
    failed_sections+=("$1")
}

# ── Phase 1: independent tasks in parallel ───────────────────────

bg_task "Global CLI tools" run_global_cli_tools
pid_cli=$BG_TASK_PID

bg_task "GSD workflow" run_gsd_workflow
pid_gsd=$BG_TASK_PID

bg_task "Codex TUI" run_codex_statusline
pid_codex_tui=$BG_TASK_PID

skills_pids=()
for agent in claude-code codex gemini-cli; do
    bg_task "skills-anthro-$agent" run_skills_anthro "$agent"
    skills_pids+=("skills-anthro-$agent:$BG_TASK_PID")

    bg_task "skills-codex-$agent" run_skills_codex "$agent"
    skills_pids+=("skills-codex-$agent:$BG_TASK_PID")
done

# ── Collect results ──────────────────────────────────────────────

cli_ok=true
if ! await_task "Global CLI tools" "$pid_cli"; then
    record_failure "Global CLI tools"
    cli_ok=false
fi

section "Claude Code Plugins"
echo "  ! optional: install Claude plugins manually after configuring a marketplace"
echo "    claude plugin marketplace add <owner/repo>"
echo "    claude plugin install <plugin>@<marketplace>"

if [ "$cli_ok" = true ]; then
    bg_task "MCP: fetch" run_mcp_fetch
    pid_fetch=$BG_TASK_PID
    if ! await_task "MCP: fetch" "$pid_fetch"; then
        record_failure "MCP: fetch"
    fi
else
    section "MCP: fetch"
    echo "  ! skipped because Global CLI tools failed"
fi

if ! await_task "GSD workflow" "$pid_gsd"; then
    record_failure "GSD workflow"
fi

if ! await_task "Codex TUI" "$pid_codex_tui"; then
    record_failure "Codex TUI"
fi

section "Skills"
skills_failed=false
for entry in "${skills_pids[@]}"; do
    name="${entry%%:*}"
    pid="${entry##*:}"
    if ! wait "$pid"; then
        skills_failed=true
    fi
    cat "$LOGDIR/$name.log" 2>/dev/null
done

if ! npx -y skills ls -g; then
    skills_failed=true
fi

if [ "$skills_failed" = true ]; then
    record_failure "Skills"
fi

bg_task "GStack State" run_gstack_state
pid_gstack_state=$BG_TASK_PID
if ! await_task "GStack State" "$pid_gstack_state"; then
    record_failure "GStack State"
fi

if [ "$cli_ok" = true ]; then
    bg_task "GStack" run_gstack
    pid_gstack=$BG_TASK_PID
    if ! await_task "GStack" "$pid_gstack"; then
        record_failure "GStack"
    fi
else
    section "GStack"
    echo "  ! skipped because Global CLI tools failed"
fi

if [ "${#failed_sections[@]}" -gt 0 ]; then
    section "Failed ✗"
    for name in "${failed_sections[@]}"; do
        echo "  - $name"
    done
    exit 1
fi

section "Done ✓"
