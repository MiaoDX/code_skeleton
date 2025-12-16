#!/bin/bash

PROJECT_DIR=$PWD

# script's own directory (where code_skeleton lives)
SKELETON_DIR=$(dirname "$0")

# softlink these cli md
ln -s $SKELETON_DIR/CLAUDE.md .
ln -s $SKELETON_DIR/AGENTS.md .
ln -s $SKELETON_DIR/GEMINI.md .

# softlink the refs
ln -s $SKELETON_DIR/refs .

# softlink gemini config to make sure zen click usage
ln -s ~/.gemini/ .

# Add claude_yolo alias to shell rc file (if not already present)
ALIAS_LINE="alias claude_yolo='claude --dangerously-skip-permissions'"
RC_FILE="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.zshrc" ] && RC_FILE="$HOME/.bashrc"

if ! grep -q "claude_yolo" "$RC_FILE" 2>/dev/null; then
    echo "" >> "$RC_FILE"
    echo "# Claude Code yolo mode (skip permissions)" >> "$RC_FILE"
    echo "$ALIAS_LINE" >> "$RC_FILE"
    echo "Added claude_yolo alias to $RC_FILE"
else
    echo "claude_yolo alias already exists in $RC_FILE"
fi
