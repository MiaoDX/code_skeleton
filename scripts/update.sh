#!/bin/bash
set -euo pipefail

section() { echo ""; echo "══ $1 ══"; }
LOGDIR=$(mktemp -d)
trap 'rm -rf "$LOGDIR"' EXIT

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

print_failure_hint() {
    local name="$1" log_file="$2"

    case "$name" in
        "Global CLI tools")
            print_npm_failure_hint "$log_file"
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

run_global_cli_tools() {
    # Keep all global npm installs in one command so they do not race on the same prefix.
    npm install -g --loglevel=error \
        @anthropic-ai/claude-code \
        claude-fetch-setup \
        @google/gemini-cli \
        @openai/codex \
        happy-coder \
        opencode-ai@latest

    echo "  ✓ claude $(claude --version 2>/dev/null)"
    echo "  ✓ codex $(codex --version 2>/dev/null)"
    echo "  ✓ gemini-cli"
    echo "  ✓ happy-coder"
    echo "  ✓ opencode-ai"
}

run_gsd_workflow() {
    npx -y get-shit-done-cc --claude --global
    npx -y get-shit-done-cc --codex --global
    echo "  ✓ gsd (claude + codex)"
}

run_mcp_fetch() {
    claude-fetch-setup
    echo "  ✓ claude-fetch-setup"
}

run_skills_anthro() {
    local agent="$1"
    npx -y skills add anthropics/skills -a "$agent" -g -y \
        --skill skill-creator --skill mcp-builder --skill pdf --skill xlsx --skill docx
}

run_skills_codex() {
    local agent="$1"
    npx -y skills add skills-directory/skill-codex -a "$agent" -g -y
}

# ── Phase 1: independent tasks in parallel ───────────────────────

bg_task "Global CLI tools" run_global_cli_tools
pid_cli=$BG_TASK_PID

bg_task "GSD workflow" run_gsd_workflow
pid_gsd=$BG_TASK_PID

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

if [ "${#failed_sections[@]}" -gt 0 ]; then
    section "Failed ✗"
    for name in "${failed_sections[@]}"; do
        echo "  - $name"
    done
    exit 1
fi

section "Done ✓"
