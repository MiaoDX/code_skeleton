#!/bin/bash
set -e

section() { echo ""; echo "══ $1 ══"; }
LOGDIR=$(mktemp -d)
trap 'rm -rf "$LOGDIR"' EXIT

# Run a task in the background, capturing output to a log file.
# Usage: bg_task <name> <command...>
bg_task() {
    local name="$1"; shift
    "$@" &>"$LOGDIR/$name.log" &
    echo $!
}

# Wait for a pid and print its captured output under a section header.
await_task() {
    local name="$1" pid="$2"
    wait "$pid" 2>/dev/null || true
    section "$name"
    cat "$LOGDIR/$name.log"
}

# ── Phase 1: independent tasks in parallel ───────────────────────

pid_claude=$(bg_task "Claude Code" bash -c '
    # npm is faster in China (mirrors) than `claude update` (Anthropic CDN).
    npm install -g @anthropic-ai/claude-code 2>&1 | tail -1
    echo "  ✓ claude $(claude --version 2>/dev/null)"
')

pid_fetch=$(bg_task "MCP: fetch" bash -c '
    npm install -g claude-fetch-setup 2>&1 | tail -1
    claude-fetch-setup 2>&1 || true
    echo "  ✓ claude-fetch-setup"
')

pid_gsd=$(bg_task "GSD workflow" bash -c '
    npx -y get-shit-done-cc --claude --global 2>&1 | tail -2 &
    npx -y get-shit-done-cc --codex --global 2>&1 | tail -2 &
    wait
    echo "  ✓ gsd (claude + codex)"
')

pid_cli=$(bg_task "Global CLI tools" bash -c '
    npm install -g @google/gemini-cli @openai/codex happy-coder opencode-ai@latest 2>&1 | tail -1
    echo "  ✓ gemini-cli, codex, happy-coder, opencode-ai"
')

# Skills: 3 agents × 2 sources = 6 calls, all independent
skills_pids=()
for agent in claude-code codex gemini-cli; do
    pid=$(bg_task "skills-anthro-$agent" bash -c "
        npx -y skills add anthropics/skills -a '$agent' -g -y \
            --skill skill-creator --skill mcp-builder --skill pdf --skill xlsx --skill docx \
            2>&1 | grep -E '✓|Done' || true
    ")
    skills_pids+=("skills-anthro-$agent:$pid")

    pid=$(bg_task "skills-codex-$agent" bash -c "
        npx -y skills add skills-directory/skill-codex -a '$agent' -g -y \
            2>&1 | grep -E '✓|Done' || true
    ")
    skills_pids+=("skills-codex-$agent:$pid")
done

# ── Collect results ──────────────────────────────────────────────

await_task "Claude Code" "$pid_claude"

# Plugin depends on claude being updated
section "Claude Code Plugins"
claude plugin update ralph-wiggum@claude-code-plugins 2>/dev/null || \
    claude plugin install ralph-wiggum@claude-code-plugins 2>/dev/null || true
echo "  ✓ ralph-wiggum"

await_task "MCP: fetch"      "$pid_fetch"
await_task "GSD workflow"     "$pid_gsd"
await_task "Global CLI tools" "$pid_cli"

section "Skills"
for entry in "${skills_pids[@]}"; do
    name="${entry%%:*}"
    pid="${entry##*:}"
    wait "$pid" 2>/dev/null || true
    cat "$LOGDIR/$name.log" 2>/dev/null
done
npx -y skills ls -g

section "Done ✓"
