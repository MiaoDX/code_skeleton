#!/bin/bash
set -x

# Get the directory where this script is located
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

# Load .env file if exists
if [ -f "$SCRIPT_DIR/.env" ]; then
    echo "Loading .env file..."
    set -a
    source "$SCRIPT_DIR/.env"
    set +a
else
    echo "WARNING: .env file not found. Some features may be limited."
    echo "  Create .env from .env.example if you need API keys."
fi

npm install -g @anthropic-ai/claude-code
claude update
# https://github.com/pomelo-nwu/claude-fetch-setup
#npx claude-fetch-setup
npm install -g claude-fetch-setup
claude-fetch-setup

# Continuous Claude setup/update
CC_DIR="$SCRIPT_DIR/gits/Continuous-Claude-v3"

if [ ! -d "$CC_DIR" ]; then
    echo "Installing Continuous-Claude-v3..."
    git clone https://github.com/parcadei/Continuous-Claude-v3.git "$CC_DIR"
    cd "$CC_DIR/opc"
    uv run python -m scripts.setup.wizard
    cd - > /dev/null
else
    echo "Updating Continuous-Claude-v3..."
    cd "$CC_DIR"
    git pull
    cd opc
    uv run python -m scripts.setup.update
    cd - > /dev/null
fi

# Rename or delete the hook file
mv ~/.claude/hooks/dist/tldr-read-enforcer.mjs ~/.claude/hooks/dist/tldr-read-enforcer.mjs.disabled

npm install -g @google/gemini-cli
npm install -g @openai/codex
