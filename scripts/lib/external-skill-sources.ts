#!/usr/bin/env bun

import { existsSync, readFileSync } from "node:fs";

export type ExternalSkillSourceMode = "all" | "allowlist";

export type ExternalSkillSource = {
  label: string;
  repo: string;
  mode: ExternalSkillSourceMode;
  skills: string[];
};

export type ExternalSkillSourceManifest = {
  sources: ExternalSkillSource[];
};

const labelPattern = /^[a-z][a-z0-9-]*$/;
const repoSlugPattern = /^[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+$/;
const githubUrlPattern = /^https:\/\/github\.com\/[A-Za-z0-9_.-]+\/[A-Za-z0-9_.-]+(?:\.git)?$/;
const skillNamePattern = /^[A-Za-z0-9][A-Za-z0-9._-]*$/;

const parseLines = (text: string): { manifest: ExternalSkillSourceManifest; errors: string[] } => {
  const sources: ExternalSkillSource[] = [];
  const errors: string[] = [];
  const seenLabels = new Set<string>();

  text.split(/\r?\n/).forEach((rawLine, index) => {
    const lineNumber = index + 1;
    const line = rawLine.trim();
    if (line === "" || line.startsWith("#")) {
      return;
    }

    const parts = line.split(/\s+/);
    const [kind, label, repo, mode, ...skills] = parts;
    if (kind !== "source" || !label || !repo || !mode) {
      errors.push(`invalid external skill source line ${lineNumber}: ${rawLine}`);
      return;
    }

    if (!labelPattern.test(label)) {
      errors.push(`unsafe external skill source label on line ${lineNumber}: ${label}`);
    }

    if (!repoSlugPattern.test(repo) && !githubUrlPattern.test(repo)) {
      errors.push(`unsupported external skill repo on line ${lineNumber}: ${repo}`);
    }

    if (mode !== "all" && mode !== "allowlist") {
      errors.push(`unknown external skill source mode on line ${lineNumber}: ${mode}`);
    }

    if (seenLabels.has(label)) {
      errors.push(`duplicate external skill source label on line ${lineNumber}: ${label}`);
    }
    seenLabels.add(label);

    for (const skill of skills) {
      if (!skillNamePattern.test(skill)) {
        errors.push(`unsafe external skill name on line ${lineNumber}: ${skill}`);
      }
    }

    if (mode === "allowlist" && skills.length === 0) {
      errors.push(`allowlisted external skill source needs at least one skill on line ${lineNumber}: ${label}`);
    }

    if (mode === "all" && skills.length > 0) {
      errors.push(`external skill source in all mode must not name skills on line ${lineNumber}: ${label}`);
    }

    if (mode === "all" || mode === "allowlist") {
      sources.push({ label, repo, mode, skills });
    }
  });

  return { manifest: { sources }, errors };
};

export const checkExternalSkillSourcesText = (text: string): string[] => parseLines(text).errors;

export const parseExternalSkillSourcesText = (text: string): ExternalSkillSourceManifest => {
  const result = parseLines(text);
  if (result.errors.length > 0) {
    throw new Error(result.errors.join("\n"));
  }
  return result.manifest;
};

export const readExternalSkillSources = (manifestPath: string): ExternalSkillSourceManifest => {
  if (!existsSync(manifestPath)) {
    throw new Error(`missing external skill source manifest: ${manifestPath}`);
  }

  return parseExternalSkillSourcesText(readFileSync(manifestPath, "utf8"));
};

export const findExternalSkillSource = (
  manifest: ExternalSkillSourceManifest,
  label: string,
): ExternalSkillSource => {
  const source = manifest.sources.find((candidate) => candidate.label === label);
  if (!source) {
    throw new Error(`unknown external skill source: ${label}`);
  }
  return source;
};

const usage = () => {
  console.error("Usage: external-skill-sources.ts <validate|list|repo|skill-args> <manifest> [label]");
};

const main = () => {
  const [command, manifestPath, label] = process.argv.slice(2);
  if (!command || !manifestPath) {
    usage();
    process.exit(2);
  }

  try {
    const manifest = readExternalSkillSources(manifestPath);

    if (command === "validate") {
      console.log("  ✓ external skill sources are valid");
      return;
    }

    if (command === "list") {
      console.log(manifest.sources.map((source) => source.label).join("\n"));
      return;
    }

    if (!label) {
      usage();
      process.exit(2);
    }

    const source = findExternalSkillSource(manifest, label);

    if (command === "repo") {
      console.log(source.repo);
      return;
    }

    if (command === "skill-args") {
      if (source.mode === "allowlist") {
        console.log(source.skills.flatMap((skill) => ["--skill", skill]).join("\n"));
      }
      return;
    }

    usage();
    process.exit(2);
  } catch (error) {
    console.error(`  ! ${error instanceof Error ? error.message : String(error)}`);
    process.exit(1);
  }
};

if (import.meta.main) {
  main();
}
