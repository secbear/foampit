export type CallClass =
  | "durableOperationMutation"
  | "existingHandleIntent"
  | "sequencedProcessControl"
  | "observation";

export type ResultBranch = "accepted" | "rejected" | "recovery" | "observed";

export type ResultCarrierKind =
  | "newDurableOperation"
  | "existingOperationObservation"
  | "processControlReceipt"
  | "observation";

export type MatrixCellKind = "transition" | "replay" | "reject" | "noop";

export type RecoveryCoordinateKind =
  | "idempotencyKey"
  | "operationId"
  | "processId"
  | "runtimeEpoch"
  | "sequence"
  | "writerLease";

export type RecoveryCoordinate = Readonly<{
  kind: RecoveryCoordinateKind;
  value: string;
}>;

export type OperationResult = Readonly<{
  carrierKind: ResultCarrierKind;
  schemaStableId: string;
}>;

export type ContractProfileValue = Readonly<{
  profileId: "packet-e-contract-prototype";
  terminalStateIds: readonly string[];
}>;

export function parseContractProfile(value: unknown): ContractProfileValue | undefined {
  const object = asObject(value);
  if (object === undefined || propertyLiteral(object, "profileId", ["packet-e-contract-prototype"]) === undefined) return undefined;
  const terminalStateIds = propertyStrings(object, "terminalStateIds");
  return terminalStateIds === undefined ? undefined : Object.freeze({ profileId: "packet-e-contract-prototype", terminalStateIds: sorted(terminalStateIds) });
}

export type OperationDefinitionValue = Readonly<{
  operationId: string;
  callClass: CallClass;
  resultBranches: readonly ResultBranch[];
  allowedRequestErrors: readonly string[];
  allowedRecoveryErrors: readonly string[];
  allowedKnownFailures: readonly string[];
  allowedAmbiguities: readonly string[];
  recoveryCoordinates: readonly RecoveryCoordinate[];
  matrixIds: readonly string[];
  result: OperationResult;
}>;

export type MatrixCellValue = Readonly<{
  rowStateId: string;
  columnOperationId: string;
  kind: MatrixCellKind;
  nextStateId: string;
  requestErrorId: string;
}>;

export type MatrixDefinitionValue = Readonly<{
  matrixId: string;
  rowStateIds: readonly string[];
  columnOperationIds: readonly string[];
  cells: readonly MatrixCellValue[];
}>;

export function parseOperationDefinition(
  value: unknown,
): OperationDefinitionValue | undefined {
  const object = asObject(value);
  if (object === undefined) {
    return undefined;
  }

  const operationId = propertyString(object, "operationId");
  const callClass = propertyLiteral<CallClass>(object, "callClass", [
    "durableOperationMutation",
    "existingHandleIntent",
    "sequencedProcessControl",
    "observation",
  ]);
  const resultBranches = propertyLiterals<ResultBranch>(object, "resultBranches", [
    "accepted",
    "rejected",
    "recovery",
    "observed",
  ]);
  const allowedRequestErrors = propertyStrings(object, "allowedRequestErrors");
  const allowedRecoveryErrors = propertyStrings(object, "allowedRecoveryErrors");
  const allowedKnownFailures = propertyStrings(object, "allowedKnownFailures");
  const allowedAmbiguities = propertyStrings(object, "allowedAmbiguities");
  const recoveryCoordinates = propertyCoordinates(object, "recoveryCoordinates");
  const matrixIds = propertyStrings(object, "matrixIds");
  const result = propertyResult(object, "result");

  if (
    operationId === undefined ||
    callClass === undefined ||
    resultBranches === undefined ||
    allowedRequestErrors === undefined ||
    allowedRecoveryErrors === undefined ||
    allowedKnownFailures === undefined ||
    allowedAmbiguities === undefined ||
    recoveryCoordinates === undefined ||
    matrixIds === undefined ||
    result === undefined
  ) {
    return undefined;
  }

  return Object.freeze({
    operationId,
    callClass,
    resultBranches: sorted(resultBranches),
    allowedRequestErrors: sorted(allowedRequestErrors),
    allowedRecoveryErrors: sorted(allowedRecoveryErrors),
    allowedKnownFailures: sorted(allowedKnownFailures),
    allowedAmbiguities: sorted(allowedAmbiguities),
    recoveryCoordinates: Object.freeze(
      [...recoveryCoordinates].sort(
        (left, right) =>
          left.kind.localeCompare(right.kind) || left.value.localeCompare(right.value),
      ),
    ),
    matrixIds: sorted(matrixIds),
    result,
  });
}

export function parseMatrixDefinition(
  value: unknown,
): MatrixDefinitionValue | undefined {
  const object = asObject(value);
  if (object === undefined) {
    return undefined;
  }

  const matrixId = propertyString(object, "matrixId");
  const rowStateIds = propertyStrings(object, "rowStateIds");
  const columnOperationIds = propertyStrings(object, "columnOperationIds");
  const cells = propertyCells(object, "cells");
  if (
    matrixId === undefined ||
    rowStateIds === undefined ||
    columnOperationIds === undefined ||
    cells === undefined
  ) {
    return undefined;
  }

  return Object.freeze({
    matrixId,
    rowStateIds: sorted(rowStateIds),
    columnOperationIds: sorted(columnOperationIds),
    cells: Object.freeze(
      [...cells].sort(
        (left, right) =>
          left.rowStateId.localeCompare(right.rowStateId) ||
          left.columnOperationId.localeCompare(right.columnOperationId),
      ),
    ),
  });
}

export function hasWildcardStateCoordinate(matrix: MatrixDefinitionValue): boolean {
  return (
    matrix.rowStateIds.includes("*") ||
    matrix.cells.some(
      (cell) => cell.rowStateId === "*" || cell.nextStateId === "*",
    )
  );
}

function propertyCoordinates(
  object: Record<string, unknown>,
  name: string,
): readonly RecoveryCoordinate[] | undefined {
  const values = propertyArray(object, name);
  if (values === undefined) {
    return undefined;
  }
  const coordinates: RecoveryCoordinate[] = [];
  for (const value of values) {
    const coordinate = asObject(value);
    const kind = coordinate && propertyLiteral<RecoveryCoordinateKind>(coordinate, "kind", [
      "idempotencyKey",
      "operationId",
      "processId",
      "runtimeEpoch",
      "sequence",
      "writerLease",
    ]);
    const coordinateValue = coordinate && propertyString(coordinate, "value");
    if (kind === undefined || coordinateValue === undefined) {
      return undefined;
    }
    coordinates.push(Object.freeze({ kind, value: coordinateValue }));
  }
  return Object.freeze(coordinates);
}

function propertyResult(
  object: Record<string, unknown>,
  name: string,
): OperationResult | undefined {
  const result = asObject(property(object, name));
  if (result === undefined) {
    return undefined;
  }
  const carrierKind = propertyLiteral<ResultCarrierKind>(result, "carrierKind", [
    "newDurableOperation",
    "existingOperationObservation",
    "processControlReceipt",
    "observation",
  ]);
  const schemaStableId = propertyString(result, "schemaStableId");
  return carrierKind === undefined || schemaStableId === undefined
    ? undefined
    : Object.freeze({ carrierKind, schemaStableId });
}

function propertyCells(
  object: Record<string, unknown>,
  name: string,
): readonly MatrixCellValue[] | undefined {
  const values = propertyArray(object, name);
  if (values === undefined) {
    return undefined;
  }
  const cells: MatrixCellValue[] = [];
  for (const value of values) {
    const cell = asObject(value);
    const rowStateId = cell && propertyString(cell, "rowStateId");
    const columnOperationId = cell && propertyString(cell, "columnOperationId");
    const kind = cell && propertyLiteral<MatrixCellKind>(cell, "kind", [
      "transition",
      "replay",
      "reject",
      "noop",
    ]);
    const nextStateId = cell && propertyString(cell, "nextStateId");
    const requestErrorId = cell && propertyString(cell, "requestErrorId");
    if (
      rowStateId === undefined ||
      columnOperationId === undefined ||
      kind === undefined ||
      nextStateId === undefined ||
      requestErrorId === undefined
    ) {
      return undefined;
    }
    cells.push(
      Object.freeze({
        rowStateId,
        columnOperationId,
        kind,
        nextStateId,
        requestErrorId,
      }),
    );
  }
  return Object.freeze(cells);
}

function propertyLiterals<T extends string>(
  object: Record<string, unknown>,
  name: string,
  allowed: readonly T[],
): readonly T[] | undefined {
  const values = propertyArray(object, name);
  if (values === undefined) {
    return undefined;
  }
  const literals: T[] = [];
  for (const value of values) {
    const literal = asLiteral(value, allowed);
    if (literal === undefined) {
      return undefined;
    }
    literals.push(literal);
  }
  return Object.freeze(literals);
}

function propertyLiteral<T extends string>(
  object: Record<string, unknown>,
  name: string,
  allowed: readonly T[],
): T | undefined {
  return asLiteral(property(object, name), allowed);
}

function asLiteral<T extends string>(
  value: unknown,
  allowed: readonly T[],
): T | undefined {
  const string = asString(value);
  return string !== undefined && (allowed as readonly string[]).includes(string)
    ? (string as T)
    : undefined;
}

function propertyStrings(
  object: Record<string, unknown>,
  name: string,
): readonly string[] | undefined {
  const values = propertyArray(object, name);
  if (values === undefined) {
    return undefined;
  }
  const strings: string[] = [];
  for (const value of values) {
    const string = asString(value);
    if (string === undefined) {
      return undefined;
    }
    strings.push(string);
  }
  return Object.freeze(strings);
}

function propertyArray(
  object: Record<string, unknown>,
  name: string,
): readonly unknown[] | undefined {
  const value = property(object, name);
  return Array.isArray(value) ? value : undefined;
}

function propertyString(
  object: Record<string, unknown>,
  name: string,
): string | undefined {
  return asString(property(object, name));
}

function property(object: Record<string, unknown>, name: string): unknown {
  return object[name];
}

function asObject(value: unknown): Record<string, unknown> | undefined {
  return typeof value === "object" && value !== null && !Array.isArray(value)
    ? (value as Record<string, unknown>)
    : undefined;
}

function asString(value: unknown): string | undefined {
  return typeof value === "string" ? value : undefined;
}

function sorted<T extends string>(values: readonly T[]): readonly T[] {
  return Object.freeze([...values].sort((left, right) => left.localeCompare(right)));
}
