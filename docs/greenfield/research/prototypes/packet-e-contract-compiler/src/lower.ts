import type { Namespace, Program, Type, Union } from "@typespec/compiler";

import {
  getContractRoot,
  getContractProfile,
  getMatrixDefinitions,
  getOperationDefinition,
  getStableId,
  getWireTag,
} from "./accessors.js";
import type { MatrixCellValue } from "./definition.js";
import type {
  ClosedSum,
  ContractModel,
  MatrixCell,
  OperationContract,
  TotalMatrix,
} from "./model.js";

const sourceTargets = new WeakMap<ContractModel, Map<string, Type>>();

export function lowerContract(program: Program): ContractModel {
  const root = getContractRoot(program) ?? program.getGlobalNamespaceType();
  const profile = getContractProfile(program);
  if (profile === undefined) throw new Error("contract source must explicitly select a semantic profile");
  const targets = new Map<string, Type>();
  const unions = allUnions(program, getStableId);
  const sums = [...unions.entries()]
    .map(([id, union]) => lowerClosedSum(union, id, program, targets))
    .sort(byId);
  const operations: OperationContract[] = [];
  for (const operation of root.operations.values()) {
    const definition = getOperationDefinition(program, operation);
    if (definition === undefined) continue;
    operations.push(Object.freeze({ ...definition }));
    targets.set(`operation:${definition.operationId}`, operation);
  }
  const matrices = getMatrixDefinitions(program).map((matrix) => {
    targets.set(`matrix:${matrix.matrixId}`, root);
    return Object.freeze({
      id: matrix.matrixId,
      rowIds: Object.freeze([...matrix.rowStateIds]),
      columnIds: Object.freeze([...matrix.columnOperationIds]),
      cells: Object.freeze(matrix.cells.map(cellFromValue)),
    });
  });
  const model: ContractModel = Object.freeze({
    contractModelVersion: "0.1.0",
    contractId: "packet-e-vertical-slice",
    semanticProfile: "packet-e-contract-prototype",
    terminalStateIds: Object.freeze([...profile.terminalStateIds]),
    closedSums: Object.freeze(sums),
    operations: Object.freeze(operations.sort(byOperationId)),
    matrices: Object.freeze([...matrices].sort(byId)),
  });
  sourceTargets.set(model, targets);
  return model;
}

export function sourceTargetFor(model: ContractModel, key: string): Type | undefined {
  return sourceTargets.get(model)?.get(key);
}

function allUnions(
  program: Program,
  stableId: (program: Program, target: Type) => string | undefined,
): Map<string, Union> {
  const result = new Map<string, Union>();
  for (const namespace of namespaces(program.getGlobalNamespaceType())) {
    for (const union of namespace.unions.values()) {
      const id = stableId(program, union);
      if (id !== undefined) result.set(id, union);
    }
  }
  return result;
}

function namespaces(root: Namespace): readonly Namespace[] {
  return [root, ...[...root.namespaces.values()].flatMap(namespaces)];
}

function lowerClosedSum(
  union: Union,
  id: string,
  program: Program,
  targets: Map<string, Type>,
): ClosedSum {
  const variants = [...union.variants.values()]
        .map((variant) => {
          const variantId = getStableId(program, variant);
          if (variantId === undefined) return undefined;
          const wireTag = getWireTag(program, variant);
          return Object.freeze(wireTag === undefined ? { id: variantId } : { id: variantId, wireTag });
        })
        .filter((variant): variant is NonNullable<typeof variant> => variant !== undefined)
        .sort(byId);
  targets.set(`sum:${id}`, union);
  return Object.freeze({ id, variants: Object.freeze(variants) });
}

function cellFromValue(cell: MatrixCellValue): MatrixCell {
  const common = { rowId: cell.rowStateId, columnId: cell.columnOperationId };
  switch (cell.kind) {
    case "transition": return Object.freeze({ ...common, kind: cell.kind, nextStateId: cell.nextStateId });
    case "reject": return Object.freeze({ ...common, kind: cell.kind, requestErrorId: cell.requestErrorId });
    case "replay": return Object.freeze({ ...common, kind: cell.kind });
    case "noop": return Object.freeze({ ...common, kind: cell.kind });
  }
}

function byId<T extends { id: string }>(left: T, right: T): number { return left.id.localeCompare(right.id); }
function byOperationId(left: OperationContract, right: OperationContract): number { return left.operationId.localeCompare(right.operationId); }
