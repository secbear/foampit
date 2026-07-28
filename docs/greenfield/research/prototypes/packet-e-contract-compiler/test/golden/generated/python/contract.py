from __future__ import annotations

from dataclasses import dataclass
from enum import Enum
from typing import Final, Literal, Never, Protocol, TypeAlias, cast

INVALID_OUTCOME: Final = "contract/invalid-outcome"
_CONSTRUCTION_TOKEN: Final = object()


class ContractDiagnostic(ValueError):
    category: Final = INVALID_OUTCOME

    def __init__(self) -> None:
        super().__init__(INVALID_OUTCOME)


def _invalid() -> ContractDiagnostic:
    return ContractDiagnostic()


def _require(condition: bool) -> None:
    if not condition:
        raise _invalid()


class RegistryAmbiguity(Enum):
    AMBIGUITY_RUNTIME_UNKNOWN = ("ambiguity.runtime.unknown", "1")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryCallerRecovery(Enum):
    CALLER_RECOVERY_RETRY = ("caller.recovery.retry", "1")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryCoreResolution(Enum):
    CORE_RESOLUTION_RECONCILE = ("core.resolution.reconcile", "1")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryKnownFailure(Enum):
    FAILURE_RUNTIME_PROVISIONING = ("failure.runtime.provisioning", "1")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryOperationOutcome(Enum):
    OUTCOME_ACCEPTED = ("outcome.accepted", "1")
    OUTCOME_OBSERVED = ("outcome.observed", "4")
    OUTCOME_RECOVERY = ("outcome.recovery", "3")
    OUTCOME_REJECTED = ("outcome.rejected", "2")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryProcessControlOutcome(Enum):
    OUTCOME_PROCESS_ACCEPTED = ("outcome.process.accepted", "1")
    OUTCOME_PROCESS_RECOVERY = ("outcome.process.recovery", "3")
    OUTCOME_PROCESS_REJECTED = ("outcome.process.rejected", "2")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryProcessTermination(Enum):
    PROCESS_TERMINATION_EXITED = ("process.termination.exited", "1")
    PROCESS_TERMINATION_SIGNALLED = ("process.termination.signalled", "2")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryProviderEvidence(Enum):
    PROVIDER_EVIDENCE_OBSERVED = ("provider.evidence.observed", "1")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryRecoveryError(Enum):
    RECOVERY_IDEMPOTENCY_EXPIRED = ("recovery.idempotency.expired", "1")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryRequestError(Enum):
    REQUEST_INVALID_STATE = ("request.invalid.state", "1")
    REQUEST_SEQUENCE_OUT_OF_RANGE = ("request.sequence.out.of.range", "2")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class RegistryTransportError(Enum):
    TRANSPORT_ERROR_UNAVAILABLE = ("transport.error.unavailable", "1")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class StateOperation(Enum):
    STATE_OPERATION_ACCEPTED = ("state.operation.accepted", "1")
    STATE_OPERATION_CANCEL_REQUESTED = ("state.operation.cancel.requested", "3")
    STATE_OPERATION_CANCELLED = ("state.operation.cancelled", "6")
    STATE_OPERATION_FAILED = ("state.operation.failed", "5")
    STATE_OPERATION_RUNNING = ("state.operation.running", "2")
    STATE_OPERATION_SUCCEEDED = ("state.operation.succeeded", "4")
    STATE_OPERATION_UNKNOWN = ("state.operation.unknown", "7")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class StateProcess(Enum):
    STATE_PROCESS_ACCEPTED = ("state.process.accepted", "1")
    STATE_PROCESS_RUNNING = ("state.process.running", "3")
    STATE_PROCESS_STARTING = ("state.process.starting", "2")
    STATE_PROCESS_TERMINATED = ("state.process.terminated", "5")
    STATE_PROCESS_UNKNOWN = ("state.process.unknown", "4")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag


class StateSandbox(Enum):
    STATE_SANDBOX_PROVISIONING = ("state.sandbox.provisioning", "2")
    STATE_SANDBOX_RUNNING = ("state.sandbox.running", "3")
    STATE_SANDBOX_STOPPED = ("state.sandbox.stopped", "1")
    STATE_SANDBOX_UNKNOWN = ("state.sandbox.unknown", "4")

    def __init__(self, stable_id: str, wire_tag: str) -> None:
        self._stable_id = stable_id
        self._wire_tag = wire_tag

    @property
    def stable_id(self) -> str:
        return self._stable_id

    @property
    def wire_tag(self) -> str:
        return self._wire_tag

OperationId: TypeAlias = Literal["operation.cancel.operation", "operation.start.sandbox", "operation.wait.operation", "operation.write.process.input"]

class CancelOperationRequestError(Enum):
    REQUEST_INVALID_STATE = "request.invalid.state"

class CancelOperationRecoveryError(Enum):
    RECOVERY_IDEMPOTENCY_EXPIRED = "recovery.idempotency.expired"

CancelOperationKnownFailure: TypeAlias = Never

class CancelOperationAmbiguity(Enum):
    AMBIGUITY_RUNTIME_UNKNOWN = "ambiguity.runtime.unknown"

@dataclass(frozen=True, slots=True, init=False)
class CancelOperationCarrier:
    def __init__(self, token: object) -> None:
        _require(token is _CONSTRUCTION_TOKEN)

    @classmethod
    def _create(cls) -> CancelOperationCarrier:
        return cls(_CONSTRUCTION_TOKEN)

    @property
    def carrier_kind(self) -> str:
        return "existingOperationObservation"

    @property
    def schema_stable_id(self) -> str:
        return "result.existing.operation.observation"


@dataclass(frozen=True, slots=True)
class CancelOperationAccepted:
    operation_id: str
    branch: str
    carrier: CancelOperationCarrier

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.cancel.operation")
        _require(type(self.branch) is str and self.branch == "accepted")
        _require(type(self.carrier) is CancelOperationCarrier)

    @property
    def carrier_kind(self) -> str:
        return self.carrier.carrier_kind

    @property
    def schema_stable_id(self) -> str:
        return self.carrier.schema_stable_id


@dataclass(frozen=True, slots=True)
class CancelOperationRecovery:
    operation_id: str
    branch: str
    recovery_error_id: CancelOperationRecoveryError

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.cancel.operation")
        _require(type(self.branch) is str and self.branch == "recovery")
        _require(type(self.recovery_error_id) is CancelOperationRecoveryError)


@dataclass(frozen=True, slots=True)
class CancelOperationRejected:
    operation_id: str
    branch: str
    request_error_id: CancelOperationRequestError

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.cancel.operation")
        _require(type(self.branch) is str and self.branch == "rejected")
        _require(type(self.request_error_id) is CancelOperationRequestError)

CancelOperationOutcome: TypeAlias = CancelOperationAccepted | CancelOperationRecovery | CancelOperationRejected

class StartSandboxRequestError(Enum):
    REQUEST_INVALID_STATE = "request.invalid.state"

class StartSandboxRecoveryError(Enum):
    RECOVERY_IDEMPOTENCY_EXPIRED = "recovery.idempotency.expired"

class StartSandboxKnownFailure(Enum):
    FAILURE_RUNTIME_PROVISIONING = "failure.runtime.provisioning"

class StartSandboxAmbiguity(Enum):
    AMBIGUITY_RUNTIME_UNKNOWN = "ambiguity.runtime.unknown"

@dataclass(frozen=True, slots=True, init=False)
class StartSandboxCarrier:
    def __init__(self, token: object) -> None:
        _require(token is _CONSTRUCTION_TOKEN)

    @classmethod
    def _create(cls) -> StartSandboxCarrier:
        return cls(_CONSTRUCTION_TOKEN)

    @property
    def carrier_kind(self) -> str:
        return "newDurableOperation"

    @property
    def schema_stable_id(self) -> str:
        return "result.operation.start.sandbox"


@dataclass(frozen=True, slots=True)
class StartSandboxAccepted:
    operation_id: str
    branch: str
    carrier: StartSandboxCarrier

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.start.sandbox")
        _require(type(self.branch) is str and self.branch == "accepted")
        _require(type(self.carrier) is StartSandboxCarrier)

    @property
    def carrier_kind(self) -> str:
        return self.carrier.carrier_kind

    @property
    def schema_stable_id(self) -> str:
        return self.carrier.schema_stable_id


@dataclass(frozen=True, slots=True)
class StartSandboxRecovery:
    operation_id: str
    branch: str
    recovery_error_id: StartSandboxRecoveryError

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.start.sandbox")
        _require(type(self.branch) is str and self.branch == "recovery")
        _require(type(self.recovery_error_id) is StartSandboxRecoveryError)


@dataclass(frozen=True, slots=True)
class StartSandboxRejected:
    operation_id: str
    branch: str
    request_error_id: StartSandboxRequestError

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.start.sandbox")
        _require(type(self.branch) is str and self.branch == "rejected")
        _require(type(self.request_error_id) is StartSandboxRequestError)

StartSandboxOutcome: TypeAlias = StartSandboxAccepted | StartSandboxRecovery | StartSandboxRejected

class WaitOperationRequestError(Enum):
    REQUEST_INVALID_STATE = "request.invalid.state"

WaitOperationRecoveryError: TypeAlias = Never

WaitOperationKnownFailure: TypeAlias = Never

WaitOperationAmbiguity: TypeAlias = Never

@dataclass(frozen=True, slots=True, init=False)
class WaitOperationCarrier:
    def __init__(self, token: object) -> None:
        _require(token is _CONSTRUCTION_TOKEN)

    @classmethod
    def _create(cls) -> WaitOperationCarrier:
        return cls(_CONSTRUCTION_TOKEN)

    @property
    def carrier_kind(self) -> str:
        return "observation"

    @property
    def schema_stable_id(self) -> str:
        return "result.operation.wait.observation"


@dataclass(frozen=True, slots=True)
class WaitOperationObserved:
    operation_id: str
    branch: str
    carrier: WaitOperationCarrier

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.wait.operation")
        _require(type(self.branch) is str and self.branch == "observed")
        _require(type(self.carrier) is WaitOperationCarrier)

    @property
    def carrier_kind(self) -> str:
        return self.carrier.carrier_kind

    @property
    def schema_stable_id(self) -> str:
        return self.carrier.schema_stable_id


@dataclass(frozen=True, slots=True)
class WaitOperationRejected:
    operation_id: str
    branch: str
    request_error_id: WaitOperationRequestError

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.wait.operation")
        _require(type(self.branch) is str and self.branch == "rejected")
        _require(type(self.request_error_id) is WaitOperationRequestError)

WaitOperationOutcome: TypeAlias = WaitOperationObserved | WaitOperationRejected

class WriteProcessInputRequestError(Enum):
    REQUEST_INVALID_STATE = "request.invalid.state"
    REQUEST_SEQUENCE_OUT_OF_RANGE = "request.sequence.out.of.range"

class WriteProcessInputRecoveryError(Enum):
    RECOVERY_IDEMPOTENCY_EXPIRED = "recovery.idempotency.expired"

WriteProcessInputKnownFailure: TypeAlias = Never

class WriteProcessInputAmbiguity(Enum):
    AMBIGUITY_RUNTIME_UNKNOWN = "ambiguity.runtime.unknown"

@dataclass(frozen=True, slots=True, init=False)
class WriteProcessInputCarrier:
    def __init__(self, token: object) -> None:
        _require(token is _CONSTRUCTION_TOKEN)

    @classmethod
    def _create(cls) -> WriteProcessInputCarrier:
        return cls(_CONSTRUCTION_TOKEN)

    @property
    def carrier_kind(self) -> str:
        return "processControlReceipt"

    @property
    def schema_stable_id(self) -> str:
        return "result.process.control.receipt"


@dataclass(frozen=True, slots=True)
class WriteProcessInputAccepted:
    operation_id: str
    branch: str
    carrier: WriteProcessInputCarrier

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.write.process.input")
        _require(type(self.branch) is str and self.branch == "accepted")
        _require(type(self.carrier) is WriteProcessInputCarrier)

    @property
    def carrier_kind(self) -> str:
        return self.carrier.carrier_kind

    @property
    def schema_stable_id(self) -> str:
        return self.carrier.schema_stable_id


@dataclass(frozen=True, slots=True)
class WriteProcessInputRecovery:
    operation_id: str
    branch: str
    recovery_error_id: WriteProcessInputRecoveryError

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.write.process.input")
        _require(type(self.branch) is str and self.branch == "recovery")
        _require(type(self.recovery_error_id) is WriteProcessInputRecoveryError)


@dataclass(frozen=True, slots=True)
class WriteProcessInputRejected:
    operation_id: str
    branch: str
    request_error_id: WriteProcessInputRequestError

    def __init_subclass__(cls, **kwargs: object) -> None:
        raise TypeError("contract branch classes are sealed")

    def __post_init__(self) -> None:
        _require(type(self.operation_id) is str and self.operation_id == "operation.write.process.input")
        _require(type(self.branch) is str and self.branch == "rejected")
        _require(type(self.request_error_id) is WriteProcessInputRequestError)

WriteProcessInputOutcome: TypeAlias = WriteProcessInputAccepted | WriteProcessInputRecovery | WriteProcessInputRejected

InvocationOutcome: TypeAlias = CancelOperationOutcome | StartSandboxOutcome | WaitOperationOutcome | WriteProcessInputOutcome


class PacketEService(Protocol):
    def cancel_operation(self) -> CancelOperationOutcome:
        ...

    def start_sandbox(self) -> StartSandboxOutcome:
        ...

    def wait_operation(self) -> WaitOperationOutcome:
        ...

    def write_process_input(self) -> WriteProcessInputOutcome:
        ...


def decode_cancel_operation_outcome(value: object) -> CancelOperationOutcome:
    dict_value = _plain_dict(value)
    _exact_value(dict_value, "operationId", "operation.cancel.operation")
    branch = _string_field(dict_value, "branch")
    if branch == "accepted":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "carrierKind", "schemaStableId")))
        _exact_value(dict_value, "carrierKind", "existingOperationObservation")
        _exact_value(dict_value, "schemaStableId", "result.existing.operation.observation")
        return CancelOperationAccepted(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            carrier=CancelOperationCarrier._create(),
        )
    elif branch == "recovery":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "recoveryErrorId")))
        try:
            reason = CancelOperationRecoveryError(_string_field(dict_value, "recoveryErrorId"))
        except ValueError:
            raise _invalid() from None
        return CancelOperationRecovery(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            recovery_error_id=reason,
        )
    elif branch == "rejected":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "requestErrorId")))
        try:
            reason = CancelOperationRequestError(_string_field(dict_value, "requestErrorId"))
        except ValueError:
            raise _invalid() from None
        return CancelOperationRejected(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            request_error_id=reason,
        )
    raise _invalid()

def decode_start_sandbox_outcome(value: object) -> StartSandboxOutcome:
    dict_value = _plain_dict(value)
    _exact_value(dict_value, "operationId", "operation.start.sandbox")
    branch = _string_field(dict_value, "branch")
    if branch == "accepted":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "carrierKind", "schemaStableId")))
        _exact_value(dict_value, "carrierKind", "newDurableOperation")
        _exact_value(dict_value, "schemaStableId", "result.operation.start.sandbox")
        return StartSandboxAccepted(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            carrier=StartSandboxCarrier._create(),
        )
    elif branch == "recovery":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "recoveryErrorId")))
        try:
            reason = StartSandboxRecoveryError(_string_field(dict_value, "recoveryErrorId"))
        except ValueError:
            raise _invalid() from None
        return StartSandboxRecovery(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            recovery_error_id=reason,
        )
    elif branch == "rejected":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "requestErrorId")))
        try:
            reason = StartSandboxRequestError(_string_field(dict_value, "requestErrorId"))
        except ValueError:
            raise _invalid() from None
        return StartSandboxRejected(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            request_error_id=reason,
        )
    raise _invalid()

def decode_wait_operation_outcome(value: object) -> WaitOperationOutcome:
    dict_value = _plain_dict(value)
    _exact_value(dict_value, "operationId", "operation.wait.operation")
    branch = _string_field(dict_value, "branch")
    if branch == "observed":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "carrierKind", "schemaStableId")))
        _exact_value(dict_value, "carrierKind", "observation")
        _exact_value(dict_value, "schemaStableId", "result.operation.wait.observation")
        return WaitOperationObserved(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            carrier=WaitOperationCarrier._create(),
        )
    elif branch == "rejected":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "requestErrorId")))
        try:
            reason = WaitOperationRequestError(_string_field(dict_value, "requestErrorId"))
        except ValueError:
            raise _invalid() from None
        return WaitOperationRejected(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            request_error_id=reason,
        )
    raise _invalid()

def decode_write_process_input_outcome(value: object) -> WriteProcessInputOutcome:
    dict_value = _plain_dict(value)
    _exact_value(dict_value, "operationId", "operation.write.process.input")
    branch = _string_field(dict_value, "branch")
    if branch == "accepted":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "carrierKind", "schemaStableId")))
        _exact_value(dict_value, "carrierKind", "processControlReceipt")
        _exact_value(dict_value, "schemaStableId", "result.process.control.receipt")
        return WriteProcessInputAccepted(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            carrier=WriteProcessInputCarrier._create(),
        )
    elif branch == "recovery":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "recoveryErrorId")))
        try:
            reason = WriteProcessInputRecoveryError(_string_field(dict_value, "recoveryErrorId"))
        except ValueError:
            raise _invalid() from None
        return WriteProcessInputRecovery(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            recovery_error_id=reason,
        )
    elif branch == "rejected":
        _exact_keys(dict_value, frozenset(("operationId", "branch", "requestErrorId")))
        try:
            reason = WriteProcessInputRequestError(_string_field(dict_value, "requestErrorId"))
        except ValueError:
            raise _invalid() from None
        return WriteProcessInputRejected(
            operation_id=_string_field(dict_value, "operationId"),
            branch=branch,
            request_error_id=reason,
        )
    raise _invalid()

def decode_outcome(value: object) -> InvocationOutcome:
    dict_value = _plain_dict(value)
    operation_id = _string_field(dict_value, "operationId")
    if operation_id == "operation.cancel.operation":
        return decode_cancel_operation_outcome(value)
    elif operation_id == "operation.start.sandbox":
        return decode_start_sandbox_outcome(value)
    elif operation_id == "operation.wait.operation":
        return decode_wait_operation_outcome(value)
    elif operation_id == "operation.write.process.input":
        return decode_write_process_input_outcome(value)
    raise _invalid()


def _plain_dict(value: object) -> dict[str, object]:
    if type(value) is not dict:
        raise _invalid()
    return cast(dict[str, object], value)


def _exact_keys(value: dict[str, object], expected: frozenset[str]) -> None:
    if any(type(key) is not str for key in value) or frozenset(value.keys()) != expected:
        raise _invalid()


def _string_field(value: dict[str, object], key: str) -> str:
    field = value.get(key)
    if type(field) is not str:
        raise _invalid()
    return field


def _exact_value(value: dict[str, object], key: str, expected: str) -> None:
    if _string_field(value, key) != expected:
        raise _invalid()
