module PacketEInvariants {
  import PacketEContract.* from "./contract"
  import PacketEMachine.* from "./machine"

  val rejectedRequestHasNoHandleOrDispatch =
    state.requestOutcome != "rejected"
      or all {
        state.durableHandle == "none",
        state.returnedHandle == "none",
        state.dispatchCount == 0,
      }

  val dispatchRequiresDurableIntent = all {
    state.dispatchCount == 0
      or all {
        state.requestOutcome == "accepted",
        state.intentState == "persisted",
        state.durableHandle != "none",
      },
    state.dispatchCount <= state.priorDispatchCount
      or state.priorIntentState == "persisted",
  }

  val equalReplayReturnsSameHandle =
    state.lastEvent != "equal-replay"
      or all {
        state.returnedHandle == state.durableHandle,
        state.dispatchCount == state.priorDispatchCount,
      }

  val conflictingReplayHasNoEffect =
    state.lastEvent != "conflicting-replay"
      or all {
        state.returnedHandle == "none",
        effectStateOf(state) == state.priorEffectState,
      }

  val staleEpochHasNoAuthority =
    state.actorEpoch == state.currentEpoch or not(state.authorityOwned)

  val successRequiresExactPostcondition =
    state.operationState != stateOperationSucceeded
      or state.exactPostcondition

  val failedOrCancelledHasNoPossiblyActingAuthority =
    not(Set(stateOperationFailed, stateOperationCancelled).contains(state.operationState))
      or not(state.possiblyActing)

  val terminalUnknownHasNoBlindSuccessor =
    state.operationState != stateOperationUnknown
      or not(state.blindSuccessorDispatched)

  val terminalOperationIsImmutable =
    not(state.terminalCommitted)
      or state.operationState == state.terminalSnapshot

  val waitTimeoutDoesNotMutateResource =
    state.lastEvent != "wait-timeout"
      or state.resourceRevision == state.priorResourceRevision

  val providerAcknowledgementDoesNotEstablishSuccess =
    not(state.providerAcknowledged)
      or state.exactPostcondition
      or state.operationState != stateOperationSucceeded

  val allInvariants = all {
    rejectedRequestHasNoHandleOrDispatch,
    dispatchRequiresDurableIntent,
    equalReplayReturnsSameHandle,
    conflictingReplayHasNoEffect,
    staleEpochHasNoAuthority,
    successRequiresExactPostcondition,
    failedOrCancelledHasNoPossiblyActingAuthority,
    terminalUnknownHasNoBlindSuccessor,
    terminalOperationIsImmutable,
    waitTimeoutDoesNotMutateResource,
    providerAcknowledgementDoesNotEstablishSuccess,
  }

  action init = referenceInit
  action step = referenceStep
}
