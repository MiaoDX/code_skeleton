# Human Docs

This directory is for current human-facing docs that are more detailed than the
root orientation files.

Start here:

- [README.md](../../README.md) for orientation and first commands
- [ARCHITECTURE.md](../../ARCHITECTURE.md) for subsystem contracts and extension
  points
- [STATUS.md](../../STATUS.md) for current state and maintenance focus
- [BELIEFS.md](../../BELIEFS.md) for the doctrine behind the workflow
- [legacy-repo-migration.md](legacy-repo-migration.md) for the copy/paste
  `$intuitive-migrate` prompt

## Doc Tiers

Human-authoritative:

- root `README.md`, `ARCHITECTURE.md`, and `STATUS.md`
- files under `docs/human/**`

Evidence or history:

- `docs/release-notes/**`
- generated reports, planning logs, retrospectives, and proof bundles

Implementation detail:

- source code
- scripts and tests
- vendored tooling
- dependency directories

When a generated or implementation-detail artifact becomes something humans
need at `HEAD`, promote its durable claims into the root docs or this directory
instead of making humans read the raw artifact.
