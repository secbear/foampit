#!/usr/bin/env node

import assert from "node:assert/strict";
import { createHash } from "node:crypto";
import { mkdtemp, readFile, writeFile } from "node:fs/promises";
import { existsSync, readFileSync, realpathSync } from "node:fs";
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
const toolchain = JSON.parse(
  await readFile(join(here, "..", "toolchain.json"), "utf8")
);

const requiredTheorems = [
  "PacketESpike.populationAbstractionUnbounded",
  "PacketESpike.populationInductionSymmetry",
  "PacketESpike.mixedFamilyIncrementCommutation",
  "PacketESpike.coverageShardSpecUniversal",
  "PacketESpike.contextualReductionCompleteCarrier"
];

const cases = [
  "positive-kernel-interface",
  "typed-proof-material-binding",
  "required-theorems-proof-bound",
  "contextual-arbitrary-carrier",
  "semantic-coverage-cardinality",
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
  "expr-alias-prop",
  "expr-arbitrary-prop",
  "expr-private-generated",
  "expr-implicit-prop",
  "expr-transparent-multihop",
  "incomplete-transitive-closure",
  "unpinned-dependency",
  "pinned-dependency-wrong-pin"
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

function leanExprAudit(moduleName, theorem, leanPath) {
  const projectRoot = moduleName.split(".")[0];
  return leanProbe(
    `
import Lean
import ${moduleName}

open Lean Elab Command Meta

private def packetEBelongsToProject (root : String) (name : Name) : Bool :=
  (name.toString.splitOn ".").contains root

private def packetEHeadName? (expression : Expr) : Option String :=
  expression.getAppFn.constName?.map Name.toString

partial def packetEValidateBinders (type : Expr) : MetaM Unit := do
  let type ← whnf type
  match type with
  | .forallE binderName domain body binderInfo =>
      let reducedDomain ← whnf domain
      let headName := packetEHeadName? reducedDomain
      if headName == some "Exists" then
        throwError "Exists premise"
      if headName == some "Decidable" then
        throwError "semantic Decidable premise"
      if headName == some "Subtype" then
        throwError "subtype premise"
      if headName == some "Nonempty" then
        throwError "Nonempty premise"
      if binderInfo.isInstImplicit then
        throwError "typeclass premise"
      match reducedDomain with
      | .sort _ => throwError "nested Type parameter"
      | _ => pure ()
      if ← isProp reducedDomain then
        if headName == some "True" then
          throwError "local proposition premise"
        else if headName == some "Eq" then
          throwError "conclusion-as-assumption"
        else
          throwError "proposition premise"
      withLocalDecl binderName binderInfo domain fun localValue =>
        packetEValidateBinders (body.instantiate1 localValue)
  | _ => pure ()

partial def packetEConstants : Expr → List Name
  | .const name _ => [name]
  | .app function argument =>
      packetEConstants function ++ packetEConstants argument
  | .lam _ domain body _ =>
      packetEConstants domain ++ packetEConstants body
  | .forallE _ domain body _ =>
      packetEConstants domain ++ packetEConstants body
  | .letE _ type value body _ =>
      packetEConstants type ++ packetEConstants value ++ packetEConstants body
  | .mdata _ expression => packetEConstants expression
  | .proj _ _ expression => packetEConstants expression
  | _ => []

partial def packetEValidateBody
    (root : String) (declaration : Name) (visited : Array Name) : MetaM (Array Name) := do
  if visited.contains declaration then
    return visited
  let info ← getConstInfo declaration
  if packetEBelongsToProject root declaration then
    match info with
    | .axiomInfo _ => throwError "project semantic axiom: {declaration}"
    | .opaqueInfo _ => throwError "opaque semantic dependency: {declaration}"
    | _ => pure ()
  let mut result := visited.push declaration
  if let some value := info.value? true then
    for reference in packetEConstants value do
      if packetEBelongsToProject root reference then
        result ← packetEValidateBody root reference result
  return result

run_cmd do
  liftTermElabM do
    let info ← getConstInfo \`${theorem}
    packetEValidateBinders info.type
    let _ ← packetEValidateBody "${projectRoot}" \`${theorem} #[]
    logInfo "PACKET_E_EXPR_AUDIT:PASS"
`,
    { leanPath }
  );
}

function dependencyClosure(
  sourcePath,
  leanPath,
  declaredLocalModules = [],
  declaredLocalPins = {}
) {
  const leanOutput = realpathSync(toolchain.tools.lean.outPath);
  const standardPins = new Map(
    toolchain.tools.lean.libraries.map((library) => [
      realpathSync(library.storePath),
      library.sha256
    ])
  );
  const dependencies = new Map();
  const localModules = new Map();
  const scannedSources = new Set();
  function scan(currentSource) {
    const absoluteSource = realpathSync(resolve(currentSource));
    if (scannedSources.has(absoluteSource)) return;
    scannedSources.add(absoluteSource);
    const result = command("lean", ["--deps", absoluteSource], { leanPath });
    for (const line of result.stdout.split("\n")) {
      const dependency = line.trim();
      if (!dependency) continue;
      const identity = realpathSync(dependency);
      const digest = hash(readFileSync(identity));
      dependencies.set(identity, digest);
      if (identity.startsWith(`${leanOutput}/`)) {
        if (!standardPins.has(identity) || standardPins.get(identity) !== digest) {
          throw new Error(`dependency identity mismatch: ${identity}`);
        }
        continue;
      }
      const relativeModule = leanPath
        ? identity
            .slice(realpathSync(leanPath).length + 1, -".olean".length)
            .replaceAll("/", ".")
        : basename(identity, ".olean");
      localModules.set(relativeModule, { identity, digest });
      const dependencySource = dependency.replace(/\.olean$/, ".lean");
      if (existsSync(dependencySource)) scan(dependencySource);
    }
  }
  scan(sourcePath);
  const expected = new Set(declaredLocalModules);
  if (
    [...localModules.keys()].sort().join(",") !== [...expected].sort().join(",")
  ) {
    throw new Error(
      `incomplete transitive dependency closure: observed=${[
        ...localModules.keys()
      ].sort()} declared=${[...expected].sort()}`
    );
  }
  const declaredPinNames = Object.keys(declaredLocalPins).sort();
  if (declaredPinNames.join(",") !== [...expected].sort().join(",")) {
    throw new Error(
      `incomplete transitive dependency pins: declared=${declaredPinNames} expected=${[
        ...expected
      ].sort()}`
    );
  }
  for (const [module, { digest }] of localModules) {
    if (declaredLocalPins[module] !== digest) {
      throw new Error(`dependency identity mismatch: ${module}`);
    }
  }
  return {
    dependencies: [...dependencies].map(([path, sha256]) => ({ path, sha256 })),
    leanOutput
  };
}

function auditModule({
  moduleName,
  sourcePath,
  theorem,
  leanPath,
  declaredLocalModules = [],
  declaredLocalPins = {},
  inspectInterface = true
}) {
  dependencyClosure(
    sourcePath,
    leanPath,
    declaredLocalModules,
    declaredLocalPins
  );
  const output = leanProbe(
    `import ${moduleName}\nset_option pp.universes true in\n#check @${theorem}\n#print axioms ${theorem}\n`,
    { leanPath }
  );
  const axioms = parseAxioms(output, theorem);
  if (axioms.length !== 0) {
    throw new Error(`unclassified axiom closure: ${axioms.join(",")}`);
  }
  if (inspectInterface) {
    const exprAudit = leanExprAudit(moduleName, theorem, leanPath);
    assert.match(exprAudit, /PACKET_E_EXPR_AUDIT:PASS/);
  }
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
  declaredLocalModules = [],
  declaredLocalPins = {}
}) {
  const directory = await buildFixture(modules);
  let rejected = null;
  try {
    auditModule({
      moduleName: "Fixture",
      sourcePath: join(directory, "Fixture.lean"),
      theorem,
      leanPath: directory,
      declaredLocalModules,
      declaredLocalPins
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

  const evaluate = (expression) =>
    leanProbe(`import PacketESpike\n#eval ${expression}\n`).trim();
  const evaluateJson = (expression) => JSON.parse(evaluate(expression));
  assert.equal(
    evaluateJson("PacketESpike.boundProofMaterial.canonicalBytes"),
    proofBytes,
    "Lean canonical proof-material bytes differ"
  );
  assert.equal(
    evaluateJson("PacketESpike.boundProofMaterial.canonicalSha256"),
    hash(proofBytes),
    "Lean canonical proof-material digest differs"
  );
  assert.equal(
    evaluateJson("PacketESpike.boundProofMaterial.catalog.bytes"),
    Buffer.from(proofMaterial.catalogBytesHex, "hex").toString("utf8"),
    "Lean catalog bytes differ"
  );
  assert.equal(
    Number(evaluate("PacketESpike.boundProofMaterial.catalog.byteCount")),
    Buffer.from(proofMaterial.catalogBytesHex, "hex").length,
    "Lean catalog byte count differs"
  );
  assert.equal(
    evaluateJson("PacketESpike.boundProofMaterial.catalog.sha256"),
    proofMaterial.catalogBytesSha256,
    "Lean catalog digest differs"
  );
  assert.deepEqual(
    evaluateJson("PacketESpike.boundProofMaterial.completeCarrierFields"),
    proofMaterial.completeCarrierFields,
    "Lean complete carrier fields differ"
  );
  assert.equal(
    evaluateJson("PacketESpike.boundProofMaterial.model.bytes"),
    Buffer.from(proofMaterial.modelBytesHex, "hex").toString("utf8"),
    "Lean model bytes differ"
  );
  assert.equal(
    Number(evaluate("PacketESpike.boundProofMaterial.model.byteCount")),
    Buffer.from(proofMaterial.modelBytesHex, "hex").length,
    "Lean model byte count differs"
  );
  assert.equal(
    evaluateJson("PacketESpike.boundProofMaterial.model.sha256"),
    proofMaterial.modelBytesSha256,
    "Lean model digest differs"
  );
  assert.equal(
    Number(evaluate("PacketESpike.boundProofMaterial.shardCount")),
    proofMaterial.shardCount,
    "Lean shard count differs"
  );
  assert.match(
    evaluate("PacketESpike.boundProofMaterial.solverResult"),
    /kernelChecked$/,
    "Lean solver/procedure result differs"
  );

  const source = await readFile(join(here, "PacketESpike.lean"), "utf8");
  if (/\b(?:sorry|admit)\b/.test(source)) throw new Error("sorry/admit source token");
  const declarationOutput = leanProbe(
    "import PacketESpike\n#print PacketESpike.SemanticCarrier\n#print PacketESpike.CoverageShardSpec\n"
  );
  for (const field of proofMaterial.completeCarrierFields) {
    assert.match(declarationOutput, new RegExp(`\\b${field}\\b`));
  }
  assert.doesNotMatch(declarationOutput, /\bcardinalityFormula\b/);
  for (const field of [
    "leftRegion",
    "rightRegion",
    "leftCardinality",
    "rightCardinality",
    "totalCardinality"
  ]) {
    assert.match(declarationOutput, new RegExp(`\\b${field}\\b`));
  }

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
  assert.match(
    interfaces.get(requiredTheorems[3]),
    /HMul\.hMul[\s\S]*2 population/
  );
  assert.match(
    interfaces.get(requiredTheorems[4]),
    /carrier : (?:PacketESpike\.)?SemanticCarrier/
  );
  assert.match(interfaces.get(requiredTheorems[4]), /other interleavings : Nat/);
  assert.match(interfaces.get(requiredTheorems[4]), /SemanticCarrier/);
  assert.match(interfaces.get(requiredTheorems[4]), /contextualCarrierRelation/);
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
  if (name === "typed-proof-material-binding") {
    const source = await readFile(join(here, "PacketESpike.lean"), "utf8");
    assert.match(source, /structure ExactBytesBinding\b/);
    assert.match(source, /structure ProofMaterialTranslation\b/);
    assert.match(source, /def boundProofMaterial\b/);
    assert.match(source, /structure ProofMaterialBound\b/);
    return;
  }
  if (name === "required-theorems-proof-bound") {
    command("lake", ["build"]);
    for (const theorem of requiredTheorems) {
      const body = leanProbe(
        `import PacketESpike\nset_option pp.all true in\n#print ${theorem}\n`
      );
      assert.match(
        body,
        /ProofMaterialBound/,
        `${theorem} is not kernel-bound to exact proof material`
      );
    }
    return;
  }
  if (name === "contextual-arbitrary-carrier") {
    command("lake", ["build"]);
    const output = leanProbe(
      "import PacketESpike\n#check @PacketESpike.contextualReductionCompleteCarrier\n"
    );
    assert.match(output, /\(carrier : PacketESpike\.SemanticCarrier\)/);
    assert.match(output, /contextualCarrierRelation/);
    return;
  }
  if (name === "semantic-coverage-cardinality") {
    command("lake", ["build"]);
    const source = await readFile(join(here, "PacketESpike.lean"), "utf8");
    assert.doesNotMatch(source, /cardinalityFormula\s*:\s*String/);
    const output = leanProbe(
      "import PacketESpike\n#print PacketESpike.CoverageShardSpec\n" +
        "#check @PacketESpike.coverageShardSpecUniversal\n"
    );
    assert.match(output, /leftCardinality/);
    assert.match(output, /rightCardinality/);
    assert.match(output, /totalCardinality/);
    assert.match(output, /2 \* population|population \* 2/);
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
    "expr-alias-prop": {
      modules: {
        Fixture:
          "namespace Fixture\nabbrev HiddenPremise := 1 < 2\n" +
          "theorem target (hidden : HiddenPremise) : True := True.intro\nend Fixture\n"
      },
      expected: "proposition premise"
    },
    "expr-arbitrary-prop": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target (hidden : 1 < 2) : True := True.intro\nend Fixture\n"
      },
      expected: "proposition premise"
    },
    "expr-private-generated": {
      modules: {
        Fixture:
          "namespace Fixture\nprivate abbrev HiddenPremise := 1 < 2\n" +
          "theorem target (hidden : HiddenPremise) : True := True.intro\nend Fixture\n"
      },
      expected: "proposition premise"
    },
    "expr-implicit-prop": {
      modules: {
        Fixture:
          "namespace Fixture\ntheorem target {hidden : 1 < 2} : True := True.intro\nend Fixture\n"
      },
      expected: "proposition premise"
    },
    "expr-transparent-multihop": {
      modules: {
        Fixture:
          "namespace Fixture\nabbrev HiddenA := 1 < 2\nabbrev HiddenB := HiddenA\n" +
          "abbrev HiddenC := HiddenB\n" +
          "theorem target (hidden : HiddenC) : True := True.intro\nend Fixture\n"
      },
      expected: "proposition premise"
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
    },
    "pinned-dependency-wrong-pin": {
      modules: {
        ThirdParty:
          "namespace ThirdParty\ntheorem imported : True := True.intro\nend ThirdParty\n",
        Fixture:
          "import ThirdParty\nnamespace Fixture\ntheorem target : True := ThirdParty.imported\nend Fixture\n"
      },
      declaredLocalModules: ["ThirdParty"],
      declaredLocalPins: { ThirdParty: "0".repeat(64) },
      expected: "dependency identity mismatch"
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
