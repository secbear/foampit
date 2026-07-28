import { readFile } from "node:fs/promises";

import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

import {
  getMatrixDefinitions,
  getOperationDefinition,
  getStableId,
} from "../src/accessors.js";
import type { OperationDefinitionValue } from "../src/definition.js";

const { compile, diagnose } = createTester(new URL("../", import.meta.url).pathname, {
  libraries: ["contract"],
});

const validFixture = await readFile(
  new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url),
  "utf8",
);

function operation(program: Awaited<ReturnType<typeof compile>>["program"], name: string) {
  const root = program.getGlobalNamespaceType().namespaces.get("PacketE");
  return root?.operations.get(name);
}

function metadata(overrides = ""): string {
  return `#{
    operationId: "operation.start.sandbox",
    callClass: "durableOperationMutation",
    resultBranches: #["accepted", "rejected", "recovery"],
    allowedRequestErrors: #["request.invalid.state"],
    allowedRecoveryErrors: #["recovery.idempotency.expired"],
    allowedKnownFailures: #["failure.runtime.provisioning"],
    allowedAmbiguities: #["ambiguity.runtime.unknown"],
    recoveryCoordinates: #[#{ kind: "runtimeEpoch", value: "sandbox.runtime.epoch" }],
    matrixIds: #["matrix.sandbox-operation"],${overrides}
    result: #{ carrierKind: "newDurableOperation", schemaStableId: "result.operation.start.sandbox" }
  }`;
}

it("retains literal explicit metadata for the vertical-slice operations", async () => {
  const result = await compile(validFixture);
  const start = getOperationDefinition(result.program, operation(result.program, "StartSandbox")!);
  const cancel = getOperationDefinition(result.program, operation(result.program, "CancelOperation")!);
  const write = getOperationDefinition(result.program, operation(result.program, "WriteProcessInput")!);
  const wait = getOperationDefinition(result.program, operation(result.program, "WaitOperation")!);

  expect(start).toEqual<OperationDefinitionValue>({
    operationId: "operation.start.sandbox",
    callClass: "durableOperationMutation",
    resultBranches: ["accepted", "recovery", "rejected"],
    allowedRequestErrors: ["request.invalid.state"],
    allowedRecoveryErrors: ["recovery.idempotency.expired"],
    allowedKnownFailures: ["failure.runtime.provisioning"],
    allowedAmbiguities: ["ambiguity.runtime.unknown"],
    recoveryCoordinates: [
      { kind: "idempotencyKey", value: "start.idempotency-key" },
      { kind: "runtimeEpoch", value: "sandbox.runtime.epoch" },
    ],
    matrixIds: ["matrix.sandbox-operation"],
    result: {
      carrierKind: "newDurableOperation",
      schemaStableId: "result.operation.start.sandbox",
    },
  });
  expect(cancel).toEqual<OperationDefinitionValue>({
    operationId: "operation.cancel.operation",
    callClass: "existingHandleIntent",
    resultBranches: ["accepted", "recovery", "rejected"],
    allowedRequestErrors: ["request.invalid.state"],
    allowedRecoveryErrors: ["recovery.idempotency.expired"],
    allowedKnownFailures: [],
    allowedAmbiguities: ["ambiguity.runtime.unknown"],
    recoveryCoordinates: [
      { kind: "operationId", value: "existing.operation.id" },
    ],
    matrixIds: ["matrix.sandbox-operation"],
    result: {
      carrierKind: "existingOperationObservation",
      schemaStableId: "result.existing.operation.observation",
    },
  });
  expect(write).toEqual<OperationDefinitionValue>({
    operationId: "operation.write.process.input",
    callClass: "sequencedProcessControl",
    resultBranches: ["accepted", "recovery", "rejected"],
    allowedRequestErrors: [
      "request.invalid.state",
      "request.sequence.out.of.range",
    ],
    allowedRecoveryErrors: ["recovery.idempotency.expired"],
    allowedKnownFailures: [],
    allowedAmbiguities: ["ambiguity.runtime.unknown"],
    recoveryCoordinates: [
      { kind: "processId", value: "process.id" },
      { kind: "runtimeEpoch", value: "sandbox.runtime.epoch" },
      { kind: "sequence", value: "process.input.sequence" },
      { kind: "writerLease", value: "process.writer.lease" },
    ],
    matrixIds: ["matrix.sandbox-operation"],
    result: {
      carrierKind: "processControlReceipt",
      schemaStableId: "result.process.control.receipt",
    },
  });
  expect(wait).toEqual<OperationDefinitionValue>({
    operationId: "operation.wait.operation",
    callClass: "observation",
    resultBranches: ["observed", "rejected"],
    allowedRequestErrors: ["request.invalid.state"],
    allowedRecoveryErrors: [],
    allowedKnownFailures: [],
    allowedAmbiguities: [],
    recoveryCoordinates: [],
    matrixIds: ["matrix.sandbox-operation"],
    result: {
      carrierKind: "observation",
      schemaStableId: "result.operation.wait.observation",
    },
  });
  expect(getStableId(result.program, operation(result.program, "StartSandbox")!.returnType)).toBe(
    "result.operation.start.sandbox",
  );
  expect(getStableId(result.program, operation(result.program, "CancelOperation")!.returnType)).toBe(
    "result.existing.operation.observation",
  );
  expect(getStableId(result.program, operation(result.program, "WriteProcessInput")!.returnType)).toBe(
    "result.process.control.receipt",
  );
  expect(getStableId(result.program, operation(result.program, "WaitOperation")!.returnType)).toBe(
    "result.operation.wait.observation",
  );
  expect(getMatrixDefinitions(result.program)).toEqual([
    expect.objectContaining({
      matrixId: "matrix.sandbox-operation",
      rowStateIds: [
        "state.sandbox.provisioning",
        "state.sandbox.running",
        "state.sandbox.stopped",
        "state.sandbox.unknown",
      ],
      columnOperationIds: [
        "operation.cancel.operation",
        "operation.start.sandbox",
        "operation.wait.operation",
        "operation.write.process.input",
      ],
      cells: expect.any(Array),
    }),
  ]);
  expect(getMatrixDefinitions(result.program)[0]?.cells).toHaveLength(16);
});

it.each([
  "operationId",
  "callClass",
  "resultBranches",
  "allowedRequestErrors",
  "allowedRecoveryErrors",
  "allowedKnownFailures",
  "allowedAmbiguities",
  "recoveryCoordinates",
  "matrixIds",
  "result",
])("rejects an operation definition missing %s", async (field) => {
  const source = `
    import "contract";
    using PacketE.Contract;

    @contractRoot namespace PacketE {
      @operationContract(${metadata().replace(new RegExp(`\\n\\s*${field}: [^\\n]+,?`), "")})
      op StartSandbox(): void;
    }
  `;

  expect(await diagnose(source)).toEqual(
    expect.arrayContaining([expect.objectContaining({ code: "invalid-argument" })]),
  );
});

it("rejects wildcard matrix state coordinates", async () => {
  expect(await diagnose(`
    import "contract";
    using PacketE.Contract;

    @contractRoot
    @contractMatrix(#{
      matrixId: "matrix.sandbox-operation",
      rowStateIds: #["*"],
      columnOperationIds: #["operation.start-sandbox"],
      cells: #[#{
        rowStateId: "*",
        columnOperationId: "operation.start-sandbox",
        kind: "noop",
        nextStateId: "",
        requestErrorId: ""
      }]
    })
    namespace PacketE {}
  `)).toEqual(
    expect.arrayContaining([
      expect.objectContaining({ code: "contract/wildcard-cell-forbidden" }),
    ]),
  );
});
