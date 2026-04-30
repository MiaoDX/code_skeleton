#!/bin/bash

_run_skills() {
    local agent="$1" repo="$2" label="$3"; shift 3
    local out
    out=$(npx -y skills add "$repo" -a "$agent" -g -y "$@" 2>&1) || { echo "$out"; return 1; }
    echo "$out" | grep -E '(warn|error|⚠|✗)' || true
    echo "  ✓ skills ($label) → $agent"
}

run_skills_anthro() {
    _run_skills "$1" "anthropics/skills" "anthropics" \
        --skill skill-creator --skill mcp-builder --skill pdf --skill xlsx --skill docx
}

run_skills_codex() {
    _run_skills "$1" "skills-directory/skill-codex" "codex"
}

run_skills_mattpocock() {
    _run_skills "$1" "https://github.com/mattpocock/skills" "mattpocock"
}
