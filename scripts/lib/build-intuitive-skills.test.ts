import { describe, expect, test } from "bun:test";
import { existsSync, mkdirSync, mkdtempSync, rmSync, writeFileSync } from "node:fs";
import { dirname, join } from "node:path";
import { tmpdir } from "node:os";
import { buildIntuitiveSkills, checkIntuitiveSkills } from "./build-intuitive-skills";

const withTempProject = async (callback: (root: string) => Promise<void> | void) => {
  const root = mkdtempSync(join(tmpdir(), "skill-build-project-"));
  try {
    await callback(root);
  } finally {
    rmSync(root, { recursive: true, force: true });
  }
};

const writeFixtureFile = (root: string, relativePath: string, text: string) => {
  const path = join(root, relativePath);
  mkdirSync(dirname(path), { recursive: true });
  writeFileSync(path, text);
};

describe("intuitive skill builder", () => {
  test("expands common fragments into standalone skill output and copies resources", async () => {
    await withTempProject(async (root) => {
      writeFixtureFile(root, "skills-src/intuitive-common/shared.md", "shared rule\n");
      writeFixtureFile(
        root,
        "skills-src/intuitive-alpha/SKILL.md",
        "before\n{{> intuitive-common/shared.md}}\nafter\n",
      );
      writeFixtureFile(root, "skills-src/intuitive-alpha/evals/evals.json", "{}\n");

      const result = buildIntuitiveSkills({
        sourceRoot: join(root, "skills-src"),
        outputRoot: join(root, "skills"),
      });

      expect(result.skillNames).toEqual(["intuitive-alpha"]);
      expect(await Bun.file(join(root, "skills", "intuitive-alpha", "SKILL.md")).text()).toBe(
        "before\nshared rule\nafter\n",
      );
      expect(existsSync(join(root, "skills", "intuitive-alpha", "evals", "evals.json"))).toBe(true);
    });
  });

  test("check reports generated output drift", async () => {
    await withTempProject(async (root) => {
      writeFixtureFile(root, "skills-src/intuitive-common/shared.md", "fresh\n");
      writeFixtureFile(root, "skills-src/intuitive-alpha/SKILL.md", "{{> intuitive-common/shared.md}}\n");
      writeFixtureFile(root, "skills/intuitive-alpha/SKILL.md", "stale\n");

      const errors = checkIntuitiveSkills({
        sourceRoot: join(root, "skills-src"),
        outputRoot: join(root, "skills"),
      });

      expect(errors).toContain("generated file is stale: skills/intuitive-alpha/SKILL.md");
    });
  });

  test("check reports stale intuitive output directories without source", async () => {
    await withTempProject(async (root) => {
      writeFixtureFile(root, "skills-src/intuitive-alpha/SKILL.md", "alpha\n");
      writeFixtureFile(root, "skills/intuitive-old/SKILL.md", "old\n");

      const errors = checkIntuitiveSkills({
        sourceRoot: join(root, "skills-src"),
        outputRoot: join(root, "skills"),
      });

      expect(errors).toContain("unexpected generated skill directory: skills/intuitive-old");
    });
  });

  test("rejects unsafe include paths", async () => {
    await withTempProject((root) => {
      writeFixtureFile(root, "skills-src/intuitive-alpha/SKILL.md", "{{> ../bad.md}}\n");

      expect(() =>
        buildIntuitiveSkills({
          sourceRoot: join(root, "skills-src"),
          outputRoot: join(root, "skills"),
        }),
      ).toThrow("unsafe include path");
    });
  });
});
