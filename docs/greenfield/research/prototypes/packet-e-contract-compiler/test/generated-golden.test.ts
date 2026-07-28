import { spawnSync } from "node:child_process";
import {
  access,
  copyFile,
  mkdir,
  mkdtemp,
  readFile,
  readdir,
  realpath,
  rm,
  stat,
  symlink,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join, relative, sep } from "node:path";

import { createTester } from "@typespec/compiler/testing";
import { afterEach, expect, it, vi } from "vitest";

import { generatedFile, type ContractGenerator } from "../src/generate/common.js";
import { generateAll } from "../src/generate/index.js";
import { generateOpenApi } from "../src/generate/openapi.js";
import { generateProtobuf } from "../src/generate/protobuf.js";
import { lowerContract } from "../src/lower.js";

const packageRoot = new URL("../", import.meta.url).pathname;
const goldenRoot = join(packageRoot, "test/golden/generated");
const scriptPath = join(packageRoot, "scripts/generated-golden.mjs");
const safeTreeModuleUrl = new URL(
  "../scripts/safe-tree.mjs",
  import.meta.url,
).href;
const { compile } = createTester(packageRoot, { libraries: ["contract"] });
const expectedPaths = [
  "cue/contract.cue",
  "go/contract.go",
  "go/contract_test.go",
  "go/go.mod",
  "openapi/contract.json",
  "protobuf/contract.proto",
  "python/contract.py",
  "python/run.py",
  "python/test_contract.py",
  "quint/contract.qnt",
  "rust/lib.rs",
  "rust/validate.rs",
  "typescript/contract.ts",
  "typescript/run.mjs",
  "typescript/static-construction.test.ts",
  "typescript/tsconfig.json",
] as const;

async function contractModel(fixture = "packet-e-slice") {
  const source = await readFile(
    new URL(`../fixtures/valid/${fixture}/main.tsp`, import.meta.url),
    "utf8",
  );
  return lowerContract((await compile(source)).program);
}

async function filesUnder(root: string): Promise<ReadonlyMap<string, Buffer>> {
  const files = new Map<string, Buffer>();
  async function visit(directory: string): Promise<void> {
    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch (error) {
      if (
        typeof error === "object" &&
        error !== null &&
        "code" in error &&
        error.code === "ENOENT"
      ) {
        return;
      }
      throw error;
    }
    for (const entry of entries) {
      const path = join(directory, entry.name);
      if (entry.isDirectory()) {
        await visit(path);
      } else if (entry.isFile()) {
        files.set(relative(root, path).replaceAll("\\", "/"), await readFile(path));
      }
    }
  }
  await visit(root);
  return files;
}

async function fileState(
  root: string,
): Promise<ReadonlyMap<string, Readonly<{ bytes: Buffer; mtimeNs: bigint }>>> {
  const files = await filesUnder(root);
  return new Map(
    await Promise.all(
      [...files].map(async ([path, bytes]) => [
        path,
        Object.freeze({
          bytes,
          mtimeNs: (await stat(join(root, ...path.split("/")), { bigint: true }))
            .mtimeNs,
        }),
      ] as const),
    ),
  );
}

type SafeTreeModule = Readonly<{
  removeBuildOutput: (root: string) => Promise<string>;
  removeGeneratedGolden: (root: string) => Promise<string>;
  removeTreeSafely: (
    root: string,
    relativeTarget: string,
    options: Readonly<{ allowMissingLeaf: boolean }>,
  ) => Promise<string>;
}>;

async function safeTree(): Promise<SafeTreeModule> {
  return (await import(safeTreeModuleUrl)) as SafeTreeModule;
}

async function goldenCheckSandbox(
  temporary: string,
  symlinkAt: "test/golden" | "test/golden/generated",
): Promise<
  Readonly<{
    root: string;
    script: string;
    sentinelPath: string;
    sentinelBytes: Buffer;
  }>
> {
  const root = join(temporary, "package");
  const externalGolden = join(temporary, "external-golden");
  const externalGenerated = join(externalGolden, "generated");
  const fixtureDirectory = join(root, "fixtures/valid/packet-e-slice");
  await mkdir(join(root, "scripts"), { recursive: true });
  await mkdir(join(root, "lib"), { recursive: true });
  await mkdir(fixtureDirectory, { recursive: true });
  await mkdir(externalGenerated, { recursive: true });
  await Promise.all([
    copyFile(join(packageRoot, "package.json"), join(root, "package.json")),
    copyFile(
      join(packageRoot, "scripts/generated-golden.mjs"),
      join(root, "scripts/generated-golden.mjs"),
    ),
    copyFile(
      join(packageRoot, "scripts/safe-tree.mjs"),
      join(root, "scripts/safe-tree.mjs"),
    ),
    copyFile(join(packageRoot, "lib/main.tsp"), join(root, "lib/main.tsp")),
    copyFile(
      join(packageRoot, "fixtures/valid/packet-e-slice/main.tsp"),
      join(fixtureDirectory, "main.tsp"),
    ),
    symlink(join(packageRoot, "dist"), join(root, "dist"), "dir"),
    symlink(
      join(packageRoot, "node_modules"),
      join(root, "node_modules"),
      "dir",
    ),
  ]);

  const generated = generateAll(await contractModel());
  for (const file of generated) {
    const destination = join(
      externalGenerated,
      ...file.relativePath.split("/"),
    );
    await mkdir(join(destination, ".."), { recursive: true });
    await writeFile(destination, file.bytes);
  }
  const sentinel = generated[0];
  if (sentinel === undefined) {
    throw new Error("test setup requires at least one generated file");
  }
  const sentinelPath = join(
    externalGenerated,
    ...sentinel.relativePath.split("/"),
  );

  if (symlinkAt === "test/golden") {
    await mkdir(join(root, "test"), { recursive: true });
    await symlink(externalGolden, join(root, "test/golden"), "dir");
  } else {
    await mkdir(join(root, "test/golden"), { recursive: true });
    await symlink(
      externalGenerated,
      join(root, "test/golden/generated"),
      "dir",
    );
  }
  return {
    root,
    script: join(root, "scripts/generated-golden.mjs"),
    sentinelPath,
    sentinelBytes: Buffer.from(sentinel.bytes),
  };
}

afterEach(() => {
  vi.doUnmock("../src/generate/rust.js");
  vi.resetModules();
});

it.each([
  { name: "build", relativeTarget: "dist" },
  { name: "golden", relativeTarget: "test/golden/generated" },
])(
  "rejects a symlinked $name deletion leaf before touching its external target",
  async ({ relativeTarget }) => {
    const temporary = await mkdtemp(join(tmpdir(), "packet-e-safe-leaf-"));
    try {
      const root = join(temporary, "project");
      const external = join(temporary, "external");
      const target = join(root, ...relativeTarget.split("/"));
      await mkdir(join(target, ".."), { recursive: true });
      await mkdir(external, { recursive: true });
      await writeFile(join(external, "sentinel"), "external-leaf\n");
      await symlink(external, target, "dir");

      const module = await safeTree();
      const removal =
        relativeTarget === "dist"
          ? module.removeBuildOutput(root)
          : module.removeGeneratedGolden(root);
      await expect(removal).rejects.toThrow(
        "contract/removal-path-symlink",
      );
      expect(await readFile(join(external, "sentinel"), "utf8")).toBe(
        "external-leaf\n",
      );
      await expect(access(target)).resolves.toBe(undefined);
    } finally {
      await rm(temporary, { recursive: true, force: true });
    }
  },
);

it.each([
  { name: "build", relativeTarget: "cache/dist", ancestor: "cache" },
  {
    name: "golden",
    relativeTarget: "test/golden/generated",
    ancestor: "test",
  },
])(
  "rejects a symlinked $name deletion ancestor before touching its external target",
  async ({ relativeTarget, ancestor }) => {
    const temporary = await mkdtemp(join(tmpdir(), "packet-e-safe-ancestor-"));
    try {
      const root = join(temporary, "project");
      const external = join(temporary, "external");
      await mkdir(root, { recursive: true });
      await mkdir(external, { recursive: true });
      await writeFile(join(external, "sentinel"), "external-ancestor\n");
      await symlink(external, join(root, ancestor), "dir");

      const module = await safeTree();
      const removal =
        relativeTarget === "test/golden/generated"
          ? module.removeGeneratedGolden(root)
          : module.removeTreeSafely(root, relativeTarget, {
              allowMissingLeaf: true,
            });
      await expect(removal).rejects.toThrow(
        "contract/removal-path-symlink",
      );
      expect(await readFile(join(external, "sentinel"), "utf8")).toBe(
        "external-ancestor\n",
      );
    } finally {
      await rm(temporary, { recursive: true, force: true });
    }
  },
);

it("removes only normal physical build and golden leaves without a trailing separator", async () => {
  const temporary = await mkdtemp(join(tmpdir(), "packet-e-safe-normal-"));
  try {
    const root = join(temporary, "project");
    const sibling = join(root, "sibling");
    await mkdir(join(root, "dist"), { recursive: true });
    await mkdir(join(root, "test/golden/generated"), { recursive: true });
    await writeFile(join(root, "dist/stale"), "build\n");
    await writeFile(
      join(root, "test/golden/generated/stale"),
      "golden\n",
    );
    await writeFile(sibling, "preserve\n");

    const module = await safeTree();
    const buildLeaf = await module.removeBuildOutput(root);
    const goldenLeaf = await module.removeGeneratedGolden(root);

    expect(buildLeaf.endsWith(sep)).toBe(false);
    expect(goldenLeaf.endsWith(sep)).toBe(false);
    await expect(access(join(root, "dist"))).rejects.toMatchObject({
      code: "ENOENT",
    });
    await expect(
      access(join(root, "test/golden/generated")),
    ).rejects.toMatchObject({ code: "ENOENT" });
    expect(await readFile(sibling, "utf8")).toBe("preserve\n");
  } finally {
    await rm(temporary, { recursive: true, force: true });
  }
});

it("permits only a missing final leaf below a fully physical ancestor chain", async () => {
  const temporary = await mkdtemp(join(tmpdir(), "packet-e-safe-missing-"));
  try {
    const root = join(temporary, "project");
    await mkdir(root, { recursive: true });
    const module = await safeTree();

    const missingLeaf = await module.removeTreeSafely(root, "dist", {
      allowMissingLeaf: true,
    });
    expect(missingLeaf).toBe(join(await realpath(root), "dist"));
    expect(missingLeaf.endsWith(sep)).toBe(false);
    await expect(
      module.removeTreeSafely(root, "missing/leaf", {
        allowMissingLeaf: true,
      }),
    ).rejects.toThrow("contract/removal-path-missing-ancestor");
  } finally {
    await rm(temporary, { recursive: true, force: true });
  }
});

it("composes the exact deterministic target set from either declaration order", async () => {
  const model = await contractModel();
  const generator: ContractGenerator = generateAll;
  const first = generator(model);
  const second = generator(model);
  const reordered = generator(await contractModel("packet-e-slice-reordered"));

  expect(first.map((file) => file.relativePath)).toEqual(expectedPaths);
  expect(first).toEqual(second);
  expect(first).toEqual(reordered);
  for (const file of first) {
    const output = new TextDecoder().decode(file.bytes);
    expect(output).not.toContain(packageRoot);
    expect(output).not.toContain("packet-e-slice/main.tsp");
    expect(output).not.toMatch(/\d{4}-\d{2}-\d{2}T\d{2}:\d{2}:\d{2}/);
  }
});

it("rejects an invalid model before any generator target runs", async () => {
  const model = await contractModel();
  expect(() => generateAll({ ...model, terminalStateIds: [] })).toThrow("contract/invalid-contract-model");
});

it("rejects a missing closed-variant wire tag before generator fan-out", async () => {
  const model = await contractModel();
  const mutated = { ...model, closedSums: model.closedSums.map((sum, index) => index === 0 ? { ...sum, variants: sum.variants.map((variant, variantIndex) => variantIndex === 0 ? { id: variant.id } : variant) } : sum) };
  expect(() => generateAll(mutated)).toThrow("contract/invalid-contract-model");
});

it.each([
  ["Protobuf", generateProtobuf],
  ["OpenAPI", generateOpenApi],
])("defensively rejects invalid wire tags in direct %s generation", async (_name, generator) => {
  const model = await contractModel();
  const mutated = { ...model, closedSums: model.closedSums.map((sum, index) => index === 0 ? { ...sum, variants: sum.variants.map((variant, variantIndex) => variantIndex === 0 ? { ...variant, wireTag: "536870912" } : variant) } : sum) };
  expect(() => generator(mutated)).toThrow("contract/invalid-wire-tag");
});

it.each([
  {
    name: "cross-target duplicate",
    files: [generatedFile("go/contract.go", "duplicate")],
    diagnostic: "contract/generated-file-path-duplicate",
  },
  {
    name: "unsafe target path",
    files: [generatedFile("../escape", "unsafe")],
    diagnostic: "contract/generated-file-path-invalid",
  },
])("rejects a $name from one composed target", async ({ files, diagnostic }) => {
  vi.resetModules();
  vi.doMock("../src/generate/rust.js", () => ({
    generateRust: () => files,
  }));
  const isolatedModule = await import("../src/generate/index.js");
  const model = await contractModel();
  expect(() => isolatedModule.generateAll(model)).toThrow(diagnostic);
});

it("matches every committed generated golden by exact path and byte", async () => {
  const generated = generateAll(await contractModel());
  const committed = await filesUnder(goldenRoot);

  expect([...committed.keys()].sort()).toEqual(expectedPaths);
  for (const file of generated) {
    expect(committed.get(file.relativePath), file.relativePath).toEqual(
      Buffer.from(file.bytes),
    );
  }
});

it("check mode is read-only and rejects every caller-selected output path", async () => {
  const before = await fileState(goldenRoot);
  const check = spawnSync(process.execPath, [scriptPath, "--check"], {
    cwd: packageRoot,
    encoding: "utf8",
  });
  expect(check.status, check.stderr).toBe(0);
  expect(check.stdout).toBe(
    `generated goldens match (${expectedPaths.length} files)\n`,
  );
  expect(await fileState(goldenRoot)).toEqual(before);

  const outside = join(packageRoot, "generated-golden-escape");
  await rm(outside, { recursive: true, force: true });
  const rejected = spawnSync(
    process.execPath,
    [scriptPath, "--update", outside],
    { cwd: packageRoot, encoding: "utf8" },
  );
  expect(rejected.status).not.toBe(0);
  await expect(access(outside)).rejects.toMatchObject({ code: "ENOENT" });
});

it("check mode rejects a symlink inventory entry without reading its target", async () => {
  const privateRoot = await mkdtemp(join(tmpdir(), "packet-e-golden-link-"));
  const sentinel = join(privateRoot, "sentinel");
  const link = join(goldenRoot, `unsafe-link-${process.pid}`);
  await writeFile(sentinel, "survives\n");
  try {
    await symlink(sentinel, link, "file");
    const check = spawnSync(process.execPath, [scriptPath, "--check"], {
      cwd: packageRoot,
      encoding: "utf8",
    });
    expect(check.status).not.toBe(0);
    expect(check.stderr).toContain("contract/generated-golden-entry-invalid");
    expect(await readFile(sentinel, "utf8")).toBe("survives\n");
  } finally {
    await rm(link, { force: true });
    await rm(privateRoot, { recursive: true, force: true });
  }
});

it.each([
  {
    name: "generated root",
    symlinkAt: "test/golden/generated",
    invalidPath: "test/golden/generated",
  },
  {
    name: "golden ancestor",
    symlinkAt: "test/golden",
    invalidPath: "test/golden",
  },
] as const)(
  "check mode rejects a symlinked $name before inventory traversal",
  async ({ symlinkAt, invalidPath }) => {
    const temporary = await mkdtemp(join(tmpdir(), "packet-e-golden-chain-"));
    try {
      const sandbox = await goldenCheckSandbox(temporary, symlinkAt);
      const check = spawnSync(process.execPath, [sandbox.script, "--check"], {
        cwd: sandbox.root,
        encoding: "utf8",
      });
      expect(check.status).not.toBe(0);
      expect(check.stderr).toContain(
        `contract/generated-golden-directory-invalid: ${invalidPath}`,
      );
      expect(await readFile(sandbox.sentinelPath)).toEqual(
        sandbox.sentinelBytes,
      );
    } finally {
      await rm(temporary, { recursive: true, force: true });
    }
  },
);

it("build removes stale compiled tests and emits source modules only", async () => {
  const staleTest = join(packageRoot, "dist/test/stale.test.js");
  const neighbor = join(packageRoot, "dist-neighbor-sentinel");
  await mkdir(join(staleTest, ".."), { recursive: true });
  await writeFile(staleTest, "throw new Error('rediscovered stale test');\n");
  await writeFile(neighbor, "preserve\n");
  try {
    const build = spawnSync("pnpm", ["build"], {
      cwd: packageRoot,
      encoding: "utf8",
    });
    expect(build.status, `${build.stdout}\n${build.stderr}`).toBe(0);
    await expect(access(join(packageRoot, "dist/test"))).rejects.toMatchObject({
      code: "ENOENT",
    });
    await expect(access(join(packageRoot, "dist/src/index.js"))).resolves.toBe(
      undefined,
    );
    expect(await readFile(neighbor, "utf8")).toBe("preserve\n");
  } finally {
    await rm(neighbor, { force: true });
    await rm(join(packageRoot, "dist/test"), {
      recursive: true,
      force: true,
    });
  }
});
