# claude-devkit

**One config. Two AI agents. Every project.**

Stop copy-pasting prompt files. `claude-devkit` is the portable agent-config kit that keeps Claude Code and Codex aligned across every repo on your machine — shared rules, skills, slash commands, and update scripts wired in through symlinks instead of forks.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-toolkit-4EAA25.svg)](scripts/)
[![Claude Code](https://img.shields.io/badge/Claude_Code-ready-111827.svg)](CLAUDE.md)
[![Codex](https://img.shields.io/badge/Codex-ready-111827.svg)](AGENTS.md)

<p align="center">
  <img src="docs/assets/supported-tools.svg" alt="Claude Code, Codex, GSD, MCP servers, and shared skills" width="720">
</p>

<p align="center">
  <a href="https://miaodx.com/LIP/share/ultrathink-to-goal/"><strong>📖&nbsp;&nbsp;From Ultrathink to Goal — A Year of AI Coding Engineering</strong></a><br>
  <sub><i>The interactive slide deck behind this kit · 中文</i></sub>
</p>

## Why You'll Star This

- ⚡ **30-second project onboarding** — one command symlinks every rule, skill, and command into a new repo
- 🔁 **Update once, propagate everywhere** — `git pull` here, every project gets the new rules instantly
- 🤖 **Multi-agent ready** — Claude Code and Codex hand off work to each other through Ralph Loop reviews
- 🧠 **Real workflows, not demo prompts** — distilled from daily multi-agent development, not a starter pack
- 🛠️ **One updater rules them all** — CLIs, MCP servers, skills, commands, and the GSD workflow stay current with a single script

## 30-Second Setup

```bash
# Clone the devkit once
git clone https://github.com/MiaoDX/claude-devkit.git ~/claude-devkit

# Drop it into any project
cd ~/your-project && ~/claude-devkit/scripts/setup.sh

# Install or refresh the supported tooling
~/claude-devkit/scripts/update.sh
```

That's it — your repo now speaks Claude Code and Codex with the same vocabulary.

<table><tr>
<td><img src="docs/assets/terminal-setup.svg" alt="setup.sh on macOS" width="400"></td>
<td><img src="docs/assets/terminal-update.svg" alt="update.sh on Ubuntu" width="400"></td>
</tr><tr>
<td align="center"><b>macOS</b> — setup.sh</td>
<td align="center"><b>Ubuntu</b> — update.sh</td>
</tr></table>

## Use It Everywhere

Run setup from each repo that should inherit the shared agent config:

```bash
cd ~/projects/robotics-arm   && ~/claude-devkit/scripts/setup.sh
cd ~/projects/web-dashboard  && ~/claude-devkit/scripts/setup.sh
cd ~/projects/ml-pipeline    && ~/claude-devkit/scripts/setup.sh
```

Each project gets symlinks back to this devkit. Pull updates here, every project picks them up automatically.

## What Gets Linked

| File or directory | Purpose |
| --- | --- |
| `CLAUDE.md` | Claude Code entrypoint — operating rules, conventions, delegation policy |
| `AGENTS.md` | Codex entrypoint — same intent, Codex-specific constraints |
| `.claude/commands/` | Claude slash commands |
| `.claude/skills/` | Claude Code skills |
| `context/` | Shared reference material projects can pull from |

## What's Inside

### Shared Operating Rules

The same high-value behavior, every project, both agents:

- Parallel delegation for independent exploration, review, and verification
- Main-thread focus on requirements, architecture, integration, and synthesis
- Real tests over excessive mocks
- Visualization-aware validation when logs and numbers can miss rendering or geometry failures
- Repo constraints such as `fetch-mcp`, `uv` + `.venv`, and conservative cleanup behavior

### Multi-Agent Skills

Skills that teach Claude Code to orchestrate Codex and pair on hard problems:

| Skill | What it does |
| --- | --- |
| **codex** | Delegate analysis, review, and refactoring to Codex CLI |
| **intuitive-doc** | Keep AI-developed repos readable through a small human doc surface |

### Ralph Loop Reviews

The Ralph Loop is an iterative `review → triage → fix → verify` cycle. One agent finds problems, another fixes them, both stop when convergence is reached:

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

### Slash Commands & Scripts

| Command or script | Purpose |
| --- | --- |
| `/gsd_squash` | Squash noisy commits into clean, logical git history |
| `/gsd_status [N]` | Show status of the last N GSD phases |
| `scripts/setup.sh` | Symlink this devkit into a project |
| `scripts/update.sh` | Install or update CLIs, MCP servers, skills, commands, and GSD |
| `scripts/convert-docs.sh` | Convert code/docs to LLM-ready markdown |

## How It Works

<p align="center">
  <img src="docs/assets/architecture.svg" alt="Architecture" width="800">
</p>

Edit rules in `CLAUDE.md` and `AGENTS.md` once. Every project that has run `setup.sh` reads them through symlinks. No copies, no drift.

## Supported Tools

| Tool | Integration |
| --- | --- |
| **Claude Code** | Primary runtime — skills, slash commands, review workflows |
| **Codex CLI** | Delegation skills + Ralph Loop code review |
| **GSD workflow** | Vendored lifecycle commands and specialist agents |
| **MCP servers** | `fetch-mcp` and related tooling installed by `update.sh` |

## Contributing

PRs are welcome from humans and AI agents.

The most useful contributions: new skills, sharper shared rules, safer updater behavior, doc improvements, and fixes to workflows that drifted as the underlying CLIs evolved.

## License

MIT — see [LICENSE](LICENSE).
