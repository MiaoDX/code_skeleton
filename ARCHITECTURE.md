# Architecture

`intuitive-flow` is a portable operating kit for AI-agent-developed repos. It
does not own an application runtime. It owns a small set of human docs, reusable
agent skills, and install/update automation for Claude Code, Codex, GSD, gstack,
MCP fetch tooling, and related skill sources.

## System Shape

```text
human docs
  README.md, BELIEFS.md, ARCHITECTURE.md, STATUS.md, docs/human/**
        |
        v
agent guidance
  AGENTS.md, CLAUDE.md
        |
        v
reusable workflows
  skills-src/*/SKILL.md + skills-src/intuitive-common/*.md
        |
        v
  skills/*/SKILL.md
        |
        v
install and sync pipeline
  scripts/update.sh -> scripts/tasks/* + scripts/support/* -> scripts/lib/*
        |
        v
local/global agent surfaces
  ~/.claude, ~/.codex, ~/.agents, ~/.gstack, vendor/gstack
```

The root docs define what the project is. Agent guidance files define how
Claude Code and Codex should operate inside a repo. `skills-src/` is the
authoring surface for generated intuitive-family skills, `skills/` is the
flattened install surface, and scripts install and sync those workflows into
local agent tooling.

## Human Documentation Contract

The current human-facing source of truth is intentionally small:

- `README.md` gives orientation, install commands, and the public project map.
- `ARCHITECTURE.md` names subsystems, contracts, extension points, and proof
  boundaries.
- `STATUS.md` records current state, supported commands, and active maintenance
  focus.
- `docs/human/**` holds human-facing detail that should not bloat the root docs.

Everything else is lower tier by default. `docs/assets/**` supports root docs,
`docs/release-notes/**` is generated or historical analysis, `vendor/**` is
external tooling, and planning or execution artifacts are evidence unless a
human doc promotes them.

## Agent Guidance Contract

`AGENTS.md` and `CLAUDE.md` are starter guidance for this repo and examples for
target repos. They should remain self-contained enough for their host agents to
act without chasing a long manual.

Target repos should not inherit these files wholesale. `$intuitive-init`
combines local repo evidence, any available `/init` output, and Intuitive Flow
defaults into project-local `AGENTS.md` and `CLAUDE.md` files.

## Skill Contract

Each reusable workflow installs from `skills/<name>/SKILL.md`. A skill should
describe when it activates, how it should run, and what output or side effects
are expected.

The intuitive-family skills are authored under `skills-src/<name>/SKILL.md` and
may include shared fragments from `skills-src/intuitive-common/*.md` with this
source-only syntax:

```text
{{> intuitive-common/<fragment>.md}}
```

`scripts/lib/build-intuitive-skills.ts` expands those fragments and writes
flattened standalone outputs under `skills/`. Claude Code and Codex still
install from `skills/`, so runtime skill consumers do not depend on native
`@import` or cross-skill loading support.

The install surface is controlled by `scripts/local-skill-manifest.txt`:

- `root-skill` entries are repo-owned skills that should be installed or synced.
- `legacy-skill` and `legacy-command` entries identify old local artifacts that
  the updater may prune.
- The manifest check fails if a root skill exists but is not listed, or if the
  manifest lists a missing root skill.

To add a public non-generated skill, create `skills/<name>/SKILL.md`, add it to
the manifest, update `README.md` if it belongs in the preferred skill list, and
run `bun run verify`. To change an intuitive-family skill, edit
`skills-src/<name>/SKILL.md` or `skills-src/intuitive-common/*.md`, run
`bun run build:skills`, and commit both the source and flattened `skills/`
output.

## Update Pipeline Contract

`scripts/update.sh` is the orchestration entrypoint. Bash owns process control,
environment checks, task ordering, and parallel execution. Bun-run TypeScript
owns structured parsing, validation, and config rewrites where shell string
handling would be brittle.

The updater currently handles these phases:

- environment and running-Codex prechecks
- global CLI installation for Claude Code, Codex, fetch setup, and Pyright
- GSD installation for Claude and Codex
- MCP fetch setup
- Claude plugin installation
- Codex feature and status-line config
- gstack state sync and vendored gstack setup
- external skill source installation
- local command and root-skill sync

Task execution is centralized in `scripts/lib/task-runner.sh`. Individual phases
live under `scripts/tasks/`. Updater-only patch hooks live under
`scripts/support/`. TypeScript helpers and their tests live under `scripts/lib/`.
Local workstation utilities that are not part of the updater contract live under
`scripts/dev/`.

To add a new update phase, implement the phase in `scripts/tasks/`, source it
from `scripts/update.sh`, schedule it with the task runner, and document any new
external state or environment variables in the human docs.

## Codex Adapter Contract

Claude Code slash commands and Codex skills have different shapes. When this
repo has `.claude/commands/*.md`, `scripts/lib/codex-skill-adapter.sh` can render
those command files as Codex skill directories with an adapter block.

The adapter contract translates:

- Claude `AskUserQuestion` prompts into Codex `request_user_input` calls when
  available.
- Claude `Task(...)` calls into Codex `spawn_agent` calls.
- Claude command arguments into skill invocation arguments.

Root skills under `skills/` are copied directly into `~/.codex/skills/` and
installed for Claude Code through the skills CLI.

## Proof Boundary

The basic local proof command is:

```bash
bun run verify
```

That checks generated intuitive skills for drift, runs TypeScript checking, and
runs Bun tests. GitHub Actions mirrors the same proof in
`.github/workflows/verify.yml`, so direct edits to generated
`skills/intuitive-*` output fail CI unless `skills-src/` is updated and
`bun run build:skills` has refreshed the flattened output.

At the moment, the test suite covers the local skill manifest parser, root-skill
manifest checks, generated intuitive skill expansion, unsafe name/include
rejection, and pruning of manifest-owned legacy artifacts.

`scripts/update.sh` is intentionally not part of the default proof command
because it mutates global tool installations and user-level agent config.
