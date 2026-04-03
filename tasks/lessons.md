# Lessons

- 2026-03-17: When answering whether an integration is installed by repo automation, inspect the actual setup/update scripts first.
- 2026-04-02: When a user says an update script ran but the version did not change, reproduce the script and inspect subprocess exit handling before assuming they used the wrong script.
- 2026-04-02: For maintenance scripts, prefer explicit hints over automatic repair when recovery would mutate user-managed tool state.
- 2026-04-03: When the user asks to review root-level guidance files, do not expand scope into subrepos or vendored projects unless explicitly requested.
- Rule: Distinguish between installing a CLI binary and installing that tool's runtime-specific workflow/config layer.
- Rule: For agent-runtime questions in this repo, check `scripts/setup.sh` and `scripts/update.sh` before describing current behavior.
- Rule: In installer scripts, do not hide critical command failures behind `| tail`, `| grep`, or `wait ... || true` unless the failure is surfaced explicitly.
- Rule: Keep maintenance scripts small and readable; if remediation is risky, print the exact path and a manual command instead of changing the filesystem automatically.
- Rule: Confirm the repository scope from the user's wording and restrict audits to that scope; treat nested repos as out of scope by default.
