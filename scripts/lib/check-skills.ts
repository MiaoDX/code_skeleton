#!/usr/bin/env bun

import { existsSync, readdirSync, readFileSync, statSync } from "node:fs";
import { join } from "node:path";
import { checkExternalSkillSourcesText } from "./external-skill-sources";
import { checkRootSkills, parseManifestText } from "./local-skill-manifest";

export type SkillCheckOptions = {
  skillsRoot: string;
  manifestPath: string;
  deprecatedSourceRoot: string;
  externalSkillSourcesPath?: string;
};

const defaultOptions = (): SkillCheckOptions => ({
  skillsRoot: join(process.cwd(), "skills"),
  manifestPath: join(process.cwd(), "scripts", "local-skill-manifest.txt"),
  deprecatedSourceRoot: join(process.cwd(), "skills-src"),
  externalSkillSourcesPath: join(process.cwd(), "scripts", "external-skill-sources.txt"),
});

const sortedDirEntries = (dir: string) => readdirSync(dir).sort((a, b) => a.localeCompare(b));

const listFiles = (dir: string, prefix = ""): string[] => {
  if (!existsSync(dir)) {
    return [];
  }

  const files: string[] = [];
  for (const entry of sortedDirEntries(dir)) {
    const fullPath = join(dir, entry);
    const relativePath = prefix === "" ? entry : `${prefix}/${entry}`;
    if (statSync(fullPath).isDirectory()) {
      files.push(...listFiles(fullPath, relativePath));
    } else {
      files.push(relativePath);
    }
  }
  return files;
};

const skillNames = (skillsRoot: string): string[] => {
  if (!existsSync(skillsRoot)) {
    return [];
  }

  return sortedDirEntries(skillsRoot).filter((entry) => {
    const skillDir = join(skillsRoot, entry);
    return statSync(skillDir).isDirectory() && existsSync(join(skillDir, "SKILL.md"));
  });
};

const frontmatter = (text: string): string | undefined => {
  const match = /^---\n([\s\S]*?)\n---\n/.exec(text);
  return match?.[1];
};

const frontmatterValue = (frontmatterText: string, key: string): string | undefined => {
  const match = new RegExp(`^${key}:\\s*(.*)$`, "m").exec(frontmatterText);
  return match?.[1]?.trim().replace(/^["']|["']$/g, "");
};

const blockValue = (frontmatterText: string, key: string): string => {
  const lines = frontmatterText.split("\n");
  const start = lines.findIndex((line) => line.startsWith(`${key}:`));
  if (start === -1) {
    return "";
  }

  const first = lines[start].slice(`${key}:`.length).trim();
  if (first !== "|" && first !== ">") {
    return first;
  }

  const body: string[] = [];
  for (const line of lines.slice(start + 1)) {
    if (/^[A-Za-z0-9_-]+:\s*/.test(line)) {
      break;
    }
    body.push(line.replace(/^ {2}/, ""));
  }
  return body.join("\n").trim();
};

const normalizeMention = (mention: string): string =>
  mention.replace(/[),.;:]+$/g, "").replace(/^["'`]+|["'`]+$/g, "");

const localResourceMentions = (text: string): string[] => {
  const mentions = new Set<string>();
  const resourcePattern = /\b(?:references|templates)\/[A-Za-z0-9._/-]+/g;
  for (const match of text.matchAll(resourcePattern)) {
    mentions.add(normalizeMention(match[0]));
  }
  const markdownLinkPattern = /\[[^\]]*]\(([^)]+)\)/g;
  for (const match of text.matchAll(markdownLinkPattern)) {
    const target = match[1]?.trim();
    if (
      target &&
      !target.startsWith("#") &&
      !target.startsWith("http://") &&
      !target.startsWith("https://") &&
      !target.startsWith("/")
    ) {
      mentions.add(normalizeMention(target));
    }
  }
  return [...mentions].sort((a, b) => a.localeCompare(b));
};

const checkSkill = (skillsRoot: string, skillName: string): string[] => {
  const errors: string[] = [];
  const skillDir = join(skillsRoot, skillName);
  const skillPath = join(skillDir, "SKILL.md");
  const text = readFileSync(skillPath, "utf8");
  const header = frontmatter(text);

  if (!header) {
    errors.push(`missing frontmatter: skills/${skillName}/SKILL.md`);
  } else {
    const name = frontmatterValue(header, "name");
    if (name !== skillName) {
      errors.push(`frontmatter name mismatch in skills/${skillName}/SKILL.md: expected ${skillName}, got ${name ?? "<missing>"}`);
    }

    const description = blockValue(header, "description");
    if (description.length === 0) {
      errors.push(`missing description in skills/${skillName}/SKILL.md`);
    } else if (description.length > 1024) {
      errors.push(`description too long in skills/${skillName}/SKILL.md: ${description.length} chars`);
    }
  }

  for (const file of listFiles(skillDir)) {
    const filePath = join(skillDir, file);
    const fileText = readFileSync(filePath, "utf8");
    if (fileText.includes("{{>")) {
      errors.push(`template include left in canonical skill file: skills/${skillName}/${file}`);
    }
  }

  for (const mention of localResourceMentions(text)) {
    if (!existsSync(join(skillDir, mention))) {
      errors.push(`missing referenced skill resource in skills/${skillName}/SKILL.md: ${mention}`);
    }
  }

  return errors;
};

export const checkSkills = (options = defaultOptions()): string[] => {
  const errors: string[] = [];

  if (existsSync(options.deprecatedSourceRoot) && listFiles(options.deprecatedSourceRoot).length > 0) {
    errors.push("deprecated generated skill source remains: skills-src/");
  }

  if (!existsSync(options.skillsRoot)) {
    errors.push("missing skills directory: skills/");
    return errors;
  }

  if (!existsSync(options.manifestPath)) {
    errors.push("missing local skill manifest: scripts/local-skill-manifest.txt");
    return errors;
  }

  const manifest = parseManifestText(readFileSync(options.manifestPath, "utf8"));
  errors.push(...checkRootSkills(manifest, options.skillsRoot));

  if (options.externalSkillSourcesPath) {
    if (!existsSync(options.externalSkillSourcesPath)) {
      errors.push("missing external skill source manifest: scripts/external-skill-sources.txt");
    } else {
      errors.push(...checkExternalSkillSourcesText(readFileSync(options.externalSkillSourcesPath, "utf8")));
    }
  }

  for (const skillName of skillNames(options.skillsRoot)) {
    errors.push(...checkSkill(options.skillsRoot, skillName));
  }

  return errors;
};

const main = () => {
  const errors = checkSkills();
  for (const error of errors) {
    console.error(`  ! ${error}`);
  }
  if (errors.length > 0) {
    process.exit(1);
  }
  console.log("  ✓ skills are structurally valid");
};

if (import.meta.main) {
  main();
}
