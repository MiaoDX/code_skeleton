# claude-devkit

**AI-native repo init. Shared skills and commands. Project-local agent guidance.**

`claude-devkit` is a portable workflow kit for Claude Code and Codex. Its core
idea is simple: reusable workflows live in skills, while every repo keeps its
own `CLAUDE.md` and `AGENTS.md` with local commands, constraints, and
source-of-truth rules.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-toolkit-4EAA25.svg)](scripts/)
[![Claude Code](https://img.shields.io/badge/Claude_Code-ready-111827.svg)](CLAUDE.md)
[![Codex](https://img.shields.io/badge/Codex-ready-111827.svg)](AGENTS.md)

<p align="center">
  <img src="docs/assets/supported-tools.svg" alt="Claude Code, Codex, GSD, MCP servers, and shared skills" width="720">
</p>

<p align="center">
  <a href="https://miaodx.com/LIP/share/ultrathink-to-goal/"><strong>From Ultrathink to Goal - A Year of AI Coding Engineering</strong></a><br>
  <sub><i>The interactive slide deck behind this kit · 中文</i></sub>
</p>

## Why This Exists

- **AI-native init** - give the agent `$intuitive-init`, let it inspect the repo, run `/init`-style discovery when available, and propose local guidance updates.
- **Project-local agent files** - `CLAUDE.md` and `AGENTS.md` should contain each repo's real commands, hazards, and workflow rules.
- **Reusable skills** - shared workflows live in skills so repos can opt into them without pasting manuals into root guidance.
- **Periodic refresh** - rerun `$intuitive-init` after weeks of drift, new command surfaces, or repeated agent mistakes.
- **One updater** - CLIs, MCP servers, skills, commands, and the GSD workflow stay current with a single script.

## AI-Native Init

In the target repo, give your AI agent the skill file and ask it to initialize
local guidance:

```text
Read or paste this skill:
https://github.com/MiaoDX/claude-devkit/blob/main/skills/intuitive-init/SKILL.md

Then run:
Use $intuitive-init to initialize this repo's AGENTS.md and CLAUDE.md.
Run /init-style discovery if available.
Preserve project-specific instructions.
Propose a diff before applying.
```

For agents that can fetch raw files directly, use:

```text
https://raw.githubusercontent.com/MiaoDX/claude-devkit/main/skills/intuitive-init/SKILL.md
```

<p align="center">
  <img src="docs/assets/terminal-init.svg" alt="AI-native intuitive-init flow" width="720">
</p>

## Optional Tool Install

Clone the devkit when you want the update scripts and local skill sync:

```bash
git clone https://github.com/MiaoDX/claude-devkit.git ~/claude-devkit
~/claude-devkit/scripts/update.sh
```

`scripts/update.sh` installs or refreshes supported CLI tools, MCP servers,
remote skills, local root `skills/*`, and command-to-skill adapters. It does
not initialize project root agent files; use `$intuitive-init` for that.

## Preferred Skills

| Skill | Use it for |
| --- | --- |
| **intuitive-init** | Merge `/init` suggestions, devkit defaults, and repo evidence into local `AGENTS.md` / `CLAUDE.md` |
| **intuitive-doc** | Keep human-facing docs small, current, and separated from agent evidence/history |
| **intuitive-layout** | Improve repo/folder organization before deeper architecture work |
| **intuitive-ut** | Organize, prune, mark, and refactor tests around behavior |
| **hybrid-phase-pipeline** | Move a fuzzy idea through plan review, GSD handoff, execution, cleanup, and verification |
| **refactor-scope-gate** | Bound broad refactors with accepted severities, evidence, and a stop condition |
| **simplify** | Review changed code for reuse, quality, and efficiency before final verification |
| **codex** | Delegate analysis, review, and refactoring to Codex CLI where available |

## Shared Operating Rules

The root `CLAUDE.md` and `AGENTS.md` in this repo are starter guidance, not files
that every project should inherit wholesale. They capture useful defaults:

- parallel delegation for independent exploration, review, and verification
- main-thread focus on requirements, architecture, integration, and synthesis
- real tests over excessive mocks
- visualization-aware validation when logs and numbers can miss rendering or geometry failures
- repo-local command, environment, and cleanup constraints

## Ralph Loop Reviews

The Ralph Loop is an iterative `review -> triage -> fix -> verify` cycle. One
agent finds problems, another fixes them, and both stop when convergence is
reached:

| Skill | Reviews | Reviewer |
| --- | --- | --- |
| `codex-plan-ralph-refactor` | GSD phase plans | Codex |
| `codex-impl-ralph-refactor` | Implemented code | Codex |
| `agent-teams-plan-ralph-refactor` | GSD phase plans | Claude agent teams |
| `agent-teams-impl-ralph-refactor` | Implemented code | Claude agent teams |

```bash
# Review plans before executing
/codex-plan-ralph-refactor 38

# Review code after implementation, auto-fixing must-fix issues
/codex-impl-ralph-refactor 42 --fix-level must
```

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/update.sh` | Install or update CLIs, MCP servers, skills, commands, and GSD |
| `scripts/convert-docs.sh` | Convert code/docs to LLM-ready markdown |

## How It Works

<p align="center">
  <img src="docs/assets/architecture.svg" alt="Architecture" width="800">
</p>

Root agent files are initialized by the agent in the target repo. Reusable
workflow knowledge lives in skills, and install/update automation stays in
scripts.

## Supported Tools

| Tool | Integration |
| --- | --- |
| **Claude Code** | Primary runtime - skills, slash commands, review workflows |
| **Codex CLI** | Delegation skills + Ralph Loop code review |
| **GSD workflow** | Vendored lifecycle commands and specialist agents |
| **MCP servers** | `fetch-mcp` and related tooling installed by `update.sh` |

## Contributing

PRs are welcome from humans and AI agents.

The most useful contributions: new skills, sharper shared rules, safer updater
behavior, doc improvements, and fixes to workflows that drifted as the
underlying CLIs evolved.

## License

MIT - see [LICENSE](LICENSE).
