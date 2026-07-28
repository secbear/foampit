import { execFile } from "node:child_process";
import { mkdtemp, readFile, rm, writeFile } from "node:fs/promises";
import { tmpdir } from "node:os";
import { join } from "node:path";
import { promisify } from "node:util";

import { createTester } from "@typespec/compiler/testing";
import { expect, it } from "vitest";

import { buildContractBundle, type ContractBundle } from "../src/emitter.js";
import { generateCue } from "../src/generate/cue.js";
import { lowerContract } from "../src/lower.js";

const packageRoot = new URL("../", import.meta.url).pathname;
const { compile } = createTester(packageRoot, { libraries: ["contract"] });
const execute = promisify(execFile);
const changedDigest = "0".repeat(64);
const cueTimeoutMs = 20_000;

type Mutable<T> = T extends readonly (infer Item)[]
  ? Mutable<Item>[]
  : T extends object
    ? { -readonly [Key in keyof T]: Mutable<T[Key]> }
    : T;
type MutableBundle = Mutable<ContractBundle>;
type Mutant = Readonly<{
  name: string;
  marker: string;
  mutate: (bundle: MutableBundle) => void;
}>;

async function contractModel() {
  const source = await readFile(
    new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url),
    "utf8",
  );
  return lowerContract((await compile(source)).program);
}

function required<T>(value: T | undefined, description: string): T {
  if (value === undefined) {
    throw new Error(`test setup missing ${description}`);
  }
  return value;
}

async function vet(
  schema: string,
  value: unknown,
  definition = "#ContractBundle",
): Promise<Readonly<{ exitCode: number; diagnostics: string }>> {
  const temporary = await mkdtemp(join(tmpdir(), "packet-e-cue-oracle-"));
  try {
    const schemaPath = join(temporary, "contract.cue");
    const bundlePath = join(temporary, "bundle.json");
    await Promise.all([
      writeFile(schemaPath, schema),
      writeFile(bundlePath, `${JSON.stringify(value)}\n`),
    ]);
    const controller = new AbortController();
    const timeout = setTimeout(() => controller.abort(), cueTimeoutMs);
    try {
      const result = await execute(
        "cue",
        [
          "vet",
          "-E",
          "-c",
          "-d",
          definition,
          "contract.cue",
          "bundle.json",
        ],
        { cwd: temporary, signal: controller.signal },
      );
      return {
        exitCode: 0,
        diagnostics: `${result.stdout}${result.stderr}`,
      };
    } catch (error) {
      if (
        typeof error !== "object" ||
        error === null ||
        !("code" in error) ||
        !("stdout" in error) ||
        !("stderr" in error)
      ) {
        throw error;
      }
      return {
        exitCode: typeof error.code === "number" ? error.code : 1,
        diagnostics: `${String(error.stdout)}${String(error.stderr)}`,
      };
    } finally {
      clearTimeout(timeout);
    }
  } finally {
    await rm(temporary, { recursive: true, force: true });
  }
}

function cloneBundle(bundle: ContractBundle): MutableBundle {
  return structuredClone(bundle) as MutableBundle;
}

it(
  "uses the selected #ContractBundle as a real CUE structural and relational oracle",
  { timeout: 60_000 },
  async () => {
    const model = await contractModel();
    const generated = generateCue(model);
    expect(generated.map((file) => file.relativePath)).toEqual([
      "cue/contract.cue",
    ]);
    const schema = new TextDecoder().decode(generated[0]!.bytes);
    expect(schema).toContain("#ContractBundle:");

    const uniqueSum = {
      id: "probe.sum",
      variants: [
        { id: "probe.variant.first", wireTag: "1" },
        { id: "probe.variant.second", wireTag: "2" },
      ],
    };
    expect(await vet(schema, uniqueSum, "#ClosedSum")).toEqual({
      exitCode: 0,
      diagnostics: "",
    });
    const duplicateTagSum = structuredClone(uniqueSum);
    duplicateTagSum.variants[1]!.wireTag = "1";
    const duplicateTagResult = await vet(
      schema,
      duplicateTagSum,
      "#ClosedSum",
    );
    expect(duplicateTagResult.exitCode).not.toBe(0);
    expect(duplicateTagResult.diagnostics).toContain("#wireTagsUnique");

    const matrixProbe = {
      id: "probe.matrix",
      rowIds: ["row.first", "row.second"],
      columnIds: ["column.first", "column.second"],
      cells: [
        {
          rowId: "row.first",
          columnId: "column.first",
          kind: "noop",
        },
        {
          rowId: "row.first",
          columnId: "column.second",
          kind: "replay",
        },
        {
          rowId: "row.second",
          columnId: "column.first",
          kind: "replay",
        },
        {
          rowId: "row.second",
          columnId: "column.second",
          kind: "noop",
        },
      ],
    };
    expect(
      await vet(
        schema,
        { ...matrixProbe, cells: [...matrixProbe.cells].reverse() },
        "#Matrix",
      ),
    ).toEqual({ exitCode: 0, diagnostics: "" });
    const missingMatrixCell = structuredClone(matrixProbe);
    missingMatrixCell.cells.splice(0, 1);
    const missingMatrixResult = await vet(
      schema,
      missingMatrixCell,
      "#Matrix",
    );
    expect(missingMatrixResult.exitCode).not.toBe(0);
    expect(missingMatrixResult.diagnostics).toContain(
      "#matrixCoordinatesComplete",
    );
    const duplicateMatrixCell = structuredClone(matrixProbe);
    duplicateMatrixCell.cells[3] = structuredClone(
      required(duplicateMatrixCell.cells[0], "probe matrix cell"),
    );
    const duplicateMatrixResult = await vet(
      schema,
      duplicateMatrixCell,
      "#Matrix",
    );
    expect(duplicateMatrixResult.exitCode).not.toBe(0);
    expect(duplicateMatrixResult.diagnostics).toContain(
      "#matrixCoordinatesUnique",
    );
    const extraMatrixCell = structuredClone(matrixProbe);
    extraMatrixCell.cells.push({
      rowId: "row.not.declared",
      columnId: "column.first",
      kind: "noop",
    });
    const extraMatrixResult = await vet(schema, extraMatrixCell, "#Matrix");
    expect(extraMatrixResult.exitCode).not.toBe(0);
    expect(extraMatrixResult.diagnostics).toContain(
      "#matrixCoordinatesDeclared",
    );

    const baseline = buildContractBundle(model);
    const digestControl = cloneBundle(baseline);
    digestControl.semanticDigest = changedDigest;
    expect(await vet(schema, digestControl)).toEqual({
      exitCode: 0,
      diagnostics: "",
    });
    const reorderedCells = cloneBundle(baseline);
    reorderedCells.semanticDigest = changedDigest;
    required(reorderedCells.model.matrices[0], "matrix").cells.reverse();
    expect(await vet(schema, reorderedCells)).toEqual({
      exitCode: 0,
      diagnostics: "",
    });

    const mutants: readonly Mutant[] = [
      {
        name: "deleted matrix cell",
        marker: "#matrixCoordinatesComplete",
        mutate(bundle) {
          required(bundle.model.matrices[0], "matrix").cells.splice(0, 1);
        },
      },
      {
        name: "duplicate matrix cell",
        marker: "#matrixCoordinatesUnique",
        mutate(bundle) {
          const cells = required(bundle.model.matrices[0], "matrix").cells;
          cells.push(structuredClone(required(cells[0], "matrix cell")));
        },
      },
      {
        name: "wildcard matrix coordinate",
        marker: "#matrixCoordinatesDeclared",
        mutate(bundle) {
          required(
            required(bundle.model.matrices[0], "matrix").cells[0],
            "matrix cell",
          ).rowId = "*";
        },
      },
      {
        name: "undeclared matrix coordinate",
        marker: "#matrixCoordinatesDeclared",
        mutate(bundle) {
          required(
            required(bundle.model.matrices[0], "matrix").cells[0],
            "matrix cell",
          ).columnId = "operation.not.declared";
        },
      },
      {
        name: "duplicate matrix axis",
        marker: "#rowIdsUnique",
        mutate(bundle) {
          const rowIds = required(bundle.model.matrices[0], "matrix").rowIds;
          rowIds[1] = required(rowIds[0], "matrix row");
        },
      },
      {
        name: "operation-inadmissible request error",
        marker: "#requestErrorsAdmissible",
        mutate(bundle) {
          const errors = required(
            bundle.model.operations.find(
              (operation) =>
                operation.operationId === "operation.start.sandbox",
            ),
            "StartSandbox operation",
          ).allowedRequestErrors;
          errors[0] = "request.sequence.out.of.range";
        },
      },
      {
        name: "duplicate closed-sum wire tag",
        marker: "#wireTagSelected",
        mutate(bundle) {
          const sum = required(
            bundle.model.closedSums.find(
              (candidate) => candidate.variants.length > 1,
            ),
            "multi-variant closed sum",
          );
          required(sum.variants[1], "second closed-sum variant").wireTag =
            required(sum.variants[0], "first closed-sum variant").wireTag;
        },
      },
      {
        name: "WaitOperation changed to mutation",
        marker: "#waitOperationObservation",
        mutate(bundle) {
          required(
            bundle.model.operations.find(
              (operation) =>
                operation.operationId === "operation.wait.operation",
            ),
            "WaitOperation",
          ).callClass = "durableOperationMutation";
        },
      },
      {
        name: "observation changed to an accepted branch",
        marker: "#observationBranchShape",
        mutate(bundle) {
          required(
            bundle.model.operations.find(
              (operation) =>
                operation.operationId === "operation.wait.operation",
            ),
            "WaitOperation",
          ).resultBranches[0] = "accepted";
        },
      },
      {
        name: "transition references an undeclared state",
        marker: "#matrixTransitionsResolve",
        mutate(bundle) {
          required(
            required(bundle.model.matrices[0], "matrix").cells.find(
              (cell) => cell.kind === "transition",
            ),
            "transition cell",
          ).nextStateId = "state.sandbox.not.declared";
        },
      },
      {
        name: "matrix cell has a valid but source-incorrect kind",
        marker: "#matrixCellsSelected",
        mutate(bundle) {
          const cell = required(
            required(bundle.model.matrices[0], "matrix").cells.find(
              (candidate) => candidate.kind === "replay",
            ),
            "replay cell",
          );
          (cell as { kind: string }).kind = "noop";
        },
      },
      {
        name: "transition has a valid but source-incorrect next state",
        marker: "#matrixCellsSelected",
        mutate(bundle) {
          required(
            required(bundle.model.matrices[0], "matrix").cells.find(
              (cell) => cell.kind === "transition",
            ),
            "transition cell",
          ).nextStateId = "state.sandbox.running";
        },
      },
      {
        name: "reject has a valid but source-incorrect request error",
        marker: "#matrixCellsSelected",
        mutate(bundle) {
          const cell = required(
            required(bundle.model.matrices[0], "matrix").cells.find(
              (candidate) =>
                candidate.kind === "reject" &&
                candidate.columnId === "operation.write.process.input",
            ),
            "WriteProcessInput reject cell",
          );
          if (cell.kind !== "reject") {
            throw new Error("test setup expected a reject cell");
          }
          cell.requestErrorId = "request.sequence.out.of.range";
        },
      },
      {
        name: "operation references an undeclared matrix",
        marker: "#matrixReferencesResolve",
        mutate(bundle) {
          required(
            bundle.model.operations.find(
              (operation) =>
                operation.operationId === "operation.start.sandbox",
            ),
            "StartSandbox operation",
          ).matrixIds[0] = "matrix.not.declared";
        },
      },
      {
        name: "bundle identity changed",
        marker: "bundleVersion",
        mutate(bundle) {
          (
            bundle as unknown as {
              bundleVersion: string;
            }
          ).bundleVersion = "0.2.0";
        },
      },
      {
        name: "model identity changed",
        marker: "contractId",
        mutate(bundle) {
          (
            bundle.model as unknown as {
              contractId: string;
            }
          ).contractId = "packet-e-not-the-selected-contract";
        },
      },
      {
        name: "undeclared model field",
        marker: "field not allowed",
        mutate(bundle) {
          (
            bundle.model as unknown as Record<string, unknown>
          ).undeclaredField = true;
        },
      },
    ];

    for (const mutant of mutants) {
      const bundle = cloneBundle(baseline);
      bundle.semanticDigest = changedDigest;
      mutant.mutate(bundle);
      const result = await vet(schema, bundle);
      expect(
        result.exitCode,
        `${mutant.name} unexpectedly passed CUE vet`,
      ).not.toBe(0);
      expect(
        result.diagnostics,
        `${mutant.name} failed without its assigned CUE marker`,
      ).toContain(mutant.marker);
    }

    const regeneratedSchemaMutants: readonly Mutant[] = [
      {
        name: "regenerated schema from an incomplete matrix",
        marker: "#matrixCoordinatesComplete",
        mutate(bundle) {
          required(bundle.model.matrices[0], "matrix").cells.splice(0, 1);
        },
      },
      {
        name: "regenerated schema from duplicate matrix coordinates",
        marker: "#matrixCoordinatesUnique",
        mutate(bundle) {
          const cells = required(bundle.model.matrices[0], "matrix").cells;
          cells[1] = structuredClone(required(cells[0], "matrix cell"));
        },
      },
      {
        name: "regenerated schema from an extra undeclared matrix cell",
        marker: "#matrixCoordinatesDeclared",
        mutate(bundle) {
          required(bundle.model.matrices[0], "matrix").cells.push({
            rowId: "state.sandbox.not.declared",
            columnId: "operation.start.sandbox",
            kind: "noop",
          });
        },
      },
    ];
    for (const mutant of regeneratedSchemaMutants) {
      const bundle = cloneBundle(baseline);
      bundle.semanticDigest = changedDigest;
      mutant.mutate(bundle);
      const regeneratedSchema = new TextDecoder().decode(
        generateCue(bundle.model)[0]!.bytes,
      );
      const result = await vet(regeneratedSchema, bundle);
      expect(
        result.exitCode,
        `${mutant.name} unexpectedly passed its regenerated CUE schema`,
      ).not.toBe(0);
      expect(
        result.diagnostics,
        `${mutant.name} did not exercise its independent CUE relation`,
      ).toContain(mutant.marker);
    }
  },
);
