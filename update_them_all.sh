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

# ─── Local Skills Check ─────────────────────────
section "Local Skills"
# Verify local skills exist (gemini is a local dir, codex is a symlink)
[ -d ~/.claude/skills/gemini ] && echo "  ✓ gemini skill (local)"
[ -L ~/.claude/skills/codex ] && echo "  ✓ codex skill (linked)"
echo "  ✓ Local skills ready"

# ─── Skills (Claude Code, Codex, Gemini CLI only) ───────────────
section "Skills"
# Install for Claude Code, Codex, and Gemini CLI only (not all agents)
for agent in claude codex gemini; do
    npx -y skills add anthropics/skills -a "$agent" -g -y --skill skill-creator --skill mcp-builder --skill pdf --skill xlsx --skill docx 2>&1 | grep -E "✓|Done" || true
done
#npx -y skills add vercel-labs/agent-skills -a '*' -g -y 2>&1 | grep -E "✓|Done"
# https://github.com/skills-directory/skill-codex
for agent in claude codex gemini; do
    npx -y skills add skills-directory/skill-codex -a "$agent" -g -y 2>&1 | grep -E "✓|Done" || true
done
npx -y skills ls -g

section "Done ✓"
