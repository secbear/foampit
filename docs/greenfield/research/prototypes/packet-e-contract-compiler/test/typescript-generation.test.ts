import { execFile } from "node:child_process";
import {
  mkdir,
  mkdtemp,
  readFile,
  rm,
  writeFile,
} from "node:fs/promises";
import { basename, join } from "node:path";
import { tmpdir } from "node:os";
import { promisify } from "node:util";

import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

import {
  generatedName,
  validateGeneratedFiles,
  type GeneratedFile,
} from "../src/generate/common.js";
import { generateGo } from "../src/generate/go.js";
import { generatePython } from "../src/generate/python.js";
import { generateRust } from "../src/generate/rust.js";
import { generateTypeScript } from "../src/generate/typescript.js";
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

it("emits all closed sums and exact readonly per-method TypeScript unions", async () => {
  const model = await contractModel();
  const files = generateTypeScript(model);
  const source = text(
    files.find((file) => file.relativePath === "typescript/contract.ts")!,
  );

  expect(model.closedSums).toHaveLength(14);
  expect(
    model.closedSums.reduce((count, sum) => count + sum.variants.length, 0),
  ).toBe(34);
  for (const sum of model.closedSums) {
    expect(source).toContain(`export type ${generatedName(sum.id)} =`);
    for (const variant of sum.variants) {
      expect(source).toContain(
        `Readonly<{ readonly kind: "${variant.id}"; readonly wireTag: "${variant.wireTag}" }>`,
      );
    }
  }

  expect(source).toContain("export type StartSandboxRequestError =");
  expect(source).toMatch(
    /type StartSandboxRequestError =[^;]*request\.invalid\.state[^;]*;/,
  );
  expect(source).not.toMatch(
    /type StartSandboxRequestError =[^;]*request\.sequence\.out\.of\.range[^;]*;/,
  );
  expect(source).toContain("export type StartSandboxKnownFailure =");
  expect(source).toContain("export type StartSandboxAmbiguity =");
  expect(source).toContain("export type WaitOperationOutcome =");
  expect(source).not.toMatch(
    /type WaitOperationOutcome =[^;]*branch: "accepted"[^;]*;/,
  );
  expect(source).not.toMatch(
    /type WaitOperationOutcome =[^;]*branch: "recovery"[^;]*;/,
  );
  expect(source).toContain("readonly branch:");
  expect(source).toContain("export interface PacketEService");
  expect(source).toContain("startSandbox(): Promise<StartSandboxOutcome>");
  expect(source).toContain(
    "decodeStartSandboxOutcome(value: unknown): StartSandboxOutcome",
  );
  expect(source).toContain(
    'export const INVALID_OUTCOME = "contract/invalid-outcome" as const;',
  );

  const staticTest = text(
    files.find(
      (file) => file.relativePath === "typescript/static-construction.test.ts",
    )!,
  );
  expect(staticTest.match(/@ts-expect-error/g)).toHaveLength(4);
});

it("typechecks construction exclusions and executes strict decoders over exact fixtures", async () => {
  const output = await mkdtemp(join(tmpdir(), "packet-e-typescript-generation-"));
  try {
    const files = generateTypeScript(await contractModel());
    await materialize(output, files);
    const typescriptDirectory = join(output, "typescript");
    await execute(
      "pnpm",
      [
        "exec",
        "tsc",
        "--project",
        join(typescriptDirectory, "tsconfig.json"),
      ],
      {
        cwd: new URL("../", import.meta.url).pathname,
      },
    );

    const seen = new Set<string>();
    for (const [name, expected] of Object.entries(expectedFixtures)) {
      const sourcePath = new URL(`./fixtures/outcomes/${name}`, import.meta.url);
      const bytes = await readFile(sourcePath);
      const raw = bytes.toString("utf8");
      expect(JSON.parse(raw)).toEqual(expected);
      expect(raw).toBe(`${JSON.stringify(expected)}\n`);
      expect(seen.has(raw)).toBe(false);
      seen.add(raw);

      const { stdout } = await execute(
        "node",
        [join(typescriptDirectory, "run.mjs"), sourcePath.pathname],
        { cwd: output },
      );
      expect(stdout.trim()).toBe(
        name.includes("-valid.")
          ? `${expected.operationId}:${expected.branch}`
          : "contract/invalid-outcome",
      );
    }
    expect(seen.size).toBe(8);

    const strictProbes = {
      "extra-key.json": {
        ...expectedFixtures["start-sandbox-valid.json"],
        extra: "forbidden",
      },
      "unknown-operation.json": {
        ...expectedFixtures["start-sandbox-valid.json"],
        operationId: "operation.unknown",
      },
      "wrong-error.json": {
        operationId: "operation.cancel.operation",
        branch: "rejected",
        requestErrorId: "request.sequence.out.of.range",
      },
      "wrong-recovery-error.json": {
        operationId: "operation.start.sandbox",
        branch: "recovery",
        recoveryErrorId: "request.invalid.state",
      },
      "wrong-schema.json": {
        ...expectedFixtures["start-sandbox-valid.json"],
        schemaStableId: "result.process.control.receipt",
      },
    };
    for (const [name, value] of Object.entries(strictProbes)) {
      const path = join(output, name);
      await writeFile(path, `${JSON.stringify(value)}\n`);
      const { stdout } = await execute(
        "node",
        [join(typescriptDirectory, "run.mjs"), path],
        { cwd: output },
      );
      expect(stdout.trim()).toBe("contract/invalid-outcome");
      expect(basename(path)).toBe(name);
    }
  } finally {
    await rm(output, { recursive: true, force: true });
  }
});

it("rejects identical duplicate-key bytes in every executable language boundary", async () => {
  const output = await mkdtemp(join(tmpdir(), "packet-e-typescript-duplicate-"));
  try {
    const model = await contractModel();
    await materialize(output, [
      ...generateRust(model),
      ...generateGo(model),
      ...generateTypeScript(model),
      ...generatePython(model),
    ]);
    const typescriptDirectory = join(output, "typescript");
    await execute(
      "pnpm",
      [
        "exec",
        "tsc",
        "--project",
        join(typescriptDirectory, "tsconfig.json"),
      ],
      {
        cwd: new URL("../", import.meta.url).pathname,
      },
    );
    const rustDirectory = join(output, "rust");
    const rustBinary = join(output, "rust-validator");
    await execute(
      "rustc",
      ["--edition", "2024", "validate.rs", "-o", rustBinary],
      { cwd: rustDirectory },
    );
    const goDirectory = join(output, "go");
    const goCommandDirectory = join(goDirectory, "cmd/duplicate");
    await mkdir(goCommandDirectory, { recursive: true });
    await writeFile(
      join(goCommandDirectory, "main.go"),
      `package main

import (
\t"fmt"
\t"os"

\tcontract "packet_e_contract"
)

func main() {
\tdata, err := os.ReadFile(os.Args[1])
\tif err != nil {
\t\tpanic(err)
\t}
\tif _, err := contract.DecodeOutcome(data); err != nil {
\t\tfmt.Println(err)
\t\treturn
\t}
\tfmt.Println("accepted")
}
`,
    );

    const path = join(output, "duplicate-branch.json");
    const bytes = Buffer.from(
      '{"operationId":"operation.start.sandbox","branch":"rejected","branch":"accepted","carrierKind":"newDurableOperation","schemaStableId":"result.operation.start.sandbox"}\n',
      "utf8",
    );
    await writeFile(path, bytes);
    expect(await readFile(path)).toEqual(bytes);

    const [typescript, rust, go, python] = await Promise.all([
      execute(
        "node",
        [join(typescriptDirectory, "run.mjs"), path],
        { cwd: output },
      ),
      execute(rustBinary, [path], { cwd: output }),
      execute("go", ["run", "./cmd/duplicate", path], {
        cwd: goDirectory,
      }),
      execute(
        "python3",
        [join(output, "python/run.py"), path],
        { cwd: output },
      ),
    ]);
    expect({
      go: go.stdout.trim(),
      python: python.stdout.trim(),
      rust: rust.stdout.trim(),
      typescript: typescript.stdout.trim(),
    }).toEqual({
      go: "contract/invalid-outcome",
      python: "contract/invalid-outcome",
      rust: "contract/invalid-outcome",
      typescript: "contract/invalid-outcome",
    });
  } finally {
    await rm(output, { recursive: true, force: true });
  }
});

it("accepts ordinary JSON escapes but rejects non-flat or trailing raw input", async () => {
  const output = await mkdtemp(join(tmpdir(), "packet-e-typescript-json-"));
  try {
    const files = generateTypeScript(await contractModel());
    await materialize(output, files);
    const typescriptDirectory = join(output, "typescript");
    await execute(
      "pnpm",
      [
        "exec",
        "tsc",
        "--project",
        join(typescriptDirectory, "tsconfig.json"),
      ],
      {
        cwd: new URL("../", import.meta.url).pathname,
      },
    );

    const escapedPath = join(output, "escaped-valid.json");
    await writeFile(
      escapedPath,
      '{"oper\\u0061tionId":"operation.st\\u0061rt.sandbox","br\\u0061nch":"acc\\u0065pted","carrierK\\u0069nd":"newDurableOper\\u0061tion","schemaStableId":"result.operation.start.sandbox"}\n',
    );
    const escaped = await execute(
      "node",
      [join(typescriptDirectory, "run.mjs"), escapedPath],
      { cwd: output },
    );
    expect(escaped.stdout.trim()).toBe(
      "operation.start.sandbox:accepted",
    );

    const invalidRaw = {
      "trailing-input.json":
        '{"operationId":"operation.start.sandbox","branch":"accepted","carrierKind":"newDurableOperation","schemaStableId":"result.operation.start.sandbox"} true\n',
      "non-object.json": '["operation.start.sandbox","accepted"]\n',
      "non-string.json":
        '{"operationId":"operation.start.sandbox","branch":"accepted","carrierKind":"newDurableOperation","schemaStableId":42}\n',
    } as const;
    for (const [name, raw] of Object.entries(invalidRaw)) {
      const path = join(output, name);
      await writeFile(path, raw);
      const { stdout } = await execute(
        "node",
        [join(typescriptDirectory, "run.mjs"), path],
        { cwd: output },
      );
      expect(stdout.trim()).toBe("contract/invalid-outcome");
    }
  } finally {
    await rm(output, { recursive: true, force: true });
  }
});
