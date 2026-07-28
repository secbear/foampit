import type {
  ClosedSum,
  ContractModel,
  OperationContract,
  TotalMatrix,
} from "../model.js";
import { generatedFile, type GeneratedFile } from "./common.js";

export function generateCue(
  model: Readonly<ContractModel>,
): readonly GeneratedFile[] {
  const stateIds = model.closedSums
    .filter((sum) => sum.id.startsWith("state."))
    .flatMap((sum) => sum.variants.map((variant) => variant.id));
  const requestErrorIds = variantIds(model, "registry.request.error");
  const recoveryErrorIds = variantIds(model, "registry.recovery.error");
  const knownFailureIds = variantIds(model, "registry.known.failure");
  const ambiguityIds = variantIds(model, "registry.ambiguity");
  const matrixIds = model.matrices.map((matrix) => matrix.id);
  const operationIds = model.operations.map(
    (operation) => operation.operationId,
  );

  const source = `package contract

import "list"

#ClosedVariant: close({
	id: string
	wireTag: =~"^[1-9][0-9]*$"
	#wireTagSelected: _
})

#ClosedSum: close({
	id: string
	variants: [...#ClosedVariant]
	#variantIdsUnique: true & list.UniqueItems([
		for variant in variants {variant.id}
	])
	#wireTagsUnique: true & list.UniqueItems([
		for variant in variants {variant.wireTag}
	])
})

#RecoveryCoordinate: close({
	kind: "idempotencyKey" | "operationId" | "processId" | "runtimeEpoch" | "sequence" | "writerLease"
	value: string
})

#OperationResult: close({
	carrierKind: "newDurableOperation" | "existingOperationObservation" | "processControlReceipt" | "observation"
	schemaStableId: string
})

#Operation: close({
	operationId: string
	callClass: "durableOperationMutation" | "existingHandleIntent" | "sequencedProcessControl" | "observation"
	resultBranches: [...("accepted" | "rejected" | "recovery" | "observed")]
	allowedRequestErrors: [...string]
	allowedRecoveryErrors: [...string]
	allowedKnownFailures: [...string]
	allowedAmbiguities: [...string]
	recoveryCoordinates: [...#RecoveryCoordinate]
	matrixIds: [...string]
	result: #OperationResult

	#resultBranchesUnique: true & list.UniqueItems(resultBranches)
	#requestErrorsUnique: true & list.UniqueItems(allowedRequestErrors)
	#recoveryErrorsUnique: true & list.UniqueItems(allowedRecoveryErrors)
	#knownFailuresUnique: true & list.UniqueItems(allowedKnownFailures)
	#ambiguitiesUnique: true & list.UniqueItems(allowedAmbiguities)
	#matrixReferencesUnique: true & list.UniqueItems(matrixIds)
	#recoveryCoordinatesUnique: true & list.UniqueItems([
		for coordinate in recoveryCoordinates {
			"\\(coordinate.kind)|\\(coordinate.value)"
		}
	])
	#waitOperationObservation: true & (
		operationId != "operation.wait.operation" || callClass == "observation")

	#observationBranchShape: _
	#errorBranchShape: _
	#callClassSelected: _
	#requestErrorsAdmissible: _
	#recoveryErrorsAdmissible: _
	#knownFailuresAdmissible: _
	#ambiguitiesAdmissible: _
	#requestErrorReferencesResolve: _
	#recoveryErrorReferencesResolve: _
	#knownFailureReferencesResolve: _
	#ambiguityReferencesResolve: _
	#matrixReferencesResolve: _
})

#TransitionCell: close({
	rowId: string
	columnId: string
	kind: "transition"
	nextStateId: string
})

#ReplayCell: close({
	rowId: string
	columnId: string
	kind: "replay"
})

#RejectCell: close({
	rowId: string
	columnId: string
	kind: "reject"
	requestErrorId: string
})

#NoopCell: close({
	rowId: string
	columnId: string
	kind: "noop"
})

#MatrixCell: #TransitionCell | #ReplayCell | #RejectCell | #NoopCell

#Matrix: close({
	id: string
	rowIds: [...string]
	columnIds: [...string]
	cells: [...#MatrixCell]

	#rowIdsUnique: true & list.UniqueItems(rowIds)
	#columnIdsUnique: true & list.UniqueItems(columnIds)
	#matrixCoordinates: [
		for cell in cells {"\\(cell.rowId)|\\(cell.columnId)"}
	]
	#declaredMatrixCoordinates: [
		for rowId in rowIds
			for columnId in columnIds {"\\(rowId)|\\(columnId)"}
	]
	#matrixCoordinateCardinality: cells & list.Repeat(
		[#MatrixCell],
		len(rowIds) * len(columnIds),
	)
	#matrixCoordinatesUnique: true & list.UniqueItems(#matrixCoordinates)
	#matrixCoordinatesComplete: [
		for coordinate in #declaredMatrixCoordinates {
			true & list.Contains(#matrixCoordinates, coordinate)
		}
	]
	#matrixCoordinatesDeclared: [
		for coordinate in #matrixCoordinates {
			true & list.Contains(#declaredMatrixCoordinates, coordinate)
		}
	]
	#matrixTransitionsResolve: [
		for cell in cells
		if cell.kind == "transition" {
			true & list.Contains(rowIds, cell.nextStateId)
		}
	]
	#rowIdsSelected: _
	#columnIdsSelected: _
	#rowReferencesResolve: _
	#columnReferencesResolve: _
	#matrixRejectsAdmissible: _
	#matrixCellsSelected: _
})

#ContractModel: close({
	contractModelVersion: string
	contractId: string
	semanticProfile: string
	terminalStateIds: [...string]
	closedSums: [...#ClosedSum]
	operations: [...#Operation]
	matrices: [...#Matrix]

	#closedSumIdsUnique: true & list.UniqueItems([
		for sum in closedSums {sum.id}
	])
	#operationIdsUnique: true & list.UniqueItems([
		for operation in operations {operation.operationId}
	])
	#matrixIdsUnique: true & list.UniqueItems([
		for matrix in matrices {matrix.id}
	])
	#terminalStateReferencesResolve: _
})

#ContractBundle: close({
	bundleVersion: "0.1.0"
	digestAlgorithm: "sha256"
	semanticDigest: =~"^[0-9a-f]{64}$"
	model: #ContractModel & {
		contractModelVersion: ${literal(model.contractModelVersion)}
		contractId: ${literal(model.contractId)}
		semanticProfile: ${literal(model.semanticProfile)}
		terminalStateIds: ${stringList(model.terminalStateIds)}
		#terminalStateReferencesResolve: ${subsetConstraint(
      "terminalStateIds",
      stateIds,
    )}
		closedSums: [
${model.closedSums.map(closedSumSchema).join(",\n")}
		]
		operations: [
${model.operations
  .map((operation) =>
    operationSchema(operation, {
      requestErrorIds,
      recoveryErrorIds,
      knownFailureIds,
      ambiguityIds,
      matrixIds,
    }),
  )
  .join(",\n")}
		]
		matrices: [
${model.matrices
  .map((matrix) =>
    matrixSchema(matrix, model.operations, stateIds, operationIds),
  )
  .join(",\n")}
		]
	}
})
`;

  return Object.freeze([generatedFile("cue/contract.cue", source)]);
}

function variantIds(
  model: Readonly<ContractModel>,
  sumId: string,
): readonly string[] {
  return (
    model.closedSums.find((sum) => sum.id === sumId)?.variants.map(
      (variant) => variant.id,
    ) ?? []
  );
}

function closedSumSchema(sum: ClosedSum): string {
  return `			#ClosedSum & {
				id: ${literal(sum.id)}
				variants: [
${sum.variants
  .map(
    (variant) => `					#ClosedVariant & {
						id: ${literal(variant.id)}
						wireTag: ${literal(requiredWireTag(variant.wireTag))}
						#wireTagSelected: wireTag & ${literal(
              requiredWireTag(variant.wireTag),
            )}
					}`,
  )
  .join(",\n")}
				]
			}`;
}

type OperationRegistries = Readonly<{
  requestErrorIds: readonly string[];
  recoveryErrorIds: readonly string[];
  knownFailureIds: readonly string[];
  ambiguityIds: readonly string[];
  matrixIds: readonly string[];
}>;

function operationSchema(
  operation: OperationContract,
  registries: OperationRegistries,
): string {
  return `			#Operation & {
				operationId: ${literal(operation.operationId)}
				callClass: string
				resultBranches: [...("accepted" | "rejected" | "recovery" | "observed")]
				allowedRequestErrors: [...string]
				allowedRecoveryErrors: [...string]
				allowedKnownFailures: [...string]
				allowedAmbiguities: [...string]
				matrixIds: [...string]
				recoveryCoordinates: [${operation.recoveryCoordinates
          .map(
            (coordinate) =>
              `#RecoveryCoordinate & {kind: ${literal(
                coordinate.kind,
              )}, value: ${literal(coordinate.value)}}`,
          )
          .join(", ")}]
				result: #OperationResult & {
					carrierKind: ${literal(operation.result.carrierKind)}
					schemaStableId: ${literal(operation.result.schemaStableId)}
				}
				#observationBranchShape: ${exactListConstraint(
          "resultBranches",
          operation.resultBranches,
        )}
				#errorBranchShape: ${exactListConstraint(
          "resultBranches",
          operation.resultBranches,
        )}
				#callClassSelected: callClass & ${literal(
          operation.callClass,
        )}
				#requestErrorsAdmissible: ${exactListConstraint(
          "allowedRequestErrors",
          operation.allowedRequestErrors,
        )}
				#recoveryErrorsAdmissible: ${exactListConstraint(
          "allowedRecoveryErrors",
          operation.allowedRecoveryErrors,
        )}
				#knownFailuresAdmissible: ${exactListConstraint(
          "allowedKnownFailures",
          operation.allowedKnownFailures,
        )}
				#ambiguitiesAdmissible: ${exactListConstraint(
          "allowedAmbiguities",
          operation.allowedAmbiguities,
        )}
				#requestErrorReferencesResolve: ${subsetConstraint(
          "allowedRequestErrors",
          registries.requestErrorIds,
        )}
				#recoveryErrorReferencesResolve: ${subsetConstraint(
          "allowedRecoveryErrors",
          registries.recoveryErrorIds,
        )}
				#knownFailureReferencesResolve: ${subsetConstraint(
          "allowedKnownFailures",
          registries.knownFailureIds,
        )}
				#ambiguityReferencesResolve: ${subsetConstraint(
          "allowedAmbiguities",
          registries.ambiguityIds,
        )}
				#matrixReferencesResolve: ${exactListConstraint(
          "matrixIds",
          operation.matrixIds.filter((id) => registries.matrixIds.includes(id)),
        )}
			}`;
}

function matrixSchema(
  matrix: TotalMatrix,
  operations: readonly OperationContract[],
  stateIds: readonly string[],
  operationIds: readonly string[],
): string {
  const rejectCases = matrix.columnIds.flatMap((columnId) => {
    const allowed =
      operations.find((operation) => operation.operationId === columnId)
        ?.allowedRequestErrors ?? [];
    if (allowed.length === 0) {
      return [];
    }
    return [
      `{columnId: ${literal(columnId)}, requestErrorId: ${stringUnion(
        allowed,
      )}}`,
    ];
  });
  const rejectConstraint =
    rejectCases.length === 0
      ? "_|_"
      : `#RejectCell & (${rejectCases.join(" | ")})`;
  const admissibleCellConstraint = `#TransitionCell | #ReplayCell | #NoopCell | (${rejectConstraint})`;
  const selectedCellConstraint = matrix.cells
    .map(matrixCellConstraint)
    .join(" | ");

  return `			#Matrix & {
				id: ${literal(matrix.id)}
				rowIds: [...string]
				columnIds: [...string]
				cells: [...#MatrixCell]
				#rowIdsSelected: ${exactListConstraint(
          "rowIds",
          matrix.rowIds,
        )}
				#columnIdsSelected: ${exactListConstraint(
          "columnIds",
          matrix.columnIds,
        )}
				#rowReferencesResolve: ${subsetConstraint("rowIds", stateIds)}
				#columnReferencesResolve: ${subsetConstraint(
          "columnIds",
          operationIds,
        )}
				#matrixRejectsAdmissible: cells & [...(${admissibleCellConstraint})]
				#matrixCellsSelected: cells & [...(${selectedCellConstraint})]
			}`;
}

function matrixCellConstraint(
  cell: TotalMatrix["cells"][number],
): string {
  const fields = [
    `rowId: ${literal(cell.rowId)}`,
    `columnId: ${literal(cell.columnId)}`,
  ];
  switch (cell.kind) {
    case "transition":
      return `#TransitionCell & {${fields.join(", ")}, nextStateId: ${literal(
        cell.nextStateId,
      )}}`;
    case "reject":
      return `#RejectCell & {${fields.join(", ")}, requestErrorId: ${literal(
        cell.requestErrorId,
      )}}`;
    case "replay":
      return `#ReplayCell & {${fields.join(", ")}}`;
    case "noop":
      return `#NoopCell & {${fields.join(", ")}}`;
  }
}

function exactListConstraint(
  field: string,
  values: readonly string[],
): string {
  return `${field} & [${values.map(() => stringUnion(values)).join(", ")}]`;
}

function subsetConstraint(field: string, values: readonly string[]): string {
  if (values.length === 0) {
    return `${field} & []`;
  }
  return `${field} & [...(${stringUnion(values)})]`;
}

function stringUnion(values: readonly string[]): string {
  if (values.length === 0) {
    return "_|_";
  }
  return values.map(literal).join(" | ");
}

function stringList(values: readonly string[]): string {
  return `[${values.map(literal).join(", ")}]`;
}

function literal(value: string): string {
  return JSON.stringify(value);
}

function requiredWireTag(wireTag: string | undefined): string {
  if (wireTag === undefined) {
    throw new Error("contract/generated-wire-tag-invalid");
  }
  return wireTag;
}
