# Refactor And Closeout

Use this reference for architecture/refactor routes, semantic commit boundaries,
documentation status checks, and final parked-todo reporting.

## Architecture Or Refactor Goal

Use when the user asks to improve architecture, refactor a module, fix broad
known issues, run `improve-codebase-architecture`, or stop endless cleanup
loops.

Default path:

```text
create or read refactor scope gate
architecture scan               # report-only unless gate accepts P0/P1 items
TDD or diagnosis                 # only when accepted checklist needs proof first
execute accepted P0/P1 slices
check doc status and run intuitive-doc cleanup when human docs drift
record P2/Parked ideas instead of implementing them
```

The refactor scope gate may be produced inline or by a dedicated refactor skill.
It is the source of truth for the pass and must name:

- target module or boundary
- status marker: `DONE`, `CONTINUE`, `REOPEN`, or `PARK`
- accepted severities
- accepted issue checklist
- parked issues
- required evidence level
- affected human docs or explicit "no doc impact expected"
- persistent gate file, usually `docs/plans/refactor-<target>.md`
- stop condition

Use native subagents for report-only scans, stale-path searches, test discovery,
and independent verification probes when available. Use `skill-runner`/tmux for
broad or long-running `$intuitive-refactor` execution. Use worker subagents for
direct edits only when the accepted checklist splits into disjoint ownership
scopes.

Once implementation starts, do not keep discovering and implementing new P2
cleanup. Add newly discovered work only when it is a P0/P1 regression found
while verifying the accepted checklist.

On repeated runs of the same refactor prompt, read the persistent gate first.
If status is `DONE` and evidence remains green, stop instead of rescanning for
fresh cleanup. Park P2-only taste or "could be cleaner" findings unless the user
expands scope or real usage shows repeated failure in that area.

## Documentation Status

For significant code changes and every big refactor, compare the changed
implementation surface to `README.md`, `ARCHITECTURE.md`, `STATUS.md`, and
`docs/human/**` before closeout.

Use `$intuitive-doc guard` for focused changed-file checks, or
`$intuitive-doc cleanup <scope>` when the refactor changed public contracts,
commands, package/module layout, examples, proof artifacts, or human docs.

If human-surface docs drifted, update them to match current implementation. If
human docs became AI coding guidance, process history, or obsolete detail, move
or remove them according to `$intuitive-doc` cleanup rules. Ask before broad
moves/deletions, ambiguous external consumers, or protected docs outside the
accepted scope.

If work touched domain terms, durable boundaries, or context-backed acceptance
criteria, re-check relevant `CONTEXT.md` or `CONTEXT-MAP.md`. Update it through
`grill-with-docs` semantics when terms changed; otherwise report it was checked
and left unchanged.

## Semantic Commits

For durable implementation or refactor runs that change local code, semantic
commits are the default recoverability boundary unless the user says not to
commit, the stop condition is review-only/plan-only, repo instructions forbid
commits, unrelated dirty changes prevent safe staging, or the unit has
unresolved blockers.

The default is operational, not aspirational: before final closeout, either
commit the verified owned changes or record the exact current instruction,
repo/phase policy, or unsafe staging blocker that prevents it. Do not leave
owned implementation, docs, tests, or status updates uncommitted just because
the run started from an inherited dirty worktree.

When resuming from another agent's handoff, do not let an unquoted note like
"commits disabled" override this default by itself. First identify the source of
the disablement:

- current user instruction, repo policy, or active phase rule: obey it and
  report it;
- unsafe staging because unrelated dirty changes overlap owned files: split the
  staging or leave the affected slice uncommitted with that precise reason;
- vague inherited note with no source: ignore it and create semantic commits
  after focused proof.
- inherited dirty changes that match the accepted scope: inspect, verify, and
  commit them as the owned slice; do not treat "another agent started it" as a
  commit blocker.

Dirty worktrees are normal in agent handoffs. They require selective staging,
not automatic commit suppression. Exclude unrelated local artifacts, generated
outputs, model weights, worktree folders, and user-owned edits; commit only the
owned slice whose proof you can name.

Unrelated dirty files outside the owned slice are not a reason to skip the
commit. Leave them untouched and unstaged, then mention them only if useful for
review. If unrelated edits are in the same files, inspect the diff carefully and
use path/hunk-specific staging where safe; if hunk separation is not safe, keep
that precise file out of the commit and explain the blocker.

Do local slice commits along the way. After each coherent code change with its
focused proof, inspect the diff, stage only owned files, commit with a semantic
message, and then continue the flow from that clean checkpoint. Do not defer all
commits until closeout; that leaves the run with too many changed files and makes
review/recovery harder.

Use multiple commits when the work naturally splits into independently
reviewable plan, implementation, test, docs, or verification units. Use one
commit when the diff is small and has one coherent intent. If a run accidentally
accumulates several slices before the first commit, split the staged diff if it
is practical; otherwise create one coherent catch-up commit only after the full
owned diff has focused proof.

A semantic commit boundary must have:

- one coherent intent a reviewer could accept or revert independently
- owned files only
- relevant targeted proof, or a note that proof is not applicable for a
  docs/planning-only unit
- no known unresolved blocker
- canonical artifact/progress updated when the unit changes handoff state

Useful boundaries:

- after `autoplan` decisions are reconciled into `docs/plans/<slug>.md`
- after `gsd-ingest-docs` creates or merges roadmap scope
- after `gsd-plan-phase` creates executable phase plan
- after each coherent implementation slice and focused tests
- after standalone test/verification harness lands
- after `simplify` changes code outside the preceding slice
- after material verification, docs/status, or closeout updates

Before each commit, inspect `git status` and the staged diff, run or record
proof, and include repo co-author trailers when required. If a boundary is too
mixed, split it or leave it uncommitted with a compact reason.

Closeout must not report "commits disabled" unless the disablement came from a
current user instruction, repo policy, phase rule, or explicit unsafe-staging
blocker. Otherwise include the commit id(s) created during the flow.

Fallback commit message style when no local style is obvious:

- `docs(plan): ...`
- `chore(workflow): ...`
- `feat(<area>): ...`
- `fix(<area>): ...`
- `refactor(<area>): ...`
- `test(<area>): ...`
- `docs(<area>): ...`

## Implementation Closeout And Parked Todos

Before final answer after implementation/refactor, inspect the canonical
artifact: `docs/plans/<slug>.md`, a refactor scope gate, `.planning/STATE.md`,
or the active phase plan. Extract anything explicitly parked, deferred,
out-of-scope, future-only, or left for focused follow-up.

Also include newly discovered but intentionally unimplemented work from
execution notes, simplify/review output, and verification gaps.

Always show parked work. If empty, say:

```text
Parked todos: none found in the canonical artifact or implementation notes.
```

Parked-todo shape:

```text
Parked todos:
- <item> - parked because <reason>; source: <plan/review/doc>; unpark when <trigger>
```

If `autoplan` ran, include the autoplan scope-change hint. Keep accepted scope
changes separate from parked/deferred work: accepted changes are now in the
implemented plan, parked items are not done.
