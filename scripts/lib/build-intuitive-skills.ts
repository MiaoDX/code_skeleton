#!/usr/bin/env bun

import {
  cpSync,
  existsSync,
  mkdirSync,
  mkdtempSync,
  readdirSync,
  readFileSync,
  rmSync,
  statSync,
  writeFileSync,
} from "node:fs";
import { join, relative } from "node:path";
import { tmpdir } from "node:os";

export type SkillBuildOptions = {
  sourceRoot: string;
  outputRoot: string;
};

export type SkillBuildResult = {
  skillNames: string[];
  files: string[];
};

const includePattern = /^\s*\{\{>\s*([^}]+?)\s*\}\}\s*$/;

const defaultOptions = (): SkillBuildOptions => ({
  sourceRoot: join(process.cwd(), "skills-src"),
  outputRoot: join(process.cwd(), "skills"),
});

const normalizeText = (text: string) => text.replace(/\r\n/g, "\n");

const assertSafeIncludePath = (includePath: string) => {
  const parts = includePath.split("/");
  if (
    includePath.startsWith("/") ||
    includePath.includes("\\") ||
    parts.includes("..") ||
    parts.includes(".") ||
    includePath.trim() !== includePath ||
    !includePath.endsWith(".md")
  ) {
    throw new Error(`unsafe include path: ${includePath}`);
  }
};

const sortedDirEntries = (dir: string) => readdirSync(dir).sort((a, b) => a.localeCompare(b));

export const sourceSkillNames = (options: SkillBuildOptions): string[] => {
  if (!existsSync(options.sourceRoot)) {
    throw new Error(`missing skill source root: ${options.sourceRoot}`);
  }

  return sortedDirEntries(options.sourceRoot).filter((entry) => {
    const skillDir = join(options.sourceRoot, entry);
    return entry.startsWith("intuitive-") && statSync(skillDir).isDirectory() && existsSync(join(skillDir, "SKILL.md"));
  });
};

export const expandSkillTemplate = (
  templatePath: string,
  options: SkillBuildOptions,
  stack: string[] = [],
): string => {
  const relativeTemplatePath = relative(options.sourceRoot, templatePath);
  if (stack.includes(relativeTemplatePath)) {
    throw new Error(`cyclic skill include: ${[...stack, relativeTemplatePath].join(" -> ")}`);
  }

  const nextStack = [...stack, relativeTemplatePath];
  const text = normalizeText(readFileSync(templatePath, "utf8"));

  return text
    .split("\n")
    .map((line) => {
      const match = includePattern.exec(line);
      if (!match) {
        return line;
      }

      const includePath = match[1];
      assertSafeIncludePath(includePath);
      return expandSkillTemplate(join(options.sourceRoot, includePath), options, nextStack).replace(/\n$/, "");
    })
    .join("\n");
};

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

const copySkillResources = (sourceSkillDir: string, outputSkillDir: string) => {
  for (const entry of sortedDirEntries(sourceSkillDir)) {
    if (entry === "SKILL.md") {
      continue;
    }

    cpSync(join(sourceSkillDir, entry), join(outputSkillDir, entry), { recursive: true });
  }
};

export const buildIntuitiveSkills = (options = defaultOptions()): SkillBuildResult => {
  mkdirSync(options.outputRoot, { recursive: true });

  const skillNames = sourceSkillNames(options);
  const files: string[] = [];

  for (const skillName of skillNames) {
    const sourceSkillDir = join(options.sourceRoot, skillName);
    const outputSkillDir = join(options.outputRoot, skillName);

    rmSync(outputSkillDir, { recursive: true, force: true });
    mkdirSync(outputSkillDir, { recursive: true });

    const skillText = expandSkillTemplate(join(sourceSkillDir, "SKILL.md"), options);
    writeFileSync(join(outputSkillDir, "SKILL.md"), skillText);
    copySkillResources(sourceSkillDir, outputSkillDir);

    for (const file of listFiles(outputSkillDir)) {
      files.push(`${skillName}/${file}`);
    }
  }

  return { skillNames, files: files.sort((a, b) => a.localeCompare(b)) };
};

const compareGeneratedSkill = (expectedSkillDir: string, actualSkillDir: string, skillName: string): string[] => {
  if (!existsSync(actualSkillDir)) {
    return [`missing generated skill directory: skills/${skillName}`];
  }

  const errors: string[] = [];
  const expectedFiles = listFiles(expectedSkillDir);
  const actualFiles = listFiles(actualSkillDir);
  const expectedSet = new Set(expectedFiles);
  const actualSet = new Set(actualFiles);

  for (const file of expectedFiles) {
    if (!actualSet.has(file)) {
      errors.push(`missing generated file: skills/${skillName}/${file}`);
      continue;
    }

    const expected = readFileSync(join(expectedSkillDir, file));
    const actual = readFileSync(join(actualSkillDir, file));
    if (!expected.equals(actual)) {
      errors.push(`generated file is stale: skills/${skillName}/${file}`);
    }
  }

  for (const file of actualFiles) {
    if (!expectedSet.has(file)) {
      errors.push(`unexpected generated file: skills/${skillName}/${file}`);
    }
  }

  return errors;
};

export const checkIntuitiveSkills = (options = defaultOptions()): string[] => {
  const tempRoot = mkdtempSync(join(tmpdir(), "intuitive-skill-build-"));
  try {
    const expectedOutputRoot = join(tempRoot, "skills");
    const expected = buildIntuitiveSkills({
      sourceRoot: options.sourceRoot,
      outputRoot: expectedOutputRoot,
    });
    const expectedSkillNames = new Set(expected.skillNames);

    const errors: string[] = [];
    for (const skillName of expected.skillNames) {
      errors.push(
        ...compareGeneratedSkill(
          join(expectedOutputRoot, skillName),
          join(options.outputRoot, skillName),
          skillName,
        ),
      );
    }

    if (existsSync(options.outputRoot)) {
      for (const entry of sortedDirEntries(options.outputRoot)) {
        const skillDir = join(options.outputRoot, entry);
        if (
          entry.startsWith("intuitive-") &&
          statSync(skillDir).isDirectory() &&
          existsSync(join(skillDir, "SKILL.md")) &&
          !expectedSkillNames.has(entry)
        ) {
          errors.push(`unexpected generated skill directory: skills/${entry}`);
        }
      }
    }

    return errors;
  } finally {
    rmSync(tempRoot, { recursive: true, force: true });
  }
};

const usage = () => {
  console.error("Usage: build-intuitive-skills.ts <write|check>");
};

const main = () => {
  const [command] = process.argv.slice(2);

  try {
    if (command === "write") {
      const result = buildIntuitiveSkills();
      console.log(`  ✓ generated ${result.skillNames.length} intuitive skill(s) from skills-src/`);
      return;
    }

    if (command === "check") {
      const errors = checkIntuitiveSkills();
      for (const error of errors) {
        console.error(`  ! ${error}`);
      }
      if (errors.length > 0) {
        console.error("  ! run: bun run build:skills");
        process.exit(1);
      }
      console.log("  ✓ generated intuitive skills are up to date");
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
