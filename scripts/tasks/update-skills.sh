#!/bin/bash

run_skills_anthro() {
    local agent="$1"
    # Suppress verbose skills output; only show warnings
    npx -y skills add anthropics/skills -a "$agent" -g -y \
        --skill skill-creator --skill mcp-builder --skill pdf --skill xlsx --skill docx \
        2>&1 | grep -E '(warn|error|⚠|✗)' || true
    echo "  ✓ skills (anthropics) → $agent"
}

run_skills_codex() {
    local agent="$1"
    # Suppress verbose skills output; only show warnings
    npx -y skills add skills-directory/skill-codex -a "$agent" -g -y \
        2>&1 | grep -E '(warn|error|⚠|✗)' || true
    echo "  ✓ skills (codex) → $agent"
}
