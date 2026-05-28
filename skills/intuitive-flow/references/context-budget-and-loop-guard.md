# Context Budget And Loop Guard

Use this reference for active-goal resume/debug turns, repeated blockers,
local-hardware probes, long-running verification, or any flow where context
growth is itself becoming a risk.

## Hot Resume

Hot Resume is the default route when all are true:

- an active durable run, thread goal, worker handoff, or canonical status file
  already exists;
- a canonical plan/status source already exists;
- the user asks to continue, resume, inspect status, debug a repeated blocker,
  or prevent looping;
- no new product, scope, public-contract, or roadmap decision is requested.

Hot Resume runs before normal route discovery. Do not start by loading the full
skill reference set, full canonical plan, full `STATUS.md`, full logs, large
source files, or large JSON artifacts.

Read only:

1. the task capsule, if one exists;
2. `git status --short`;
3. `git log -3 --oneline`;
4. at most one focused machine-readable artifact summary.

If no capsule exists and the run is non-trivial, create or request a capsule
before implementation. Continue in the same turn only when the experiment
contract is trivial and the next command is low-risk.

## Context Budgets

Use the smallest budget that can decide the next action.

| Budget | Allowed context |
| --- | --- |
| `low` | Up to four short commands; capsule/status summary; git short state; one focused artifact summary; no large files or extra references. |
| `medium` | One focused source file or one focused plan/status section after explaining why `low` cannot decide. |
| `high` | New planning, broad refactor, unfamiliar repo intake, or route ambiguity only; state why the escalation is necessary. |

Hot Resume defaults to `low`. Escalate only after naming the specific question
that lower context cannot answer.

Prefer `rg`, `jq`, small Python summary snippets, or repo-local summary scripts
over `cat`/`sed` of large files. Do not paste full stderr, full `state.json`,
large test logs, or long generated artifacts into the main session. Summaries
should name the artifact path and the decision it supports.

## Experiment Contract

Before implementation in Hot Resume, emit this contract:

```text
Context budget: <low | medium | high, plus reason if not low>
Current blocker: <one sentence>
Hypothesis: <one falsifiable claim>
Expected decision delta: <what next decision changes if this succeeds/fails>
Command/artifact: <exact command or artifact summary path>
Success means: <observable outcome>
Failure means: <observable outcome and next stop/route>
No-touch scope: <files, subsystems, services, or workflows not touched>
```

If `Expected decision delta` is empty, do not make the change. Read-only
inspection may continue only to form a decision-changing contract.

## Loop Breaker

Track a simple blocker fingerprint in the contract or capsule:

```text
blocker_kind: <stable category, such as isaac_semantic_aov>
root_cause_classification: <current best classification>
last_decision_delta: <what changed last turn>
```

If the same `blocker_kind` appears in two consecutive resume/debug turns without
a changed root-cause classification, the next turn must not make another
low-information observability edit.

Choose one:

- run a root-cause comparison experiment that can change the classification;
- mark/defer the capability as blocked in canonical state and continue a
  different requirement;
- ask the user for a hard decision.

A change is not aligned progress if it only records more details about the same
blocker without changing the next decision. Observability edits are acceptable
only when they name the decision they can change.

## Local Hardware And External Services

For GPU, simulator, real-device, paid API, private-data, or other external
proofs, keep the main session as the control plane. The probe may run locally,
but the main session should receive a compact result:

```json
{
  "status": "passed|failed|blocked",
  "hypothesis": "...",
  "artifact": "...",
  "decision": "..."
}
```

Do not stream full local logs into the main context unless a short summary is
insufficient to decide the next action.

## Capsule

For durable local-debug work, maintain a compact capsule under a project-local
status surface such as `docs/status/active/<task>.md` when the repo has one.
Use an equivalent task-owned file when it does not.

The capsule should contain only:

- current blocker;
- blocker fingerprint;
- last proven evidence;
- next hypothesis;
- next command/artifact;
- stop condition;
- no-touch scope;
- parked work.

The capsule is a resume accelerator, not a replacement for canonical plans,
status, or verification artifacts. Update canonical source-of-truth files only
when project-level focus, decisions, blockers, or verification expectations
materially change.
