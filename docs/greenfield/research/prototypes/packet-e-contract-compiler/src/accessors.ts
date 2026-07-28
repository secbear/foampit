import type {
  Namespace,
  Operation,
  Program,
  Type,
  UnionVariant,
  ModelProperty,
} from "@typespec/compiler";

import { $lib } from "./lib.js";
import type {
  MatrixDefinitionValue,
  OperationDefinitionValue,
  ContractProfileValue,
} from "./definition.js";

export function getContractRoot(program: Program): Namespace | undefined {
  const roots = program.stateSet($lib.stateKeys.contractRoots);
  return roots.size === 1
    ? (roots.values().next().value as Namespace)
    : undefined;
}

export function getStableId(program: Program, target: Type): string | undefined {
  return program.stateMap($lib.stateKeys.stableIds).get(target);
}

export function getWireTag(
  program: Program,
  target: UnionVariant | ModelProperty,
): string | undefined {
  return program.stateMap($lib.stateKeys.wireTags).get(target);
}

export function getOperationDefinition(
  program: Program,
  operation: Operation,
): OperationDefinitionValue | undefined {
  return program.stateMap($lib.stateKeys.operationDefinitions).get(operation);
}

export function getMatrixDefinitions(
  program: Program,
): readonly MatrixDefinitionValue[] {
  const root = getContractRoot(program);
  if (root === undefined) {
    return [];
  }
  const definitions =
    program.stateMap($lib.stateKeys.matrixDefinitions).get(root) ?? [];
  return Object.freeze(
    [...definitions].sort((left, right) =>
      left.matrixId.localeCompare(right.matrixId),
    ),
  );
}

export function getContractProfile(program: Program): ContractProfileValue | undefined {
  const root = getContractRoot(program);
  return root === undefined ? undefined : program.stateMap($lib.stateKeys.contractProfiles).get(root);
}
