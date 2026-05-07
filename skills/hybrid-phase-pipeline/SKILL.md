---
name: hybrid-phase-pipeline
description: |
  Orchestrate the staged hybrid planning-to-execution workflow: grill-me or
  office-hours for idea shaping, docs/plans as the pre-execution source of
  truth, autoplan for hard review, optional to-issues for vertical slices, GSD
  ingest/plan for committed execution, GSD execute/verify for implementation,
  and tdd inside risky slices. Use when the user asks to combine Matt Pocock
  skills, gstack, and GSD; asks for a durable pipeline; mentions
  grill-me/office-hours/autoplan/to-issues/tdd/gsd together; or wants to move
  an idea from fuzzy concept to implemented phase without duplicating sources
  of truth.
---

# Hybrid Phase Pipeline

Use this skill to route a feature or project direction through the repo's staged
hybrid workflow without turning every idea into a full process marathon.

The core rule: **one source of truth per stage**.

- Before committed execution: `docs/plans/*.md` or GitHub issues are authoritative.
- During execution: `.planning/STATE.md` and `.planning/phases/*` are authoritative.
- After shipping: retrospectives, summaries, and verification reports are authoritative.

Do not create duplicate `.planning/phases/*` artifacts while the team is still
brainstorming in `docs/plans/*.md`.

## Stage Router

Start by classifying the user's current state.

### A. Fuzzy Idea

Use when the user is still deciding what to build, why it matters, or what the
scope should be.

Default path:

```text
grill-me -> docs/plans/<slug>.md
```

Use `office-hours` instead of or after `grill-me` when the question is about
product direction, wedge, audience, demand, or "is this worth building?"

Stop after the plan doc unless the user explicitly asks to continue.

### B. Draft Plan Exists

Use when a human-readable plan exists and the user wants hard review.

Default path:

```text
autoplan docs/plans/<slug>.md
```

`autoplan` is a review pipeline, not an implementation tool. It may refine the
plan, surface scope changes, and produce review logs. It must not start coding.

When the user approves the `autoplan` gate, reconcile the approved decisions back
into the same `docs/plans/<slug>.md` file before moving on. `~/.gstack` artifacts
are supporting evidence, restore points, and review logs; they are not the
handoff source of truth.

Approval means:

- update the plan in place with accepted scope, risk, test, DX, and execution
  changes
- keep or link any external `~/.gstack` artifacts only as evidence
- verify the plan file itself contains the approved acceptance criteria and GSD
  handoff trigger

If the only in-repo change after `autoplan` is a restore comment or appended
review report, do not hand off yet. First edit the body of the plan so the next
stage ingests the approved plan, not the review artifact.

Stop after the approval gate and in-place reconciliation unless the user
explicitly approves execution.

### C. Reviewed Plan, Not Yet Committed To Execution

Use when the plan is accepted but not yet under GSD.

Before `to-issues`, `gsd-ingest-docs`, or `gsd-plan-phase`, confirm that the
accepted plan lives in `docs/plans/<slug>.md`. Do not use a generated
`~/.gstack/...test-plan...md`, restore file, review log, or final-gate summary as
the canonical input unless the user explicitly asks to promote that artifact into
the plan file first.

Optional issue path:

```text
to-issues docs/plans/<slug>.md
```

Use `to-issues` when work should be split across multiple agents, tracked in
GitHub Issues, or made independently grabbable. Skip it when the work is small
enough for one GSD phase.

Then hand off:

```text
gsd-ingest-docs docs/plans/<slug>.md
# or
gsd-plan-phase <phase>
```

After this point, GSD owns execution truth.

### D. Committed GSD Phase

Use when `.planning/phases/<phase>/` exists and the user wants implementation.

Default path:

```text
gsd-execute-phase <phase>
gsd-verify-work <phase>
```

Use `tdd` inside individual slices when behavior needs to drive the code:

- new public interfaces
- MCP tools
- parsers and manifests
- scenario scoring
- artifact schemas
- regressions

`tdd` is not a phase planner. It is the implementation discipline for one slice.

## Default Pipeline

When the user asks for the whole durable pipeline, propose this compact sequence:

```text
1. grill-me
2. docs/plans/<feature>.md
3. autoplan
4. update docs/plans/<feature>.md in place after approval
5. to-issues (optional)
6. gsd-ingest-docs or gsd-plan-phase
7. gsd-execute-phase
8. tdd inside risky slices
9. gsd-verify-work
```

Do not run `office-hours` by default if `grill-me` already made the direction
crisp. Add `office-hours` only if value, wedge, audience, or demo framing is
still uncertain.

Do not run `to-issues` by default if one GSD phase can hold the work cleanly.

Do not run `tdd` globally. Use it where behavior should be specified through
public interfaces before code.

## Required Checkpoints

Stop and ask before crossing these boundaries:

1. **Pre-plan -> Review:** "Is this the plan file you want reviewed?"
2. **Review -> In-place update:** "Do you approve these review decisions, and
   should I update the plan file in place?"
3. **Review -> Issues/GSD:** "Do you approve this updated plan for execution?"
4. **Issues -> GSD:** "Do you want GitHub issue tracking, or go straight to GSD?"
5. **GSD plan -> Execute:** "Execute now, or stop after plan generation?"
6. **Local-dev gate:** if proof depends on real simulator, real Gateway, real VLM,
   Docker, GPU, or API keys, stop unless the current session is local and equipped.

## Output Shapes

### If Producing A Pre-Plan

Write to:

```text
docs/plans/<slug>.md
```

Include:

- problem / goal
- decisions already made
- non-goals
- smallest demo
- fuller demo
- acceptance criteria
- proposed vertical slices
- GSD handoff trigger

### If Producing A Workflow Recommendation

Return a compact routing table:

```text
Current state: <fuzzy | draft-plan | reviewed-plan | gsd-phase>
Recommended next step: <skill/stage>
Why: <one sentence>
Stop condition: <what should be true before the next stage>
```

### If Updating Repo Guidance

Update `AGENTS.md` and `CLAUDE.md` only. Do not scatter workflow rules across
README or architecture docs unless the user asks.

## Anti-Patterns

- Do not run every skill just because it exists.
- Do not create both `docs/plans/<slug>.md` and `.planning/phases/<slug>/` as
  active competing sources of truth.
- Do not use `autoplan` as a code refactor tool.
- Do not use `to-issues` after GSD execution has already started unless the
  user explicitly wants GitHub tracking added midstream.
- Do not use `tdd` to write all tests up front. Use one red-green-refactor loop
  per behavior.

## MolmoSpaces Pilot

For this repo, the pilot plan is:

```text
docs/plans/molmospaces-manipulation-spike.md
```

Recommended next sequence:

```text
autoplan docs/plans/molmospaces-manipulation-spike.md
update docs/plans/molmospaces-manipulation-spike.md in place after approval
to-issues docs/plans/molmospaces-manipulation-spike.md   # optional
gsd-ingest-docs docs/plans/molmospaces-manipulation-spike.md
gsd-execute-phase <created phase>
```

Use `tdd` inside the MolmoSpaces slices for scenario scoring, manifest parsing,
MCP tool contracts, artifact schemas, and regressions.
