---
name: intuitive-flow
description: |
  Orchestrate a staged idea-to-execution workflow across planning, review,
  GSD handoff, implementation, cleanup, and verification. Use when the user asks
  for fuzzy idea shaping, durable planning, implementation from a plan, Matt
  Pocock skills + gstack + GSD together, broad refactor routing, or one coherent
  source of truth from idea to verified work.
---

# Intuitive Flow

Route work through the smallest staged workflow that preserves a clear source of
truth. This skill is an orchestrator: use downstream skills for their own
mechanics, and keep canonical route decisions in the main session.

## Read First

Load only the reference needed for the selected route:

| Need | Read |
| --- | --- |
| Source-of-truth, `STATUS.md`, `CONTEXT.md`, provenance, phase granularity | `references/source-of-truth.md` |
| Fuzzy idea shaping, single plan-file intake, `autoplan` precheck/reconciliation | `references/plan-intake-and-autoplan.md` |
| GSD ingest vs plan-phase routing, committed phase execution, `simplify` scope | `references/gsd-handoff.md` |
| Whole-run preflight, soft continuation vs hard stop, checkpoint policy, tmux/goal/clear policy | `references/checkpoints-and-auto-run.md` |
| Broad refactor route, semantic commits, doc cleanup, parked-todo closeout | `references/refactor-and-closeout.md` |
| Exact response and artifact templates | `references/output-shapes.md` and `templates/` |

If a route crosses multiple concerns, read the relevant references just before
the boundary. Do not preload every reference by default.

## Core Invariants

- Keep one source of truth per stage: `docs/plans/*.md` or GitHub issues before
  committed execution, `.planning/STATE.md` and `.planning/phases/*` during GSD,
  and verification/summary artifacts after shipping.
- Use a single `docs/plans/<slug>.md` as the canonical pre-GSD plan. Treat a
  single plan-like file under `docs/adr/`, `docs/adrs/`, or `docs/human/` as
  source evidence to refactor into `docs/plans/`, not as the review ledger.
- Do not implement a plan-backed request until `autoplan` evidence exists and
  accepted decisions have been reconciled into the canonical plan. Tiny direct
  edits that are not using a plan as source of truth may bypass this.
- Do not create competing `.planning/phases/*` artifacts while the team is still
  brainstorming in `docs/plans/*.md`.
- Check `CONTEXT.md` or `CONTEXT-MAP.md` when domain terms, durable boundaries,
  or context-backed acceptance criteria matter. Context files are evidence, not
  PRDs or execution ledgers.
- Ask only for hard-stop decisions. Auto-continue routine, reversible, or
  already-implied choices during a confirmed durable run.
- Keep the main session as the control plane for durable multi-stage runs.
  Route stateful execution through `skill-runner`/tmux workers by default so
  host-local `/goal`, `/compact`, `/clear`, or equivalent context controls stay
  isolated from route decisions and supervision history.
- For durable runs that change local code, create semantic commits along the
  way after each coherent proof-backed slice. Do not wait until the entire flow
  is done unless commits are explicitly disabled or staging cannot be made safe.
- Verify before completion. For implementation/refactor work, report tests or
  verification run, doc-status result when human-facing truth changed, and parked
  todos even when none were found.

## Route Brief

Before non-trivial artifacts or edits, show a compact route brief. For tiny
direct work, one sentence is enough.

```text
Current state: <fuzzy idea | draft plan | reviewed plan | GSD phase | changed code | refactor goal | direct implementation>
Selected path: <stage or skill sequence>
Why: <one sentence>
Bypassed/left behind: <stage - reason; stage - reason>
Execution surface: <main session direct | tmux worker per sub-phase | native subagents>
Babysitter cadence: <none | every N min based on task risk/proof duration>
Commit rhythm: <semantic commits enabled | disabled because ...>
Stop/continue point: <where work pauses or what will run now>
```

Name plausible but skipped stages such as `grill-me`, `office-hours`,
`autoplan`, `to-issues`, GSD handoff, `simplify`, or verification. This makes
shortcuts visible without turning every task into a ceremony.

## Stage Router

Start by classifying the user's current state. Then read the matching reference
and run the shortest safe route.

| Current state | Default route | Reference |
| --- | --- | --- |
| Fuzzy idea | `grill-me` or auto-guided shaping -> `docs/plans/<slug>.md`; add `office-hours` when product/wedge/demand is unclear | `plan-intake-and-autoplan.md` |
| Draft plan exists | single plan-file intake if needed -> `gstack-autoplan docs/plans/<slug>.md` -> reconcile accepted decisions into the plan | `plan-intake-and-autoplan.md` |
| Reviewed plan, not under GSD | pass `autoplan` precheck -> optional `to-issues` -> `gsd-plan-phase --prd` or manifest + `gsd-ingest-docs` then `gsd-plan-phase` | `gsd-handoff.md` |
| Committed GSD phase | `gsd-execute-phase <phase>` -> `simplify <changed-scope>` -> `gsd-verify-work <phase>` | `gsd-handoff.md` |
| Architecture/refactor goal | create/read refactor scope gate -> execute accepted P0/P1 slices -> doc-status cleanup -> parked-todo closeout | `refactor-and-closeout.md` |
| Changed code cleanup | `simplify <changed-scope>` -> rerun relevant proof | `gsd-handoff.md` |
| Direct concrete edit | implement locally -> focused verification -> closeout; bypass planning stages with reason | `output-shapes.md` as needed |

For whole-flow or durable auto-runs, first read
`references/checkpoints-and-auto-run.md` and confirm the run contract unless the
latest user message already supplied goal, success criteria, stop condition, and
boundaries and told you to use them as-is.

## Delegation

Keep the main session responsible for route decisions, canonical artifact edits,
integration, and final synthesis.

For durable multi-stage runs, default to a control-plane split:

- Main session: route, decide, inspect worker artifacts/diffs/logs, verify
  claims, and synthesize the next stage.
- Worker tmux session: execute one bounded sub-phase with its own stop
  condition, optional host-local `/goal`, and disposable context.
- Babysitter steering: choose a review cadence per worker from expected proof
  duration, risk, and artifact rhythm. Let healthy long-running refactors
  continue, but stop or steer a worker that has no durable progress, loops,
  broadens scope, or pursues the wrong artifact. Inspect captured
  logs/diff/artifacts before relaunching with a corrected goal or stopping for a
  hard decision.

Tiny direct edits and read-only probes may stay in the main session. Do not use
`/goal clear` or `/clear` in the main session while an active flow depends on
conversation context. If context pressure appears in the main session, prefer a
handoff-style `/compact` and keep canonical artifacts current.

| Work type | Preferred executor |
| --- | --- |
| Independent read-heavy probes | native subagents when available |
| Verification-heavy log/test inspection | native subagents when available |
| Bounded disjoint edits | native worker subagents with explicit file ownership |
| Stateful, interactive, durable, or long-running skill pipelines | `skill-runner` / tmux worker per sub-phase |
| Canonical source-of-truth edits and route decisions | main session |

For `skill-runner`, inspect compact artifacts such as `result.md`, `eval.md`,
`last-message.md`, targeted logs, the actual diff, and verification evidence
before trusting final status.

When a worker uses `/goal`, clear or close that goal inside the worker after the
sub-phase leaves durable state. Prefer exiting the worker over clearing and
continuing in the same terminal. The main session then reads the handoff and
decides the next worker scope.

Worker handoff shape:

```text
Scope:
Changed files:
Decisions made:
Verification:
Open risks:
Suggested next action:
```

## Hard Stops

Stop and ask the user when a choice would materially change:

- target user, demand premise, narrowest wedge, or product direction
- scope boundary, public contract, data model, phase split, or roadmap ownership
- security, privacy, paid infrastructure, external-service dependency, or API key use
- destructive action, broad file moves/deletions, or proof requiring unavailable
  local hardware/services such as Docker, GPU, real Gateway, real simulator, or API keys
- conflicting locked docs/ADRs or multiple plausible GSD phase matches

During a confirmed durable run, auto-answer soft continuations that preserve the
accepted plan, restate known premises, follow repo conventions, run normal
review/test/verification steps, or choose a reversible low-risk default.

## Commit Rhythm

Semantic commits are enabled by default when a durable implementation or
refactor run changes local code and repo/user instructions do not disable
commits. Commit as the flow progresses after each coherent proof-backed code
slice, then continue from that clean boundary instead of accumulating a large
end-of-run diff. For docs-only or review-only work, leave commits disabled
unless the user asked for them.

Treat inherited handoff notes such as "commits disabled" or "do not commit" as
claims to verify, not as binding instructions, unless they clearly quote the
current user, repo guidance, or a hard technical blocker. On resume, check the
current user request, repo instructions, and `git status`. If commits are still
safe, restore the default semantic-commit rhythm; if not, name the exact blocker
and keep it narrow, such as "unrelated dirty files prevent safe staging of this
slice."

Commit only owned files. Before each commit, inspect `git status` and the staged
diff, run or record the relevant proof, and use a semantic message such as
`feat(<area>): ...`, `fix(<area>): ...`, `refactor(<area>): ...`, or
`test(<area>): ...`. If unrelated dirty changes, unresolved blockers, or user
instructions make a slice commit unsafe, leave it uncommitted and record the
reason in the route brief or closeout.

Read `references/refactor-and-closeout.md` before creating commits during this
workflow.

## Closeout

Use `references/output-shapes.md` for exact shapes. Implementation/refactor
closeout must include:

- what changed
- verification run and result, or what was not run
- documentation status check when human-facing truth changed
- semantic commit ids created, or why commits were disabled
- `autoplan` scope changes if `autoplan` ran or was checked
- `STATUS.md` check/update result for non-trivial durable runs
- parked todos, always, including `none found`

## Anti-Patterns

- Do not run every downstream skill just because it exists.
- Do not silently bypass plausible idea shaping, `autoplan`, GSD handoff,
  cleanup, or verification; say what was skipped and why.
- Do not use `autoplan` as implementation or refactor execution.
- Do not treat `gsd-ingest-docs` and `gsd-plan-phase` as interchangeable.
- Do not pass one markdown file as a `gsd-ingest-docs` scan path; use a manifest.
- Do not manually copy a plan into phase `CONTEXT.md`; use
  `gsd-plan-phase <phase> --prd docs/plans/<slug>.md`.
- Do not create an ADR for routine implementation progress.
- Do not use `simplify` as a broad architecture scanner.
- Do not close significant implementation/refactor work without verification and
  parked-todo visibility.
