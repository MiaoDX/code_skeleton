## Human/Agent Surface Rule

The default human-facing source of truth is intentionally small:

- `README.md`
- `ARCHITECTURE.md`
- `STATUS.md`
- `docs/human/**`

`AGENTS.md` and `CLAUDE.md` are agent-operational docs. Use them for startup
rules, local hazards, command pointers, and skill routing, but do not treat them
as human-authoritative project truth by default.

Agent planning, generated evidence, history, and working notes belong in
explicit agent/process surfaces such as `.planning/**`, `docs/plans/**`,
`docs/retrospectives/**`, `docs/status/active/**`, and `output/**` unless a
human doc intentionally promotes a specific artifact into current truth.
