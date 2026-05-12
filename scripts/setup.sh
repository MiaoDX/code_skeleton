#!/bin/bash
set -euo pipefail

PROJECT_DIR=$PWD

# Toolkit root directory (one level up from scripts/).
SKELETON_DIR=$(cd "$(dirname "$0")/.." && pwd)

# Prevent running from code_skeleton directory itself.
if [ "$PROJECT_DIR" = "$SKELETON_DIR" ]; then
    echo "Error: Cannot run setup from code_skeleton directory itself"
    exit 1
fi

copy_agent_file() {
    local name="$1"
    local src="$SKELETON_DIR/$name"
    local tmp

    if [ -L "$name" ]; then
        tmp=".$name.devkit-local.$$"
        if ! cp -L "$name" "$tmp" 2>/dev/null; then
            cp "$src" "$tmp"
        fi
        rm -f "$name"
        mv "$tmp" "$name"
        echo "Converted $name symlink to a project-local file"
    elif [ -e "$name" ]; then
        echo "Keeping existing project-local $name"
    else
        cp "$src" "$name"
        echo "Created starter $name"
    fi
}

link_shared_dir() {
    local label="$1"
    local src="$2"
    local dest="$3"

    if [ ! -e "$src" ]; then
        echo "Skipping $label: source not found at $src"
        return 0
    fi

    if [ -L "$dest" ]; then
        rm -f "$dest"
    elif [ -e "$dest" ]; then
        echo "Keeping existing $label at $dest"
        return 0
    fi

    ln -s "$src" "$dest"
    echo "Linked $label -> $src"
}

echo "Preparing project-local agent guidance..."
copy_agent_file "CLAUDE.md"
copy_agent_file "AGENTS.md"
echo 'Tip: run /init for suggestions, then use $intuitive-setup to merge them conservatively.'

echo "Linking shared reference and Claude assets..."
link_shared_dir "context directory" "$SKELETON_DIR/context" "context"

mkdir -p .claude
link_shared_dir ".claude/commands directory" "$SKELETON_DIR/.claude/commands" ".claude/commands"
link_shared_dir ".claude/skills directory" "$SKELETON_DIR/.claude/skills" ".claude/skills"

# Add claude_yolo alias to shell rc file (if not already present).
echo "Setting up claude_yolo alias..."
ALIAS_LINE="alias claude_yolo='claude --dangerously-skip-permissions'"
RC_FILE="$HOME/.zshrc"
[ -f "$HOME/.bashrc" ] && [ ! -f "$HOME/.zshrc" ] && RC_FILE="$HOME/.bashrc"

if ! grep -q "claude_yolo" "$RC_FILE" 2>/dev/null; then
    {
        echo ""
        echo "# Claude Code yolo mode (skip permissions)"
        echo "$ALIAS_LINE"
    } >> "$RC_FILE"
    echo "Added claude_yolo alias to $RC_FILE"
else
    echo "claude_yolo alias already exists in $RC_FILE"
fi
