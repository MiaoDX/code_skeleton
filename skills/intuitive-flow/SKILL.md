---
name: intuitive-flow
description: |
  Orchestrate the intuitive idea-to-execution workflow: grill-me or office-hours
  for direct or auto-guided idea shaping, human-confirmed goal/success criteria
  before whole auto-runs, docs/plans as the pre-execution source of truth,
  single docs/adr or docs/human plan-like files as intake to refactor into
  docs/plans, autoplan for hard review, optional to-issues for vertical slices, GSD
  ingest/plan for committed execution, GSD execute/verify for implementation,
  semantic commits after reviewable units, simplify for changed-code cleanup,
  doc-status cleanup after big refactors, bounded scoping for
  architecture/refactor work, and tdd inside risky slices.
  Use when the user asks
  for normal development flow,
  durable planning, fuzzy idea to implementation, Matt Pocock skills + gstack +
  GSD together, improve-codebase-architecture via a pipeline, or one coherent
  source of truth from idea to verified work.
---

# Intuitive Flow

Use this skill to route a feature or project direction through one staged
development flow without turning every idea into a full process marathon.

It can produce pre-plans, scope gates, and routing recommendations inline.
When another workflow would add useful evidence or structure, use it as an
input while keeping one source of truth per stage.

## Stage Source-Of-Truth Rule

Keep one source of truth per stage:

- Before committed execution: `docs/plans/*.md` or GitHub issues are
  authoritative.
- During execution: `.planning/STATE.md` and `.planning/phases/*` are
  authoritative.
- After shipping: retrospectives, summaries, and verification reports are
  authoritative.

If the user points at exactly one plan-like markdown file under `docs/adr/`,
`docs/adrs/`, or `docs/human/`, treat it as intake evidence for the
pre-execution stage, not as the later handoff artifact. Refactor the actionable
goal, scope, constraints, decisions, and acceptance criteria into a canonical
`docs/plans/<slug>.md` file before `autoplan`, `to-issues`, or GSD handoff.
Preserve the original file's role by linking it as source evidence; do not append
`autoplan` review logs to ADR or human-facing docs unless the user explicitly
asks to edit that document.

Do not create duplicate `.planning/phases/*` artifacts while the team is still
brainstorming in `docs/plans/*.md`. When handing work from one stage to the
next, update the canonical artifact in place instead of treating generated
review logs, chat history, or temporary files as the handoff source.

## Domain Context Inputs

Some repos maintain a root `CONTEXT.md` or `CONTEXT-MAP.md` through
`grill-with-docs`. Treat these files as domain-language and decision-boundary
evidence, not as executable plans.

At the start of any fuzzy idea, plan shaping, architecture/refactor route, or
implementation whose terms or long-lived contract boundaries matter, check
whether `CONTEXT.md` or `CONTEXT-MAP.md` exists. Read the relevant context before
writing `docs/plans/<slug>.md`, running `autoplan`, or handing off to GSD. If a
`CONTEXT-MAP.md` exists, use it to select the narrow context file instead of
assuming root `CONTEXT.md` is the only source.

When user discussion resolves vocabulary, domain boundaries, or durable
architecture/product distinctions, route that update through `grill-with-docs`
or follow its context-writing contract: update `CONTEXT.md` inline with the
resolved term or relationship, keep implementation steps in `docs/plans` or GSD
artifacts, and link the context file as source evidence from the plan when it
informs acceptance criteria.

Do not clean up or relocate `CONTEXT.md` as stale planning history merely because
a `docs/plans` or GSD artifact now exists. Cleanup may remove or rewrite only
obsolete glossary entries or misleading relationships after checking current
references and preserving the active domain language somewhere equivalent.

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

## Single Plan-File Intake

When the user points at exactly one markdown file that looks like a plan, accept
these roots as pre-execution intake:

- `docs/plans/**/*.md`
- `docs/adr/**/*.md`
- `docs/adrs/**/*.md`
- `docs/human/**/*.md`

Use the supplied file as the current plan only when it already lives under
`docs/plans/`. For `docs/adr/`, `docs/adrs/`, or `docs/human/`, first refactor
the actionable parts into `docs/plans/<slug>.md`, then use that canonical plan
for `autoplan`, `to-issues`, and GSD. The refactor should preserve source links
and extract only execution-ready material: goal, scope, non-goals, decisions,
constraints, acceptance criteria, test/verification expectations, risks, and the
GSD handoff trigger. Do not move, rewrite, or append review logs to the original
ADR or human-facing doc unless the user explicitly asked to update that file.

If the supplied file is mostly reference material rather than an executable plan,
create the `docs/plans/<slug>.md` draft with clear "unknown / needs decision"
markers and stop before `autoplan` unless the user's run contract explicitly says
to continue through review.

## Delegation Model

Keep the main session as the coordinator, decision point, and canonical
artifact editor. Use delegation to keep route evidence, worker logs, and
implementation detail out of the main context when the work naturally separates.

Default matrix:

| Work type | Default executor |
| --- | --- |
| Read-heavy independent probes | native subagents |
| Verification-heavy log or test-output inspection | native subagents |
| Bounded disjoint edits | native worker subagents |
| Stateful, interactive, or long-running skill pipelines | `skill-runner` / tmux |
| Canonical source-of-truth edits and route decisions | main session |

Use native subagents by default when there are two or more independent
read-heavy, verification-heavy, or safely partitioned edit workstreams. For
mutating native workers, assign disjoint file or path ownership before launch
and require a compact handoff back to the main session.

Use `skill-runner` for downstream skill work that is stateful, interactive,
long-running, or better supervised in a standalone tmux session. Prefer one
mutating `skill-runner` worker at a time in a single worktree unless the write
ownership is explicitly disjoint. Do not assume extra git worktrees; many repos
are too large or dependency-heavy for that to be the default.

Worker handoff shape, whether native subagent or `skill-runner`:

```text
Scope:
Changed files:
Decisions made:
Verification:
Open risks:
Suggested next action:
```

For `skill-runner`, inspect `result.md`, `eval.md`, `last-message.md` when
available, targeted logs, the actual diff, and verification evidence before
trusting the worker's final status.

Model policy: prefer the current best/default model for normal delegated work.
Use smaller or quicker models only for truly easy probes where mistakes are
low-cost and easy to catch. Do not add multi-run orchestration here; leave
fan-out/fan-in runners for a later proven need.

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
Commit rhythm: <semantic commits enabled | disabled because ...>
Stop/continue point: <where work pauses or what will run now>
```

For non-trivial delegated work, include the execution boundary in the selected
path, such as "native probes -> main decision" or
"skill-runner/tmux -> main inspection."

Give this brief before edits when the request could reasonably have gone
through `grill-me`, `grill-with-docs`, `office-hours`, `docs/plans`,
`autoplan`, `to-issues`, `gsd-ingest-docs`, `gsd-plan-phase`,
`gsd-execute-phase`, `simplify`, or `gsd-verify-work`.

If the chosen path bypasses one of those stages, name the skipped stage and why.
Examples: "skipping `grill-me` because the request is already scoped",
"skipping `grill-with-docs` because the change does not alter domain language
or durable boundaries",
"skipping `office-hours` because value, wedge, and audience are not in question",
"skipping `autoplan` because the user asked for a direct tiny edit", "skipping
`gsd-ingest-docs` because an existing GSD phase already owns the roadmap
scope", or "skipping `gsd-plan-phase` because no accepted `docs/plans/` handoff
exists yet."

When the user says "impl", asks to execute a specific doc directly, or gives a
small concrete code change, a direct implementation path is allowed. Still say
which planning or GSD stages are being left behind and why. For tiny direct
questions, compress the brief to one sentence. For durable implementation or
refactor work, say whether semantic commits are enabled before the first edit.

This direct path does not apply to plan-backed implementation when the
`autoplan` gate has not already run. If the request points at a supported single
plan-like file, committed plan, or reviewed-looking implementation plan, run the
single plan-file intake and autoplan precheck below before GSD handoff or
execution.

This brief does not override Required Checkpoints. If the selected path crosses
a checkpoint below, stop there and ask.

## STATUS.md Cadence

For every non-trivial or durable `$intuitive-flow` run, check `STATUS.md` at
both ends of the flow.

At the start, read `STATUS.md` before creating the first workflow artifact or
launching downstream skills. If the requested flow changes the repo's current
focus, next action, active phase, known blocker, or verification expectation,
update `STATUS.md` before continuing so the dashboard matches the work that is
about to happen. Keep it short; do not duplicate the plan, GSD ledger, or
execution notes.

At closeout, read `STATUS.md` again and update it when the flow changed the
current focus, latest phase/status, next action, blocker, verification state, or
handoff expectation. If no update is needed, say that `STATUS.md` was checked
and left unchanged. For parallel standalone terminal work, use one task-owned
file under `docs/status/active/` instead of editing `STATUS.md` for routine
progress.

## Autoplan Precheck Before Plan Implementation

When the user asks to implement a specific plan, says "LGTM", or says "impl"
while pointing at a plan, first resolve the canonical plan path. If the user
provided a single supported file outside `docs/plans/`, refactor it into
`docs/plans/<slug>.md` and treat the original file as source evidence. Then check
whether `autoplan` already ran and its accepted decisions were reconciled into
the canonical plan file.

Codex routing note: gstack skills are installed as `gstack-*` sibling skill
directories. When routing to autoplan from this skill, prefer the installed
`gstack-autoplan` skill or the surfaced `autoplan` alias if that is the only
available name. Do not resolve review skills through nested paths like
`$GSTACK_ROOT/plan-ceo-review/SKILL.md`; use the installed `gstack-*` skill
surface instead.

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
gstack-autoplan <canonical-docs-plans-path>
```

For whole-flow, implementation, or long-running review runs, prefer launching
that autoplan step through `skill-runner` so the main session can monitor the
review behavior and inspect compact artifacts before reconciling decisions into
the plan.

Then stop at the review, in-place update, and execution checkpoints as usual.
Do not say `autoplan` was bypassed because the user approved implementation;
say `autoplan` is selected because pipeline review evidence is missing.

## Whole-Run Goal Preflight

Before starting any whole-flow, durable, auto-guided, or `/goal` run that may
cross review, GSD handoff, execution, cleanup, and verification, chat with the
human until the run contract is explicit. Do this before `autoplan`,
`to-issues`, GSD ingest/plan, `skill-runner`, autonomous execution, or
auto-confirming downstream gates.

This preflight is a user-owned checkpoint, not a soft continuation. Do not
answer it yourself just because the later pipeline can auto-confirm routine
steps. If a canonical plan already exists, inspect it first and summarize the
inferred contract instead of asking the user to restate everything from scratch.

The run contract needs:

- **Goal** - the concrete outcome the whole run is trying to achieve.
- **Success criteria** - observable done signals, including acceptance behavior,
  required verification commands or manual checks when known, and any quality bar
  that would make the user say the run succeeded.
- **Stop condition** - where this run should end: reviewed plan, GSD plan,
  implemented and verified code, PR-ready branch, or another explicit boundary.
- **Non-goals or boundaries** - only when needed to prevent scope drift,
  accidental compatibility promises, cost/security changes, or extra phases.

Use this compact prompt shape:

```text
Before I start the whole run, I want to lock the run contract.

Goal: <inferred or missing>
Success criteria: <inferred or missing>
Stop condition: <inferred or missing>
Boundaries/non-goals: <inferred or "none stated">

Is this the goal and success criteria you want me to execute against? If not,
what should change?
```

Start the auto-run only after the user confirms or corrects the goal and success
criteria, or when the user's latest message explicitly supplied the full run
contract and told you to use it as-is. Once this preflight is satisfied, apply
Goal And Auto-Run Question Triage for later gates.

## Goal And Auto-Run Question Triage

When the user starts a durable run such as `/goal` with
`$intuitive-flow for docs/plans/<slug>.md`, optimize for forward motion. Treat
the named plan and the selected workflow as authorization to continue through
routine review, reconciliation, deterministic GSD handoff, GSD plan generation,
and local verification steps. A direct prompt like
`$intuitive-flow for docs/plans/<slug>.md` counts as this durable path unless
the user says review-only, plan-only, or otherwise names a stop point. Do not
repeatedly ask the user to type `Confirm` for checkpoints whose recommended
answer is obvious from the plan, repo evidence, or the user's current request.

Before any question or downstream gate, classify it:

- **Soft continuation** - auto-answer the recommended option, log the decision
  briefly, and continue. Use this when the question preserves the user's stated
  plan, restates premises already present in the canonical artifact, chooses an
  existing repo convention, runs a normal review/test/verification step, updates
  docs with accepted review findings, selects a reversible default with low
  blast radius, or chooses the only GSD handoff route supported by repo
  evidence.
- **Hard stop** - stop and ask the user. Use this when the answer would change
  target user, demand premise, narrowest wedge, scope boundary, public contract,
  security or privacy posture, external-service dependency, API key use, paid
  infrastructure, data model, phase split, ambiguous or competing GSD roadmap
  ownership, destructive action, real-device/local-dev requirement, or anything
  that overrides the user's stated intent.
- **Unclear impact** - investigate repo/docs context first. If still unclear and
  the wrong answer could materially change scope, cost, safety, or architecture,
  treat it as a hard stop. Otherwise use the smallest reversible default and log
  it as an assumption.

For `autoplan` premise gates specifically, auto-confirm only when the premises
are direct restatements of the plan or low-risk assumptions needed for review.
Stop only when a premise is new, contradicted by repo evidence, disputed by both
review voices, or would materially change product direction, scope, contracts,
security, privacy, cost, data shape, external services, or execution ownership.

When `$intuitive-flow` invokes gstack `gstack-autoplan`/`autoplan`, keep the
auto-choice behavior: if gstack offers a recommended/default choice and the gate
is a soft continuation, choose that option, record the rationale briefly, and
continue.

If a downstream skill asks a `Confirm`/`Revise` style question and the gate is a
soft continuation, answer `Confirm` yourself with a one-line rationale instead
of waiting for the user. If it is a hard stop, ask once with the concrete impact
and the smallest useful set of options.

For GSD handoff gates, auto-continue when exactly one routing row applies:

- an existing roadmap phase clearly matches the accepted plan, so run
  `gsd-plan-phase <phase> --prd docs/plans/<slug>.md`;
- `.planning/` is missing, so create a minimal manifest for the selected plan,
  run `gsd-ingest-docs --manifest <manifest> --mode new`, inspect the created
  phase, then run `gsd-plan-phase <created-phase> --prd ...`;
- `.planning/` exists and no existing phase matches, so create a minimal
  manifest for the selected plan, run `gsd-ingest-docs --manifest <manifest>
  --mode merge`, inspect the created or changed phase, then run
  `gsd-plan-phase <created-or-updated-phase> --prd ...`.

Stop only when the repo evidence leaves multiple plausible existing phases,
would require more than one new phase, conflicts with locked docs/ADRs, changes
roadmap ownership beyond the accepted plan, or crosses a local-dev/destructive
gate. For a single reviewed plan that already names GSD handoff, "create/merge
one roadmap phase first" is a soft continuation, not a human decision.

Gather GSD route evidence with parallel native probes when it is independent:
roadmap phase match, locked-doc/ADR conflicts, manifest inputs, and verification
commands. Keep the final handoff decision in the main session.

## Semantic Change Commits For Durable Runs

When a durable `$intuitive-flow` implementation or refactor run may produce more
than one reviewable unit, create semantic commits along the way instead of
waiting for one end-of-flow commit. Treat intermediate commits as the default
recoverability boundary for long runs so failures, reversions, and reviews can
map back to a concrete intent.

Commit automation is enabled by default when the run contract asks for
implemented, verified, or PR-ready code. Announce this in the upfront route
brief or run contract. Disable it when the user says not to commit, the stop
condition is review-only or plan-only, repo instructions forbid commits, the
worktree cannot be safely separated from unrelated changes, or the current unit
has unresolved blockers. If commits are disabled, update the canonical artifact
or progress summary after each unit and state why no commit was made.

When enabled, these semantic commits are soft continuations, not separate human
checkpoints.

A semantic commit boundary must have:

- one coherent intent a reviewer would accept or revert independently
- owned files only, with unrelated dirty changes left untouched
- the relevant targeted proof run, or an explicit note that the unit is
  documentation/planning only
- no known unresolved blocker inside the unit
- the canonical artifact or progress file updated when the unit changes the
  handoff state

Create a commit immediately after each completed boundary that meets those
criteria. Do not wait for final closeout when the flow has accumulated a clean
boundary. Useful boundary moments:

- after `autoplan` reconciles accepted review decisions into
  `docs/plans/<slug>.md`
- after `gsd-ingest-docs` creates or merges roadmap scope
- after `gsd-plan-phase` creates an executable phase plan
- after each coherent implementation slice, including its focused tests
- after a standalone test harness or verification tool lands separately from
  the implementation it validates
- after `simplify` changes code outside the immediately preceding slice
- after verification or closeout updates docs/status/retrospectives materially
- after a big refactor completes its documentation status check and any needed
  `$intuitive-doc` cleanup

Choose commit messages by semantic intent, following the target repo's local
style first. If no local style is obvious, use:

- `docs(plan): ...` for accepted plan/review reconciliation
- `chore(workflow): ...` for GSD manifests, roadmap state, or workflow metadata
- `feat(<area>): ...` for new user-visible behavior
- `fix(<area>): ...` for bug fixes or failing-proof repairs
- `refactor(<area>): ...` for behavior-preserving structural changes
- `test(<area>): ...` for standalone test or verification harness changes
- `docs(<area>): ...` for human-facing documentation updates

Before each commit, inspect the diff, stage only the owned files for that
boundary, run or record the relevant proof, and include the target repo's
AI co-author trailer when applicable. If a boundary is too mixed to commit
cleanly, split the diff before continuing or leave it uncommitted with a compact
reason in the progress summary.

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

## Provenance Honesty

Name where decisions and artifacts came from. If another workflow actually ran,
say so and use its result as evidence. If you produced the output inline with
similar reasoning, label it as `intuitive-flow` output instead of borrowing the
other workflow's name. The point is clear handoff provenance, not ceremony.

## Auto-Guided Idea Shaping (Experimental)

Use this only for fuzzy ideas before `docs/plans/<slug>.md` exists, and only
when the user chose or clearly requested the auto-guided route.

Auto-guided shaping can borrow the question style of `grill-me` and
`office-hours`, but label the work as `intuitive-flow` auto-guided shaping
unless those workflows actually ran.

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
- `grill-with-docs` maintains domain-language context such as root `CONTEXT.md`
  or context files selected by `CONTEXT-MAP.md`. Treat those files as source
  evidence for terminology, invariants, and durable boundaries, not as PRDs or
  execution ledgers.
- Auto-guided idea shaping is inline `intuitive-flow` output. It may use
  `grill-me` or `office-hours` question styles, but keep the provenance clear.
- A single plan-like `docs/adr/**`, `docs/adrs/**`, or `docs/human/**` file is
  intake evidence for this workflow. Refactor it into `docs/plans/<slug>.md`
  before review or execution instead of letting ADR/human docs become plan-review
  ledgers.
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
- Treat `docs/plans/<slug>.md` as pre-GSD PRD input. If the user started from
  `docs/adr/**`, `docs/adrs/**`, or `docs/human/**`, the refactored
  `docs/plans/<slug>.md` is the PRD input and the original file is supporting
  evidence. Do not manually copy the plan to a phase `CONTEXT.md`; use
  `gsd-plan-phase <phase> --prd docs/plans/<slug>.md` when the phase already
  exists.
- If `CONTEXT.md` or a mapped context file informed the plan, include it as
  supporting evidence. Do not copy the context body into the plan; cite the
  relevant terms or relationships and keep the glossary maintained in place.
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
find evidence that `autoplan` already ran and was reconciled into the canonical
plan.

Default path:

```text
single plan-file intake, if needed -> gstack-autoplan docs/plans/<slug>.md
```

`gstack-autoplan`/`autoplan` is a review pipeline, not an implementation tool.
It may refine the plan, surface scope changes, and produce review logs. It must
not start coding.

For non-trivial or whole-flow runs, run the review pipeline through
`skill-runner`/tmux. The main session owns review decision classification,
canonical plan reconciliation, and the next route decision after inspecting the
worker artifacts and diff.

Apply Goal And Auto-Run Question Triage to `autoplan` gates. A `/goal` or
explicit whole-flow request may auto-confirm soft premise, review, and
reconciliation gates when they preserve the canonical plan and add only
low-risk review findings. Stop for hard-stop changes such as new premises,
scope changes, phase split choices, public contracts, cost, security, privacy,
external services, data model changes, or rejected user intent.

When the user approves the `autoplan` gate, or when triage classifies the gate
as a soft continuation, reconcile the approved decisions back into the canonical
`docs/plans/<slug>.md` file before moving on. `~/.gstack` artifacts are
supporting evidence, restore points, and review logs; they are not the handoff
source of truth. If the run began from `docs/adr/**`, `docs/adrs/**`, or
`docs/human/**`, do not propagate `autoplan` review reports back into that
original document unless the user explicitly asked for a doc update.

Approval means:

- update the plan in place with accepted scope, risk, test, DX, and execution
  changes
- keep or link any external `~/.gstack` artifacts only as evidence
- verify the plan file itself contains the approved acceptance criteria and GSD
  handoff trigger
- surface scope changes before execution: new requirements, removed or deferred
  requirements, non-goals, phase split changes, validation gates, and assumptions
  that changed since the original plan

If the only in-repo change after `autoplan` is a restore comment or appended
review report, do not hand off yet. First edit the body of the plan so the next
stage ingests the approved plan, not the review artifact.

Before moving from `autoplan` reconciliation to implementation, show a compact
scope-change hint block. Use this even when the change is "none" so the user can
see that scope drift was checked:

```text
Autoplan scope changes: <none | accepted changes | hard-stop changes>
Accepted into plan: <short bullets or "none">
Parked/deferred from autoplan: <short bullets or "none">
Hard-stop decisions still needing user input: <short bullets or "none">
```

Treat new or disputed product scope, public contracts, security/privacy posture,
paid services, data model changes, phase ownership changes, or incompatible
requirements as hard stops. Treat clarified tests, implementation sequencing,
DX cleanup, and risk notes that preserve the original intent as accepted plan
updates once reconciled into the plan body.

After the approval gate and in-place reconciliation, continue when the user
asked for execution, the active `/goal` objective covers the handoff or
implementation stage, or the current request is a durable
`$intuitive-flow for <supported-plan-file>.md` run without a review-only stop
point. Otherwise stop with the updated canonical plan ready.

### C. Reviewed Plan, Not Yet Committed To Execution

Use when the plan is accepted, already passed the autoplan precheck, and is not
yet under GSD. A user's implementation approval alone is not enough to enter
this stage.

Before treating any plan as reviewed, run the autoplan precheck. If
`gstack-autoplan`/`autoplan` has not run or its accepted decisions were not
reconciled into the canonical plan, reclassify the request as `Draft Plan
Exists` and run `gstack-autoplan` before `to-issues`, `gsd-ingest-docs`,
`gsd-plan-phase`, or implementation.

Before `to-issues`, `gsd-ingest-docs`, or `gsd-plan-phase`, confirm that the
accepted plan lives in `docs/plans/<slug>.md`. Do not use a generated
`~/.gstack/...test-plan...md`, restore file, review log, or final-gate summary as
the canonical input unless the user explicitly asks to promote that artifact into
the plan file first.

If the original user-supplied file was under `docs/adr/**`, `docs/adrs/**`, or
`docs/human/**`, use the refactored `docs/plans/<slug>.md` for all later phases.
Include the original file in an ingest manifest only when it contains locked
decisions or human-facing truth that GSD must respect; otherwise link it from the
plan as evidence and keep the handoff single-source.

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

If exactly one of these paths matches the repo evidence, auto-select it and log
the rationale. Do not stop merely because the selected route creates or merges
one roadmap phase for the reviewed plan; that is the normal handoff path. Stop
only for competing phase matches, multiple new phases, conflicting locked docs,
or a local-dev/destructive gate.

Use native read-only probes to find the route, then run stateful GSD ingest or
plan generation through `skill-runner`/tmux when the run is long or the main
session should remain clean for supervision. The main session inspects the
created or updated `.planning/` artifacts before continuing.

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

For committed phase execution, prefer `skill-runner`/tmux around the
stateful GSD execution and verification steps. Use native worker subagents for
bounded disjoint implementation or diagnosis slices inside a phase only when
file ownership is explicit and integration remains in the main session.

At GSD closeout/verify/ship, check and update `STATUS.md` when the current
focus, latest phase, next action, blocker, verification state, or handoff
expectation changed. Keep it as a short dashboard; do not mirror the GSD
ledger.

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

### Implementation Closeout, Doc Status, And Parked Todos

After every `intuitive-flow` implementation, inspect the canonical artifact
before the final answer: `docs/plans/<slug>.md`, a refactor scope gate,
`.planning/STATE.md`, or the active phase plan. Extract anything explicitly
parked, deferred, out of scope, future-only, or left for a focused follow-up.
Also include newly discovered but intentionally unimplemented work from the
execution notes, simplify/review output, and verification gaps.

For significant code changes and every big refactor, run a documentation status
check before closeout. Use `$intuitive-doc guard` for a focused changed-file
check, or `$intuitive-doc cleanup <scope>` when the refactor changed public
contracts, commands, package/module layout, examples, proof artifacts, or human
docs. If human-surface docs are drifted, update them to match the current
implementation. If human-surface docs are now outdated implementation detail or
agent-only procedure, move them to `docs/agents/**`, another AI/process folder,
or remove them according to `$intuitive-doc` cleanup rules.

If the work touched domain terms, durable boundaries, or context-backed
acceptance criteria, also re-check the relevant `CONTEXT.md` or `CONTEXT-MAP.md`
entry before closeout. Update it through `grill-with-docs` semantics when the
term or relationship changed; otherwise report that the context was checked and
left unchanged. Do not let context drift hide behind a passing implementation.

Always show parked work in the final implementation closeout. If there is
nothing parked, say `Parked todos: none found in the canonical artifact or
implementation notes.` Do not let parked work disappear inside plan files or
review logs.

Use this compact shape:

```text
Parked todos:
- <item> - parked because <reason>; source: <plan/review/doc>; unpark when <trigger>
```

If `autoplan` ran in the flow, include the autoplan scope-change hint in the
same closeout. Keep accepted scope changes separate from parked/deferred work:
accepted changes are now part of the implemented plan, while parked items are
not done and should not be implied complete.

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
check doc status and run intuitive-doc cleanup when human docs drift
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
- affected human docs or an explicit "no doc impact expected" note
- persistent gate file, usually `docs/plans/refactor-<target>.md`
- stop condition

Use native subagents for report-only architecture scans, stale-path searches,
test discovery, and independent verification probes. Use `skill-runner`/tmux
for a broad or long-running `$intuitive-refactor` execution. Use native worker
subagents for direct edits only when the accepted checklist can be split into
bounded, disjoint ownership scopes.

Once implementation starts, do not keep discovering and implementing new P2
cleanup. Only add newly discovered work if it is a P0/P1 regression found while
verifying the accepted checklist.

For one big refactor, treat documentation status as part of the refactor
closeout, not optional polish. Before marking the refactor `DONE`, compare the
changed implementation surface to `README.md`, `ARCHITECTURE.md`, `STATUS.md`,
and `docs/human/**`. Update current human docs through `$intuitive-doc`, and
move/remove outdated human docs when they are now AI coding guidance, process
history, or obsolete implementation detail. Record the doc check result in the
refactor gate or closeout.

On repeated runs of the same refactor prompt, read the persistent gate file
first. Read the frontmatter `status` marker, falling back to the `## Status`
section. If the status is `DONE` and evidence remains green, stop instead of
re-scanning for fresh cleanup. Park P2-only wording, taste, or "could be
cleaner" findings after `DONE` unless the user explicitly expands the scope or
real usage shows a repeated failure in that seam.

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
0. whole-run goal preflight:
   - chat with the human to confirm Goal, success criteria, stop condition, and
     boundaries before any auto-run work begins
0a. status preflight:
   - read STATUS.md and update it when the current focus, next action, blocker,
     active phase, or verification expectation changed because this flow is
     starting
1. choose idea-shaping mode:
   - direct route (preferred)
   - auto-guided route (experimental)
2. shape the idea:
   - direct -> grill-me, plus office-hours when product/wedge/demand is unclear
   - auto-guided -> intuitive-flow auto-decisions with user-owned stops
3. docs/plans/<feature>.md
4. gstack-autoplan
5. update docs/plans/<feature>.md in place after approval or soft-continuation triage
6. to-issues (optional)
7. choose the GSD handoff:
   - existing phase -> gsd-plan-phase <phase> --prd docs/plans/<feature>.md
   - missing .planning or roadmap scope -> gsd-ingest-docs via manifest, then
     gsd-plan-phase --prd
8. gsd-execute-phase
9. tdd inside risky slices
10. create semantic commits after each completed reviewable unit when enabled
11. simplify changed code
12. create a separate semantic commit for simplify changes when they are a
    distinct reviewable unit
13. gsd-verify-work
14. intuitive-doc guard/cleanup when code or refactor changes human-facing truth
15. create a semantic commit for material docs/status closeout changes when
    enabled
16. check/update STATUS.md after the flow; report when it was checked and left unchanged
```

For parallel standalone tasks, write progress to
`docs/status/active/<task-slug>.md` and keep `STATUS.md` repo-level only.
Create that progress file only for detached or long-running runs that the main
session may monitor or steer; for short waited runs, rely on `skill-runner`
artifacts and the final synthesis.

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
checklist. Before closeout, run the doc-status check and update or relocate
stale human docs when the implementation surface changed.

## Required Checkpoints

Apply Goal And Auto-Run Question Triage before crossing these boundaries. Stop
and ask only for hard-stop decisions. For soft continuations, auto-answer the
recommended option, record the rationale in the relevant artifact or progress
summary, and continue. The whole-run goal preflight is earlier than this triage
and remains a hard human checkpoint.

1. **Whole-run goal preflight:** before any durable whole-flow, auto-guided, or
   `/goal` pipeline starts, confirm the Goal, success criteria, stop condition,
   and needed boundaries with the human. Do not auto-answer this checkpoint
   unless the user's latest message explicitly supplied the full run contract and
   told you to use it as-is.
2. **Idea-shaping route:** for fuzzy ideas, ask whether to use the direct route
   (preferred) or auto-guided route (experimental), unless the user already made
   the choice clear.
3. **Auto-guided user-owned decision:** in auto-guided mode, ask before deciding
   target user, demand premise, narrowest wedge, scope boundary, public contract,
   external-service dependency, paid infrastructure, phase split, or any override
   of stated user intent.
4. **Pre-plan -> Review:** "Is this the plan file you want reviewed?"
5. **Review -> In-place update:** "Do you approve these review decisions, and
   should I update the plan file in place?"
6. **Review -> Issues/GSD:** "Do you approve this updated plan for execution?"
7. **GSD handoff choice:** Auto-select the route when repo evidence gives one
   clear answer: existing phase -> `gsd-plan-phase --prd`; missing planning ->
   manifest + `gsd-ingest-docs --mode new`; existing planning with no matching
   phase -> manifest + `gsd-ingest-docs --mode merge`. Ask only when multiple
   phases match, more than one new phase would be created, locked docs conflict,
   or the route changes roadmap ownership beyond the accepted plan.
8. **Issues -> GSD:** "Do you want GitHub issue tracking, or go straight to GSD?"
9. **GSD plan -> Execute:** "Execute now, or stop after plan generation?"
10. **Many phases:** before creating more than three phases from one prompt, ask
   "Should this be grouped into a smaller set of coherent phases instead?"
11. **Simplify -> Verify:** "Review and clean the changed code with `simplify`
   before final verification, or skip because the change is docs-only/trivial?"
12. **Refactor scope -> Execute:** "Do you approve this P0/P1 checklist and stop
   condition for implementation?"
13. **Refactor doc cleanup:** after a big refactor, auto-run the focused doc
   status check and apply in-scope `$intuitive-doc` cleanup when docs drift.
   Ask only before broad moves/deletions, ambiguous external consumers, or
   protected docs outside the accepted refactor scope.
14. **Local-dev gate:** if proof depends on real simulator, real Gateway, real VLM,
   Docker, GPU, or API keys, stop unless the current session is local and equipped.

## Output Shapes

### If Giving An Upfront Route Brief

Return this before the first artifact or edit:

```text
Current state: <classification>
Selected path: <stage/skill sequence>
Why: <one sentence>
Bypassed/left behind: <stage - reason; stage - reason>
Commit rhythm: <semantic commits enabled | disabled because ...>
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
- success criteria and acceptance criteria
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

### If Completing A Flow Implementation

Return a compact closeout that includes:

- what changed
- verification run and result
- documentation status check and any doc updates/moves/removals, when code or
  refactor work changed human-facing truth
- semantic commit ids created, or why commits were disabled
- autoplan scope changes, if `autoplan` ran or was checked
- `STATUS.md` check/update result
- parked todos, always, including `none found` when empty
- any verification explicitly not run

For parked todos, name the source and the reason it stayed out of scope. Do not
bury parked work behind "follow-ups available"; make it visible as its own
section or sentence.

### If Updating Repo Guidance

Update `AGENTS.md` and `CLAUDE.md` only. Do not scatter workflow rules across
README or architecture docs unless the user asks.

## Anti-Patterns

- Do not run every skill just because it exists.
- Do not start a whole auto-run or durable `/goal` pipeline by silently
  inferring the Goal or success criteria. Confirm the run contract with the
  human first unless the user explicitly supplied it and told you to use it
  as-is.
- Do not silently bypass idea shaping. If `grill-me` or `office-hours` would
  have been plausible, say whether they are selected or skipped and why.
- Do not bypass `CONTEXT.md` / `CONTEXT-MAP.md` when the repo uses them for
  domain language and the requested work depends on terminology, invariants, or
  long-lived contract boundaries.
- Do not treat `CONTEXT.md` as a PRD, scratch pad, implementation checklist, or
  phase execution ledger. It is context evidence maintained in place.
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
- Keep auto-guided shaping provenance clear: style inspiration is not the same
  as running `grill-me` or `office-hours`.
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
- Do not delete or relocate root `CONTEXT.md` during cleanup merely because a
  `docs/plans` or `.planning` artifact exists. Remove only obsolete entries
  after checking references and preserving current domain language.
- Do not use `autoplan` as a code refactor tool.
- Do not close a big refactor without checking whether human docs still match
  the current implementation.
- Do not use `simplify` as a broad refactor scanner. It reviews changed code
  for reuse, quality, and efficiency after implementation.
- Do not use `improve-codebase-architecture` as an unbounded refactor executor;
  produce or load a bounded refactor scope gate first.
- Do not use `to-issues` after GSD execution has already started unless the
  user explicitly wants GitHub tracking added midstream.
- Do not use `tdd` to write all tests up front. Use one red-green-refactor loop
  per behavior.
