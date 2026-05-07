---
name: refactor-safety-ladder
description: Plan and verify architecture reviews, refactors, and test-harness work through a confidence ladder. Use when the user wants to run improve-codebase-architecture safely, refactor without breaking behavior, decide which tests/harnesses are enough, or build/refine verification gates before changing code.
---

# Refactor Safety Ladder

Use this skill to keep architecture review and refactoring work honest. It does
not replace `/improve-codebase-architecture`, `/tdd`, `/diagnose`, `/to-prd`,
or `/to-issues`; it routes between them and decides what evidence is required
before code changes are considered safe.

## Operating rule

Start report-only. Do not edit production code until the needed confidence
level is explicit and either already covered or covered by a new test/harness
slice.

If the user asks for a full autonomous run, continue only through safe,
deterministic gates. Pause before local-only, paid-provider, Docker/Gateway, or
human-judgment gates unless the user explicitly authorized them.

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

### 1. Classify the work

Read the user's goal and identify:

- target area or module
- whether the request is bug/perf shaped, architecture shaped, or feature shaped
- user-visible behavior that must not regress
- minimum required confidence level
- whether any evidence is local-only, paid, slow, or environment-sensitive

If repo-local docs exist, read the agent config first:

- `docs/agents/domain.md`
- `docs/agents/issue-tracker.md`
- `docs/agents/triage-labels.md`

Then read the repo's required orientation docs before making claims.

### 2. Choose the route

Pick the smallest route that fits:

- unclear architecture or seam quality -> run `/improve-codebase-architecture`
  in report-only mode
- missing behavior coverage -> run `/tdd` to add one public-interface test
  before refactoring
- bug, flake, perf regression, or known blind spot -> run `/diagnose` to build
  a reproducible feedback loop first
- large feature or harness program -> run `/to-prd`, then `/to-issues`
- existing issue queue or TODO grooming -> run `/triage`

Do not run `/to-issues` before the parent plan or PRD is shaped enough to split
into vertical slices.

### 3. Produce a safety plan

Before implementation, present this compact plan:

```markdown
## Refactor Safety Plan

- Target:
- Change type:
- Minimum confidence level:
- Existing evidence:
- Missing evidence:
- Local-only gates:
- Recommended next skill:
- Stop condition:
```

The stop condition is the point where the agent should pause rather than
continue blindly, such as "requires real OpenClaw Gateway run" or "needs user
approval of architecture candidate."

### 4. Execute one vertical slice

When the user approves action, work in one tracer bullet:

1. Add or identify the proof first.
2. Watch the proof fail if adding new coverage.
3. Apply the smallest implementation/refactor.
4. Run the required ladder levels.
5. Summarize evidence and residual risk.

Never batch unrelated refactors. If a proposed architecture cleanup touches
multiple seams, split it with `/to-issues`.

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

## Output when only advising

If the user is still discussing strategy, do not edit files. Return:

- recommended command namespace
- proposed confidence ladder
- which Matt Pocock skill should be used next
- which part should become a PRD or issue only if it is large enough

## Completion summary

After action, report:

- files changed, if any
- ladder levels run and results
- gates skipped and why
- whether the change is safe for AFK agent pickup, human review, or local
  validation
