# Human Docs

This directory is for current human-facing docs that are more detailed than the
root orientation files.

Start here:

- [README.md](../../README.md) for orientation and first commands
- [ARCHITECTURE.md](../../ARCHITECTURE.md) for subsystem contracts and extension
  points
- [STATUS.md](../../STATUS.md) for current state and maintenance focus
- [BELIEFS.md](../../BELIEFS.md) for the doctrine behind the workflow
- [agent-harness-references.md](agent-harness-references.md) for the external
  references and lessons that guide agent harness upgrades
- [intuitive-flow-audit-prompt.md](intuitive-flow-audit-prompt.md) for the
  periodic human-triggered review prompt for `$intuitive-flow` against current
  official and community agent-workflow practice
- [skill-self-improvement-audit.md](skill-self-improvement-audit.md) for the
  current review of repo-owned skills through the self-improvement lens
- [reduce-repo-entropy.md](reduce-repo-entropy.md) for the copy/paste
  `$intuitive-reduce-entropy` maintenance prompt

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
