import { posix } from "node:path";

import type { ContractModel } from "../model.js";

export type GeneratedFile = Readonly<{
  relativePath: string;
  bytes: Uint8Array;
}>;
export type ContractGenerator = (
  model: Readonly<ContractModel>,
) => readonly GeneratedFile[];
export type GeneratedSymbol = Readonly<{
  source: string;
  name: string;
}>;

const encoder = new TextEncoder();
const stableIdPattern = /^[a-z][a-z0-9]*(?:\.[a-z][a-z0-9]*)*$/;

export function generatedFile(
  relativePath: string,
  content: string,
): GeneratedFile {
  return Object.freeze({ relativePath, bytes: encoder.encode(content) });
}

export function validateGeneratedFiles(
  files: readonly GeneratedFile[],
): readonly GeneratedFile[] {
  const paths = new Set<string>();
  for (const file of files) {
    if (!isSafeRelativePath(file.relativePath)) {
      throw new Error("contract/generated-file-path-invalid");
    }
    const identity = portablePathIdentity(file.relativePath);
    if (paths.has(identity)) {
      throw new Error("contract/generated-file-path-duplicate");
    }
    paths.add(identity);
  }
  return Object.freeze(
    [...files].sort((left, right) =>
      compareStrings(left.relativePath, right.relativePath),
    ),
  );
}

export function generatedName(stableId: string): string {
  if (!stableIdPattern.test(stableId)) {
    throw new Error("contract/generated-name-invalid");
  }
  return stableId
    .split(".")
    .map((part) => part.slice(0, 1).toUpperCase() + part.slice(1))
    .join("");
}

export function generatedNames(
  stableIds: readonly string[],
): ReadonlyMap<string, string> {
  return generatedSymbolTable(
    stableIds.map((stableId) => ({
      source: stableId,
      name: generatedName(stableId),
    })),
  );
}

export function generatedSymbolTable(
  symbols: readonly GeneratedSymbol[],
): ReadonlyMap<string, string> {
  const bySource = new Map<string, string>();
  const names = new Set<string>();
  const sorted = [...symbols].sort(
    (left, right) =>
      compareStrings(left.name, right.name) ||
      compareStrings(left.source, right.source),
  );
  for (const symbol of sorted) {
    if (bySource.has(symbol.source) || names.has(symbol.name)) {
      throw new Error("contract/generated-name-collision");
    }
    bySource.set(symbol.source, symbol.name);
    names.add(symbol.name);
  }
  return bySource;
}

export function operationNames(
  model: Readonly<ContractModel>,
): readonly string[] {
  const operationIds = model.operations.map(
    (operation) => operation.operationId,
  );
  const names = generatedNames(operationIds);
  return Object.freeze(
    [...names.entries()]
      .map(([stableId, name]) => {
        const prefix = "operation.";
        if (!stableId.startsWith(prefix)) {
          throw new Error("contract/generated-name-invalid");
        }
        return generatedName(stableId.slice(prefix.length));
      })
      .sort(compareStrings),
  );
}

export function lowerCamel(name: string): string {
  return name.slice(0, 1).toLowerCase() + name.slice(1);
}

export function snakeCase(name: string): string {
  return name
    .replace(/([a-z0-9])([A-Z])/g, "$1_$2")
    .replace(/([A-Z])([A-Z][a-z])/g, "$1_$2")
    .toLowerCase();
}

export function compareStrings(left: string, right: string): number {
  return left < right ? -1 : left > right ? 1 : 0;
}

function isSafeRelativePath(relativePath: string): boolean {
  if (
    relativePath.length === 0 ||
    relativePath.includes("\0") ||
    relativePath.includes("\\") ||
    relativePath.startsWith("/") ||
    /^[A-Za-z]:/.test(relativePath) ||
    relativePath !== relativePath.normalize("NFC") ||
    posix.normalize(relativePath) !== relativePath
  ) {
    return false;
  }
  const parts = relativePath.split("/");
  return parts.every(
    (part) => part.length > 0 && part !== "." && part !== "..",
  );
}

function portablePathIdentity(relativePath: string): string {
  return relativePath.normalize("NFC").toLowerCase();
}
