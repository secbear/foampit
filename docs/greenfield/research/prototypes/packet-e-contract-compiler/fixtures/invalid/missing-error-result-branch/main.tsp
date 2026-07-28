import "contract";

using PacketE.Contract;

@stableId("state.sandbox")
union SandboxState {
  @stableId("state.sandbox.stopped") @wireTag("1") stopped: void,
  @stableId("state.sandbox.provisioning") @wireTag("2") provisioning: void,
  @stableId("state.sandbox.running") @wireTag("3") running: void,
  @stableId("state.sandbox.unknown") @wireTag("4") unknownState: void,
}

@stableId("state.operation")
union OperationState {
  @stableId("state.operation.accepted") @wireTag("1") accepted: void,
  @stableId("state.operation.running") @wireTag("2") running: void,
  @stableId("state.operation.cancel.requested")
  @wireTag("3")
  cancelRequested: void,
  @stableId("state.operation.succeeded") @wireTag("4") succeeded: void,
  @stableId("state.operation.failed") @wireTag("5") failed: void,
  @stableId("state.operation.cancelled") @wireTag("6") cancelled: void,
  @stableId("state.operation.unknown") @wireTag("7") unknownState: void,
}

@stableId("state.process")
union ProcessState {
  @stableId("state.process.accepted") @wireTag("1") accepted: void,
  @stableId("state.process.starting") @wireTag("2") starting: void,
  @stableId("state.process.running") @wireTag("3") running: void,
  @stableId("state.process.unknown") @wireTag("4") unknownState: void,
  @stableId("state.process.terminated") @wireTag("5") terminated: void,
}

@stableId("registry.request.error")
union RequestError {
  @stableId("request.invalid.state") @wireTag("1") invalidState: void,
  @stableId("request.sequence.out.of.range")
  @wireTag("2")
  sequenceOutOfRange: void,
}

@stableId("registry.recovery.error")
union RecoveryError {
  @stableId("recovery.idempotency.expired")
  @wireTag("1")
  idempotencyExpired: void,
}

@stableId("registry.known.failure")
union KnownFailure {
  @stableId("failure.runtime.provisioning")
  @wireTag("1")
  runtimeProvisioning: void,
}

@stableId("registry.ambiguity")
union Ambiguity {
  @stableId("ambiguity.runtime.unknown") @wireTag("1") runtimeUnknown: void,
}

@stableId("registry.operation.outcome")
union OperationOutcome {
  @stableId("outcome.accepted") @wireTag("1") accepted: void,
  @stableId("outcome.rejected") @wireTag("2") rejected: void,
  @stableId("outcome.recovery") @wireTag("3") recovery: void,
  @stableId("outcome.observed") @wireTag("4") observed: void,
}

@stableId("registry.process.control.outcome")
union ProcessControlOutcome {
  @stableId("outcome.process.accepted") @wireTag("1") accepted: void,
  @stableId("outcome.process.rejected") @wireTag("2") rejected: void,
  @stableId("outcome.process.recovery") @wireTag("3") recovery: void,
}

@stableId("registry.process.termination")
union ProcessTermination {
  @stableId("process.termination.exited") @wireTag("1") exited: void,
  @stableId("process.termination.signalled") @wireTag("2") signalled: void,
}

@stableId("registry.caller.recovery")
union CallerRecovery {
  @stableId("caller.recovery.retry") @wireTag("1") retry: void,
}

@stableId("registry.core.resolution")
union CoreResolution {
  @stableId("core.resolution.reconcile") @wireTag("1") reconcile: void,
}

@stableId("registry.transport.error")
union TransportError {
  @stableId("transport.error.unavailable") @wireTag("1") unavailable: void,
}

@stableId("registry.provider.evidence")
union ProviderEvidence {
  @stableId("provider.evidence.observed") @wireTag("1") observed: void,
}

@contractRoot
@contractProfile(#{
  profileId: "packet-e-contract-prototype",
  terminalStateIds: #[
    "state.operation.succeeded",
    "state.operation.failed",
    "state.operation.cancelled",
    "state.operation.unknown",
    "state.process.terminated"
  ],
})
@contractMatrix(#{
  matrixId: "matrix.sandbox-operation",
  rowStateIds: #[
    "state.sandbox.stopped",
    "state.sandbox.provisioning",
    "state.sandbox.running",
    "state.sandbox.unknown"
  ],
  columnOperationIds: #[
    "operation.start.sandbox",
    "operation.cancel.operation",
    "operation.write.process.input",
    "operation.wait.operation"
  ],
  cells: #[
    #{
      rowStateId: "state.sandbox.stopped",
      columnOperationId: "operation.start.sandbox",
      kind: "transition",
      nextStateId: "state.sandbox.provisioning",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.stopped",
      columnOperationId: "operation.cancel.operation",
      kind: "reject",
      nextStateId: "",
      requestErrorId: "request.invalid.state",
    },
    #{
      rowStateId: "state.sandbox.stopped",
      columnOperationId: "operation.write.process.input",
      kind: "reject",
      nextStateId: "",
      requestErrorId: "request.invalid.state",
    },
    #{
      rowStateId: "state.sandbox.stopped",
      columnOperationId: "operation.wait.operation",
      kind: "noop",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.provisioning",
      columnOperationId: "operation.start.sandbox",
      kind: "replay",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.provisioning",
      columnOperationId: "operation.cancel.operation",
      kind: "noop",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.provisioning",
      columnOperationId: "operation.write.process.input",
      kind: "reject",
      nextStateId: "",
      requestErrorId: "request.invalid.state",
    },
    #{
      rowStateId: "state.sandbox.provisioning",
      columnOperationId: "operation.wait.operation",
      kind: "noop",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.running",
      columnOperationId: "operation.start.sandbox",
      kind: "replay",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.running",
      columnOperationId: "operation.cancel.operation",
      kind: "noop",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.running",
      columnOperationId: "operation.write.process.input",
      kind: "noop",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.running",
      columnOperationId: "operation.wait.operation",
      kind: "noop",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.unknown",
      columnOperationId: "operation.start.sandbox",
      kind: "reject",
      nextStateId: "",
      requestErrorId: "request.invalid.state",
    },
    #{
      rowStateId: "state.sandbox.unknown",
      columnOperationId: "operation.cancel.operation",
      kind: "noop",
      nextStateId: "",
      requestErrorId: "",
    },
    #{
      rowStateId: "state.sandbox.unknown",
      columnOperationId: "operation.write.process.input",
      kind: "reject",
      nextStateId: "",
      requestErrorId: "request.invalid.state",
    },
    #{
      rowStateId: "state.sandbox.unknown",
      columnOperationId: "operation.wait.operation",
      kind: "noop",
      nextStateId: "",
      requestErrorId: "",
    }
  ],
})
namespace PacketE {
  @stableId("result.operation.start.sandbox")
  model StartSandboxOperationResult {}

  @stableId("result.existing.operation.observation")
  model ExistingOperationObservation {}

  @stableId("result.process.control.receipt")
  model ProcessControlReceipt {}

  @stableId("result.operation.wait.observation")
  model WaitOperationObservation {}

  @stableId("operation.start.sandbox")
  @operationContract(#{
    operationId: "operation.start.sandbox",
    callClass: "durableOperationMutation",
    resultBranches: #["accepted", "rejected", "recovery"],
    allowedRequestErrors: #["request.invalid.state"],
    allowedRecoveryErrors: #["recovery.idempotency.expired"],
    allowedKnownFailures: #["failure.runtime.provisioning"],
    allowedAmbiguities: #["ambiguity.runtime.unknown"],
    recoveryCoordinates: #[
      #{ kind: "runtimeEpoch", value: "sandbox.runtime.epoch" },
      #{ kind: "idempotencyKey", value: "start.idempotency-key" }
    ],
    matrixIds: #["matrix.sandbox-operation"],
    result: #{
      carrierKind: "newDurableOperation",
      schemaStableId: "result.operation.start.sandbox",
    },
  })
  op StartSandbox(): StartSandboxOperationResult;

  @stableId("operation.cancel.operation")
  @operationContract(#{
    operationId: "operation.cancel.operation",
    callClass: "existingHandleIntent",
    resultBranches: #["accepted", "rejected", "recovery"],
    allowedRequestErrors: #["request.invalid.state"],
    allowedRecoveryErrors: #["recovery.idempotency.expired"],
    allowedKnownFailures: #[],
    allowedAmbiguities: #["ambiguity.runtime.unknown"],
    recoveryCoordinates: #[
      #{ kind: "operationId", value: "existing.operation.id" }
    ],
    matrixIds: #["matrix.sandbox-operation"],
    result: #{
      carrierKind: "existingOperationObservation",
      schemaStableId: "result.existing.operation.observation",
    },
  })
  op CancelOperation(): ExistingOperationObservation;

  @stableId("operation.write.process.input")
  @operationContract(#{
    operationId: "operation.write.process.input",
    callClass: "sequencedProcessControl",
    resultBranches: #["accepted", "rejected", "recovery"],
    allowedRequestErrors: #[
      "request.invalid.state",
      "request.sequence.out.of.range"
    ],
    allowedRecoveryErrors: #["recovery.idempotency.expired"],
    allowedKnownFailures: #[],
    allowedAmbiguities: #["ambiguity.runtime.unknown"],
    recoveryCoordinates: #[
      #{ kind: "processId", value: "process.id" },
      #{ kind: "runtimeEpoch", value: "sandbox.runtime.epoch" },
      #{ kind: "writerLease", value: "process.writer.lease" },
      #{ kind: "sequence", value: "process.input.sequence" }
    ],
    matrixIds: #["matrix.sandbox-operation"],
    result: #{
      carrierKind: "processControlReceipt",
      schemaStableId: "result.process.control.receipt",
    },
  })
  op WriteProcessInput(): ProcessControlReceipt;

  @stableId("operation.wait.operation")
  @operationContract(#{
    operationId: "operation.wait.operation",
    callClass: "observation",
    resultBranches: #["observed"],
    allowedRequestErrors: #["request.invalid.state"],
    allowedRecoveryErrors: #[],
    allowedKnownFailures: #[],
    allowedAmbiguities: #[],
    recoveryCoordinates: #[],
    matrixIds: #["matrix.sandbox-operation"],
    result: #{
      carrierKind: "observation",
      schemaStableId: "result.operation.wait.observation",
    },
  })
  op WaitOperation(): WaitOperationObservation;
}
