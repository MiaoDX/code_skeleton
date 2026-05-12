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

_manifest_entries() {
    local manifest="$1"
    local kind="$2"

    awk -v kind="$kind" '
        /^[[:space:]]*#/ { next }
        NF == 0 { next }
        $1 == kind { print $2 }
    ' "$manifest"
}

_manifest_has_entry() {
    local manifest="$1"
    local kind="$2"
    local value="$3"

    _manifest_entries "$manifest" "$kind" | grep -Fxq "$value"
}

_remove_stale_local_artifacts() {
    local manifest="$1"

    if [ ! -f "$manifest" ]; then
        echo "  ! missing local skill manifest: $manifest"
        return 1
    fi

    local removed=0 legacy_name stale_path install_root command_name

    while IFS= read -r command_name; do
        stale_path="$HOME/.claude/commands/$command_name"
        if [ -e "$stale_path" ]; then
            # Allowed destructive cleanup: this path is built from a repo-owned
            # manifest entry plus a known local agent install root.
            rm -rf "$stale_path"
            removed=$((removed + 1))
        fi
    done < <(_manifest_entries "$manifest" legacy-command)

    while IFS= read -r legacy_name; do
        for install_root in "$HOME/.codex/skills" "$HOME/.agents/skills" "$HOME/.claude/skills"; do
            stale_path="$install_root/$legacy_name"
            if [ -e "$stale_path" ]; then
                # Allowed destructive cleanup: legacy names are explicitly
                # listed in scripts/local-skill-manifest.txt.
                rm -rf "$stale_path"
                removed=$((removed + 1))
            fi
        done
    done < <(_manifest_entries "$manifest" legacy-skill)

    if [ "$removed" -gt 0 ]; then
        echo "  ✓ removed $removed stale local command/skill artifact(s)"
    fi
}

_check_root_skill_manifest() {
    local manifest="$1"
    local root_skills_src="$2"
    local missing=0 skill_dir skill_name

    while IFS= read -r skill_name; do
        skill_dir="$root_skills_src/$skill_name"
        if [ ! -f "$skill_dir/SKILL.md" ]; then
            echo "  ! manifest lists missing root skill: $skill_name"
            missing=$((missing + 1))
        fi
    done < <(_manifest_entries "$manifest" root-skill)

    if [ -d "$root_skills_src" ]; then
        for skill_dir in "$root_skills_src"/*; do
            [ -d "$skill_dir" ] || continue
            [ -f "$skill_dir/SKILL.md" ] || continue
            skill_name=$(basename "$skill_dir")
            if ! _manifest_has_entry "$manifest" root-skill "$skill_name"; then
                echo "  ! root skill missing from manifest: $skill_name"
                missing=$((missing + 1))
            fi
        done
    fi

    [ "$missing" -eq 0 ]
}

# Sync .claude/commands/*.md from this repo to:
#   ~/.claude/commands/   (Claude Code global commands — raw .md copy)
#   ~/.codex/skills/      (Codex skills — rendered via render_codex_skill)
run_sync_local_commands_skills() {
    local project_dir commands_src local_skill_manifest
    project_dir=$(cd "$SCRIPT_DIR/.." && pwd)
    commands_src="$project_dir/.claude/commands"
    local_skill_manifest="$project_dir/scripts/local-skill-manifest.txt"

    _remove_stale_local_artifacts "$local_skill_manifest" || return 1

    local claude_dest="$HOME/.claude/commands"
    local codex_dest="$HOME/.codex/skills"
    local synced=0 src_file filename name codex_name

    mkdir -p "$claude_dest"

    if [ -d "$commands_src" ]; then
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
            echo "  synced command: $name"
        done
    fi

    if [ "$synced" -eq 0 ]; then
        echo "  ! no .md files found in .claude/commands/"
    elif [ -d "$codex_dest" ]; then
        echo "  ✓ $synced local command(s) → ~/.claude/commands/ + ~/.codex/skills/"
    else
        echo "  ✓ $synced local command(s) → ~/.claude/commands/"
    fi

    # ── Sync local .claude/skills/* to ~/.agents/skills/ via npx skills ─
    local skills_src="$project_dir/.claude/skills"
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

    # ── Sync local skills/* (repo root) to Claude Code + Codex ─
    local root_skills_src="$project_dir/skills"
    if [ -d "$root_skills_src" ]; then
        local root_skills_codex_synced=0
        local root_skills_claude_synced=0
        local skill_dir skill_name
        if ! _check_root_skill_manifest "$local_skill_manifest" "$root_skills_src"; then
            return 1
        fi
        while IFS= read -r skill_name; do
            skill_dir="$root_skills_src/$skill_name"

            if npx -y skills add "$skill_dir" -g -y -a claude-code >/dev/null 2>&1; then
                root_skills_claude_synced=$((root_skills_claude_synced + 1))
            else
                echo "  ! failed to sync Claude Code skill: $skill_name"
            fi

            if [ -d "$codex_dest" ]; then
                # Copy contents in place so reruns update the existing skill
                # directory instead of nesting skill_dir/skill_dir.
                if ! _copy_dir_contents "$skill_dir" "$codex_dest/$skill_name"; then
                    return 1
                fi
                root_skills_codex_synced=$((root_skills_codex_synced + 1))
            fi
            echo "  synced skill: $skill_name"
        done < <(_manifest_entries "$local_skill_manifest" root-skill)
        if [ "$root_skills_claude_synced" -gt 0 ] || [ "$root_skills_codex_synced" -gt 0 ]; then
            echo "  ✓ $root_skills_claude_synced local skill(s) → Claude Code"
            echo "  ✓ $root_skills_codex_synced local skill(s) → ~/.codex/skills/"
        fi
    fi
}

if [[ "${BASH_SOURCE[0]}" == "$0" ]]; then
    SCRIPT_DIR=$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)
    run_sync_local_commands_skills "$@"
fi
