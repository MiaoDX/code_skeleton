## Skill Self-Improvement Rule

This section governs maintenance of the skill itself, not ordinary execution in
the target repo.

When editing this skill, preserve a compact WHY / WHAT / HOW contract:

- WHY: the user problem, failure mode, or workflow drift the skill prevents.
- WHAT: the repo surfaces, artifacts, and decisions the skill owns, plus the
  nearby surfaces it deliberately does not own.
- HOW: the default workflow, decision gates, evidence ladder, stop condition,
  and handoff artifact that let a future agent improve the skill safely.

Before adding long instructions, route them to the right harness layer:

- shared rule across intuitive-family skills -> `skills-src/intuitive-common/`
- durable source or doctrine lesson -> `docs/human/agent-harness-references.md`
- repo-specific operational runbook -> `docs/agents/**`
- deterministic enforcement -> scripts, tests, CI, hooks, or MCP tools
- reusable task workflow -> a skill, not a root agent file

When a new official doc, field report, or model/tool change alters the guidance,
record the link and distilled lesson in `docs/human/agent-harness-references.md`,
then update this skill with only the smallest operational rule that changes how
agents should act.

For this repo, edit intuitive-family skills in `skills-src/`, run
`bun run build:skills`, and verify with `bun run verify` so generated `skills/`
output stays reproducible.
