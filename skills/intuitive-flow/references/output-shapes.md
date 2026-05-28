# Output Shapes

Use these compact shapes for `intuitive-flow` responses and artifacts. Prefer
the files in `templates/` when creating durable artifacts.

## Upfront Route Brief

Return before the first non-trivial artifact or edit:

```text
Current state: <classification>
Selected path: <stage/skill sequence>
Why: <one sentence>
Bypassed/left behind: <stage - reason; stage - reason>
Execution surface: <main session direct | tmux worker per sub-phase | native subagents if stable/non-Codex>
Babysitter cadence: <none | every N min based on task risk/proof duration>
Commit rhythm: <semantic commits enabled | disabled because ...>
Stop gate: <repo command/artifact deciding complete | blocked | continue, or "none">
Stop/continue point: <what happens before the next checkpoint>
```

For tiny direct work, one sentence is enough, but still name the selected path
when heavier routing was plausible.

## Pre-Plan

Write to:

```text
docs/plans/<slug>.md
```

Include:

- problem / goal
- idea-shaping mode: direct or auto-guided
- decisions already made
- idea shaping decisions table when auto-guided mode was used
- source evidence
- non-goals
- smallest demo
- fuller demo
- success criteria and acceptance criteria
- verification expectations
- proposed vertical slices
- risks and assumptions
- GSD handoff trigger:
  - existing phase -> `gsd-plan-phase <phase> --prd docs/plans/<slug>.md`
  - missing `.planning/` or missing roadmap phase -> create/use ingest manifest,
    run `gsd-ingest-docs --manifest <manifest>`, then
    `gsd-plan-phase <created-phase> --prd docs/plans/<slug>.md`

## Workflow Recommendation

```text
Current state: <fuzzy | draft-plan | reviewed-plan | gsd-phase | changed-code | refactor-goal>
Recommended next step: <skill/stage>
Why: <one sentence>
Stop condition: <what should be true before the next stage>
```

## Implementation Closeout

Include:

- what changed
- verification run and result
- documentation status check and any doc updates/moves/removals when code or
  refactor work changed human-facing truth
- semantic commit ids created, or why commits were disabled
- stop gate checked, with result when this was a durable auto-run
- `autoplan` scope changes if `autoplan` ran or was checked
- `STATUS.md` check/update result for non-trivial durable runs
- Serena memory check/update result when Serena memories are configured, or
  `not configured/not available`
- parked todos, always, including `none found`
- verification explicitly not run
- worker handoff inspected when execution ran in tmux
- worker drift or timeout intervention, including revised goal, when one
  occurred

Do not bury parked work behind "follow-ups available"; make it visible.

## Repo Guidance Updates

When updating root agent guidance, update `AGENTS.md` and `CLAUDE.md` only. Do
not scatter workflow rules across README or architecture docs unless the user
asks.
