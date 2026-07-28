module PacketEMutants {
  import PacketEContract.* from "./contract"
  import PacketEMachine.* from "./machine"

  action mutantRejectedRequestCreatesEffects = all {
    state.requestOutcome == "pending",
    state' = {
      ...state,
      requestOutcome: "rejected",
      durableHandle: "operation-mutant",
      returnedHandle: "operation-mutant",
      intentState: "absent",
      dispatchCount: 1,
      priorDispatchCount: state.dispatchCount,
      lastEvent: "request-rejected",
    },
  }

  action mutantPersistsIntentAndDispatchesAtomically = all {
    state.requestOutcome == "pending",
    state' = {
      ...state,
      requestOutcome: "accepted",
      durableHandle: "operation-mutant",
      returnedHandle: "operation-mutant",
      intentState: "persisted",
      dispatchCount: 1,
      priorDispatchCount: state.dispatchCount,
      priorIntentState: state.intentState,
      effectCertainty: "uncertain",
      possiblyActing: true,
      operationState: stateOperationRunning,
      lastEvent: "intent-dispatched",
    },
  }

  action mutantEqualReplayReturnsDifferentHandle = all {
    state.requestOutcome == "accepted",
    state' = {
      ...state,
      returnedHandle: "different-operation",
      replayClass: "equal",
      priorDispatchCount: state.dispatchCount,
      lastEvent: "equal-replay",
    },
  }

  action mutantConflictingReplayMutatesResource = all {
    state.requestOutcome == "accepted",
    state' = {
      ...state,
      returnedHandle: "none",
      replayClass: "conflicting",
      priorDispatchCount: state.dispatchCount,
      priorEffectState: effectStateOf(state),
      priorResourceRevision: state.resourceRevision,
      resourceRevision: state.resourceRevision + 1,
      lastEvent: "conflicting-replay",
    },
  }

  action mutantStaleEpochRetainsAuthority = state' = {
    ...state,
    currentEpoch: state.currentEpoch + 1,
    actorEpoch: state.currentEpoch,
    authorityOwned: true,
    lastEvent: "epoch-advanced",
  }

  action mutantSuccessWithoutExactPostcondition = state' = {
    ...state,
    exactPostcondition: false,
    operationState: stateOperationSucceeded,
    terminalCommitted: true,
    terminalSnapshot: stateOperationSucceeded,
    lastEvent: "terminal-succeeded",
  }

  action mutantFailureWhilePossiblyActing = state' = {
    ...state,
    possiblyActing: true,
    operationState: stateOperationFailed,
    terminalCommitted: true,
    terminalSnapshot: stateOperationFailed,
    lastEvent: "terminal-failed",
  }

  action mutantUnknownDispatchesBlindSuccessor = state' = {
    ...state,
    operationState: stateOperationUnknown,
    terminalCommitted: true,
    terminalSnapshot: stateOperationUnknown,
    blindSuccessorDispatched: true,
    lastEvent: "blind-successor-dispatched",
  }

  action mutantRewritesTerminalOperation = all {
    state.terminalCommitted,
    state' = {
      ...state,
      operationState: stateOperationRunning,
      lastEvent: "terminal-rewritten",
    },
  }

  action mutantWaitTimeoutMutatesResource = state' = {
    ...state,
    priorResourceRevision: state.resourceRevision,
    resourceRevision: state.resourceRevision + 1,
    lastEvent: "wait-timeout",
  }

  action mutantProviderAcknowledgementEstablishesSuccess = state' = {
    ...state,
    providerAcknowledged: true,
    exactPostcondition: false,
    operationState: stateOperationSucceeded,
    terminalCommitted: true,
    terminalSnapshot: stateOperationSucceeded,
    lastEvent: "provider-acknowledged",
  }
}
