package contract

import (
	"bytes"
	"encoding/json"
	"io"
)

const InvalidOutcome = "contract/invalid-outcome"

type ContractDiagnostic struct {
	Category string
}

func (diagnostic *ContractDiagnostic) Error() string {
	return diagnostic.Category
}

func invalid() error {
	return &ContractDiagnostic{Category: InvalidOutcome}
}

type WireIdentity struct {
	ContainerID string
	VariantID   string
	WireTag     string
}

var wireIdentities = [...]WireIdentity{
	{ContainerID: "registry.ambiguity", VariantID: "ambiguity.runtime.unknown", WireTag: "1"},
	{ContainerID: "registry.caller.recovery", VariantID: "caller.recovery.retry", WireTag: "1"},
	{ContainerID: "registry.core.resolution", VariantID: "core.resolution.reconcile", WireTag: "1"},
	{ContainerID: "registry.known.failure", VariantID: "failure.runtime.provisioning", WireTag: "1"},
	{ContainerID: "registry.operation.outcome", VariantID: "outcome.accepted", WireTag: "1"},
	{ContainerID: "registry.operation.outcome", VariantID: "outcome.observed", WireTag: "4"},
	{ContainerID: "registry.operation.outcome", VariantID: "outcome.recovery", WireTag: "3"},
	{ContainerID: "registry.operation.outcome", VariantID: "outcome.rejected", WireTag: "2"},
	{ContainerID: "registry.process.control.outcome", VariantID: "outcome.process.accepted", WireTag: "1"},
	{ContainerID: "registry.process.control.outcome", VariantID: "outcome.process.recovery", WireTag: "3"},
	{ContainerID: "registry.process.control.outcome", VariantID: "outcome.process.rejected", WireTag: "2"},
	{ContainerID: "registry.process.termination", VariantID: "process.termination.exited", WireTag: "1"},
	{ContainerID: "registry.process.termination", VariantID: "process.termination.signalled", WireTag: "2"},
	{ContainerID: "registry.provider.evidence", VariantID: "provider.evidence.observed", WireTag: "1"},
	{ContainerID: "registry.recovery.error", VariantID: "recovery.idempotency.expired", WireTag: "1"},
	{ContainerID: "registry.request.error", VariantID: "request.invalid.state", WireTag: "1"},
	{ContainerID: "registry.request.error", VariantID: "request.sequence.out.of.range", WireTag: "2"},
	{ContainerID: "registry.transport.error", VariantID: "transport.error.unavailable", WireTag: "1"},
	{ContainerID: "state.operation", VariantID: "state.operation.accepted", WireTag: "1"},
	{ContainerID: "state.operation", VariantID: "state.operation.cancel.requested", WireTag: "3"},
	{ContainerID: "state.operation", VariantID: "state.operation.cancelled", WireTag: "6"},
	{ContainerID: "state.operation", VariantID: "state.operation.failed", WireTag: "5"},
	{ContainerID: "state.operation", VariantID: "state.operation.running", WireTag: "2"},
	{ContainerID: "state.operation", VariantID: "state.operation.succeeded", WireTag: "4"},
	{ContainerID: "state.operation", VariantID: "state.operation.unknown", WireTag: "7"},
	{ContainerID: "state.process", VariantID: "state.process.accepted", WireTag: "1"},
	{ContainerID: "state.process", VariantID: "state.process.running", WireTag: "3"},
	{ContainerID: "state.process", VariantID: "state.process.starting", WireTag: "2"},
	{ContainerID: "state.process", VariantID: "state.process.terminated", WireTag: "5"},
	{ContainerID: "state.process", VariantID: "state.process.unknown", WireTag: "4"},
	{ContainerID: "state.sandbox", VariantID: "state.sandbox.provisioning", WireTag: "2"},
	{ContainerID: "state.sandbox", VariantID: "state.sandbox.running", WireTag: "3"},
	{ContainerID: "state.sandbox", VariantID: "state.sandbox.stopped", WireTag: "1"},
	{ContainerID: "state.sandbox", VariantID: "state.sandbox.unknown", WireTag: "4"},
}

func ContractWireIdentities() []WireIdentity {
	identities := make([]WireIdentity, len(wireIdentities))
	copy(identities, wireIdentities[:])
	return identities
}

type RegistryAmbiguity interface {
	isRegistryAmbiguity()
	StableID() string
	WireTag() string
}

type registryAmbiguityAmbiguityRuntimeUnknown struct{}

func (registryAmbiguityAmbiguityRuntimeUnknown) isRegistryAmbiguity() {}
func (registryAmbiguityAmbiguityRuntimeUnknown) StableID() string { return "ambiguity.runtime.unknown" }
func (registryAmbiguityAmbiguityRuntimeUnknown) WireTag() string { return "1" }

type RegistryCallerRecovery interface {
	isRegistryCallerRecovery()
	StableID() string
	WireTag() string
}

type registryCallerRecoveryCallerRecoveryRetry struct{}

func (registryCallerRecoveryCallerRecoveryRetry) isRegistryCallerRecovery() {}
func (registryCallerRecoveryCallerRecoveryRetry) StableID() string { return "caller.recovery.retry" }
func (registryCallerRecoveryCallerRecoveryRetry) WireTag() string { return "1" }

type RegistryCoreResolution interface {
	isRegistryCoreResolution()
	StableID() string
	WireTag() string
}

type registryCoreResolutionCoreResolutionReconcile struct{}

func (registryCoreResolutionCoreResolutionReconcile) isRegistryCoreResolution() {}
func (registryCoreResolutionCoreResolutionReconcile) StableID() string { return "core.resolution.reconcile" }
func (registryCoreResolutionCoreResolutionReconcile) WireTag() string { return "1" }

type RegistryKnownFailure interface {
	isRegistryKnownFailure()
	StableID() string
	WireTag() string
}

type registryKnownFailureFailureRuntimeProvisioning struct{}

func (registryKnownFailureFailureRuntimeProvisioning) isRegistryKnownFailure() {}
func (registryKnownFailureFailureRuntimeProvisioning) StableID() string { return "failure.runtime.provisioning" }
func (registryKnownFailureFailureRuntimeProvisioning) WireTag() string { return "1" }

type RegistryOperationOutcome interface {
	isRegistryOperationOutcome()
	StableID() string
	WireTag() string
}

type registryOperationOutcomeOutcomeAccepted struct{}

func (registryOperationOutcomeOutcomeAccepted) isRegistryOperationOutcome() {}
func (registryOperationOutcomeOutcomeAccepted) StableID() string { return "outcome.accepted" }
func (registryOperationOutcomeOutcomeAccepted) WireTag() string { return "1" }

type registryOperationOutcomeOutcomeObserved struct{}

func (registryOperationOutcomeOutcomeObserved) isRegistryOperationOutcome() {}
func (registryOperationOutcomeOutcomeObserved) StableID() string { return "outcome.observed" }
func (registryOperationOutcomeOutcomeObserved) WireTag() string { return "4" }

type registryOperationOutcomeOutcomeRecovery struct{}

func (registryOperationOutcomeOutcomeRecovery) isRegistryOperationOutcome() {}
func (registryOperationOutcomeOutcomeRecovery) StableID() string { return "outcome.recovery" }
func (registryOperationOutcomeOutcomeRecovery) WireTag() string { return "3" }

type registryOperationOutcomeOutcomeRejected struct{}

func (registryOperationOutcomeOutcomeRejected) isRegistryOperationOutcome() {}
func (registryOperationOutcomeOutcomeRejected) StableID() string { return "outcome.rejected" }
func (registryOperationOutcomeOutcomeRejected) WireTag() string { return "2" }

type RegistryProcessControlOutcome interface {
	isRegistryProcessControlOutcome()
	StableID() string
	WireTag() string
}

type registryProcessControlOutcomeOutcomeProcessAccepted struct{}

func (registryProcessControlOutcomeOutcomeProcessAccepted) isRegistryProcessControlOutcome() {}
func (registryProcessControlOutcomeOutcomeProcessAccepted) StableID() string { return "outcome.process.accepted" }
func (registryProcessControlOutcomeOutcomeProcessAccepted) WireTag() string { return "1" }

type registryProcessControlOutcomeOutcomeProcessRecovery struct{}

func (registryProcessControlOutcomeOutcomeProcessRecovery) isRegistryProcessControlOutcome() {}
func (registryProcessControlOutcomeOutcomeProcessRecovery) StableID() string { return "outcome.process.recovery" }
func (registryProcessControlOutcomeOutcomeProcessRecovery) WireTag() string { return "3" }

type registryProcessControlOutcomeOutcomeProcessRejected struct{}

func (registryProcessControlOutcomeOutcomeProcessRejected) isRegistryProcessControlOutcome() {}
func (registryProcessControlOutcomeOutcomeProcessRejected) StableID() string { return "outcome.process.rejected" }
func (registryProcessControlOutcomeOutcomeProcessRejected) WireTag() string { return "2" }

type RegistryProcessTermination interface {
	isRegistryProcessTermination()
	StableID() string
	WireTag() string
}

type registryProcessTerminationProcessTerminationExited struct{}

func (registryProcessTerminationProcessTerminationExited) isRegistryProcessTermination() {}
func (registryProcessTerminationProcessTerminationExited) StableID() string { return "process.termination.exited" }
func (registryProcessTerminationProcessTerminationExited) WireTag() string { return "1" }

type registryProcessTerminationProcessTerminationSignalled struct{}

func (registryProcessTerminationProcessTerminationSignalled) isRegistryProcessTermination() {}
func (registryProcessTerminationProcessTerminationSignalled) StableID() string { return "process.termination.signalled" }
func (registryProcessTerminationProcessTerminationSignalled) WireTag() string { return "2" }

type RegistryProviderEvidence interface {
	isRegistryProviderEvidence()
	StableID() string
	WireTag() string
}

type registryProviderEvidenceProviderEvidenceObserved struct{}

func (registryProviderEvidenceProviderEvidenceObserved) isRegistryProviderEvidence() {}
func (registryProviderEvidenceProviderEvidenceObserved) StableID() string { return "provider.evidence.observed" }
func (registryProviderEvidenceProviderEvidenceObserved) WireTag() string { return "1" }

type RegistryRecoveryError interface {
	isRegistryRecoveryError()
	StableID() string
	WireTag() string
}

type registryRecoveryErrorRecoveryIdempotencyExpired struct{}

func (registryRecoveryErrorRecoveryIdempotencyExpired) isRegistryRecoveryError() {}
func (registryRecoveryErrorRecoveryIdempotencyExpired) StableID() string { return "recovery.idempotency.expired" }
func (registryRecoveryErrorRecoveryIdempotencyExpired) WireTag() string { return "1" }

type RegistryRequestError interface {
	isRegistryRequestError()
	StableID() string
	WireTag() string
}

type registryRequestErrorRequestInvalidState struct{}

func (registryRequestErrorRequestInvalidState) isRegistryRequestError() {}
func (registryRequestErrorRequestInvalidState) StableID() string { return "request.invalid.state" }
func (registryRequestErrorRequestInvalidState) WireTag() string { return "1" }

type registryRequestErrorRequestSequenceOutOfRange struct{}

func (registryRequestErrorRequestSequenceOutOfRange) isRegistryRequestError() {}
func (registryRequestErrorRequestSequenceOutOfRange) StableID() string { return "request.sequence.out.of.range" }
func (registryRequestErrorRequestSequenceOutOfRange) WireTag() string { return "2" }

type RegistryTransportError interface {
	isRegistryTransportError()
	StableID() string
	WireTag() string
}

type registryTransportErrorTransportErrorUnavailable struct{}

func (registryTransportErrorTransportErrorUnavailable) isRegistryTransportError() {}
func (registryTransportErrorTransportErrorUnavailable) StableID() string { return "transport.error.unavailable" }
func (registryTransportErrorTransportErrorUnavailable) WireTag() string { return "1" }

type StateOperation interface {
	isStateOperation()
	StableID() string
	WireTag() string
}

type stateOperationStateOperationAccepted struct{}

func (stateOperationStateOperationAccepted) isStateOperation() {}
func (stateOperationStateOperationAccepted) StableID() string { return "state.operation.accepted" }
func (stateOperationStateOperationAccepted) WireTag() string { return "1" }

type stateOperationStateOperationCancelRequested struct{}

func (stateOperationStateOperationCancelRequested) isStateOperation() {}
func (stateOperationStateOperationCancelRequested) StableID() string { return "state.operation.cancel.requested" }
func (stateOperationStateOperationCancelRequested) WireTag() string { return "3" }

type stateOperationStateOperationCancelled struct{}

func (stateOperationStateOperationCancelled) isStateOperation() {}
func (stateOperationStateOperationCancelled) StableID() string { return "state.operation.cancelled" }
func (stateOperationStateOperationCancelled) WireTag() string { return "6" }

type stateOperationStateOperationFailed struct{}

func (stateOperationStateOperationFailed) isStateOperation() {}
func (stateOperationStateOperationFailed) StableID() string { return "state.operation.failed" }
func (stateOperationStateOperationFailed) WireTag() string { return "5" }

type stateOperationStateOperationRunning struct{}

func (stateOperationStateOperationRunning) isStateOperation() {}
func (stateOperationStateOperationRunning) StableID() string { return "state.operation.running" }
func (stateOperationStateOperationRunning) WireTag() string { return "2" }

type stateOperationStateOperationSucceeded struct{}

func (stateOperationStateOperationSucceeded) isStateOperation() {}
func (stateOperationStateOperationSucceeded) StableID() string { return "state.operation.succeeded" }
func (stateOperationStateOperationSucceeded) WireTag() string { return "4" }

type stateOperationStateOperationUnknown struct{}

func (stateOperationStateOperationUnknown) isStateOperation() {}
func (stateOperationStateOperationUnknown) StableID() string { return "state.operation.unknown" }
func (stateOperationStateOperationUnknown) WireTag() string { return "7" }

type StateProcess interface {
	isStateProcess()
	StableID() string
	WireTag() string
}

type stateProcessStateProcessAccepted struct{}

func (stateProcessStateProcessAccepted) isStateProcess() {}
func (stateProcessStateProcessAccepted) StableID() string { return "state.process.accepted" }
func (stateProcessStateProcessAccepted) WireTag() string { return "1" }

type stateProcessStateProcessRunning struct{}

func (stateProcessStateProcessRunning) isStateProcess() {}
func (stateProcessStateProcessRunning) StableID() string { return "state.process.running" }
func (stateProcessStateProcessRunning) WireTag() string { return "3" }

type stateProcessStateProcessStarting struct{}

func (stateProcessStateProcessStarting) isStateProcess() {}
func (stateProcessStateProcessStarting) StableID() string { return "state.process.starting" }
func (stateProcessStateProcessStarting) WireTag() string { return "2" }

type stateProcessStateProcessTerminated struct{}

func (stateProcessStateProcessTerminated) isStateProcess() {}
func (stateProcessStateProcessTerminated) StableID() string { return "state.process.terminated" }
func (stateProcessStateProcessTerminated) WireTag() string { return "5" }

type stateProcessStateProcessUnknown struct{}

func (stateProcessStateProcessUnknown) isStateProcess() {}
func (stateProcessStateProcessUnknown) StableID() string { return "state.process.unknown" }
func (stateProcessStateProcessUnknown) WireTag() string { return "4" }

type StateSandbox interface {
	isStateSandbox()
	StableID() string
	WireTag() string
}

type stateSandboxStateSandboxProvisioning struct{}

func (stateSandboxStateSandboxProvisioning) isStateSandbox() {}
func (stateSandboxStateSandboxProvisioning) StableID() string { return "state.sandbox.provisioning" }
func (stateSandboxStateSandboxProvisioning) WireTag() string { return "2" }

type stateSandboxStateSandboxRunning struct{}

func (stateSandboxStateSandboxRunning) isStateSandbox() {}
func (stateSandboxStateSandboxRunning) StableID() string { return "state.sandbox.running" }
func (stateSandboxStateSandboxRunning) WireTag() string { return "3" }

type stateSandboxStateSandboxStopped struct{}

func (stateSandboxStateSandboxStopped) isStateSandbox() {}
func (stateSandboxStateSandboxStopped) StableID() string { return "state.sandbox.stopped" }
func (stateSandboxStateSandboxStopped) WireTag() string { return "1" }

type stateSandboxStateSandboxUnknown struct{}

func (stateSandboxStateSandboxUnknown) isStateSandbox() {}
func (stateSandboxStateSandboxUnknown) StableID() string { return "state.sandbox.unknown" }
func (stateSandboxStateSandboxUnknown) WireTag() string { return "4" }

type CancelOperationRequestError interface {
	isCancelOperationRequestError()
	StableID() string
}

type cancelOperationRequestErrorRequestInvalidState struct{}

func (cancelOperationRequestErrorRequestInvalidState) isCancelOperationRequestError() {}
func (cancelOperationRequestErrorRequestInvalidState) StableID() string { return "request.invalid.state" }

type CancelOperationRecoveryError interface {
	isCancelOperationRecoveryError()
	StableID() string
}

type cancelOperationRecoveryErrorRecoveryIdempotencyExpired struct{}

func (cancelOperationRecoveryErrorRecoveryIdempotencyExpired) isCancelOperationRecoveryError() {}
func (cancelOperationRecoveryErrorRecoveryIdempotencyExpired) StableID() string { return "recovery.idempotency.expired" }

type CancelOperationKnownFailure interface {
	isCancelOperationKnownFailure()
	StableID() string
}



type CancelOperationAmbiguity interface {
	isCancelOperationAmbiguity()
	StableID() string
}

type cancelOperationAmbiguityAmbiguityRuntimeUnknown struct{}

func (cancelOperationAmbiguityAmbiguityRuntimeUnknown) isCancelOperationAmbiguity() {}
func (cancelOperationAmbiguityAmbiguityRuntimeUnknown) StableID() string { return "ambiguity.runtime.unknown" }

type cancelOperationCarrier struct {
	private struct{}
}

func (cancelOperationCarrier) CarrierKind() string {
	return "existingOperationObservation"
}

func (cancelOperationCarrier) SchemaStableID() string {
	return "result.existing.operation.observation"
}

// CancelOperationOutcome is package-marked, not statically sealed. Go interface
// embedding can satisfy private marker methods. Inspect or validate values
// received across a trust boundary before using their semantics.
type CancelOperationOutcome interface {
	isCancelOperationOutcome()
	isAnyOutcome()
}

type CancelOperationAccepted interface {
	CancelOperationOutcome
	isCancelOperationAccepted()
}

type cancelOperationAccepted struct {
	carrier cancelOperationCarrier
}

func (cancelOperationAccepted) isCancelOperationOutcome() {}
func (cancelOperationAccepted) isAnyOutcome() {}
func (cancelOperationAccepted) isCancelOperationAccepted() {}
func (cancelOperationAccepted) Branch() string { return "accepted" }
func (cancelOperationAccepted) OperationID() string { return "operation.cancel.operation" }

type CancelOperationRecovery interface {
	CancelOperationOutcome
	isCancelOperationRecovery()
}

type cancelOperationRecovery struct {
	reason CancelOperationRecoveryError
}

func (cancelOperationRecovery) isCancelOperationOutcome() {}
func (cancelOperationRecovery) isAnyOutcome() {}
func (cancelOperationRecovery) isCancelOperationRecovery() {}
func (cancelOperationRecovery) Branch() string { return "recovery" }
func (cancelOperationRecovery) OperationID() string { return "operation.cancel.operation" }

type CancelOperationRejected interface {
	CancelOperationOutcome
	isCancelOperationRejected()
}

type cancelOperationRejected struct {
	reason CancelOperationRequestError
}

func (cancelOperationRejected) isCancelOperationOutcome() {}
func (cancelOperationRejected) isAnyOutcome() {}
func (cancelOperationRejected) isCancelOperationRejected() {}
func (cancelOperationRejected) Branch() string { return "rejected" }
func (cancelOperationRejected) OperationID() string { return "operation.cancel.operation" }

type CancelOperationOutcomeView struct {
	operationID    string
	branch         string
	carrierKind    string
	schemaStableID string
	requestError   CancelOperationRequestError
	recoveryError  CancelOperationRecoveryError
}

func (CancelOperationOutcomeView) isAnyOutcomeView() {}

func (view CancelOperationOutcomeView) OperationID() string {
	return view.operationID
}

func (view CancelOperationOutcomeView) Branch() string {
	return view.branch
}

func (view CancelOperationOutcomeView) CarrierKind() (string, bool) {
	return view.carrierKind, view.carrierKind != ""
}

func (view CancelOperationOutcomeView) SchemaStableID() (string, bool) {
	return view.schemaStableID, view.schemaStableID != ""
}

func (view CancelOperationOutcomeView) RequestError() (CancelOperationRequestError, bool) {
	return view.requestError, view.requestError != nil
}

func (view CancelOperationOutcomeView) RecoveryError() (CancelOperationRecoveryError, bool) {
	return view.recoveryError, view.recoveryError != nil
}

// InspectCancelOperationOutcome validates an interface value by exact generated
// concrete type before exposing a semantic view.
func InspectCancelOperationOutcome(outcome CancelOperationOutcome) (CancelOperationOutcomeView, error) {
	switch value := outcome.(type) {
	case cancelOperationAccepted:
		if value.OperationID() != "operation.cancel.operation" ||
			value.Branch() != "accepted" ||
			value.carrier.CarrierKind() != "existingOperationObservation" ||
			value.carrier.SchemaStableID() != "result.existing.operation.observation" {
			return CancelOperationOutcomeView{}, invalid()
		}
		return CancelOperationOutcomeView{
			operationID:    value.OperationID(),
			branch:         value.Branch(),
			carrierKind:    value.carrier.CarrierKind(),
			schemaStableID: value.carrier.SchemaStableID(),
		}, nil
	case cancelOperationRecovery:
		if value.OperationID() != "operation.cancel.operation" ||
			value.Branch() != "recovery" {
			return CancelOperationOutcomeView{}, invalid()
		}
		reason, ok := inspectCancelOperationRecoveryError(value.reason)
		if !ok {
			return CancelOperationOutcomeView{}, invalid()
		}
		return CancelOperationOutcomeView{
			operationID:   value.OperationID(),
			branch:        value.Branch(),
			recoveryError: reason,
		}, nil
	case cancelOperationRejected:
		if value.OperationID() != "operation.cancel.operation" ||
			value.Branch() != "rejected" {
			return CancelOperationOutcomeView{}, invalid()
		}
		reason, ok := inspectCancelOperationRequestError(value.reason)
		if !ok {
			return CancelOperationOutcomeView{}, invalid()
		}
		return CancelOperationOutcomeView{
			operationID:  value.OperationID(),
			branch:       value.Branch(),
			requestError: reason,
		}, nil
	default:
		return CancelOperationOutcomeView{}, invalid()
	}
}

func ValidateCancelOperationOutcome(outcome CancelOperationOutcome) error {
	_, err := InspectCancelOperationOutcome(outcome)
	return err
}

func inspectCancelOperationRequestError(reason CancelOperationRequestError) (CancelOperationRequestError, bool) {
	switch value := reason.(type) {
	case cancelOperationRequestErrorRequestInvalidState:
		if value.StableID() != "request.invalid.state" {
			return nil, false
		}
		return value, true
	default:
		return nil, false
	}
}

func inspectCancelOperationRecoveryError(reason CancelOperationRecoveryError) (CancelOperationRecoveryError, bool) {
	switch value := reason.(type) {
	case cancelOperationRecoveryErrorRecoveryIdempotencyExpired:
		if value.StableID() != "recovery.idempotency.expired" {
			return nil, false
		}
		return value, true
	default:
		return nil, false
	}
}

type StartSandboxRequestError interface {
	isStartSandboxRequestError()
	StableID() string
}

type startSandboxRequestErrorRequestInvalidState struct{}

func (startSandboxRequestErrorRequestInvalidState) isStartSandboxRequestError() {}
func (startSandboxRequestErrorRequestInvalidState) StableID() string { return "request.invalid.state" }

type StartSandboxRecoveryError interface {
	isStartSandboxRecoveryError()
	StableID() string
}

type startSandboxRecoveryErrorRecoveryIdempotencyExpired struct{}

func (startSandboxRecoveryErrorRecoveryIdempotencyExpired) isStartSandboxRecoveryError() {}
func (startSandboxRecoveryErrorRecoveryIdempotencyExpired) StableID() string { return "recovery.idempotency.expired" }

type StartSandboxKnownFailure interface {
	isStartSandboxKnownFailure()
	StableID() string
}

type startSandboxKnownFailureFailureRuntimeProvisioning struct{}

func (startSandboxKnownFailureFailureRuntimeProvisioning) isStartSandboxKnownFailure() {}
func (startSandboxKnownFailureFailureRuntimeProvisioning) StableID() string { return "failure.runtime.provisioning" }

type StartSandboxAmbiguity interface {
	isStartSandboxAmbiguity()
	StableID() string
}

type startSandboxAmbiguityAmbiguityRuntimeUnknown struct{}

func (startSandboxAmbiguityAmbiguityRuntimeUnknown) isStartSandboxAmbiguity() {}
func (startSandboxAmbiguityAmbiguityRuntimeUnknown) StableID() string { return "ambiguity.runtime.unknown" }

type startSandboxCarrier struct {
	private struct{}
}

func (startSandboxCarrier) CarrierKind() string {
	return "newDurableOperation"
}

func (startSandboxCarrier) SchemaStableID() string {
	return "result.operation.start.sandbox"
}

// StartSandboxOutcome is package-marked, not statically sealed. Go interface
// embedding can satisfy private marker methods. Inspect or validate values
// received across a trust boundary before using their semantics.
type StartSandboxOutcome interface {
	isStartSandboxOutcome()
	isAnyOutcome()
}

type StartSandboxAccepted interface {
	StartSandboxOutcome
	isStartSandboxAccepted()
}

type startSandboxAccepted struct {
	carrier startSandboxCarrier
}

func (startSandboxAccepted) isStartSandboxOutcome() {}
func (startSandboxAccepted) isAnyOutcome() {}
func (startSandboxAccepted) isStartSandboxAccepted() {}
func (startSandboxAccepted) Branch() string { return "accepted" }
func (startSandboxAccepted) OperationID() string { return "operation.start.sandbox" }

type StartSandboxRecovery interface {
	StartSandboxOutcome
	isStartSandboxRecovery()
}

type startSandboxRecovery struct {
	reason StartSandboxRecoveryError
}

func (startSandboxRecovery) isStartSandboxOutcome() {}
func (startSandboxRecovery) isAnyOutcome() {}
func (startSandboxRecovery) isStartSandboxRecovery() {}
func (startSandboxRecovery) Branch() string { return "recovery" }
func (startSandboxRecovery) OperationID() string { return "operation.start.sandbox" }

type StartSandboxRejected interface {
	StartSandboxOutcome
	isStartSandboxRejected()
}

type startSandboxRejected struct {
	reason StartSandboxRequestError
}

func (startSandboxRejected) isStartSandboxOutcome() {}
func (startSandboxRejected) isAnyOutcome() {}
func (startSandboxRejected) isStartSandboxRejected() {}
func (startSandboxRejected) Branch() string { return "rejected" }
func (startSandboxRejected) OperationID() string { return "operation.start.sandbox" }

type StartSandboxOutcomeView struct {
	operationID    string
	branch         string
	carrierKind    string
	schemaStableID string
	requestError   StartSandboxRequestError
	recoveryError  StartSandboxRecoveryError
}

func (StartSandboxOutcomeView) isAnyOutcomeView() {}

func (view StartSandboxOutcomeView) OperationID() string {
	return view.operationID
}

func (view StartSandboxOutcomeView) Branch() string {
	return view.branch
}

func (view StartSandboxOutcomeView) CarrierKind() (string, bool) {
	return view.carrierKind, view.carrierKind != ""
}

func (view StartSandboxOutcomeView) SchemaStableID() (string, bool) {
	return view.schemaStableID, view.schemaStableID != ""
}

func (view StartSandboxOutcomeView) RequestError() (StartSandboxRequestError, bool) {
	return view.requestError, view.requestError != nil
}

func (view StartSandboxOutcomeView) RecoveryError() (StartSandboxRecoveryError, bool) {
	return view.recoveryError, view.recoveryError != nil
}

// InspectStartSandboxOutcome validates an interface value by exact generated
// concrete type before exposing a semantic view.
func InspectStartSandboxOutcome(outcome StartSandboxOutcome) (StartSandboxOutcomeView, error) {
	switch value := outcome.(type) {
	case startSandboxAccepted:
		if value.OperationID() != "operation.start.sandbox" ||
			value.Branch() != "accepted" ||
			value.carrier.CarrierKind() != "newDurableOperation" ||
			value.carrier.SchemaStableID() != "result.operation.start.sandbox" {
			return StartSandboxOutcomeView{}, invalid()
		}
		return StartSandboxOutcomeView{
			operationID:    value.OperationID(),
			branch:         value.Branch(),
			carrierKind:    value.carrier.CarrierKind(),
			schemaStableID: value.carrier.SchemaStableID(),
		}, nil
	case startSandboxRecovery:
		if value.OperationID() != "operation.start.sandbox" ||
			value.Branch() != "recovery" {
			return StartSandboxOutcomeView{}, invalid()
		}
		reason, ok := inspectStartSandboxRecoveryError(value.reason)
		if !ok {
			return StartSandboxOutcomeView{}, invalid()
		}
		return StartSandboxOutcomeView{
			operationID:   value.OperationID(),
			branch:        value.Branch(),
			recoveryError: reason,
		}, nil
	case startSandboxRejected:
		if value.OperationID() != "operation.start.sandbox" ||
			value.Branch() != "rejected" {
			return StartSandboxOutcomeView{}, invalid()
		}
		reason, ok := inspectStartSandboxRequestError(value.reason)
		if !ok {
			return StartSandboxOutcomeView{}, invalid()
		}
		return StartSandboxOutcomeView{
			operationID:  value.OperationID(),
			branch:       value.Branch(),
			requestError: reason,
		}, nil
	default:
		return StartSandboxOutcomeView{}, invalid()
	}
}

func ValidateStartSandboxOutcome(outcome StartSandboxOutcome) error {
	_, err := InspectStartSandboxOutcome(outcome)
	return err
}

func inspectStartSandboxRequestError(reason StartSandboxRequestError) (StartSandboxRequestError, bool) {
	switch value := reason.(type) {
	case startSandboxRequestErrorRequestInvalidState:
		if value.StableID() != "request.invalid.state" {
			return nil, false
		}
		return value, true
	default:
		return nil, false
	}
}

func inspectStartSandboxRecoveryError(reason StartSandboxRecoveryError) (StartSandboxRecoveryError, bool) {
	switch value := reason.(type) {
	case startSandboxRecoveryErrorRecoveryIdempotencyExpired:
		if value.StableID() != "recovery.idempotency.expired" {
			return nil, false
		}
		return value, true
	default:
		return nil, false
	}
}

type WaitOperationRequestError interface {
	isWaitOperationRequestError()
	StableID() string
}

type waitOperationRequestErrorRequestInvalidState struct{}

func (waitOperationRequestErrorRequestInvalidState) isWaitOperationRequestError() {}
func (waitOperationRequestErrorRequestInvalidState) StableID() string { return "request.invalid.state" }

type WaitOperationRecoveryError interface {
	isWaitOperationRecoveryError()
	StableID() string
}



type WaitOperationKnownFailure interface {
	isWaitOperationKnownFailure()
	StableID() string
}



type WaitOperationAmbiguity interface {
	isWaitOperationAmbiguity()
	StableID() string
}



type waitOperationCarrier struct {
	private struct{}
}

func (waitOperationCarrier) CarrierKind() string {
	return "observation"
}

func (waitOperationCarrier) SchemaStableID() string {
	return "result.operation.wait.observation"
}

// WaitOperationOutcome is package-marked, not statically sealed. Go interface
// embedding can satisfy private marker methods. Inspect or validate values
// received across a trust boundary before using their semantics.
type WaitOperationOutcome interface {
	isWaitOperationOutcome()
	isAnyOutcome()
}

type WaitOperationObserved interface {
	WaitOperationOutcome
	isWaitOperationObserved()
}

type waitOperationObserved struct {
	carrier waitOperationCarrier
}

func (waitOperationObserved) isWaitOperationOutcome() {}
func (waitOperationObserved) isAnyOutcome() {}
func (waitOperationObserved) isWaitOperationObserved() {}
func (waitOperationObserved) Branch() string { return "observed" }
func (waitOperationObserved) OperationID() string { return "operation.wait.operation" }

type WaitOperationRejected interface {
	WaitOperationOutcome
	isWaitOperationRejected()
}

type waitOperationRejected struct {
	reason WaitOperationRequestError
}

func (waitOperationRejected) isWaitOperationOutcome() {}
func (waitOperationRejected) isAnyOutcome() {}
func (waitOperationRejected) isWaitOperationRejected() {}
func (waitOperationRejected) Branch() string { return "rejected" }
func (waitOperationRejected) OperationID() string { return "operation.wait.operation" }

type WaitOperationOutcomeView struct {
	operationID    string
	branch         string
	carrierKind    string
	schemaStableID string
	requestError   WaitOperationRequestError
	recoveryError  WaitOperationRecoveryError
}

func (WaitOperationOutcomeView) isAnyOutcomeView() {}

func (view WaitOperationOutcomeView) OperationID() string {
	return view.operationID
}

func (view WaitOperationOutcomeView) Branch() string {
	return view.branch
}

func (view WaitOperationOutcomeView) CarrierKind() (string, bool) {
	return view.carrierKind, view.carrierKind != ""
}

func (view WaitOperationOutcomeView) SchemaStableID() (string, bool) {
	return view.schemaStableID, view.schemaStableID != ""
}

func (view WaitOperationOutcomeView) RequestError() (WaitOperationRequestError, bool) {
	return view.requestError, view.requestError != nil
}

func (view WaitOperationOutcomeView) RecoveryError() (WaitOperationRecoveryError, bool) {
	return view.recoveryError, view.recoveryError != nil
}

// InspectWaitOperationOutcome validates an interface value by exact generated
// concrete type before exposing a semantic view.
func InspectWaitOperationOutcome(outcome WaitOperationOutcome) (WaitOperationOutcomeView, error) {
	switch value := outcome.(type) {
	case waitOperationObserved:
		if value.OperationID() != "operation.wait.operation" ||
			value.Branch() != "observed" ||
			value.carrier.CarrierKind() != "observation" ||
			value.carrier.SchemaStableID() != "result.operation.wait.observation" {
			return WaitOperationOutcomeView{}, invalid()
		}
		return WaitOperationOutcomeView{
			operationID:    value.OperationID(),
			branch:         value.Branch(),
			carrierKind:    value.carrier.CarrierKind(),
			schemaStableID: value.carrier.SchemaStableID(),
		}, nil
	case waitOperationRejected:
		if value.OperationID() != "operation.wait.operation" ||
			value.Branch() != "rejected" {
			return WaitOperationOutcomeView{}, invalid()
		}
		reason, ok := inspectWaitOperationRequestError(value.reason)
		if !ok {
			return WaitOperationOutcomeView{}, invalid()
		}
		return WaitOperationOutcomeView{
			operationID:  value.OperationID(),
			branch:       value.Branch(),
			requestError: reason,
		}, nil
	default:
		return WaitOperationOutcomeView{}, invalid()
	}
}

func ValidateWaitOperationOutcome(outcome WaitOperationOutcome) error {
	_, err := InspectWaitOperationOutcome(outcome)
	return err
}

func inspectWaitOperationRequestError(reason WaitOperationRequestError) (WaitOperationRequestError, bool) {
	switch value := reason.(type) {
	case waitOperationRequestErrorRequestInvalidState:
		if value.StableID() != "request.invalid.state" {
			return nil, false
		}
		return value, true
	default:
		return nil, false
	}
}

func inspectWaitOperationRecoveryError(WaitOperationRecoveryError) (WaitOperationRecoveryError, bool) {
	return nil, false
}

type WriteProcessInputRequestError interface {
	isWriteProcessInputRequestError()
	StableID() string
}

type writeProcessInputRequestErrorRequestInvalidState struct{}

func (writeProcessInputRequestErrorRequestInvalidState) isWriteProcessInputRequestError() {}
func (writeProcessInputRequestErrorRequestInvalidState) StableID() string { return "request.invalid.state" }

type writeProcessInputRequestErrorRequestSequenceOutOfRange struct{}

func (writeProcessInputRequestErrorRequestSequenceOutOfRange) isWriteProcessInputRequestError() {}
func (writeProcessInputRequestErrorRequestSequenceOutOfRange) StableID() string { return "request.sequence.out.of.range" }

type WriteProcessInputRecoveryError interface {
	isWriteProcessInputRecoveryError()
	StableID() string
}

type writeProcessInputRecoveryErrorRecoveryIdempotencyExpired struct{}

func (writeProcessInputRecoveryErrorRecoveryIdempotencyExpired) isWriteProcessInputRecoveryError() {}
func (writeProcessInputRecoveryErrorRecoveryIdempotencyExpired) StableID() string { return "recovery.idempotency.expired" }

type WriteProcessInputKnownFailure interface {
	isWriteProcessInputKnownFailure()
	StableID() string
}



type WriteProcessInputAmbiguity interface {
	isWriteProcessInputAmbiguity()
	StableID() string
}

type writeProcessInputAmbiguityAmbiguityRuntimeUnknown struct{}

func (writeProcessInputAmbiguityAmbiguityRuntimeUnknown) isWriteProcessInputAmbiguity() {}
func (writeProcessInputAmbiguityAmbiguityRuntimeUnknown) StableID() string { return "ambiguity.runtime.unknown" }

type writeProcessInputCarrier struct {
	private struct{}
}

func (writeProcessInputCarrier) CarrierKind() string {
	return "processControlReceipt"
}

func (writeProcessInputCarrier) SchemaStableID() string {
	return "result.process.control.receipt"
}

// WriteProcessInputOutcome is package-marked, not statically sealed. Go interface
// embedding can satisfy private marker methods. Inspect or validate values
// received across a trust boundary before using their semantics.
type WriteProcessInputOutcome interface {
	isWriteProcessInputOutcome()
	isAnyOutcome()
}

type WriteProcessInputAccepted interface {
	WriteProcessInputOutcome
	isWriteProcessInputAccepted()
}

type writeProcessInputAccepted struct {
	carrier writeProcessInputCarrier
}

func (writeProcessInputAccepted) isWriteProcessInputOutcome() {}
func (writeProcessInputAccepted) isAnyOutcome() {}
func (writeProcessInputAccepted) isWriteProcessInputAccepted() {}
func (writeProcessInputAccepted) Branch() string { return "accepted" }
func (writeProcessInputAccepted) OperationID() string { return "operation.write.process.input" }

type WriteProcessInputRecovery interface {
	WriteProcessInputOutcome
	isWriteProcessInputRecovery()
}

type writeProcessInputRecovery struct {
	reason WriteProcessInputRecoveryError
}

func (writeProcessInputRecovery) isWriteProcessInputOutcome() {}
func (writeProcessInputRecovery) isAnyOutcome() {}
func (writeProcessInputRecovery) isWriteProcessInputRecovery() {}
func (writeProcessInputRecovery) Branch() string { return "recovery" }
func (writeProcessInputRecovery) OperationID() string { return "operation.write.process.input" }

type WriteProcessInputRejected interface {
	WriteProcessInputOutcome
	isWriteProcessInputRejected()
}

type writeProcessInputRejected struct {
	reason WriteProcessInputRequestError
}

func (writeProcessInputRejected) isWriteProcessInputOutcome() {}
func (writeProcessInputRejected) isAnyOutcome() {}
func (writeProcessInputRejected) isWriteProcessInputRejected() {}
func (writeProcessInputRejected) Branch() string { return "rejected" }
func (writeProcessInputRejected) OperationID() string { return "operation.write.process.input" }

type WriteProcessInputOutcomeView struct {
	operationID    string
	branch         string
	carrierKind    string
	schemaStableID string
	requestError   WriteProcessInputRequestError
	recoveryError  WriteProcessInputRecoveryError
}

func (WriteProcessInputOutcomeView) isAnyOutcomeView() {}

func (view WriteProcessInputOutcomeView) OperationID() string {
	return view.operationID
}

func (view WriteProcessInputOutcomeView) Branch() string {
	return view.branch
}

func (view WriteProcessInputOutcomeView) CarrierKind() (string, bool) {
	return view.carrierKind, view.carrierKind != ""
}

func (view WriteProcessInputOutcomeView) SchemaStableID() (string, bool) {
	return view.schemaStableID, view.schemaStableID != ""
}

func (view WriteProcessInputOutcomeView) RequestError() (WriteProcessInputRequestError, bool) {
	return view.requestError, view.requestError != nil
}

func (view WriteProcessInputOutcomeView) RecoveryError() (WriteProcessInputRecoveryError, bool) {
	return view.recoveryError, view.recoveryError != nil
}

// InspectWriteProcessInputOutcome validates an interface value by exact generated
// concrete type before exposing a semantic view.
func InspectWriteProcessInputOutcome(outcome WriteProcessInputOutcome) (WriteProcessInputOutcomeView, error) {
	switch value := outcome.(type) {
	case writeProcessInputAccepted:
		if value.OperationID() != "operation.write.process.input" ||
			value.Branch() != "accepted" ||
			value.carrier.CarrierKind() != "processControlReceipt" ||
			value.carrier.SchemaStableID() != "result.process.control.receipt" {
			return WriteProcessInputOutcomeView{}, invalid()
		}
		return WriteProcessInputOutcomeView{
			operationID:    value.OperationID(),
			branch:         value.Branch(),
			carrierKind:    value.carrier.CarrierKind(),
			schemaStableID: value.carrier.SchemaStableID(),
		}, nil
	case writeProcessInputRecovery:
		if value.OperationID() != "operation.write.process.input" ||
			value.Branch() != "recovery" {
			return WriteProcessInputOutcomeView{}, invalid()
		}
		reason, ok := inspectWriteProcessInputRecoveryError(value.reason)
		if !ok {
			return WriteProcessInputOutcomeView{}, invalid()
		}
		return WriteProcessInputOutcomeView{
			operationID:   value.OperationID(),
			branch:        value.Branch(),
			recoveryError: reason,
		}, nil
	case writeProcessInputRejected:
		if value.OperationID() != "operation.write.process.input" ||
			value.Branch() != "rejected" {
			return WriteProcessInputOutcomeView{}, invalid()
		}
		reason, ok := inspectWriteProcessInputRequestError(value.reason)
		if !ok {
			return WriteProcessInputOutcomeView{}, invalid()
		}
		return WriteProcessInputOutcomeView{
			operationID:  value.OperationID(),
			branch:       value.Branch(),
			requestError: reason,
		}, nil
	default:
		return WriteProcessInputOutcomeView{}, invalid()
	}
}

func ValidateWriteProcessInputOutcome(outcome WriteProcessInputOutcome) error {
	_, err := InspectWriteProcessInputOutcome(outcome)
	return err
}

func inspectWriteProcessInputRequestError(reason WriteProcessInputRequestError) (WriteProcessInputRequestError, bool) {
	switch value := reason.(type) {
	case writeProcessInputRequestErrorRequestInvalidState:
		if value.StableID() != "request.invalid.state" {
			return nil, false
		}
		return value, true
	case writeProcessInputRequestErrorRequestSequenceOutOfRange:
		if value.StableID() != "request.sequence.out.of.range" {
			return nil, false
		}
		return value, true
	default:
		return nil, false
	}
}

func inspectWriteProcessInputRecoveryError(reason WriteProcessInputRecoveryError) (WriteProcessInputRecoveryError, bool) {
	switch value := reason.(type) {
	case writeProcessInputRecoveryErrorRecoveryIdempotencyExpired:
		if value.StableID() != "recovery.idempotency.expired" {
			return nil, false
		}
		return value, true
	default:
		return nil, false
	}
}


// AnyOutcome is package-marked, not statically sealed. Go interface
// embedding can satisfy private marker methods. Inspect or validate values
// received across a trust boundary before using their semantics.
type AnyOutcome interface {
	isAnyOutcome()
}

type AnyOutcomeView interface {
	isAnyOutcomeView()
	Branch() string
	OperationID() string
}

var (
	_ AnyOutcome = (CancelOperationOutcome)(nil)
	_ AnyOutcome = (StartSandboxOutcome)(nil)
	_ AnyOutcome = (WaitOperationOutcome)(nil)
	_ AnyOutcome = (WriteProcessInputOutcome)(nil)
)

// InspectOutcome accepts only exact generated private concrete outcome types.
func InspectOutcome(outcome AnyOutcome) (AnyOutcomeView, error) {
	switch value := outcome.(type) {
	case cancelOperationAccepted:
		view, err := InspectCancelOperationOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case cancelOperationRecovery:
		view, err := InspectCancelOperationOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case cancelOperationRejected:
		view, err := InspectCancelOperationOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case startSandboxAccepted:
		view, err := InspectStartSandboxOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case startSandboxRecovery:
		view, err := InspectStartSandboxOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case startSandboxRejected:
		view, err := InspectStartSandboxOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case waitOperationObserved:
		view, err := InspectWaitOperationOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case waitOperationRejected:
		view, err := InspectWaitOperationOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case writeProcessInputAccepted:
		view, err := InspectWriteProcessInputOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case writeProcessInputRecovery:
		view, err := InspectWriteProcessInputOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	case writeProcessInputRejected:
		view, err := InspectWriteProcessInputOutcome(value)
		if err != nil {
			return nil, err
		}
		return view, nil
	default:
		return nil, invalid()
	}
}

func ValidateOutcome(outcome AnyOutcome) error {
	_, err := InspectOutcome(outcome)
	return err
}

type PacketEService interface {
	CancelOperation() CancelOperationOutcome
	StartSandbox() StartSandboxOutcome
	WaitOperation() WaitOperationOutcome
	WriteProcessInput() WriteProcessInputOutcome
}

func DecodeCancelOperationOutcome(data []byte) (CancelOperationOutcome, error) {
	fields, err := parseFlatObject(data)
	if err != nil {
		return nil, err
	}
	if err := expectValue(fields, "operationId", "operation.cancel.operation"); err != nil {
		return nil, err
	}
	switch fields["branch"] {
	case "accepted":
		if err := expectKeys(fields, "operationId", "branch", "carrierKind", "schemaStableId"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "carrierKind", "existingOperationObservation"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "schemaStableId", "result.existing.operation.observation"); err != nil {
			return nil, err
		}
		return cancelOperationAccepted{carrier: newCancelOperationCarrier()}, nil
	case "recovery":
		if err := expectKeys(fields, "operationId", "branch", "recoveryErrorId"); err != nil {
			return nil, err
		}
		var reason CancelOperationRecoveryError
		switch fields["recoveryErrorId"] {
		case "recovery.idempotency.expired":
			reason = cancelOperationRecoveryErrorRecoveryIdempotencyExpired{}
		default:
			return nil, invalid()
		}
		return cancelOperationRecovery{reason: reason}, nil
	case "rejected":
		if err := expectKeys(fields, "operationId", "branch", "requestErrorId"); err != nil {
			return nil, err
		}
		var reason CancelOperationRequestError
		switch fields["requestErrorId"] {
		case "request.invalid.state":
			reason = cancelOperationRequestErrorRequestInvalidState{}
		default:
			return nil, invalid()
		}
		return cancelOperationRejected{reason: reason}, nil
	default:
		return nil, invalid()
	}
}

func newCancelOperationCarrier() cancelOperationCarrier {
	return cancelOperationCarrier{}
}
func DecodeStartSandboxOutcome(data []byte) (StartSandboxOutcome, error) {
	fields, err := parseFlatObject(data)
	if err != nil {
		return nil, err
	}
	if err := expectValue(fields, "operationId", "operation.start.sandbox"); err != nil {
		return nil, err
	}
	switch fields["branch"] {
	case "accepted":
		if err := expectKeys(fields, "operationId", "branch", "carrierKind", "schemaStableId"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "carrierKind", "newDurableOperation"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "schemaStableId", "result.operation.start.sandbox"); err != nil {
			return nil, err
		}
		return startSandboxAccepted{carrier: newStartSandboxCarrier()}, nil
	case "recovery":
		if err := expectKeys(fields, "operationId", "branch", "recoveryErrorId"); err != nil {
			return nil, err
		}
		var reason StartSandboxRecoveryError
		switch fields["recoveryErrorId"] {
		case "recovery.idempotency.expired":
			reason = startSandboxRecoveryErrorRecoveryIdempotencyExpired{}
		default:
			return nil, invalid()
		}
		return startSandboxRecovery{reason: reason}, nil
	case "rejected":
		if err := expectKeys(fields, "operationId", "branch", "requestErrorId"); err != nil {
			return nil, err
		}
		var reason StartSandboxRequestError
		switch fields["requestErrorId"] {
		case "request.invalid.state":
			reason = startSandboxRequestErrorRequestInvalidState{}
		default:
			return nil, invalid()
		}
		return startSandboxRejected{reason: reason}, nil
	default:
		return nil, invalid()
	}
}

func newStartSandboxCarrier() startSandboxCarrier {
	return startSandboxCarrier{}
}
func DecodeWaitOperationOutcome(data []byte) (WaitOperationOutcome, error) {
	fields, err := parseFlatObject(data)
	if err != nil {
		return nil, err
	}
	if err := expectValue(fields, "operationId", "operation.wait.operation"); err != nil {
		return nil, err
	}
	switch fields["branch"] {
	case "observed":
		if err := expectKeys(fields, "operationId", "branch", "carrierKind", "schemaStableId"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "carrierKind", "observation"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "schemaStableId", "result.operation.wait.observation"); err != nil {
			return nil, err
		}
		return waitOperationObserved{carrier: newWaitOperationCarrier()}, nil
	case "rejected":
		if err := expectKeys(fields, "operationId", "branch", "requestErrorId"); err != nil {
			return nil, err
		}
		var reason WaitOperationRequestError
		switch fields["requestErrorId"] {
		case "request.invalid.state":
			reason = waitOperationRequestErrorRequestInvalidState{}
		default:
			return nil, invalid()
		}
		return waitOperationRejected{reason: reason}, nil
	default:
		return nil, invalid()
	}
}

func newWaitOperationCarrier() waitOperationCarrier {
	return waitOperationCarrier{}
}
func DecodeWriteProcessInputOutcome(data []byte) (WriteProcessInputOutcome, error) {
	fields, err := parseFlatObject(data)
	if err != nil {
		return nil, err
	}
	if err := expectValue(fields, "operationId", "operation.write.process.input"); err != nil {
		return nil, err
	}
	switch fields["branch"] {
	case "accepted":
		if err := expectKeys(fields, "operationId", "branch", "carrierKind", "schemaStableId"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "carrierKind", "processControlReceipt"); err != nil {
			return nil, err
		}
		if err := expectValue(fields, "schemaStableId", "result.process.control.receipt"); err != nil {
			return nil, err
		}
		return writeProcessInputAccepted{carrier: newWriteProcessInputCarrier()}, nil
	case "recovery":
		if err := expectKeys(fields, "operationId", "branch", "recoveryErrorId"); err != nil {
			return nil, err
		}
		var reason WriteProcessInputRecoveryError
		switch fields["recoveryErrorId"] {
		case "recovery.idempotency.expired":
			reason = writeProcessInputRecoveryErrorRecoveryIdempotencyExpired{}
		default:
			return nil, invalid()
		}
		return writeProcessInputRecovery{reason: reason}, nil
	case "rejected":
		if err := expectKeys(fields, "operationId", "branch", "requestErrorId"); err != nil {
			return nil, err
		}
		var reason WriteProcessInputRequestError
		switch fields["requestErrorId"] {
		case "request.invalid.state":
			reason = writeProcessInputRequestErrorRequestInvalidState{}
		case "request.sequence.out.of.range":
			reason = writeProcessInputRequestErrorRequestSequenceOutOfRange{}
		default:
			return nil, invalid()
		}
		return writeProcessInputRejected{reason: reason}, nil
	default:
		return nil, invalid()
	}
}

func newWriteProcessInputCarrier() writeProcessInputCarrier {
	return writeProcessInputCarrier{}
}

func DecodeOutcome(data []byte) (AnyOutcome, error) {
	fields, err := parseFlatObject(data)
	if err != nil {
		return nil, err
	}
	switch fields["operationId"] {
	case "operation.cancel.operation":
		return DecodeCancelOperationOutcome(data)
	case "operation.start.sandbox":
		return DecodeStartSandboxOutcome(data)
	case "operation.wait.operation":
		return DecodeWaitOperationOutcome(data)
	case "operation.write.process.input":
		return DecodeWriteProcessInputOutcome(data)
	default:
		return nil, invalid()
	}
}

func parseFlatObject(data []byte) (map[string]string, error) {
	decoder := json.NewDecoder(bytes.NewReader(data))
	token, err := decoder.Token()
	if err != nil || token != json.Delim('{') {
		return nil, invalid()
	}
	fields := make(map[string]string)
	for decoder.More() {
		token, err = decoder.Token()
		if err != nil {
			return nil, invalid()
		}
		key, ok := token.(string)
		if !ok {
			return nil, invalid()
		}
		if _, exists := fields[key]; exists {
			return nil, invalid()
		}
		var value string
		if err := decoder.Decode(&value); err != nil {
			return nil, invalid()
		}
		fields[key] = value
	}
	token, err = decoder.Token()
	if err != nil || token != json.Delim('}') {
		return nil, invalid()
	}
	if token, err = decoder.Token(); err != io.EOF || token != nil {
		return nil, invalid()
	}
	return fields, nil
}

func expectKeys(fields map[string]string, expected ...string) error {
	if len(fields) != len(expected) {
		return invalid()
	}
	for _, key := range expected {
		if _, ok := fields[key]; !ok {
			return invalid()
		}
	}
	return nil
}

func expectValue(fields map[string]string, key string, expected string) error {
	if fields[key] != expected {
		return invalid()
	}
	return nil
}
