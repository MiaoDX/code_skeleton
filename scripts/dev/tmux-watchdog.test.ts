import { spawnSync } from "node:child_process";
import { describe, expect, test } from "bun:test";

const repoRoot = process.cwd();

function runWatchdogCheck(functionName: string, output: string) {
  const script = `
source scripts/dev/tmux-watchdog.sh
if ${functionName} "$1"; then
  printf 'yes'
else
  printf 'no'
fi
`;

  const result = spawnSync("bash", ["-c", script, "bash", output], {
    cwd: repoRoot,
    encoding: "utf8",
    env: {
      ...process.env,
      WATCHDOG_STUCK_WINDOW_LINES: "12",
    },
  });

  if (result.status !== 0) {
    throw new Error(`watchdog check failed\nstdout:\n${result.stdout}\nstderr:\n${result.stderr}`);
  }

  return result.stdout;
}

describe("tmux watchdog stuck detection", () => {
  test("ignores completed-agent prose that mentions provider API errors", () => {
    const output = [
      "• Review complete",
      "  - Kimi RAW_FPV was retried twice. Both runs reached MCP tools, then failed from the provider with API Error: The server had an error while processing your request.",
      "",
      "›",
    ].join("\n");

    expect(runWatchdogCheck("has_stuck_pattern", output)).toBe("no");
  });

  test("ignores stale rate-limit text outside the actionable prompt window", () => {
    const filler = Array.from({ length: 16 }, (_, index) => `completed step ${index + 1}`);
    const output = ["rate limit reached; resets at 18:00", ...filler, "", "›"].join("\n");

    expect(runWatchdogCheck("has_stuck_pattern", output)).toBe("no");
  });

  test("detects recent rate-limit text near the ready prompt", () => {
    const output = ["working", "rate limit reached; resets at 18:00", "", "›"].join("\n");

    expect(runWatchdogCheck("has_stuck_pattern", output)).toBe("yes");
  });
});
