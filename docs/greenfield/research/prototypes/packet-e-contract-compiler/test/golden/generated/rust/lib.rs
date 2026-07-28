use std::collections::BTreeMap;
use std::fmt;

pub const INVALID_OUTCOME: &str = "contract/invalid-outcome";

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct ContractDiagnostic {
    category: &'static str,
}

impl ContractDiagnostic {
    pub fn category(&self) -> &'static str {
        self.category
    }
}

impl fmt::Display for ContractDiagnostic {
    fn fmt(&self, formatter: &mut fmt::Formatter<'_>) -> fmt::Result {
        formatter.write_str(self.category)
    }
}

impl std::error::Error for ContractDiagnostic {}

fn invalid() -> ContractDiagnostic {
    ContractDiagnostic { category: INVALID_OUTCOME }
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryAmbiguity {
    AmbiguityRuntimeUnknown = 1,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryCallerRecovery {
    CallerRecoveryRetry = 1,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryCoreResolution {
    CoreResolutionReconcile = 1,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryKnownFailure {
    FailureRuntimeProvisioning = 1,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryOperationOutcome {
    OutcomeAccepted = 1,
    OutcomeObserved = 4,
    OutcomeRecovery = 3,
    OutcomeRejected = 2,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryProcessControlOutcome {
    OutcomeProcessAccepted = 1,
    OutcomeProcessRecovery = 3,
    OutcomeProcessRejected = 2,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryProcessTermination {
    ProcessTerminationExited = 1,
    ProcessTerminationSignalled = 2,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryProviderEvidence {
    ProviderEvidenceObserved = 1,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryRecoveryError {
    RecoveryIdempotencyExpired = 1,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryRequestError {
    RequestInvalidState = 1,
    RequestSequenceOutOfRange = 2,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum RegistryTransportError {
    TransportErrorUnavailable = 1,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum StateOperation {
    StateOperationAccepted = 1,
    StateOperationCancelRequested = 3,
    StateOperationCancelled = 6,
    StateOperationFailed = 5,
    StateOperationRunning = 2,
    StateOperationSucceeded = 4,
    StateOperationUnknown = 7,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum StateProcess {
    StateProcessAccepted = 1,
    StateProcessRunning = 3,
    StateProcessStarting = 2,
    StateProcessTerminated = 5,
    StateProcessUnknown = 4,
}

#[derive(Clone, Copy, Debug, PartialEq, Eq)]
#[repr(u32)]
pub enum StateSandbox {
    StateSandboxProvisioning = 2,
    StateSandboxRunning = 3,
    StateSandboxStopped = 1,
    StateSandboxUnknown = 4,
}

pub const WIRE_IDENTITIES: &[(&str, &str, u32)] = &[
    ("registry.ambiguity", "ambiguity.runtime.unknown", 1),
    ("registry.caller.recovery", "caller.recovery.retry", 1),
    ("registry.core.resolution", "core.resolution.reconcile", 1),
    ("registry.known.failure", "failure.runtime.provisioning", 1),
    ("registry.operation.outcome", "outcome.accepted", 1),
    ("registry.operation.outcome", "outcome.observed", 4),
    ("registry.operation.outcome", "outcome.recovery", 3),
    ("registry.operation.outcome", "outcome.rejected", 2),
    ("registry.process.control.outcome", "outcome.process.accepted", 1),
    ("registry.process.control.outcome", "outcome.process.recovery", 3),
    ("registry.process.control.outcome", "outcome.process.rejected", 2),
    ("registry.process.termination", "process.termination.exited", 1),
    ("registry.process.termination", "process.termination.signalled", 2),
    ("registry.provider.evidence", "provider.evidence.observed", 1),
    ("registry.recovery.error", "recovery.idempotency.expired", 1),
    ("registry.request.error", "request.invalid.state", 1),
    ("registry.request.error", "request.sequence.out.of.range", 2),
    ("registry.transport.error", "transport.error.unavailable", 1),
    ("state.operation", "state.operation.accepted", 1),
    ("state.operation", "state.operation.cancel.requested", 3),
    ("state.operation", "state.operation.cancelled", 6),
    ("state.operation", "state.operation.failed", 5),
    ("state.operation", "state.operation.running", 2),
    ("state.operation", "state.operation.succeeded", 4),
    ("state.operation", "state.operation.unknown", 7),
    ("state.process", "state.process.accepted", 1),
    ("state.process", "state.process.running", 3),
    ("state.process", "state.process.starting", 2),
    ("state.process", "state.process.terminated", 5),
    ("state.process", "state.process.unknown", 4),
    ("state.sandbox", "state.sandbox.provisioning", 2),
    ("state.sandbox", "state.sandbox.running", 3),
    ("state.sandbox", "state.sandbox.stopped", 1),
    ("state.sandbox", "state.sandbox.unknown", 4),
];

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CancelOperationRequestError {
    RequestInvalidState,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CancelOperationRecoveryError {
    RecoveryIdempotencyExpired,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CancelOperationKnownFailure {

}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CancelOperationAmbiguity {
    AmbiguityRuntimeUnknown,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct CancelOperationCarrier {
    private: (),
}

impl CancelOperationCarrier {
    fn new() -> Self {
        Self { private: () }
    }

    pub fn carrier_kind(&self) -> &'static str {
        "existingOperationObservation"
    }

    pub fn schema_stable_id(&self) -> &'static str {
        "result.existing.operation.observation"
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum CancelOperationOutcome {
    Accepted(CancelOperationCarrier),
    Recovery(CancelOperationRecoveryError),
    Rejected(CancelOperationRequestError),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum StartSandboxRequestError {
    RequestInvalidState,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum StartSandboxRecoveryError {
    RecoveryIdempotencyExpired,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum StartSandboxKnownFailure {
    FailureRuntimeProvisioning,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum StartSandboxAmbiguity {
    AmbiguityRuntimeUnknown,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct StartSandboxCarrier {
    private: (),
}

impl StartSandboxCarrier {
    fn new() -> Self {
        Self { private: () }
    }

    pub fn carrier_kind(&self) -> &'static str {
        "newDurableOperation"
    }

    pub fn schema_stable_id(&self) -> &'static str {
        "result.operation.start.sandbox"
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum StartSandboxOutcome {
    Accepted(StartSandboxCarrier),
    Recovery(StartSandboxRecoveryError),
    Rejected(StartSandboxRequestError),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WaitOperationRequestError {
    RequestInvalidState,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WaitOperationRecoveryError {

}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WaitOperationKnownFailure {

}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WaitOperationAmbiguity {

}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WaitOperationCarrier {
    private: (),
}

impl WaitOperationCarrier {
    fn new() -> Self {
        Self { private: () }
    }

    pub fn carrier_kind(&self) -> &'static str {
        "observation"
    }

    pub fn schema_stable_id(&self) -> &'static str {
        "result.operation.wait.observation"
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WaitOperationOutcome {
    Observed(WaitOperationCarrier),
    Rejected(WaitOperationRequestError),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WriteProcessInputRequestError {
    RequestInvalidState,
    RequestSequenceOutOfRange,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WriteProcessInputRecoveryError {
    RecoveryIdempotencyExpired,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WriteProcessInputKnownFailure {

}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WriteProcessInputAmbiguity {
    AmbiguityRuntimeUnknown,
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub struct WriteProcessInputCarrier {
    private: (),
}

impl WriteProcessInputCarrier {
    fn new() -> Self {
        Self { private: () }
    }

    pub fn carrier_kind(&self) -> &'static str {
        "processControlReceipt"
    }

    pub fn schema_stable_id(&self) -> &'static str {
        "result.process.control.receipt"
    }
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum WriteProcessInputOutcome {
    Accepted(WriteProcessInputCarrier),
    Recovery(WriteProcessInputRecoveryError),
    Rejected(WriteProcessInputRequestError),
}

#[derive(Clone, Debug, PartialEq, Eq)]
pub enum AnyOutcome {
    CancelOperation(CancelOperationOutcome),
    StartSandbox(StartSandboxOutcome),
    WaitOperation(WaitOperationOutcome),
    WriteProcessInput(WriteProcessInputOutcome),
}

pub trait PacketEService {
    fn cancel_operation(&self) -> CancelOperationOutcome;
    fn start_sandbox(&self) -> StartSandboxOutcome;
    fn wait_operation(&self) -> WaitOperationOutcome;
    fn write_process_input(&self) -> WriteProcessInputOutcome;
}

pub fn decode_cancel_operation_outcome(input: &[u8]) -> Result<CancelOperationOutcome, ContractDiagnostic> {
    let fields = parse_flat_object(input)?;
    expect_value(&fields, "operationId", "operation.cancel.operation")?;
    match required(&fields, "branch")? {
        "accepted" => {
            expect_keys(&fields, &["operationId", "branch", "carrierKind", "schemaStableId"])?;
            expect_value(&fields, "carrierKind", "existingOperationObservation")?;
            expect_value(&fields, "schemaStableId", "result.existing.operation.observation")?;
            Ok(CancelOperationOutcome::Accepted(CancelOperationCarrier::new()))
        }
        "recovery" => {
            expect_keys(&fields, &["operationId", "branch", "recoveryErrorId"])?;
            let reason = match required(&fields, "recoveryErrorId")? {
                "recovery.idempotency.expired" => CancelOperationRecoveryError::RecoveryIdempotencyExpired,
                _ => return Err(invalid()),
            };
            Ok(CancelOperationOutcome::Recovery(reason))
        }
        "rejected" => {
            expect_keys(&fields, &["operationId", "branch", "requestErrorId"])?;
            let reason = match required(&fields, "requestErrorId")? {
                "request.invalid.state" => CancelOperationRequestError::RequestInvalidState,
                _ => return Err(invalid()),
            };
            Ok(CancelOperationOutcome::Rejected(reason))
        }
        _ => Err(invalid()),
    }
}

pub fn decode_start_sandbox_outcome(input: &[u8]) -> Result<StartSandboxOutcome, ContractDiagnostic> {
    let fields = parse_flat_object(input)?;
    expect_value(&fields, "operationId", "operation.start.sandbox")?;
    match required(&fields, "branch")? {
        "accepted" => {
            expect_keys(&fields, &["operationId", "branch", "carrierKind", "schemaStableId"])?;
            expect_value(&fields, "carrierKind", "newDurableOperation")?;
            expect_value(&fields, "schemaStableId", "result.operation.start.sandbox")?;
            Ok(StartSandboxOutcome::Accepted(StartSandboxCarrier::new()))
        }
        "recovery" => {
            expect_keys(&fields, &["operationId", "branch", "recoveryErrorId"])?;
            let reason = match required(&fields, "recoveryErrorId")? {
                "recovery.idempotency.expired" => StartSandboxRecoveryError::RecoveryIdempotencyExpired,
                _ => return Err(invalid()),
            };
            Ok(StartSandboxOutcome::Recovery(reason))
        }
        "rejected" => {
            expect_keys(&fields, &["operationId", "branch", "requestErrorId"])?;
            let reason = match required(&fields, "requestErrorId")? {
                "request.invalid.state" => StartSandboxRequestError::RequestInvalidState,
                _ => return Err(invalid()),
            };
            Ok(StartSandboxOutcome::Rejected(reason))
        }
        _ => Err(invalid()),
    }
}

pub fn decode_wait_operation_outcome(input: &[u8]) -> Result<WaitOperationOutcome, ContractDiagnostic> {
    let fields = parse_flat_object(input)?;
    expect_value(&fields, "operationId", "operation.wait.operation")?;
    match required(&fields, "branch")? {
        "observed" => {
            expect_keys(&fields, &["operationId", "branch", "carrierKind", "schemaStableId"])?;
            expect_value(&fields, "carrierKind", "observation")?;
            expect_value(&fields, "schemaStableId", "result.operation.wait.observation")?;
            Ok(WaitOperationOutcome::Observed(WaitOperationCarrier::new()))
        }
        "rejected" => {
            expect_keys(&fields, &["operationId", "branch", "requestErrorId"])?;
            let reason = match required(&fields, "requestErrorId")? {
                "request.invalid.state" => WaitOperationRequestError::RequestInvalidState,
                _ => return Err(invalid()),
            };
            Ok(WaitOperationOutcome::Rejected(reason))
        }
        _ => Err(invalid()),
    }
}

pub fn decode_write_process_input_outcome(input: &[u8]) -> Result<WriteProcessInputOutcome, ContractDiagnostic> {
    let fields = parse_flat_object(input)?;
    expect_value(&fields, "operationId", "operation.write.process.input")?;
    match required(&fields, "branch")? {
        "accepted" => {
            expect_keys(&fields, &["operationId", "branch", "carrierKind", "schemaStableId"])?;
            expect_value(&fields, "carrierKind", "processControlReceipt")?;
            expect_value(&fields, "schemaStableId", "result.process.control.receipt")?;
            Ok(WriteProcessInputOutcome::Accepted(WriteProcessInputCarrier::new()))
        }
        "recovery" => {
            expect_keys(&fields, &["operationId", "branch", "recoveryErrorId"])?;
            let reason = match required(&fields, "recoveryErrorId")? {
                "recovery.idempotency.expired" => WriteProcessInputRecoveryError::RecoveryIdempotencyExpired,
                _ => return Err(invalid()),
            };
            Ok(WriteProcessInputOutcome::Recovery(reason))
        }
        "rejected" => {
            expect_keys(&fields, &["operationId", "branch", "requestErrorId"])?;
            let reason = match required(&fields, "requestErrorId")? {
                "request.invalid.state" => WriteProcessInputRequestError::RequestInvalidState,
                "request.sequence.out.of.range" => WriteProcessInputRequestError::RequestSequenceOutOfRange,
                _ => return Err(invalid()),
            };
            Ok(WriteProcessInputOutcome::Rejected(reason))
        }
        _ => Err(invalid()),
    }
}

pub fn decode_outcome(input: &[u8]) -> Result<AnyOutcome, ContractDiagnostic> {
    let fields = parse_flat_object(input)?;
    match required(&fields, "operationId")? {
        "operation.cancel.operation" => decode_cancel_operation_outcome(input).map(AnyOutcome::CancelOperation),
        "operation.start.sandbox" => decode_start_sandbox_outcome(input).map(AnyOutcome::StartSandbox),
        "operation.wait.operation" => decode_wait_operation_outcome(input).map(AnyOutcome::WaitOperation),
        "operation.write.process.input" => decode_write_process_input_outcome(input).map(AnyOutcome::WriteProcessInput),
        _ => Err(invalid()),
    }
}

struct Parser<'a> {
    input: &'a [u8],
    offset: usize,
}

impl<'a> Parser<'a> {
    fn new(input: &'a [u8]) -> Self {
        Self { input, offset: 0 }
    }

    fn whitespace(&mut self) {
        while matches!(self.input.get(self.offset), Some(b' ' | b'\n' | b'\r' | b'\t')) {
            self.offset += 1;
        }
    }

    fn byte(&mut self, expected: u8) -> Result<(), ContractDiagnostic> {
        if self.input.get(self.offset) == Some(&expected) {
            self.offset += 1;
            Ok(())
        } else {
            Err(invalid())
        }
    }

    fn string(&mut self) -> Result<String, ContractDiagnostic> {
        self.byte(b'"')?;
        let mut output = String::new();
        loop {
            let byte = *self.input.get(self.offset).ok_or_else(invalid)?;
            self.offset += 1;
            match byte {
                b'"' => return Ok(output),
                b'\\' => {
                    let escaped = *self.input.get(self.offset).ok_or_else(invalid)?;
                    self.offset += 1;
                    match escaped {
                        b'"' => output.push('"'),
                        b'\\' => output.push('\\'),
                        b'/' => output.push('/'),
                        b'b' => output.push('\u{0008}'),
                        b'f' => output.push('\u{000c}'),
                        b'n' => output.push('\n'),
                        b'r' => output.push('\r'),
                        b't' => output.push('\t'),
                        b'u' => {
                            let mut value = 0_u32;
                            for _ in 0..4 {
                                let digit = *self.input.get(self.offset).ok_or_else(invalid)?;
                                self.offset += 1;
                                value = value * 16 + match digit {
                                    b'0'..=b'9' => u32::from(digit - b'0'),
                                    b'a'..=b'f' => u32::from(digit - b'a' + 10),
                                    b'A'..=b'F' => u32::from(digit - b'A' + 10),
                                    _ => return Err(invalid()),
                                };
                            }
                            output.push(char::from_u32(value).ok_or_else(invalid)?);
                        }
                        _ => return Err(invalid()),
                    }
                }
                0x00..=0x1f | 0x80..=0xff => return Err(invalid()),
                _ => output.push(char::from(byte)),
            }
        }
    }
}

fn parse_flat_object(input: &[u8]) -> Result<BTreeMap<String, String>, ContractDiagnostic> {
    let mut parser = Parser::new(input);
    let mut fields = BTreeMap::new();
    parser.whitespace();
    parser.byte(b'{')?;
    parser.whitespace();
    if parser.input.get(parser.offset) == Some(&b'}') {
        parser.offset += 1;
    } else {
        loop {
            let key = parser.string()?;
            parser.whitespace();
            parser.byte(b':')?;
            parser.whitespace();
            let value = parser.string()?;
            if fields.insert(key, value).is_some() {
                return Err(invalid());
            }
            parser.whitespace();
            match parser.input.get(parser.offset) {
                Some(b',') => {
                    parser.offset += 1;
                    parser.whitespace();
                }
                Some(b'}') => {
                    parser.offset += 1;
                    break;
                }
                _ => return Err(invalid()),
            }
        }
    }
    parser.whitespace();
    if parser.offset != parser.input.len() {
        return Err(invalid());
    }
    Ok(fields)
}

fn required<'a>(
    fields: &'a BTreeMap<String, String>,
    name: &str,
) -> Result<&'a str, ContractDiagnostic> {
    fields.get(name).map(String::as_str).ok_or_else(invalid)
}

fn expect_value(
    fields: &BTreeMap<String, String>,
    name: &str,
    expected: &str,
) -> Result<(), ContractDiagnostic> {
    if required(fields, name)? == expected {
        Ok(())
    } else {
        Err(invalid())
    }
}

fn expect_keys(
    fields: &BTreeMap<String, String>,
    expected: &[&str],
) -> Result<(), ContractDiagnostic> {
    if fields.len() == expected.len() && expected.iter().all(|key| fields.contains_key(*key)) {
        Ok(())
    } else {
        Err(invalid())
    }
}
