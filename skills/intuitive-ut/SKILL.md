---
name: intuitive-ut
description: Use this skill whenever the user asks about unit test best practices, UT organization, flat test suites, redundant tests, test refactors, pytest/JUnit/Jest/xUnit layout, test taxonomy, flaky tests, coverage quality, fixtures, mocks, parametrization, or "which tests are worth keeping." It turns broad testing advice into a practical, behavior-first cleanup workflow that preserves useful contracts while pruning low-signal unit tests.
---

# Intuitive Unit Tests

Use this skill to make a test suite easier to understand, faster to run, and
less coupled to implementation details. The goal is not "more tests." The goal
is a suite where each test has an obvious reason to exist.

The workflow is framework-agnostic, but the examples assume Python/pytest.

## Core Principles

Prefer tests that verify observable behavior through public interfaces.

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
- a file exists, unless packaging or runtime discovery depends on it
- a mock saw an internal call that does not affect caller-visible behavior

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

## Refactor Workflow

Use a small, reversible sequence:

1. **Inventory** test files with `rg`/`find` and identify current runners (`pytest`, `just`, CI).
2. **Classify** each file as unit, contract, integration, regression, local, or slow.
3. **Preserve entrypoints** before moving files: explicit CI/recipe paths, docs, hooks, and developer commands.
4. **Add markers** and strict marker checking before directory moves.
5. **Prune low-signal tests** only when the replacement behavior test still proves the same caller-facing contract.
6. **Extract factories** when three or more tests build the same dense object/dict.
7. **Run focused tests** for touched modules, then the relevant layer (`-m unit`, `-m contract`, etc.).

Stop after one useful slice. Do not "clean up the entire test suite" by drift.

## Low-Signal Pruning Checklist

For each candidate test, ask:

- Would a real bug make this test fail?
- Would a harmless refactor make this test fail?
- Is this assertion already covered by a stronger behavior or contract test?
- Is this testing framework/language mechanics rather than project behavior?
- Does this protect a public API, artifact, or compatibility promise?

Actions:

- **Keep** if it protects safety, parsing, fallback behavior, schema, CLI/report compatibility, or a known regression.
- **Merge** if several tests assert one behavior one field at a time.
- **Delete** if it only asserts language mechanics or duplicated implementation shape.
- **Reclassify** if it is not really a unit test but is valuable as contract or regression coverage.

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
Low-signal tests changed:
Entry points preserved:
Commands run:
Residual risk:
Next safe slice:
```
