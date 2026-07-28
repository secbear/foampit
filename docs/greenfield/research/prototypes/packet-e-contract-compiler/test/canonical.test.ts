import { createHash } from "node:crypto";
import { access, readFile, rm } from "node:fs/promises";
import { execFile } from "node:child_process";
import { promisify } from "node:util";

import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

import { canonicalizeSemanticJson, semanticDigest } from "../src/canonical.js";
import { lowerContract } from "../src/lower.js";

const { compile } = createTester(new URL("../", import.meta.url).pathname, { libraries: ["contract"] });
const exec = promisify(execFile);

async function validModel() {
  const source = await readFile(new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url), "utf8");
  return lowerContract((await compile(source)).program);
}

it("canonicalizes object keys while preserving semantic array order", () => {
  expect(canonicalizeSemanticJson({ b: "two", a: [true, null, "one"] })).toEqual(
    canonicalizeSemanticJson({ a: [true, null, "one"], b: "two" }),
  );
  expect(canonicalizeSemanticJson(["one", "two"])).not.toEqual(
    canonicalizeSemanticJson(["two", "one"]),
  );
});

it.each([1, undefined, new Date(), { toJSON: () => "host" }])("rejects non-semantic value %#", (value) => {
  expect(() => canonicalizeSemanticJson(value as never)).toThrow();
});

it.each([new Array(1), "/host/absolute", "C:\\host\\absolute", "\\\\server\\share\\path"])("rejects sparse arrays and absolute host paths %#", (value) => {
  expect(() => canonicalizeSemanticJson(value as never)).toThrow();
});

it("runs the documented emit command", async () => {
  const output = new URL("../tsp-output", import.meta.url);
  await rm(output, { recursive: true, force: true });
  await expect(exec("pnpm", ["emit", "--", "fixtures/valid/packet-e-slice"], { cwd: new URL("../", import.meta.url).pathname })).resolves.toBeDefined();
  await expect(access(output)).rejects.toThrow();
});

it("hashes exactly the canonical model bytes and changes for semantic mutations", async () => {
  const model = await validModel();
  expect(semanticDigest(model)).toBe(createHash("sha256").update(canonicalizeSemanticJson(model)).digest("hex"));
  expect(semanticDigest({ ...model, contractId: "changed" } as never)).not.toBe(semanticDigest(model));
  expect(semanticDigest({ ...model, terminalStateIds: model.terminalStateIds.slice(1) })).not.toBe(semanticDigest(model));
  expect(semanticDigest({ ...model, matrices: [{ ...model.matrices[0]!, cells: [{ rowId: "x", columnId: "y", kind: "noop" }] }] })).not.toBe(semanticDigest(model));
  expect(semanticDigest({ ...model, operations: [{ ...model.operations[0]!, allowedRequestErrors: ["request.changed"] }, ...model.operations.slice(1)] })).not.toBe(semanticDigest(model));
});

it("changes the digest for one existing stable ID, wire tag, matrix outcome, and allowed error", async () => {
  const model = await validModel();
  const changedStableId = { ...model, closedSums: [{ ...model.closedSums[0]!, variants: [{ ...model.closedSums[0]!.variants[0]!, id: "ambiguity.runtime.changed" }, ...model.closedSums[0]!.variants.slice(1)] }, ...model.closedSums.slice(1)] };
  const changedWireTag = { ...model, closedSums: [{ ...model.closedSums[0]!, variants: [{ ...model.closedSums[0]!.variants[0]!, wireTag: "9" }, ...model.closedSums[0]!.variants.slice(1)] }, ...model.closedSums.slice(1)] };
  const changedOutcome = { ...model, matrices: [{ ...model.matrices[0]!, cells: [{ ...model.matrices[0]!.cells[0]!, kind: "replay" as const }, ...model.matrices[0]!.cells.slice(1)] }] };
  const changedError = { ...model, operations: [{ ...model.operations[0]!, allowedRequestErrors: ["request.sequence.out.of.range"] }, ...model.operations.slice(1)] };
  for (const mutated of [changedStableId, changedWireTag, changedOutcome, changedError]) {
    expect(semanticDigest(mutated)).not.toBe(semanticDigest(model));
  }
});

it("matches the canonical model golden byte-for-byte", async () => {
  const golden = await readFile(new URL("./golden/contract-model.json", import.meta.url), "utf8");
  const canonical = new TextDecoder().decode(
    canonicalizeSemanticJson(await validModel() as never),
  );
  expect(canonical).not.toContain('"states":');
  expect(canonical).not.toContain('"registries":');
  expect(canonical).not.toContain('"wireIdentities":');
  expect(canonical).toBe(golden);
});
