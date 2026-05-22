# Intuitive Flow Audit Prompt

Last reviewed: 2026-05-22

Use this prompt when a human wants to periodically review `skills/intuitive-flow`
against current agent-tool capabilities and community practice. The goal is to
keep the default workflow skill high quality without turning its runtime
instructions into a self-review manual.

Good triggers:

- a major Claude Code, Codex, GSD, gstack, or community skill release
- a recurring three-to-six-month harness review
- evidence that `$intuitive-flow` is producing worse plans, handoffs,
  verification, or closeouts than newer available practice
- a deliberate research pass across high-star community skills, commands,
  hooks, plugins, or workflow repos

## Prompt

```text
Run a report-first audit of the `intuitive-flow` skill against current official
agent capabilities and high-signal community skill practice.

Goal:
- Decide whether `skills/intuitive-flow` still deserves to be the default
  workflow skill for fuzzy idea shaping, planning, handoff, implementation,
  cleanup, verification, and closeout.
- Identify concrete updates that would improve execution quality across repos.
- Keep runtime skill text small: do not add meta-maintenance guidance to
  `skills/intuitive-flow/SKILL.md` unless it changes what an agent must do during
  a real workflow run.

Default mode:
- Report only. Do not edit files unless the latest user message explicitly asks
  for implementation.
- If implementation is later requested and the change is more than a tiny doc
  tweak, create or update one bounded `docs/plans/` gate before editing runtime
  skills, scripts, or tests.

Read local truth first:
- `README.md`
- `ARCHITECTURE.md`
- `STATUS.md`
- `docs/human/agent-harness-references.md`
- `docs/human/skill-self-improvement-audit.md`
- `skills/intuitive-flow/SKILL.md`
- relevant `skills/intuitive-flow/references/*.md` only when the route being
  audited needs that detail

Then research current external practice:
- official Claude Code docs, release notes, skills, hooks, plugins, MCP,
  subagents, and memory guidance
- official Codex docs, release notes, AGENTS.md guidance, MCP/tooling guidance,
  and built-in planning or execution features
- high-star public coding-agent skills, commands, hooks, plugins, and workflow
  repos with concrete repeatable practices
- community writeups that include reproducible workflow, harness, or evaluation
  lessons rather than only opinions

For every external source used:
- record the link, access date, and distilled lesson
- distinguish official capability from community practice
- say whether the lesson should update
  `docs/human/agent-harness-references.md`, `docs/human/**`,
  `docs/agents/**`, `skills/intuitive-flow/**`, scripts/tests, or nothing
- do not treat a high-star repo as better by default; require an explicit
  quality signal, adoption signal, or A/B test hypothesis

Audit questions:
- Is `skills/intuitive-flow/SKILL.md` still a compact router, with conditional
  detail kept in `references/` and output shapes in `templates/`?
- Are source-of-truth boundaries still correct for `docs/plans/`,
  `.planning/`, `STATUS.md`, `CONTEXT.md`, GSD artifacts, verification reports,
  and closeout notes?
- Are `autoplan`, GSD handoff, `simplify`, verification, semantic commits, and
  parked-todo closeout still routed at the right stage?
- Are any current steps obsolete because Claude Code, Codex, GSD, gstack, MCP,
  LSP tooling, or community skills now provide a stronger built-in path?
- Has the skill accumulated brittle current-tool mechanics, duplicated policy,
  one-off lessons, or rules that belong in scripts/tests instead?
- Are there candidate community sub-skills worth A/B testing before adopting?
- Are there missing deterministic checks that would catch drift better than
  adding more prompt text?

Use these severity labels:
- P0: current flow is broken, misleading, or likely to corrupt source of truth
- P1: likely quality regression versus available official or proven community
  practice
- P2: useful maintenance improvement with bounded upside
- Parked: interesting, but not actionable without stronger evidence

A/B test candidates must include:
- candidate source and exact behavior to test
- baseline behavior in current `intuitive-flow`
- fixture repo or task shape
- success metrics, such as plan quality, source-of-truth clarity, verification
  rate, token cost, user intervention count, or time to closeout
- stop condition and adoption threshold

Return this report:

1. Summary verdict:
   - keep as-is, update docs only, update runtime skill, add deterministic
     validation, run A/B test, or retire/replace a route
2. Current architecture fit:
   - where `intuitive-flow` still matches local `README.md`, `ARCHITECTURE.md`,
     `STATUS.md`, and the self-improvement audit
3. External drift findings:
   - official capability drift and community-practice drift, each with sources
4. Runtime skill findings:
   - P0/P1/P2/Parked findings tied to specific `intuitive-flow` behaviors
5. Recommended changes:
   - update `docs/human/agent-harness-references.md`
   - update this prompt or another human doc
   - update `docs/agents/**`
   - update `skills/intuitive-flow/**`
   - add scripts/tests/checks
   - run A/B tests
   - no action / parked
6. Verification plan:
   - commands to run, expected evidence, and what must be manually inspected

Guardrails:
- Do not patch installed user-level skills or global agent tooling by default.
- Do not edit vendored or third-party skills unless the task is explicitly
  upstream maintenance.
- Do not add a self-review section to `skills/intuitive-flow/SKILL.md`.
- Prefer deleting, moving, or testing brittle guidance before adding more
  runtime prompt text.
- Preserve safety, provenance, verification, and source-of-truth gates unless
  a stronger replacement is specified.
```

## Local Verification

After changing this prompt or any linked skill-maintenance docs, run:

```bash
bun run check:skills
bun run verify
```

If an audit recommends changes to `skills/intuitive-flow/**`, also inspect the
diff manually to confirm `SKILL.md` remains the small entrypoint and that
conditional detail stays in `references/` or `templates/`.
