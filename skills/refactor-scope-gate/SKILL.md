---
name: refactor-scope-gate
description: Set a bounded refactor goal before architecture or cleanup work starts. Use whenever the user wants to improve architecture, refactor safely, "fix all big issues", avoid endless refactors, decide what is in/out of scope, classify P0/P1/P2/Parked findings, or define the tests and stop condition before changing code. This skill works standalone and can also be combined with architecture scanners, planning pipelines, TDD, or diagnosis skills.
---

# Refactor Scope Gate

Use this skill to set the goal, scope, evidence, and stop condition for a
refactor before code changes start.

This skill is standalone. If no other skill is invoked, it should gather enough
repo context itself to produce a scope gate, write/update the persistent gate
file when execution is requested, and stop or execute according to the accepted
checklist.

It can also be combined with other skills. In that case, this skill owns the
scope gate and stop condition; the other skill provides candidate findings,
proof, planning, or implementation.

## Operating rule

Start report-only.

Do not edit production code until all of these are explicit:

- the target module or seam
- the accepted issue checklist
- which issue severities are in scope
- the required evidence level
- the stop condition
- the persistent gate file, if this is more than advice

The goal is not "no more possible refactors." Any healthy project will always
have possible refactor points. The goal is "the accepted P0/P1 checklist is
green, and lower-priority ideas are parked instead of implemented by drift."

If the user asks for a full autonomous run, continue only through safe,
deterministic gates. Pause before local-only, paid-provider, Docker/Gateway, or
human-judgment gates unless the user explicitly authorized them.

## Persistent state rule

Skills are not stateful by themselves. Chat history, agent memory, and previous
command output are not reliable stop conditions across repeated runs. Persist
the refactor gate in the repo when the user asks for execution, repeated runs,
or "all big known issues."

Use one source of truth:

- If a relevant `docs/plans/<slug>.md` already exists, update that file.
- Otherwise create `docs/plans/refactor-<target-slug>.md`.
- Do not create a second active plan for the same seam.
- Do not use `~/.gstack`, temporary logs, chat memory, or commit history as the
  handoff source of truth. They can be evidence, not the gate.

The gate file must mark its status explicitly. Use these exact status values:

- `DONE` — accepted checklist is complete and evidence is still green.
- `CONTINUE` — accepted P0/P1 item remains incomplete.
- `REOPEN` — user explicitly expanded scope or new evidence shows a P0/P1
  regression.
- `PARK` — no active P0/P1 work remains; only P2/Parked ideas exist.

When creating or updating the gate file, write the status in both places:

- YAML frontmatter `status: <DONE|CONTINUE|REOPEN|PARK>` for quick parsing
- `## Status` for human scanning

The gate file should contain this shape:

```markdown
---
refactor_scope: <target-slug>
status: CONTINUE
accepted_severities:
  - P0
  - P1
last_verified: null
---

# Refactor Scope: <target>

## Status

CONTINUE

## Target

## Accepted Severities

## Accepted P0/P1 Checklist

## Parked P2 / Future Ideas

## Evidence Ladder

## Stop Condition

## Execution Log
```

On a repeated run, read the existing gate file first. Check the frontmatter
`status` first, then `## Status` if the frontmatter is missing. Classify the
current state as:

- **DONE** — accepted checklist is complete and evidence is still green; stop.
- **CONTINUE** — accepted P0/P1 item remains incomplete; continue that item.
- **REOPEN** — the user explicitly expands scope or new evidence shows a P0/P1
  regression; update the same gate file.
- **PARK** — only P2/Parked ideas remain; record them and stop.

## Severity gate

Classify every finding before implementation:

| Severity | Meaning | Default action |
| --- | --- | --- |
| P0 | Current breakage, data loss, security exposure, deploy failure, or a verifier that gives false green on real failure | Fix now |
| P1 | A real correctness, source-of-truth, or testability gap that can hide failure in the named seam | Fix now |
| P2 | Maintainability, duplication, naming, drift risk, or "this could be cleaner" without current failure evidence | Park unless the user explicitly opts in |
| Parked | Speculative, cross-seam, broad cleanup, taste preference, or future-proofing | Record only |

When the user's prompt says "all big known issues," interpret "big" as P0/P1
unless they explicitly widen the scope.

After implementation starts, do not add newly discovered P2/Parked items to the
active checklist. Only add a new item mid-run if it is a P0/P1 regression found
while verifying the accepted checklist.

## Confidence ladder

Use these levels when classifying a proposed change:

| Level | Name | Evidence |
| --- | --- | --- |
| L0 | Static | formatting, lint, whitespace, importable tooling |
| L1 | Unit/mock | fast unit and mock-backed behavior tests |
| L2 | Contract | frozen schemas, fixtures, CLI/report output contracts |
| L3 | Mock regression | baseline-vs-candidate behavior capture using mock providers |
| L4 | Local simulator | real simulator / rendering / physics validation |
| L5 | Local Gateway/provider | real OpenClaw/Gateway/VLM/API validation |
| L6 | Navigator harness | coding-agent-in-the-loop task run with curated metrics |

## Workflow

### 1. Orient and classify

Read the user's goal and identify:

- target area or module
- target seam, if known
- whether the request is bug/perf shaped, architecture shaped, or feature shaped
- user-visible behavior that must not regress
- what "done" would prove from a caller's perspective
- minimum required confidence level
- whether any evidence is local-only, paid, slow, or environment-sensitive

If repo-local docs exist, read the agent config first:

- `docs/agents/domain.md`
- `docs/agents/issue-tracker.md`
- `docs/agents/triage-labels.md`

Then read the repo's required orientation docs before making claims.

Look for an existing gate before proposing new work:

- `docs/plans/*refactor*.md`
- `docs/plans/*architecture*.md`
- a user-provided plan path
- GSD phase artifacts if the refactor is already a committed phase

If the target seam is unclear, stop after a report-only map. Do not wander
through the whole repo looking for unrelated cleanup.

### 2. Decide whether to stay standalone or hand off

By default, stay standalone: produce the scope gate, write/update the persistent
gate file when appropriate, and stop before implementation unless the user has
approved execution.

Use another skill only when it materially improves the current pass:

- unclear architecture or seam quality -> use an architecture scanner in
  report-only mode
- missing behavior coverage -> use TDD to add one public-interface proof
  before refactoring
- bug, flake, perf regression, or known blind spot -> diagnose to build
  a reproducible feedback loop first
- large feature or harness program -> create a PRD, then issues
- existing issue queue or TODO grooming -> triage

Do not split into issues before the parent plan or PRD is shaped enough to split
into vertical slices. Do not require any other skill just because it exists.

### 3. Produce the scope gate

Before implementation, present this compact gate:

```markdown
## Refactor Scope Gate

- Target:
- Change type:
- Current status:
- Accepted severities:
- Accepted issue checklist:
- Parked issues:
- Minimum confidence level:
- Existing evidence:
- Missing evidence:
- Local-only gates:
- Recommended next skill:
- Persistent gate file:
- Stop condition:
```

The stop condition must be concrete enough that an agent can stop even if it can
still imagine more cleanup. Good stop conditions look like:

- "All accepted P0/P1 items pass `npm run test:publish-rules` and
  `npm run quality:check`; P2 findings are recorded only."
- "Stop after report-only architecture candidates; wait for the user to pick
  one candidate."
- "Stop before implementation because the next proof requires real Gateway
  access."

If implementation is approved, write or update the persistent gate file before
editing production code. If there are accepted P0/P1 items, mark it
`CONTINUE`. If the scan finds only P2/Parked ideas, mark it `PARK` and stop.

### 4. Execute one vertical slice

When the user approves action, work in one tracer bullet:

1. Add or identify the proof first.
2. Watch the proof fail if adding new coverage.
3. Apply the smallest implementation/refactor.
4. Run the required ladder levels.
5. Summarize evidence and residual risk.

Never batch unrelated refactors. If a proposed architecture cleanup touches
multiple seams, split it with `/to-issues` or park the extra seams.

### 5. Close the loop

Before declaring completion, audit the accepted checklist against real evidence:

- every P0/P1 item has a concrete change or a documented "no change needed"
  reason
- every required evidence level has command output or a stated skipped gate
- every P2/Parked item is recorded and not silently implemented
- no unapproved new refactor work was added after implementation began

Update the gate file with the final checklist status, evidence commands, skipped
gates, and parked ideas. Also update both status markers:

- mark `DONE` when the accepted checklist is complete and evidence is green
- mark `CONTINUE` when accepted P0/P1 work remains
- mark `PARK` when only lower-priority ideas remain
- mark `REOPEN` only when the user explicitly widens scope or new P0/P1 evidence
  invalidates a previous `DONE`

## Suggested repo command naming

Prefer a `verify::*` namespace for deterministic safety gates:

- `verify::static`
- `verify::mock`
- `verify::contract`
- `verify::regression-mock`
- `verify::sim-local`
- `verify::openclaw-local`
- `verify::navigator`
- `verify::full-local`

Reserve `harness::*` for a specific agent/simulator harness, not generic lint
or unit-test commands.

If the repo has different commands, use the repo's existing names and map them
to ladder levels in the safety plan.

## Suggested prompt

Use this shape when the user wants a bounded architecture pass:

```text
Run $refactor-scope-gate.

Scope: one named module/seam only.
Start report-only.
Load any existing docs/plans/refactor-*.md or architecture plan first.
Classify findings as P0/P1/P2/Parked.
Implement only accepted P0/P1 items.
Write/update one persistent gate file in docs/plans/.
Record P2/Parked items there instead of implementing them.
Stop when the accepted P0/P1 checklist passes the required confidence ladder.
Commit each coherent slice.
```

If the user combines this with an architecture scanner, add:

```text
Use the scanner only for report-only candidate discovery. The accepted checklist
and stop condition still come from the refactor scope gate.
```

## Output when only advising

If the user is still discussing strategy, do not edit files. Return:

- recommended command namespace
- proposed confidence ladder
- current/persistent status, if a gate file exists
- accepted severity threshold
- concrete stop condition
- whether a persistent gate file should be created or updated
- which optional skill, if any, should be used next
- which part should become a PRD or issue only if it is large enough

## Completion summary

After action, report:

- files changed, if any
- persistent gate file path and status
- accepted checklist status
- parked issues, if any
- ladder levels run and results
- gates skipped and why
- whether the change is safe for AFK agent pickup, human review, or local
  validation
