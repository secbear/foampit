import type { Type } from "@typespec/compiler";

import { sourceTargetFor } from "./lower.js";
import type { ContractModel, MatrixCell, OperationContract } from "./model.js";
import { isPortableWireTag } from "./wire-tag.js";

export type ContractDiagnostic = Readonly<{ code: string; target?: Type }>;

const expectedOperations: Readonly<Record<string, OperationContract>> = {
  "operation.cancel.operation": {
    operationId: "operation.cancel.operation",
    callClass: "existingHandleIntent",
    resultBranches: ["accepted", "recovery", "rejected"],
    allowedRequestErrors: ["request.invalid.state"],
    allowedRecoveryErrors: ["recovery.idempotency.expired"],
    allowedKnownFailures: [],
    allowedAmbiguities: ["ambiguity.runtime.unknown"],
    recoveryCoordinates: [
      { kind: "operationId", value: "existing.operation.id" },
    ],
    matrixIds: ["matrix.sandbox-operation"],
    result: {
      carrierKind: "existingOperationObservation",
      schemaStableId: "result.existing.operation.observation",
    },
  },
  "operation.start.sandbox": {
    operationId: "operation.start.sandbox",
    callClass: "durableOperationMutation",
    resultBranches: ["accepted", "recovery", "rejected"],
    allowedRequestErrors: ["request.invalid.state"],
    allowedRecoveryErrors: ["recovery.idempotency.expired"],
    allowedKnownFailures: ["failure.runtime.provisioning"],
    allowedAmbiguities: ["ambiguity.runtime.unknown"],
    recoveryCoordinates: [
      { kind: "idempotencyKey", value: "start.idempotency-key" },
      { kind: "runtimeEpoch", value: "sandbox.runtime.epoch" },
    ],
    matrixIds: ["matrix.sandbox-operation"],
    result: {
      carrierKind: "newDurableOperation",
      schemaStableId: "result.operation.start.sandbox",
    },
  },
  "operation.wait.operation": {
    operationId: "operation.wait.operation",
    callClass: "observation",
    resultBranches: ["observed", "rejected"],
    allowedRequestErrors: ["request.invalid.state"],
    allowedRecoveryErrors: [],
    allowedKnownFailures: [],
    allowedAmbiguities: [],
    recoveryCoordinates: [],
    matrixIds: ["matrix.sandbox-operation"],
    result: {
      carrierKind: "observation",
      schemaStableId: "result.operation.wait.observation",
    },
  },
  "operation.write.process.input": {
    operationId: "operation.write.process.input",
    callClass: "sequencedProcessControl",
    resultBranches: ["accepted", "recovery", "rejected"],
    allowedRequestErrors: [
      "request.invalid.state",
      "request.sequence.out.of.range",
    ],
    allowedRecoveryErrors: ["recovery.idempotency.expired"],
    allowedKnownFailures: [],
    allowedAmbiguities: ["ambiguity.runtime.unknown"],
    recoveryCoordinates: [
      { kind: "processId", value: "process.id" },
      { kind: "runtimeEpoch", value: "sandbox.runtime.epoch" },
      { kind: "sequence", value: "process.input.sequence" },
      { kind: "writerLease", value: "process.writer.lease" },
    ],
    matrixIds: ["matrix.sandbox-operation"],
    result: {
      carrierKind: "processControlReceipt",
      schemaStableId: "result.process.control.receipt",
    },
  },
};

const expectedUniverse: Readonly<Record<string, readonly string[]>> = {
  "state.operation": ["state.operation.accepted", "state.operation.running", "state.operation.cancel.requested", "state.operation.succeeded", "state.operation.failed", "state.operation.cancelled", "state.operation.unknown"],
  "state.process": ["state.process.accepted", "state.process.starting", "state.process.running", "state.process.unknown", "state.process.terminated"],
  "state.sandbox": ["state.sandbox.stopped", "state.sandbox.provisioning", "state.sandbox.running", "state.sandbox.unknown"],
  "registry.request.error": ["request.invalid.state", "request.sequence.out.of.range"],
  "registry.recovery.error": ["recovery.idempotency.expired"],
  "registry.known.failure": ["failure.runtime.provisioning"],
  "registry.ambiguity": ["ambiguity.runtime.unknown"],
  "registry.operation.outcome": ["outcome.accepted", "outcome.rejected", "outcome.recovery", "outcome.observed"],
  "registry.process.control.outcome": ["outcome.process.accepted", "outcome.process.rejected", "outcome.process.recovery"],
  "registry.process.termination": ["process.termination.exited", "process.termination.signalled"],
  "registry.caller.recovery": ["caller.recovery.retry"],
  "registry.core.resolution": ["core.resolution.reconcile"],
  "registry.transport.error": ["transport.error.unavailable"],
  "registry.provider.evidence": ["provider.evidence.observed"],
};
const expectedOperationIds = Object.keys(expectedOperations).sort();
const expectedMatrixIds = ["matrix.sandbox-operation"];
const expectedMatrixAxes: Readonly<Record<string, Readonly<{
  rows: readonly string[];
  columns: readonly string[];
}>>> = {
  "matrix.sandbox-operation": {
    rows: [
      "state.sandbox.provisioning",
      "state.sandbox.running",
      "state.sandbox.stopped",
      "state.sandbox.unknown",
    ],
    columns: expectedOperationIds,
  },
};
const expectedTerminalStateIds = [
  "state.operation.cancelled",
  "state.operation.failed",
  "state.operation.succeeded",
  "state.operation.unknown",
  "state.process.terminated",
];

export function validateContract(model: ContractModel): readonly ContractDiagnostic[] {
  if (model.contractModelVersion !== "0.1.0"
    || model.contractId !== "packet-e-vertical-slice"
    || model.semanticProfile !== "packet-e-contract-prototype") {
    return [diagnostic("contract/invalid-contract-identity", undefined)];
  }
  if (!same(model.operations.map((operation) => operation.operationId), expectedOperationIds)
    || !same(model.matrices.map((matrix) => matrix.id), expectedMatrixIds)
    || !same(model.terminalStateIds, expectedTerminalStateIds)
    || !same(model.closedSums.map((sum) => sum.id), Object.keys(expectedUniverse).sort())
    || model.closedSums.some((sum) => !same(sum.variants.map((variant) => variant.id), [...(expectedUniverse[sum.id] ?? [])].sort()))) {
    return [diagnostic("contract/invalid-contract-universe", undefined)];
  }
  for (const matrix of model.matrices) {
    const target = sourceTargetFor(model, `matrix:${matrix.id}`);
    if (matrix.rowIds.includes("*") || matrix.cells.some((cell) => "nextStateId" in cell && cell.nextStateId === "*")) return [diagnostic("contract/wildcard-cell-forbidden", target)];
    if (matrix.cells.some((cell) => cell.kind === "transition" && model.terminalStateIds.includes(cell.rowId))) return [diagnostic("contract/terminal-state-transition", target)];
    if (hasDuplicates(matrix.rowIds) || hasDuplicates(matrix.columnIds)) return [diagnostic("contract/duplicate-matrix-axis", target)];
    const required = cartesian(matrix.rowIds, matrix.columnIds);
    const actualKeys = matrix.cells.map(cellKey);
    const actual = new Set(actualKeys);
    if (actual.size !== actualKeys.length) return [diagnostic("contract/duplicate-matrix-cell", target)];
    if (![...required].every((key) => actual.has(key))) return [diagnostic("contract/incomplete-matrix", target)];
    if ([...actual].some((key) => !required.has(key))) return [diagnostic("contract/extra-matrix-cell", target)];
    if (matrix.cells.some((cell) => cell.kind === "transition" && !matrix.rowIds.includes(cell.nextStateId))) return [diagnostic("contract/unreachable-transition", target)];
    if (!isCanonicalUnique(matrix.rowIds)
      || !isCanonicalUnique(matrix.columnIds)
      || !isCanonicalUnique(actualKeys)) {
      return [diagnostic("contract/noncanonical-contract-collection", target)];
    }
    const expectedAxes = expectedMatrixAxes[matrix.id];
    if (expectedAxes === undefined
      || !same(matrix.rowIds, expectedAxes.rows)
      || !same(matrix.columnIds, expectedAxes.columns)) {
      return [diagnostic("contract/matrix-axis-mismatch", target)];
    }
  }
  for (const operation of model.operations) {
    const target = sourceTargetFor(model, `operation:${operation.operationId}`);
    const branches = new Set(operation.resultBranches);
    if (branches.size !== operation.resultBranches.length) return [diagnostic("contract/duplicate-result-branch", target)];
    if (operation.callClass === "observation" && (!branches.has("observed") || branches.has("accepted"))) return [diagnostic("contract/conflicting-result-branch", target)];
    if (operation.callClass !== "observation" && (!branches.has("accepted") || branches.has("observed"))) return [diagnostic("contract/contradictory-outcome", target)];
    if ((operation.allowedRequestErrors.length > 0) !== branches.has("rejected") || (operation.allowedRecoveryErrors.length > 0) !== branches.has("recovery")) return [diagnostic("contract/error-result-branch-mismatch", target)];
    if (branches.has("accepted") && branches.has("observed")) return [diagnostic(operation.callClass === "observation" ? "contract/conflicting-result-branch" : "contract/contradictory-outcome", target)];
    if (operation.callClass !== "observation" && branches.has("recovery") && operation.recoveryCoordinates.length === 0) return [diagnostic("contract/missing-recovery-coordinate", target)];
    const expected = expectedOperations[operation.operationId];
    if (expected !== undefined && !sameMembers(operation.allowedRequestErrors, expected.allowedRequestErrors)
      || expected !== undefined && !sameMembers(operation.allowedRecoveryErrors, expected.allowedRecoveryErrors)
      || expected !== undefined && !sameMembers(operation.allowedKnownFailures, expected.allowedKnownFailures)
      || expected !== undefined && !sameMembers(operation.allowedAmbiguities, expected.allowedAmbiguities)) {
      return [diagnostic("contract/inadmissible-error", target)];
    }
    if (!operationCollectionsCanonical(operation)) {
      return [diagnostic("contract/noncanonical-contract-collection", target)];
    }
    if (expected === undefined || !sameOperation(operation, expected)) {
      return [diagnostic("contract/operation-contract-mismatch", target)];
    }
  }
  for (const sum of model.closedSums) {
    const identities = new Set<string>();
    if (sum.variants.some((variant) => variant.wireTag === undefined)) {
      return [diagnostic("contract/missing-wire-tag", sourceTargetFor(model, `sum:${sum.id}`))];
    }
    if (sum.variants.some((variant) => variant.wireTag !== undefined && !isPortableWireTag(variant.wireTag))) {
      return [diagnostic("contract/invalid-wire-tag", sourceTargetFor(model, `sum:${sum.id}`))];
    }
    for (const variant of sum.variants) {
      if (variant.wireTag === undefined) continue;
      if (identities.has(variant.wireTag)) {
        return [
          diagnostic("contract/duplicate-wire-identity", sourceTargetFor(model, `sum:${sum.id}`)),
        ];
      }
      identities.add(variant.wireTag);
    }
  }
  return [];
}

export class ContractModelValidationError extends Error {
  constructor(readonly diagnostics: readonly ContractDiagnostic[]) {
    super(`contract/invalid-contract-model: ${diagnostics.map((diagnostic) => diagnostic.code).join(",")}`);
    this.name = "ContractModelValidationError";
  }
}

export function assertValidContractModel(model: Readonly<ContractModel>): void {
  const diagnostics = validateContract(model);
  if (diagnostics.length > 0) throw new ContractModelValidationError(diagnostics);
}

function diagnostic(code: string, target: Type | undefined): ContractDiagnostic { return Object.freeze({ code, target }); }
function cartesian(rows: readonly string[], columns: readonly string[]): Set<string> { return new Set(rows.flatMap((row) => columns.map((column) => `${row}\0${column}`))); }
function cellKey(cell: MatrixCell): string { return `${cell.rowId}\0${cell.columnId}`; }
function coordinateKey(coordinate: OperationContract["recoveryCoordinates"][number]): string { return `${coordinate.kind}\0${coordinate.value}`; }
function hasDuplicates(values: readonly string[]): boolean { return new Set(values).size !== values.length; }
function isCanonicalUnique(values: readonly string[]): boolean { return same(values, [...new Set(values)].sort()); }
function operationCollectionsCanonical(operation: OperationContract): boolean {
  return isCanonicalUnique(operation.resultBranches)
    && isCanonicalUnique(operation.allowedRequestErrors)
    && isCanonicalUnique(operation.allowedRecoveryErrors)
    && isCanonicalUnique(operation.allowedKnownFailures)
    && isCanonicalUnique(operation.allowedAmbiguities)
    && isCanonicalUnique(operation.recoveryCoordinates.map(coordinateKey))
    && isCanonicalUnique(operation.matrixIds);
}
function sameMembers(actual: readonly string[], expected: readonly string[]): boolean {
  const actualSet = new Set(actual);
  return actualSet.size === expected.length && expected.every((value) => actualSet.has(value));
}
function sameOperation(actual: OperationContract, expected: OperationContract): boolean {
  return actual.operationId === expected.operationId
    && actual.callClass === expected.callClass
    && same(actual.resultBranches, expected.resultBranches)
    && same(actual.allowedRequestErrors, expected.allowedRequestErrors)
    && same(actual.allowedRecoveryErrors, expected.allowedRecoveryErrors)
    && same(actual.allowedKnownFailures, expected.allowedKnownFailures)
    && same(actual.allowedAmbiguities, expected.allowedAmbiguities)
    && same(actual.recoveryCoordinates.map(coordinateKey), expected.recoveryCoordinates.map(coordinateKey))
    && same(actual.matrixIds, expected.matrixIds)
    && actual.result.carrierKind === expected.result.carrierKind
    && actual.result.schemaStableId === expected.result.schemaStableId;
}
function same(actual: readonly string[], expected: readonly string[]): boolean { return actual.length === expected.length && actual.every((value, index) => value === expected[index]); }
