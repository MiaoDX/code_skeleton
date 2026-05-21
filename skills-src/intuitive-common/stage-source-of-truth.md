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
