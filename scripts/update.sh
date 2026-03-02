#!/bin/bash
set -e

section() { echo ""; echo "══ $1 ══"; }

# ─── Claude Code ────────────────────────────────
section "Claude Code"
command -v claude &>/dev/null || curl -fsSL https://claude.ai/install.sh | bash
claude update

# ─── MCP: fetch ─────────────────────────────────
section "MCP: fetch"
npm install -g claude-fetch-setup --silent 2>/dev/null
claude-fetch-setup

# ─── GSD workflow ───────────────────────────────
section "GSD workflow"
npx -y get-shit-done-cc --claude --global

# ─── Global CLI tools ──────────────────────────
section "Global CLI tools"
npm install -g --silent @google/gemini-cli @openai/codex happy-coder opencode-ai@latest
echo "  ✓ gemini-cli, codex, happy-coder, opencode-ai"

# ─── Claude Code Plugins ────────────────────────
section "Claude Code Plugins"
claude plugin update ralph-wiggum@claude-code-plugins 2>/dev/null || \
    claude plugin install ralph-wiggum@claude-code-plugins 2>/dev/null || true
echo "  ✓ ralph-wiggum"

# ─── Skills (Claude Code, Codex CLI, Gemini CLI) ───────────────
section "Skills"
# Note: Claude Code's agent name is "claude-code", not "claude"
for agent in claude-code codex gemini-cli; do
    npx -y skills add anthropics/skills -a "$agent" -g -y --skill skill-creator --skill mcp-builder --skill pdf --skill xlsx --skill docx 2>&1 | grep -E "✓|Done" || true
    npx -y skills add skills-directory/skill-codex -a "$agent" -g -y 2>&1 | grep -E "✓|Done" || true
done
npx -y skills ls -g

section "Done ✓"
