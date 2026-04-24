#!/bin/bash

ensure_no_running_codex() {
    local current_pid parent_pid
    local -a rows=()

    current_pid=$$
    parent_pid=$PPID

    while IFS= read -r row; do
        rows+=("$row")
    done < <(
        ps -eo pid=,tty=,command= |
            awk -v current_pid="$current_pid" -v parent_pid="$parent_pid" '
                /(^|[[:space:]])codex([[:space:]]|$)|\/codex([[:space:]]|$)/ && $1 != current_pid && $1 != parent_pid { print }
            '
    )

    if [ "${#rows[@]}" -eq 0 ]; then
        return 0
    fi

    echo "  ! Refusing to update Codex config while Codex is already running."
    echo "  ! Older Codex sessions can rewrite ~/.codex/config.toml on exit and discard the new status line."
    echo "  ! Close these Codex sessions first, then rerun this script:"
    for row in "${rows[@]}"; do
        echo "    $row"
    done
    return 1
}
