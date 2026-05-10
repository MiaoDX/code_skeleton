#!/bin/bash
# Task runner for parallel install/sync orchestration.
#
# Owns: backgrounding, log capture, per-task hint dispatch, failure tally.
# Caller owns: the task list, phase ordering (when to await, when to gate).
#
# Vocabulary:
#   task_init                              — call once before scheduling tasks.
#   task_run NAME FN [args...] [--hint H]  — spawn FN in background, capture log.
#   task_await NAME                        — wait, print section, run hint on fail.
#   task_await_group GROUP NAME...         — wait for many; one section, merged log.
#   task_skip NAME REASON                  — mark skipped (e.g. upstream gate failed).
#   task_succeeded NAME                    — query last result; 0 iff status is "ok".
#   task_summary                           — print failed list; return 1 iff any failed.
#
# Implementation note: parallel arrays + linear lookup (bash 3.2 has no
# associative arrays). With ~10 tasks the linear scan is irrelevant.

_TR_NAMES=()    # task name in insertion order
_TR_PIDS=()     # pid (or empty after await)
_TR_HINTS=()    # hint fn name (or empty)
_TR_STATUS=()   # "ok" | "fail" | "skip" | ""  (empty = pending)
_TR_FAILED=()   # names that failed, for summary
_TR_LOGDIR=""

task_init() {
    _TR_LOGDIR=$(mktemp -d)
    trap '[ -n "${_TR_LOGDIR:-}" ] && rm -rf "$_TR_LOGDIR"' EXIT
}

# _tr_index_of NAME — echo index of NAME in _TR_NAMES, return 1 if not found.
_tr_index_of() {
    local needle="$1" i
    for i in "${!_TR_NAMES[@]}"; do
        if [ "${_TR_NAMES[$i]}" = "$needle" ]; then
            echo "$i"
            return 0
        fi
    done
    return 1
}

_section() { echo ""; echo "══ $1 ══"; }

# task_run NAME FN [args...] [--hint HINT_FN]
task_run() {
    local name="$1"; shift
    local hint="" cmd=()
    while [ $# -gt 0 ]; do
        case "$1" in
            --hint) hint="$2"; shift 2 ;;
            *)      cmd+=("$1"); shift ;;
        esac
    done

    "${cmd[@]}" >"$_TR_LOGDIR/$name.log" 2>&1 &
    local pid=$!

    local idx
    if idx=$(_tr_index_of "$name"); then
        _TR_PIDS[$idx]="$pid"
        _TR_HINTS[$idx]="$hint"
        _TR_STATUS[$idx]=""
    else
        _TR_NAMES+=("$name")
        _TR_PIDS+=("$pid")
        _TR_HINTS+=("$hint")
        _TR_STATUS+=("")
    fi
}

# task_await NAME — always returns 0; caller queries via task_succeeded.
task_await() {
    local name="$1" idx
    if ! idx=$(_tr_index_of "$name"); then
        echo "task_await: no task named '$name'" >&2
        return 0
    fi
    local pid="${_TR_PIDS[$idx]}"
    if [ -z "$pid" ]; then
        echo "task_await: task '$name' has no pending pid" >&2
        return 0
    fi

    local status=0
    wait "$pid" || status=$?
    _TR_PIDS[$idx]=""

    _section "$name"
    cat "$_TR_LOGDIR/$name.log"

    if [ "$status" -eq 0 ]; then
        _TR_STATUS[$idx]="ok"
    else
        _TR_STATUS[$idx]="fail"
        _TR_FAILED+=("$name")
        local hint="${_TR_HINTS[$idx]}"
        if [ -n "$hint" ]; then
            "$hint" "$_TR_LOGDIR/$name.log"
        fi
    fi
    return 0
}

# task_await_group GROUP NAME1 [NAME2...]
# Wait for many tasks, print one section under GROUP, merge their logs.
# If any failed, GROUP is recorded as the failure (not individual tasks).
task_await_group() {
    local group="$1"; shift
    local any_failed=false name idx pid status

    _section "$group"
    for name in "$@"; do
        if ! idx=$(_tr_index_of "$name"); then
            echo "  ! task_await_group: no task '$name'" >&2
            any_failed=true
            continue
        fi
        pid="${_TR_PIDS[$idx]}"
        if [ -z "$pid" ]; then
            echo "  ! task_await_group: task '$name' has no pending pid" >&2
            any_failed=true
            continue
        fi

        status=0
        wait "$pid" || status=$?
        _TR_PIDS[$idx]=""

        if [ "$status" -eq 0 ]; then
            _TR_STATUS[$idx]="ok"
        else
            _TR_STATUS[$idx]="fail"
            any_failed=true
        fi

        cat "$_TR_LOGDIR/$name.log" 2>/dev/null
    done

    if $any_failed; then
        _TR_FAILED+=("$group")
    fi
    return 0
}

# task_skip NAME REASON — used when an upstream task failed.
task_skip() {
    local name="$1" reason="$2" idx
    if idx=$(_tr_index_of "$name"); then
        _TR_STATUS[$idx]="skip"
    else
        _TR_NAMES+=("$name")
        _TR_PIDS+=("")
        _TR_HINTS+=("")
        _TR_STATUS+=("skip")
    fi
    _section "$name"
    echo "  ! $reason"
}

# task_succeeded NAME — return 0 iff the named task's status is "ok".
task_succeeded() {
    local idx
    idx=$(_tr_index_of "$1") || return 1
    [ "${_TR_STATUS[$idx]}" = "ok" ]
}

# task_summary — print failed-section list. Returns 1 iff any failed.
task_summary() {
    if [ "${#_TR_FAILED[@]}" -gt 0 ]; then
        _section "Failed ✗"
        local n
        for n in "${_TR_FAILED[@]}"; do
            echo "  - $n"
        done
        return 1
    fi
    _section "Done ✓"
    return 0
}
