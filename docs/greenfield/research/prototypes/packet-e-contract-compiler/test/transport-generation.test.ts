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

import { semanticDigest } from "../src/canonical.js";
import {
  generatedName,
  snakeCase,
  validateGeneratedFiles,
  type GeneratedFile,
} from "../src/generate/common.js";
import { generateOpenApi } from "../src/generate/openapi.js";
import { generateProtobuf } from "../src/generate/protobuf.js";
import { lowerContract } from "../src/lower.js";

const execute = promisify(execFile);
const packageRoot = new URL("../", import.meta.url).pathname;
const { compile } = createTester(packageRoot, { libraries: ["contract"] });

async function contractModel(fixture = "packet-e-slice") {
  const source = await readFile(
    new URL(`../fixtures/valid/${fixture}/main.tsp`, import.meta.url),
    "utf8",
  );
  return lowerContract((await compile(source)).program);
}

function text(file: GeneratedFile): string {
  return new TextDecoder().decode(file.bytes);
}

function message(source: string, name: string): string {
  const prefix = `message ${name} {`;
  const start = source.indexOf(prefix);
  if (start < 0) {
    throw new Error(`missing ${prefix}`);
  }
  let depth = 0;
  for (let index = start; index < source.length; index += 1) {
    if (source[index] === "{") {
      depth += 1;
    } else if (source[index] === "}") {
      depth -= 1;
      if (depth === 0) {
        return source.slice(start, index + 1);
      }
    }
  }
  throw new Error(`unterminated ${prefix}`);
}

async function materialize(root: string, files: readonly GeneratedFile[]) {
  for (const file of validateGeneratedFiles(files)) {
    const destination = join(root, ...file.relativePath.split("/"));
    await mkdir(join(destination, ".."), { recursive: true });
    await writeFile(destination, file.bytes);
  }
}

it("emits compilable closed Protobuf projections with exact tags and current exclusions", async () => {
  const model = await contractModel();
  const files = generateProtobuf(model);
  const source = text(
    files.find((file) => file.relativePath === "protobuf/contract.proto")!,
  );

  expect(source).toContain('syntax = "proto3";');
  expect(source).toContain('import "google/protobuf/descriptor.proto";');
  expect(source).toContain("package packet_e.contract.v1;");
  expect(source).not.toMatch(/\benum\s/);
  expect(source).toContain(
    "// Current-contract exclusions only; reservations do not prove historical removal.",
  );
  expect(model.closedSums).toHaveLength(14);
  expect(
    model.closedSums.reduce((count, sum) => count + sum.variants.length, 0),
  ).toBe(34);
  for (const sum of model.closedSums) {
    const block = message(source, generatedName(sum.id));
    expect(block).toContain(`option (stable_id) = "${sum.id}";`);
    expect(block).toContain("oneof variant {");
    for (const variant of sum.variants) {
      expect(block).toContain(
        `${generatedName(variant.id)} ${snakeCase(generatedName(variant.id))} = ${variant.wireTag} [(variant_stable_id) = "${variant.id}", (variant_wire_tag) = "${variant.wireTag}"];`,
      );
    }
  }

  expect(message(source, "StartSandboxRequestError")).toContain(
    'RequestInvalidState request_invalid_state = 1 [(variant_stable_id) = "request.invalid.state", (variant_wire_tag) = "1"];',
  );
  expect(message(source, "StartSandboxRequestError")).toContain("reserved 2;");
  expect(message(source, "StartSandboxRequestError")).toContain(
    'reserved "request_sequence_out_of_range";',
  );

  const waitOutcome = message(source, "WaitOperationOutcome");
  expect(waitOutcome).toContain(
    'WaitOperationRequestError rejected = 2 [(variant_stable_id) = "outcome.rejected", (variant_wire_tag) = "2"];',
  );
  expect(waitOutcome).toContain(
    'WaitOperationCarrier observed = 4 [(variant_stable_id) = "outcome.observed", (variant_wire_tag) = "4"];',
  );
  expect(waitOutcome).toContain("reserved 1, 3;");
  expect(waitOutcome).toContain('reserved "accepted", "recovery";');
  expect(waitOutcome).not.toMatch(/\baccepted\s*=/);
  expect(waitOutcome).not.toMatch(/\brecovery\s*=/);

  const writeOutcome = message(source, "WriteProcessInputOutcome");
  expect(writeOutcome).toContain(
    'WriteProcessInputCarrier accepted = 1 [(variant_stable_id) = "outcome.process.accepted", (variant_wire_tag) = "1"];',
  );
  expect(writeOutcome).toContain(
    'WriteProcessInputRecoveryError recovery = 3 [(variant_stable_id) = "outcome.process.recovery", (variant_wire_tag) = "3"];',
  );
  expect(message(source, "WaitOperationRecoveryError")).toContain(
    'reserved "recovery_idempotency_expired";',
  );

  const output = await mkdtemp(join(tmpdir(), "packet-e-protobuf-"));
  try {
    await materialize(output, files);
    const protobufDirectory = join(output, "protobuf");
    await execute(
      "protoc",
      [
        `--proto_path=${protobufDirectory}`,
        `--descriptor_set_out=${join(output, "contract.pb")}`,
        join(protobufDirectory, "contract.proto"),
      ],
      { cwd: output },
    );
    expect((await readFile(join(output, "contract.pb"))).byteLength).toBeGreaterThan(
      0,
    );
  } finally {
    await rm(output, { recursive: true, force: true });
  }

  const reordered = generateProtobuf(
    await contractModel("packet-e-slice-reordered"),
  );
  expect(files).toEqual(generateProtobuf(model));
  expect(files).toEqual(reordered);
});

it("emits downstream-only closed OpenAPI 3.1 schemas with exact discriminators", async () => {
  const model = await contractModel();
  const beforeDigest = semanticDigest(model);
  const beforeBytes = JSON.stringify(model);
  const files = generateOpenApi(model);
  expect(semanticDigest(model)).toBe(beforeDigest);
  expect(JSON.stringify(model)).toBe(beforeBytes);
  expect(files).toEqual(generateOpenApi(model));
  expect(files).toEqual(
    generateOpenApi(await contractModel("packet-e-slice-reordered")),
  );

  const sourceFile = files.find(
    (file) => file.relativePath === "openapi/contract.json",
  );
  expect(sourceFile).toBeDefined();
  if (sourceFile === undefined) {
    return;
  }
  const source = text(sourceFile);
  expect(source).toBe(`${JSON.stringify(JSON.parse(source), undefined, 2)}\n`);
  const document = JSON.parse(source) as {
    openapi: string;
    paths: object;
    components: { schemas: Record<string, Record<string, unknown>> };
  };
  expect(document.openapi).toBe("3.1.0");
  expect(document.paths).toEqual({});
  const schemas = document.components.schemas;
  for (const sum of model.closedSums) {
    expect(schemas[generatedName(sum.id)]).toMatchObject({
      "x-stable-id": sum.id,
    });
    for (const variant of sum.variants) {
      expect(
        schemas[`${generatedName(sum.id)}${generatedName(variant.id)}`],
      ).toMatchObject({
        type: "object",
        additionalProperties: false,
        required: ["stableId"],
        properties: { stableId: { const: variant.id } },
        "x-stable-id": variant.id,
        "x-wire-tag": variant.wireTag,
      });
    }
  }

  expect(schemas.StartSandboxOutcome).toMatchObject({
    oneOf: [
      { $ref: "#/components/schemas/StartSandboxAccepted" },
      { $ref: "#/components/schemas/StartSandboxRecovery" },
      { $ref: "#/components/schemas/StartSandboxRejected" },
    ],
    discriminator: {
      propertyName: "branch",
      mapping: {
        accepted: "#/components/schemas/StartSandboxAccepted",
        recovery: "#/components/schemas/StartSandboxRecovery",
        rejected: "#/components/schemas/StartSandboxRejected",
      },
    },
  });
  expect(schemas.StartSandboxRequestError).toMatchObject({
    oneOf: [
      {
        $ref: "#/components/schemas/RegistryRequestErrorRequestInvalidState",
      },
    ],
    discriminator: {
      propertyName: "stableId",
      mapping: {
        "request.invalid.state":
          "#/components/schemas/RegistryRequestErrorRequestInvalidState",
      },
    },
  });
  expect(schemas.StartSandboxRequestError).not.toEqual(
    expect.objectContaining({
      "request.sequence.out.of.range":
        "#/components/schemas/RegistryRequestErrorRequestSequenceOutOfRange",
    }),
  );

  expect(schemas.WaitOperationOutcome).toMatchObject({
    oneOf: [
      { $ref: "#/components/schemas/WaitOperationObserved" },
      { $ref: "#/components/schemas/WaitOperationRejected" },
    ],
    discriminator: {
      propertyName: "branch",
      mapping: {
        observed: "#/components/schemas/WaitOperationObserved",
        rejected: "#/components/schemas/WaitOperationRejected",
      },
    },
  });
  expect(schemas.WaitOperationRecoveryError).toEqual({ not: {} });
  expect(schemas.WaitOperationKnownFailure).toEqual({ not: {} });
  expect(schemas.WaitOperationAmbiguity).toEqual({ not: {} });

  expect(schemas.StartSandboxAccepted).toMatchObject({
    type: "object",
    additionalProperties: false,
    required: ["operationId", "branch", "carrierKind", "schemaStableId"],
    properties: {
      operationId: { const: "operation.start.sandbox" },
      branch: { const: "accepted" },
      carrierKind: { const: "newDurableOperation" },
      schemaStableId: { const: "result.operation.start.sandbox" },
    },
    "x-stable-id": "outcome.accepted",
    "x-wire-tag": "1",
  });
  expect(schemas.WriteProcessInputRejected).toMatchObject({
    oneOf: [
      {
        $ref: "#/components/schemas/WriteProcessInputRejectedRequestInvalidState",
      },
      {
        $ref: "#/components/schemas/WriteProcessInputRejectedRequestSequenceOutOfRange",
      },
    ],
    discriminator: {
      propertyName: "requestErrorId",
      mapping: {
        "request.invalid.state":
          "#/components/schemas/WriteProcessInputRejectedRequestInvalidState",
        "request.sequence.out.of.range":
          "#/components/schemas/WriteProcessInputRejectedRequestSequenceOutOfRange",
      },
    },
  });
  expect(
    schemas.WriteProcessInputRejectedRequestSequenceOutOfRange,
  ).toMatchObject({
    type: "object",
    additionalProperties: false,
    required: ["operationId", "branch", "requestErrorId"],
    properties: {
      operationId: { const: "operation.write.process.input" },
      branch: { const: "rejected" },
      requestErrorId: { const: "request.sequence.out.of.range" },
    },
    "x-stable-id": "outcome.process.rejected",
    "x-wire-tag": "2",
  });

  for (const schema of Object.values(schemas)) {
    if (schema.type === "object") {
      expect(schema.additionalProperties).toBe(false);
      expect(schema.required).toEqual(
        Object.keys(schema.properties as Record<string, unknown>),
      );
      for (const property of Object.values(
        schema.properties as Record<string, Record<string, unknown>>,
      )) {
        expect(property).toHaveProperty("const");
      }
    }
  }
  expect(source).not.toContain('"nullable"');
  expect(source).not.toContain('"fallback"');
  expect(source).not.toContain('"type": "string"');
});
