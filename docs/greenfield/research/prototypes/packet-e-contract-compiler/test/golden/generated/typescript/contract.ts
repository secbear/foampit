export const INVALID_OUTCOME = "contract/invalid-outcome" as const;

export class ContractDiagnostic extends Error {
  readonly category = INVALID_OUTCOME;

  constructor() {
    super(INVALID_OUTCOME);
    this.name = "ContractDiagnostic";
  }
}

export type RegistryAmbiguity =
  | Readonly<{ readonly kind: "ambiguity.runtime.unknown"; readonly wireTag: "1" }>;

export type RegistryCallerRecovery =
  | Readonly<{ readonly kind: "caller.recovery.retry"; readonly wireTag: "1" }>;

export type RegistryCoreResolution =
  | Readonly<{ readonly kind: "core.resolution.reconcile"; readonly wireTag: "1" }>;

export type RegistryKnownFailure =
  | Readonly<{ readonly kind: "failure.runtime.provisioning"; readonly wireTag: "1" }>;

export type RegistryOperationOutcome =
  | Readonly<{ readonly kind: "outcome.accepted"; readonly wireTag: "1" }>
  | Readonly<{ readonly kind: "outcome.observed"; readonly wireTag: "4" }>
  | Readonly<{ readonly kind: "outcome.recovery"; readonly wireTag: "3" }>
  | Readonly<{ readonly kind: "outcome.rejected"; readonly wireTag: "2" }>;

export type RegistryProcessControlOutcome =
  | Readonly<{ readonly kind: "outcome.process.accepted"; readonly wireTag: "1" }>
  | Readonly<{ readonly kind: "outcome.process.recovery"; readonly wireTag: "3" }>
  | Readonly<{ readonly kind: "outcome.process.rejected"; readonly wireTag: "2" }>;

export type RegistryProcessTermination =
  | Readonly<{ readonly kind: "process.termination.exited"; readonly wireTag: "1" }>
  | Readonly<{ readonly kind: "process.termination.signalled"; readonly wireTag: "2" }>;

export type RegistryProviderEvidence =
  | Readonly<{ readonly kind: "provider.evidence.observed"; readonly wireTag: "1" }>;

export type RegistryRecoveryError =
  | Readonly<{ readonly kind: "recovery.idempotency.expired"; readonly wireTag: "1" }>;

export type RegistryRequestError =
  | Readonly<{ readonly kind: "request.invalid.state"; readonly wireTag: "1" }>
  | Readonly<{ readonly kind: "request.sequence.out.of.range"; readonly wireTag: "2" }>;

export type RegistryTransportError =
  | Readonly<{ readonly kind: "transport.error.unavailable"; readonly wireTag: "1" }>;

export type StateOperation =
  | Readonly<{ readonly kind: "state.operation.accepted"; readonly wireTag: "1" }>
  | Readonly<{ readonly kind: "state.operation.cancel.requested"; readonly wireTag: "3" }>
  | Readonly<{ readonly kind: "state.operation.cancelled"; readonly wireTag: "6" }>
  | Readonly<{ readonly kind: "state.operation.failed"; readonly wireTag: "5" }>
  | Readonly<{ readonly kind: "state.operation.running"; readonly wireTag: "2" }>
  | Readonly<{ readonly kind: "state.operation.succeeded"; readonly wireTag: "4" }>
  | Readonly<{ readonly kind: "state.operation.unknown"; readonly wireTag: "7" }>;

export type StateProcess =
  | Readonly<{ readonly kind: "state.process.accepted"; readonly wireTag: "1" }>
  | Readonly<{ readonly kind: "state.process.running"; readonly wireTag: "3" }>
  | Readonly<{ readonly kind: "state.process.starting"; readonly wireTag: "2" }>
  | Readonly<{ readonly kind: "state.process.terminated"; readonly wireTag: "5" }>
  | Readonly<{ readonly kind: "state.process.unknown"; readonly wireTag: "4" }>;

export type StateSandbox =
  | Readonly<{ readonly kind: "state.sandbox.provisioning"; readonly wireTag: "2" }>
  | Readonly<{ readonly kind: "state.sandbox.running"; readonly wireTag: "3" }>
  | Readonly<{ readonly kind: "state.sandbox.stopped"; readonly wireTag: "1" }>
  | Readonly<{ readonly kind: "state.sandbox.unknown"; readonly wireTag: "4" }>;


export type OperationId =
  | "operation.cancel.operation"
  | "operation.start.sandbox"
  | "operation.wait.operation"
  | "operation.write.process.input";

export type CancelOperationRequestError = Extract<
  RegistryRequestError,
  Readonly<{ readonly kind: "request.invalid.state" }>
>;

export type CancelOperationRecoveryError = Extract<
  RegistryRecoveryError,
  Readonly<{ readonly kind: "recovery.idempotency.expired" }>
>;

export type CancelOperationKnownFailure = never;

export type CancelOperationAmbiguity = Extract<
  RegistryAmbiguity,
  Readonly<{ readonly kind: "ambiguity.runtime.unknown" }>
>;

export type CancelOperationCarrier = Readonly<{
  readonly carrierKind: "existingOperationObservation";
  readonly schemaStableId: "result.existing.operation.observation";
}>;

export type CancelOperationOutcome =
  | Readonly<{ readonly operationId: "operation.cancel.operation"; readonly branch: "accepted"; readonly carrierKind: CancelOperationCarrier["carrierKind"]; readonly schemaStableId: CancelOperationCarrier["schemaStableId"] }>
  | Readonly<{ readonly operationId: "operation.cancel.operation"; readonly branch: "recovery"; readonly recoveryErrorId: CancelOperationRecoveryError["kind"] }>
  | Readonly<{ readonly operationId: "operation.cancel.operation"; readonly branch: "rejected"; readonly requestErrorId: CancelOperationRequestError["kind"] }>;

export type StartSandboxRequestError = Extract<
  RegistryRequestError,
  Readonly<{ readonly kind: "request.invalid.state" }>
>;

export type StartSandboxRecoveryError = Extract<
  RegistryRecoveryError,
  Readonly<{ readonly kind: "recovery.idempotency.expired" }>
>;

export type StartSandboxKnownFailure = Extract<
  RegistryKnownFailure,
  Readonly<{ readonly kind: "failure.runtime.provisioning" }>
>;

export type StartSandboxAmbiguity = Extract<
  RegistryAmbiguity,
  Readonly<{ readonly kind: "ambiguity.runtime.unknown" }>
>;

export type StartSandboxCarrier = Readonly<{
  readonly carrierKind: "newDurableOperation";
  readonly schemaStableId: "result.operation.start.sandbox";
}>;

export type StartSandboxOutcome =
  | Readonly<{ readonly operationId: "operation.start.sandbox"; readonly branch: "accepted"; readonly carrierKind: StartSandboxCarrier["carrierKind"]; readonly schemaStableId: StartSandboxCarrier["schemaStableId"] }>
  | Readonly<{ readonly operationId: "operation.start.sandbox"; readonly branch: "recovery"; readonly recoveryErrorId: StartSandboxRecoveryError["kind"] }>
  | Readonly<{ readonly operationId: "operation.start.sandbox"; readonly branch: "rejected"; readonly requestErrorId: StartSandboxRequestError["kind"] }>;

export type WaitOperationRequestError = Extract<
  RegistryRequestError,
  Readonly<{ readonly kind: "request.invalid.state" }>
>;

export type WaitOperationRecoveryError = never;

export type WaitOperationKnownFailure = never;

export type WaitOperationAmbiguity = never;

export type WaitOperationCarrier = Readonly<{
  readonly carrierKind: "observation";
  readonly schemaStableId: "result.operation.wait.observation";
}>;

export type WaitOperationOutcome =
  | Readonly<{ readonly operationId: "operation.wait.operation"; readonly branch: "observed"; readonly carrierKind: WaitOperationCarrier["carrierKind"]; readonly schemaStableId: WaitOperationCarrier["schemaStableId"] }>
  | Readonly<{ readonly operationId: "operation.wait.operation"; readonly branch: "rejected"; readonly requestErrorId: WaitOperationRequestError["kind"] }>;

export type WriteProcessInputRequestError = Extract<
  RegistryRequestError,
  Readonly<{ readonly kind: "request.invalid.state" | "request.sequence.out.of.range" }>
>;

export type WriteProcessInputRecoveryError = Extract<
  RegistryRecoveryError,
  Readonly<{ readonly kind: "recovery.idempotency.expired" }>
>;

export type WriteProcessInputKnownFailure = never;

export type WriteProcessInputAmbiguity = Extract<
  RegistryAmbiguity,
  Readonly<{ readonly kind: "ambiguity.runtime.unknown" }>
>;

export type WriteProcessInputCarrier = Readonly<{
  readonly carrierKind: "processControlReceipt";
  readonly schemaStableId: "result.process.control.receipt";
}>;

export type WriteProcessInputOutcome =
  | Readonly<{ readonly operationId: "operation.write.process.input"; readonly branch: "accepted"; readonly carrierKind: WriteProcessInputCarrier["carrierKind"]; readonly schemaStableId: WriteProcessInputCarrier["schemaStableId"] }>
  | Readonly<{ readonly operationId: "operation.write.process.input"; readonly branch: "recovery"; readonly recoveryErrorId: WriteProcessInputRecoveryError["kind"] }>
  | Readonly<{ readonly operationId: "operation.write.process.input"; readonly branch: "rejected"; readonly requestErrorId: WriteProcessInputRequestError["kind"] }>;


export type InvocationOutcome =
  | CancelOperationOutcome
  | StartSandboxOutcome
  | WaitOperationOutcome
  | WriteProcessInputOutcome;

export interface PacketEService {
  cancelOperation(): Promise<CancelOperationOutcome>;
  startSandbox(): Promise<StartSandboxOutcome>;
  waitOperation(): Promise<WaitOperationOutcome>;
  writeProcessInput(): Promise<WriteProcessInputOutcome>;
}

export function decodeCancelOperationOutcome(value: unknown): CancelOperationOutcome {
  const object = record(value);
  exactValue(object, "operationId", "operation.cancel.operation");
  switch (stringField(object, "branch")) {
    case "accepted":
      exactKeys(object, ["operationId", "branch", "carrierKind", "schemaStableId"]);
      exactValue(object, "carrierKind", "existingOperationObservation");
      exactValue(object, "schemaStableId", "result.existing.operation.observation");
      return Object.freeze({
        operationId: "operation.cancel.operation",
        branch: "accepted",
        carrierKind: "existingOperationObservation",
        schemaStableId: "result.existing.operation.observation",
      });
    case "recovery": {
      exactKeys(object, ["operationId", "branch", "recoveryErrorId"]);
      const reason = stringField(object, "recoveryErrorId");
      switch (reason) {
        case "recovery.idempotency.expired":
          return Object.freeze({
            operationId: "operation.cancel.operation",
            branch: "recovery",
            recoveryErrorId: reason,
          }) as CancelOperationOutcome;
        default:
          throw invalid();
      }
    }
    case "rejected": {
      exactKeys(object, ["operationId", "branch", "requestErrorId"]);
      const reason = stringField(object, "requestErrorId");
      switch (reason) {
        case "request.invalid.state":
          return Object.freeze({
            operationId: "operation.cancel.operation",
            branch: "rejected",
            requestErrorId: reason,
          }) as CancelOperationOutcome;
        default:
          throw invalid();
      }
    }
    default:
      throw invalid();
  }
}

export function decodeStartSandboxOutcome(value: unknown): StartSandboxOutcome {
  const object = record(value);
  exactValue(object, "operationId", "operation.start.sandbox");
  switch (stringField(object, "branch")) {
    case "accepted":
      exactKeys(object, ["operationId", "branch", "carrierKind", "schemaStableId"]);
      exactValue(object, "carrierKind", "newDurableOperation");
      exactValue(object, "schemaStableId", "result.operation.start.sandbox");
      return Object.freeze({
        operationId: "operation.start.sandbox",
        branch: "accepted",
        carrierKind: "newDurableOperation",
        schemaStableId: "result.operation.start.sandbox",
      });
    case "recovery": {
      exactKeys(object, ["operationId", "branch", "recoveryErrorId"]);
      const reason = stringField(object, "recoveryErrorId");
      switch (reason) {
        case "recovery.idempotency.expired":
          return Object.freeze({
            operationId: "operation.start.sandbox",
            branch: "recovery",
            recoveryErrorId: reason,
          }) as StartSandboxOutcome;
        default:
          throw invalid();
      }
    }
    case "rejected": {
      exactKeys(object, ["operationId", "branch", "requestErrorId"]);
      const reason = stringField(object, "requestErrorId");
      switch (reason) {
        case "request.invalid.state":
          return Object.freeze({
            operationId: "operation.start.sandbox",
            branch: "rejected",
            requestErrorId: reason,
          }) as StartSandboxOutcome;
        default:
          throw invalid();
      }
    }
    default:
      throw invalid();
  }
}

export function decodeWaitOperationOutcome(value: unknown): WaitOperationOutcome {
  const object = record(value);
  exactValue(object, "operationId", "operation.wait.operation");
  switch (stringField(object, "branch")) {
    case "observed":
      exactKeys(object, ["operationId", "branch", "carrierKind", "schemaStableId"]);
      exactValue(object, "carrierKind", "observation");
      exactValue(object, "schemaStableId", "result.operation.wait.observation");
      return Object.freeze({
        operationId: "operation.wait.operation",
        branch: "observed",
        carrierKind: "observation",
        schemaStableId: "result.operation.wait.observation",
      });
    case "rejected": {
      exactKeys(object, ["operationId", "branch", "requestErrorId"]);
      const reason = stringField(object, "requestErrorId");
      switch (reason) {
        case "request.invalid.state":
          return Object.freeze({
            operationId: "operation.wait.operation",
            branch: "rejected",
            requestErrorId: reason,
          }) as WaitOperationOutcome;
        default:
          throw invalid();
      }
    }
    default:
      throw invalid();
  }
}

export function decodeWriteProcessInputOutcome(value: unknown): WriteProcessInputOutcome {
  const object = record(value);
  exactValue(object, "operationId", "operation.write.process.input");
  switch (stringField(object, "branch")) {
    case "accepted":
      exactKeys(object, ["operationId", "branch", "carrierKind", "schemaStableId"]);
      exactValue(object, "carrierKind", "processControlReceipt");
      exactValue(object, "schemaStableId", "result.process.control.receipt");
      return Object.freeze({
        operationId: "operation.write.process.input",
        branch: "accepted",
        carrierKind: "processControlReceipt",
        schemaStableId: "result.process.control.receipt",
      });
    case "recovery": {
      exactKeys(object, ["operationId", "branch", "recoveryErrorId"]);
      const reason = stringField(object, "recoveryErrorId");
      switch (reason) {
        case "recovery.idempotency.expired":
          return Object.freeze({
            operationId: "operation.write.process.input",
            branch: "recovery",
            recoveryErrorId: reason,
          }) as WriteProcessInputOutcome;
        default:
          throw invalid();
      }
    }
    case "rejected": {
      exactKeys(object, ["operationId", "branch", "requestErrorId"]);
      const reason = stringField(object, "requestErrorId");
      switch (reason) {
        case "request.invalid.state":
        case "request.sequence.out.of.range":
          return Object.freeze({
            operationId: "operation.write.process.input",
            branch: "rejected",
            requestErrorId: reason,
          }) as WriteProcessInputOutcome;
        default:
          throw invalid();
      }
    }
    default:
      throw invalid();
  }
}


export function decodeOutcome(value: unknown): InvocationOutcome {
  const object = record(value);
  switch (stringField(object, "operationId")) {
    case "operation.cancel.operation":
      return decodeCancelOperationOutcome(value);
    case "operation.start.sandbox":
      return decodeStartSandboxOutcome(value);
    case "operation.wait.operation":
      return decodeWaitOperationOutcome(value);
    case "operation.write.process.input":
      return decodeWriteProcessInputOutcome(value);
    default:
      throw invalid();
  }
}

function record(value: unknown): Readonly<Record<string, unknown>> {
  if (typeof value !== "object" || value === null || Array.isArray(value)) {
    throw invalid();
  }
  const prototype = Object.getPrototypeOf(value);
  if (prototype !== Object.prototype && prototype !== null) {
    throw invalid();
  }
  return value as Readonly<Record<string, unknown>>;
}

function exactKeys(
  value: Readonly<Record<string, unknown>>,
  expected: readonly string[],
): void {
  const actual = Reflect.ownKeys(value);
  if (actual.length !== expected.length || !expected.every((key) => {
    const descriptor = Object.getOwnPropertyDescriptor(value, key);
    return actual.includes(key) && descriptor?.enumerable === true && descriptor !== undefined && "value" in descriptor;
  })) {
    throw invalid();
  }
}

function stringField(
  value: Readonly<Record<string, unknown>>,
  key: string,
): string {
  const field = value[key];
  if (typeof field !== "string") {
    throw invalid();
  }
  return field;
}

function exactValue(
  value: Readonly<Record<string, unknown>>,
  key: string,
  expected: string,
): void {
  if (stringField(value, key) !== expected) {
    throw invalid();
  }
}

function invalid(): ContractDiagnostic {
  return new ContractDiagnostic();
}
