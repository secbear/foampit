import type {
  CancelOperationOutcome,
  StartSandboxOutcome,
  WaitOperationOutcome,
  WriteProcessInputOutcome,
} from "./contract.js";

const validCancelOperation: CancelOperationOutcome = { operationId: "operation.cancel.operation", branch: "accepted", carrierKind: "existingOperationObservation", schemaStableId: "result.existing.operation.observation" };
const validStartSandbox: StartSandboxOutcome = { operationId: "operation.start.sandbox", branch: "accepted", carrierKind: "newDurableOperation", schemaStableId: "result.operation.start.sandbox" };
const validWaitOperation: WaitOperationOutcome = { operationId: "operation.wait.operation", branch: "observed", carrierKind: "observation", schemaStableId: "result.operation.wait.observation" };
const validWriteProcessInput: WriteProcessInputOutcome = { operationId: "operation.write.process.input", branch: "accepted", carrierKind: "processControlReceipt", schemaStableId: "result.process.control.receipt" };

// @ts-expect-error invalid operation.cancel.operation construction
const invalidCancelOperation: CancelOperationOutcome = { operationId: "operation.cancel.operation", branch: "observed", carrierKind: "existingOperationObservation", schemaStableId: "result.existing.operation.observation" };
// @ts-expect-error invalid operation.start.sandbox construction
const invalidStartSandbox: StartSandboxOutcome = { operationId: "operation.start.sandbox", branch: "rejected", requestErrorId: "request.sequence.out.of.range" };
// @ts-expect-error invalid operation.wait.operation construction
const invalidWaitOperation: WaitOperationOutcome = { operationId: "operation.wait.operation", branch: "accepted", carrierKind: "observation", schemaStableId: "result.operation.wait.observation" };
// @ts-expect-error invalid operation.write.process.input construction
const invalidWriteProcessInput: WriteProcessInputOutcome = { operationId: "operation.write.process.input", branch: "accepted", carrierKind: "existingOperationObservation", schemaStableId: "result.process.control.receipt" };

void [
  validCancelOperation,
  validStartSandbox,
  validWaitOperation,
  validWriteProcessInput,
];
