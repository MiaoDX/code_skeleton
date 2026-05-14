---
name: intuitive-flow
description: |
  Orchestrate the intuitive idea-to-execution workflow: grill-me or office-hours
  for direct or auto-guided idea shaping, docs/plans as the pre-execution source
  of truth, autoplan for hard review, optional to-issues for vertical slices,
  GSD ingest/plan for committed execution, GSD execute/verify for
  implementation, simplify for changed-code cleanup, bounded scoping for
  architecture/refactor work, and tdd inside risky slices. Use when the user asks
  for normal development flow,
  durable planning, fuzzy idea to implementation, Matt Pocock skills + gstack +
  GSD together, improve-codebase-architecture via a pipeline, or one coherent
  source of truth from idea to verified work.
---

# Intuitive Flow

Use this skill to route a feature or project direction through one staged
development flow without turning every idea into a full process marathon.

This skill is standalone. It can produce pre-plans, scope gates, and routing
recommendations inline. When the user explicitly combines it with another skill,
use that skill for its specialty but keep one source of truth per stage.

## Stage Source-Of-Truth Rule

Keep one source of truth per stage:

- Before committed execution: `docs/plans/*.md` or GitHub issues are
  authoritative.
- During execution: `.planning/STATE.md` and `.planning/phases/*` are
  authoritative.
- After shipping: retrospectives, summaries, and verification reports are
  authoritative.

Do not create duplicate `.planning/phases/*` artifacts while the team is still
brainstorming in `docs/plans/*.md`. When handing work from one stage to the
next, update the canonical artifact in place instead of treating generated
review logs, chat history, or temporary files as the handoff source.

## Scope Defaults

Keep the workflow small, obvious, and proportionate. The pipeline should make
the next right step easier to see; it should not turn normal implementation
work into a ceremony.

Default to:

- the fewest artifacts that preserve the source of truth
- one plan per coherent delivery unit
- tasks/checklists inside a phase for small steps
- follow-up notes for interesting but non-blocking ideas
- explicit stop conditions instead of open-ended continuation

If the simple path is enough, use it. Split only when the split makes execution
or verification clearer.

## Upfront Route Brief

Before executing a non-trivial request or producing artifacts, show the proposed
pipeline route first. The goal is to make shortcuts visible, not to ask for
permission for every small step.

Use this shape:

```text
Current state: <fuzzy idea | draft plan | reviewed plan | GSD phase | changed code | refactor goal | direct implementation>
Selected path: <stage or skill sequence>
Why: <one sentence>
Bypassed/left behind: <stage - reason; stage - reason>
Stop/continue point: <where work pauses or what will run now>
```

Give this brief before edits when the request could reasonably have gone
through `grill-me`, `office-hours`, `docs/plans`, `autoplan`, `to-issues`,
`gsd-ingest-docs`, `gsd-plan-phase`, `gsd-execute-phase`, `simplify`, or
`gsd-verify-work`.

If the chosen path bypasses one of those stages, name the skipped stage and why.
Examples: "skipping `grill-me` because the request is already scoped",
"skipping `office-hours` because value, wedge, and audience are not in question",
"skipping `autoplan` because the user asked for a direct tiny edit", "skipping
`gsd-ingest-docs` because an existing GSD phase already owns the roadmap
scope", or "skipping `gsd-plan-phase` because no accepted `docs/plans/` handoff
exists yet."

When the user says "impl", asks to execute a specific doc directly, or gives a
small concrete code change, a direct implementation path is allowed. Still say
which planning or GSD stages are being left behind and why. For tiny direct
questions, compress the brief to one sentence.

This direct path does not apply to plan-backed implementation when the
`autoplan` gate has not already run. If the request points at a
`docs/plans/*.md` file, committed plan, or reviewed-looking implementation plan,
run the autoplan precheck below before GSD handoff or execution.

This brief does not override Required Checkpoints. If the selected path crosses
a checkpoint below, stop there and ask.

## Autoplan Precheck Before Plan Implementation

When the user asks to implement a specific plan, says "LGTM", or says "impl"
while pointing at a plan, first check whether `autoplan` already ran and its
accepted decisions were reconciled into the canonical plan file.

Treat as `autoplan` evidence:

- the canonical `docs/plans/<slug>.md` contains accepted review decisions for
  scope, risks, tests, DX, and execution, or links a review summary while keeping
  those decisions in the plan body
- recent conversation or repo history explicitly shows `autoplan` ran and the
  plan was updated in place afterward

Do not treat as `autoplan` evidence:

- the user saying "LGTM", "approved", "go implement", or "keep this plan"
- a commit containing the plan without a visible `autoplan` review/update step
- a raw `~/.gstack` review log, restore file, or final-gate summary that was not
  reconciled into the canonical plan

If evidence is missing, classify the request as `Draft Plan Exists` and run:

```text
autoplan docs/plans/<slug>.md
```

Then stop at the review, in-place update, and execution checkpoints as usual.
Do not say `autoplan` was bypassed because the user approved implementation;
say `autoplan` is selected because pipeline review evidence is missing.

## Goal And Auto-Run Question Triage

When the user starts a durable run such as `/goal` with
`$intuitive-flow for docs/plans/<slug>.md`, optimize for forward motion. Treat
the named plan and the selected workflow as authorization to continue through
routine review, reconciliation, and local verification steps. Do not repeatedly
ask the user to type `Confirm` for checkpoints whose recommended answer is
obvious from the plan, repo evidence, or the user's current request.

Before any question or downstream gate, classify it:

- **Soft continuation** - auto-answer the recommended option, log the decision
  briefly, and continue. Use this when the question preserves the user's stated
  plan, restates premises already present in the canonical artifact, chooses an
  existing repo convention, runs a normal review/test/verification step, updates
  docs with accepted review findings, or selects a reversible default with low
  blast radius.
- **Hard stop** - stop and ask the user. Use this when the answer would change
  target user, demand premise, narrowest wedge, scope boundary, public contract,
  security or privacy posture, external-service dependency, API key use, paid
  infrastructure, data model, phase split, GSD roadmap ownership, destructive
  action, real-device/local-dev requirement, or anything that overrides the
  user's stated intent.
- **Unclear impact** - investigate repo/docs context first. If still unclear and
  the wrong answer could materially change scope, cost, safety, or architecture,
  treat it as a hard stop. Otherwise use the smallest reversible default and log
  it as an assumption.

For `autoplan` premise gates specifically, auto-confirm only when the premises
are direct restatements of the plan or low-risk assumptions needed for review.
Stop only when a premise is new, contradicted by repo evidence, disputed by both
review voices, or would materially change product direction, scope, contracts,
security, privacy, cost, data shape, external services, or execution ownership.

If a downstream skill asks a `Confirm`/`Revise` style question and the gate is a
soft continuation, answer `Confirm` yourself with a one-line rationale instead
of waiting for the user. If it is a hard stop, ask once with the concrete impact
and the smallest useful set of options.

## Idea-Shaping Mode Selection

At the beginning of a fuzzy-idea run, before the first `grill-me` or
`office-hours` question, hint the user to choose the shaping route:

```text
Which route should we use?

A. Direct route (preferred) - plain, more detailed, and user-led. I ask the
   important questions directly and wait for your answers.
B. Auto-guided route (experimental) - I auto-accept obvious defaults, save those
   decisions into the plan, and ask you only for scope, premise, or hard-to-reason
   choices.
```

Mode selection rules:

- If the user explicitly asks for direct/manual shaping, `grill-me`, or
  `office-hours`, use the direct route.
- If the user explicitly asks for auto mode, "make the decisions", "move fast",
  or similar, use the auto-guided route.
- If the user gives no preference and a safe default is needed, use the direct
  route.
- Skip this prompt when a draft plan already exists and the next step is
  `autoplan`.
- This choice is not approval to review, hand off to GSD, or execute. All later
  required checkpoints still apply.

## Phase Granularity

A GSD phase should be one coherent delivery unit:

- one user-visible capability
- one acceptance artifact
- one risk gate
- one bounded refactor outcome
- one local-dev validation gate

Do not create a new phase for:

- every blocker found during implementation
- every diagnostic improvement
- every proof retry
- every small report/checker change
- every ADR-worthy detail
- every commit

Use tasks, checklist items, commits, notes, or verification rows inside the
current phase for those.

Before creating more than three phases from one user prompt, stop and propose a
grouping. The proposal should name:

- the smallest sensible phase set
- what stays as tasks inside each phase
- what is parked
- what evidence closes each phase

If the user asks for "each item has its own phase," interpret that as "each
coherent deliverable has its own phase," then confirm before creating many
micro-phases.

## Execution Honesty

This skill is an orchestrator, not a magic executor. Be explicit about whether
an artifact was produced inline by this skill or by a downstream skill.

When this skill selects a downstream step such as `grill-me`, `office-hours`,
`autoplan`, `to-issues`, `gsd-ingest-docs`, `gsd-plan-phase`,
`gsd-execute-phase`, `simplify`, `gsd-verify-work`, or `tdd`, do one of these:

- actually invoke/load that named skill and follow its workflow
- say the named skill is unavailable or blocked, then stop or give a routing
  recommendation
- if the user asked only for advice, state that this is a recommendation and no
  downstream skill has run

Do not hand-write an artifact and claim it was produced by a downstream skill.
If you produce something inline, label it as inline output from
`intuitive-flow`.

## Auto-Guided Idea Shaping (Experimental)

Use this only for fuzzy ideas before `docs/plans/<slug>.md` exists, and only
when the user chose or clearly requested the auto-guided route.

Auto-guided shaping borrows the question style of `grill-me` and
`office-hours`, but it is not the normal interactive version of either skill.
Label the work as `intuitive-flow` auto-guided shaping unless the downstream
skill is actually invoked without overrides.

Routing inside auto-guided shaping:

- Product direction, wedge, audience, demand, or "is this worth building?" uses
  an `office-hours`-style pass first.
- Implementation shape, scope, design, architecture, or delivery sequencing uses
  a `grill-me`-style pass.
- If both are present, run product shaping first, then implementation shaping.

Decision handling:

- **Mechanical** - auto-decide when the repo, docs, existing conventions, or the
  user's own words already answer the question.
- **Assumption** - auto-decide when the default is low-risk, reversible, and
  does not materially change scope. Mark it as an assumption.
- **Taste** - choose the strongest recommendation, but surface it at the plan
  checkpoint because reasonable builders could choose differently.
- **User-owned** - stop and ask. This includes target user, demand premise,
  narrowest wedge, goal vs non-goal boundaries, public contracts, security or
  privacy posture, external services, API keys, paid infrastructure, phase
  creation/splitting, and any change that overrides the user's stated intent.

Product-premise rule: do not auto-answer demand reality, painful status quo,
buyer/user identity, or narrowest wedge unless the user's message already gives
concrete evidence. Ask the user for those.

Record decisions in the generated pre-plan under:

```markdown
## Idea Shaping Decisions

| # | Question | Classification | Decision | Rationale | Revisit if |
|---|----------|----------------|----------|-----------|------------|
```

At the pre-plan checkpoint, show only the necessary parts:

- user-owned questions still open
- taste decisions worth reviewing
- assumptions that could change scope
- skipped unknowns that would affect execution or validation

Do not ask the user every mechanical question in auto-guided mode. Do not
silently decide user-owned questions.

## Artifact Provenance

- `docs/plans/<slug>.md` pre-plans may be produced inline by this skill when the
  user is still before committed execution.
- Matt Pocock discussion skills such as `grill-me` shape decisions through
  questions. The current agent still writes any resulting plan file unless a
  specific writing skill is invoked.
- Auto-guided idea shaping is inline `intuitive-flow` output. It may use
  `grill-me` or `office-hours` question styles, but do not claim either
  downstream skill produced the auto-decisions unless it was actually invoked
  according to its own workflow.
- ADRs are not a default output of this skill. Create or update ADRs only when a
  documentation/ADR-capable skill is explicitly used or the user explicitly asks
  for an ADR. ADRs record durable architecture or product decisions, not
  implementation progress. Do not create an ADR merely because a phase exists;
  prefer updating the phase plan or summary unless the decision changes a
  long-lived contract.
- `.planning/*` files are GSD-owned. Do not create or edit `.planning/`
  artifacts inline and call it GSD. Use `gsd-ingest-docs` to bootstrap/merge
  docs into `.planning/`, and use `gsd-plan-phase` to create executable GSD
  phase plans.
- Treat `docs/plans/<slug>.md` as pre-GSD PRD input. Do not manually copy it to
  a phase `CONTEXT.md`; use `gsd-plan-phase <phase> --prd docs/plans/<slug>.md`
  when the phase already exists.
- `~/.gstack` artifacts, review logs, and restore points are evidence only.
  They are not the source of truth for the next stage.

## GSD Handoff Decision

`gsd-ingest-docs` and `gsd-plan-phase` are not interchangeable.

- Use `gsd-ingest-docs` when GSD needs project setup, roadmap changes,
  requirement merges, or conflict detection across multiple ADR/PRD/SPEC/DOC
  sources.
- When ingesting a specific `docs/plans/<slug>.md`, create or use a manifest
  that lists it as `PRD` or `SPEC`; do not pass a single markdown file as the
  ingest scan path.
- Use `gsd-plan-phase` when a GSD roadmap phase already exists and needs
  executable `PLAN.md` files.
- Use `gsd-plan-phase <phase> --prd docs/plans/<slug>.md` when an approved
  `docs/plans/` file is the acceptance-criteria source for that existing phase.

Preferred routing:

| Current state | Preferred handoff |
| --- | --- |
| No `.planning/` exists | `gsd-ingest-docs --manifest <manifest> --mode new`, then `gsd-plan-phase <created-phase>` |
| `.planning/` exists but the accepted plan adds roadmap scope or requirements | `gsd-ingest-docs --manifest <manifest> --mode merge`, then `gsd-plan-phase <new-phase>` |
| `.planning/` exists and the phase already exists | `gsd-plan-phase <phase> --prd docs/plans/<slug>.md` |
| Many source docs or possible ADR/spec conflicts | `gsd-ingest-docs --manifest <file>` |
| One approved implementation plan for one known phase | `gsd-plan-phase <phase> --prd docs/plans/<slug>.md` |

When both ingest and planning are needed, run them one by one. First run ingest,
inspect the created or changed roadmap phase, then run plan-phase for that phase.
Do not present `gsd-ingest-docs or gsd-plan-phase` as a coin flip.

Minimal manifest shape for ingesting a plan:

```yaml
docs:
  - path: docs/plans/<slug>.md
    type: PRD
```

Add ADRs, specs, or RFCs to the same manifest when they contain locked
decisions the roadmap merge must respect.

## Stage Router

Start by classifying the user's current state, then give the Upfront Route Brief
before running the selected route. If you choose a shortened path, say what was
left behind and why.

### A. Fuzzy Idea

Use when the user is still deciding what to build, why it matters, or what the
scope should be.

First choose the idea-shaping route unless the user already made the mode clear.

Direct route default path:

```text
grill-me -> docs/plans/<slug>.md
```

Auto-guided route default path:

```text
intuitive-flow auto-guided shaping -> docs/plans/<slug>.md
```

Use `office-hours` instead of or after `grill-me` when the question is about
product direction, wedge, audience, demand, or "is this worth building?"

In auto-guided mode, use `office-hours`-style questions for product direction
and `grill-me`-style questions for implementation shape, but record decisions
as inline `intuitive-flow` output.

Stop after the plan doc unless the user explicitly asks to continue.

### B. Draft Plan Exists

Use when a human-readable plan exists and the user wants hard review. Also use
when the user wants implementation of a plan but the autoplan precheck does not
find evidence that `autoplan` already ran and was reconciled into the plan.

Default path:

```text
autoplan docs/plans/<slug>.md
```

`autoplan` is a review pipeline, not an implementation tool. It may refine the
plan, surface scope changes, and produce review logs. It must not start coding.

Apply Goal And Auto-Run Question Triage to `autoplan` gates. A `/goal` or
explicit whole-flow request may auto-confirm soft premise, review, and
reconciliation gates when they preserve the canonical plan and add only
low-risk review findings. Stop for hard-stop changes such as new premises,
scope changes, phase split choices, public contracts, cost, security, privacy,
external services, data model changes, or rejected user intent.

When the user approves the `autoplan` gate, or when triage classifies the gate
as a soft continuation, reconcile the approved decisions back into the same
`docs/plans/<slug>.md` file before moving on. `~/.gstack` artifacts are
supporting evidence, restore points, and review logs; they are not the handoff
source of truth.

Approval means:

- update the plan in place with accepted scope, risk, test, DX, and execution
  changes
- keep or link any external `~/.gstack` artifacts only as evidence
- verify the plan file itself contains the approved acceptance criteria and GSD
  handoff trigger

If the only in-repo change after `autoplan` is a restore comment or appended
review report, do not hand off yet. First edit the body of the plan so the next
stage ingests the approved plan, not the review artifact.

After the approval gate and in-place reconciliation, continue only if the user
already asked for execution or the active `/goal` objective clearly covers the
handoff/implementation stage. Otherwise stop with the updated plan ready.

### C. Reviewed Plan, Not Yet Committed To Execution

Use when the plan is accepted, already passed the autoplan precheck, and is not
yet under GSD. A user's implementation approval alone is not enough to enter
this stage.

Before treating any plan as reviewed, run the autoplan precheck. If `autoplan`
has not run or its accepted decisions were not reconciled into the canonical
plan, reclassify the request as `Draft Plan Exists` and run `autoplan` before
`to-issues`, `gsd-ingest-docs`, `gsd-plan-phase`, or implementation.

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

Choose the GSD handoff path:

```text
# If the phase already exists in .planning/ROADMAP.md:
gsd-plan-phase <phase> --prd docs/plans/<slug>.md

# If .planning/ does not exist yet:
create or verify an ingest manifest that includes docs/plans/<slug>.md
gsd-ingest-docs --manifest <manifest> --mode new
gsd-plan-phase <created-phase> --prd docs/plans/<slug>.md

# If .planning/ exists but this plan creates or changes roadmap scope:
create or verify an ingest manifest that includes docs/plans/<slug>.md
gsd-ingest-docs --manifest <manifest> --mode merge
gsd-plan-phase <created-or-updated-phase> --prd docs/plans/<slug>.md
```

This is a real handoff only if the named GSD skill is invoked and its workflow
is followed. If you only recommend this step, say no GSD artifact has been
generated yet. Do not approximate `.planning/` files inline as a substitute for
`gsd-ingest-docs` or `gsd-plan-phase`.

Do not manually turn `docs/plans/<slug>.md` into `CONTEXT.md`. The PRD express
path in `gsd-plan-phase --prd` generates phase context from the approved plan
and continues through research, planning, and verification.

After a real handoff, GSD owns execution truth.

### D. Committed GSD Phase

Use when `.planning/phases/<phase>/` exists and the user wants implementation.

Default path:

```text
gsd-execute-phase <phase>
simplify <changed-scope>
gsd-verify-work <phase>
```

At GSD closeout/verify/ship, update `STATUS.md` when the current focus, latest
phase, next action, or blocker changed. Keep it as a short dashboard; do not
mirror the GSD ledger. For parallel standalone terminal work, use one task-owned
file under `docs/status/active/` instead of editing `STATUS.md` for routine
progress.

When implementation hits a blocker, stay inside the current phase by default.
Record the blocker and either fix it, narrow the phase, or mark the phase
blocked. Create a follow-up phase only when the blocker is a separate coherent
delivery unit with its own acceptance evidence.

Use `tdd` inside individual slices when behavior needs to drive the code:

- new public interfaces
- MCP tools
- parsers and manifests
- scenario scoring
- artifact schemas
- regressions

`tdd` is not a phase planner. It is the implementation discipline for one slice.

Use `simplify` after implementation produces code changes and before final
verification or final commit. It reviews changed code for reuse, quality, and
efficiency, then fixes valid findings directly.

Scope `simplify` to the actual changed code:

- if changes are still uncommitted, use `simplify`
- if the slice was already committed, use `simplify <base-ref>` or
  `simplify <path>`
- if only docs/plans changed, skip `simplify` unless the user explicitly asks

`simplify` is not an architecture discovery tool. Do not use it to find new
features, expand refactor scope, or replace `gsd-verify-work`. After `simplify`
changes code, rerun the relevant tests or verification gates before declaring
the phase done.

### E. Architecture Or Refactor Goal

Use when the user asks to improve architecture, refactor a module, fix "all big
known issues", run `improve-codebase-architecture`, or stop endless cleanup
loops.

Default path:

```text
create or read refactor scope gate
architecture scan               # report-only unless the scope gate accepts P0/P1 items
TDD or diagnosis                 # only when the accepted checklist needs proof first
execute accepted P0/P1 slices
record P2/Parked ideas instead of implementing them
```

The refactor scope gate can be produced inline by this skill or by a dedicated
refactor-scope skill if the user explicitly combines one. Either way, the gate
is the source of truth for the refactor pass. It must name:

- target module or seam
- status marker: `DONE`, `CONTINUE`, `REOPEN`, or `PARK`
- accepted severities
- accepted issue checklist
- parked issues
- required evidence level
- persistent gate file, usually `docs/plans/refactor-<target>.md`
- stop condition

Once implementation starts, do not keep discovering and implementing new P2
cleanup. Only add newly discovered work if it is a P0/P1 regression found while
verifying the accepted checklist.

On repeated runs of the same refactor prompt, read the persistent gate file
first. Read the frontmatter `status` marker, falling back to the `## Status`
section. If the status is `DONE` and evidence remains green, stop instead of
re-scanning for fresh cleanup.

### F. Changed Code Needs Cleanup

Use when implementation has already changed code and the next risk is local
quality: duplication, missed reuse, avoidable complexity, or inefficient work.

Default path:

```text
simplify <changed-scope>
rerun relevant tests or verification gates
```

Pick the scope from the actual diff:

- uncommitted changes -> `simplify`
- committed slice -> `simplify <base-ref>`
- focused package/module -> `simplify <path>`

After `simplify`, keep the source of truth unchanged: GSD still owns phase
execution truth, and the original plan or scope gate still owns what is in
scope. Treat new broad cleanup ideas as P2/Parked unless they are valid findings
against code already changed in this slice.

## Default Pipeline

When the user asks for the whole durable pipeline, propose this compact sequence:

```text
1. choose idea-shaping mode:
   - direct route (preferred)
   - auto-guided route (experimental)
2. shape the idea:
   - direct -> grill-me, plus office-hours when product/wedge/demand is unclear
   - auto-guided -> intuitive-flow auto-decisions with user-owned stops
3. docs/plans/<feature>.md
4. autoplan
5. update docs/plans/<feature>.md in place after approval or soft-continuation triage
6. to-issues (optional)
7. choose the GSD handoff:
   - existing phase -> gsd-plan-phase <phase> --prd docs/plans/<feature>.md
   - missing .planning or roadmap scope -> gsd-ingest-docs via manifest, then
     gsd-plan-phase --prd
8. gsd-execute-phase
9. tdd inside risky slices
10. simplify changed code
11. gsd-verify-work
12. update STATUS.md if the current focus, latest phase, next action, or blocker changed
```

For parallel standalone tasks, write progress to
`docs/status/active/<task-slug>.md` and keep `STATUS.md` repo-level only.

The agent may choose a shortened path when the user's request is already scoped,
trivial, or already under an authoritative source of truth. When shortening,
announce the selected path and every material stage left behind before moving.
This includes idea-shaping stages: if `grill-me` or `office-hours` would have
been plausible but are skipped, name them and explain why.

Do not shorten a plan-backed implementation past `autoplan` unless the autoplan
precheck finds evidence it already ran and was reconciled, or the task is a tiny
direct edit that is not using a plan as the source of truth.

Do not run `office-hours` by default if `grill-me` already made the direction
crisp. Add `office-hours` only if value, wedge, audience, or demo framing is
still uncertain.

Do not run `to-issues` by default if one GSD phase can hold the work cleanly.

Do not run `tdd` globally. Use it where behavior should be specified through
public interfaces before code.

Do not run `simplify` globally. Run it on changed code after implementation and
before final verification, or after a committed slice by passing a base ref or
path.

For architecture/refactor work, do not run `improve-codebase-architecture` as
the execution driver. First produce or load an accepted refactor scope gate,
then use architecture findings as report-only input to the accepted P0/P1
checklist.

## Required Checkpoints

Apply Goal And Auto-Run Question Triage before crossing these boundaries. Stop
and ask only for hard-stop decisions. For soft continuations, auto-answer the
recommended option, record the rationale in the relevant artifact or progress
summary, and continue.

1. **Idea-shaping route:** for fuzzy ideas, ask whether to use the direct route
   (preferred) or auto-guided route (experimental), unless the user already made
   the choice clear.
2. **Auto-guided user-owned decision:** in auto-guided mode, ask before deciding
   target user, demand premise, narrowest wedge, scope boundary, public contract,
   external-service dependency, paid infrastructure, phase split, or any override
   of stated user intent.
3. **Pre-plan -> Review:** "Is this the plan file you want reviewed?"
4. **Review -> In-place update:** "Do you approve these review decisions, and
   should I update the plan file in place?"
5. **Review -> Issues/GSD:** "Do you approve this updated plan for execution?"
6. **GSD handoff choice:** "Does this map to an existing GSD phase for
   `gsd-plan-phase --prd`, or should `gsd-ingest-docs` create/merge roadmap
   scope first?"
7. **Issues -> GSD:** "Do you want GitHub issue tracking, or go straight to GSD?"
8. **GSD plan -> Execute:** "Execute now, or stop after plan generation?"
9. **Many phases:** before creating more than three phases from one prompt, ask
   "Should this be grouped into a smaller set of coherent phases instead?"
10. **Simplify -> Verify:** "Review and clean the changed code with `simplify`
   before final verification, or skip because the change is docs-only/trivial?"
11. **Refactor scope -> Execute:** "Do you approve this P0/P1 checklist and stop
   condition for implementation?"
12. **Local-dev gate:** if proof depends on real simulator, real Gateway, real VLM,
   Docker, GPU, or API keys, stop unless the current session is local and equipped.

## Output Shapes

### If Giving An Upfront Route Brief

Return this before the first artifact or edit:

```text
Current state: <classification>
Selected path: <stage/skill sequence>
Why: <one sentence>
Bypassed/left behind: <stage - reason; stage - reason>
Stop/continue point: <what happens before the next checkpoint>
```

For tiny direct work, one sentence is enough, but it still needs to name the
selected path when a heavier route was plausible.

### If Producing A Pre-Plan

Write to:

```text
docs/plans/<slug>.md
```

Include:

- problem / goal
- idea-shaping mode: direct or auto-guided
- decisions already made
- idea shaping decisions table when auto-guided mode was used
- non-goals
- smallest demo
- fuller demo
- acceptance criteria
- proposed vertical slices
- GSD handoff trigger:
  - existing phase -> `gsd-plan-phase <phase> --prd docs/plans/<slug>.md`
  - missing `.planning/` or missing roadmap phase -> create/use an ingest
    manifest, run `gsd-ingest-docs --manifest <manifest>`, then run
    `gsd-plan-phase <created-phase> --prd docs/plans/<slug>.md`

### If Producing A Workflow Recommendation

Return a compact routing table:

```text
Current state: <fuzzy | draft-plan | reviewed-plan | gsd-phase | changed-code | refactor-goal>
Recommended next step: <skill/stage>
Why: <one sentence>
Stop condition: <what should be true before the next stage>
```

### If Updating Repo Guidance

Update `AGENTS.md` and `CLAUDE.md` only. Do not scatter workflow rules across
README or architecture docs unless the user asks.

## Anti-Patterns

- Do not run every skill just because it exists.
- Do not silently bypass idea shaping. If `grill-me` or `office-hours` would
  have been plausible, say whether they are selected or skipped and why.
- Do not bypass `autoplan` for plan-backed implementation because the user said
  "LGTM", "impl", or approved a plan. Run the autoplan precheck first unless
  review evidence is present.
- Do not silently bypass `autoplan`, `to-issues`, GSD handoff, execution,
  cleanup, or verification stages when they were plausible routes. Say what was
  left behind and why before continuing.
- Do not silently choose auto-guided idea shaping when the user asked for direct
  `grill-me` or `office-hours`.
- Do not auto-decide user-owned product, scope, contract, cost, security,
  privacy, or phase-boundary choices.
- Do not claim `grill-me` or `office-hours` produced auto-guided decisions. Label
  that output as inline `intuitive-flow` auto-guided shaping.
- Do not create a new GSD phase for every small task, diagnostic, proof retry,
  report tweak, checker tweak, blocker, or commit. Keep those inside the
  current coherent phase unless they need separate acceptance evidence.
- Do not create an ADR for routine implementation progress.
- Do not create both `docs/plans/<slug>.md` and `.planning/phases/<slug>/` as
  active competing sources of truth.
- Do not treat `gsd-ingest-docs` and `gsd-plan-phase` as interchangeable.
  Ingest owns project/roadmap/requirements synthesis; plan-phase owns executable
  phase plans.
- Do not pass a single `docs/plans/<slug>.md` file as the `gsd-ingest-docs`
  scan path. Use a manifest when ingesting selected files.
- Do not manually copy `docs/plans/<slug>.md` into a phase `CONTEXT.md`; use
  `gsd-plan-phase <phase> --prd docs/plans/<slug>.md`.
- Do not use `autoplan` as a code refactor tool.
- Do not use `simplify` as a broad refactor scanner. It reviews changed code
  for reuse, quality, and efficiency after implementation.
- Do not use `improve-codebase-architecture` as an unbounded refactor executor;
  produce or load a bounded refactor scope gate first.
- Do not use `to-issues` after GSD execution has already started unless the
  user explicitly wants GitHub tracking added midstream.
- Do not use `tdd` to write all tests up front. Use one red-green-refactor loop
  per behavior.
