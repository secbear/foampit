import "contract";

using PacketE.Contract;

@contractRoot
namespace PacketE.Slice;

@stableId("state.sandbox.runtime")
union SandboxRuntimeState {
  @wireTag("1") stopped: void,
  @wireTag("2") provisioning: void,
  @wireTag("3") running: void,
  @wireTag("4") `unknown`: void,
}

@stableId("result.operation")
union OperationResult {
  @wireTag("1") accepted: void,
  @wireTag("2") succeeded: void,
  @wireTag("3") failed: void,
}

@stableId("error.request")
union RequestError {
  @wireTag("1") invalidArgument: void,
  @wireTag("2") staleRuntime: void,
}

@stableId("evidence.provider")
union ProviderEvidence {
  @wireTag("1") observed: void,
  @wireTag("2") missing: void,
}

@stableId("method.start.sandbox")
op StartSandbox(): void;

@stableId("method.cancel.operation")
op CancelOperation(): void;

@stableId("method.write.process.input")
op WriteProcessInput(): void;

@stableId("method.wait.operation")
op WaitOperation(): void;
