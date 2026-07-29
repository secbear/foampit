#!/usr/bin/env node

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { basename, dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { performance } from "node:perf_hooks";
import { spawnSync } from "node:child_process";

const here = dirname(fileURLToPath(import.meta.url));
const buildLibrary = join(here, ".lake", "build", "lib", "lean");
const proofMaterialPath = join(here, "proof-material.json");
const catalogPath = join(here, "..", "normalization", "fixtures", "catalog.json");
const modelPath = join(here, "..", "normalization", "fixtures", "expected-model.json");

const requiredTheorems = [
  "PacketESpike.populationAbstractionUnbounded",
  "PacketESpike.populationInductionSymmetry",
  "PacketESpike.mixedFamilyIncrementCommutation",
  "PacketESpike.coverageShardSpecUniversal",
  "PacketESpike.contextualReductionCompleteCarrier"
];

const cases = [
  "positive-kernel-interface",
  "omitted-source-bytes",
  "omitted-model-bytes",
  "solver-unknown",
  "sorry",
  "admit",
  "third-party-axiom",
  "transitive-axiom",
  "local-premise",
  "conclusion-as-assumption",
  "subtype-premise",
  "nonempty-premise",
  "exists-premise",
  "semantic-decidable",
  "typeclass-premise",
  "opaque-premise",
  "nested-type-parameter",
  "incomplete-transitive-closure",
  "unpinned-dependency"
];

function hash(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function command(program, args, options = {}) {
  const result = spawnSync(program, args, {
    cwd: options.cwd ?? here,
    encoding: "utf8",
    env: {
      ...process.env,
      LEAN_PATH: [options.leanPath, buildLibrary, process.env.LEAN_PATH]
        .filter(Boolean)
        .join(":")
    },
    input: options.input
  });
  if (result.status !== 0 && !options.allowFailure) {
    throw new Error(
      `${program} ${args.join(" ")} failed:\n${result.stderr || result.stdout}`
    );
  }
  return result;
}

function leanProbe(source, options = {}) {
  const result = command("lean", ["--stdin"], { ...options, input: source });
  return `${result.stdout}${result.stderr}`;
}

async function validateProofMaterial(material, exactBytes = null) {
  const requiredKeys = [
    "catalogBytesHex",
    "catalogBytesSha256",
    "completeCarrierFields",
    "modelBytesHex",
    "modelBytesSha256",
    "shardCount",
    "solverResult"
  ];
  if (!material.catalogBytesHex) throw new Error("source bytes omitted");
  if (!material.modelBytesHex) throw new Error("model bytes omitted");
  if (Object.keys(material).sort().join(",") !== requiredKeys.sort().join(",")) {
    throw new Error("proof material interface is incomplete");
  }
  if (material.solverResult !== "kernel-checked") {
    throw new Error(`solver/procedure ${material.solverResult}`);
  }
  if (!/^[0-9a-f]+$/.test(material.catalogBytesHex) || material.catalogBytesHex.length % 2 !== 0) {
    throw new Error("catalog exact-byte encoding invalid");
  }
  if (!/^[0-9a-f]+$/.test(material.modelBytesHex) || material.modelBytesHex.length % 2 !== 0) {
    throw new Error("model exact-byte encoding invalid");
  }
  const catalogBytes = Buffer.from(material.catalogBytesHex, "hex");
  const modelBytes = Buffer.from(material.modelBytesHex, "hex");
  if (hash(catalogBytes) !== material.catalogBytesSha256) {
    throw new Error("catalog exact-byte digest mismatch");
  }
  if (hash(modelBytes) !== material.modelBytesSha256) {
    throw new Error("model exact-byte digest mismatch");
  }
  assert.deepEqual(
    material.completeCarrierFields,
    ["enabled", "gates", "nextState", "outcomes", "postcondition", "effects", "evidence"],
    "complete semantic carrier translation is not literal"
  );
  assert.equal(material.shardCount, 2, "CoverageShardSpec shard count is not literal");
  if (exactBytes !== null) {
    assert.equal(
      exactBytes,
      `${JSON.stringify(material)}\n`,
      "proof material is not exact canonical JSON bytes"
    );
    assert.deepEqual(catalogBytes, await readFile(catalogPath), "bound catalog bytes differ");
    assert.deepEqual(modelBytes, await readFile(modelPath), "bound model bytes differ");
  }
}

function parseAxioms(output, theorem) {
  if (output.includes(`'${theorem}' does not depend on any axioms`)) return [];
  const axiomLine = output
    .split("\n")
    .find((line) => line.includes(`'${theorem}' depends on axioms:`));
  const match = axiomLine?.match(/depends on axioms: \[([^\]]*)\]/);
  if (!match) throw new Error(`axiom closure was not reported for ${theorem}`);
  return match[1]
    .split(",")
    .map((name) => name.trim())
    .filter(Boolean);
}

function inspectElaboratedInterface(interfaceText) {
  const forbiddenMarkers = [
    [/\bsorryAx\b/, "sorry/admit"],
    [/\bNonempty\b/, "Nonempty premise"],
    [/\bExists\b|∃/, "Exists premise"],
    [/\bDecidable\b/, "semantic Decidable premise"],
    [/\bSubtype\b|\{ [^}]+ \/\/ /, "subtype premise"],
    [/∀ \[[^\]]+\]/, "typeclass premise"],
    [/: Type(?:\s|[}),])/, "nested Type parameter"],
    [/∀ \([^)]* : True\)|:\s*True\s*→/, "local proposition premise"],
    [
      /∀ \([^)]* : [^)]* = [^)]*\)|:\s*\d+\s*=\s*\d+\s*→|:\s*Eq\.\{\d+\}\s+\d+\s+\d+\s*→/,
      "conclusion-as-assumption"
    ]
  ];
  for (const [pattern, label] of forbiddenMarkers) {
    if (pattern.test(interfaceText)) throw new Error(label);
  }
}

function dependencyClosure(sourcePath, leanPath, declaredLocalModules = []) {
  const prefix = command("lean", ["--print-prefix"]).stdout.trim();
  const dependencies = new Set();
  const localModules = new Set();
  const scannedSources = new Set();
  function scan(currentSource) {
    const absoluteSource = resolve(currentSource);
    if (scannedSources.has(absoluteSource)) return;
    scannedSources.add(absoluteSource);
    const result = command("lean", ["--deps", absoluteSource], { leanPath });
    for (const line of result.stdout.split("\n")) {
      const dependency = line.trim();
      if (!dependency) continue;
      dependencies.add(dependency);
      if (dependency.startsWith(`${prefix}/`)) continue;
      const module = basename(dependency, ".olean");
      localModules.add(module);
      const dependencySource = join(dirname(dependency), `${module}.lean`);
      if (existsSync(dependencySource)) scan(dependencySource);
    }
  }
  scan(sourcePath);
  const expected = new Set(declaredLocalModules);
  if (
    [...localModules].sort().join(",") !== [...expected].sort().join(",")
  ) {
    throw new Error(
      `incomplete transitive dependency closure: observed=${[...localModules].sort()} declared=${[
        ...expected
      ].sort()}`
    );
  }
  return { dependencies: [...dependencies], prefix };
}

function rejectOpaqueSemanticDependencies(moduleName, theorem, leanPath) {
  const pending = [theorem];
  const visited = new Set();
  while (pending.length !== 0) {
    const declaration = pending.pop();
    if (visited.has(declaration)) continue;
    visited.add(declaration);
    const printed = leanProbe(
      `import ${moduleName}\nset_option pp.all true in\n#print ${declaration}\n`,
      { leanPath }
    );
    if (declaration !== theorem && new RegExp(`opaque\\s+${declaration.replaceAll(".", "\\.")}\\b`).test(printed)) {
      throw new Error(`opaque semantic dependency: ${declaration}`);
    }
    const localName = new RegExp(`\\b${moduleName}\\.[A-Za-z_][A-Za-z0-9_']*`, "g");
    for (const referenced of printed.match(localName) ?? []) {
      if (!visited.has(referenced)) pending.push(referenced);
    }
  }
  return [...visited].sort();
}

function auditModule({
  moduleName,
  sourcePath,
  theorem,
  leanPath,
  declaredLocalModules = [],
  inspectInterface = true
}) {
  dependencyClosure(sourcePath, leanPath, declaredLocalModules);
  const output = leanProbe(
    `import ${moduleName}\nset_option pp.universes true in\n#check @${theorem}\n#print axioms ${theorem}\n`,
    { leanPath }
  );
  const axioms = parseAxioms(output, theorem);
  if (axioms.length !== 0) {
    throw new Error(`unclassified axiom closure: ${axioms.join(",")}`);
  }
  rejectOpaqueSemanticDependencies(moduleName, theorem, leanPath);
  if (inspectInterface) inspectElaboratedInterface(output);
  return output;
}

async function buildFixture(modules) {
  const directory = await mkdtemp(join(tmpdir(), "packet-e-lean-audit-"));
  for (const [name, source] of Object.entries(modules)) {
    const path = join(directory, `${name}.lean`);
    await writeFile(path, source);
    command("lean", ["-o", `${name}.olean`, `${name}.lean`], {
      cwd: directory,
      leanPath: directory
    });
  }
  return directory;
}

async function expectFixtureRejected({
  modules,
  theorem = "Fixture.target",
  expected,
  declaredLocalModules = []
}) {
  const directory = await buildFixture(modules);
  let rejected = null;
  try {
    auditModule({
      moduleName: "Fixture",
      sourcePath: join(directory, "Fixture.lean"),
      theorem,
      leanPath: directory,
      declaredLocalModules
    });
  } catch (error) {
    rejected = error;
  }
  assert.ok(rejected, `negative fixture was accepted: ${expected}`);
  assert.match(rejected.message, new RegExp(expected));
}

async function runPositiveAudit() {
  const start = performance.now();
  command("lake", ["build"]);
  const proofBytes = await readFile(proofMaterialPath, "utf8");
  const proofMaterial = JSON.parse(proofBytes);
  await validateProofMaterial(proofMaterial, proofBytes);

  const evaluatedBindings = leanProbe(
    [
      "import PacketESpike",
      "#eval PacketESpike.proofMaterialSha256",
      "#eval PacketESpike.translatedCatalogBytesSha256",
      "#eval PacketESpike.translatedModelBytesSha256",
      "#eval PacketESpike.translatedCompleteCarrierFields",
      "#eval PacketESpike.translatedShardCount"
    ].join("\n")
  );
  assert.match(evaluatedBindings, new RegExp(hash(proofBytes)));
  assert.match(evaluatedBindings, new RegExp(proofMaterial.catalogBytesSha256));
  assert.match(evaluatedBindings, new RegExp(proofMaterial.modelBytesSha256));
  for (const field of proofMaterial.completeCarrierFields) {
    assert.match(evaluatedBindings, new RegExp(`"${field}"`));
  }
  assert.match(evaluatedBindings, /\n2\n/);

  const source = await readFile(join(here, "PacketESpike.lean"), "utf8");
  if (/\b(?:sorry|admit)\b/.test(source)) throw new Error("sorry/admit source token");
  const declarationOutput = leanProbe(
    "import PacketESpike\n#print PacketESpike.SemanticCarrier\n#print PacketESpike.CoverageShardSpec\n"
  );
  for (const field of proofMaterial.completeCarrierFields) {
    assert.match(declarationOutput, new RegExp(`\\b${field}\\b`));
  }
  assert.match(declarationOutput, /\bcardinalityFormula\b/);

  const interfaces = new Map();
  for (const theorem of requiredTheorems) {
    interfaces.set(
      theorem,
      auditModule({
        moduleName: "PacketESpike",
        sourcePath: join(here, "PacketESpike.lean"),
        theorem
      })
    );
  }
  assert.match(interfaces.get(requiredTheorems[0]), /population other interleavings : Nat/);
  assert.match(interfaces.get(requiredTheorems[1]), /left right : Nat/);
  assert.match(interfaces.get(requiredTheorems[2]), /FamilyCoordinate/);
  assert.match(interfaces.get(requiredTheorems[3]), /CoverageCoordinate population/);
  assert.match(interfaces.get(requiredTheorems[3]), /IsBijective/);
  assert.match(interfaces.get(requiredTheorems[4]), /primary other interleavings : Nat/);
  assert.match(interfaces.get(requiredTheorems[4]), /SemanticCarrier/);
  auditModule({
    moduleName: "PacketESpike",
    sourcePath: join(here, "PacketESpike.lean"),
    theorem: "PacketESpike.proofMaterialTranslationBound",
    inspectInterface: false
  });
  const elapsed = performance.now() - start;
  process.stdout.write(
    `formal audit: PASS theorems=6 axioms=0 proofElapsedMs=${elapsed.toFixed(1)}\n`
  );
}

async function runCase(name) {
  if (name === "positive-kernel-interface") {
    await runPositiveAudit();
    return;
  }
  if (["omitted-source-bytes", "omitted-model-bytes", "solver-unknown"].includes(name)) {
    const proof = JSON.parse(await readFile(proofMaterialPath, "utf8"));
    if (name === "omitted-source-bytes") delete proof.catalogBytesHex;
    if (name === "omitted-model-bytes") delete proof.modelBytesHex;
    if (name === "solver-unknown") proof.solverResult = "unknown";
    let rejected = null;
    try {
      await validateProofMaterial(proof);
    } catch (error) {
      rejected = error;
    }
    assert.ok(rejected, `${name} was accepted`);
    const expected = {
      "omitted-source-bytes": "source bytes omitted",
      "omitted-model-bytes": "model bytes omitted",
      "solver-unknown": "solver/procedure unknown"
    }[name];
    assert.match(rejected.message, new RegExp(expected));
    return;
  }

  const fixtures = {
    sorry: {
      modules: { Fixture: "namespace Fixture\ntheorem target : True := by sorry\nend Fixture\n" },
      expected: "sorryAx"
    },
    admit: {
      modules: { Fixture: "namespace Fixture\ntheorem target : True := by admit\nend Fixture\n" },
      expected: "sorryAx"
    },
    "third-party-axiom": {
      modules: {
        Fixture:
          "namespace Fixture\naxiom contradiction : False\ntheorem target : True := False.elim contradiction\nend Fixture\n"
      },
      expected: "Fixture.contradiction"
    },
    "transitive-axiom": {
      modules: {
        Fixture:
          "namespace Fixture\naxiom importedAxiom : True\ntheorem helper : True := importedAxiom\ntheorem target : True := helper\nend Fixture\n"
      },
      expected: "Fixture.importedAxiom"
    },
    "local-premise": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target (semanticPremise : True) : 0 = 0 := rfl\nend Fixture\n"
      },
      expected: "local proposition premise"
    },
    "conclusion-as-assumption": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target (assumed : 2 = 2) : 2 = 2 := assumed\nend Fixture\n"
      },
      expected: "conclusion-as-assumption"
    },
    "subtype-premise": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target (hidden : { unit : Unit // True }) : True := hidden.property\nend Fixture\n"
      },
      expected: "subtype premise"
    },
    "nonempty-premise": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target (hidden : Nonempty { unit : Unit // True }) : True := True.intro\nend Fixture\n"
      },
      expected: "Nonempty premise"
    },
    "exists-premise": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target (hidden : ∃ number : Nat, number = number) : True := True.intro\nend Fixture\n"
      },
      expected: "Exists premise"
    },
    "semantic-decidable": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target [Decidable (0 = 0)] : True := True.intro\nend Fixture\n"
      },
      expected: "semantic Decidable premise"
    },
    "typeclass-premise": {
      modules: {
        Fixture:
          "namespace Fixture\nclass SemanticPremise where witness : True\ntheorem target [SemanticPremise] : True := SemanticPremise.witness\nend Fixture\n"
      },
      expected: "typeclass premise"
    },
    "opaque-premise": {
      modules: {
        Fixture:
          "namespace Fixture\nopaque hidden : True\ntheorem target : True := hidden\nend Fixture\n"
      },
      expected: "Fixture.hidden"
    },
    "nested-type-parameter": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target {Carrier : Type} (value : Carrier) : True := True.intro\nend Fixture\n"
      },
      expected: "nested Type parameter"
    },
    "incomplete-transitive-closure": {
      modules: {
        ThirdParty:
          "namespace ThirdParty\naxiom hidden : True\nend ThirdParty\n",
        Helper:
          "import ThirdParty\nnamespace Helper\ntheorem bridge : True := ThirdParty.hidden\nend Helper\n",
        Fixture:
          "import Helper\nnamespace Fixture\ntheorem target : True := Helper.bridge\nend Fixture\n"
      },
      declaredLocalModules: ["Helper"],
      expected: "incomplete transitive dependency closure"
    },
    "unpinned-dependency": {
      modules: {
        ThirdParty:
          "namespace ThirdParty\ntheorem imported : True := True.intro\nend ThirdParty\n",
        Fixture:
          "import ThirdParty\nnamespace Fixture\ntheorem target : True := ThirdParty.imported\nend Fixture\n"
      },
      expected: "incomplete transitive dependency closure"
    }
  };
  const fixture = fixtures[name];
  if (!fixture) throw new Error(`unknown formal case: ${name}`);
  await expectFixtureRejected(fixture);
}

if (process.argv[2] === "--all") {
  for (const name of cases) {
    await runCase(name);
    process.stdout.write(`PASS formal/${name}\n`);
  }
  process.stdout.write(`formal tests: ${cases.length} passed\n`);
} else if (process.argv[2] === "--case" && cases.includes(process.argv[3])) {
  await runCase(process.argv[3]);
} else {
  throw new Error(`usage: audit.mjs --all | --case ${cases.join("|")}`);
}
