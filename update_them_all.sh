#!/bin/bash
set -x

# Use nvm to install the lasted node first plz

if ! command -v claude &> /dev/null; then
    echo "Installing claude..."
    curl -fsSL https://claude.ai/install.sh | bash
fi
claude update

# https://github.com/pomelo-nwu/claude-fetch-setup
#npx claude-fetch-setup
npm install -g claude-fetch-setup
claude-fetch-setup

npx get-shit-done-cc --claude --global

npm install -g @google/gemini-cli
npm install -g @openai/codex
npm install -g happy-coder
