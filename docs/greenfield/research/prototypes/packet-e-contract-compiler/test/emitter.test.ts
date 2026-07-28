import { mkdtemp, readFile, rm } from "node:fs/promises";
import { execFile } from "node:child_process";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

import { buildContractBundle, buildSourceMap } from "../src/emitter.js";
import { canonicalizeSemanticJson } from "../src/canonical.js";
import { lowerContract } from "../src/lower.js";

const { compile } = createTester(new URL("../", import.meta.url).pathname, { libraries: ["contract"] });
const exec = promisify(execFile);
const packageRoot = new URL("../", import.meta.url).pathname;

async function compileValid() {
  const source = await readFile(new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url), "utf8");
  const { program } = await compile(source);
  return { program, model: lowerContract(program) };
}

it("builds a bundle from only canonical model bytes", async () => {
  const { model } = await compileValid();
  const bundle = buildContractBundle(model);
  expect(bundle.digestAlgorithm).toBe("sha256");
  expect(bundle.semanticDigest).toMatch(/^[a-f0-9]{64}$/);
  expect(bundle.model).toEqual(model);
  expect(JSON.stringify(bundle)).not.toContain(".tsp");
});

it("rejects an invalid model before constructing a bundle", async () => {
  const { model } = await compileValid();
  expect(() => buildContractBundle({ ...model, terminalStateIds: [] })).toThrow("contract/invalid-contract-model");
});

it("rejects a missing closed-variant wire tag before constructing a bundle", async () => {
  const { model } = await compileValid();
  const mutated = { ...model, closedSums: model.closedSums.map((sum, index) => index === 0 ? { ...sum, variants: sum.variants.map((variant, variantIndex) => variantIndex === 0 ? { id: variant.id } : variant) } : sum) };
  expect(() => buildContractBundle(mutated)).toThrow("contract/invalid-contract-model");
});

it("keeps source paths in a separate relative POSIX source map", async () => {
  const { program, model } = await compileValid();
  const sourceMap = buildSourceMap(program, model);
  expect(sourceMap.entries.length).toBeGreaterThan(0);
  expect(sourceMap.entries.every((entry) => !entry.path.startsWith("/") && !entry.path.includes("\\\\"))).toBe(true);
  expect(JSON.stringify(buildContractBundle(model))).not.toContain(JSON.stringify(sourceMap));
});

it("is deterministic across fresh compiler programs", async () => {
  const first = await compileValid();
  const second = await compileValid();
  expect(JSON.stringify(buildContractBundle(first.model))).toBe(JSON.stringify(buildContractBundle(second.model)));
  expect(JSON.stringify(buildSourceMap(first.program, first.model))).toBe(JSON.stringify(buildSourceMap(second.program, second.model)));
});

it("matches the canonical bundle golden byte-for-byte while source locations remain separate", async () => {
  const golden = await readFile(new URL("./golden/contract-bundle.json", import.meta.url), "utf8");
  const { model } = await compileValid();
  expect(new TextDecoder().decode(canonicalizeSemanticJson(buildContractBundle(model) as never))).toBe(golden);
});

it("changes only the source map when a declaration moves", async () => {
  const source = await readFile(new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url), "utf8");
  const first = await compileValid();
  const secondProgram = (await compile(`\n${source}`)).program;
  const secondModel = lowerContract(secondProgram);
  expect(buildContractBundle(secondModel)).toEqual(buildContractBundle(first.model));
  expect(buildSourceMap(secondProgram, secondModel)).not.toEqual(buildSourceMap(first.program, first.model));
});

it("byte-compares artifacts from two separate TypeSpec CLI processes with all goldens", async () => {
  const first = await mkdtemp(join(tmpdir(), "contract-emitter-a-"));
  const second = await mkdtemp(join(tmpdir(), "contract-emitter-b-"));
  try {
    await Promise.all([first, second].map((outputDir) => exec("pnpm", ["exec", "tsp", "compile", "--emit", "contract", "fixtures/valid/packet-e-slice", "--output-dir", outputDir], { cwd: packageRoot })));
    for (const name of ["contract-model.json", "contract-bundle.json", "source-map.json"]) {
      const [left, right, golden] = await Promise.all([readFile(join(first, "contract", name)), readFile(join(second, "contract", name)), readFile(new URL(`./golden/${name}`, import.meta.url))]);
      expect(left).toEqual(right);
      expect(left).toEqual(golden);
    }
  } finally {
    await Promise.all([rm(first, { recursive: true, force: true }), rm(second, { recursive: true, force: true })]);
  }
});

it("emits equal semantic bytes for the reordered declaration fixture", async () => {
  const first = await mkdtemp(join(tmpdir(), "contract-order-a-"));
  const second = await mkdtemp(join(tmpdir(), "contract-order-b-"));
  try {
    await exec("pnpm", ["exec", "tsp", "compile", "--emit", "contract", "fixtures/valid/packet-e-slice", "--output-dir", first], { cwd: packageRoot });
    await exec("pnpm", ["exec", "tsp", "compile", "--emit", "contract", "fixtures/valid/packet-e-slice-reordered", "--output-dir", second], { cwd: packageRoot });
    expect(await readFile(join(first, "contract", "contract-model.json"))).toEqual(await readFile(join(second, "contract", "contract-model.json")));
    expect(await readFile(join(first, "contract", "contract-bundle.json"))).toEqual(await readFile(join(second, "contract", "contract-bundle.json")));
  } finally {
    await Promise.all([rm(first, { recursive: true, force: true }), rm(second, { recursive: true, force: true })]);
  }
});
