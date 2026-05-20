#!/usr/bin/env bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
REPO_SCRIPTS_DIR=$(cd "$SCRIPT_DIR/.." && pwd)

# Install and configure Agent Deck as an isolated AI-agent session dashboard.
# https://github.com/asheshgoplani/agent-deck
#
# Defaults can be overridden by environment variables:
#   AGENT_DECK_VERSION=v1.9.20|latest
#   AGENT_DECK_INSTALL_DIR=~/.local/bin
#   AGENT_DECK_BIN_NAME=agent-deck
#   AGENT_DECK_CONFIG=~/.agent-deck/config.toml
#   AGENT_DECK_SKIP_INSTALL=1

AGENT_DECK_VERSION="${AGENT_DECK_VERSION:-v1.9.20}"
AGENT_DECK_INSTALL_DIR="${AGENT_DECK_INSTALL_DIR:-$HOME/.local/bin}"
AGENT_DECK_BIN_NAME="${AGENT_DECK_BIN_NAME:-agent-deck}"
AGENT_DECK_CONFIG="${AGENT_DECK_CONFIG:-$HOME/.agent-deck/config.toml}"
AGENT_DECK_SKIP_INSTALL="${AGENT_DECK_SKIP_INSTALL:-0}"
AGENT_DECK_AVAILABLE=true

resolve_agent_deck_cmd() {
    local installed_cmd="$AGENT_DECK_INSTALL_DIR/$AGENT_DECK_BIN_NAME"
    if [ -x "$installed_cmd" ]; then
        printf '%s\n' "$installed_cmd"
        return 0
    fi

    if command -v "$AGENT_DECK_BIN_NAME" >/dev/null 2>&1; then
        command -v "$AGENT_DECK_BIN_NAME"
        return 0
    fi

    return 1
}

install_agent_deck() {
    local installer
    installer=$(mktemp)

    echo "==> Installing Agent Deck..."
    echo "    Version: $AGENT_DECK_VERSION"
    echo "    Install dir: $AGENT_DECK_INSTALL_DIR"

    curl -fsSL https://raw.githubusercontent.com/asheshgoplani/agent-deck/main/install.sh -o "$installer"
    bash "$installer" \
        --name "$AGENT_DECK_BIN_NAME" \
        --dir "$AGENT_DECK_INSTALL_DIR" \
        --version "$AGENT_DECK_VERSION" \
        --skip-tmux-config \
        --non-interactive

    rm -f "$installer"
}

if [ "$AGENT_DECK_SKIP_INSTALL" = "1" ]; then
    echo "==> Skipping Agent Deck install because AGENT_DECK_SKIP_INSTALL=1"
else
    install_agent_deck
fi

if ! AGENT_DECK_CMD=$(resolve_agent_deck_cmd); then
    if [ "$AGENT_DECK_SKIP_INSTALL" = "1" ]; then
        AGENT_DECK_AVAILABLE=false
        AGENT_DECK_CMD="$AGENT_DECK_BIN_NAME"
    else
        echo "ERROR: could not find $AGENT_DECK_BIN_NAME after setup." >&2
        echo "       Add $AGENT_DECK_INSTALL_DIR to PATH or set AGENT_DECK_INSTALL_DIR." >&2
        exit 1
    fi
fi

mkdir -p "$(dirname "$AGENT_DECK_CONFIG")"
if [ -s "$AGENT_DECK_CONFIG" ]; then
    cp "$AGENT_DECK_CONFIG" "$AGENT_DECK_CONFIG.bak.$(date +%s)"
    echo "==> Backed up existing Agent Deck config."
fi

echo "==> Applying Agent Deck pilot config..."
bun "$REPO_SCRIPTS_DIR/lib/ensure-agent-deck-config.ts" "$AGENT_DECK_CONFIG"

if [ "$AGENT_DECK_AVAILABLE" = true ]; then
    echo "==> Agent Deck version:"
    "$AGENT_DECK_CMD" --version 2>/dev/null || "$AGENT_DECK_CMD" version 2>/dev/null || true

    echo "==> Checking Agent Deck Codex notify hook..."
    "$AGENT_DECK_CMD" codex-hooks install
fi

echo ""
echo "==> Done."
echo ""
echo "Configured defaults:"
echo "  - Codex is the default tool."
echo "  - Agent Deck uses isolated tmux socket: tmux -L agent-deck"
echo "  - Agent Deck status line is enabled only inside that isolated tmux server."
echo "  - Auto-update and startup update checks are disabled."
echo "  - Global search is enabled with bounded indexing: balanced, 100MB, 90 days, rate 10."
echo "  - MCP pooling, Docker-by-default, and worktree-by-default are disabled."
echo "  - Codex turn notifications are installed with agent-deck codex-hooks install."
echo ""
echo "Try:"
echo "  $AGENT_DECK_CMD"
echo "  $AGENT_DECK_CMD web --read-only"
echo "  tmux -L agent-deck ls"
