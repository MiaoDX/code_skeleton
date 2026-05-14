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
