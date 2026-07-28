package contract

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
			"\(coordinate.kind)|\(coordinate.value)"
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
		for cell in cells {"\(cell.rowId)|\(cell.columnId)"}
	]
	#declaredMatrixCoordinates: [
		for rowId in rowIds
			for columnId in columnIds {"\(rowId)|\(columnId)"}
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
		contractModelVersion: "0.1.0"
		contractId: "packet-e-vertical-slice"
		semanticProfile: "packet-e-contract-prototype"
		terminalStateIds: ["state.operation.cancelled", "state.operation.failed", "state.operation.succeeded", "state.operation.unknown", "state.process.terminated"]
		#terminalStateReferencesResolve: terminalStateIds & [...("state.operation.accepted" | "state.operation.cancel.requested" | "state.operation.cancelled" | "state.operation.failed" | "state.operation.running" | "state.operation.succeeded" | "state.operation.unknown" | "state.process.accepted" | "state.process.running" | "state.process.starting" | "state.process.terminated" | "state.process.unknown" | "state.sandbox.provisioning" | "state.sandbox.running" | "state.sandbox.stopped" | "state.sandbox.unknown")]
		closedSums: [
			#ClosedSum & {
				id: "registry.ambiguity"
				variants: [
					#ClosedVariant & {
						id: "ambiguity.runtime.unknown"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					}
				]
			},
			#ClosedSum & {
				id: "registry.caller.recovery"
				variants: [
					#ClosedVariant & {
						id: "caller.recovery.retry"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					}
				]
			},
			#ClosedSum & {
				id: "registry.core.resolution"
				variants: [
					#ClosedVariant & {
						id: "core.resolution.reconcile"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					}
				]
			},
			#ClosedSum & {
				id: "registry.known.failure"
				variants: [
					#ClosedVariant & {
						id: "failure.runtime.provisioning"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					}
				]
			},
			#ClosedSum & {
				id: "registry.operation.outcome"
				variants: [
					#ClosedVariant & {
						id: "outcome.accepted"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					},
					#ClosedVariant & {
						id: "outcome.observed"
						wireTag: "4"
						#wireTagSelected: wireTag & "4"
					},
					#ClosedVariant & {
						id: "outcome.recovery"
						wireTag: "3"
						#wireTagSelected: wireTag & "3"
					},
					#ClosedVariant & {
						id: "outcome.rejected"
						wireTag: "2"
						#wireTagSelected: wireTag & "2"
					}
				]
			},
			#ClosedSum & {
				id: "registry.process.control.outcome"
				variants: [
					#ClosedVariant & {
						id: "outcome.process.accepted"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					},
					#ClosedVariant & {
						id: "outcome.process.recovery"
						wireTag: "3"
						#wireTagSelected: wireTag & "3"
					},
					#ClosedVariant & {
						id: "outcome.process.rejected"
						wireTag: "2"
						#wireTagSelected: wireTag & "2"
					}
				]
			},
			#ClosedSum & {
				id: "registry.process.termination"
				variants: [
					#ClosedVariant & {
						id: "process.termination.exited"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					},
					#ClosedVariant & {
						id: "process.termination.signalled"
						wireTag: "2"
						#wireTagSelected: wireTag & "2"
					}
				]
			},
			#ClosedSum & {
				id: "registry.provider.evidence"
				variants: [
					#ClosedVariant & {
						id: "provider.evidence.observed"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					}
				]
			},
			#ClosedSum & {
				id: "registry.recovery.error"
				variants: [
					#ClosedVariant & {
						id: "recovery.idempotency.expired"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					}
				]
			},
			#ClosedSum & {
				id: "registry.request.error"
				variants: [
					#ClosedVariant & {
						id: "request.invalid.state"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					},
					#ClosedVariant & {
						id: "request.sequence.out.of.range"
						wireTag: "2"
						#wireTagSelected: wireTag & "2"
					}
				]
			},
			#ClosedSum & {
				id: "registry.transport.error"
				variants: [
					#ClosedVariant & {
						id: "transport.error.unavailable"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					}
				]
			},
			#ClosedSum & {
				id: "state.operation"
				variants: [
					#ClosedVariant & {
						id: "state.operation.accepted"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					},
					#ClosedVariant & {
						id: "state.operation.cancel.requested"
						wireTag: "3"
						#wireTagSelected: wireTag & "3"
					},
					#ClosedVariant & {
						id: "state.operation.cancelled"
						wireTag: "6"
						#wireTagSelected: wireTag & "6"
					},
					#ClosedVariant & {
						id: "state.operation.failed"
						wireTag: "5"
						#wireTagSelected: wireTag & "5"
					},
					#ClosedVariant & {
						id: "state.operation.running"
						wireTag: "2"
						#wireTagSelected: wireTag & "2"
					},
					#ClosedVariant & {
						id: "state.operation.succeeded"
						wireTag: "4"
						#wireTagSelected: wireTag & "4"
					},
					#ClosedVariant & {
						id: "state.operation.unknown"
						wireTag: "7"
						#wireTagSelected: wireTag & "7"
					}
				]
			},
			#ClosedSum & {
				id: "state.process"
				variants: [
					#ClosedVariant & {
						id: "state.process.accepted"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					},
					#ClosedVariant & {
						id: "state.process.running"
						wireTag: "3"
						#wireTagSelected: wireTag & "3"
					},
					#ClosedVariant & {
						id: "state.process.starting"
						wireTag: "2"
						#wireTagSelected: wireTag & "2"
					},
					#ClosedVariant & {
						id: "state.process.terminated"
						wireTag: "5"
						#wireTagSelected: wireTag & "5"
					},
					#ClosedVariant & {
						id: "state.process.unknown"
						wireTag: "4"
						#wireTagSelected: wireTag & "4"
					}
				]
			},
			#ClosedSum & {
				id: "state.sandbox"
				variants: [
					#ClosedVariant & {
						id: "state.sandbox.provisioning"
						wireTag: "2"
						#wireTagSelected: wireTag & "2"
					},
					#ClosedVariant & {
						id: "state.sandbox.running"
						wireTag: "3"
						#wireTagSelected: wireTag & "3"
					},
					#ClosedVariant & {
						id: "state.sandbox.stopped"
						wireTag: "1"
						#wireTagSelected: wireTag & "1"
					},
					#ClosedVariant & {
						id: "state.sandbox.unknown"
						wireTag: "4"
						#wireTagSelected: wireTag & "4"
					}
				]
			}
		]
		operations: [
			#Operation & {
				operationId: "operation.cancel.operation"
				callClass: string
				resultBranches: [...("accepted" | "rejected" | "recovery" | "observed")]
				allowedRequestErrors: [...string]
				allowedRecoveryErrors: [...string]
				allowedKnownFailures: [...string]
				allowedAmbiguities: [...string]
				matrixIds: [...string]
				recoveryCoordinates: [#RecoveryCoordinate & {kind: "operationId", value: "existing.operation.id"}]
				result: #OperationResult & {
					carrierKind: "existingOperationObservation"
					schemaStableId: "result.existing.operation.observation"
				}
				#observationBranchShape: resultBranches & ["accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected"]
				#errorBranchShape: resultBranches & ["accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected"]
				#callClassSelected: callClass & "existingHandleIntent"
				#requestErrorsAdmissible: allowedRequestErrors & ["request.invalid.state"]
				#recoveryErrorsAdmissible: allowedRecoveryErrors & ["recovery.idempotency.expired"]
				#knownFailuresAdmissible: allowedKnownFailures & []
				#ambiguitiesAdmissible: allowedAmbiguities & ["ambiguity.runtime.unknown"]
				#requestErrorReferencesResolve: allowedRequestErrors & [...("request.invalid.state" | "request.sequence.out.of.range")]
				#recoveryErrorReferencesResolve: allowedRecoveryErrors & [...("recovery.idempotency.expired")]
				#knownFailureReferencesResolve: allowedKnownFailures & [...("failure.runtime.provisioning")]
				#ambiguityReferencesResolve: allowedAmbiguities & [...("ambiguity.runtime.unknown")]
				#matrixReferencesResolve: matrixIds & ["matrix.sandbox-operation"]
			},
			#Operation & {
				operationId: "operation.start.sandbox"
				callClass: string
				resultBranches: [...("accepted" | "rejected" | "recovery" | "observed")]
				allowedRequestErrors: [...string]
				allowedRecoveryErrors: [...string]
				allowedKnownFailures: [...string]
				allowedAmbiguities: [...string]
				matrixIds: [...string]
				recoveryCoordinates: [#RecoveryCoordinate & {kind: "idempotencyKey", value: "start.idempotency-key"}, #RecoveryCoordinate & {kind: "runtimeEpoch", value: "sandbox.runtime.epoch"}]
				result: #OperationResult & {
					carrierKind: "newDurableOperation"
					schemaStableId: "result.operation.start.sandbox"
				}
				#observationBranchShape: resultBranches & ["accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected"]
				#errorBranchShape: resultBranches & ["accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected"]
				#callClassSelected: callClass & "durableOperationMutation"
				#requestErrorsAdmissible: allowedRequestErrors & ["request.invalid.state"]
				#recoveryErrorsAdmissible: allowedRecoveryErrors & ["recovery.idempotency.expired"]
				#knownFailuresAdmissible: allowedKnownFailures & ["failure.runtime.provisioning"]
				#ambiguitiesAdmissible: allowedAmbiguities & ["ambiguity.runtime.unknown"]
				#requestErrorReferencesResolve: allowedRequestErrors & [...("request.invalid.state" | "request.sequence.out.of.range")]
				#recoveryErrorReferencesResolve: allowedRecoveryErrors & [...("recovery.idempotency.expired")]
				#knownFailureReferencesResolve: allowedKnownFailures & [...("failure.runtime.provisioning")]
				#ambiguityReferencesResolve: allowedAmbiguities & [...("ambiguity.runtime.unknown")]
				#matrixReferencesResolve: matrixIds & ["matrix.sandbox-operation"]
			},
			#Operation & {
				operationId: "operation.wait.operation"
				callClass: string
				resultBranches: [...("accepted" | "rejected" | "recovery" | "observed")]
				allowedRequestErrors: [...string]
				allowedRecoveryErrors: [...string]
				allowedKnownFailures: [...string]
				allowedAmbiguities: [...string]
				matrixIds: [...string]
				recoveryCoordinates: []
				result: #OperationResult & {
					carrierKind: "observation"
					schemaStableId: "result.operation.wait.observation"
				}
				#observationBranchShape: resultBranches & ["observed" | "rejected", "observed" | "rejected"]
				#errorBranchShape: resultBranches & ["observed" | "rejected", "observed" | "rejected"]
				#callClassSelected: callClass & "observation"
				#requestErrorsAdmissible: allowedRequestErrors & ["request.invalid.state"]
				#recoveryErrorsAdmissible: allowedRecoveryErrors & []
				#knownFailuresAdmissible: allowedKnownFailures & []
				#ambiguitiesAdmissible: allowedAmbiguities & []
				#requestErrorReferencesResolve: allowedRequestErrors & [...("request.invalid.state" | "request.sequence.out.of.range")]
				#recoveryErrorReferencesResolve: allowedRecoveryErrors & [...("recovery.idempotency.expired")]
				#knownFailureReferencesResolve: allowedKnownFailures & [...("failure.runtime.provisioning")]
				#ambiguityReferencesResolve: allowedAmbiguities & [...("ambiguity.runtime.unknown")]
				#matrixReferencesResolve: matrixIds & ["matrix.sandbox-operation"]
			},
			#Operation & {
				operationId: "operation.write.process.input"
				callClass: string
				resultBranches: [...("accepted" | "rejected" | "recovery" | "observed")]
				allowedRequestErrors: [...string]
				allowedRecoveryErrors: [...string]
				allowedKnownFailures: [...string]
				allowedAmbiguities: [...string]
				matrixIds: [...string]
				recoveryCoordinates: [#RecoveryCoordinate & {kind: "processId", value: "process.id"}, #RecoveryCoordinate & {kind: "runtimeEpoch", value: "sandbox.runtime.epoch"}, #RecoveryCoordinate & {kind: "sequence", value: "process.input.sequence"}, #RecoveryCoordinate & {kind: "writerLease", value: "process.writer.lease"}]
				result: #OperationResult & {
					carrierKind: "processControlReceipt"
					schemaStableId: "result.process.control.receipt"
				}
				#observationBranchShape: resultBranches & ["accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected"]
				#errorBranchShape: resultBranches & ["accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected", "accepted" | "recovery" | "rejected"]
				#callClassSelected: callClass & "sequencedProcessControl"
				#requestErrorsAdmissible: allowedRequestErrors & ["request.invalid.state" | "request.sequence.out.of.range", "request.invalid.state" | "request.sequence.out.of.range"]
				#recoveryErrorsAdmissible: allowedRecoveryErrors & ["recovery.idempotency.expired"]
				#knownFailuresAdmissible: allowedKnownFailures & []
				#ambiguitiesAdmissible: allowedAmbiguities & ["ambiguity.runtime.unknown"]
				#requestErrorReferencesResolve: allowedRequestErrors & [...("request.invalid.state" | "request.sequence.out.of.range")]
				#recoveryErrorReferencesResolve: allowedRecoveryErrors & [...("recovery.idempotency.expired")]
				#knownFailureReferencesResolve: allowedKnownFailures & [...("failure.runtime.provisioning")]
				#ambiguityReferencesResolve: allowedAmbiguities & [...("ambiguity.runtime.unknown")]
				#matrixReferencesResolve: matrixIds & ["matrix.sandbox-operation"]
			}
		]
		matrices: [
			#Matrix & {
				id: "matrix.sandbox-operation"
				rowIds: [...string]
				columnIds: [...string]
				cells: [...#MatrixCell]
				#rowIdsSelected: rowIds & ["state.sandbox.provisioning" | "state.sandbox.running" | "state.sandbox.stopped" | "state.sandbox.unknown", "state.sandbox.provisioning" | "state.sandbox.running" | "state.sandbox.stopped" | "state.sandbox.unknown", "state.sandbox.provisioning" | "state.sandbox.running" | "state.sandbox.stopped" | "state.sandbox.unknown", "state.sandbox.provisioning" | "state.sandbox.running" | "state.sandbox.stopped" | "state.sandbox.unknown"]
				#columnIdsSelected: columnIds & ["operation.cancel.operation" | "operation.start.sandbox" | "operation.wait.operation" | "operation.write.process.input", "operation.cancel.operation" | "operation.start.sandbox" | "operation.wait.operation" | "operation.write.process.input", "operation.cancel.operation" | "operation.start.sandbox" | "operation.wait.operation" | "operation.write.process.input", "operation.cancel.operation" | "operation.start.sandbox" | "operation.wait.operation" | "operation.write.process.input"]
				#rowReferencesResolve: rowIds & [...("state.operation.accepted" | "state.operation.cancel.requested" | "state.operation.cancelled" | "state.operation.failed" | "state.operation.running" | "state.operation.succeeded" | "state.operation.unknown" | "state.process.accepted" | "state.process.running" | "state.process.starting" | "state.process.terminated" | "state.process.unknown" | "state.sandbox.provisioning" | "state.sandbox.running" | "state.sandbox.stopped" | "state.sandbox.unknown")]
				#columnReferencesResolve: columnIds & [...("operation.cancel.operation" | "operation.start.sandbox" | "operation.wait.operation" | "operation.write.process.input")]
				#matrixRejectsAdmissible: cells & [...(#TransitionCell | #ReplayCell | #NoopCell | (#RejectCell & ({columnId: "operation.cancel.operation", requestErrorId: "request.invalid.state"} | {columnId: "operation.start.sandbox", requestErrorId: "request.invalid.state"} | {columnId: "operation.wait.operation", requestErrorId: "request.invalid.state"} | {columnId: "operation.write.process.input", requestErrorId: "request.invalid.state" | "request.sequence.out.of.range"})))]
				#matrixCellsSelected: cells & [...(#NoopCell & {rowId: "state.sandbox.provisioning", columnId: "operation.cancel.operation"} | #ReplayCell & {rowId: "state.sandbox.provisioning", columnId: "operation.start.sandbox"} | #NoopCell & {rowId: "state.sandbox.provisioning", columnId: "operation.wait.operation"} | #RejectCell & {rowId: "state.sandbox.provisioning", columnId: "operation.write.process.input", requestErrorId: "request.invalid.state"} | #NoopCell & {rowId: "state.sandbox.running", columnId: "operation.cancel.operation"} | #ReplayCell & {rowId: "state.sandbox.running", columnId: "operation.start.sandbox"} | #NoopCell & {rowId: "state.sandbox.running", columnId: "operation.wait.operation"} | #NoopCell & {rowId: "state.sandbox.running", columnId: "operation.write.process.input"} | #RejectCell & {rowId: "state.sandbox.stopped", columnId: "operation.cancel.operation", requestErrorId: "request.invalid.state"} | #TransitionCell & {rowId: "state.sandbox.stopped", columnId: "operation.start.sandbox", nextStateId: "state.sandbox.provisioning"} | #NoopCell & {rowId: "state.sandbox.stopped", columnId: "operation.wait.operation"} | #RejectCell & {rowId: "state.sandbox.stopped", columnId: "operation.write.process.input", requestErrorId: "request.invalid.state"} | #NoopCell & {rowId: "state.sandbox.unknown", columnId: "operation.cancel.operation"} | #RejectCell & {rowId: "state.sandbox.unknown", columnId: "operation.start.sandbox", requestErrorId: "request.invalid.state"} | #NoopCell & {rowId: "state.sandbox.unknown", columnId: "operation.wait.operation"} | #RejectCell & {rowId: "state.sandbox.unknown", columnId: "operation.write.process.input", requestErrorId: "request.invalid.state"})]
			}
		]
	}
})
