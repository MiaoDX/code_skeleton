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

# ─── Skills (all agents, global) ───────────────
section "Skills"
npx -y skills add anthropics/skills -a '*' -g -y --skill skill-creator --skill mcp-builder --skill pdf --skill xlsx --skill docx 2>&1 | grep -E "✓|Done"
#npx -y skills add vercel-labs/agent-skills -a '*' -g -y 2>&1 | grep -E "✓|Done"
# https://github.com/skills-directory/skill-codex
npx -y skills add skills-directory/skill-codex -a '*' -g -y 2>&1 | grep -E "✓|Done"
npx -y skills ls -g

section "Done ✓"
