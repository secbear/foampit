import { relative } from "node:path";

import { emitFile, getSourceLocation, type EmitContext, type Program, type Type } from "@typespec/compiler";

import { canonicalizeSemanticJson, semanticDigest } from "./canonical.js";
import { getContractRoot } from "./accessors.js";
import { sourceTargetFor, lowerContract } from "./lower.js";
import type { ContractModel } from "./model.js";
import { assertValidContractModel } from "./validate.js";

export type ContractBundle = Readonly<{
  bundleVersion: "0.1.0";
  digestAlgorithm: "sha256";
  semanticDigest: string;
  model: ContractModel;
}>;

export type ContractSourceMap = Readonly<{
  sourceMapVersion: "0.1.0";
  entries: readonly (Readonly<{ id: string; path: string; line: string; column: string }>)[];
}>;

export type EmitterOptions = Record<string, never>;

const decoder = new TextDecoder();

export function buildContractBundle(model: ContractModel): ContractBundle {
  assertValidContractModel(model);
  return Object.freeze({
    bundleVersion: "0.1.0",
    digestAlgorithm: "sha256",
    semanticDigest: semanticDigest(model),
    model,
  });
}

export function buildSourceMap(program: Program, model: ContractModel): ContractSourceMap {
  const targets: readonly (readonly [string, Type | undefined])[] = [
    ["contract-root", getContractRoot(program)],
    ...model.closedSums.map((sum) => [`sum:${sum.id}`, sourceTargetFor(model, `sum:${sum.id}`)] as const),
    ...model.operations.map((operation) => [`operation:${operation.operationId}`, sourceTargetFor(model, `operation:${operation.operationId}`)] as const),
    ...model.matrices.map((matrix) => [`matrix:${matrix.id}`, sourceTargetFor(model, `matrix:${matrix.id}`)] as const),
  ];
  const entries = targets.flatMap(([id, target]) => {
    if (target === undefined) return [];
    const location = getSourceLocation(target);
    const lineAndCharacter = location.file.getLineAndCharacterOfPosition(location.pos);
    return [Object.freeze({
      id,
      path: relative(program.projectRoot, location.file.path).replaceAll("\\", "/"),
      line: String(lineAndCharacter.line + 1),
      column: String(lineAndCharacter.character + 1),
    })];
  }).sort((left, right) => left.id.localeCompare(right.id));
  return Object.freeze({ sourceMapVersion: "0.1.0", entries: Object.freeze(entries) });
}

export async function $onEmit(context: EmitContext<EmitterOptions>): Promise<void> {
  const model = lowerContract(context.program);
  const bundle = buildContractBundle(model);
  const sourceMap = buildSourceMap(context.program, model);
  await Promise.all([
    emitCanonical(context, "contract-model.json", model),
    emitCanonical(context, "contract-bundle.json", bundle),
    emitCanonical(context, "source-map.json", sourceMap),
  ]);
}

async function emitCanonical(context: EmitContext<EmitterOptions>, name: string, value: Parameters<typeof canonicalizeSemanticJson>[0]): Promise<void> {
  await emitFile(context.program, {
    path: `${context.emitterOutputDir}/${name}`,
    content: decoder.decode(canonicalizeSemanticJson(value as unknown as import("./canonical.js").SemanticJson)),
  });
}
