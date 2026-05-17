---
name: intuitive-tests
description: Use this skill whenever the user asks about unit test best practices, test organization, flat test suites, redundant tests, test refactors, pytest/JUnit/Jest/xUnit layout, test taxonomy, flaky tests, coverage quality, fixtures, mocks, parametrization, pruning existing UTs, or "which tests are worth keeping." It turns broad testing advice into a practical, behavior-first cleanup workflow. For broad suite refactors, audit first, propose a recommended path across markers, folder layout, pruning, fixtures, and parameterization, then wait for user feedback before applying disruptive changes.
---

# Intuitive Tests

Use this skill to make a test suite easier to understand, faster to run, and
less coupled to implementation details. The goal is not "more tests." The goal
is a suite where each test has an obvious reason to exist.

Existing tests are not grandfathered in. If a current unit test does not prove
project logic, caller-visible behavior, a meaningful failure mode, or a real
contract, remove it, merge it into a stronger behavior test, or reclassify it to
the correct layer. Treat structure-only, metadata-only, wiring-only, and
implementation-shape tests as deletion candidates by default.

The workflow is framework-agnostic, but the examples assume Python/pytest.

## Skill Self-Improvement Rule

This section governs maintenance of the skill itself, not ordinary execution in
the target repo.

When editing this skill, preserve a compact WHY / WHAT / HOW contract:

- WHY: the user problem, failure mode, or workflow drift the skill prevents.
- WHAT: the repo surfaces, artifacts, and decisions the skill owns, plus the
  nearby surfaces it deliberately does not own.
- HOW: the default workflow, decision gates, evidence ladder, stop condition,
  and handoff artifact that let a future agent improve the skill safely.

Before adding long instructions, route them to the right harness layer:

- shared rule across intuitive-family skills -> `skills-src/intuitive-common/`
- durable source or doctrine lesson -> `docs/human/agent-harness-references.md`
- repo-specific operational runbook -> `docs/agents/**`
- deterministic enforcement -> scripts, tests, CI, hooks, or MCP tools
- reusable task workflow -> a skill, not a root agent file

When a new official doc, field report, or model/tool change alters the guidance,
record the link and distilled lesson in `docs/human/agent-harness-references.md`,
then update this skill with only the smallest operational rule that changes how
agents should act.

For this repo, edit intuitive-family skills in `skills-src/`, run
`bun run build:skills`, and verify with `bun run verify` so generated `skills/`
output stays reproducible.

## Bounded Proposal Rule

For broad or ambiguous cleanup, audit first and stop after a decision-complete
proposal. Do not move files, delete tests, rewrite guidance, or edit production
code until the target slice, accepted checklist, evidence level, and stop
condition are explicit.

For a precise target where the user asks for implementation, apply one coherent
vertical slice. Keep newly discovered unrelated ideas parked instead of letting
the work expand by drift.

For test-suite cleanup, a good proposal lets the user choose between
conservative, layout-first, pruning-first, or fixture-extraction paths.

Verification skips are repo truth, not reusable skill truth. If some tests must
not run because of network, credentials, simulator, hardware, paid APIs, or
local services, derive the skip from the user's prompt and repo instructions,
then report those skipped checks explicitly.

## Core Principles

Prefer tests that verify observable behavior through public interfaces.

Unit tests should exercise code logic at the right confidence level: parsing,
validation, state transitions, branching, transformations, error handling,
fallbacks, and domain rules. They should not exist just to assert static shape:
repository layout, file names, file presence, import locations, decorator
presence, registration tables, config keys, copied constants, class wiring, or
implementation trivia. Those checks belong in contract tests only when
packaging, runtime discovery, CLI behavior, plugin registration, schemas, or a
documented public artifact actually depends on them.

Good unit tests are:

- **Readable**: Arrange, Act, Assert is visually obvious.
- **Behavior-focused**: the test name states the capability or failure mode.
- **Deterministic**: no real network, clock, random seed, database, or test-order dependency.
- **Small but meaningful**: narrow setup, one main action, specific assertions.
- **Refactor-tolerant**: internal renames and helper extraction should not break them.

Avoid tests that only prove:

- dataclass/record fields store values
- a private helper was called
- a constant equals a copied constant
- a file has a particular name
- a file exists, unless packaging or runtime discovery depends on it
- a directory contains a hard-coded list of files
- an import path or module location exists after all in-repo consumers have
  migrated to a new layout
- a module imports successfully without exercising behavior
- a decorator, marker, class inheritance edge, registry entry, or config key is
  present but no caller-visible behavior changes
- a CLI command, plugin, or route is listed but not invoked through its public
  interface
- a mock saw an internal call that does not affect caller-visible behavior
- coverage increased without a meaningful assertion

## Useful Community Patterns

Use these patterns deliberately:

- **AAA / Given-When-Then** for test shape.
- **Parameterized or table-driven tests** for parsers, validators, edge-case matrices, and pure logic.
- **Fixtures, factories, and builders** for reusable setup; keep them explicit and local until duplication is real.
- **Test doubles vocabulary**: dummy, stub, fake, spy, mock. Prefer fakes/stubs for state and use mocks mainly for external collaborations.
- **Coverage literacy**: coverage is a signal, not the goal. Weak assertions can produce high coverage.
- **Mutation testing** for critical pure logic when line coverage looks high but confidence is low.
- **Property-based testing** for algorithms and invariants with broad input space.
- **TDD tracer bullets**: one behavior test, one implementation step, then refactor.

## Organization Taxonomy

Classify tests by the confidence they provide and the cost to run them.

Recommended layers:

```text
unit        fast, isolated logic through public module APIs
contract    schemas, CLI output, file formats, public tools, report/replay payloads
integration process, Docker, network, external CLI, provider, or simulator boundaries
regression  reproduces a known bug or protects a high-level artifact/output shape
local       requires local GPU, paid API key, real simulator, or real gateway
slow        CI-safe but expensive enough to exclude from tight loops
```

If the suite is already large and many commands reference exact paths, add
markers first. Move files into directories only after the marker split is green
and path consumers have been updated.

Good eventual layout:

```text
tests/
  unit/
  contract/
  integration/
  regression/
  support/
    factories.py
    fixtures.py
```

## Modes

### 1. AUDIT / PROPOSE mode

Default for broad or ambiguous test-suite refactors.

**Steps:**
1. Inventory test files with `rg --files`, `find`, or the repo's test index.
2. Identify current runners and path consumers: `pyproject.toml`, `pytest.ini`,
   `tox.ini`, CI workflows, `just` recipes, scripts, docs, pre-commit hooks.
3. Classify each file as `unit`, `contract`, `integration`, `regression`,
   `local`, or `slow`.
4. Identify low-signal candidates, repeated setup, table-driven opportunities,
   implementation-coupled tests, shape/metadata/wiring-only assertions, and
   external-boundary tests.
5. Recommend one primary path and one fallback:
   - **Marker-first**: safest when path consumers are many or CI is fragile.
   - **Layout-first**: good when file names already map cleanly to layers and
     path consumers are easy to update.
   - **Pruning-first**: good when many tests duplicate stronger behavior tests.
   - **Fixture/factory-first**: good when setup noise hides test intent.
   - **Parametrization-first**: good for validators, parsers, edge matrices, and
     repeated one-case tests.
6. Stop and ask the user which path to apply unless the prompt already makes
   the choice explicit.

Use this decision prompt:

```text
Recommended next slice: <marker-first | layout-first | pruning-first | fixture/factory-first | parametrization-first>
Why: <short reason based on the inventory>
Expected changes: <files/config/tests likely touched>
Verification plan: <commands to run, plus any checks skipped because the user/repo said so>
Tradeoff: <main risk or cost>
Please confirm this slice or choose a different one.
```

### 2. MARKER mode

Use when the user approves marker-first migration or when directory movement is
risky.

**Steps:**
1. Register markers in `pyproject.toml` or `pytest.ini`; prefer
   `--strict-markers`.
2. Add explicit markers to touched tests, or add a temporary transparent
   collection hook for legacy flat files.
3. Add runner examples for useful layers such as `pytest -m unit` and
   `pytest -m "contract or regression"`.
4. Run focused collection/tests for the changed layer.

### 3. LAYOUT mode

Use when the user approves a folder layout migration or explicitly asks to move
tests into a layer-based structure.

**Steps:**
1. Confirm the target layout and preserve importability:
   ```text
   tests/
     unit/
     contract/
     integration/
     regression/
     support/
   ```
2. Move only the classified files in the approved slice.
3. Update path consumers found during AUDIT / PROPOSE mode: CI, recipes,
   scripts, docs, hooks, `pytest` config, and imports.
4. Keep `tests/support/` for shared factories and fixtures; avoid making it a
   dumping ground for one-off helpers.
5. Run collection and relevant layer tests. If a check is skipped, cite the user
   prompt or repo instruction that made it out of scope.

### 4. PRUNE / CONSOLIDATE mode

Use when the user approves pruning low-signal tests, or when the requested slice
is explicitly about unnecessary unit tests.

**Steps:**
1. For each candidate, decide whether it protects code logic, caller-visible
   behavior, a failure mode, or a real public contract.
2. If it protects a real guarantee, identify the stronger
   behavior/contract/regression test that already covers it or should absorb it.
3. Merge one-field-at-a-time tests into behavior tests when that improves
   readability.
4. Delete tests that only assert static shape: file names, file existence,
   directory shape, import smoke, registry membership, decorator presence,
   config keys, language mechanics, copied constants, private-call
   choreography, or stale implementation layout.
5. Reclassify file/artifact checks as contract tests only when they protect
   packaging, runtime discovery, CLI output, schemas, report payloads, or
   documented public artifacts.
6. Keep a short report of what was kept, merged, deleted, or reclassified.

### 5. FIXTURE / FACTORY mode

Use when repeated setup is the main problem.

**Steps:**
1. Extract a factory only after repeated dense setup appears in three or more
   tests, or when a single setup block obscures the behavior under test.
2. Prefer local fixtures near the tests until reuse is real.
3. Keep factories readable and domain-named; avoid generic "make dict" helpers.

### 6. PARAMETERIZE mode

Use when repeated tests differ only by input/expected output or edge case.

**Steps:**
1. Convert repeated cases into table-driven tests.
2. Give each case a readable id.
3. Keep separate tests when setup, behavior, or failure diagnosis meaningfully
   differs.

## Refactor Workflow

Use a small, reversible sequence:

1. **Inventory** test files with `rg`/`find` and identify current runners (`pytest`, `just`, CI).
2. **Classify** each file as unit, contract, integration, regression, local, or slow.
3. **Preserve entrypoints** before moving files: explicit CI/recipe paths, docs, hooks, and developer commands.
4. **Prompt for slice choice** when the request is broad or the best path is not obvious.
5. **Add markers** and strict marker checking before directory moves unless the
   user approved a layout-first migration.
6. **Prune low-signal tests** aggressively. Keep or replace them only when they
   prove real behavior or a real contract.
7. **Extract factories** when three or more tests build the same dense object/dict.
8. **Run focused tests** for touched modules, then the relevant layer (`-m unit`, `-m contract`, etc.).

Stop after one useful slice. Do not "clean up the entire test suite" by drift.

## Low-Signal Pruning Checklist

For each candidate test, ask:

- Would a real bug make this test fail?
- Would a harmless refactor make this test fail?
- Is this assertion already covered by a stronger behavior or contract test?
- Is this testing framework/language mechanics rather than project behavior?
- Does this protect a public API, artifact, or compatibility promise?
- Is this only checking a file name, file existence, directory listing, import
  path, or stale layout?
- Is this only checking static shape, metadata, registration, wiring, decorator
  presence, or private-call choreography?

Actions:

- **Keep** if it protects safety, parsing, fallback behavior, schema, CLI/report compatibility, or a known regression.
- **Merge** if several tests assert one behavior one field at a time.
- **Delete** if it only asserts language mechanics, duplicated implementation
  shape, static metadata/wiring, file/path/name trivia, or a stale layout/API
  that is no longer canonical.
- **Reclassify** if it is not really a unit test but is valuable as contract or
  regression coverage.
- **Replace** only when deletion would remove the last proof of meaningful
  behavior.

## Pytest Implementation Notes

Register custom markers in `pyproject.toml` or `pytest.ini` and use
`--strict-markers`.

Example:

```toml
[tool.pytest.ini_options]
addopts = "--tb=short -q --strict-markers"
markers = [
  "unit: fast isolated behavior tests",
  "contract: public schema/CLI/report/tool compatibility tests",
  "integration: process, Docker, provider, simulator, or external CLI tests",
  "regression: known-bug or artifact-regression tests",
  "local: requires local GPU, paid API key, simulator, or gateway",
  "slow: CI-safe but expensive tests",
]
```

Use `tests/conftest.py` to auto-mark legacy flat files while migrating:

```python
def pytest_collection_modifyitems(config, items):
    for item in items:
        name = item.path.name
        if "contract" in name or "mcp" in name:
            item.add_marker("contract")
        else:
            item.add_marker("unit")
```

Keep the hook boring and transparent. It is a bridge, not a permanent mystery
router.

## Report Format

When applying this skill, report:

```text
Target:
Change type:
Classification:
Recommended slice:
Low-signal tests changed:
Entry points preserved:
Commands run:
Residual risk:
Next safe slice:
```
