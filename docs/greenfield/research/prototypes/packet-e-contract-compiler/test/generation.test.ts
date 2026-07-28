import { execFile } from "node:child_process";
import {
  access,
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
  generatedFile,
  generatedName,
  lowerCamel,
  operationNames,
  validateGeneratedFiles,
  type GeneratedFile,
} from "../src/generate/common.js";
import { generateGo } from "../src/generate/go.js";
import { generateOpenApi } from "../src/generate/openapi.js";
import { generateProtobuf } from "../src/generate/protobuf.js";
import { generatePython } from "../src/generate/python.js";
import { generateRust } from "../src/generate/rust.js";
import { generateTypeScript } from "../src/generate/typescript.js";
import { lowerContract } from "../src/lower.js";

const { compile } = createTester(new URL("../", import.meta.url).pathname, {
  libraries: ["contract"],
});
const execute = promisify(execFile);
const fixtureNames = [
  "start-sandbox-valid.json",
  "start-sandbox-invalid.json",
  "cancel-operation-valid.json",
  "cancel-operation-invalid.json",
  "write-process-input-valid.json",
  "write-process-input-invalid.json",
  "wait-operation-valid.json",
  "wait-operation-invalid.json",
] as const;
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
} as const satisfies Record<(typeof fixtureNames)[number], object>;

async function contractModel() {
  const source = await readFile(
    new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url),
    "utf8",
  );
  return lowerContract((await compile(source)).program);
}

async function fixtureBytes(name: (typeof fixtureNames)[number]) {
  return readFile(new URL(`./fixtures/outcomes/${name}`, import.meta.url));
}

function decode(file: GeneratedFile): string {
  return new TextDecoder().decode(file.bytes);
}

async function materialize(root: string, files: readonly GeneratedFile[]) {
  for (const file of validateGeneratedFiles(files)) {
    const destination = join(root, ...file.relativePath.split("/"));
    await mkdir(join(destination, ".."), { recursive: true });
    await writeFile(destination, file.bytes);
  }
  const fixtureDirectory = join(root, "outcomes");
  await mkdir(fixtureDirectory, { recursive: true });
  for (const name of fixtureNames) {
    await writeFile(join(fixtureDirectory, name), await fixtureBytes(name));
  }
  return fixtureDirectory;
}

it("rejects every unsafe, noncanonical, and duplicate generated path", () => {
  for (const relativePath of [
    "",
    ".",
    "..",
    "/absolute",
    "C:/drive",
    "C:\\drive",
    "\\\\server\\share",
    "rust\\lib.rs",
    "rust/\0lib.rs",
    "rust//lib.rs",
    "rust/./lib.rs",
    "rust/../lib.rs",
  ]) {
    expect(() =>
      validateGeneratedFiles([generatedFile(relativePath, "")]),
    ).toThrow("contract/generated-file-path-invalid");
  }

  expect(() =>
    validateGeneratedFiles([
      generatedFile("rust/lib.rs", "first"),
      generatedFile("rust/lib.rs", "second"),
    ]),
  ).toThrow("contract/generated-file-path-duplicate");
  expect(() =>
    validateGeneratedFiles([
      generatedFile("Rust/lib.rs", "first"),
      generatedFile("rust/lib.rs", "second"),
    ]),
  ).toThrow("contract/generated-file-path-duplicate");
  expect(() =>
    validateGeneratedFiles([
      generatedFile("rust/\u00e9.rs", "first"),
      generatedFile("rust/e\u0301.rs", "second"),
    ]),
  ).toThrow("contract/generated-file-path-invalid");
});

it("derives centralized stable names deterministically and rejects collisions", () => {
  expect(generatedName("operation.start.sandbox")).toBe(
    "OperationStartSandbox",
  );
  const fakeModel = {
    operations: [
      { operationId: "operation.write.process.input" },
      { operationId: "operation.start.sandbox" },
    ],
  } as never;
  expect(operationNames(fakeModel)).toEqual([
    "StartSandbox",
    "WriteProcessInput",
  ]);
  expect(() =>
    operationNames({
      operations: [
        { operationId: "operation.start.sandbox" },
        { operationId: "operation.start.sandbox" },
      ],
    } as never),
  ).toThrow("contract/generated-name-collision");
  expect(() => generatedName("Operation.Start")).toThrow(
    "contract/generated-name-invalid",
  );
});

it("emits closed Rust and Go method boundaries with exact exclusions", async () => {
  const model = await contractModel();
  const rust = decode(
    generateRust(model).find((file) => file.relativePath === "rust/lib.rs")!,
  );
  const go = decode(
    generateGo(model).find((file) => file.relativePath === "go/contract.go")!,
  );

  expect(rust).toContain("pub enum StartSandboxOutcome");
  expect(rust).toContain("pub enum StartSandboxRequestError");
  expect(rust).toContain("RequestInvalidState");
  expect(rust).not.toMatch(
    /enum StartSandboxRequestError\s*\{[^}]*RequestSequenceOutOfRange/,
  );
  expect(rust).toContain("pub enum WaitOperationOutcome");
  expect(rust).not.toMatch(
    /enum WaitOperationOutcome\s*\{[^}]*\bAccepted\b/,
  );
  expect(rust).toContain("fn new() -> Self");
  expect(rust).not.toContain("pub fn new() -> Self");
  expect(rust).toContain("pub trait PacketEService");

  expect(go).toContain("type StartSandboxOutcome interface");
  expect(go).toContain("isStartSandboxOutcome()");
  expect(go).not.toMatch(
    /type StartSandboxOutcome interface\s*\{[^}]*\bBranch\(\)/,
  );
  expect(go).not.toMatch(
    /type StartSandboxOutcome interface\s*\{[^}]*\bOperationID\(\)/,
  );
  expect(go).toContain("type startSandboxAccepted struct");
  expect(go).not.toContain("type StartSandboxAccepted struct");
  expect(go).toContain("type StartSandboxAccepted interface");
  expect(go).not.toMatch(
    /type StartSandboxAccepted interface\s*\{[^}]*CarrierKind/,
  );
  expect(go).toContain("CarrierKind() (string, bool)");
  expect(go).toContain("SchemaStableID() (string, bool)");
  expect(go).toContain("type StartSandboxRejected interface");
  expect(go).not.toMatch(
    /type StartSandboxRejected interface\s*\{[^}]*RequestError/,
  );
  expect(go).toContain(
    "RequestError() (StartSandboxRequestError, bool)",
  );
  expect(go).toContain("type StartSandboxRecovery interface");
  expect(go).not.toMatch(
    /type StartSandboxRecovery interface\s*\{[^}]*RecoveryError/,
  );
  expect(go).toContain(
    "RecoveryError() (StartSandboxRecoveryError, bool)",
  );
  expect(go).toContain("func InspectStartSandboxOutcome");
  expect(go).toContain("func ValidateStartSandboxOutcome");
  expect(go).toContain("func InspectOutcome");
  expect(go).toContain("func ValidateOutcome");
  expect(go).not.toMatch(/type AnyOutcome interface\s*\{[^}]*\bBranch\(\)/);
  expect(go).not.toMatch(
    /type AnyOutcome interface\s*\{[^}]*\bOperationID\(\)/,
  );
  expect(go).toContain("package-marked, not statically sealed");
  expect(go).toContain("type StartSandboxRequestError interface");
  expect(go).not.toMatch(
    /type StartSandboxRequestError interface\s*\{[^}]*RequestSequenceOutOfRange/,
  );
  expect(go).toContain("type WaitOperationOutcome interface");
  expect(go).not.toContain("type waitOperationAccepted struct");
  expect(go).toContain("func DecodeStartSandboxOutcome");
  expect(go).toContain("type PacketEService interface");
});

it("emits all fourteen Go closed sums with exact private wire variants", async () => {
  const model = await contractModel();
  const go = decode(
    generateGo(model).find((file) => file.relativePath === "go/contract.go")!,
  );
  expect(model.closedSums).toHaveLength(14);
  expect(
    model.closedSums.reduce((count, sum) => count + sum.variants.length, 0),
  ).toBe(34);

  for (const sum of model.closedSums) {
    const sumName = generatedName(sum.id);
    expect(go).toContain(`type ${sumName} interface {`);
    expect(go).toContain(`is${sumName}()`);
    for (const variant of sum.variants) {
      const implementation = `${lowerCamel(sumName)}${generatedName(variant.id)}`;
      expect(go).toContain(`type ${implementation} struct{}`);
      expect(go).toContain(`func (${implementation}) is${sumName}() {}`);
      expect(go).toContain(
        `func (${implementation}) StableID() string { return "${variant.id}" }`,
      );
      expect(go).toContain(
        `func (${implementation}) WireTag() string { return "${variant.wireTag}" }`,
      );
    }
  }
});

it("derives every target's wire tag from closed sums", async () => {
  const model = await contractModel();
  const changed = {
    ...model,
    closedSums: model.closedSums.map((sum) =>
      sum.id === "state.sandbox"
        ? {
            ...sum,
            variants: sum.variants.map((variant) =>
              variant.id === "state.sandbox.stopped"
                ? { ...variant, wireTag: "9" }
                : variant,
            ),
          }
        : sum,
    ),
  };
  const go = decode(
    generateGo(changed).find((file) => file.relativePath === "go/contract.go")!,
  );
  const rust = decode(
    generateRust(changed).find((file) => file.relativePath === "rust/lib.rs")!,
  );
  const typescript = decode(
    generateTypeScript(changed).find(
      (file) => file.relativePath === "typescript/contract.ts",
    )!,
  );
  const python = decode(
    generatePython(changed).find(
      (file) => file.relativePath === "python/contract.py",
    )!,
  );
  const protobuf = decode(
    generateProtobuf(changed).find(
      (file) => file.relativePath === "protobuf/contract.proto",
    )!,
  );
  const openapi = JSON.parse(
    decode(
      generateOpenApi(changed).find(
        (file) => file.relativePath === "openapi/contract.json",
      )!,
    ),
  ) as {
    components: {
      schemas: Record<string, Readonly<Record<string, unknown>>>;
    };
  };
  expect(go).toContain(
    '{ContainerID: "state.sandbox", VariantID: "state.sandbox.stopped", WireTag: "9"}',
  );
  expect(rust).toContain('("state.sandbox", "state.sandbox.stopped", 9)');
  expect(typescript).toContain(
    'readonly kind: "state.sandbox.stopped"; readonly wireTag: "9"',
  );
  expect(python).toContain(
    'STATE_SANDBOX_STOPPED = ("state.sandbox.stopped", "9")',
  );
  expect(protobuf).toContain(
    'StateSandboxStopped state_sandbox_stopped = 9 [(variant_stable_id) = "state.sandbox.stopped", (variant_wire_tag) = "9"]',
  );
  expect(
    openapi.components.schemas.StateSandboxStateSandboxStopped,
  ).toMatchObject({
    "x-stable-id": "state.sandbox.stopped",
    "x-wire-tag": "9",
  });
});

it("binds every committed fixture filename to exact unique semantic bytes", async () => {
  const seen = new Set<string>();
  for (const name of fixtureNames) {
    const bytes = await fixtureBytes(name);
    const text = bytes.toString("utf8");
    expect(JSON.parse(text)).toEqual(expectedFixtures[name]);
    expect(text).toBe(`${JSON.stringify(expectedFixtures[name])}\n`);
    expect(seen.has(text)).toBe(false);
    seen.add(text);
  }
  expect(seen.size).toBe(8);
});

it("compiles and executes Rust and Go validators over the exact shared bytes", async () => {
  const output = await mkdtemp(join(tmpdir(), "packet-e-rust-go-generation-"));
  try {
    const model = await contractModel();
    const fixtureDirectory = await materialize(output, [
      ...generateRust(model),
      ...generateGo(model),
    ]);
    const rustDirectory = join(output, "rust");
    const rustBinary = join(output, "rust-validator");

    await execute(
      "rustc",
      ["--edition", "2024", "lib.rs", "--crate-type", "lib", "-o", join(output, "libpacket_e.rlib")],
      { cwd: rustDirectory },
    );
    await execute(
      "rustc",
      ["--edition", "2024", "validate.rs", "-o", rustBinary],
      { cwd: rustDirectory },
    );
    for (const name of fixtureNames) {
      const { stdout } = await execute(rustBinary, [join(fixtureDirectory, name)], {
        cwd: output,
      });
      expect(stdout.trim()).toBe(
        name.includes("-valid.")
          ? "ok"
          : "contract/invalid-outcome",
      );
    }

    await execute("go", ["test", "./..."], {
      cwd: join(output, "go"),
      env: {
        ...process.env,
        PACKET_E_OUTCOME_FIXTURES: fixtureDirectory,
      },
    });
    const externalDirectory = join(output, "go", "external");
    await mkdir(externalDirectory, { recursive: true });
    await writeFile(
      join(externalDirectory, "consumer_test.go"),
      `package external

import (
\t"errors"
\tcontract "packet_e_contract"
\t"testing"
)

func requireInvalid(t *testing.T, err error) {
\tt.Helper()
\tvar diagnostic *contract.ContractDiagnostic
\tif !errors.As(err, &diagnostic) || diagnostic.Category != contract.InvalidOutcome {
\t\tt.Fatalf("error = %v, want %s", err, contract.InvalidOutcome)
\t}
}

type forgedRejected struct {
\tcontract.WriteProcessInputRejected
}

func (forgedRejected) Branch() string { panic("forged Branch must not be inspected") }
func (forgedRejected) OperationID() string { panic("forged OperationID must not be inspected") }
func (forgedRejected) RequestError() contract.WriteProcessInputRequestError {
\tpanic("forged RequestError must not be inspected")
}

func TestValidatedOutcomeInspection(t *testing.T) {
\trequestErrors := []string{
\t\t"request.invalid.state",
\t\t"request.sequence.out.of.range",
\t}
\tfor _, stableID := range requestErrors {
\t\toutcome, err := contract.DecodeWriteProcessInputOutcome([]byte(
\t\t\t\`{"operationId":"operation.write.process.input","branch":"rejected","requestErrorId":"\` + stableID + \`"}\`,
\t\t))
\t\tif err != nil {
\t\t\tt.Fatal(err)
\t\t}
\t\tview, err := contract.InspectWriteProcessInputOutcome(outcome)
\t\tif err != nil {
\t\t\tt.Fatal(err)
\t\t}
\t\treason, ok := view.RequestError()
\t\tif !ok {
\t\t\tt.Fatalf("rejected view = %#v", view)
\t\t}
\t\tif got := reason.StableID(); got != stableID {
\t\t\tt.Fatalf("request error = %q, want %q", got, stableID)
\t\t}
\t}

\taccepted, err := contract.DecodeWriteProcessInputOutcome([]byte(
\t\t\`{"operationId":"operation.write.process.input","branch":"accepted","carrierKind":"processControlReceipt","schemaStableId":"result.process.control.receipt"}\`,
\t))
\tif err != nil {
\t\tt.Fatal(err)
\t}
\tacceptedView, err := contract.InspectWriteProcessInputOutcome(accepted)
\tif err != nil {
\t\tt.Fatal(err)
\t}
\tcarrierKind, ok := acceptedView.CarrierKind()
\tif !ok {
\t\tt.Fatalf("accepted view = %#v", acceptedView)
\t}
\tif got := carrierKind; got != "processControlReceipt" {
\t\tt.Fatalf("carrier kind = %q", got)
\t}
\tschemaStableID, ok := acceptedView.SchemaStableID()
\tif !ok {
\t\tt.Fatalf("accepted view = %#v", acceptedView)
\t}
\tif got := schemaStableID; got != "result.process.control.receipt" {
\t\tt.Fatalf("schema stable ID = %q", got)
\t}

\tobserved, err := contract.DecodeWaitOperationOutcome([]byte(
\t\t\`{"operationId":"operation.wait.operation","branch":"observed","carrierKind":"observation","schemaStableId":"result.operation.wait.observation"}\`,
\t))
\tif err != nil {
\t\tt.Fatal(err)
\t}
\tobservedView, err := contract.InspectWaitOperationOutcome(observed)
\tif err != nil {
\t\tt.Fatal(err)
\t}
\tobservedCarrierKind, ok := observedView.CarrierKind()
\tif !ok {
\t\tt.Fatalf("observed view = %#v", observedView)
\t}
\tif got := observedCarrierKind; got != "observation" {
\t\tt.Fatalf("observed carrier kind = %q", got)
\t}
\tobservedSchemaStableID, ok := observedView.SchemaStableID()
\tif !ok {
\t\tt.Fatalf("observed view = %#v", observedView)
\t}
\tif got := observedSchemaStableID; got != "result.operation.wait.observation" {
\t\tt.Fatalf("observed schema stable ID = %q", got)
\t}

\trecovery, err := contract.DecodeWriteProcessInputOutcome([]byte(
\t\t\`{"operationId":"operation.write.process.input","branch":"recovery","recoveryErrorId":"recovery.idempotency.expired"}\`,
\t))
\tif err != nil {
\t\tt.Fatal(err)
\t}
\trecoveryView, err := contract.InspectWriteProcessInputOutcome(recovery)
\tif err != nil {
\t\tt.Fatal(err)
\t}
\trecoveryReason, ok := recoveryView.RecoveryError()
\tif !ok {
\t\tt.Fatalf("recovery view = %#v", recoveryView)
\t}
\tif got := recoveryReason.StableID(); got != "recovery.idempotency.expired" {
\t\tt.Fatalf("recovery error = %q", got)
\t}

\tanyOutcome, err := contract.DecodeOutcome([]byte(
\t\t\`{"operationId":"operation.write.process.input","branch":"rejected","requestErrorId":"request.invalid.state"}\`,
\t))
\tif err != nil {
\t\tt.Fatal(err)
\t}
\tanyView, err := contract.InspectOutcome(anyOutcome)
\tif err != nil {
\t\tt.Fatal(err)
\t}
\tif _, ok := anyView.(contract.WriteProcessInputOutcomeView); !ok {
\t\tt.Fatalf("any view type = %T", anyView)
\t}
}

func TestEmbeddedInterfaceForgeryCompilesButFailsValidation(t *testing.T) {
\toutcome, err := contract.DecodeWriteProcessInputOutcome([]byte(
\t\t\`{"operationId":"operation.write.process.input","branch":"rejected","requestErrorId":"request.invalid.state"}\`,
\t))
\tif err != nil {
\t\tt.Fatal(err)
\t}
\tbranch, ok := outcome.(contract.WriteProcessInputRejected)
\tif !ok {
\t\tt.Fatalf("decoded type = %T", outcome)
\t}
\tforged := forgedRejected{WriteProcessInputRejected: branch}

\tvar methodOutcome contract.WriteProcessInputOutcome = forged
\tvar anyOutcome contract.AnyOutcome = forged

\t_, err = contract.InspectWriteProcessInputOutcome(methodOutcome)
\trequireInvalid(t, err)
\trequireInvalid(t, contract.ValidateWriteProcessInputOutcome(methodOutcome))
\t_, err = contract.InspectOutcome(anyOutcome)
\trequireInvalid(t, err)
\trequireInvalid(t, contract.ValidateOutcome(anyOutcome))
}
`,
    );
    await execute("go", ["test", "./external"], {
      cwd: join(output, "go"),
    });
    await rm(externalDirectory, { recursive: true, force: true });

    await access(join(output, "libpacket_e.rlib"));
    await expect(access(join(process.cwd(), "libpacket_e.rlib"))).rejects.toThrow();
  } finally {
    await rm(output, { recursive: true, force: true });
  }
});
