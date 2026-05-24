import { spawnSync } from "node:child_process";
import { existsSync, mkdtempSync, readFileSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, test } from "bun:test";

const repoRoot = process.cwd();
const runnerScript = join(repoRoot, "skills", "skill-runner", "scripts", "run_skill_runner.py");
const hasTmux = spawnSync("tmux", ["-V"], { encoding: "utf8" }).status === 0;

function runPython(body: string) {
  const script = `
import importlib.util
import json
import sys

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("run_skill_runner", ${JSON.stringify(runnerScript)})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)

${body}
`;

  const result = spawnSync("python3", ["-c", script], {
    cwd: repoRoot,
    encoding: "utf8",
    env: {
      ...process.env,
      PYTHONDONTWRITEBYTECODE: "1",
    },
  });

  if (result.status !== 0) {
    throw new Error(`python import failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`);
  }

  return JSON.parse(result.stdout);
}

describe("skill-runner script", () => {
  test("detects Codex bwrap sandbox failures reported in last-message", () => {
    const runDir = mkdtempSync(join(tmpdir(), "skill-runner-bwrap-"));
    try {
      writeFileSync(
        join(runDir, "last-message.md"),
        [
          "RESULT_STATUS: FAILED",
          "SUMMARY: bwrap: loopback: Failed RTM_NEWADDR: Operation not permitted",
          "",
        ].join("\n"),
      );

      const output = runPython(`
from pathlib import Path

run_dir = Path(${JSON.stringify(runDir)})
print(json.dumps({
    "detected": module.detect_sandbox_loopback_failure(run_dir),
    "classification": module.classify_worker_exit(run_dir, 0),
    "preflight": module.classify_sandbox_preflight(run_dir, exit_code=1),
}))
`);
      expect(output.detected).toBe(true);
      expect(output.classification[0]).toBe("BLOCKED");
      expect(output.classification[1]).toBe(125);
      expect(output.classification[2]).toContain("sandbox-loopback-denied");
      expect(output.preflight.status).toBe("loopback_unavailable");
    } finally {
      rmSync(runDir, { recursive: true, force: true });
    }
  });

  test("cache key changes when host capability inputs change", () => {
    const output = runPython(`
key1 = module.build_sandbox_cache_key(
    codex_path="/bin/codex",
    codex_version="codex-cli 1",
    bwrap_path="/usr/bin/bwrap",
    bwrap_version="bubblewrap 1",
    kernel="Linux test 1",
    sysctls={"kernel.unprivileged_userns_clone": "1"},
)
key2 = module.build_sandbox_cache_key(
    codex_path="/bin/codex",
    codex_version="codex-cli 1",
    bwrap_path="/usr/bin/bwrap",
    bwrap_version="bubblewrap 1",
    kernel="Linux test 1",
    sysctls={"kernel.unprivileged_userns_clone": "0"},
)
print(json.dumps({
    "changed": key1 != key2,
    "stable": key1 == module.build_sandbox_cache_key(
        codex_path="/bin/codex",
        codex_version="codex-cli 1",
        bwrap_path="/usr/bin/bwrap",
        bwrap_version="bubblewrap 1",
        kernel="Linux test 1",
        sysctls={"kernel.unprivileged_userns_clone": "1"},
    ),
}))
`);

    expect(output.changed).toBe(true);
    expect(output.stable).toBe(true);
  });

  test("cached loopback failure selects bypass unless sandbox is required", () => {
    const output = runPython(`
from pathlib import Path

key = module.build_sandbox_cache_key(
    codex_path="/bin/codex",
    codex_version="codex-cli 1",
    bwrap_path="/usr/bin/bwrap",
    bwrap_version="bubblewrap 1",
    kernel="Linux test 1",
    sysctls={"kernel.unprivileged_userns_clone": "1"},
)
cache = {
    "schema_version": module.SANDBOX_CACHE_SCHEMA_VERSION,
    "status": "loopback_unavailable",
    "reason": "bwrap loopback denied",
    "key": key,
    "updated_at": "2026-05-18T00:00:00+00:00",
}
normal = module.sandbox_decision_from_cache(
    cache,
    key,
    require_sandbox=False,
    cache_path=Path("/tmp/sandbox-capability.json"),
)
strict = module.sandbox_decision_from_cache(
    cache,
    key,
    require_sandbox=True,
    cache_path=Path("/tmp/sandbox-capability.json"),
)
print(json.dumps({
    "normal_dangerous": normal["dangerous"],
    "normal_blocked": normal["blocked"],
    "normal_mode": normal["mode"],
    "strict_dangerous": strict["dangerous"],
    "strict_blocked": strict["blocked"],
    "strict_mode": strict["mode"],
}))
`);

    expect(output.normal_dangerous).toBe(true);
    expect(output.normal_blocked).toBe(false);
    expect(output.normal_mode).toBe("bypass");
    expect(output.strict_dangerous).toBe(false);
    expect(output.strict_blocked).toBe(true);
    expect(output.strict_mode).toBe("blocked");
  });

  test("detects interactive approval prompts in terminal logs when requested", () => {
    const runDir = mkdtempSync(join(tmpdir(), "skill-runner-terminal-risk-"));
    try {
      writeFileSync(
        join(runDir, "terminal.log"),
        [
          "[ ! ] Action Required",
          "Would you like to run the following command?",
          "",
        ].join("\n"),
      );

      const output = runPython(`
from pathlib import Path

run_dir = Path(${JSON.stringify(runDir)})
print(json.dumps({
    "normal": module.detect_risk(run_dir),
    "interactive": module.detect_risk(run_dir, include_terminal=True),
}))
`);
      expect(output.normal).toBe(null);
      expect(output.interactive).toBe("interactive-approval");
    } finally {
      rmSync(runDir, { recursive: true, force: true });
    }
  });

  test("detects RESULT_STATUS rendered with terminal UI prefixes", () => {
    const runDir = mkdtempSync(join(tmpdir(), "skill-runner-terminal-result-"));
    try {
      writeFileSync(
        join(runDir, "terminal.log"),
        [
          "────────────────",
          "• RESULT_STATUS: SUCCESS",
          "  SUMMARY: done",
          "",
        ].join("\n"),
      );

      const output = runPython(`
from pathlib import Path

run_dir = Path(${JSON.stringify(runDir)})
module.materialize_interactive_last_message(run_dir)
print(json.dumps({
    "status": module.read_worker_result_status(run_dir),
    "last_message": (run_dir / "last-message.md").read_text(),
}))
`);
      expect(output.status).toBe("SUCCESS");
      expect(output.last_message).toContain("RESULT_STATUS: SUCCESS");
    } finally {
      rmSync(runDir, { recursive: true, force: true });
    }
  });

  function runFakeInteractiveRunner(extraArgs: string[] = []) {
    const tempDir = mkdtempSync(join(tmpdir(), "skill-runner-interactive-"));
    const commandLog = join(tempDir, "commands.log");
    const fakeAgent = join(tempDir, "fake-agent.sh");
    writeFileSync(
      fakeAgent,
      [
        "#!/usr/bin/env bash",
        "set -euo pipefail",
        "printf '\\n› '",
        "while IFS= read -r line; do",
        `  printf '%s\\n' "$line" >> ${JSON.stringify(commandLog)}`,
        "  case \"$line\" in",
        "    /goal\\ *) printf '\\nGoal active\\n› ' ;;",
        "    /goal\\ clear) printf '\\nGoal cleared\\n› ' ;;",
        "    /clear) printf '\\nCleared\\n› ' ;;",
        "    *) printf '\\nRESULT_STATUS: SUCCESS\\nSUMMARY: fake interactive worker complete\\nCHANGED_FILES: none\\nCOMMITS: none\\nVERIFICATION: fake agent\\nOPEN_DECISIONS: none\\nSKILL_BEHAVIOR_NOTES: none\\nRECOMMENDED_GOAL_REVISION: none\\n› ' ;;",
        "  esac",
        "done",
        "",
      ].join("\n"),
      { mode: 0o755 },
    );

    const result = spawnSync(
      "python3",
      [
        runnerScript,
        "--interactive",
        "--dangerous",
        "--no-auto-stop",
        "--agent-command",
        fakeAgent,
        "--cwd",
        repoRoot,
        "--run-root",
        tempDir,
        "--timeout-min",
        "0.05",
        "--idle-timeout-min",
        "0.05",
        "--interactive-send-settle-sec",
        "0",
        "--interactive-ready-timeout-sec",
        "2",
        "--poll-interval-sec",
        "0.1",
        "--goal",
        "stable interactive goal",
        ...extraArgs,
        "--",
        "fake interactive task",
      ],
      {
        cwd: repoRoot,
        encoding: "utf8",
        env: {
          ...process.env,
          PYTHONDONTWRITEBYTECODE: "1",
        },
      },
    );

    const runDir = result.stdout.trim().split("\n").at(-1) ?? "";
    return { commandLog, result, runDir, tempDir };
  }

  test.skipIf(!hasTmux)("interactive mode closes tmux without clearing goal by default", () => {
    const run = runFakeInteractiveRunner();
    try {
      expect(run.result.status).toBe(0);
      expect(existsSync(join(run.runDir, "result.md"))).toBe(true);
      expect(readFileSync(join(run.runDir, "result.md"), "utf8")).toContain("Status: SUCCESS");
      expect(readFileSync(join(run.runDir, "tmux-inputs.jsonl"), "utf8")).toContain('"label": "goal"');
      const commands = readFileSync(run.commandLog, "utf8").trim().split("\n");
      expect(commands[0]).toBe("/goal stable interactive goal");
      expect(commands[1]).toContain("rewritten-prompt.md");
      expect(commands[1]).toContain("RESULT_STATUS");
      expect(commands).not.toContain("/goal clear");
      expect(commands).not.toContain("/clear");
    } finally {
      rmSync(run.tempDir, { recursive: true, force: true });
    }
  });

  test.skipIf(!hasTmux)("interactive mode can opt into goal and context clearing", () => {
    const run = runFakeInteractiveRunner(["--clear-goal-on-exit", "--clear-context-on-exit"]);
    try {
      expect(run.result.status).toBe(0);
      const commands = readFileSync(run.commandLog, "utf8").trim().split("\n");
      expect(commands.slice(-2)).toEqual(["/goal clear", "/clear"]);
    } finally {
      rmSync(run.tempDir, { recursive: true, force: true });
    }
  });
});
