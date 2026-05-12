# claude-devkit

**Shared skills and commands. Project-local agent guidance.**

`claude-devkit` is a portable workflow kit for Claude Code and Codex. It keeps
skills, slash commands, update scripts, and shared references reusable across
projects while keeping each repo's `CLAUDE.md` and `AGENTS.md` local enough to
carry project-specific setup, constraints, and source-of-truth rules.

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

- **Project-local agent files** - `CLAUDE.md` and `AGENTS.md` should contain each repo's real commands, hazards, and workflow rules, not a one-size-fits-all symlink.
- **Reusable skills** - shared workflows live in skills so repos can opt into them without pasting manuals into root guidance.
- **Init-assisted refresh** - `$intuitive-setup` can use `/init` output as suggestions, merge the useful parts, and preserve project-specific constraints.
- **Multi-agent ready** - Claude Code and Codex can share vocabulary for planning, review, execution, and cleanup.
- **One updater** - CLIs, MCP servers, skills, commands, and the GSD workflow stay current with a single script.

## 30-Second Setup

```bash
# Clone the devkit once
git clone https://github.com/MiaoDX/claude-devkit.git ~/claude-devkit

# Seed a project with local agent files and shared assets
cd ~/your-project && ~/claude-devkit/scripts/setup.sh

# Install or refresh supported tooling and synced skills
~/claude-devkit/scripts/update.sh
```

`setup.sh` creates starter `CLAUDE.md` and `AGENTS.md` only when they are
missing. If an older project has those files as symlinks, setup converts them
to regular local files before continuing. Existing project-local files are left
alone.

<table><tr>
<td><img src="docs/assets/terminal-setup.svg" alt="setup.sh creating local agent files" width="400"></td>
<td><img src="docs/assets/terminal-update.svg" alt="update.sh on Ubuntu" width="400"></td>
</tr><tr>
<td align="center"><b>macOS</b> - setup.sh</td>
<td align="center"><b>Ubuntu</b> - update.sh</td>
</tr></table>

## Use It Everywhere

Run setup once from each repo that should use the shared commands, skills, and
references:

```bash
cd ~/projects/robotics-arm   && ~/claude-devkit/scripts/setup.sh
cd ~/projects/web-dashboard  && ~/claude-devkit/scripts/setup.sh
cd ~/projects/ml-pipeline    && ~/claude-devkit/scripts/setup.sh
```

Each project keeps its root agent guidance local. Rerun `$intuitive-setup`
after major workflow changes or every few weeks if the repo's commands and
planning conventions have drifted.

## What Setup Touches

| Path | Behavior |
| --- | --- |
| `CLAUDE.md` | Starter local file when missing; existing files preserved; old symlinks converted to local files |
| `AGENTS.md` | Starter local file when missing; existing files preserved; old symlinks converted to local files |
| `.claude/commands/` | Linked to shared Claude slash commands when the path is free |
| `.claude/skills/` | Linked to shared Claude skills when the path is free |
| `context/` | Linked to shared reference material when the path is free |

Run `scripts/update.sh` to install or refresh global CLI tools, MCP servers,
remote skills, local root `skills/*`, and command-to-skill adapters.

## What's Inside

### Preferred Skills

| Skill | Use it for |
| --- | --- |
| **intuitive-setup** | Merge `/init` suggestions, devkit defaults, and repo evidence into local `AGENTS.md` / `CLAUDE.md` |
| **intuitive-doc** | Keep human-facing docs small, current, and separated from agent evidence/history |
| **intuitive-layout** | Improve repo/folder organization before deeper architecture work |
| **intuitive-ut** | Organize, prune, mark, and refactor tests around behavior |
| **hybrid-phase-pipeline** | Move a fuzzy idea through plan review, GSD handoff, execution, cleanup, and verification |
| **refactor-scope-gate** | Bound broad refactors with accepted severities, evidence, and a stop condition |
| **simplify** | Review changed code for reuse, quality, and efficiency before final verification |
| **codex** | Delegate analysis, review, and refactoring to Codex CLI where available |

### Shared Operating Rules

The root `CLAUDE.md` and `AGENTS.md` in this repo are starter guidance, not files
that every project should inherit by symlink. They capture useful defaults:

- parallel delegation for independent exploration, review, and verification
- main-thread focus on requirements, architecture, integration, and synthesis
- real tests over excessive mocks
- visualization-aware validation when logs and numbers can miss rendering or geometry failures
- repo-local command, environment, and cleanup constraints

### Ralph Loop Reviews

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

### Slash Commands And Scripts

| Command or script | Purpose |
| --- | --- |
| `/gsd_squash` | Squash noisy commits into clean, logical git history |
| `/gsd_status [N]` | Show status of the last N GSD phases |
| `scripts/setup.sh` | Seed local agent files and link shared command/skill assets into a project |
| `scripts/update.sh` | Install or update CLIs, MCP servers, skills, commands, and GSD |
| `scripts/convert-docs.sh` | Convert code/docs to LLM-ready markdown |

## How It Works

<p align="center">
  <img src="docs/assets/architecture.svg" alt="Architecture" width="800">
</p>

Root agent files are copied or preserved per project. Reusable workflows live in
skills, and shared command/skill assets can still be linked or synced because
they are not expected to carry project-only rules.

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
