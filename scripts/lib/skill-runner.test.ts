import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, test } from "bun:test";

const repoRoot = process.cwd();
const runnerScript = join(repoRoot, "skills", "skill-runner", "scripts", "run_skill_runner.py");

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
});
