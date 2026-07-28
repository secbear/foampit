import "@typespec/compiler";
import "../dist/src/index.js";

using TypeSpec.Reflection;

namespace PacketE.Contract;

alias CallClass =
  | "durableOperationMutation"
  | "existingHandleIntent"
  | "sequencedProcessControl"
  | "observation";

alias ResultBranch = "accepted" | "rejected" | "recovery" | "observed";

alias ResultCarrierKind =
  | "newDurableOperation"
  | "existingOperationObservation"
  | "processControlReceipt"
  | "observation";

alias MatrixCellKind = "transition" | "replay" | "reject" | "noop";

alias RecoveryCoordinateKind =
  | "idempotencyKey"
  | "operationId"
  | "processId"
  | "runtimeEpoch"
  | "sequence"
  | "writerLease";

model RecoveryCoordinate {
  kind: RecoveryCoordinateKind;
  value: string;
}

model OperationResult {
  carrierKind: ResultCarrierKind;
  schemaStableId: string;
}

model ContractProfile {
  profileId: "packet-e-contract-prototype";
  terminalStateIds: string[];
}

model OperationDefinition {
  operationId: string;
  callClass: CallClass;
  resultBranches: ResultBranch[];
  allowedRequestErrors: string[];
  allowedRecoveryErrors: string[];
  allowedKnownFailures: string[];
  allowedAmbiguities: string[];
  recoveryCoordinates: RecoveryCoordinate[];
  matrixIds: string[];
  result: OperationResult;
}

model MatrixCell {
  rowStateId: string;
  columnOperationId: string;
  kind: MatrixCellKind;
  nextStateId: string;
  requestErrorId: string;
}

model MatrixDefinition {
  matrixId: string;
  rowStateIds: string[];
  columnOperationIds: string[];
  cells: MatrixCell[];
}

extern dec contractRoot(target: Namespace);
extern dec contractProfile(
  target: Namespace,
  definition: valueof ContractProfile
);
extern dec stableId(target: unknown, id: valueof string);
extern dec wireTag(target: UnionVariant | ModelProperty, tag: valueof string);
extern dec operationContract(
  target: Operation,
  definition: valueof OperationDefinition
);
extern dec contractMatrix(
  target: Namespace,
  definition: valueof MatrixDefinition
);
