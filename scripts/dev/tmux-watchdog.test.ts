import { spawnSync } from "node:child_process";
import { describe, expect, test } from "bun:test";

const repoRoot = process.cwd();

function runWatchdogScript(script: string, args: string[] = [], env: NodeJS.ProcessEnv = {}) {
  return spawnSync("bash", ["-c", script, "bash", ...args], {
    cwd: repoRoot,
    encoding: "utf8",
    env: {
      ...process.env,
      WATCHDOG_TMUX_TARGETS: "",
      WATCHDOG_TMUX_SOCKET_NAME: "",
      WATCHDOG_TMUX_SOCKET_PATH: "",
      ...env,
    },
  });
}

function runWatchdogCheck(functionName: string, output: string) {
  const script = `
source scripts/dev/tmux-watchdog.sh
if ${functionName} "$1"; then
  printf 'yes'
else
  printf 'no'
fi
`;

  const result = runWatchdogScript(script, [output], {
    WATCHDOG_STUCK_WINDOW_LINES: "12",
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

describe("tmux watchdog tmux target selection", () => {
  test("uses the default and Agent Deck tmux servers without arguments", () => {
    const result = runWatchdogScript(`
source scripts/dev/tmux-watchdog.sh
parse_args
tmux_targets_display
`);

    expect(result.status).toBe(0);
    expect(result.stdout).toBe("tmux, tmux -L agent-deck");
  });

  test("supports the agent-deck monitor shorthand", () => {
    const result = runWatchdogScript(`
source scripts/dev/tmux-watchdog.sh
parse_args monitor agent-deck
tmux_targets_display
`);

    expect(result.status).toBe(0);
    expect(result.stdout).toBe("tmux -L agent-deck");
  });

  test("supports tmux socket name from the environment", () => {
    const result = runWatchdogScript(
      `
source scripts/dev/tmux-watchdog.sh
parse_args
tmux_targets_display
`,
      [],
      { WATCHDOG_TMUX_SOCKET_NAME: "agent-deck" },
    );

    expect(result.status).toBe(0);
    expect(result.stdout).toBe("tmux -L agent-deck");
  });

  test("lets the default target override a socket environment variable", () => {
    const result = runWatchdogScript(
      `
source scripts/dev/tmux-watchdog.sh
parse_args default
tmux_targets_display
`,
      [],
      { WATCHDOG_TMUX_SOCKET_NAME: "agent-deck" },
    );

    expect(result.status).toBe(0);
    expect(result.stdout).toBe("tmux");
  });

  test("rejects conflicting socket name and path settings", () => {
    const result = runWatchdogScript(
      `
source scripts/dev/tmux-watchdog.sh
parse_args
`,
      [],
      {
        WATCHDOG_TMUX_SOCKET_NAME: "agent-deck",
        WATCHDOG_TMUX_SOCKET_PATH: "/tmp/tmux-agent-deck.sock",
      },
    );

    expect(result.status).not.toBe(0);
    expect(result.stderr).toContain("set only one of WATCHDOG_TMUX_SOCKET_NAME or WATCHDOG_TMUX_SOCKET_PATH");
  });
});
