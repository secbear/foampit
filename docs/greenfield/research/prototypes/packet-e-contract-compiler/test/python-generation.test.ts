import { execFile } from "node:child_process";
import {
  mkdir,
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

import {
  generatedName,
  validateGeneratedFiles,
  type GeneratedFile,
} from "../src/generate/common.js";
import { generatePython } from "../src/generate/python.js";
import { lowerContract } from "../src/lower.js";

const execute = promisify(execFile);
const { compile } = createTester(new URL("../", import.meta.url).pathname, {
  libraries: ["contract"],
});
const expectedFixtures = {
  "start-sandbox-valid.json": {
    operationId: "operation.start.sandbox",
    branch: "accepted",
    carrierKind: "newDurableOperation",
    schemaStableId: "result.operation.start.sandbox",
  },
  "start-sandbox-invalid.json": {
    operationId: "operation.start.sandbox",
    branch: "rejected",
    requestErrorId: "request.sequence.out.of.range",
  },
  "cancel-operation-valid.json": {
    operationId: "operation.cancel.operation",
    branch: "accepted",
    carrierKind: "existingOperationObservation",
    schemaStableId: "result.existing.operation.observation",
  },
  "cancel-operation-invalid.json": {
    operationId: "operation.cancel.operation",
    branch: "observed",
    carrierKind: "existingOperationObservation",
    schemaStableId: "result.existing.operation.observation",
  },
  "write-process-input-valid.json": {
    operationId: "operation.write.process.input",
    branch: "accepted",
    carrierKind: "processControlReceipt",
    schemaStableId: "result.process.control.receipt",
  },
  "write-process-input-invalid.json": {
    operationId: "operation.write.process.input",
    branch: "accepted",
    carrierKind: "newDurableOperation",
    schemaStableId: "result.process.control.receipt",
  },
  "wait-operation-valid.json": {
    operationId: "operation.wait.operation",
    branch: "observed",
    carrierKind: "observation",
    schemaStableId: "result.operation.wait.observation",
  },
  "wait-operation-invalid.json": {
    operationId: "operation.wait.operation",
    branch: "accepted",
    carrierKind: "observation",
    schemaStableId: "result.operation.wait.observation",
  },
} as const;

async function contractModel() {
  const source = await readFile(
    new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url),
    "utf8",
  );
  return lowerContract((await compile(source)).program);
}

function text(file: GeneratedFile): string {
  return new TextDecoder().decode(file.bytes);
}

async function materialize(root: string, files: readonly GeneratedFile[]) {
  for (const file of validateGeneratedFiles(files)) {
    const destination = join(root, ...file.relativePath.split("/"));
    await mkdir(join(destination, ".."), { recursive: true });
    await writeFile(destination, file.bytes);
  }
}

it("emits closed Python sums and exact runtime-enforced per-method boundaries", async () => {
  const model = await contractModel();
  const files = generatePython(model);
  const source = text(
    files.find((file) => file.relativePath === "python/contract.py")!,
  );

  expect(model.closedSums).toHaveLength(14);
  expect(
    model.closedSums.reduce((count, sum) => count + sum.variants.length, 0),
  ).toBe(34);
  for (const sum of model.closedSums) {
    expect(source).toContain(`class ${generatedName(sum.id)}(Enum):`);
    for (const variant of sum.variants) {
      expect(source).toContain(
        `(${JSON.stringify(variant.id)}, ${JSON.stringify(variant.wireTag)})`,
      );
    }
  }

  expect(source).toMatch(
    /class StartSandboxRequestError\(Enum\):[^]*REQUEST_INVALID_STATE[^]*class StartSandboxRecoveryError/,
  );
  expect(source).not.toMatch(
    /class StartSandboxRequestError\(Enum\):[^]*REQUEST_SEQUENCE_OUT_OF_RANGE[^]*class StartSandboxRecoveryError/,
  );
  expect(source).toContain("WaitOperationRecoveryError: TypeAlias = Never");
  expect(source).toContain("WaitOperationKnownFailure: TypeAlias = Never");
  expect(source).toContain("WaitOperationAmbiguity: TypeAlias = Never");
  expect(source).toContain("@dataclass(frozen=True, slots=True)");
  expect(source).toContain(
    "@dataclass(frozen=True, slots=True, init=False)",
  );
  expect(source).toContain("class StartSandboxCarrier:");
  expect(source).toContain("def _create(cls) -> StartSandboxCarrier:");
  expect(source).toContain("carrier: StartSandboxCarrier");
  expect(source).not.toContain(
    "class StartSandboxCarrier:\n    carrier_kind: str",
  );
  expect(source).toContain("class StartSandboxAccepted:");
  expect(source).toContain("class StartSandboxRejected:");
  expect(source).toContain("class WaitOperationObserved:");
  expect(source).not.toContain("class WaitOperationAccepted:");
  expect(source).not.toContain("class WaitOperationRecovery:");
  expect(source).toContain("def __post_init__(self) -> None:");
  expect(source).toContain(
    "StartSandboxOutcome: TypeAlias = StartSandboxAccepted | StartSandboxRecovery | StartSandboxRejected",
  );
  expect(source).toContain(
    "WaitOperationOutcome: TypeAlias = WaitOperationObserved | WaitOperationRejected",
  );
  expect(source).toContain("class PacketEService(Protocol):");
  expect(source).toContain(
    "def start_sandbox(self) -> StartSandboxOutcome:",
  );
  expect(source).toContain(
    "def decode_start_sandbox_outcome(value: object) -> StartSandboxOutcome:",
  );
  expect(source).toContain(
    'INVALID_OUTCOME: Final = "contract/invalid-outcome"',
  );
  expect(source).toContain("if type(value) is not dict:");

  const testSource = text(
    files.find((file) => file.relativePath === "python/test_contract.py")!,
  );
  expect(testSource).toContain("PACKET_E_OUTCOME_FIXTURES");
  for (const name of Object.keys(expectedFixtures)) {
    expect(testSource).toContain(JSON.stringify(name));
  }
  expect(testSource).toContain("self.assertRaises(ContractDiagnostic)");
  expect(testSource).toContain("carrier=object()");
});

it("runs pinned unittest decoders over the exact shared eight fixture bytes", async () => {
  const output = await mkdtemp(join(tmpdir(), "packet-e-python-generation-"));
  try {
    const files = generatePython(await contractModel());
    await materialize(output, files);
    const pythonDirectory = join(output, "python");
    const fixtureDirectory = join(output, "outcomes");
    await mkdir(fixtureDirectory, { recursive: true });

    const seen = new Set<string>();
    for (const [name, expected] of Object.entries(expectedFixtures)) {
      const sourcePath = new URL(`./fixtures/outcomes/${name}`, import.meta.url);
      const bytes = await readFile(sourcePath);
      const raw = bytes.toString("utf8");
      expect(JSON.parse(raw)).toEqual(expected);
      expect(raw).toBe(`${JSON.stringify(expected)}\n`);
      expect(seen.has(raw)).toBe(false);
      seen.add(raw);
      await writeFile(join(fixtureDirectory, name), bytes);
    }
    expect(seen.size).toBe(8);

    const { stdout, stderr } = await execute(
      "python3",
      ["-m", "unittest", "discover", "-s", pythonDirectory, "-v"],
      {
        cwd: pythonDirectory,
        env: {
          ...process.env,
          PACKET_E_OUTCOME_FIXTURES: fixtureDirectory,
        },
      },
    );
    expect(`${stdout}\n${stderr}`).toContain("OK");

    for (const [name, expected] of Object.entries(expectedFixtures)) {
      const { stdout: runnerOutput } = await execute(
        "python3",
        [join(pythonDirectory, "run.py"), join(fixtureDirectory, name)],
        { cwd: pythonDirectory },
      );
      expect(runnerOutput.trim()).toBe(
        name.includes("-valid.")
          ? `${expected.operationId}:${expected.branch}`
          : "contract/invalid-outcome",
      );
    }
  } finally {
    await rm(output, { recursive: true, force: true });
  }
});
