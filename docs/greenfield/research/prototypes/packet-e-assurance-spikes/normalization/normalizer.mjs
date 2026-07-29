#!/usr/bin/env node

import { createHash } from "node:crypto";
import { readFile } from "node:fs/promises";
import { dirname, resolve } from "node:path";
import { fileURLToPath } from "node:url";

const here = dirname(fileURLToPath(import.meta.url));

function parseArgs(argv) {
  const result = new Map();
  for (let index = 0; index < argv.length; index += 2) {
    const flag = argv.at(index);
    const value = argv.at(index + 1);
    if (!flag?.startsWith("--") || value === undefined) {
      throw new Error("usage: normalizer.mjs --catalog FILE --foreign FILE");
    }
    result.set(flag.slice(2), value);
  }
  if (!result.get("catalog") || !result.get("foreign")) {
    throw new Error("catalog and foreign files are required");
  }
  return result;
}

function ownValue(value, wantedKey) {
  for (const [key, child] of Object.entries(value)) {
    if (key === wantedKey) return child;
  }
  return undefined;
}

function canonical(value) {
  if (Array.isArray(value)) {
    return `[${value.map(canonical).join(",")}]`;
  }
  if (value !== null && typeof value === "object") {
    return `{${Object.entries(value)
      .sort(([left], [right]) => left.localeCompare(right))
      .map(([key, child]) => `${JSON.stringify(key)}:${canonical(child)}`)
      .join(",")}}`;
  }
  return JSON.stringify(value);
}

function sha256(bytes) {
  return createHash("sha256").update(bytes).digest("hex");
}

function pointerTokens(pointer) {
  return pointer
    .split("/")
    .slice(1)
    .map((token) => token.replaceAll("~1", "/").replaceAll("~0", "~"));
}

function atPointer(value, pointer) {
  return pointerTokens(pointer).reduce(
    (current, token) =>
      Array.isArray(current)
        ? current.at(Number(token))
        : ownValue(current, token),
    value
  );
}

function leafPaths(value, prefix = "") {
  if (Array.isArray(value)) {
    return value.flatMap((entry, index) => leafPaths(entry, `${prefix}/${index}`));
  }
  if (value !== null && typeof value === "object") {
    return Object.entries(value)
      .sort(([left], [right]) => left.localeCompare(right))
      .flatMap(([key, child]) =>
        leafPaths(
          child,
          `${prefix}/${key.replaceAll("~", "~0").replaceAll("/", "~1")}`
        )
      );
  }
  return [prefix];
}

function assertKeys(value, expected, label) {
  const actual = Object.keys(value).sort();
  const wanted = [...expected].sort();
  if (canonical(actual) !== canonical(wanted)) {
    throw new Error(`${label} is not closed`);
  }
}

function validateCatalog(catalog, foreign, foreignBytes) {
  assertKeys(catalog, ["imports", "operations", "profiles", "schemaRevision"], "catalog");
  assertKeys(foreign, ["definitions", "schemaRevision"], "foreign catalog");
  const imported = catalog.imports.at(0);
  if (catalog.imports.length !== 1 || imported.path !== "foreign.json") {
    throw new Error("the closed spike requires exactly foreign.json");
  }
  if (imported.sha256 !== sha256(foreignBytes)) {
    throw new Error("pinned foreign import digest mismatch");
  }
  const ids = new Set(catalog.operations.map((operation) => operation.id));
  if (ids.size !== catalog.operations.length) throw new Error("duplicate operation id");
  for (const operation of catalog.operations) {
    assertKeys(
      operation,
      ["id", "order", "outcome", "profile", "reference", "selector"],
      `operation ${operation.id}`
    );
    assertKeys(operation.selector, ["capability", "family"], `selector ${operation.id}`);
    if (!ownValue(catalog.profiles, operation.profile)) {
      throw new Error(`unknown profile ${operation.profile}`);
    }
    if (operation.reference.startsWith("local:") && !ids.has(operation.reference.slice(6))) {
      throw new Error(`unknown local reference ${operation.reference}`);
    }
    if (
      operation.reference.startsWith("foreign:") &&
      !ownValue(foreign.definitions, operation.reference.slice(8))
    ) {
      throw new Error(`unknown foreign reference ${operation.reference}`);
    }
  }
}

function referenceBinding(reference, foreign, mutation) {
  if (reference.startsWith("local:")) {
    return {
      kind: "local",
      target: mutation === "reference" ? "zeta" : reference.slice(6)
    };
  }
  const definition = reference.slice(8);
  const imported = ownValue(foreign.definitions, definition);
  return {
    definition,
    enabled: imported.enabled,
    kind: "foreign",
    lane: mutation === "import" ? "mutated-lane" : imported.lane,
    source: "foreign.json"
  };
}

function buildModel(catalog, foreign, mutation) {
  const operations = catalog.operations.map((operation) => {
    const profile = ownValue(catalog.profiles, operation.profile);
    return {
      effect: profile.effect,
      gates:
        mutation === "profile"
          ? [profile.gates.at(0), "mutated-quota"]
          : [...profile.gates],
      id: operation.id,
      order: operation.order,
      outcome: operation.outcome,
      profile: operation.profile,
      reference: referenceBinding(operation.reference, foreign, mutation),
      selector:
        mutation === "selector" && operation.id === "alpha"
          ? { capability: operation.selector.capability, family: "mutated-family" }
          : { ...operation.selector }
    };
  });
  operations.sort(
    mutation === "order"
      ? (left, right) => left.id.localeCompare(right.id)
      : (left, right) => left.order - right.order || left.id.localeCompare(right.id)
  );
  return {
    foreignRevision: foreign.schemaRevision,
    imports: catalog.imports.map((entry) => ({
      id: entry.id,
      path: entry.path,
      sha256: entry.sha256,
      sourceRevision: foreign.schemaRevision
    })),
    operations,
    schemaRevision: "packet-e-model-v1",
    sourceRevision: catalog.schemaRevision
  };
}

function modelPathsFor(file, sourcePath, catalog, model) {
  const tokens = pointerTokens(sourcePath);
  if (file === "catalog.json" && sourcePath === "/schemaRevision") {
    return ["/sourceRevision"];
  }
  if (file === "catalog.json" && tokens.at(0) === "imports") {
    return [`/imports/${tokens.at(1)}/${tokens.slice(2).join("/")}`];
  }
  if (file === "catalog.json" && tokens.at(0) === "profiles") {
    const profileName = tokens.at(1);
    const suffix = tokens.slice(2).join("/");
    return model.operations
      .map((operation, index) => ({ operation, index }))
      .filter(({ operation }) => operation.profile === profileName)
      .map(({ index }) => `/operations/${index}/${suffix}`);
  }
  if (file === "catalog.json" && tokens.at(0) === "operations") {
    const sourceOperation = catalog.operations.at(Number(tokens.at(1)));
    const modelIndex = model.operations.findIndex((operation) => operation.id === sourceOperation.id);
    const field = tokens.at(2);
    if (field === "profile") {
      return [
        `/operations/${modelIndex}/profile`,
        `/operations/${modelIndex}/effect`,
        `/operations/${modelIndex}/gates`
      ];
    }
    return [`/operations/${modelIndex}/${tokens.slice(2).join("/")}`];
  }
  if (file === "foreign.json" && sourcePath === "/schemaRevision") {
    return ["/foreignRevision", "/imports/0/sourceRevision"];
  }
  if (file === "foreign.json" && tokens.at(0) === "definitions") {
    const definition = tokens.at(1);
    const field = tokens.at(2);
    return model.operations
      .map((operation, index) => ({ operation, index }))
      .filter(({ operation }) => operation.reference.definition === definition)
      .map(({ index }) => `/operations/${index}/reference/${field}`);
  }
  throw new Error(`unmapped semantic source path ${file}:${sourcePath}`);
}

function reachability(catalog, foreign, model) {
  const sources = [
    ["catalog.json", catalog],
    ["foreign.json", foreign]
  ];
  return sources.flatMap(([file, value]) =>
    leafPaths(value).map((sourcePath) => {
      const modelPaths = modelPathsFor(file, sourcePath, catalog, model);
      return {
        file,
        modelPaths,
        modelValueSha256: modelPaths.map((path) => sha256(canonical(atPointer(model, path)))),
        sourcePath,
        sourceValueSha256: sha256(canonical(atPointer(value, sourcePath)))
      };
    })
  );
}

const args = parseArgs(process.argv.slice(2));
const mutation = process.env.PACKET_E_NORMALIZER_MUTATION ?? "";
const catalogBytes = await readFile(resolve(args.get("catalog")), "utf8");
const foreignBytes = await readFile(resolve(args.get("foreign")), "utf8");
const catalog = JSON.parse(catalogBytes);
const foreign = JSON.parse(foreignBytes);
validateCatalog(catalog, foreign, foreignBytes);

let modelCatalog = catalog;
if (mutation === "constant") {
  modelCatalog = JSON.parse(await readFile(resolve(here, "fixtures/catalog.json"), "utf8"));
}
const model = buildModel(modelCatalog, foreign, mutation);
const modelBytes = `${canonical(model)}\n`;
const sources = [
  { bytes: catalogBytes, file: "catalog.json", sha256: sha256(catalogBytes) },
  { bytes: foreignBytes, file: "foreign.json", sha256: sha256(foreignBytes) }
];
const proof = {
  format: "packet-e-normalization-proof-material-v1",
  modelBytes,
  modelSha256: sha256(modelBytes),
  sourceReachability: reachability(catalog, foreign, model),
  sourceSetSha256: sha256(`${canonical(sources)}\n`),
  sources
};

if (mutation === "omit-reachability") {
  proof.sourceReachability = proof.sourceReachability.filter(
    (entry) => !(entry.file === "catalog.json" && entry.sourcePath === "/operations/1/outcome")
  );
}
if (mutation === "verdict") proof.verdict = "pass";
if (mutation === "certificate") proof.normalizationCertificate = { issued: true };

process.stdout.write(`${canonical(proof)}\n`);
