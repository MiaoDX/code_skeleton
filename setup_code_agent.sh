#!/bin/bash

PROJECT_DIR=$PWD

# script's own directory (where code_skeleton lives) - use absolute path
SKELETON_DIR=$(cd "$(dirname "$0")" && pwd)

# Prevent running from code_skeleton directory itself (would create self-referential symlinks)
if [ "$PROJECT_DIR" = "$SKELETON_DIR" ]; then
    echo "Error: Cannot run setup from code_skeleton directory itself"
    exit 1
fi

# softlink these cli md
echo "Linking CLI markdown files..."
ln -sf $SKELETON_DIR/CLAUDE.md .
ln -sf $SKELETON_DIR/AGENTS.md .
ln -sf $SKELETON_DIR/GEMINI.md .

# softlink the refs
echo "Linking refs directory..."
ln -sf $SKELETON_DIR/refs .

# softlink gemini config to make sure zen click usage
echo "Linking gemini config..."
ln -sf ~/.gemini/ .

# softlink entire .claude directory (commands, hooks, settings)
echo "Linking .claude directory..."
ln -sf $SKELETON_DIR/.claude .claude

# Add claude_yolo alias to shell rc file (if not already present)
echo "Setting up claude_yolo alias..."
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
