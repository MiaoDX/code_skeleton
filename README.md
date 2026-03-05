# 🧠 AI Agent Toolkit

> Best practices for coding with AI agents — Claude Code, Gemini CLI, Codex, and friends.

Bring consistency, speed, and real patterns to every project — without copy-pasting configs.

---

## ⚡ 30-Second Setup

```bash
# Clone once
git clone https://github.com/MiaoDX/code_skeleton.git ~/code_skeleton

# In any project
~/code_skeleton/scripts/setup.sh
```

Your project now has shared guidelines, commands, and skills — all via symlinks. No drift.

---

## 📦 What You Get

### 📋 Guidelines

Core principles baked into `CLAUDE.md` (symlinked as `AGENTS.md` and `GEMINI.md`):

| Principle | In Practice |
|-----------|-------------|
| **Simplicity First** | Minimal changes, no premature abstractions |
| **Root Cause** | Fix causes, not symptoms |
| **Challenge First** | Question assumptions before implementing |
| **Parallel Execution** | Subagents for everything — protect the main context |

---

### 🛠 Commands

Slash commands available in Claude Code:

| Command | What it does |
|---------|--------------|
| `/gsd_squash` | Squash noisy GSD commits into a clean, logical git history |
| `/gsd_status [N]` | Show status of last N GSD phases and quick tasks |

> **Tip:** For second opinions, use `/gemini` or `/codex` directly — they each spawn a full
> agent session with their respective CLIs, which is more flexible than a wrapper command.

---

### 🎯 Skills

Reusable skills that extend Claude's capabilities:

| Skill | When to use |
|-------|-------------|
| `gemini` | Delegate tasks to Gemini CLI — analysis, refactoring, editing |
| `codex` | Delegate tasks to Codex CLI — code review, automated edits |
| `codex-plan-ralph-refactor` | Review a GSD phase's **plans** with Codex + iterative fix loop |
| `codex-impl-ralph-refactor` | Review **implemented code** with Codex + triage and auto-fix loop |
| `doc-keeper` | Audit architecture docs for drift; update stale claims against code |

#### Ralph Loop Skills

The two `codex-*-ralph-refactor` skills use a review → fix → verify loop that:
- Runs **parallel Codex agents** across multiple review angles
- Auto-routes findings to the right plan/code files
- Stops early once all critical issues are resolved
- Persists state so a fresh session picks up where the last one left off

```bash
# Review plans before executing a phase
/codex-plan-ralph-refactor 38

# Review code after a phase completes
/codex-impl-ralph-refactor 42 --fix-level must
```

---

### 🔧 Scripts

| Script | Purpose |
|--------|---------|
| `scripts/setup.sh` | Symlink configs into your project |
| `scripts/update.sh` | Update all AI CLI tools (Claude, Gemini, Codex, GSD, MCPs) |
| `scripts/convert-docs.sh` | Convert code/docs → LLM-ready markdown for context |

---

## 🗂 Structure

```
.
├── CLAUDE.md              # Main guidelines (source of truth)
├── AGENTS.md → CLAUDE.md  # Shared across agents
├── GEMINI.md → CLAUDE.md
├── .claude/
│   ├── commands/          # Slash commands (/gsd_squash, /gsd_status)
│   └── skills/            # Skills (gemini, codex, doc-keeper, ralph loops)
├── context/               # Reference docs for LLM context
├── scripts/               # Setup & utility scripts
├── docs/                  # Documentation & release notes
└── vendor/                # Third-party tools (GSD, Zen MCP, etc.)
```

---

## 🚀 Full Install

```bash
scripts/update.sh
```

Installs: Claude Code, Gemini CLI, Codex, GSD workflow, MCP servers, and essential skills.

---

## 💡 Why This Exists

AI coding tools are powerful but chaotic — inconsistent configs, copy-pasted prompts, no shared patterns.

This toolkit solves it:

1. **Consistency** — Same guidelines across all your projects, always in sync
2. **Speed** — Commands and skills that encode what actually works
3. **Portability** — Symlinks, not copies — update once, propagate everywhere

Built from real usage patterns. Nothing fancy, just what works.
