---
refactor_scope: readme-doc-assets
status: DONE
accepted_severities:
  - P1
  - P2
last_verified: 2026-05-13
---

# Refactor Scope: README and Docs Assets

## Status

DONE

## Target

Update `README.md` and `docs/assets/architecture.svg` so the public docs stay
small and match the current updater implementation.

## Accepted Severities

- P1: stale public docs that misstate supported install/runtime surfaces.
- P2: visual polish for diagrams that are still accurate but less readable than
  the current docs standard.

## Accepted P0/P1 Checklist

- [x] Keep `README.md` under 150 lines.
- [x] Change the public clone command to use `--depth=1`.
- [x] Hint AI agents to download only the latest version of this repo for tool
  install/update use.
- [x] Remove the duplicated README Supported Tools section and represent those
  details in the single architecture diagram.
- [x] Align `docs/assets/architecture.svg` with the current updater phases.

## Parked P2 / Future Ideas

- [x] Remove the separate `docs/assets/supported-tools.svg` asset after merging
  its content into `docs/assets/architecture.svg`.

## Evidence Ladder

- L0 Static: inspect README line count and run `bun run verify`.

## Stop Condition

Stop when the accepted checklist is complete, README is under 150 lines, the
architecture diagram has been refreshed as the parked visual polish item, and
`bun run verify` passes.

## Execution Log

- 2026-05-13: Opened scope after user requested a smaller README, latest-only
  clone guidance, and refreshed docs assets.
- 2026-05-13: Completed README shrink, shallow clone guidance, and refreshed
  architecture diagram.
- 2026-05-13: Verified with `wc -l README.md`, `xmllint --noout
  docs/assets/architecture.svg`, headless Chrome screenshots, and
  `bun run verify`.
- 2026-05-13: Ran `$design-consultation` + `$design-review` as a focused docs
  pass. Tightened SVGs into a shorter technical-map style, reduced generic card
  feel, clarified updater phase labels, rendered before/after screenshots, and
  re-ran `bun run verify`.
- 2026-05-13: Merged supported tooling details into `architecture.svg`, removed
  `supported-tools.svg`, and collapsed the README diagram description into one
  paragraph.
- 2026-05-13: Removed standalone utility callouts from the public architecture
  map while keeping larger community workflow sources visible.
