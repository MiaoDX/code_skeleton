# Agent Harness References

Last reviewed: 2026-05-21

This page is the human-facing source for external references that shape
Intuitive Flow's agent harness: root instructions, layered local guidance,
skills, hooks, plugins, MCP, subagents, verification, and maintenance cadence.

Use it when updating `AGENTS.md`, `CLAUDE.md`, `skills-src/**`,
`docs/agents/**`, hooks, MCP config, or repo automation. Add new links here
before spreading their lessons into skills. Skills should carry the smallest
operational rule; this page should preserve the source and rationale.

## Working Principles

- Harness quality matters as much as model choice. Treat instructions, skills,
  hooks, MCP, LSP, plugins, and subagents as one designed system.
- Keep always-loaded files lean and layered. Root guidance should give the map,
  critical hazards, and routing rules; local files and skills carry detail.
- Put deterministic checks in tools. Use scripts, tests, CI, hooks, and MCP
  tools for repeatable enforcement instead of asking agents to remember lint,
  format, or generated-output rules.
- Use skills for on-demand expertise. Repeated task workflows belong in skills
  so they do not bloat every session.
- Make improvement explicit. When a source changes how the harness should work,
  update this page, then update shared skill fragments or targeted skills.
- Review the harness on a cadence. Do a meaningful review after major
  model/tool releases and at least every three to six months.

## Skill Self-Improvement Lens

Use this as a maintainer review lens, not as text to paste into every skill's
runtime instructions. Runtime skill text should help the agent perform the
current task. Meta-guidance about maintaining the skill belongs here, in a
planning gate, or in a targeted skill-maintenance run.

When reviewing a skill, preserve a compact WHY / WHAT / HOW contract:

- WHY: the user problem, failure mode, or workflow drift the skill prevents.
- WHAT: the repo surfaces, artifacts, and decisions the skill owns, plus nearby
  surfaces it deliberately does not own.
- HOW: the default workflow, decision gates, evidence ladder, stop condition,
  and handoff artifact that let a future agent improve the skill safely.

Route new guidance to the smallest effective harness layer:

- shared rule across generated intuitive-family skills -> `skills-src/intuitive-common/`
- durable source or doctrine lesson -> this reference page
- repo-specific operational runbook -> `docs/agents/**`
- deterministic enforcement -> scripts, tests, CI, hooks, or MCP tools
- reusable task workflow -> a skill, not a root agent file

Do not add task-specific preferences, product-specific style rules, or one-off
agent mistakes as permanent skill policy. Prefer deleting, shortening, or moving
instructions before adding new runtime rules.

## Official References

| Source | What It Teaches This Repo |
| --- | --- |
| [How Claude Code works in large codebases](https://claude.com/blog/how-claude-code-works-in-large-codebases-best-practices-and-where-to-start) | Treat the harness as the performance layer: `CLAUDE.md`, hooks, skills, plugins, MCP, LSP, and subagents each have different jobs. Keep context layered, scope commands by subdirectory, use hooks for deterministic checks and fresh learnings, and assign ownership for ongoing harness maintenance. |
| [Claude Code best practices](https://code.claude.com/docs/en/best-practices) | Use `/init` as a starting point, keep `CLAUDE.md` useful for project memory, and prefer workflows that let Claude inspect the live codebase instead of relying on stale summaries. |
| [Claude Code memory docs](https://code.claude.com/docs/en/memory) | `CLAUDE.md` files are loaded as project memory. Root and nested memory should be scoped so broad guidance stays broad and local conventions stay local. |
| [Claude Code docs map](https://code.claude.com/docs/en/claude_code_docs_map) | Use the docs map as the canonical starting point when checking whether Claude Code feature guidance has moved or expanded. |
| [Claude Help: CLAUDE.md and better prompts](https://support.claude.com/en/articles/14553240-give-claude-context-claude-md-and-better-prompts) | Project memory should brief a capable new teammate: what matters, what to avoid, where important pieces live, and how to start safely. |
| [Claude blog: using CLAUDE.md files](https://claude.com/blog/using-claude-md-files) | Keep project guidance practical and repo-specific; let it capture conventions, repeated commands, and project context that should survive across sessions. |
| [Codex best practices](https://developers.openai.com/codex/learn/best-practices) | Treat Codex as a coding agent that needs clear environment setup, precise task framing, and verification commands tied to the repo. |
| [Codex AGENTS.md guide](https://developers.openai.com/codex/guides/agents-md) | `AGENTS.md` is Codex's project instruction surface. Keep it local, operational, and aligned with actual repo commands and constraints. |
| [Codex advanced configuration](https://developers.openai.com/codex/config-advanced) | Advanced config such as project root markers and doc byte limits affects how Codex discovers and loads project guidance; repo harness design should account for those knobs. |
| [AGENTS.md open format](https://agents.md/) | `AGENTS.md` is a cross-agent convention supported by multiple coding tools. Prefer it for shared repo rules, with tool-specific deltas kept in tool-specific files. |

## Community And Field Reports

| Source | What It Teaches This Repo |
| --- | --- |
| [HumanLayer: Writing a good CLAUDE.md](https://www.hlyr.dev/blog/writing-a-good-claude-md) | The WHY / WHAT / HOW shape is a useful review lens: explain project purpose, repo shape, and how to build/test/change safely. Keep root guidance short enough to remain useful. |
| [HumanLayer: Skill Issue, harness engineering for coding agents](https://www.humanlayer.dev/blog/skill-issue-harness-engineering-for-coding-agents) | Skills should be evaluated as part of the harness, not treated as static prompts. Prefer narrow, tested workflows over broad instruction dumps. |
| [Serena MCP](https://github.com/oraios/serena) | A language-aware MCP server that exposes symbol-level LSP operations (find/rename symbol, find referencing symbols, document symbols, diagnostics) to coding agents through one connection, covering Python, TypeScript, Rust, Go, and other stacks via underlying language servers. Useful when an agent needs symbol navigation in a repo whose host CLI does not already provide a working LSP path, and when the same setup should work for both Claude Code and Codex (Serena ships a Codex-specific `--context codex` mode). Treat as one option among several; checked-in repo-local language-server config still wins when the project already has one. |

## Repo Upgrade Checklist

When this page gains a source that changes repo practice:

1. Add the link and the lesson here first.
2. Decide the right harness layer: root guidance, nested guidance, shared skill
   fragment, targeted skill, hook, script, MCP config, plugin, or human doc.
3. Update `skills-src/**` or `skills/**` only when the lesson changes runtime
   agent behavior, not merely how maintainers should review the skill.
4. Run `bun run build:skills` after intuitive-family skill source edits.
5. Run `bun run verify`.
6. Update `STATUS.md` or `ARCHITECTURE.md` only when the repo's supported
   commands, public contracts, or proof boundaries changed.

## Parked Questions

- Which skill-quality evals should run against fixture repos before a release?
- Which hook patterns are mature enough to install by default instead of only
  recommending in guidance?
- LSP setup now offers at least two recorded paths: checked-in repo-local
  language-server config (the default) and a Serena MCP connection that exposes
  symbol operations to both Claude Code and Codex. Open question: when should
  `$intuitive-init` prefer one over the other by default, and how should that
  default change as Claude Code's native LSP plugin surface stabilizes?
