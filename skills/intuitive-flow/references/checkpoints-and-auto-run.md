# Checkpoints And Auto-Run Policy

Use this reference before whole-flow, durable, auto-guided, or `/goal` runs and
before crossing review, GSD, execution, cleanup, or verification boundaries.

## Whole-Run Goal Preflight

Before starting a whole-flow or durable auto-run that may cross review, GSD
handoff, execution, cleanup, and verification, chat with the human until the run
contract is explicit. Do this before `autoplan`, `to-issues`, GSD ingest/plan,
`skill-runner`, autonomous execution, or auto-confirming downstream gates.

If a canonical plan already exists, inspect it first and summarize the inferred
contract instead of asking the user to restate everything.

Required run contract:

- Goal: concrete outcome
- Success criteria: observable done signals and required verification when known
- Stop condition: reviewed plan, GSD plan, implemented and verified code,
  PR-ready branch, or another boundary
- Boundaries/non-goals: only when needed to prevent scope, cost, safety, or
  compatibility drift

Prompt shape:

```text
Before I start the whole run, I want to lock the run contract.

Goal: <inferred or missing>
Success criteria: <inferred or missing>
Stop condition: <inferred or missing>
Boundaries/non-goals: <inferred or "none stated">

Is this the goal and success criteria you want me to execute against? If not,
what should change?
```

Start only after the user confirms/corrects the contract, or when their latest
message explicitly supplied the full contract and told you to use it as-is.

## Decision Triage

During a confirmed durable run, classify each question or downstream gate:

| Class | Action |
| --- | --- |
| Soft continuation | Auto-answer the recommended/default option, log briefly, continue |
| Hard stop | Stop and ask once with concrete impact |
| Unclear impact | Investigate repo/docs context; if still materially risky, hard stop; otherwise choose the smallest reversible default |

Soft continuation examples:

- preserves the user's accepted plan
- restates premises already present in the canonical artifact
- chooses an existing repo convention
- runs normal review, test, verification, or doc sync
- updates the plan with accepted review findings
- chooses a reversible low-blast-radius default
- selects the only GSD handoff route supported by evidence

Hard-stop examples:

- target user, demand premise, narrowest wedge, product direction
- scope boundary, public contract, data model, phase split, roadmap ownership
- security/privacy posture, paid infrastructure, external service, API key use
- destructive action, real-device/local-dev requirement, or unavailable proof
- locked-doc/ADR conflict, multiple plausible phases, or user intent override

For `autoplan` premise gates, auto-confirm only when premises restate the plan
or add low-risk assumptions needed for review. Stop when a premise is new,
contradicted by repo evidence, disputed by review voices, or changes product,
scope, contract, security, privacy, cost, data, services, or ownership.

If a downstream skill asks a `Confirm`/`Revise` style question and the gate is a
soft continuation, answer `Confirm` with a one-line rationale instead of waiting
for the user.

## GSD Handoff Gates

Auto-continue when exactly one routing row applies:

- existing roadmap phase clearly matches -> `gsd-plan-phase <phase> --prd`
- `.planning/` missing -> manifest + `gsd-ingest-docs --mode new`, inspect
  phase, then `gsd-plan-phase --prd`
- `.planning/` exists and no phase matches -> manifest +
  `gsd-ingest-docs --mode merge`, inspect created/changed phase, then
  `gsd-plan-phase --prd`

Stop for multiple plausible existing phases, more than one new phase, locked
doc conflicts, or changes to roadmap ownership beyond the accepted plan.

## Required Checkpoints

Apply decision triage before crossing these boundaries:

1. Whole-run goal preflight: always human-owned unless the latest message
   supplied the full run contract and told you to use it as-is.
2. Idea-shaping route: ask direct vs auto-guided for fuzzy ideas unless already
   clear.
3. Auto-guided user-owned decision: ask before target user, demand premise,
   wedge, scope, public contract, services, cost, phase split, or overrides.
4. Pre-plan -> Review: confirm the plan file is ready for review unless the run
   contract already says to continue.
5. Review -> In-place update: update plan only after approval or soft-continuation
   classification.
6. Review -> Issues/GSD: continue only when execution is covered by the request
   or active run contract.
7. GSD handoff choice: auto-select only with one clear route.
8. Issues -> GSD: ask if GitHub issue tracking vs direct GSD is material.
9. GSD plan -> Execute: continue only when execution is covered by request or
   run contract.
10. Many phases: ask before creating more than three phases.
11. Code slice -> Next slice/cleanup: when local code changed and commits are
   enabled, create a semantic slice commit after focused proof before starting
   the next slice or cleanup pass.
12. Simplify -> Verify: skip only for docs-only/trivial changes or explicit user
   instruction.
13. Refactor scope -> Execute: require accepted P0/P1 checklist and stop
   condition.
14. Refactor doc cleanup: auto-run focused doc status; ask before broad
   moves/deletions or protected docs outside scope.
15. Local-dev gate: stop when proof needs real simulator, Gateway, VLM, Docker,
   GPU, API keys, or similar unavailable resources.
