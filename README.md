# claude-devkit

**Install once. Keep Claude Code, Codex, and Gemini CLI aligned in every repo.**

`claude-devkit` is a portable agent-config kit for developers who use multiple AI coding tools. It gives every project the same rules, skills, slash commands, update scripts, and multi-agent workflows through symlinks instead of copy-pasted prompt files.

[![License: MIT](https://img.shields.io/badge/License-MIT-blue.svg)](LICENSE)
[![Shell](https://img.shields.io/badge/Shell-toolkit-4EAA25.svg)](scripts/)
[![Claude Code](https://img.shields.io/badge/Claude_Code-ready-111827.svg)](CLAUDE.md)
[![Codex](https://img.shields.io/badge/Codex-ready-111827.svg)](AGENTS.md)
[![Gemini CLI](https://img.shields.io/badge/Gemini_CLI-ready-111827.svg)](GEMINI.md)

<p align="center">
  <img src="docs/assets/supported-tools.svg" alt="Claude Code, Codex, Gemini CLI, GSD, MCP servers, and shared skills" width="720">
</p>

## Why Use It

AI coding agents are useful, but their setup usually drifts across projects: one repo has an old `CLAUDE.md`, another has stale Codex rules, another has missing skills, and every tool learns a different workflow.

`claude-devkit` gives you one source of truth:

- **One shared rule set** for Claude Code, Codex, and Gemini CLI
- **Project setup in seconds** with symlinked agent files and Claude commands
- **Reusable skills** for delegation, review loops, docs maintenance, and cross-agent workflows
- **Single updater** for CLIs, MCP servers, skills, local commands, and the vendored GSD workflow
- **Practical defaults** from real multi-agent development work, not a demo prompt pack

## 30-Second Setup

Clone the devkit once:

```bash
git clone https://github.com/MiaoDX/claude-devkit.git ~/claude-devkit
```

Link it into any project:

```bash
cd ~/your-project
~/claude-devkit/scripts/setup.sh
```

Install or update the supported tooling:

```bash
~/claude-devkit/scripts/update.sh
```

Works on macOS and Linux:

<table><tr>
<td><img src="docs/assets/terminal-setup.svg" alt="setup.sh on macOS" width="400"></td>
<td><img src="docs/assets/terminal-update.svg" alt="update.sh on Ubuntu" width="400"></td>
</tr><tr>
<td align="center"><b>macOS</b> - setup.sh</td>
<td align="center"><b>Ubuntu</b> - update.sh</td>
</tr></table>

## Use It Everywhere

Run the same setup command from each repo that should inherit the shared agent config:

```bash
cd ~/projects/robotics-arm && ~/claude-devkit/scripts/setup.sh
cd ~/projects/web-dashboard && ~/claude-devkit/scripts/setup.sh
cd ~/projects/ml-pipeline   && ~/claude-devkit/scripts/setup.sh
```

Each project gets symlinks back to this devkit, so updates propagate without copying files around.

## What Gets Linked

| File or directory | Purpose |
| --- | --- |
| `AGENT_CORE.md` | Shared operating rules for all supported agents |
| `CLAUDE.md` | Claude Code entrypoint that imports the shared core |
| `AGENTS.md` | Codex entrypoint with self-contained repo rules |
| `GEMINI.md` | Gemini CLI symlink to the shared core |
| `.claude/commands/` | Claude slash commands |
| `.claude/skills/` | Claude Code skills |
| `context/` | Shared reference material for projects that need it |

## What's Inside

### Shared Agent Core

The shared core keeps high-value behavior consistent:

- Parallel delegation for independent exploration, review, and verification
- Main-thread focus on requirements, architecture, integration, and synthesis
- Real tests over excessive mocks
- Visualization-aware validation when logs and numbers can miss rendering or geometry failures
- Repo constraints such as `fetch-mcp`, `uv` + `.venv`, and conservative cleanup behavior

### Multi-Agent Skills

Skills that teach Claude Code to orchestrate other AI tools:

| Skill | What it does |
| --- | --- |
| **gemini** | Delegate analysis, refactoring, and review tasks to Gemini CLI |
| **codex** / **codex-mify** | Delegate tasks to Codex CLI, including optional proxy routing |
| **doc-keeper** | Audit architecture docs for drift and update stale claims |

### Ralph Loop Reviews

The Ralph Loop is an iterative `review -> triage -> fix -> verify` cycle across AI agents:

| Skill | Reviews | Reviewer |
| --- | --- | --- |
| `codex-plan-ralph-refactor` | GSD phase plans | Codex |
| `codex-impl-ralph-refactor` | Implemented code | Codex |
| `agent-teams-plan-ralph-refactor` | GSD phase plans | Claude agents |
| `agent-teams-impl-ralph-refactor` | Implemented code | Claude agents |

```bash
# Review plans before executing
/codex-plan-ralph-refactor 38

# Review code after implementation
/codex-impl-ralph-refactor 42 --fix-level must
```

### Slash Commands And Scripts

| Command or script | Purpose |
| --- | --- |
| `/gsd_squash` | Squash noisy commits into clean, logical git history |
| `/gsd_status [N]` | Show status of the last N GSD phases |
| `scripts/setup.sh` | Symlink this devkit into a project |
| `scripts/update.sh` | Install or update CLIs, MCP servers, skills, local commands, and GSD |
| `scripts/convert-docs.sh` | Convert code/docs to LLM-ready markdown |

## How It Works

<p align="center">
  <img src="docs/assets/architecture.svg" alt="Architecture" width="800">
</p>

Edit `AGENT_CORE.md` for shared rules. Keep tool-specific entry files thin unless a tool needs different operational constraints.

## Supported Tools

| Tool | Integration |
| --- | --- |
| **Claude Code** | Primary runtime, skills, slash commands, and review workflows |
| **Codex CLI** | Delegation skills and Ralph Loop code review |
| **Gemini CLI** | Shared project rules via `GEMINI.md` |
| **GSD workflow** | Vendored lifecycle commands and specialist agents |
| **MCP servers** | `fetch-mcp` and related tooling installed by `update.sh` |

## Contributing

PRs are welcome from humans and AI agents.

Useful contributions include new skills, sharper shared rules, safer updater behavior, docs improvements, and fixes to workflows that became stale as the underlying CLIs changed.

## License

MIT - see [LICENSE](LICENSE).
