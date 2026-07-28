import type {
  ContractModel,
  MatrixCell,
  OperationContract,
} from "../model.js";
import {
  compareStrings,
  generatedFile,
  type GeneratedFile,
} from "./common.js";

const fixedNames = {
  contractModelVersion: "contractModelVersion",
  contractId: "contractId",
  semanticProfile: "semanticProfile",
  terminalStateIds: "terminalStateIds",
} as const;
const sumSuffixes = {
  wireIdentities: "WireIdentities",
} as const;
const operationSuffixes = {
  callClass: "CallClass",
  resultBranches: "ResultBranches",
  allowedRequestErrors: "AllowedRequestErrors",
  allowedRecoveryErrors: "AllowedRecoveryErrors",
  allowedKnownFailures: "AllowedKnownFailures",
  allowedAmbiguities: "AllowedAmbiguities",
  recoveryCoordinates: "RecoveryCoordinates",
  matrixIds: "MatrixIds",
  resultCarrierKind: "ResultCarrierKind",
  resultSchemaStableId: "ResultSchemaStableId",
} as const;
const matrixSuffixes = {
  rows: "Rows",
  columns: "Columns",
  cells: "Cells",
} as const;
const quintReservedNames = new Set([
  "module",
  "const",
  "var",
  "assume",
  "val",
  "pure",
  "type",
  "def",
  "action",
  "run",
  "temporal",
  "nondet",
  "int",
  "str",
  "bool",
  "all",
  "any",
  "if",
  "else",
  "and",
  "or",
  "iff",
  "implies",
  "leadsTo",
  "match",
  "import",
  "export",
  "true",
  "false",
]);

export function generateQuint(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  preflightQuintSymbols(model);
  const sections = [
    pureString(fixedNames.contractModelVersion, model.contractModelVersion),
    pureString(fixedNames.contractId, model.contractId),
    pureString(fixedNames.semanticProfile, model.semanticProfile),
    pureStringSet(fixedNames.terminalStateIds, model.terminalStateIds),
    ...[...model.closedSums]
      .sort((left, right) => compareStrings(left.id, right.id))
      .flatMap((sum) => {
        const name = quintName(sum.id);
        return [
          pureStringSet(
            name,
            sum.variants.map((variant) => variant.id),
          ),
          ...[...sum.variants]
            .sort((left, right) => compareStrings(left.id, right.id))
            .map((variant) => pureString(quintName(variant.id), variant.id)),
          pureStringSet(
            `${name}${sumSuffixes.wireIdentities}`,
            sum.variants.map((variant) => {
              if (variant.wireTag === undefined) {
                throw new Error("contract/generated-wire-tag-invalid");
              }
              return `${variant.id}|${variant.wireTag}`;
            }),
          ),
        ];
      }),
    ...[...model.operations]
      .sort((left, right) =>
        compareStrings(left.operationId, right.operationId),
      )
      .flatMap(operationConstants),
    ...[...model.matrices]
      .sort((left, right) => compareStrings(left.id, right.id))
      .flatMap((matrix) => {
        const name = quintName(matrix.id);
        return [
          pureString(name, matrix.id),
          pureStringSet(`${name}${matrixSuffixes.rows}`, matrix.rowIds),
          pureStringSet(
            `${name}${matrixSuffixes.columns}`,
            matrix.columnIds,
          ),
          pureStringSet(
            `${name}${matrixSuffixes.cells}`,
            matrix.cells.map(matrixCell),
          ),
        ];
      }),
  ];
  const source = `module PacketEContract {
${sections.map((section) => `  ${section}`).join("\n")}
}
`;
  return Object.freeze([generatedFile("quint/contract.qnt", source)]);
}

function operationConstants(operation: OperationContract): readonly string[] {
  const name = quintName(operation.operationId);
  return [
    pureString(name, operation.operationId),
    pureString(`${name}${operationSuffixes.callClass}`, operation.callClass),
    pureStringSet(
      `${name}${operationSuffixes.resultBranches}`,
      operation.resultBranches,
    ),
    pureStringSet(
      `${name}${operationSuffixes.allowedRequestErrors}`,
      operation.allowedRequestErrors,
    ),
    pureStringSet(
      `${name}${operationSuffixes.allowedRecoveryErrors}`,
      operation.allowedRecoveryErrors,
    ),
    pureStringSet(
      `${name}${operationSuffixes.allowedKnownFailures}`,
      operation.allowedKnownFailures,
    ),
    pureStringSet(
      `${name}${operationSuffixes.allowedAmbiguities}`,
      operation.allowedAmbiguities,
    ),
    pureStringSet(
      `${name}${operationSuffixes.recoveryCoordinates}`,
      operation.recoveryCoordinates.map(
        (coordinate) => `${coordinate.kind}|${coordinate.value}`,
      ),
    ),
    pureStringSet(
      `${name}${operationSuffixes.matrixIds}`,
      operation.matrixIds,
    ),
    pureString(
      `${name}${operationSuffixes.resultCarrierKind}`,
      operation.result.carrierKind,
    ),
    pureString(
      `${name}${operationSuffixes.resultSchemaStableId}`,
      operation.result.schemaStableId,
    ),
  ];
}

function preflightQuintSymbols(model: Readonly<ContractModel>): void {
  const symbols: Array<Readonly<{ source: string; name: string }>> =
    Object.entries(fixedNames).map(([source, name]) => ({
      source: `fixed:${source}`,
      name,
    }));
  for (const sum of model.closedSums) {
    const name = quintName(sum.id);
    symbols.push(
      { source: `sum:${sum.id}`, name },
      {
        source: `sum:${sum.id}:wire-identities`,
        name: `${name}${sumSuffixes.wireIdentities}`,
      },
    );
    for (const variant of sum.variants) {
      symbols.push({
        source: `variant:${sum.id}:${variant.id}`,
        name: quintName(variant.id),
      });
    }
  }
  for (const operation of model.operations) {
    const name = quintName(operation.operationId);
    symbols.push({ source: `operation:${operation.operationId}`, name });
    for (const [suffixSource, suffix] of Object.entries(operationSuffixes)) {
      symbols.push({
        source: `operation:${operation.operationId}:${suffixSource}`,
        name: `${name}${suffix}`,
      });
    }
  }
  for (const matrix of model.matrices) {
    const name = quintName(matrix.id);
    symbols.push({ source: `matrix:${matrix.id}`, name });
    for (const [suffixSource, suffix] of Object.entries(matrixSuffixes)) {
      symbols.push({
        source: `matrix:${matrix.id}:${suffixSource}`,
        name: `${name}${suffix}`,
      });
    }
  }

  const names = new Set<string>();
  for (const symbol of symbols) {
    if (quintReservedNames.has(symbol.name)) {
      throw new Error("contract/generated-name-invalid");
    }
    if (names.has(symbol.name)) {
      throw new Error("contract/generated-name-collision");
    }
    names.add(symbol.name);
  }
}

function matrixCell(cell: MatrixCell): string {
  const common = `${cell.rowId}|${cell.columnId}|${cell.kind}`;
  switch (cell.kind) {
    case "transition":
      return `${common}|nextStateId=${cell.nextStateId}`;
    case "reject":
      return `${common}|requestErrorId=${cell.requestErrorId}`;
    case "replay":
    case "noop":
      return common;
  }
}

function pureString(name: string, value: string): string {
  return `pure val ${name} = ${literal(value)}`;
}

function pureStringSet(name: string, values: readonly string[]): string {
  return `pure val ${name}: Set[str] = Set(${[...values]
    .sort(compareStrings)
    .map(literal)
    .join(", ")})`;
}

function quintName(stableId: string): string {
  if (!/^[a-z][a-z0-9]*(?:[.-][a-z0-9]+)*$/.test(stableId)) {
    throw new Error("contract/generated-name-invalid");
  }
  const [first, ...rest] = stableId.split(/[.-]/);
  return `${first}${rest
    .map((part) => part.slice(0, 1).toUpperCase() + part.slice(1))
    .join("")}`;
}

function literal(value: string): string {
  return JSON.stringify(value);
}
