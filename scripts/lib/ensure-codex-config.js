#!/usr/bin/env node

const fs = require("fs");
const path = process.argv[2];

if (!path) {
  console.error("Usage: ensure-codex-config.js <config-path>");
  process.exit(1);
}

const configDir = require("path").dirname(path);
fs.mkdirSync(configDir, { recursive: true });

const oldManagedVariants = [
  [
    "model-with-reasoning",
    "current-dir",
  ],
  [
    "model-with-reasoning",
    "current-dir",
    "context-used",
    "fast-mode",
  ],
  [
    "model-with-reasoning",
    "current-dir",
    "context-used",
    "fast-mode",
    "thread-title",
    "profile",
  ],
];

const wantedItems = [
  "current-dir",
  "context-used",
  "fast-mode",
  "thread-title",
];

const defaultItems = [
  "model-with-reasoning",
  "current-dir",
  "context-used",
  "fast-mode",
  "thread-title",
];

const formatStatusLine = (items) =>
  `[${items.map((item) => JSON.stringify(item)).join(", ")}]`;

const unique = (items) => {
  const seen = new Set();
  return items.filter((item) => {
    if (seen.has(item)) {
      return false;
    }
    seen.add(item);
    return true;
  });
};

const mergeStatusItems = (existingItems) => {
  if (oldManagedVariants.some((items) => JSON.stringify(existingItems) === JSON.stringify(items))) {
    return defaultItems;
  }

  const merged = unique(existingItems);
  for (const item of wantedItems) {
    if (!merged.includes(item)) {
      merged.push(item);
    }
  }
  return merged;
};

const original = fs.existsSync(path) ? fs.readFileSync(path, "utf8") : "";
const lines = original === "" ? [] : original.split(/\r?\n/);

const findTableBounds = (tableName) => {
  const header = `[${tableName}]`;
  let start = -1;
  for (let i = 0; i < lines.length; i += 1) {
    if (lines[i].trim() === header) {
      start = i;
      break;
    }
  }

  if (start === -1) {
    return null;
  }

  let end = lines.length;
  for (let i = start + 1; i < lines.length; i += 1) {
    if (/^\[/.test(lines[i])) {
      end = i;
      break;
    }
  }

  return { start, end };
};

const ensureTableKey = (tableName, keyPattern, keyLine) => {
  const bounds = findTableBounds(tableName);
  if (!bounds) {
    const next = lines.join("\n").trimEnd();
    const prefix = next === "" ? [] : [next, ""];
    lines.length = 0;
    if (prefix.length > 0) {
      lines.push(...prefix[0].split("\n"), "");
    }
    lines.push(`[${tableName}]`, keyLine);
    return;
  }

  for (let i = bounds.start + 1; i < bounds.end; i += 1) {
    if (keyPattern.test(lines[i])) {
      lines[i] = keyLine;
      return;
    }
  }

  lines.splice(bounds.start + 1, 0, keyLine);
};

ensureTableKey("features", /^\s*codex_hooks\s*=/, "codex_hooks = true");

const tuiBounds = findTableBounds("tui");
if (!tuiBounds) {
  lines.push(lines.length === 0 ? "[tui]" : "", "[tui]", `status_line = ${formatStatusLine(defaultItems)}`);
} else {
  let statusLineIndex = -1;
  for (let i = tuiBounds.start + 1; i < tuiBounds.end; i += 1) {
    if (/^\s*status_line\s*=/.test(lines[i])) {
      statusLineIndex = i;
      break;
    }
  }

  if (statusLineIndex === -1) {
    lines.splice(tuiBounds.start + 1, 0, `status_line = ${formatStatusLine(defaultItems)}`);
  } else {
    const match = lines[statusLineIndex].match(/^\s*status_line\s*=\s*(\[[^\]]*\])/);
    if (!match) {
      lines[statusLineIndex] = `status_line = ${formatStatusLine(defaultItems)}`;
    } else {
      try {
        const parsedItems = JSON.parse(match[1]);
        lines[statusLineIndex] = `status_line = ${formatStatusLine(mergeStatusItems(parsedItems))}`;
      } catch {
        lines[statusLineIndex] = `status_line = ${formatStatusLine(defaultItems)}`;
      }
    }
  }
}

fs.writeFileSync(path, `${lines.join("\n").replace(/\n+$/, "")}\n`);
