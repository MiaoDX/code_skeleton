import { spawnSync } from "node:child_process";
import { mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { describe, expect, test } from "bun:test";

const repoRoot = process.cwd();

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

      const script = `
import importlib.util
import json
import sys
from pathlib import Path

sys.dont_write_bytecode = True
spec = importlib.util.spec_from_file_location("run_skill_runner", ${JSON.stringify(
        join(repoRoot, "skills", "skill-runner", "scripts", "run_skill_runner.py"),
      )})
module = importlib.util.module_from_spec(spec)
spec.loader.exec_module(module)
run_dir = Path(${JSON.stringify(runDir)})
print(json.dumps({
    "detected": module.detect_sandbox_loopback_failure(run_dir),
    "classification": module.classify_worker_exit(run_dir, 0),
}))
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

      const output = JSON.parse(result.stdout);
      expect(output.detected).toBe(true);
      expect(output.classification[0]).toBe("BLOCKED");
      expect(output.classification[1]).toBe(125);
      expect(output.classification[2]).toContain("sandbox-loopback-denied");
    } finally {
      rmSync(runDir, { recursive: true, force: true });
    }
  });
});
