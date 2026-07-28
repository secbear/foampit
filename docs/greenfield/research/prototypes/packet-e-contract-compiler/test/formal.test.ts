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

import { generateCue } from "../src/generate/cue.js";
import { generateAll } from "../src/generate/index.js";
import { generateQuint } from "../src/generate/quint.js";
import { lowerContract } from "../src/lower.js";

const execute = promisify(execFile);
const packageRoot = new URL("../", import.meta.url).pathname;
const { compile } = createTester(packageRoot, { libraries: ["contract"] });

type AdversarialLedger = Readonly<{
  schemaVersion: "0.1.0";
  cue: readonly Readonly<{
    mutation: string;
    constraint: string;
    property: string;
  }>[];
  quint: readonly Readonly<{
    action: string;
    invariant: string;
    property: string;
  }>[];
}>;

async function contractModel() {
  const source = await readFile(
    new URL("../fixtures/valid/packet-e-slice/main.tsp", import.meta.url),
    "utf8",
  );
  return lowerContract((await compile(source)).program);
}

async function adversarialLedger(): Promise<AdversarialLedger> {
  const value: unknown = JSON.parse(
    await readFile(
      new URL(
        "./handwritten/adversarial-outcomes.json",
        import.meta.url,
      ),
      "utf8",
    ),
  );
  if (
    !isRecord(value) ||
    Object.keys(value).sort().join("|") !==
      "cue|quint|schemaVersion" ||
    value.schemaVersion !== "0.1.0" ||
    !Array.isArray(value.cue) ||
    !Array.isArray(value.quint)
  ) {
    throw new Error("contract/adversarial-ledger-invalid");
  }
  for (const [lane, entries, keys] of [
    [
      "cue",
      value.cue,
      ["constraint", "mutation", "property"],
    ],
    [
      "quint",
      value.quint,
      ["action", "invariant", "property"],
    ],
  ] as const) {
    for (const entry of entries) {
      if (
        !isRecord(entry) ||
        Object.keys(entry).sort().join("|") !== keys.join("|") ||
        Object.values(entry).some(
          (field) => typeof field !== "string" || field.length === 0,
        )
      ) {
        throw new Error(`contract/adversarial-ledger-${lane}-entry-invalid`);
      }
    }
  }
  return value as AdversarialLedger;
}

function isRecord(value: unknown): value is Record<string, unknown> {
  return typeof value === "object" && value !== null && !Array.isArray(value);
}

function unique(values: readonly string[]): readonly string[] {
  return [...new Set(values)].sort();
}

function matches(source: string, expression: RegExp): readonly string[] {
  return [...source.matchAll(expression)].map((match) => match[1]!);
}

function pairs(
  source: string,
  expression: RegExp,
): readonly (readonly [string, string])[] {
  return [...source.matchAll(expression)].map((match) => [
    match[1]!,
    match[2]!,
  ]);
}

it("assigns every formal mutant to exactly one independently owned check", async () => {
  const ledger = await adversarialLedger();
  expect(ledger.cue).toHaveLength(20);
  expect(ledger.quint).toHaveLength(11);

  const cueMutations = ledger.cue.map((entry) => entry.mutation);
  const cueConstraints = ledger.cue.map((entry) => entry.constraint);
  const quintActions = ledger.quint.map((entry) => entry.action);
  const quintInvariants = ledger.quint.map((entry) => entry.invariant);
  expect(unique(cueMutations)).toHaveLength(cueMutations.length);
  expect(unique(quintActions)).toHaveLength(quintActions.length);
  expect(unique(quintInvariants)).toHaveLength(quintInvariants.length);

  const [cueTest, quintTest, mutants, invariants] = await Promise.all([
    readFile(new URL("./cue-oracle.test.ts", import.meta.url), "utf8"),
    readFile(new URL("./quint-model.test.ts", import.meta.url), "utf8"),
    readFile(new URL("./handwritten/mutants.qnt", import.meta.url), "utf8"),
    readFile(new URL("./handwritten/invariants.qnt", import.meta.url), "utf8"),
  ]);
  expect(unique(matches(cueTest, /\bname: "([^"]+)"/g))).toEqual(
    unique(cueMutations),
  );
  expect(
    unique(
      matches(
        cueTest,
        /\bmarker: "([^"]+)"/g,
      ),
    ),
  ).toEqual(unique(cueConstraints));
  expect(unique(matches(quintTest, /\baction: "([^"]+)"/g))).toEqual(
    unique(quintActions),
  );
  expect(unique(matches(quintTest, /\binvariant: "([^"]+)"/g))).toEqual(
    unique(quintInvariants),
  );
  expect(
    unique(matches(mutants, /^\s*action (mutant[A-Za-z0-9_]*)\s*=/gm)),
  ).toEqual(unique(quintActions));
  expect(
    unique(
      matches(invariants, /^\s*val ([A-Za-z][A-Za-z0-9_]*)\s*=/gm).filter(
        (name) => name !== "allInvariants",
      ),
    ),
  ).toEqual(unique(quintInvariants));
  expect(
    [
      ...pairs(
        cueTest,
        /\{\s*name: "([^"]+)",\s*marker: "([^"]+)"/g,
      ),
    ].sort(),
  ).toEqual(
    ledger.cue
      .map((entry) => [entry.mutation, entry.constraint] as const)
      .sort(),
  );
  expect(
    [
      ...pairs(
        quintTest,
        /\{\s*action: "([^"]+)",\s*invariant: "([^"]+)"/g,
      ),
    ].sort(),
  ).toEqual(
    ledger.quint
      .map((entry) => [entry.action, entry.invariant] as const)
      .sort(),
  );
  for (const entry of ledger.quint) {
    expect(mutants).toMatch(
      new RegExp(`\\baction ${entry.action.replaceAll("$", "\\$")}(?:\\s|=)`),
    );
    expect(invariants).toMatch(
      new RegExp(`\\bval ${entry.invariant.replaceAll("$", "\\$")}(?:\\s|=)`),
    );
  }
});

it("includes byte-identical CUE and Quint artifacts in the canonical target set", async () => {
  const model = await contractModel();
  const generated = generateAll(model);
  const expected = [...generateCue(model), ...generateQuint(model)];

  for (const formal of expected) {
    const composed = generated.find(
      (candidate) => candidate.relativePath === formal.relativePath,
    );
    expect(composed, formal.relativePath).toEqual(formal);
    expect(
      await readFile(
        new URL(
          `./golden/generated/${formal.relativePath}`,
          import.meta.url,
        ),
      ),
      formal.relativePath,
    ).toEqual(Buffer.from(formal.bytes));
  }
});

it(
  "executes the committed CUE boundary and typechecks the composed Quint model",
  { timeout: 60_000 },
  async () => {
    const temporary = await mkdtemp(join(tmpdir(), "packet-e-formal-"));
    try {
      const contractPath = join(temporary, "contract.qnt");
      await writeFile(
        contractPath,
        await readFile(
          new URL("./golden/generated/quint/contract.qnt", import.meta.url),
        ),
      );
      for (const name of ["machine.qnt", "invariants.qnt", "mutants.qnt"]) {
        await copyFile(
          new URL(`./handwritten/${name}`, import.meta.url),
          join(temporary, name),
        );
      }
      const compositionPath = join(temporary, "formal-composition.qnt");
      await writeFile(
        compositionPath,
        `module PacketEFormalComposition {
  import PacketEInvariants.* from "./invariants"
  import PacketEMutants.* from "./mutants"
}
`,
      );
      await execute(
        "cue",
        [
          "vet",
          "-E",
          "-c",
          "-d",
          "#ContractBundle",
          new URL(
            "./golden/generated/cue/contract.cue",
            import.meta.url,
          ).pathname,
          new URL("./golden/contract-bundle.json", import.meta.url).pathname,
        ],
        {
          cwd: packageRoot,
          signal: AbortSignal.timeout(20_000),
        },
      );
      await execute(
        "quint",
        ["typecheck", compositionPath],
        {
          cwd: temporary,
          signal: AbortSignal.timeout(20_000),
        },
      );
    } finally {
      await rm(temporary, { recursive: true, force: true });
    }
  },
);
