#!/usr/bin/env python3
"""Run a skill-driven task in a supervised tmux agent session."""

from __future__ import annotations

import argparse
import datetime as dt
import json
import os
import re
import shlex
import subprocess
import sys
import time
from pathlib import Path


DEFAULT_SKILL_REPO = Path("/home/mi/ws/code_skeleton")
DEFAULT_RUN_ROOT = Path(os.environ.get("XDG_CACHE_HOME", Path.home() / ".cache")) / "skill-runner" / "runs"
SANDBOX_LOOPBACK_PATTERN = re.compile(
    r"bwrap:\s+loopback:\s+Failed RTM_NEWADDR:\s+Operation not permitted",
    re.I,
)
RESULT_STATUS_PATTERN = re.compile(
    r"^\s*RESULT_STATUS:\s*(SUCCESS|PARTIAL|BLOCKED_NEEDS_DECISION|FAILED)\b",
    re.I | re.M,
)


RISK_PATTERNS: tuple[tuple[str, re.Pattern[str]], ...] = (
    ("missing-agent-cli", re.compile(r"\b(codex|claude): command not found\b", re.I)),
    ("sandbox-loopback-denied", SANDBOX_LOOPBACK_PATTERN),
    (
        "auth-required",
        re.compile(
            r"(authentication required|not authenticated|login required|please run .*\blogin\b|"
            r"api key (is )?(required|missing|not set)|401 unauthorized)",
            re.I,
        ),
    ),
    ("context-exhausted", re.compile(r"(context length|maximum context|too many tokens)", re.I)),
    ("noninteractive-approval", re.compile(r"(approval required|cannot prompt|requires confirmation)", re.I)),
)


def main() -> int:
    args = parse_args()
    if args.prompt and args.prompt[0] == "--":
        args.prompt = args.prompt[1:]
    prompt = " ".join(args.prompt).strip()
    if not prompt:
        print("error: provide a task prompt after --", file=sys.stderr)
        return 2

    cwd = Path(args.cwd).expanduser().resolve()
    skill_repo = Path(args.skill_repo).expanduser().resolve()
    run_dir = make_run_dir(args.run_root, cwd, prompt)
    run_dir.mkdir(parents=True, exist_ok=False)

    skills = detect_skills(prompt)
    rewritten = rewrite_prompt(prompt=prompt, skills=skills, cwd=cwd)

    write_text(run_dir / "input.md", prompt + "\n")
    write_text(run_dir / "rewritten-prompt.md", rewritten)
    workspace_status_before = git_status(cwd)
    write_json(
        run_dir / "run.json",
        {
            "agent": args.agent,
            "cwd": str(cwd),
            "skills": skills,
            "session": args.session or default_session_name(run_dir),
            "created_at": dt.datetime.now(dt.timezone.utc).isoformat(),
            "auto_retry_sandbox_failure": args.auto_retry_sandbox_failure,
        },
    )

    session = args.session or default_session_name(run_dir)
    write_run_script(run_dir, args, cwd, dangerous=args.dangerous)

    if args.dry_run:
        write_result(run_dir, session, "DRY_RUN", "Prompt rewritten; tmux session not started.")
        write_eval(run_dir, cwd, skill_repo, "DRY_RUN", 0, "No worker run executed.")
        print(run_dir)
        return 0

    start_tmux(session=session, run_dir=run_dir, cwd=cwd)
    if args.detach:
        write_result(run_dir, session, "DETACHED", "Worker session started and left running.")
        print(f"session: {session}")
        print(f"run_dir: {run_dir}")
        print(f"attach: tmux attach -t {shlex.quote(session)}")
        return 0

    status, exit_code, reason = wait_for_worker(session=session, run_dir=run_dir, args=args)
    if should_retry_sandbox_failure(args, run_dir, cwd, workspace_status_before):
        retry_session = retry_session_name(session)
        archive_attempt_logs(run_dir, "attempt-1")
        write_text(
            run_dir / "auto-retry.md",
            "Initial Codex run hit the known bwrap loopback sandbox failure. "
            "The workspace git status was unchanged, so skill-runner retried "
            "once with --dangerously-bypass-approvals-and-sandbox.\n",
        )
        write_run_script(run_dir, args, cwd, dangerous=True)
        start_tmux(session=retry_session, run_dir=run_dir, cwd=cwd)
        status, exit_code, retry_reason = wait_for_worker(
            session=retry_session,
            run_dir=run_dir,
            args=args,
        )
        session = retry_session
        reason = f"auto-retried sandbox-loopback-denied; retry result: {retry_reason}"

    if args.sync_on_skill_change:
        maybe_sync_skill_changes(skill_repo)
    if args.commit_skill_changes:
        maybe_commit_skill_changes(skill_repo)

    write_result(run_dir, session, status, reason)
    write_eval(run_dir, cwd, skill_repo, status, exit_code, reason)
    print(run_dir)
    return exit_code


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(description=__doc__)
    parser.add_argument("--agent", choices=("codex", "claude"), default="codex")
    parser.add_argument("--cwd", default=os.getcwd())
    parser.add_argument("--session")
    parser.add_argument("--run-root", default=str(DEFAULT_RUN_ROOT))
    parser.add_argument("--skill-repo", default=str(DEFAULT_SKILL_REPO))
    parser.add_argument("--timeout-min", type=float, default=120.0)
    parser.add_argument("--idle-timeout-min", type=float, default=20.0)
    parser.add_argument("--detach", action="store_true")
    parser.add_argument("--dry-run", action="store_true")
    parser.add_argument("--dangerous", action="store_true")
    parser.add_argument(
        "--auto-retry-sandbox-failure",
        dest="auto_retry_sandbox_failure",
        action="store_true",
        default=True,
        help="Retry known Codex bwrap loopback sandbox failures once without sandboxing.",
    )
    parser.add_argument(
        "--no-auto-retry-sandbox-failure",
        dest="auto_retry_sandbox_failure",
        action="store_false",
        help="Do not retry known Codex bwrap loopback sandbox failures automatically.",
    )
    parser.add_argument("--no-auto-stop", action="store_true")
    parser.add_argument("--sync-on-skill-change", action="store_true")
    parser.add_argument("--commit-skill-changes", action="store_true")
    parser.add_argument("prompt", nargs=argparse.REMAINDER)
    return parser.parse_args()


def make_run_dir(run_root: str, cwd: Path, prompt: str) -> Path:
    stamp = dt.datetime.now().strftime("%Y%m%d-%H%M%S")
    repo_slug = slug(cwd.name)
    prompt_slug = slug(prompt)[:48] or "task"
    return Path(run_root).expanduser().resolve() / f"{stamp}-{repo_slug}-{prompt_slug}"


def default_session_name(run_dir: Path) -> str:
    return "skill-runner-" + run_dir.name[:80]


def retry_session_name(session: str) -> str:
    return (session + "-retry")[:200]


def slug(value: str) -> str:
    value = re.sub(r"[^A-Za-z0-9]+", "-", value).strip("-").lower()
    return value or "run"


def detect_skills(prompt: str) -> list[str]:
    found: list[str] = []
    for match in re.findall(r"\$([A-Za-z][A-Za-z0-9_-]*)", prompt):
        if match not in found:
            found.append(match)
    for match in re.findall(r"\b(gsd-[A-Za-z0-9_-]+)\b", prompt):
        if match not in found:
            found.append(match)
    return found


def rewrite_prompt(*, prompt: str, skills: list[str], cwd: Path) -> str:
    selected = ", ".join(f"${s}" for s in skills) if skills else "none explicitly named"
    return f"""Objective:
{prompt}

Selected skills:
{selected}

Workspace:
{cwd}

Operating contract:
- Treat the workspace above as the task/product repo and apply the selected
  skill workflows there.
- Do not substitute the custom skill source repo for the task workspace merely
  because the prompt mentions a skill file or installed skill copy.
- If the workspace appears wrong for the user objective, stop and report
  BLOCKED_NEEDS_DECISION instead of doing a plausible task in the wrong repo.
- Use the selected skill workflows honestly. If a named skill is unavailable, say so and stop.
- Keep the work KISS: smallest useful change, fewest artifacts, clear stop condition.
- Preserve unrelated user changes. Do not revert work you did not make.
- Do not edit custom skills unless the objective explicitly asks for skill work.
- Do not edit third-party/system skills directly.
- Commit only when the user's prompt or repo workflow asks for a commit.
- If blocked by credentials, paid APIs, local hardware, Docker, GPU, or a human decision, stop and report BLOCKED_NEEDS_DECISION.

Skill-specific guardrails:
- For $hybrid-phase-pipeline: one phase is one coherent delivery unit. Do not create more than three phases from this prompt without stopping for grouping approval. Use tasks/checklists for blockers, proof retries, diagnostics, and small report/checker changes.
- For $simplify: review the actual changed scope only. Do not expand into broad architecture discovery.
- For GSD work: do not hand-write .planning artifacts and claim a downstream GSD skill produced them.

Verification:
- Run the most relevant fast checks available for the changed scope.
- If a required check is skipped, explain exactly why.
- Do not claim completion from intent, effort, or proxy signals alone.

Final response format:
RESULT_STATUS: SUCCESS | PARTIAL | BLOCKED_NEEDS_DECISION | FAILED
SUMMARY: <short description>
CHANGED_FILES: <files or "none">
COMMITS: <hashes or "none">
VERIFICATION: <commands and results>
OPEN_DECISIONS: <remaining decisions or "none">
SKILL_BEHAVIOR_NOTES: <reusable skill issue candidates or "none">
"""


def write_run_script(
    run_dir: Path,
    args: argparse.Namespace,
    cwd: Path,
    *,
    dangerous: bool,
) -> None:
    prompt_path = run_dir / "rewritten-prompt.md"
    exit_path = run_dir / "exit_code"
    if args.agent == "codex":
        command = [
            "codex",
            "exec",
            "--cd",
            str(cwd),
            "--json",
            "--output-last-message",
            str(run_dir / "last-message.md"),
        ]
        if dangerous:
            command.append("--dangerously-bypass-approvals-and-sandbox")
        else:
            command.extend(["--sandbox", "workspace-write"])
        command.append("-")
    else:
        command = [
            "claude",
            "-p",
            "--output-format",
            "stream-json",
            "--permission-mode",
            "auto",
        ]
        if dangerous:
            command.append("--dangerously-skip-permissions")

    quoted = " ".join(shlex.quote(part) for part in command)
    script = f"""#!/usr/bin/env bash
set -u
cd {shlex.quote(str(cwd))}
echo $$ > {shlex.quote(str(run_dir / "worker.pid"))}
echo running > {shlex.quote(str(run_dir / "status"))}
set +e
{quoted} < {shlex.quote(str(prompt_path))} 2> >(tee {shlex.quote(str(run_dir / "stderr.log"))} >&2) | tee {shlex.quote(str(run_dir / "events.jsonl"))}
code=${{PIPESTATUS[0]}}
echo "$code" > {shlex.quote(str(exit_path))}
if [ "$code" -eq 0 ]; then
  echo complete > {shlex.quote(str(run_dir / "status"))}
else
  echo failed > {shlex.quote(str(run_dir / "status"))}
fi
exit "$code"
"""
    run_script = run_dir / "run.sh"
    write_text(run_script, script)
    run_script.chmod(0o755)


def start_tmux(*, session: str, run_dir: Path, cwd: Path) -> None:
    run_script = run_dir / "run.sh"
    subprocess.run(
        ["tmux", "new-session", "-d", "-s", session, "-c", str(cwd), "bash", str(run_script)],
        check=True,
    )
    subprocess.run(
        ["tmux", "pipe-pane", "-o", "-t", session, f"cat >> {shlex.quote(str(run_dir / 'terminal.log'))}"],
        check=False,
    )


def wait_for_worker(*, session: str, run_dir: Path, args: argparse.Namespace) -> tuple[str, int, str]:
    started = time.monotonic()
    last_activity = time.monotonic()
    last_size = -1
    exit_path = run_dir / "exit_code"
    timeout = args.timeout_min * 60
    idle_timeout = args.idle_timeout_min * 60

    while True:
        if exit_path.exists():
            code = read_exit_code(exit_path)
            return classify_worker_exit(run_dir, code)

        if not tmux_has_session(session):
            return "FAILED", 1, "tmux session ended without exit_code"

        current_size = log_size(run_dir)
        if current_size != last_size:
            last_activity = time.monotonic()
            last_size = current_size

        if time.monotonic() - started > timeout:
            stop_session(session, run_dir, "timeout")
            return "FAILED", 124, f"timeout after {args.timeout_min:g} minutes"

        if time.monotonic() - last_activity > idle_timeout:
            stop_session(session, run_dir, "idle-timeout")
            return "FAILED", 124, f"idle timeout after {args.idle_timeout_min:g} minutes"

        if not args.no_auto_stop:
            risk = detect_risk(run_dir)
            if risk:
                stop_session(session, run_dir, risk)
                return "BLOCKED", 125, f"auto-stopped: {risk}"

        time.sleep(5)


def tmux_has_session(session: str) -> bool:
    return subprocess.run(["tmux", "has-session", "-t", session], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL).returncode == 0


def stop_session(session: str, run_dir: Path, reason: str) -> None:
    capture_path = run_dir / "pane-before-stop.log"
    with capture_path.open("w", encoding="utf-8") as fh:
        subprocess.run(["tmux", "capture-pane", "-p", "-S", "-2000", "-t", session], stdout=fh, stderr=subprocess.DEVNULL)
    write_text(run_dir / "stopped_reason", reason + "\n")
    subprocess.run(["tmux", "kill-session", "-t", session], stdout=subprocess.DEVNULL, stderr=subprocess.DEVNULL)
    write_text(run_dir / "exit_code", "125\n")
    write_text(run_dir / "status", "stopped\n")


def classify_worker_exit(run_dir: Path, code: int) -> tuple[str, int, str]:
    worker_status = read_worker_result_status(run_dir)
    if worker_status == "SUCCESS":
        return "SUCCESS", 0, f"worker reported RESULT_STATUS: SUCCESS; cli exit code {code}"
    if worker_status == "PARTIAL":
        return "PARTIAL", 0, f"worker reported RESULT_STATUS: PARTIAL; cli exit code {code}"
    if worker_status == "BLOCKED_NEEDS_DECISION":
        return "BLOCKED", 125, (
            f"worker reported RESULT_STATUS: BLOCKED_NEEDS_DECISION; cli exit code {code}"
        )
    if worker_status == "FAILED":
        return "FAILED", 1, f"worker reported RESULT_STATUS: FAILED; cli exit code {code}"
    if detect_sandbox_loopback_failure(run_dir):
        return "BLOCKED", 125, f"sandbox-loopback-denied; cli exit code {code}"
    status = "SUCCESS" if code == 0 else "FAILED"
    return status, code, f"worker exited with code {code}"


def read_worker_result_status(run_dir: Path) -> str | None:
    path = run_dir / "last-message.md"
    if not path.exists():
        return None
    match = RESULT_STATUS_PATTERN.search(path.read_text(encoding="utf-8", errors="replace"))
    if not match:
        return None
    return match.group(1).upper()


def detect_sandbox_loopback_failure(run_dir: Path) -> bool:
    return SANDBOX_LOOPBACK_PATTERN.search(read_log_tail(run_dir / "stderr.log")) is not None


def should_retry_sandbox_failure(
    args: argparse.Namespace,
    run_dir: Path,
    cwd: Path,
    workspace_status_before: str,
) -> bool:
    if args.agent != "codex" or args.dangerous or not args.auto_retry_sandbox_failure:
        return False
    if not detect_sandbox_loopback_failure(run_dir):
        return False
    return git_status(cwd) == workspace_status_before


def archive_attempt_logs(run_dir: Path, prefix: str) -> None:
    for name in (
        "events.jsonl",
        "stderr.log",
        "terminal.log",
        "last-message.md",
        "exit_code",
        "status",
        "worker.pid",
        "stopped_reason",
        "pane-before-stop.log",
    ):
        path = run_dir / name
        if path.exists():
            path.rename(run_dir / f"{prefix}.{name}")


def log_size(run_dir: Path) -> int:
    total = 0
    for name in ("events.jsonl", "stderr.log", "terminal.log"):
        path = run_dir / name
        if path.exists():
            total += path.stat().st_size
    return total


def detect_risk(run_dir: Path) -> str | None:
    text = read_log_tail(run_dir / "stderr.log")
    for label, pattern in RISK_PATTERNS:
        if pattern.search(text):
            return label
    return None


def read_log_tail(path: Path, limit: int = 8000) -> str:
    if not path.exists():
        return ""
    return path.read_text(encoding="utf-8", errors="replace")[-limit:]


def read_exit_code(path: Path) -> int:
    try:
        return int(path.read_text(encoding="utf-8").strip())
    except Exception:
        return 1


def write_result(run_dir: Path, session: str, status: str, reason: str) -> None:
    write_text(
        run_dir / "result.md",
        f"""# Skill Runner Result

- Status: {status}
- Reason: {reason}
- Tmux session: `{session}`
- Attach command: `tmux attach -t {session}`

Review `last-message.md`, `eval.md`, and targeted log excerpts before relying
on this run.
""",
    )


def write_eval(run_dir: Path, cwd: Path, skill_repo: Path, status: str, exit_code: int, reason: str) -> None:
    workspace_status = git_status(cwd)
    skill_status = git_status(skill_repo, ["--", "skills"])
    verdict = "NO_SKILL_CHANGE" if not skill_status.strip() else "REVIEW_REQUIRED"
    write_text(
        run_dir / "eval.md",
        f"""# Skill Runner Evaluation

## Run

- Status: {status}
- Exit code: {exit_code}
- Reason: {reason}

## Workspace Diff

```text
{workspace_status or "clean"}
```

## Custom Skill Diff

```text
{skill_status or "clean"}
```

## Skill Patch Verdict

{verdict}

Patch a skill only for reusable workflow defects. Prefer deleting, simplifying,
or moving detail to a script/reference before adding new rules.
""",
    )


def git_status(cwd: Path, extra: list[str] | None = None) -> str:
    is_worktree = subprocess.run(
        ["git", "-C", str(cwd), "rev-parse", "--is-inside-work-tree"],
        text=True,
        stdout=subprocess.PIPE,
        stderr=subprocess.DEVNULL,
    )
    if is_worktree.returncode != 0:
        return "not a git worktree"
    cmd = ["git", "-C", str(cwd), "status", "--short"]
    if extra:
        cmd.extend(extra)
    result = subprocess.run(cmd, text=True, stdout=subprocess.PIPE, stderr=subprocess.STDOUT)
    return result.stdout.strip()


def maybe_sync_skill_changes(skill_repo: Path) -> None:
    if not git_status(skill_repo, ["--", "skills"]).strip():
        return
    script = skill_repo / "scripts" / "tasks" / "sync-local-commands-skills.sh"
    if script.exists():
        subprocess.run([str(script)], cwd=str(skill_repo), check=False)


def maybe_commit_skill_changes(skill_repo: Path) -> None:
    if not git_status(skill_repo, ["--", "skills"]).strip():
        return
    subprocess.run(["git", "-C", str(skill_repo), "add", "skills"], check=False)
    subprocess.run(
        ["git", "-C", str(skill_repo), "commit", "-m", "docs: refine custom skills"],
        check=False,
    )


def write_text(path: Path, text: str) -> None:
    path.parent.mkdir(parents=True, exist_ok=True)
    path.write_text(text, encoding="utf-8")


def write_json(path: Path, data: object) -> None:
    write_text(path, json.dumps(data, indent=2, sort_keys=True) + "\n")


if __name__ == "__main__":
    raise SystemExit(main())
