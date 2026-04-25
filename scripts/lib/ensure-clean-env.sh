#!/bin/bash

# Pre-flight environment checks for update.sh
# Ensures nvm, bun, and a single npm-based claude/codex installation.

NODE_MIN_MAJOR=20  # Minimum recommended node major version (LTS)

ensure_clean_env() {
    local errors=()
    local warnings=()

    # ── Check 1: nvm is installed ─────────────────────────────────────
    # nvm is a shell function, not a binary, so we check for NVM_DIR and nvm.sh

    if [ -z "${NVM_DIR:-}" ]; then
        errors+=("NVM_DIR is not set. nvm does not appear to be installed.")
        errors+=("  Install nvm: curl -o- https://raw.githubusercontent.com/nvm-sh/nvm/v0.40.4/install.sh | bash")
        errors+=("  Then restart your shell.")
    elif [ ! -f "$NVM_DIR/nvm.sh" ]; then
        errors+=("nvm.sh not found at \$NVM_DIR/nvm.sh")
        errors+=("  NVM_DIR is set to: $NVM_DIR")
        errors+=("  Reinstall nvm or fix NVM_DIR in your shell profile.")
    fi

    # ── Check 2: nvm default alias points to an installed version ────
    # Source nvm to check the alias (nvm is a shell function)

    if [ -n "${NVM_DIR:-}" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
        source "$NVM_DIR/nvm.sh" 2>/dev/null
        local default_alias
        default_alias=$(nvm alias default 2>/dev/null || true)
        if [[ "$default_alias" == *"N/A"* ]]; then
            errors+=("nvm default alias points to a version that is not installed:")
            errors+=("  $default_alias")
            errors+=("")
            errors+=("  Fix by setting default to latest LTS:")
            errors+=("    nvm alias default 'lts/*'")
        fi
    fi

    # ── Check 3: node/npm come from nvm ──────────────────────────────

    local node_path npm_path
    node_path=$(command -v node 2>/dev/null || true)
    npm_path=$(command -v npm 2>/dev/null || true)

    if [ -z "$node_path" ]; then
        errors+=("node not found in PATH.")
        errors+=("  Install a node version via nvm: nvm install --lts")
    elif [[ "$node_path" != *".nvm"* ]]; then
        errors+=("node is not provided by nvm: $node_path")
        errors+=("  Remove or unlink non-nvm node installations and use nvm instead.")
    fi

    if [ -z "$npm_path" ]; then
        errors+=("npm not found in PATH.")
    elif [[ "$npm_path" != *".nvm"* ]]; then
        errors+=("npm is not provided by nvm: $npm_path")
        errors+=("  Remove or unlink non-nvm npm installations.")
    fi

    # ── Check 4: node version is not too old ──────────────────────────

    if [ -n "$node_path" ]; then
        local node_major
        node_major=$(node --version 2>/dev/null | sed 's/^v//' | cut -d. -f1)
        if [ -n "$node_major" ] && [ "$node_major" -lt "$NODE_MIN_MAJOR" ]; then
            warnings+=("Node version v$node_major is outdated (minimum recommended: v$NODE_MIN_MAJOR).")
            warnings+=("  Consider upgrading: nvm install --lts && nvm use --lts")
        fi
    fi

    # ── Check 5: bun is installed ────────────────────────────────────

    if ! command -v bun >/dev/null 2>&1; then
        errors+=("bun not found in PATH.")
        errors+=("  Install bun: curl -fsSL https://bun.sh/install | bash")
    fi

    # ── Check 6: single claude binary from nvm npm ───────────────────
    # Use 'type -a' and extract paths (portable across bash versions)

    local claude_paths claude_count claude_first
    claude_paths=$(type -a claude 2>/dev/null | sed -n 's/^claude is //p' || true)
    if [ -z "$claude_paths" ]; then
        claude_count=0
    else
        claude_count=$(echo "$claude_paths" | wc -l | tr -d ' ')
    fi
    claude_first=$(echo "$claude_paths" | head -1)

    if [ "$claude_count" -eq 0 ] || [ -z "$claude_first" ]; then
        # No claude installed yet — that's fine, update.sh will install it.
        :
    elif [ "$claude_count" -gt 1 ]; then
        errors+=("Multiple claude binaries found in PATH:")
        while IFS= read -r p; do
            [ -n "$p" ] && errors+=("  - $p")
        done <<< "$claude_paths"
        errors+=("  Remove duplicates so only the nvm npm global install remains.")
    elif [[ "$claude_first" != *".nvm"* ]]; then
        errors+=("claude is not installed via nvm npm: $claude_first")
        errors+=("  Remove this installation. update.sh will install via npm.")
    fi

    # ── Check 7: single codex binary from nvm npm ────────────────────

    local codex_paths codex_count codex_first
    codex_paths=$(type -a codex 2>/dev/null | sed -n 's/^codex is //p' || true)
    if [ -z "$codex_paths" ]; then
        codex_count=0
    else
        codex_count=$(echo "$codex_paths" | wc -l | tr -d ' ')
    fi
    codex_first=$(echo "$codex_paths" | head -1)

    if [ "$codex_count" -eq 0 ] || [ -z "$codex_first" ]; then
        # No codex installed yet — that's fine.
        :
    elif [ "$codex_count" -gt 1 ]; then
        errors+=("Multiple codex binaries found in PATH:")
        while IFS= read -r p; do
            [ -n "$p" ] && errors+=("  - $p")
        done <<< "$codex_paths"
        errors+=("  Remove duplicates so only the nvm npm global install remains.")
    elif [[ "$codex_first" != *".nvm"* ]]; then
        errors+=("codex is not installed via nvm npm: $codex_first")
        errors+=("  Remove this installation. update.sh will install via npm.")
    fi

    # ── Check 8: npm global modules are user-writable ─────────────────
    # With nvm, you should NEVER need sudo for npm. Root-owned files mean
    # someone ran "sudo npm install -g" at some point, which is wrong.

    if [ -n "$node_path" ]; then
        local npm_prefix npm_modules node_version
        npm_prefix=$(dirname "$(dirname "$node_path")")
        npm_modules="$npm_prefix/lib/node_modules"
        node_version=$(basename "$npm_prefix")

        if [ -d "$npm_modules" ]; then
            local root_owned
            root_owned=$(find "$npm_modules" -maxdepth 2 -user root 2>/dev/null | head -1 || true)
            if [ -n "$root_owned" ]; then
                errors+=("Some npm global modules are owned by root:")
                errors+=("  $root_owned")
                errors+=("")
                errors+=("  This happens when 'sudo npm install -g' was used. With nvm, sudo is never needed.")
                errors+=("")
                errors+=("  Recommended - Switch to latest LTS (clean slate, update.sh re-installs everything):")
                errors+=("    nvm install --lts && nvm uninstall $node_version && nvm use --lts")
                errors+=("")
                errors+=("  Not recommended - Fix permissions only (quick but doesn't address root cause):")
                errors+=("    sudo chown -R \$(whoami):staff $npm_modules")
            fi
        fi
    fi

    # ── Report errors ────────────────────────────────────────────────

    if [ "${#errors[@]}" -gt 0 ]; then
        echo "══ Environment Pre-Check Failed ══"
        echo ""
        echo "The following issues must be resolved before running update.sh:"
        echo ""
        for err in "${errors[@]}"; do
            echo "$err"
        done
        echo ""
        echo "After fixing these issues, rerun update.sh."
        return 1
    fi

    # ── Print warnings (non-blocking) ────────────────────────────────

    if [ "${#warnings[@]}" -gt 0 ]; then
        echo "══ Environment Warnings ══"
        echo ""
        for warn in "${warnings[@]}"; do
            echo "$warn"
        done
        echo ""
    fi

    return 0
}
