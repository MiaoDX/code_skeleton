#!/bin/bash

_TASK_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)
source "$_TASK_DIR/../lib/codex-skill-adapter.sh"
unset _TASK_DIR

_copy_dir_contents() {
    local src_dir="$1"
    local dest_dir="$2"

    if [ -e "$dest_dir" ] && [ ! -d "$dest_dir" ]; then
        echo "  ! destination exists and is not a directory: $dest_dir"
        return 1
    fi

    mkdir -p "$dest_dir"
    cp -R "$src_dir"/. "$dest_dir"/
}

# Sync .claude/commands/*.md from this repo to:
#   ~/.claude/commands/   (Claude Code global commands — raw .md copy)
#   ~/.codex/skills/      (Codex skills — rendered via render_codex_skill)
run_sync_local_commands_skills() {
    local devkit_dir commands_src
    devkit_dir=$(cd "$SCRIPT_DIR/.." && pwd)
    commands_src="$devkit_dir/.claude/commands"

    if [ ! -d "$commands_src" ]; then
        echo "  ! no .claude/commands directory — skipping"
        return 0
    fi

    local claude_dest="$HOME/.claude/commands"
    local codex_dest="$HOME/.codex/skills"
    local synced=0 src_file filename name codex_name

    mkdir -p "$claude_dest"

    for src_file in "$commands_src"/*.md; do
        [ -f "$src_file" ] || continue

        filename=$(basename "$src_file")
        name="${filename%.md}"
        codex_name="${name//_/-}"

        cp "$src_file" "$claude_dest/$name.md"

        if [ -d "$codex_dest" ]; then
            render_codex_skill "$src_file" "$codex_dest/$codex_name" "$codex_name"
        fi

        synced=$((synced + 1))
        echo "  synced: $name"
    done

    if [ "$synced" -eq 0 ]; then
        echo "  ! no .md files found in .claude/commands/"
    elif [ -d "$codex_dest" ]; then
        echo "  ✓ $synced local command(s) → ~/.claude/commands/ + ~/.codex/skills/"
    else
        echo "  ✓ $synced local command(s) → ~/.claude/commands/"
    fi

    # ── Sync local .claude/skills/* to ~/.agents/skills/ via npx skills ─
    local skills_src="$devkit_dir/.claude/skills"
    if [ -d "$skills_src" ]; then
        local skills_synced=0
        for skill_dir in "$skills_src"/*; do
            [ -d "$skill_dir" ] || continue
            [ -f "$skill_dir/SKILL.md" ] || continue

            local skill_name
            skill_name=$(basename "$skill_dir")

            if npx -y skills add "$skill_dir" -g -y -a codex >/dev/null 2>&1; then
                skills_synced=$((skills_synced + 1))
                echo "  synced skill: $skill_name"
            else
                echo "  ! failed to sync skill: $skill_name"
            fi
        done
        if [ "$skills_synced" -gt 0 ]; then
            echo "  ✓ $skills_synced local skill(s) → ~/.agents/skills/ (via skills CLI)"
        fi
    fi

    # ── Sync local skills/* (repo root) to ~/.codex/skills/ for Codex ─
    local root_skills_src="$devkit_dir/skills"
    if [ -d "$root_skills_src" ] && [ -d "$codex_dest" ]; then
        local root_skills_synced=0
        for skill_dir in "$root_skills_src"/*; do
            [ -d "$skill_dir" ] || continue
            [ -f "$skill_dir/SKILL.md" ] || continue

            local skill_name
            skill_name=$(basename "$skill_dir")

            # Copy contents in place so reruns update the existing skill directory
            # instead of nesting skill_dir/skill_dir on repeated syncs.
            if ! _copy_dir_contents "$skill_dir" "$codex_dest/$skill_name"; then
                return 1
            fi
            root_skills_synced=$((root_skills_synced + 1))
            echo "  synced skill: $skill_name"
        done
        if [ "$root_skills_synced" -gt 0 ]; then
            echo "  ✓ $root_skills_synced local skill(s) → ~/.codex/skills/"
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
    run_sync_local_commands_skills "$@"
fi
