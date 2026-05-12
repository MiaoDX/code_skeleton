#!/usr/bin/env bun

import { dirname, join } from "node:path";
import { existsSync, mkdirSync, readFileSync, writeFileSync } from "node:fs";

const settingsPath = process.argv[2];
const pluginDir = process.argv[3];

if (!settingsPath || !pluginDir) {
  console.error("Usage: ensure-claude-hooks.ts <settings-path> <plugin-dir>");
  process.exit(1);
}

const hookEvents = ["UserPromptSubmit", "PreToolUse", "Stop", "Notification"];
const hookPath = join(pluginDir, "hooks", "better-hook.sh");

const readSettings = (): Record<string, unknown> => {
  if (!existsSync(settingsPath) || readFileSync(settingsPath, "utf8").trim() === "") {
    return {};
  }

  const parsed = JSON.parse(readFileSync(settingsPath, "utf8")) as unknown;
  if (!parsed || typeof parsed !== "object" || Array.isArray(parsed)) {
    throw new Error("Claude settings JSON must be an object");
  }

  return parsed as Record<string, unknown>;
};

const settings = readSettings();
const existingHooks =
  settings.hooks && typeof settings.hooks === "object" && !Array.isArray(settings.hooks)
    ? (settings.hooks as Record<string, unknown>)
    : {};

for (const event of hookEvents) {
  existingHooks[event] = [
    {
      hooks: [
        {
          type: "command",
          command: `${hookPath} ${event}`,
        },
      ],
    },
  ];
}

settings.hooks = existingHooks;
mkdirSync(dirname(settingsPath), { recursive: true });
writeFileSync(settingsPath, `${JSON.stringify(settings, null, 2)}\n`);
