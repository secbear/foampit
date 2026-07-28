import { readFile } from "node:fs/promises";

import {
  ContractDiagnostic,
  decodeOutcome,
  INVALID_OUTCOME,
} from "./dist/contract.js";

const path = process.argv[2];
if (path === undefined) {
  throw new Error("fixture path required");
}

try {
  const value = parseFlatStringObject(await readFile(path, "utf8"));
  const outcome = decodeOutcome(value);
  console.log(`${outcome.operationId}:${outcome.branch}`);
} catch (error) {
  if (
    typeof error === "object" &&
    error !== null &&
    "category" in error &&
    error.category === INVALID_OUTCOME
  ) {
    console.log(INVALID_OUTCOME);
  } else {
    throw error;
  }
}

function parseFlatStringObject(input) {
  let offset = 0;
  const fields = Object.create(null);
  whitespace();
  character("{");
  whitespace();
  if (input[offset] === "}") {
    offset += 1;
  } else {
    while (true) {
      const key = string();
      if (Object.hasOwn(fields, key)) {
        invalidJson();
      }
      whitespace();
      character(":");
      whitespace();
      fields[key] = string();
      whitespace();
      if (input[offset] === ",") {
        offset += 1;
        whitespace();
      } else if (input[offset] === "}") {
        offset += 1;
        break;
      } else {
        invalidJson();
      }
    }
  }
  whitespace();
  if (offset !== input.length) {
    invalidJson();
  }
  return fields;

  function whitespace() {
    while (
      input.charCodeAt(offset) === 0x09 ||
      input.charCodeAt(offset) === 0x0a ||
      input.charCodeAt(offset) === 0x0d ||
      input.charCodeAt(offset) === 0x20
    ) {
      offset += 1;
    }
  }

  function character(expected) {
    if (input[offset] !== expected) {
      invalidJson();
    }
    offset += 1;
  }

  function string() {
    const start = offset;
    character('"');
    let escaped = false;
    while (offset < input.length) {
      const code = input.charCodeAt(offset);
      if (code <= 0x1f) {
        invalidJson();
      }
      offset += 1;
      if (escaped) {
        escaped = false;
      } else if (code === 0x5c) {
        escaped = true;
      } else if (code === 0x22) {
        try {
          return JSON.parse(input.slice(start, offset));
        } catch {
          invalidJson();
        }
      }
    }
    invalidJson();
  }
}

function invalidJson() {
  throw new ContractDiagnostic();
}
