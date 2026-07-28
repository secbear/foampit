import { execFile } from "node:child_process";
import {
  copyFile,
  mkdtemp,
  readFile,
  rm,
  writeFile,
} from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

import { generateQuint } from "../src/generate/quint.js";
import { lowerContract } from "../src/lower.js";
import type { ContractModel } from "../src/model.js";

const execute = promisify(execFile);
const { compile } = createTester(new URL("../", import.meta.url).pathname, {
  libraries: ["contract"],
});

const quintMainArguments = [
  "--main=PacketEInvariants",
  "--init=init",
  "--step=step",
] as const;
const quintCommandTimeoutMs = {
  typecheck: 20_000,
  run: 90_000,
  verify: 140_000,
} as const;

const mutants = [
  {
    action: "mutantRejectedRequestCreatesEffects",
    invariant: "rejectedRequestHasNoHandleOrDispatch",
  },
  {
    action: "mutantPersistsIntentAndDispatchesAtomically",
    invariant: "dispatchRequiresDurableIntent",
  },
  {
    action: "mutantEqualReplayReturnsDifferentHandle",
    invariant: "equalReplayReturnsSameHandle",
  },
  {
    action: "mutantConflictingReplayMutatesResource",
    invariant: "conflictingReplayHasNoEffect",
  },
  {
    action: "mutantStaleEpochRetainsAuthority",
    invariant: "staleEpochHasNoAuthority",
  },
  {
    action: "mutantSuccessWithoutExactPostcondition",
    invariant: "successRequiresExactPostcondition",
  },
  {
    action: "mutantFailureWhilePossiblyActing",
    invariant: "failedOrCancelledHasNoPossiblyActingAuthority",
  },
  {
    action: "mutantUnknownDispatchesBlindSuccessor",
    invariant: "terminalUnknownHasNoBlindSuccessor",
  },
  {
    action: "mutantRewritesTerminalOperation",
    invariant: "terminalOperationIsImmutable",
  },
  {
    action: "mutantWaitTimeoutMutatesResource",
    invariant: "waitTimeoutDoesNotMutateResource",
  },
  {
    action: "mutantProviderAcknowledgementEstablishesSuccess",
    invariant: "providerAcknowledgementDoesNotEstablishSuccess",
  },
] as const;

async function contractModel() {
  const source = await readFile(
    new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url),
    "utf8",
  );
  return lowerContract((await compile(source)).program);
}

function decode(bytes: Uint8Array): string {
  return new TextDecoder().decode(bytes);
}

function executeQuint(
  command: keyof typeof quintCommandTimeoutMs,
  arguments_: readonly string[],
  cwd: string,
) {
  return execute("quint", [command, ...arguments_], {
    cwd,
    signal: AbortSignal.timeout(quintCommandTimeoutMs[command]),
  });
}

function withFirstSumId(
  model: ContractModel,
  id: string,
): ContractModel {
  return {
    ...model,
    closedSums: model.closedSums.map((sum, index) =>
      index === 0 ? { ...sum, id } : sum,
    ),
  };
}

function withFirstVariantId(
  model: ContractModel,
  id: string,
): ContractModel {
  return {
    ...model,
    closedSums: model.closedSums.map((sum, sumIndex) =>
      sumIndex === 0
        ? {
            ...sum,
            variants: sum.variants.map((variant, variantIndex) =>
              variantIndex === 0 ? { ...variant, id } : variant,
            ),
          }
        : sum,
    ),
  };
}

function withOperationIds(
  model: ContractModel,
  firstId: string,
  secondId: string,
): ContractModel {
  return {
    ...model,
    operations: model.operations.map((operation, index) =>
      index === 0
        ? { ...operation, operationId: firstId }
        : index === 1
          ? { ...operation, operationId: secondId }
          : operation,
    ),
  };
}

function withFirstMatrixId(
  model: ContractModel,
  id: string,
): ContractModel {
  return {
    ...model,
    matrices: model.matrices.map((matrix, index) =>
      index === 0 ? { ...matrix, id } : matrix,
    ),
  };
}

async function quintWorkspace(): Promise<string> {
  const root = await mkdtemp(join(tmpdir(), "packet-e-quint-"));
  try {
    const model = await contractModel();
    const contract = generateQuint(model)[0]!;
    await writeFile(join(root, "contract.qnt"), contract.bytes);
    for (const name of ["machine.qnt", "invariants.qnt", "mutants.qnt"]) {
      await copyFile(
        new URL(`./handwritten/${name}`, import.meta.url),
        join(root, name),
      );
    }
    return root;
  } catch (error) {
    await rm(root, { recursive: true, force: true });
    throw error;
  }
}

it("generates only ContractModel-derived Quint vocabulary", async () => {
  const model = await contractModel();
  const files = generateQuint(model);

  expect(files.map((file) => file.relativePath)).toEqual([
    "quint/contract.qnt",
  ]);
  const source = decode(files[0]!.bytes);
  expect(source).toContain("module PacketEContract {");
  expect(source).toContain(
    'pure val stateOperation: Set[str] = Set("state.operation.accepted"',
  );
  expect(source).toContain(
    'pure val stateOperationSucceeded = "state.operation.succeeded"',
  );
  expect(source).toContain(
    'pure val operationStartSandbox = "operation.start.sandbox"',
  );
  expect(source).toContain(
    'pure val terminalStateIds: Set[str] = Set("state.operation.cancelled"',
  );
  expect(source).toContain(
    'pure val matrixSandboxOperationRows: Set[str] = Set("state.sandbox.provisioning"',
  );
  expect(source).toContain(
    'pure val matrixSandboxOperationCells: Set[str] = Set(',
  );
  expect(source).not.toMatch(/^\s*(?:var|action|run|temporal)\s/m);
  expect(source).not.toContain("dispatchCount");
  expect(source).not.toContain("possiblyActing");
  expect(source).not.toContain("blindSuccessor");
});

it("rejects collisions with every fixed module symbol", async () => {
  const model = await contractModel();
  for (const stableId of [
    "contract.model.version",
    "contract.id",
    "semantic.profile",
    "terminal.state.ids",
  ]) {
    expect(() => generateQuint(withFirstSumId(model, stableId))).toThrow(
      "contract/generated-name-collision",
    );
  }
});

it("rejects every derived suffix collision before emitting Quint", async () => {
  const model = await contractModel();

  expect(() =>
    generateQuint(
      withFirstVariantId(
        withFirstSumId(model, "probe"),
        "probe.wire.identities",
      ),
    ),
  ).toThrow("contract/generated-name-collision");

  for (const suffix of [
    "call.class",
    "result.branches",
    "allowed.request.errors",
    "allowed.recovery.errors",
    "allowed.known.failures",
    "allowed.ambiguities",
    "recovery.coordinates",
    "matrix.ids",
    "result.carrier.kind",
    "result.schema.stable.id",
  ]) {
    expect(() =>
      generateQuint(withOperationIds(model, "probe", `probe.${suffix}`)),
    ).toThrow("contract/generated-name-collision");
  }

  for (const suffix of ["rows", "columns", "cells"]) {
    expect(() =>
      generateQuint(
        withFirstVariantId(
          withFirstMatrixId(model, "probe"),
          `probe.${suffix}`,
        ),
      ),
    ).toThrow("contract/generated-name-collision");
  }
});

it("rejects cross-category and separator-erasure module collisions", async () => {
  const model = await contractModel();
  const crossCategory = {
    ...withFirstSumId(model, "shared.symbol"),
    operations: model.operations.map((operation, index) =>
      index === 0
        ? { ...operation, operationId: "shared.symbol" }
        : operation,
    ),
  };
  expect(() => generateQuint(crossCategory)).toThrow(
    "contract/generated-name-collision",
  );

  expect(() =>
    generateQuint(withOperationIds(model, "a.b", "a-b")),
  ).toThrow("contract/generated-name-collision");

  expect(() =>
    generateQuint(withOperationIds(model, "case.name", "casename")),
  ).not.toThrow();
});

it("rejects every Quint 0.32 reserved declaration identifier", async () => {
  const model = await contractModel();
  for (const stableId of [
    "module",
    "const",
    "var",
    "assume",
    "val",
    "pure",
    "type",
    "def",
    "action",
    "run",
    "temporal",
    "nondet",
    "int",
    "str",
    "bool",
    "all",
    "any",
    "if",
    "else",
    "and",
    "or",
    "iff",
    "implies",
    "leads.to",
    "match",
    "import",
    "export",
    "true",
    "false",
  ]) {
    expect(() => generateQuint(withFirstSumId(model, stableId))).toThrow(
      "contract/generated-name-invalid",
    );
  }
});

it(
  "typechecks the generated vocabulary with handwritten machine and invariants",
  async () => {
    const root = await quintWorkspace();
    try {
      const machine = await readFile(join(root, "machine.qnt"), "utf8");
      const invariants = await readFile(join(root, "invariants.qnt"), "utf8");
      expect(machine).toContain(
        'import PacketEContract.* from "./contract"',
      );
      expect(invariants).toContain(
        'import PacketEMachine.* from "./machine"',
      );
      expect(`${machine}\n${invariants}`).not.toMatch(
        /from\s+["'][^"']+\.qnt["']/,
      );
      await executeQuint(
        "typecheck",
        [join(root, "invariants.qnt")],
        root,
      );
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  },
  30_000,
);

it(
  "runs deterministic reference traces and checks every invariant",
  async () => {
    const root = await quintWorkspace();
    try {
      const output = join(root, "run.json");
      await executeQuint(
        "run",
        [
          join(root, "invariants.qnt"),
          ...quintMainArguments,
          "--invariant=allInvariants",
          "--max-samples=10000",
          "--max-steps=20",
          "--n-threads=1",
          "--seed=0x5061636b",
          "--backend=rust",
          "--verbosity=1",
          `--out=${output}`,
        ],
        root,
      );
      const result = JSON.parse(await readFile(output, "utf8")) as {
        status?: string;
      };
      expect(result.status).toBe("ok");
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  },
  120_000,
);

it(
  "finds no invariant violation through eight reference transitions",
  async () => {
    const root = await quintWorkspace();
    try {
      const output = join(root, "verify.json");
      await executeQuint(
        "verify",
        [
          join(root, "invariants.qnt"),
          ...quintMainArguments,
          "--invariant=allInvariants",
          "--max-steps=8",
          "--backend=apalache",
          "--verbosity=1",
          `--out=${output}`,
        ],
        root,
      );
      const result = JSON.parse(await readFile(output, "utf8")) as {
        status?: string;
      };
      expect(result.status).toBe("ok");
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  },
  180_000,
);

it.each(mutants)(
  "typechecks and kills $action with $invariant",
  async ({ action, invariant }) => {
    const root = await quintWorkspace();
    try {
      const invariantPath = join(root, "invariants.qnt");
      const source = await readFile(invariantPath, "utf8");
      const mutated = source
        .replace(
          'import PacketEMachine.* from "./machine"',
          'import PacketEMachine.* from "./machine"\n'
            + '  import PacketEMutants.* from "./mutants"',
        )
        .replace(
          "action step = referenceStep",
          `action step = any { referenceStep, ${action} }`,
        );
      expect(mutated).not.toBe(source);
      await writeFile(invariantPath, mutated);
      await executeQuint("typecheck", [invariantPath], root);

      const output = join(root, "mutant.json");
      let exitCode = 0;
      try {
        await executeQuint(
          "verify",
          [
            invariantPath,
            ...quintMainArguments,
            `--invariant=${invariant}`,
            "--max-steps=8",
            "--backend=apalache",
            "--verbosity=1",
            `--out=${output}`,
          ],
          root,
        );
      } catch (error) {
        exitCode = (error as { code?: number }).code ?? -1;
      }

      const result = JSON.parse(await readFile(output, "utf8")) as {
        status?: string;
        trace?: readonly unknown[];
      };
      expect(exitCode).toBe(1);
      expect(result.status).toBe("violation");
      expect(result.trace?.length).toBeGreaterThan(0);
    } finally {
      await rm(root, { recursive: true, force: true });
    }
  },
  180_000,
);
