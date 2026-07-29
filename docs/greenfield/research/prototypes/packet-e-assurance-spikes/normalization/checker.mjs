#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

function abort(message) {
  process.stderr.write(`normalization checker: ${message}\n`);
  process.exit(1);
}

function argumentsOf(argv) {
  const parsed = new Map();
  for (let index = 0; index < argv.length; index += 2) {
    const flag = argv.at(index);
    const value = argv.at(index + 1);
    if (!flag?.startsWith("--") || value === undefined) {
      abort("usage: checker.mjs --proof FILE --cases FILE");
    }
    parsed.set(flag.slice(2), value);
  }
  if (!parsed.get("proof") || !parsed.get("cases")) {
    abort("proof and cases files are required");
  }
  return parsed;
}

function findOwnMember(value, wantedName) {
  for (const [name, child] of Object.entries(value)) {
    if (name === wantedName) return { found: true, value: child };
  }
  return { found: false, value: undefined };
}

function encodeCanonical(value) {
  if (value === null || typeof value !== "object") return JSON.stringify(value);
  if (Array.isArray(value)) return `[${value.map(encodeCanonical).join(",")}]`;
  const members = [];
  const entries = Object.entries(value).sort(([left], [right]) =>
    left.localeCompare(right)
  );
  for (const [name, child] of entries) {
    members.push(`${JSON.stringify(name)}:${encodeCanonical(child)}`);
  }
  return `{${members.join(",")}}`;
}

function digest(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function decodePointer(pointer) {
  if (!pointer.startsWith("/")) abort(`invalid JSON pointer ${pointer}`);
  return pointer
    .slice(1)
    .split("/")
    .map((part) => part.replaceAll("~1", "/").replaceAll("~0", "~"));
}

function lookup(value, pointer) {
  let current = value;
  for (const token of decodePointer(pointer)) {
    if (current === null || current === undefined) {
      abort(`model reachability target is absent: ${pointer}`);
    }
    if (Array.isArray(current)) {
      const child = current.at(Number(token));
      if (child === undefined) {
        abort(`model reachability target is absent: ${pointer}`);
      }
      current = child;
    } else {
      const member = findOwnMember(current, token);
      if (!member.found) {
        abort(`model reachability target is absent: ${pointer}`);
      }
      current = member.value;
    }
  }
  return current;
}

function enumerateLeaves(value, prefix = "") {
  if (value !== null && typeof value === "object") {
    if (Array.isArray(value)) {
      return value.flatMap((item, index) => enumerateLeaves(item, `${prefix}/${index}`));
    }
    return Object.entries(value)
      .sort(([left], [right]) => left.localeCompare(right))
      .flatMap(([key, child]) =>
        enumerateLeaves(
          child,
          `${prefix}/${key.replaceAll("~", "~0").replaceAll("/", "~1")}`
        )
      );
  }
  return [prefix];
}

function exactKeys(value, keys, label) {
  if (encodeCanonical(Object.keys(value).sort()) !== encodeCanonical([...keys].sort())) {
    abort(`${label} contains an unknown or missing field`);
  }
}

function findForbiddenOutput(value, path = "") {
  if (value === null || typeof value !== "object") return null;
  for (const [key, child] of Object.entries(value)) {
    const keyPath = `${path}/${key}`;
    if (/(accept|verdict|certificate|baseline)/i.test(key)) return keyPath;
    const nested = findForbiddenOutput(child, keyPath);
    if (nested) return nested;
  }
  return null;
}

function validateClosedSources(catalog, foreign, foreignBytes) {
  exactKeys(catalog, ["imports", "operations", "profiles", "schemaRevision"], "catalog");
  exactKeys(foreign, ["definitions", "schemaRevision"], "foreign catalog");
  if (catalog.imports.length !== 1) abort("closed import count mismatch");
  const imported = catalog.imports.at(0);
  exactKeys(imported, ["id", "path", "sha256"], "import");
  if (
    imported.id !== "foreign-ops" ||
    imported.path !== "foreign.json" ||
    imported.sha256 !== digest(foreignBytes)
  ) {
    abort("foreign import binding mismatch");
  }
  const operationIds = catalog.operations.map((operation) => operation.id);
  if (new Set(operationIds).size !== operationIds.length) abort("operation ids are not unique");
  for (const operation of catalog.operations) {
    exactKeys(
      operation,
      ["id", "order", "outcome", "profile", "reference", "selector"],
      `operation ${operation.id}`
    );
    exactKeys(operation.selector, ["capability", "family"], `selector ${operation.id}`);
    if (!findOwnMember(catalog.profiles, operation.profile).found) {
      abort(`profile is unresolved: ${operation.profile}`);
    }
    const [referenceKind, target] = operation.reference.split(":");
    if (referenceKind === "local" && !operationIds.includes(target)) {
      abort(`local reference is unresolved: ${operation.reference}`);
    }
    if (referenceKind === "foreign" && !findOwnMember(foreign.definitions, target).found) {
      abort(`foreign reference is unresolved: ${operation.reference}`);
    }
    if (!["local", "foreign"].includes(referenceKind)) {
      abort(`reference kind is closed: ${operation.reference}`);
    }
  }
}

function expandReference(rawReference, foreign, checkerMutation) {
  const separator = rawReference.indexOf(":");
  const kind = rawReference.slice(0, separator);
  const target = rawReference.slice(separator + 1);
  if (kind === "local") {
    return {
      kind: "local",
      target: checkerMutation === "reference" ? "zeta" : target
    };
  }
  const definition = findOwnMember(foreign.definitions, target).value;
  return {
    definition: target,
    enabled: definition.enabled,
    kind: "foreign",
    lane: checkerMutation === "import" ? "mutated-lane" : definition.lane,
    source: "foreign.json"
  };
}

function replay(catalog, foreign, checkerMutation) {
  const expanded = [];
  for (const sourceOperation of catalog.operations) {
    const selectedProfile = findOwnMember(
      catalog.profiles,
      sourceOperation.profile
    ).value;
    expanded.push({
      effect: selectedProfile.effect,
      gates:
        checkerMutation === "profile"
          ? [selectedProfile.gates.at(0), "mutated-quota"]
          : selectedProfile.gates.map((gate) => gate),
      id: sourceOperation.id,
      order: sourceOperation.order,
      outcome: sourceOperation.outcome,
      profile: sourceOperation.profile,
      reference: expandReference(sourceOperation.reference, foreign, checkerMutation),
      selector:
        checkerMutation === "selector" && sourceOperation.id === "alpha"
          ? { capability: sourceOperation.selector.capability, family: "mutated-family" }
          : {
              capability: sourceOperation.selector.capability,
              family: sourceOperation.selector.family
            }
    });
  }
  expanded.sort(
    checkerMutation === "order"
      ? (first, second) => first.id.localeCompare(second.id)
      : (first, second) => first.order - second.order || first.id.localeCompare(second.id)
  );
  return {
    foreignRevision: foreign.schemaRevision,
    imports: [
      {
        id: catalog.imports.at(0).id,
        path: catalog.imports.at(0).path,
        sha256: catalog.imports.at(0).sha256,
        sourceRevision: foreign.schemaRevision
      }
    ],
    operations: expanded,
    schemaRevision: "packet-e-model-v1",
    sourceRevision: catalog.schemaRevision
  };
}

function expectedTargets(file, sourcePath, catalog, model) {
  const tokens = decodePointer(sourcePath);
  if (file === "catalog.json" && sourcePath === "/schemaRevision") return ["/sourceRevision"];
  if (file === "catalog.json" && tokens.at(0) === "imports") {
    return [`/imports/${tokens.at(1)}/${tokens.slice(2).join("/")}`];
  }
  if (file === "catalog.json" && tokens.at(0) === "profiles") {
    const profile = tokens.at(1);
    const outputField = tokens.slice(2).join("/");
    const targets = [];
    model.operations.forEach((operation, index) => {
      if (operation.profile === profile) targets.push(`/operations/${index}/${outputField}`);
    });
    return targets;
  }
  if (file === "catalog.json" && tokens.at(0) === "operations") {
    const sourceOperation = catalog.operations.at(Number(tokens.at(1)));
    const destination = model.operations.findIndex((operation) => operation.id === sourceOperation.id);
    if (tokens.at(2) === "profile") {
      return [
        `/operations/${destination}/profile`,
        `/operations/${destination}/effect`,
        `/operations/${destination}/gates`
      ];
    }
    return [`/operations/${destination}/${tokens.slice(2).join("/")}`];
  }
  if (file === "foreign.json" && sourcePath === "/schemaRevision") {
    return ["/foreignRevision", "/imports/0/sourceRevision"];
  }
  if (file === "foreign.json" && tokens.at(0) === "definitions") {
    const definition = tokens.at(1);
    const outputField = tokens.at(2);
    const targets = [];
    model.operations.forEach((operation, index) => {
      if (operation.reference.definition === definition) {
        targets.push(`/operations/${index}/reference/${outputField}`);
      }
    });
    return targets;
  }
  abort(`semantic source path has no independent replay mapping: ${file}:${sourcePath}`);
}

function compareReachability(proof, catalog, foreign, model, cases) {
  if (!Array.isArray(proof.sourceReachability)) abort("reachability proof is absent");
  const sourceValues = new Map([
    ["catalog.json", catalog],
    ["foreign.json", foreign]
  ]);
  const actualPaths = new Map();
  for (const file of sourceValues.keys()) actualPaths.set(file, []);
  const seen = new Set();
  for (const entry of proof.sourceReachability) {
    exactKeys(
      entry,
      ["file", "modelPaths", "modelValueSha256", "sourcePath", "sourceValueSha256"],
      "reachability entry"
    );
    const identity = `${entry.file}:${entry.sourcePath}`;
    if (seen.has(identity)) abort(`duplicate reachability entry ${identity}`);
    seen.add(identity);
    if (!sourceValues.has(entry.file)) abort(`unknown reachability source ${entry.file}`);
    actualPaths.get(entry.file).push(entry.sourcePath);
    const source = sourceValues.get(entry.file);
    const expectedSourceDigest = digest(encodeCanonical(lookup(source, entry.sourcePath)));
    if (entry.sourceValueSha256 !== expectedSourceDigest) {
      abort(`reachability source value digest mismatch at ${identity}`);
    }
    const targets = expectedTargets(entry.file, entry.sourcePath, catalog, model);
    if (encodeCanonical(entry.modelPaths) !== encodeCanonical(targets)) {
      abort(`reachability model paths mismatch at ${identity}`);
    }
    const targetDigests = targets.map((pointer) => digest(encodeCanonical(lookup(model, pointer))));
    if (encodeCanonical(entry.modelValueSha256) !== encodeCanonical(targetDigests)) {
      abort(`reachability model value digest mismatch at ${identity}`);
    }
  }
  for (const [file, expectedPaths] of Object.entries(cases.semanticSourcePaths)) {
    const observed = [...(actualPaths.get(file) ?? [])].sort();
    const literal = [...expectedPaths].sort();
    const parsedLeaves = enumerateLeaves(sourceValues.get(file)).sort();
    if (encodeCanonical(parsedLeaves) !== encodeCanonical(literal)) {
      abort(`literal semantic source path fixture is incomplete for ${file}`);
    }
    if (encodeCanonical(observed) !== encodeCanonical(literal)) {
      abort(`reachability source path set mismatch for ${file}`);
    }
  }
}

const args = argumentsOf(process.argv.slice(2));
const proof = JSON.parse(await readFile(resolve(args.get("proof")), "utf8"));
const cases = JSON.parse(await readFile(resolve(args.get("cases")), "utf8"));
const forbidden = findForbiddenOutput(proof);
if (forbidden) abort(`forbidden normalizer output at ${forbidden}`);

exactKeys(
  proof,
  ["format", "modelBytes", "modelSha256", "sourceReachability", "sourceSetSha256", "sources"],
  "proof material"
);
if (proof.format !== "packet-e-normalization-proof-material-v1") abort("proof format mismatch");
if (!Array.isArray(proof.sources) || proof.sources.length !== 2) abort("exact source bytes are absent");
const sortedSources = [...proof.sources].sort((left, right) => left.file.localeCompare(right.file));
if (encodeCanonical(sortedSources.map((entry) => entry.file)) !== '["catalog.json","foreign.json"]') {
  abort("source set is not the closed two-file catalog");
}
for (const source of sortedSources) {
  exactKeys(source, ["bytes", "file", "sha256"], `source ${source.file}`);
  if (digest(source.bytes) !== source.sha256) abort(`source digest mismatch for ${source.file}`);
}
if (digest(`${encodeCanonical(sortedSources)}\n`) !== proof.sourceSetSha256) {
  abort("source digest mismatch for exact source set");
}

const catalogSource = sortedSources.find((entry) => entry.file === "catalog.json");
const foreignSource = sortedSources.find((entry) => entry.file === "foreign.json");
const catalog = JSON.parse(catalogSource.bytes);
const foreign = JSON.parse(foreignSource.bytes);
validateClosedSources(catalog, foreign, foreignSource.bytes);
const checkerMutation = process.env.PACKET_E_CHECKER_MUTATION ?? "";
const replayedModel = replay(catalog, foreign, checkerMutation);
const replayedBytes = `${encodeCanonical(replayedModel)}\n`;
if (proof.modelBytes !== replayedBytes) abort("model bytes do not match independent replay");
if (digest(proof.modelBytes) !== proof.modelSha256) abort("model digest mismatch");

if (proof.sourceSetSha256 !== cases.expectedSourceSetSha256) {
  abort("literal source digest mismatch for exact source set");
}
if (
  catalogSource.sha256 !== cases.expectedCatalogSha256 ||
  foreignSource.sha256 !== cases.expectedForeignSha256
) {
  abort("literal source digest mismatch");
}
const literalExpectedModel = await readFile(
  resolve(dirname(resolve(args.get("cases"))), cases.expectedModelFile),
  "utf8"
);
if (proof.modelBytes !== literalExpectedModel) abort("literal expected model bytes mismatch");
if (proof.modelSha256 !== cases.expectedModelSha256) abort("literal expected model digest mismatch");

compareReachability(proof, catalog, foreign, replayedModel, cases);
process.stdout.write(
  `normalization replay: PASS sources=${sortedSources.length} fields=${proof.sourceReachability.length}\n`
);
