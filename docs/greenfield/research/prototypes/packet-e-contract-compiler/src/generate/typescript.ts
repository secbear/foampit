import {
  closedSum,
  type ContractModel,
  type OperationContract,
} from "../model.js";
import {
  compareStrings,
  generatedFile,
  generatedName,
  generatedSymbolTable,
  lowerCamel,
  type GeneratedFile,
  type GeneratedSymbol,
} from "./common.js";

export function generateTypeScript(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  assertNames(model);
  const operations = [...model.operations].sort((left, right) =>
    compareStrings(left.operationId, right.operationId),
  );
  return Object.freeze([
    generatedFile(
      "typescript/contract.ts",
      contractSource(model, operations),
    ),
    generatedFile(
      "typescript/static-construction.test.ts",
      staticConstructionTest(model, operations),
    ),
    generatedFile("typescript/tsconfig.json", tsconfig),
    generatedFile("typescript/run.mjs", runtimeRunner),
  ]);
}

function contractSource(
  model: Readonly<ContractModel>,
  operations: readonly OperationContract[],
): string {
  return `export const INVALID_OUTCOME = "contract/invalid-outcome" as const;

export class ContractDiagnostic extends Error {
  readonly category = INVALID_OUTCOME;

  constructor() {
    super(INVALID_OUTCOME);
    this.name = "ContractDiagnostic";
  }
}

${closedSums(model)}

export type OperationId =
${operations.map((operation) => `  | ${literal(operation.operationId)}`).join("\n")};

${operations.map((operation) => operationTypes(model, operation)).join("\n")}

export type InvocationOutcome =
${operations.map((operation) => `  | ${operationName(operation)}Outcome`).join("\n")};

export interface PacketEService {
${operations
  .map(
    (operation) =>
      `  ${lowerCamel(operationName(operation))}(): Promise<${operationName(operation)}Outcome>;`,
  )
  .join("\n")}
}

${operations.map(operationDecoder).join("\n")}

export function decodeOutcome(value: unknown): InvocationOutcome {
  const object = record(value);
  switch (stringField(object, "operationId")) {
${operations
  .map(
    (operation) =>
      `    case ${literal(operation.operationId)}:
      return decode${operationName(operation)}Outcome(value);`,
  )
  .join("\n")}
    default:
      throw invalid();
  }
}

function record(value: unknown): Readonly<Record<string, unknown>> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw invalid();
  }
  const prototype = Object.getPrototypeOf(value);
  if (prototype !== Object.prototype && prototype !== null) {
    throw invalid();
  }
  return value as Readonly<Record<string, unknown>>;
}

function exactKeys(
  value: Readonly<Record<string, unknown>>,
  expected: readonly string[],
): void {
  const actual = Reflect.ownKeys(value);
  if (actual.length !== expected.length || !expected.every((key) => {
    const descriptor = Object.getOwnPropertyDescriptor(value, key);
    return actual.includes(key) && descriptor?.enumerable === true && descriptor !== undefined && "value" in descriptor;
  })) {
    throw invalid();
  }
}

function stringField(
  value: Readonly<Record<string, unknown>>,
  key: string,
): string {
  const field = value[key];
  if (typeof field !== "string") {
    throw invalid();
  }
  return field;
}

function exactValue(
  value: Readonly<Record<string, unknown>>,
  key: string,
  expected: string,
): void {
  if (stringField(value, key) !== expected) {
    throw invalid();
  }
}

function invalid(): ContractDiagnostic {
  return new ContractDiagnostic();
}
`;
}

function closedSums(model: Readonly<ContractModel>): string {
  return [...model.closedSums]
    .sort((left, right) => compareStrings(left.id, right.id))
    .map((sum) => {
      const variants = [...sum.variants]
        .sort((left, right) => compareStrings(left.id, right.id))
        .map((variant) => {
          if (variant.wireTag === undefined) {
            throw new Error("contract/generated-wire-tag-invalid");
          }
          return `  | Readonly<{ readonly kind: ${literal(variant.id)}; readonly wireTag: ${literal(variant.wireTag)} }>`;
        })
        .join("\n");
      return `export type ${generatedName(sum.id)} =
${variants};
`;
    })
    .join("\n");
}

function operationTypes(
  model: Readonly<ContractModel>,
  operation: OperationContract,
): string {
  const name = operationName(operation);
  const requestRegistry = generatedName(closedSum(model, "registry.request.error").id);
  const recoveryRegistry = generatedName(closedSum(model, "registry.recovery.error").id);
  const failureRegistry = generatedName(closedSum(model, "registry.known.failure").id);
  const ambiguityRegistry = generatedName(closedSum(model, "registry.ambiguity").id);
  const branches = operation.resultBranches
    .map((branch) => {
      const prefix = `  | Readonly<{ readonly operationId: ${literal(operation.operationId)}; readonly branch: ${literal(branch)};`;
      switch (branch) {
        case "accepted":
        case "observed":
          return `${prefix} readonly carrierKind: ${name}Carrier["carrierKind"]; readonly schemaStableId: ${name}Carrier["schemaStableId"] }>`;
        case "rejected":
          return `${prefix} readonly requestErrorId: ${name}RequestError["kind"] }>`;
        case "recovery":
          return `${prefix} readonly recoveryErrorId: ${name}RecoveryError["kind"] }>`;
      }
    })
    .join("\n");
  return `${subsetType(
    `${name}RequestError`,
    requestRegistry,
    operation.allowedRequestErrors,
  )}
${subsetType(
  `${name}RecoveryError`,
  recoveryRegistry,
  operation.allowedRecoveryErrors,
)}
${subsetType(
  `${name}KnownFailure`,
  failureRegistry,
  operation.allowedKnownFailures,
)}
${subsetType(
  `${name}Ambiguity`,
  ambiguityRegistry,
  operation.allowedAmbiguities,
)}
export type ${name}Carrier = Readonly<{
  readonly carrierKind: ${literal(operation.result.carrierKind)};
  readonly schemaStableId: ${literal(operation.result.schemaStableId)};
}>;

export type ${name}Outcome =
${branches};
`;
}

function subsetType(
  name: string,
  registry: string,
  stableIds: readonly string[],
): string {
  if (stableIds.length === 0) {
    return `export type ${name} = never;\n`;
  }
  return `export type ${name} = Extract<
  ${registry},
  Readonly<{ readonly kind: ${[...stableIds]
    .sort(compareStrings)
    .map(literal)
    .join(" | ")} }>
>;\n`;
}

function operationDecoder(operation: OperationContract): string {
  const name = operationName(operation);
  const cases = operation.resultBranches
    .map((branch) => decoderBranch(operation, branch))
    .join("\n");
  return `export function decode${name}Outcome(value: unknown): ${name}Outcome {
  const object = record(value);
  exactValue(object, "operationId", ${literal(operation.operationId)});
  switch (stringField(object, "branch")) {
${cases}
    default:
      throw invalid();
  }
}
`;
}

function decoderBranch(
  operation: OperationContract,
  branch: OperationContract["resultBranches"][number],
): string {
  if (branch === "accepted" || branch === "observed") {
    return `    case ${literal(branch)}:
      exactKeys(object, ["operationId", "branch", "carrierKind", "schemaStableId"]);
      exactValue(object, "carrierKind", ${literal(operation.result.carrierKind)});
      exactValue(object, "schemaStableId", ${literal(operation.result.schemaStableId)});
      return Object.freeze({
        operationId: ${literal(operation.operationId)},
        branch: ${literal(branch)},
        carrierKind: ${literal(operation.result.carrierKind)},
        schemaStableId: ${literal(operation.result.schemaStableId)},
      });`;
  }
  const field =
    branch === "rejected" ? "requestErrorId" : "recoveryErrorId";
  const stableIds =
    branch === "rejected"
      ? operation.allowedRequestErrors
      : operation.allowedRecoveryErrors;
  return `    case ${literal(branch)}: {
      exactKeys(object, ["operationId", "branch", "${field}"]);
      const reason = stringField(object, "${field}");
      switch (reason) {
${stableIds.map((stableId) => `        case ${literal(stableId)}:`).join("\n")}
          return Object.freeze({
            operationId: ${literal(operation.operationId)},
            branch: ${literal(branch)},
            ${field}: reason,
          }) as ${operationName(operation)}Outcome;
        default:
          throw invalid();
      }
    }`;
}

function staticConstructionTest(
  model: Readonly<ContractModel>,
  operations: readonly OperationContract[],
): string {
  const imports = operations
    .map((operation) => `${operationName(operation)}Outcome`)
    .join(",\n  ");
  const valid = operations
    .map((operation) => {
      const branch = operation.resultBranches.includes("accepted")
        ? "accepted"
        : "observed";
      return `const valid${operationName(operation)}: ${operationName(operation)}Outcome = ${carrierExpression(operation, branch)};`;
    })
    .join("\n");
  const invalid = operations
    .map((operation) => {
      const expression = invalidStaticExpression(model, operation);
      return `// @ts-expect-error invalid ${operation.operationId} construction
const invalid${operationName(operation)}: ${operationName(operation)}Outcome = ${expression};`;
    })
    .join("\n");
  return `import type {
  ${imports},
} from "./contract.js";

${valid}

${invalid}

void [
${operations
  .map((operation) => `  valid${operationName(operation)},`)
  .join("\n")}
];
`;
}

function invalidStaticExpression(
  model: Readonly<ContractModel>,
  operation: OperationContract,
): string {
  if (operation.callClass === "observation") {
    return carrierExpression(operation, "accepted");
  }
  if (operation.callClass === "sequencedProcessControl") {
    const other = model.operations.find(
      (candidate) =>
        candidate.result.carrierKind !== operation.result.carrierKind,
    );
    if (other === undefined) {
      throw new Error("contract/generated-static-test-unavailable");
    }
    return `{ operationId: ${literal(operation.operationId)}, branch: "accepted", carrierKind: ${literal(other.result.carrierKind)}, schemaStableId: ${literal(operation.result.schemaStableId)} }`;
  }
  if (operation.callClass === "existingHandleIntent") {
    return carrierExpression(operation, "observed");
  }
  const disallowed = closedSum(model, "registry.request.error").variants.find(
    (variant) => !operation.allowedRequestErrors.includes(variant.id),
  );
  if (disallowed === undefined) {
    throw new Error("contract/generated-static-test-unavailable");
  }
  return `{ operationId: ${literal(operation.operationId)}, branch: "rejected", requestErrorId: ${literal(disallowed.id)} }`;
}

function carrierExpression(
  operation: OperationContract,
  branch: string,
): string {
  return `{ operationId: ${literal(operation.operationId)}, branch: ${literal(branch)}, carrierKind: ${literal(operation.result.carrierKind)}, schemaStableId: ${literal(operation.result.schemaStableId)} }`;
}

const tsconfig = `${JSON.stringify(
  {
    compilerOptions: {
      strict: true,
      target: "ES2024",
      module: "NodeNext",
      moduleResolution: "NodeNext",
      rootDir: ".",
      outDir: "dist",
      noEmitOnError: true,
      exactOptionalPropertyTypes: true,
    },
    include: ["contract.ts", "static-construction.test.ts"],
  },
  undefined,
  2,
)}\n`;

const runtimeRunner = `import { readFile } from "node:fs/promises";

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
  console.log(\`\${outcome.operationId}:\${outcome.branch}\`);
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
`;

function operationName(operation: OperationContract): string {
  const prefix = "operation.";
  if (!operation.operationId.startsWith(prefix)) {
    throw new Error("contract/generated-name-invalid");
  }
  return generatedName(operation.operationId.slice(prefix.length));
}

function assertNames(model: Readonly<ContractModel>): void {
  const typeSymbols: GeneratedSymbol[] = [
    typescriptSymbol("fixed:type:ContractDiagnostic", "ContractDiagnostic"),
    typescriptSymbol("fixed:type:OperationId", "OperationId"),
    typescriptSymbol("fixed:type:InvocationOutcome", "InvocationOutcome"),
    typescriptSymbol("fixed:type:PacketEService", "PacketEService"),
    typescriptSymbol("global:type:Extract", "Extract"),
    typescriptSymbol("global:type:Promise", "Promise"),
    typescriptSymbol("global:type:Readonly", "Readonly"),
    typescriptSymbol("global:type:Record", "Record"),
  ];
  const valueSymbols: GeneratedSymbol[] = [
    typescriptSymbol("fixed:value:INVALID_OUTCOME", "INVALID_OUTCOME"),
    typescriptSymbol("fixed:value:ContractDiagnostic", "ContractDiagnostic"),
    typescriptSymbol("fixed:value:decodeOutcome", "decodeOutcome"),
    typescriptSymbol("fixed:value:record", "record"),
    typescriptSymbol("fixed:value:exactKeys", "exactKeys"),
    typescriptSymbol("fixed:value:stringField", "stringField"),
    typescriptSymbol("fixed:value:exactValue", "exactValue"),
    typescriptSymbol("fixed:value:invalid", "invalid"),
  ];
  const serviceMethods: GeneratedSymbol[] = [];
  const staticTestValues: GeneratedSymbol[] = [];

  for (const sum of model.closedSums) {
    typeSymbols.push(
      typescriptSymbol(`closed-sum:${sum.id}`, generatedName(sum.id)),
    );
  }

  for (const operation of model.operations) {
    const name = operationName(operation);
    const source = `operation:${operation.operationId}`;
    for (const suffix of [
      "RequestError",
      "RecoveryError",
      "KnownFailure",
      "Ambiguity",
      "Carrier",
      "Outcome",
    ]) {
      typeSymbols.push(
        typescriptSymbol(`${source}:type:${suffix}`, `${name}${suffix}`),
      );
    }
    valueSymbols.push(
      typescriptSymbol(`${source}:decoder`, `decode${name}Outcome`),
    );
    serviceMethods.push(
      typescriptServiceMethod(source, lowerCamel(name)),
    );
    staticTestValues.push(
      typescriptSymbol(`${source}:valid-fixture`, `valid${name}`),
      typescriptSymbol(`${source}:invalid-fixture`, `invalid${name}`),
    );
  }

  generatedSymbolTable(typeSymbols);
  generatedSymbolTable(valueSymbols);
  generatedSymbolTable(serviceMethods);
  generatedSymbolTable(staticTestValues);
}

function typescriptSymbol(source: string, name: string): GeneratedSymbol {
  if (!/^[A-Za-z_$][A-Za-z0-9_$]*$/.test(name)) {
    throw new Error("contract/generated-name-invalid");
  }
  return Object.freeze({ source, name });
}

function typescriptServiceMethod(
  source: string,
  name: string,
): GeneratedSymbol {
  if (name === "new") {
    throw new Error("contract/generated-name-invalid");
  }
  return typescriptSymbol(source, name);
}

function literal(value: string): string {
  return JSON.stringify(value);
}
