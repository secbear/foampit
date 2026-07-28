module PacketEMachine {
  import PacketEContract.* from "./contract"

  type EffectState = {
    requestOutcome: str,
    durableHandle: str,
    intentState: str,
    dispatchCount: int,
    currentEpoch: int,
    actorEpoch: int,
    authorityOwned: bool,
    effectCertainty: str,
    possiblyActing: bool,
    providerAcknowledged: bool,
    exactPostcondition: bool,
    internalAmbiguity: bool,
    operationState: str,
    terminalCommitted: bool,
    terminalSnapshot: str,
    resourceRevision: int,
    blindSuccessorDispatched: bool,
    cleanupIdentityIssued: bool,
  }

  type MachineState = {
    requestOutcome: str,
    durableHandle: str,
    returnedHandle: str,
    replayClass: str,
    intentState: str,
    priorIntentState: str,
    dispatchCount: int,
    priorDispatchCount: int,
    priorEffectState: EffectState,
    currentEpoch: int,
    actorEpoch: int,
    authorityOwned: bool,
    effectCertainty: str,
    possiblyActing: bool,
    providerAcknowledged: bool,
    exactPostcondition: bool,
    internalAmbiguity: bool,
    operationState: str,
    terminalCommitted: bool,
    terminalSnapshot: str,
    resourceRevision: int,
    priorResourceRevision: int,
    lastEvent: str,
    blindSuccessorDispatched: bool,
    cleanupIdentityIssued: bool,
  }

  pure def effectStateOf(value: MachineState): EffectState = {
    requestOutcome: value.requestOutcome,
    durableHandle: value.durableHandle,
    intentState: value.intentState,
    dispatchCount: value.dispatchCount,
    currentEpoch: value.currentEpoch,
    actorEpoch: value.actorEpoch,
    authorityOwned: value.authorityOwned,
    effectCertainty: value.effectCertainty,
    possiblyActing: value.possiblyActing,
    providerAcknowledged: value.providerAcknowledged,
    exactPostcondition: value.exactPostcondition,
    internalAmbiguity: value.internalAmbiguity,
    operationState: value.operationState,
    terminalCommitted: value.terminalCommitted,
    terminalSnapshot: value.terminalSnapshot,
    resourceRevision: value.resourceRevision,
    blindSuccessorDispatched: value.blindSuccessorDispatched,
    cleanupIdentityIssued: value.cleanupIdentityIssued,
  }

  var state: MachineState

  action referenceInit = state' = {
    requestOutcome: "pending",
    durableHandle: "none",
    returnedHandle: "none",
    replayClass: "none",
    intentState: "absent",
    priorIntentState: "absent",
    dispatchCount: 0,
    priorDispatchCount: 0,
    priorEffectState: {
      requestOutcome: "pending",
      durableHandle: "none",
      intentState: "absent",
      dispatchCount: 0,
      currentEpoch: 0,
      actorEpoch: 0,
      authorityOwned: false,
      effectCertainty: "not-dispatched",
      possiblyActing: false,
      providerAcknowledged: false,
      exactPostcondition: false,
      internalAmbiguity: false,
      operationState: stateOperationAccepted,
      terminalCommitted: false,
      terminalSnapshot: "none",
      resourceRevision: 0,
      blindSuccessorDispatched: false,
      cleanupIdentityIssued: false,
    },
    currentEpoch: 0,
    actorEpoch: 0,
    authorityOwned: false,
    effectCertainty: "not-dispatched",
    possiblyActing: false,
    providerAcknowledged: false,
    exactPostcondition: false,
    internalAmbiguity: false,
    operationState: stateOperationAccepted,
    terminalCommitted: false,
    terminalSnapshot: "none",
    resourceRevision: 0,
    priorResourceRevision: 0,
    lastEvent: "initialized",
    blindSuccessorDispatched: false,
    cleanupIdentityIssued: false,
  }

  action rejectRequest = all {
    not(state.terminalCommitted),
    state.requestOutcome == "pending",
    state' = {
      ...state,
      requestOutcome: "rejected",
      durableHandle: "none",
      returnedHandle: "none",
      intentState: "absent",
      priorDispatchCount: state.dispatchCount,
      lastEvent: "request-rejected",
    },
  }

  action acceptAndPersistIntent = all {
    not(state.terminalCommitted),
    state.requestOutcome == "pending",
    state' = {
      ...state,
      requestOutcome: "accepted",
      durableHandle: "operation-1",
      returnedHandle: "operation-1",
      intentState: "persisted",
      lastEvent: "intent-persisted",
    },
  }

  action acquireCurrentAuthority = all {
    not(state.terminalCommitted),
    state.requestOutcome == "accepted",
    state' = {
      ...state,
      actorEpoch: state.currentEpoch,
      authorityOwned: true,
      lastEvent: "authority-acquired",
    },
  }

  action dispatchPersistedIntent = all {
    not(state.terminalCommitted),
    state.requestOutcome == "accepted",
    state.intentState == "persisted",
    state.durableHandle != "none",
    state.authorityOwned,
    state.actorEpoch == state.currentEpoch,
    state' = {
      ...state,
      dispatchCount: state.dispatchCount + 1,
      priorDispatchCount: state.dispatchCount,
      priorIntentState: state.intentState,
      effectCertainty: "uncertain",
      possiblyActing: true,
      operationState: stateOperationRunning,
      lastEvent: "intent-dispatched",
    },
  }

  action replayEqualRequest = all {
    not(state.terminalCommitted),
    state.requestOutcome == "accepted",
    state.durableHandle != "none",
    state' = {
      ...state,
      returnedHandle: state.durableHandle,
      replayClass: "equal",
      priorDispatchCount: state.dispatchCount,
      lastEvent: "equal-replay",
    },
  }

  action replayConflictingRequest = all {
    not(state.terminalCommitted),
    state.requestOutcome == "accepted",
    state.durableHandle != "none",
    state' = {
      ...state,
      returnedHandle: "none",
      replayClass: "conflicting",
      priorDispatchCount: state.dispatchCount,
      priorEffectState: effectStateOf(state),
      lastEvent: "conflicting-replay",
    },
  }

  action advanceRuntimeEpoch = all {
    not(state.terminalCommitted),
    state' = {
      ...state,
      currentEpoch: state.currentEpoch + 1,
      authorityOwned: false,
      lastEvent: "epoch-advanced",
    },
  }

  action acknowledgeProviderAcceptance = all {
    not(state.terminalCommitted),
    state.dispatchCount > 0,
    state' = {
      ...state,
      providerAcknowledged: true,
      lastEvent: "provider-acknowledged",
    },
  }

  action observeExactPostcondition = all {
    not(state.terminalCommitted),
    state.dispatchCount > 0,
    state' = {
      ...state,
      exactPostcondition: true,
      effectCertainty: "known",
      lastEvent: "exact-postcondition-observed",
    },
  }

  action establishQuiescence = all {
    not(state.terminalCommitted),
    state.dispatchCount > 0,
    state' = {
      ...state,
      effectCertainty: "known",
      possiblyActing: false,
      lastEvent: "quiescence-established",
    },
  }

  action observeInternalAmbiguity = all {
    not(state.terminalCommitted),
    state.dispatchCount > 0,
    state.effectCertainty == "uncertain",
    state' = {
      ...state,
      internalAmbiguity: true,
      lastEvent: "internal-ambiguity-observed",
    },
  }

  action recordResourceMutation = all {
    not(state.terminalCommitted),
    state.dispatchCount > 0,
    state' = {
      ...state,
      priorResourceRevision: state.resourceRevision,
      resourceRevision: state.resourceRevision + 1,
      lastEvent: "resource-mutated",
    },
  }

  action waitTimeout = all {
    not(state.terminalCommitted),
    state.requestOutcome == "accepted",
    state' = {
      ...state,
      priorResourceRevision: state.resourceRevision,
      lastEvent: "wait-timeout",
    },
  }

  action commitSucceeded = all {
    not(state.terminalCommitted),
    state.exactPostcondition,
    not(state.possiblyActing),
    state' = {
      ...state,
      operationState: stateOperationSucceeded,
      terminalCommitted: true,
      terminalSnapshot: stateOperationSucceeded,
      lastEvent: "terminal-succeeded",
    },
  }

  action commitFailed = all {
    not(state.terminalCommitted),
    state.dispatchCount > 0,
    not(state.possiblyActing),
    state' = {
      ...state,
      operationState: stateOperationFailed,
      terminalCommitted: true,
      terminalSnapshot: stateOperationFailed,
      lastEvent: "terminal-failed",
    },
  }

  action commitCancelled = all {
    not(state.terminalCommitted),
    state.requestOutcome == "accepted",
    not(state.possiblyActing),
    state' = {
      ...state,
      operationState: stateOperationCancelled,
      terminalCommitted: true,
      terminalSnapshot: stateOperationCancelled,
      lastEvent: "terminal-cancelled",
    },
  }

  action commitUnknown = all {
    not(state.terminalCommitted),
    state.internalAmbiguity,
    state' = {
      ...state,
      operationState: stateOperationUnknown,
      terminalCommitted: true,
      terminalSnapshot: stateOperationUnknown,
      lastEvent: "terminal-unknown",
    },
  }

  action reconcileUnknown = all {
    state.terminalCommitted,
    state.operationState == stateOperationUnknown,
    state' = {
      ...state,
      cleanupIdentityIssued: true,
      lastEvent: "unknown-reconciled",
    },
  }

  action observeWithoutMutation = state' = {
    ...state,
    priorResourceRevision: state.resourceRevision,
    lastEvent: "observed",
  }

  action referenceStep = any {
    rejectRequest,
    acceptAndPersistIntent,
    acquireCurrentAuthority,
    dispatchPersistedIntent,
    replayEqualRequest,
    replayConflictingRequest,
    advanceRuntimeEpoch,
    acknowledgeProviderAcceptance,
    observeExactPostcondition,
    establishQuiescence,
    observeInternalAmbiguity,
    recordResourceMutation,
    waitTimeout,
    commitSucceeded,
    commitFailed,
    commitCancelled,
    commitUnknown,
    reconcileUnknown,
    observeWithoutMutation,
  }
}
