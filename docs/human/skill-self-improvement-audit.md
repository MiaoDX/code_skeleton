# Skill Self-Improvement Audit

Last reviewed: 2026-05-17

This audit applies the self-improvement lens from
[`agent-harness-references.md`](agent-harness-references.md) to every
repo-owned root skill. The goal is not to paste a maintenance prompt into every
skill. The goal is to find which skill texts should become smaller, clearer, or
better routed across docs, scripts, hooks, tests, and skills.

## Result

The lens mostly changes where maintenance knowledge lives. It should not become
always-loaded runtime text inside task skills.

Immediate correction:

- Remove the runtime `Skill Self-Improvement Rule` block from generated
  `intuitive-*` skills.
- Keep the WHY / WHAT / HOW lens in human docs.
- Use this audit as the baseline for later skill-specific cleanup.

## Audit Table

| Skill | WHY Clarity | WHAT Boundary | HOW / Stop Condition | Recommendation |
| --- | --- | --- | --- | --- |
| `intuitive-doc` | Strong: keep human docs current and small. | Strong: owns human-facing docs and boundary drift, skips agent files by default. | Strong: audit/update/guard modes and claim verification are clear. | No runtime self-improvement block. Later slim examples if the doc keeps growing. |
| `intuitive-flow` | Strong but broad: routes fuzzy ideas to verified work. | Medium: owns staging and handoffs, but the file is long because it encodes many downstream gates. | Strong: checkpoints and routing are explicit. | Candidate for future extraction into smaller references or subflow docs, but do not add meta text. |
| `intuitive-init` | Strong after harness refresh: builds repo-local agent harness. | Strong: owns `AGENTS.md`, `CLAUDE.md`, `docs/agents/**`, init discovery, hooks, skills, and MCP routing. | Strong: modes and stop conditions are explicit. | Keep current runtime harness guidance; avoid adding maintainer meta. |
| `intuitive-layout` | Strong: make repo layout easier to navigate. | Strong: owns bounded layout slices and path consumers. | Strong: proposal shape and verification are concrete. | No immediate change. |
| `intuitive-migrate` | Strong: one legacy-repo cleanup loop. | Strong: orchestrates downstream skills rather than duplicating them. | Strong: route and stop condition are concise. | No immediate change. |
| `intuitive-refactor` | Strong: bound aggressive cleanup. | Strong: owns scope gates, severities, evidence, parked ideas. | Strong: persistent gate and ladder are clear. | No immediate change. |
| `intuitive-squash` | Strong: rewrite noisy agent history safely. | Strong: owns commit grouping and safety protocol only. | Strong: explicit confirmation and verify commands. | No immediate change. |
| `intuitive-tests` | Strong: improve test suite signal. | Strong: owns test taxonomy, pruning, fixture/layout cleanup. | Strong but long: many examples are useful runtime guidance. | Candidate for later slimming if examples start crowding task execution. |
| `simplify` | Strong: review changed code for reuse, quality, efficiency. | Medium: owns diff-scoped review; adapter block is large and mechanical. | Medium: process is clear, but the codex adapter and reviewer prompts dominate the file. | Do not add meta text. Future candidate: move adapter/mechanics to shared adapter docs or generator if more skills use it. |
| `skill-runner` | Strong: supervise real skill-driven development runs. | Strong: owns runner orchestration and reusable-skill defect detection. | Strong: verdicts, policy, and stop conditions are explicit. | Already has skill-change policy. Do not add another meta block. |

## What The Lens Changes

- It makes `docs/human/agent-harness-references.md` the durable place for
  external lessons and skill-maintenance doctrine.
- It argues against adding self-maintenance sections to runtime skill text.
- It exposes two future cleanup candidates: `intuitive-flow` because it is
  necessarily broad, and `simplify` because its adapter/mechanics are large.
- It does not justify broad rewrites today. Most skills already have clear
  execution contracts and stop conditions.

## Parked Follow-Ups

- Add a lightweight manifest check later if the repo wants to enforce that each
  root skill has a clear WHY / WHAT / HOW shape without requiring a literal
  section heading.
- Evaluate whether `simplify`'s Codex adapter block should be generated or
  moved to a shared reference if more adapted skills appear.
- Consider splitting long `intuitive-flow` reference material only after a real
  task shows that its size hurts execution quality.
