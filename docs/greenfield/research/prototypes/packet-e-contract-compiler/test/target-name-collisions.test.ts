import { readFile } from "node:fs/promises";

import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

import { generateGo } from "../src/generate/go.js";
import { generateOpenApi } from "../src/generate/openapi.js";
import { generateProtobuf } from "../src/generate/protobuf.js";
import { generatePython } from "../src/generate/python.js";
import { generateRust } from "../src/generate/rust.js";
import { generateTypeScript } from "../src/generate/typescript.js";
import { lowerContract } from "../src/lower.js";
import { closedSum, type ContractModel } from "../src/model.js";

const { compile } = createTester(new URL("../", import.meta.url).pathname, {
  libraries: ["contract"],
});

async function contractModel(): Promise<ContractModel> {
  const source = await readFile(
    new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url),
    "utf8",
  );
  return lowerContract((await compile(source)).program);
}

function withFirstStateVariantIds(
  model: ContractModel,
  firstId: string,
  secondId: string,
): ContractModel {
  const targetId = closedSum(model, "state.operation").id;
  return {
    ...model,
    closedSums: model.closedSums.map((sum) =>
      sum.id === targetId
        ? {
            ...sum,
            variants: sum.variants.map((variant, index) =>
              index === 0
                ? { ...variant, id: firstId }
                : index === 1
                  ? { ...variant, id: secondId }
                  : variant,
            ),
          }
        : sum,
    ),
  };
}

function withFirstStateId(
  model: ContractModel,
  stableId: string,
): ContractModel {
  const targetId = closedSum(model, "state.operation").id;
  return {
    ...model,
    closedSums: model.closedSums.map((sum) =>
      sum.id === targetId ? { ...sum, id: stableId } : sum,
    ),
  };
}

function withFirstOperationIds(
  model: ContractModel,
  firstId: string,
  secondId: string,
): ContractModel {
  return {
    ...model,
    operations: model.operations.map((operation, index) =>
      index === 0
        ? { ...operation, operationId: `operation.${firstId}` }
        : index === 1
          ? { ...operation, operationId: `operation.${secondId}` }
          : operation,
    ),
  };
}

function withVariantIdsAcrossFirstSums(
  model: ContractModel,
  firstId: string,
  secondId: string,
): ContractModel {
  const first = closedSum(model, "state.operation");
  const second = closedSum(model, "state.process");
  return {
    ...model,
    closedSums: model.closedSums.map((sum) => {
      const id =
        sum.id === first.id
          ? firstId
          : sum.id === second.id
            ? secondId
            : undefined;
      if (id === undefined) return sum;
      return {
        ...sum,
        variants: sum.variants.map((variant, index) =>
          index === 0 ? { ...variant, id } : variant,
        ),
      };
    }),
  };
}

function withOpenApiComponentCollision(model: ContractModel): ContractModel {
  const first = closedSum(model, "state.operation");
  const second = closedSum(model, "state.process");
  return {
    ...model,
    closedSums: model.closedSums.map((sum) => {
      if (sum.id === first.id) {
        return {
          ...sum,
          id: "a",
          variants: sum.variants.map((variant, index) =>
            index === 0 ? { ...variant, id: "b.c" } : variant,
          ),
        };
      }
      if (sum.id === second.id) {
        return {
          ...sum,
          id: "a.b",
          variants: sum.variants.map((variant, index) =>
            index === 0 ? { ...variant, id: "c" } : variant,
          ),
        };
      }
      return sum;
    }),
  };
}

const compositeTargets = [
  ["Rust", generateRust],
  ["Go", generateGo],
  ["TypeScript", generateTypeScript],
  ["OpenAPI", generateOpenApi],
] as const;

it("rejects Python enum members that collide only after target transforms", async () => {
  const model = await contractModel();

  expect(() =>
    generatePython(withFirstStateVariantIds(model, "a.a", "aa")),
  ).toThrow("contract/generated-name-collision");
  expect(() =>
    generatePython(withFirstStateVariantIds(model, "a.a", "a.b")),
  ).not.toThrow();
});

it("rejects Python service and decoder names that collide after snake-case transforms", async () => {
  const model = await contractModel();

  expect(() =>
    generatePython(withFirstOperationIds(model, "a.a", "aa")),
  ).toThrow("contract/generated-name-collision");
  expect(() =>
    generatePython(withFirstOperationIds(model, "a.a", "a.b")),
  ).not.toThrow();
});

it("rejects Python keywords after target transforms while near-valid names remain valid", async () => {
  const model = await contractModel();

  expect(() =>
    generatePython(withFirstOperationIds(model, "class", "classic")),
  ).toThrow("contract/generated-name-invalid");
  expect(() =>
    generatePython(
      withFirstOperationIds(model, "classic", "classification"),
    ),
  ).not.toThrow();
});

it("rejects Python keywords in transformed class names", async () => {
  const model = await contractModel();

  expect(() => generatePython(withFirstStateId(model, "none"))).toThrow(
    "contract/generated-name-invalid",
  );
  expect(() =>
    generatePython(withFirstStateId(model, "none.type")),
  ).not.toThrow();
});

it("rejects Protobuf fields that collide only after target transforms", async () => {
  const model = await contractModel();

  expect(() =>
    generateProtobuf(withFirstStateVariantIds(model, "a.a", "aa")),
  ).toThrow("contract/generated-name-collision");
  expect(() =>
    generateProtobuf(withFirstStateVariantIds(model, "a.a", "a.b")),
  ).not.toThrow();
});

it.each(compositeTargets)(
  "rejects a %s sum type colliding with an operation-generated outcome type",
  async (_target, generate) => {
    const model = await contractModel();
    expect(() =>
      generate(withFirstStateId(model, "cancel.operation.outcome")),
    ).toThrow("contract/generated-name-collision");
  },
);

it("rejects OpenAPI component-key collisions before schema assignment", async () => {
  const model = await contractModel();
  expect(() => generateOpenApi(withOpenApiComponentCollision(model))).toThrow(
    "contract/generated-name-collision",
  );
});

it("rejects Rust keywords after operation-name transforms while near-valid names pass", async () => {
  const model = await contractModel();
  expect(() =>
    generateRust(withFirstOperationIds(model, "type", "classic")),
  ).toThrow("contract/generated-name-invalid");
  expect(() =>
    generateRust(withFirstOperationIds(model, "types", "typed")),
  ).not.toThrow();
});

it("rejects Rust sums that shadow unqualified prelude types", async () => {
  const model = await contractModel();
  for (const stableId of ["string", "result"]) {
    expect(() => generateRust(withFirstStateId(model, stableId))).toThrow(
      "contract/generated-name-collision",
    );
  }
  for (const stableId of ["strings", "results"]) {
    expect(() => generateRust(withFirstStateId(model, stableId))).not.toThrow();
  }
});

it("rejects TypeScript service names parsed as construct signatures", async () => {
  const model = await contractModel();
  expect(() =>
    generateTypeScript(withFirstOperationIds(model, "new", "classic")),
  ).toThrow("contract/generated-name-invalid");
  expect(() =>
    generateTypeScript(withFirstOperationIds(model, "constructor", "classic")),
  ).not.toThrow();
});

it("rejects TypeScript sums that shadow unqualified global utility types", async () => {
  const model = await contractModel();
  for (const stableId of ["readonly", "record", "extract", "promise"]) {
    expect(() =>
      generateTypeScript(withFirstStateId(model, stableId)),
    ).toThrow("contract/generated-name-collision");
  }
  for (const stableId of [
    "readonly.value",
    "record.value",
    "extract.value",
    "promise.value",
  ]) {
    expect(() =>
      generateTypeScript(withFirstStateId(model, stableId)),
    ).not.toThrow();
  }
});

it("rejects Go sums that collide with generated package tests", async () => {
  const model = await contractModel();
  expect(() =>
    generateGo(withFirstStateId(model, "test.shared.outcome.fixtures")),
  ).toThrow("contract/generated-name-collision");
  expect(() =>
    generateGo(withFirstStateId(model, "test.shared.outcome.fixture")),
  ).not.toThrow();
});

it.each(compositeTargets)(
  "allows equal %s variant names in genuinely separate scopes",
  async (_target, generate) => {
    const model = await contractModel();
    expect(() =>
      generate(
        withVariantIdsAcrossFirstSums(
          model,
          "shared.variant",
          "shared.variant",
        ),
      ),
    ).not.toThrow();
  },
);
