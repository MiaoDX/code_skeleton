import { describe, expect, test } from "bun:test";
import { ensureAgentDeckConfigText } from "./ensure-agent-deck-config";

describe("agent-deck config helper", () => {
  test("creates the pilot config from an empty file", () => {
    expect(ensureAgentDeckConfigText("")).toBe(
      [
        'default_tool = "codex"',
        "",
        "[tmux]",
        'socket_name = "agent-deck"',
        "inject_status_line = true",
        "",
        "[updates]",
        "auto_update = false",
        "check_enabled = false",
        "",
        "[global_search]",
        "enabled = true",
        'tier = "balanced"',
        "memory_limit_mb = 100",
        "recent_days = 90",
        "index_rate_limit = 10",
        "",
        "[mcp_pool]",
        "enabled = false",
        "",
        "[docker]",
        "default_enabled = false",
        "",
        "[worktree]",
        "default_enabled = false",
        'default_location = "subdirectory"',
        "",
      ].join("\n"),
    );
  });

  test("preserves unrelated settings while replacing managed keys in existing sections", () => {
    const output = ensureAgentDeckConfigText(
      [
        "# existing agent-deck config",
        'default_tool = "claude"',
        "custom_top = true",
        "",
        "[tmux]",
        "mouse = false",
        'socket_name = "default"',
        "inject_status_line = false",
        "",
        "[global_search]",
        "enabled = false",
        "recent_days = 365",
        "",
        "[tools.multica]",
        'command = "multica"',
        "",
      ].join("\n"),
    );

    expect(output).toContain('default_tool = "codex"\ncustom_top = true');
    expect(output).toContain("[tmux]\n" + 'socket_name = "agent-deck"\n' + "inject_status_line = true\nmouse = false");
    expect(output).toContain("[global_search]\n" + "enabled = true\n" + 'tier = "balanced"\n');
    expect(output).toContain("[tools.multica]\n" + 'command = "multica"');
    expect(output).not.toContain('default_tool = "claude"');
    expect(output).not.toContain('socket_name = "default"');
    expect(output).not.toContain("recent_days = 365");
  });

  test("is idempotent", () => {
    const once = ensureAgentDeckConfigText("[tmux]\nmouse = true\n");
    expect(ensureAgentDeckConfigText(once)).toBe(once);
  });
});
