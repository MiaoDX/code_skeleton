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

    # Remove context-monitor PostToolUse hook — we rely on auto-compact instead (GSD #976).
    # GSD's config-set only writes per-project .planning/config.json, so we strip the
    # hook entry from the global settings.json directly.
    local settings="$HOME/.claude/settings.json"
    if [ -f "$settings" ] && command -v jq >/dev/null 2>&1; then
        local tmp
        tmp=$(jq '
          if .hooks.PostToolUse then
            .hooks.PostToolUse |= map(
              select(.hooks | any(.command | test("gsd-context-monitor")) | not)
            )
          else . end
        ' "$settings") && printf '%s\n' "$tmp" > "$settings"
        echo "  ✓ removed gsd-context-monitor hook from settings.json"
    fi

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

run_gstack() {
    local devkit_dir repo_dir repo_parent

    devkit_dir=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
    repo_dir="${GSTACK_REPO_DIR:-$devkit_dir/vendor/gstack}"

    if ! command -v git >/dev/null 2>&1; then
        echo "  ! skipped because git is not installed"
        return 0
    fi

    if ! command -v bun >/dev/null 2>&1; then
        echo "  ! skipped because bun is not installed (gstack requires Bun)"
        return 0
    fi

    repo_parent=$(dirname "$repo_dir")
    mkdir -p "$repo_parent"

    if [ -e "$repo_dir" ]; then
        if ! git -C "$repo_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
            echo "gstack install path exists but is not a git repo: $repo_dir"
            return 1
        fi

        git -C "$repo_dir" pull --ff-only
    else
        git clone --single-branch --depth 1 https://github.com/garrytan/gstack.git "$repo_dir"
    fi

    # Run explicit host installs so both Claude Code and Codex get the gstack skill set.
    (
        cd "$repo_dir"
        ./setup --host claude -q
        ./setup --host codex -q
    )

    echo "  ✓ gstack latest"
    echo "  ✓ gstack path: $repo_dir"
    echo "  ✓ gstack hosts: claude, codex"
}

run_gstack_state() {
    local state_dir state_remote sync_pull branch origin_url

    state_dir="${GSTACK_STATE_DIR:-$HOME/.gstack}"
    state_remote="${GSTACK_STATE_REPO_URL:-}"
    sync_pull="$state_dir/sync-pull"

    if ! command -v git >/dev/null 2>&1; then
        echo "  ! skipped because git is not installed"
        return 0
    fi

    if [ -d "$state_dir" ] && git -C "$state_dir" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        if [ -f "$sync_pull" ]; then
            (cd "$state_dir" && bash "$sync_pull")
        else
            if ! git -C "$state_dir" remote get-url origin >/dev/null 2>&1; then
                echo "  ! skipped because $state_dir has no origin remote"
                return 0
            fi

            branch="$(git -C "$state_dir" branch --show-current 2>/dev/null || echo main)"
            if ! git -C "$state_dir" rev-parse --verify "@{upstream}" >/dev/null 2>&1; then
                if ! git -C "$state_dir" rev-parse --verify "refs/remotes/origin/$branch" >/dev/null 2>&1; then
                    git -C "$state_dir" fetch origin "$branch" >/dev/null 2>&1 || true
                fi
                if git -C "$state_dir" rev-parse --verify "refs/remotes/origin/$branch" >/dev/null 2>&1; then
                    git -C "$state_dir" branch --set-upstream-to="origin/$branch" "$branch" >/dev/null 2>&1 || true
                fi
            fi

            git -C "$state_dir" pull --rebase --autostash
        fi

        origin_url="$(git -C "$state_dir" remote get-url origin 2>/dev/null || true)"
        echo "  ✓ gstack state synced"
        echo "  ✓ gstack state path: $state_dir"
        if [ -n "$origin_url" ]; then
            echo "  ✓ gstack state origin: $origin_url"
        fi
        return 0
    fi

    if [ -e "$state_dir" ]; then
        echo "  ! skipped because $state_dir exists but is not a git repo"
        echo "  ! Convert it with ~/.gstack/sync-init or clone your private state repo into that path."
        return 0
    fi

    if [ -z "$state_remote" ]; then
        echo "  ! skipped because $state_dir does not exist and GSTACK_STATE_REPO_URL is not set"
        return 0
    fi

    mkdir -p "$(dirname "$state_dir")"
    git clone --single-branch --depth 1 "$state_remote" "$state_dir"
    chmod +x "$state_dir"/sync-* 2>/dev/null || true

    if [ -f "$sync_pull" ]; then
        (cd "$state_dir" && bash "$sync_pull")
    fi

    echo "  ✓ gstack state cloned"
    echo "  ✓ gstack state path: $state_dir"
    echo "  ✓ gstack state origin: $state_remote"
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
