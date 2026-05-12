# intuitive-flow

**An opinionated operating model for agent-written software.**

`intuitive-flow` is a portable workflow kit for Claude Code and Codex. It keeps
the human surface small, puts reusable workflows in skills, and lets every repo
own its local `CLAUDE.md` / `AGENTS.md` guidance.

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

AI agents write all my code.

That means the repo needs two surfaces.

The human surface should be tiny: `README.md`, `ARCHITECTURE.md`, `STATUS.md`,
`docs/human/**`, the layout, and the tests. This is where I decide what the
project is, what good means, and what must not break.

Everything else is agent territory: source code, plans, logs, generated
evidence, retrospectives, scratch work, and low-level churn. Humans can inspect
it when something is risky or broken. They should not have to live there.

I do not want a giant process system. I want community best practices where
they already exist, and a small set of intuitive skills where they do not.

The workflow should make the big questions expensive and the small questions
cheap: use `office-hours` or `grill-me` for what to build, `intuitive-flow` for
normal development, and `intuitive-refactor` when it is time to clean the
system without drifting forever.

If the human docs are good enough, an agent should be able to rebuild the
project in another language or framework. That is the bar.

See [BELIEFS.md](BELIEFS.md) for the full doctrine.

## AI-Native Init

In the target repo, give your AI agent the skill file and ask it to initialize
local guidance:

```text
Read or paste this skill:
https://github.com/MiaoDX/intuitive-flow/blob/main/skills/intuitive-init/SKILL.md

Then run:
Use $intuitive-init to initialize this repo's AGENTS.md and CLAUDE.md.
Run /init-style discovery if available.
Preserve project-specific instructions.
Propose a diff before applying.
```

For agents that can fetch raw files directly, use:

```text
https://raw.githubusercontent.com/MiaoDX/intuitive-flow/main/skills/intuitive-init/SKILL.md
```

<p align="center">
  <img src="docs/assets/terminal-init.svg" alt="AI-native intuitive-init flow" width="720">
</p>

## Optional Tool Install

Clone Intuitive Flow when you want the update scripts and local skill sync:

```bash
git clone https://github.com/MiaoDX/intuitive-flow.git ~/intuitive-flow
~/intuitive-flow/scripts/update.sh
```

`scripts/update.sh` installs or refreshes supported CLI tools, MCP servers,
remote skills, local root `skills/*`, and command-to-skill adapters. It does
not initialize project root agent files; use `$intuitive-init` for that.

## Preferred Skills

`intuitive-flow` is both the project and the default development skill: the repo
defines the operating model, and `$intuitive-flow` runs it inside a target repo.

| Skill | Use it for |
| --- | --- |
| **intuitive-init** | Merge `/init` suggestions, Intuitive Flow defaults, and repo evidence into local `AGENTS.md` / `CLAUDE.md` |
| **intuitive-doc** | Keep human-facing docs small, current, and separated from agent evidence/history |
| **intuitive-layout** | Improve repo/folder organization before deeper architecture work |
| **intuitive-tests** | Organize, prune, mark, and refactor tests around behavior |
| **intuitive-flow** | Move a fuzzy idea through plan review, GSD handoff, execution, cleanup, and verification |
| **intuitive-refactor** | Bound broad refactors with accepted severities, evidence, and a stop condition |
| **intuitive-squash** | Compress noisy local agent history into a clean reviewable commit story |

## Shared Operating Rules

The root `CLAUDE.md` and `AGENTS.md` in this repo are starter guidance, not files
that every project should inherit wholesale. They capture useful defaults:

- parallel delegation for independent exploration, review, and verification
- main-thread focus on requirements, architecture, integration, and synthesis
- real tests over excessive mocks
- visualization-aware validation when logs and numbers can miss rendering or geometry failures
- repo-local command, environment, and cleanup constraints

## Scripts

| Script | Purpose |
| --- | --- |
| `scripts/update.sh` | Install or update CLIs, MCP servers, skills, commands, and GSD |

Bash scripts remain the orchestration entrypoints. Structured script logic that
needs parsing, validation, or tests lives in Bun-run TypeScript under
`scripts/lib/`.

For script development:

```bash
bun install
bun run verify
```

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
| **Codex CLI** | Shared skills, delegation, and verification workflows |
| **GSD workflow** | Vendored lifecycle commands and specialist agents |
| **MCP servers** | `fetch-mcp` and related tooling installed by `update.sh` |

## Contributing

PRs are welcome from humans and AI agents.

The most useful contributions: new skills, sharper shared rules, safer updater
behavior, doc improvements, and fixes to workflows that drifted as the
underlying CLIs evolved.

## License

MIT - see [LICENSE](LICENSE).
