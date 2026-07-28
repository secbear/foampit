import { readFile } from "node:fs/promises";

import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

import { getContractRoot } from "../src/accessors.js";
import { buildContractBundle } from "../src/emitter.js";
import { lowerContract } from "../src/lower.js";
import {
  closedSum,
  wireIdentities,
  type ContractModel,
  type OperationContract,
} from "../src/model.js";
import { validateContract } from "../src/validate.js";

const { compile, compileAndDiagnose } = createTester(
  new URL("../", import.meta.url).pathname,
  { libraries: ["contract"] },
);

async function fixture(path: string): Promise<string> {
  return readFile(new URL(`../fixtures/${path}/main.tsp`, import.meta.url), "utf8");
}

async function validModel(): Promise<ContractModel> {
  return lowerContract(
    (await compile(await fixture("valid/packet-e-slice"))).program,
  );
}

function replaceOperation(
  model: ContractModel,
  operationId: string,
  replacement: OperationContract,
): ContractModel {
  return {
    ...model,
    operations: model.operations.map((operation) =>
      operation.operationId === operationId ? replacement : operation,
    ),
  };
}

function operation(program: Awaited<ReturnType<typeof compile>>["program"], name: string) {
  return getContractRoot(program)?.operations.get(name);
}

function assertNoRedundantModelFields(model: ContractModel): void {
  // @ts-expect-error states are queried from closedSums, never serialized.
  void model.states;
  // @ts-expect-error registries are queried from closedSums, never serialized.
  void model.registries;
  // @ts-expect-error wire identities are derived from closedSums, never serialized.
  void model.wireIdentities;
}

it("lowers the explicit Packet E vertical slice into a closed model", async () => {
  const program = (await compile(await fixture("valid/packet-e-slice"))).program;
  const model = lowerContract(program);

  assertNoRedundantModelFields(model);
  expect(model).toMatchObject({
    contractModelVersion: "0.1.0",
    contractId: "packet-e-vertical-slice",
    semanticProfile: "packet-e-contract-prototype",
  });
  expect(Object.hasOwn(model, "states")).toBe(false);
  expect(Object.hasOwn(model, "registries")).toBe(false);
  expect(Object.hasOwn(model, "wireIdentities")).toBe(false);
  expect(
    ["state.operation", "state.process", "state.sandbox"].map((id) => {
      const state = closedSum(model, id);
      return [state.id, state.variants.length];
    }),
  ).toEqual([
    ["state.operation", 7],
    ["state.process", 5],
    ["state.sandbox", 4],
  ]);
  expect(model.closedSums).toHaveLength(14);
  expect(new Set(wireIdentities(model).map((identity) => identity.containerId))).toEqual(
    new Set(model.closedSums.map((sum) => sum.id)),
  );
  expect(model.operations.map((operation) => operation.operationId)).toEqual([
    "operation.cancel.operation",
    "operation.start.sandbox",
    "operation.wait.operation",
    "operation.write.process.input",
  ]);
  expect(model.operations.find((operation) => operation.operationId === "operation.start.sandbox")).toMatchObject({
    callClass: "durableOperationMutation",
    allowedRequestErrors: ["request.invalid.state"],
  });
  expect(model.operations.find((operation) => operation.operationId === "operation.write.process.input")).toMatchObject({
    callClass: "sequencedProcessControl",
    allowedRequestErrors: ["request.invalid.state", "request.sequence.out.of.range"],
  });
  expect(model.matrices).toHaveLength(1);
  expect(model.matrices[0]?.cells).toHaveLength(16);
  expect(model.terminalStateIds).toEqual([
    "state.operation.cancelled",
    "state.operation.failed",
    "state.operation.succeeded",
    "state.operation.unknown",
    "state.process.terminated",
  ]);
  expect(validateContract(model)).toEqual([]);
});

it.each([
  "contractModelVersion",
  "contractId",
  "semanticProfile",
] as const)(
  "rejects a forged runtime %s before constructing a bundle",
  async (field) => {
    const model = lowerContract(
      (await compile(await fixture("valid/packet-e-slice"))).program,
    );
    const forged = {
      ...model,
      [field]: "forged.value",
    } as unknown as ContractModel;
    expect(validateContract(forged)).toEqual([
      expect.objectContaining({ code: "contract/invalid-contract-identity" }),
    ]);
    expect(() => buildContractBundle(forged)).toThrow(
      "contract/invalid-contract-model: contract/invalid-contract-identity",
    );
  },
);

it("rejects a forged contract identity before graph validation", async () => {
  const model = lowerContract(
    (await compile(await fixture("valid/packet-e-slice"))).program,
  );
  const forged = {
    ...model,
    contractId: "forged.value",
    terminalStateIds: [],
  } as unknown as ContractModel;
  expect(validateContract(forged)).toEqual([
    expect.objectContaining({ code: "contract/invalid-contract-identity" }),
  ]);
});

it("rejects a transition from an explicit terminal state", async () => {
  const program = (await compile(await fixture("valid/packet-e-slice"))).program;
  const model = lowerContract(program);
  const mutated = {
    ...model,
    matrices: [{
      ...model.matrices[0]!,
      cells: [{
        rowId: "state.operation.succeeded",
        columnId: "operation.start.sandbox",
        kind: "transition" as const,
        nextStateId: "state.operation.running",
      }],
    }],
  };
  expect(validateContract(mutated)).toEqual([
    expect.objectContaining({ code: "contract/terminal-state-transition" }),
  ]);
});

it("rejects a transition from the immutable operation unknown state", async () => {
  const program = (await compile(await fixture("valid/packet-e-slice"))).program;
  const model = lowerContract(program);
  const mutated = {
    ...model,
    matrices: [{
      ...model.matrices[0]!,
      cells: [{
        rowId: "state.operation.unknown",
        columnId: "operation.start.sandbox",
        kind: "transition" as const,
        nextStateId: "state.operation.running",
      }],
    }],
  };
  expect(validateContract(mutated)).toEqual([
    expect.objectContaining({ code: "contract/terminal-state-transition" }),
  ]);
});

it("rejects a seventeenth cell that duplicates a complete matrix coordinate", async () => {
  const model = lowerContract(
    (await compile(await fixture("valid/packet-e-slice"))).program,
  );
  const matrix = model.matrices[0]!;
  const mutated = {
    ...model,
    matrices: [
      {
        ...matrix,
        cells: [...matrix.cells, matrix.cells[0]!],
      },
    ],
  };
  expect(validateContract(mutated)).toEqual([
    expect.objectContaining({ code: "contract/duplicate-matrix-cell" }),
  ]);
});

it("orders wildcard, terminal, duplicate, incomplete, and extra matrix diagnostics", async () => {
  const model = lowerContract(
    (await compile(await fixture("valid/packet-e-slice"))).program,
  );
  const matrix = model.matrices[0]!;
  const duplicateCells = [...matrix.cells, matrix.cells[0]!];
  const extraCell = {
    rowId: "state.sandbox.unexpected",
    columnId: matrix.columnIds[0]!,
    kind: "noop" as const,
  };
  const terminalTransition = {
    rowId: "state.operation.succeeded",
    columnId: matrix.columnIds[0]!,
    kind: "transition" as const,
    nextStateId: matrix.rowIds[0]!,
  };
  const codeFor = (
    mutation: Partial<(typeof model.matrices)[number]>,
  ): string | undefined =>
    validateContract({
      ...model,
      matrices: [{ ...matrix, ...mutation }],
    })[0]?.code;

  expect(
    codeFor({
      rowIds: [...matrix.rowIds, "*"],
      cells: duplicateCells,
    }),
  ).toBe("contract/wildcard-cell-forbidden");
  expect(
    codeFor({ cells: [...duplicateCells, terminalTransition] }),
  ).toBe("contract/terminal-state-transition");
  expect(
    codeFor({
      cells: [
        ...matrix.cells.slice(0, -1),
        matrix.cells[0]!,
        extraCell,
      ],
    }),
  ).toBe("contract/duplicate-matrix-cell");
  expect(
    codeFor({
      cells: [...matrix.cells.slice(0, -1), extraCell],
    }),
  ).toBe("contract/incomplete-matrix");
  expect(codeFor({ cells: [...matrix.cells, extraCell] })).toBe(
    "contract/extra-matrix-cell",
  );
});

it.each([
  {
    name: "row",
    mutate: (source: string) =>
      source.replace(
        `    "state.sandbox.unknown"
  ],
  columnOperationIds:`,
        `    "state.sandbox.unknown",
    "state.sandbox.stopped"
  ],
  columnOperationIds:`,
      ),
  },
  {
    name: "column",
    mutate: (source: string) =>
      source.replace(
        `    "operation.wait.operation"
  ],
  cells:`,
        `    "operation.wait.operation",
    "operation.start.sandbox"
  ],
  cells:`,
      ),
  },
])("rejects a source-expressible duplicate matrix $name axis", async ({ mutate }) => {
  const original = await fixture("valid/packet-e-slice");
  const source = mutate(original);
  expect(source).not.toBe(original);
  const program = (await compile(source)).program;
  const model = lowerContract(program);
  expect(validateContract(model)[0]?.code).toBe(
    "contract/duplicate-matrix-axis",
  );
  expect(() => buildContractBundle(model)).toThrow(
    "contract/invalid-contract-model: contract/duplicate-matrix-axis",
  );
});

it.each(["rowIds", "columnIds", "cells"] as const)(
  "rejects reversed matrix %s before constructing a bundle",
  async (field) => {
    const model = await validModel();
    const matrix = model.matrices[0]!;
    const mutated = {
      ...model,
      matrices: [
        {
          ...matrix,
          [field]: [...matrix[field]].reverse(),
        },
      ],
    };
    expect(validateContract(mutated)).toEqual([
      expect.objectContaining({
        code: "contract/noncanonical-contract-collection",
      }),
    ]);
    expect(() => buildContractBundle(mutated)).toThrow(
      "contract/invalid-contract-model: contract/noncanonical-contract-collection",
    );
  },
);

it.each([
  {
    name: "row",
    mutate: (matrix: ContractModel["matrices"][number]) => ({
      ...matrix,
      rowIds: matrix.rowIds.map((rowId) =>
        rowId === "state.sandbox.unknown"
          ? "state.sandbox.unexpected"
          : rowId,
      ),
      cells: matrix.cells.map((cell) => ({
        ...cell,
        rowId:
          cell.rowId === "state.sandbox.unknown"
            ? "state.sandbox.unexpected"
            : cell.rowId,
      })),
    }),
  },
  {
    name: "column",
    mutate: (matrix: ContractModel["matrices"][number]) => ({
      ...matrix,
      columnIds: matrix.columnIds.map((columnId) =>
        columnId === "operation.write.process.input"
          ? "operation.zzz"
          : columnId,
      ),
      cells: matrix.cells.map((cell) => ({
        ...cell,
        columnId:
          cell.columnId === "operation.write.process.input"
            ? "operation.zzz"
            : cell.columnId,
      })),
    }),
  },
])(
  "rejects a canonical but out-of-profile matrix $name axis",
  async ({ mutate }) => {
    const model = await validModel();
    const mutated = {
      ...model,
      matrices: [mutate(model.matrices[0]!)],
    };
    expect(validateContract(mutated)).toEqual([
      expect.objectContaining({ code: "contract/matrix-axis-mismatch" }),
    ]);
    expect(() => buildContractBundle(mutated)).toThrow(
      "contract/invalid-contract-model: contract/matrix-axis-mismatch",
    );
  },
);

it.each([
  {
    name: "result branches",
    mutate: (operation: OperationContract): OperationContract => ({
      ...operation,
      resultBranches: [...operation.resultBranches].reverse(),
    }),
  },
  {
    name: "recovery coordinates",
    mutate: (operation: OperationContract): OperationContract => ({
      ...operation,
      recoveryCoordinates: [...operation.recoveryCoordinates].reverse(),
    }),
  },
  {
    name: "matrix references",
    mutate: (operation: OperationContract): OperationContract => ({
      ...operation,
      matrixIds: [...operation.matrixIds, operation.matrixIds[0]!],
    }),
  },
])(
  "rejects noncanonical operation $name before constructing a bundle",
  async ({ name, mutate }) => {
    const model = await validModel();
    const selected =
      name === "recovery coordinates"
        ? model.operations.find(
            (operation) =>
              operation.operationId === "operation.write.process.input",
          )!
        : model.operations.find(
            (operation) =>
              operation.operationId === "operation.start.sandbox",
          )!;
    const mutated = replaceOperation(
      model,
      selected.operationId,
      mutate(selected),
    );
    expect(validateContract(mutated)).toEqual([
      expect.objectContaining({
        code: "contract/noncanonical-contract-collection",
      }),
    ]);
    expect(() => buildContractBundle(mutated)).toThrow(
      "contract/invalid-contract-model: contract/noncanonical-contract-collection",
    );
  },
);

it("validates exact selected-profile operation fields for all four operations", async () => {
  const model = await validModel();
  for (const operation of model.operations) {
    const alternateCallClass =
      operation.callClass === "durableOperationMutation"
        ? "existingHandleIntent"
        : "durableOperationMutation";
    const recoveryCoordinates =
      operation.recoveryCoordinates.length === 0
        ? [{ kind: "idempotencyKey" as const, value: "forged.coordinate" }]
        : operation.recoveryCoordinates.map((coordinate, index) =>
            index === 0
              ? { ...coordinate, value: `${coordinate.value}.forged` }
              : coordinate,
          );
    const mismatches: readonly OperationContract[] = [
      {
        ...operation,
        callClass: alternateCallClass,
      },
      {
        ...operation,
        result: {
          ...operation.result,
          carrierKind:
            operation.result.carrierKind === "observation"
              ? "newDurableOperation"
              : "observation",
        },
      },
      {
        ...operation,
        result: {
          ...operation.result,
          schemaStableId: "result.forged",
        },
      },
      {
        ...operation,
        matrixIds: ["matrix.forged"],
      },
      {
        ...operation,
        recoveryCoordinates,
      },
    ];
    for (const mismatch of mismatches) {
      const mutated = replaceOperation(
        model,
        operation.operationId,
        mismatch,
      );
      const expectedCode =
        operation.callClass === "observation" &&
        mismatch.callClass !== "observation"
          ? "contract/contradictory-outcome"
          : "contract/operation-contract-mismatch";
      expect(validateContract(mutated)[0]?.code).toBe(expectedCode);
      expect(() => buildContractBundle(mutated)).toThrow(
        `contract/invalid-contract-model: ${expectedCode}`,
      );
    }
  }
});

it("validates every selected-profile operation error set", async () => {
  const model = await validModel();
  const fields = [
    "allowedRequestErrors",
    "allowedRecoveryErrors",
    "allowedKnownFailures",
    "allowedAmbiguities",
  ] as const;
  for (const operation of model.operations) {
    for (const field of fields) {
      const mutatedOperation = {
        ...operation,
        [field]: [...operation[field], `${field}.forged`].sort(),
      };
      const mutated = replaceOperation(
        model,
        operation.operationId,
        mutatedOperation,
      );
      const expectedCode =
        field === "allowedRecoveryErrors" &&
        operation.allowedRecoveryErrors.length === 0
          ? "contract/error-result-branch-mismatch"
          : "contract/inadmissible-error";
      expect(validateContract(mutated)[0]?.code).toBe(expectedCode);
    }
  }
});

it("requires carrier branches for declared error registries", async () => {
  const program = (await compile(await fixture("valid/packet-e-slice"))).program;
  const model = lowerContract(program);
  const mutated = { ...model, operations: model.operations.map((operation) => operation.operationId === "operation.wait.operation" ? { ...operation, resultBranches: ["observed" as const] } : operation) };
  expect(validateContract(mutated)).toEqual([expect.objectContaining({ code: "contract/error-result-branch-mismatch" })]);
});

it("rejects an unreachable error carrier branch", async () => {
  const model = lowerContract((await compile(await fixture("valid/packet-e-slice"))).program);
  const mutated = { ...model, operations: model.operations.map((operation) => operation.operationId === "operation.wait.operation" ? { ...operation, resultBranches: ["observed" as const, "rejected" as const, "recovery" as const] } : operation) };
  expect(validateContract(mutated)).toEqual([expect.objectContaining({ code: "contract/error-result-branch-mismatch" })]);
});

it("rejects duplicate result branches before set semantics", async () => {
  const model = lowerContract((await compile(await fixture("valid/packet-e-slice"))).program);
  const mutated = { ...model, operations: model.operations.map((operation) => operation.operationId === "operation.wait.operation" ? { ...operation, resultBranches: ["observed" as const, "rejected" as const, "rejected" as const] } : operation) };
  expect(validateContract(mutated)).toEqual([expect.objectContaining({ code: "contract/duplicate-result-branch" })]);
});

it("rejects an out-of-domain wire tag in a plain model", async () => {
  const model = lowerContract((await compile(await fixture("valid/packet-e-slice"))).program);
  const mutated = { ...model, closedSums: model.closedSums.map((sum, index) => index === 0 ? { ...sum, variants: sum.variants.map((variant, variantIndex) => variantIndex === 0 ? { ...variant, wireTag: "19000" } : variant) } : sum) };
  expect(validateContract(mutated)).toEqual([expect.objectContaining({ code: "contract/invalid-wire-tag" })]);
});

it("rejects a complete source graph with one stable variant wire tag removed", async () => {
  const source = (await fixture("valid/packet-e-slice")).replace(
    '@stableId("state.sandbox.stopped") @wireTag("1")',
    '@stableId("state.sandbox.stopped")',
  );
  const [, diagnostics] = await compileAndDiagnose(source);
  expect(diagnostics).toEqual([
    expect.objectContaining({ code: "contract/missing-wire-tag" }),
  ]);
});

it("rejects a plain model with one stable variant wire tag removed", async () => {
  const model = lowerContract((await compile(await fixture("valid/packet-e-slice"))).program);
  const mutated = { ...model, closedSums: model.closedSums.map((sum, index) => index === 0 ? { ...sum, variants: sum.variants.map((variant, variantIndex) => variantIndex === 0 ? { id: variant.id } : variant) } : sum) };
  expect(validateContract(mutated)).toEqual([expect.objectContaining({ code: "contract/missing-wire-tag" })]);
});

it("derives wire identities deterministically from tagged closed-sum variants", async () => {
  const model = lowerContract((await compile(await fixture("valid/packet-e-slice"))).program);
  expect(
    wireIdentities(model)
      .filter((identity) => identity.containerId === "registry.operation.outcome")
      .map((identity) => [identity.variantId, identity.wireTag]),
  ).toEqual(
    [
      ["outcome.accepted", "1"],
      ["outcome.rejected", "2"],
      ["outcome.recovery", "3"],
      ["outcome.observed", "4"],
    ],
  );
  expect(wireIdentities({
    ...model,
    closedSums: [...model.closedSums].reverse(),
  })).toEqual(wireIdentities(model));
});

it("rejects duplicate wire tags directly within a closed sum", async () => {
  const model = lowerContract((await compile(await fixture("valid/packet-e-slice"))).program);
  const mutated = {
    ...model,
    closedSums: model.closedSums.map((sum) =>
      sum.id === "registry.request.error"
        ? {
            ...sum,
            variants: sum.variants.map((variant) =>
              variant.id === "request.sequence.out.of.range"
                ? { ...variant, wireTag: "1" }
                : variant,
            ),
          }
        : sum,
    ),
  };
  expect(validateContract(mutated)).toEqual([
    expect.objectContaining({ code: "contract/duplicate-wire-identity" }),
  ]);
});

it("rejects a vertical slice that omits or adds a declared operation or registry", async () => {
  const program = (await compile(await fixture("valid/packet-e-slice"))).program;
  const model = lowerContract(program);
  expect(validateContract({ ...model, operations: model.operations.slice(1) })).toEqual([
    expect.objectContaining({ code: "contract/invalid-contract-universe" }),
  ]);
  expect(validateContract({ ...model, operations: [...model.operations, model.operations[0]!] })).toEqual([
    expect.objectContaining({ code: "contract/invalid-contract-universe" }),
  ]);
  expect(validateContract({ ...model, closedSums: model.closedSums.filter((sum) => sum.id !== "registry.provider.evidence") })).toEqual([
    expect.objectContaining({ code: "contract/invalid-contract-universe" }),
  ]);
  expect(validateContract({ ...model, closedSums: [...model.closedSums, { id: "registry.unexpected", variants: [] }] })).toEqual([
    expect.objectContaining({ code: "contract/invalid-contract-universe" }),
  ]);
});

it.each([
  ["invalid/missing-matrix-cell", "contract/incomplete-matrix", "root"],
  ["invalid/extra-error-variant", "contract/inadmissible-error", "StartSandbox"],
  ["invalid/contradictory-outcome", "contract/contradictory-outcome", "StartSandbox"],
  ["invalid/missing-recovery-coordinate", "contract/missing-recovery-coordinate", "StartSandbox"],
  ["invalid/observed-and-accepted", "contract/conflicting-result-branch", "WaitOperation"],
  ["invalid/missing-error-result-branch", "contract/error-result-branch-mismatch", "WaitOperation"],
])("reports %s against its explicit source target", async (path, code, targetName) => {
  const program = (await compile(await fixture(path))).program;
  const target = targetName === "root" ? getContractRoot(program) : operation(program, targetName);
  expect(validateContract(lowerContract(program))).toEqual([
    expect.objectContaining({ code, target }),
  ]);
});

it("rejects wildcard matrix cells against the contract root", async () => {
  const [result, diagnostics] = await compileAndDiagnose(
    await fixture("invalid/wildcard-matrix-cell"),
  );
  expect(diagnostics).toEqual([
    expect.objectContaining({
      code: "contract/wildcard-cell-forbidden",
      target: getContractRoot(result.program),
    }),
  ]);
});
