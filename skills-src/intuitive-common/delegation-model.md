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
