#!/bin/bash

run_skills_anthro() {
    local agent="$1"
    npx -y skills add anthropics/skills -a "$agent" -g -y \
        --skill skill-creator --skill mcp-builder --skill pdf --skill xlsx --skill docx
}

run_skills_codex() {
    local agent="$1"
    npx -y skills add skills-directory/skill-codex -a "$agent" -g -y
}
