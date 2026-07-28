export {
  getContractRoot,
  getContractProfile,
  getMatrixDefinitions,
  getOperationDefinition,
  getStableId,
  getWireTag,
} from "./accessors.js";
export type {
  CallClass,
  ContractProfileValue,
  MatrixCellKind,
  MatrixDefinitionValue,
  OperationDefinitionValue,
  OperationResult,
  RecoveryCoordinate,
  RecoveryCoordinateKind,
  ResultCarrierKind,
  ResultBranch,
} from "./definition.js";
export { $lib } from "./lib.js";
export { $onValidate } from "./decorators.js";
export { canonicalizeSemanticJson, semanticDigest } from "./canonical.js";
export { $onEmit, buildContractBundle, buildSourceMap } from "./emitter.js";
export type { ContractBundle, ContractSourceMap, EmitterOptions } from "./emitter.js";
export { closedSum, wireIdentities } from "./model.js";
export type {
  ClosedSum,
  ClosedVariant,
  ContractModel,
  MatrixCell,
  OperationContract,
  StableId,
  TotalMatrix,
  WireIdentity,
} from "./model.js";
export { assertValidContractModel, validateContract, ContractModelValidationError } from "./validate.js";
export { isPortableWireTag } from "./wire-tag.js";

import {
  $contractRoot,
  $contractProfile,
  $contractMatrix,
  $operationContract,
  $stableId,
  $wireTag,
} from "./decorators.js";

export const $decorators = {
  "PacketE.Contract": {
    contractRoot: $contractRoot,
    contractProfile: $contractProfile,
    contractMatrix: $contractMatrix,
    operationContract: $operationContract,
    stableId: $stableId,
    wireTag: $wireTag,
  },
};
