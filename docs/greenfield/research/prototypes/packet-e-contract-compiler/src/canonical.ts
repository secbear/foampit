import { createHash } from "node:crypto";

import type { ContractModel } from "./model.js";

export type SemanticJson = null | boolean | string | readonly SemanticJson[] | SemanticJsonObject;
export interface SemanticJsonObject { readonly [key: string]: SemanticJson; }

const encoder = new TextEncoder();

/** RFC 8785-compatible for the intentionally restricted semantic value domain. */
export function canonicalizeSemanticJson(value: SemanticJson): Uint8Array {
  return encoder.encode(serialize(value));
}

export function semanticDigest(model: ContractModel): string {
  return createHash("sha256").update(canonicalizeSemanticJson(model as unknown as SemanticJson)).digest("hex");
}

function serialize(value: SemanticJson): string {
  if (value === null) return "null";
  if (typeof value === "boolean") return JSON.stringify(value);
  if (typeof value === "string") {
    if (isAbsoluteHostPath(value)) throw new TypeError("semantic JSON strings cannot contain absolute host paths");
    return JSON.stringify(value);
  }
  if (typeof value === "number" || typeof value === "undefined" || typeof value === "function" || typeof value === "symbol" || typeof value === "bigint") {
    throw new TypeError("semantic JSON permits only null, booleans, strings, arrays, and plain objects");
  }
  if (Array.isArray(value)) {
    for (let index = 0; index < value.length; index += 1) {
      if (!Object.hasOwn(value, index)) throw new TypeError("semantic JSON arrays cannot be sparse");
    }
    return `[${value.map(serialize).join(",")}]`;
  }
  if (Object.getPrototypeOf(value) !== Object.prototype && Object.getPrototypeOf(value) !== null) {
    throw new TypeError("semantic JSON objects must be plain objects");
  }
  const object = value as Readonly<Record<string, SemanticJson>>;
  return `{${Object.keys(object).sort().map((key) => `${JSON.stringify(key)}:${serialize(object[key]!)}`).join(",")}}`;
}

function isAbsoluteHostPath(value: string): boolean {
  return value.startsWith("/") || /^[A-Za-z]:[\\/]/.test(value) || value.startsWith("\\\\");
}
