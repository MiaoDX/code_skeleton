# AI Agent Toolkit

> Best practices for coding with AI agents — Claude Code, Gemini CLI, Codex, and friends.

## 30-Second Setup

```bash
# Clone
git clone https://github.com/MiaoDX/code_skeleton.git ~/code_skeleton

# In any project:
~/code_skeleton/scripts/setup.sh
```

That's it. Your project now shares:
- Unified guidelines (`CLAUDE.md` → linked as `AGENTS.md`, `GEMINI.md`)
- Custom commands (`/gsd_squash`, `/gsd_status`, `/zen_check`)
- Custom skills (`gemini`, `gsd-codex-ralph-review`)

## What You Get

### Guidelines

Core principles that make AI coding actually work:

| Principle | In Practice |
|-----------|-------------|
| **Simplicity First** | Minimal changes, no premature abstractions |
| **Root Cause** | Fix causes, not symptoms |
| **Challenge First** | Question assumptions before implementing |
| **Parallel Execution** | Maximize subagents for concurrent work |

### Commands

| Command | Does |
|---------|------|
| `/gsd_squash` | Clean up noisy GSD commits |
| `/gsd_status` | Show recent phase statuses |
| `/zen_check` | Double-check with Gemini + Codex |

### Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup.sh` | Link configs to your project |
| `scripts/update.sh` | Update all AI CLI tools |
| `scripts/convert-docs.sh` | Convert code/docs → LLM-ready markdown |

## Structure

```
.
├── CLAUDE.md              # Main guidelines
├── AGENTS.md → CLAUDE.md  # Shared across agents
├── GEMINI.md → CLAUDE.md
├── .claude/
│   ├── commands/          # Custom slash commands
│   └── skills/            # Custom skills
├── context/               # Reference docs (LLM context)
├── scripts/               # Setup & utility scripts
├── docs/                  # Documentation
└── vendor/                # Third-party tools
```

## Full Install

```bash
scripts/update.sh
```

Installs: Claude Code, Gemini CLI, Codex, GSD workflow, MCP servers, essential skills.

## Why This Exists

AI coding tools are powerful but chaotic. This toolkit provides:

1. **Consistency** — Same guidelines across all your projects
2. **Speed** — Pre-configured commands that actually help
3. **Portability** — Share configs via symlinks, not copy-paste

Built from real usage patterns. Nothing fancy, just what works.