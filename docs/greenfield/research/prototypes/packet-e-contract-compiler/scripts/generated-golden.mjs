import {
  lstat,
  mkdir,
  readFile,
  readdir,
  realpath,
  writeFile,
} from "node:fs/promises";
import { join, relative } from "node:path";
import { fileURLToPath } from "node:url";

import { createTester } from "@typespec/compiler/testing";

import { generateAll } from "../dist/src/generate/index.js";
import { lowerContract } from "../dist/src/lower.js";
import { removeGeneratedGolden } from "./safe-tree.mjs";

const packageRoot = await realpath(
  fileURLToPath(new URL("../", import.meta.url)),
);
const goldenRoot = join(packageRoot, "test", "golden", "generated");
const mode = process.argv[2];

if (
  process.argv.length !== 3 ||
  (mode !== "--check" && mode !== "--update")
) {
  console.error("usage: generated-golden.mjs --check|--update");
  process.exit(2);
}
const source = await readFile(
  new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url),
  "utf8",
);
const { compile } = createTester(packageRoot, { libraries: ["contract"] });
const model = lowerContract((await compile(source)).program);
const generated = generateAll(model);

if (mode === "--update") {
  const physicalGoldenRoot = await removeGeneratedGolden(packageRoot);
  for (const file of generated) {
    const destination = join(
      physicalGoldenRoot,
      ...file.relativePath.split("/"),
    );
    await mkdir(join(destination, ".."), { recursive: true });
    await writeFile(destination, file.bytes);
  }
  console.log(`updated generated goldens (${generated.length} files)`);
} else {
  await assertPhysicalDirectoryChain(packageRoot, [
    "test",
    "golden",
    "generated",
  ]);
  const committed = await filesUnder(goldenRoot);
  const expectedPaths = generated.map((file) => file.relativePath);
  const actualPaths = [...committed.keys()].sort(compareStrings);
  if (
    actualPaths.length !== expectedPaths.length ||
    actualPaths.some((path, index) => path !== expectedPaths[index])
  ) {
    throw new Error(
      `contract/generated-golden-path-mismatch: expected ${JSON.stringify(expectedPaths)}, received ${JSON.stringify(actualPaths)}`,
    );
  }
  for (const file of generated) {
    const bytes = committed.get(file.relativePath);
    if (
      bytes === undefined ||
      !bytes.equals(Buffer.from(file.bytes))
    ) {
      throw new Error(
        `contract/generated-golden-byte-mismatch: ${file.relativePath}`,
      );
    }
  }
  console.log(`generated goldens match (${generated.length} files)`);
}

async function assertPhysicalDirectoryChain(root, components) {
  let directory = root;
  for (const component of [undefined, ...components]) {
    if (component !== undefined) {
      directory = join(directory, component);
    }
    let metadata;
    try {
      metadata = await lstat(directory);
    } catch (error) {
      if (error?.code !== "ENOENT" && error?.code !== "ENOTDIR") {
        throw error;
      }
    }
    if (metadata?.isDirectory() !== true) {
      const key = relative(root, directory).replaceAll("\\", "/") || ".";
      throw new Error(`contract/generated-golden-directory-invalid: ${key}`);
    }
  }
}

async function filesUnder(root) {
  const files = new Map();
  async function visit(directory) {
    let entries;
    try {
      entries = await readdir(directory, { withFileTypes: true });
    } catch (error) {
      if (error?.code === "ENOENT") return;
      throw error;
    }
    entries.sort((left, right) => compareStrings(left.name, right.name));
    for (const entry of entries) {
      const path = join(directory, entry.name);
      if (entry.isDirectory()) {
        await visit(path);
      } else if (entry.isFile()) {
        files.set(
          relative(root, path).replaceAll("\\", "/"),
          await readFile(path),
        );
      } else {
        const key = relative(root, path).replaceAll("\\", "/");
        throw new Error(`contract/generated-golden-entry-invalid: ${key}`);
      }
    }
  }
  await visit(root);
  return files;
}

function compareStrings(left, right) {
  return left < right ? -1 : left > right ? 1 : 0;
}
