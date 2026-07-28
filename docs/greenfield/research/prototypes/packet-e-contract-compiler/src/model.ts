import type {
  CallClass,
  OperationResult,
  RecoveryCoordinate,
  ResultBranch,
} from "./definition.js";

export type StableId = string;

/** Raw lowering shape; validated ContractModel instances require wireTag. */
export type ClosedVariant = Readonly<{ id: StableId; wireTag?: string }>;
export type ClosedSum = Readonly<{
  id: StableId;
  variants: readonly ClosedVariant[];
}>;

export type MatrixCell =
  | Readonly<{ rowId: StableId; columnId: StableId; kind: "transition"; nextStateId: StableId }>
  | Readonly<{ rowId: StableId; columnId: StableId; kind: "replay" }>
  | Readonly<{ rowId: StableId; columnId: StableId; kind: "reject"; requestErrorId: StableId }>
  | Readonly<{ rowId: StableId; columnId: StableId; kind: "noop" }>;

export type TotalMatrix = Readonly<{
  id: StableId;
  rowIds: readonly StableId[];
  columnIds: readonly StableId[];
  cells: readonly MatrixCell[];
}>;

export type OperationContract = Readonly<{
  operationId: StableId;
  callClass: CallClass;
  resultBranches: readonly ResultBranch[];
  allowedRequestErrors: readonly StableId[];
  allowedRecoveryErrors: readonly StableId[];
  allowedKnownFailures: readonly StableId[];
  allowedAmbiguities: readonly StableId[];
  recoveryCoordinates: readonly RecoveryCoordinate[];
  matrixIds: readonly StableId[];
  result: OperationResult;
}>;

export type WireIdentity = Readonly<{
  containerId: StableId;
  variantId: StableId;
  wireTag: string;
}>;

export type ContractModel = Readonly<{
  contractModelVersion: "0.1.0";
  contractId: "packet-e-vertical-slice";
  semanticProfile: "packet-e-contract-prototype";
  terminalStateIds: readonly StableId[];
  /** Every decorated closed sum in the selected source profile. */
  closedSums: readonly ClosedSum[];
  operations: readonly OperationContract[];
  matrices: readonly TotalMatrix[];
}>;

/** Resolve a required closed sum without storing a second semantic projection. */
export function closedSum(model: ContractModel, id: StableId): ClosedSum {
  const sum = model.closedSums.find((candidate) => candidate.id === id);
  if (sum === undefined) throw new Error(`contract/closed-sum-not-found: ${id}`);
  return sum;
}

/** Derive the portable wire-identity index from the sole serialized source. */
export function wireIdentities(model: ContractModel): readonly WireIdentity[] {
  return Object.freeze(
    model.closedSums
      .flatMap((sum) =>
        sum.variants.flatMap((variant) =>
          variant.wireTag === undefined
            ? []
            : [
                Object.freeze({
                  containerId: sum.id,
                  variantId: variant.id,
                  wireTag: variant.wireTag,
                }),
              ],
        ),
      )
      .sort(compareWireIdentity),
  );
}

function compareWireIdentity(left: WireIdentity, right: WireIdentity): number {
  return (
    left.containerId.localeCompare(right.containerId) ||
    compareWireTag(left.wireTag, right.wireTag) ||
    left.variantId.localeCompare(right.variantId)
  );
}

function compareWireTag(left: string, right: string): number {
  const canonicalDecimal = /^[1-9][0-9]*$/;
  if (canonicalDecimal.test(left) && canonicalDecimal.test(right)) {
    return left.length - right.length || left.localeCompare(right);
  }
  return left.localeCompare(right);
}
