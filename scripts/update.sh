#!/bin/bash
set -euo pipefail

SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
SKIP_CODEX_RUNNING_CHECK=false

usage() {
    echo "Usage: ${0##*/} [--tmp-fix] [--skip-codex-running-check]"
}

# --tmp-fix → run only the dirty-patch script (scripts/tmp-fix.sh) and exit.
# Used to repair upstream-version drift (e.g. codex schema changes) without
# re-running the full update. Drop fixes from tmp-fix.sh when upstream catches up.
for arg in "$@"; do
    case "$arg" in
        --tmp-fix)
            exec "$SCRIPT_DIR/tmp-fix.sh"
            ;;
        --skip-codex-running-check)
            SKIP_CODEX_RUNNING_CHECK=true
            ;;
        -h|--help)
            usage
            exit 0
            ;;
        *)
            echo "Unknown option: $arg" >&2
            usage >&2
            exit 2
            ;;
    esac
done

# Source nvm if available (needed when running from bash but nvm is configured in zsh)
if [ -n "${NVM_DIR:-}" ] && [ -f "$NVM_DIR/nvm.sh" ]; then
    source "$NVM_DIR/nvm.sh"
    # Activate node if not in PATH (e.g., default version was uninstalled)
    if ! command -v node >/dev/null 2>&1; then
        nvm use --lts >/dev/null 2>&1 || nvm use node >/dev/null 2>&1 || true
    fi
fi

source "$SCRIPT_DIR/lib/ensure-no-running-codex.sh"
source "$SCRIPT_DIR/lib/ensure-clean-env.sh"
source "$SCRIPT_DIR/lib/task-runner.sh"
source "$SCRIPT_DIR/tasks/update-cli.sh"
source "$SCRIPT_DIR/tasks/update-skills.sh"
source "$SCRIPT_DIR/tasks/update-gstack.sh"
source "$SCRIPT_DIR/tasks/sync-local-commands-skills.sh"

ensure_clean_env
if [ "$SKIP_CODEX_RUNNING_CHECK" = true ]; then
    echo "  ! Skipping Codex running-process check by request."
else
    ensure_no_running_codex
fi

task_init

# ── Phase 1: independent tasks in parallel ───────────────────────────
task_run "Global CLI tools" run_global_cli_tools --hint print_npm_failure_hint
task_run "GSD workflow"     run_gsd_workflow

# Codex config runs sequentially after GSD workflow — both rewrite
# ~/.codex/config.toml, so racing them can clobber feature and [tui] updates.

skills_names=()

# ── Collect results, gating downstream tasks on CLI success ──────────
task_await "Global CLI tools"

if task_succeeded "Global CLI tools"; then
    task_run "MCP: fetch"     run_mcp_fetch
    task_run "Claude plugins" run_claude_plugins
    task_await "MCP: fetch"
    task_await "Claude plugins"
else
    task_skip "MCP: fetch"     "skipped because Global CLI tools failed"
    task_skip "Claude plugins" "skipped because Global CLI tools failed"
fi

task_await "GSD workflow"

task_run "Codex config" run_codex_config
task_await "Codex config"

task_run "GStack State" run_gstack_state
task_await "GStack State"

if task_succeeded "Global CLI tools"; then
    task_run "GStack" run_gstack --hint print_gstack_failure_hint
    task_await "GStack"
else
    task_skip "GStack" "skipped because Global CLI tools failed"
fi

# GSD scans ~/.codex/skills, and GStack rewrites the gstack skill links there.
# Keep those phases ahead of the remaining skill installers so home-level skill
# updates do not overlap.
for agent in claude-code codex; do
    n="skills-anthro-$agent";     skills_names+=("$n"); task_run "$n" run_skills_anthro     "$agent"
    n="skills-codex-$agent";      skills_names+=("$n"); task_run "$n" run_skills_codex      "$agent"
    n="skills-mattpocock-$agent"; skills_names+=("$n"); task_run "$n" run_skills_mattpocock "$agent"
done
task_await_group "Skills" "${skills_names[@]}"

# Local command/skill sync also writes to ~/.codex/skills. Run it last so local
# skill overrides win deterministically.
task_run "Local commands & skills" run_sync_local_commands_skills
task_await "Local commands & skills"

task_summary
