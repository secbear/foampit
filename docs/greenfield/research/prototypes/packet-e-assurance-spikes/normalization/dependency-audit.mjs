#!/usr/bin/env node

import assert from "node:assert/strict";
import { copyFile, mkdtemp, readFile, symlink, writeFile } from "node:fs/promises";
import { realpath } from "node:fs/promises";
import { existsSync } from "node:fs";
import { tmpdir } from "node:os";
import { dirname, join, resolve } from "node:path";
import { fileURLToPath } from "node:url";
import { spawnSync } from "node:child_process";

const { parse } = (await import("node:internal/deps/acorn/acorn/dist/acorn")).default;
const allowedBuiltins = new Set([
  "node:crypto",
  "node:fs/promises",
  "node:path",
  "node:url"
]);

function die(message) {
  throw new Error(message);
}

function parseAuditArgs(argv) {
  const parsed = {};
  for (let index = 0; index < argv.length; index += 2) {
    if (!argv[index]?.startsWith("--") || argv[index + 1] === undefined) {
      die("usage: dependency-audit.mjs --normalizer FILE --checker FILE");
    }
    parsed[argv[index].slice(2)] = resolve(argv[index + 1]);
  }
  if (!parsed.normalizer || !parsed.checker) die("normalizer and checker entries are required");
  return parsed;
}

async function localGraph(entry) {
  const visited = new Set();

  function walk(node, visitNode) {
    if (!node || typeof node !== "object") return;
    if (typeof node.type === "string") visitNode(node);
    for (const [key, value] of Object.entries(node)) {
      if (key === "start" || key === "end" || key === "loc") continue;
      if (Array.isArray(value)) {
        for (const child of value) walk(child, visitNode);
      } else {
        walk(value, visitNode);
      }
    }
  }

  async function visit(file) {
    const absolute = await realpath(resolve(file));
    if (visited.has(absolute)) return;
    visited.add(absolute);
    const source = await readFile(absolute, "utf8");
    const syntax = parse(source, {
      ecmaVersion: "latest",
      sourceType: "module",
      allowHashBang: true
    });
    const specifiers = [];
    walk(syntax, (node) => {
      if (
        node.type === "ImportDeclaration" ||
        node.type === "ExportNamedDeclaration" ||
        node.type === "ExportAllDeclaration"
      ) {
        if (node.source?.value !== undefined) specifiers.push(node.source.value);
      }
      if (node.type === "ImportExpression") {
        die(`dynamic dependency is forbidden: ${absolute}`);
      }
      if (
        node.type === "CallExpression" &&
        node.callee?.type === "Identifier" &&
        ["require", "eval"].includes(node.callee.name)
      ) {
        die(`indirect dependency is forbidden: ${absolute}`);
      }
      if (
        node.type === "CallExpression" &&
        node.callee?.type === "MemberExpression" &&
        node.callee.object?.type === "Identifier" &&
        node.callee.object.name === "process" &&
        node.callee.property?.name === "getBuiltinModule"
      ) {
        die(`indirect dependency is forbidden: ${absolute}`);
      }
      if (
        (node.type === "CallExpression" || node.type === "NewExpression") &&
        node.callee?.type === "Identifier" &&
        node.callee.name === "Function"
      ) {
        die(`indirect dependency is forbidden: ${absolute}`);
      }
    });
    for (const specifier of specifiers) {
      if (specifier.startsWith("node:")) {
        if (!allowedBuiltins.has(specifier)) {
          die(`indirect dependency builtin is forbidden in ${absolute}: ${specifier}`);
        }
        continue;
      }
      if (!specifier.startsWith(".") && !specifier.startsWith("/")) {
        die(`unpinned package import in ${absolute}: ${specifier}`);
      }
      const dependency = resolve(dirname(absolute), specifier);
      await visit(dependency);
    }
  }
  await visit(entry);
  return visited;
}

async function auditDependencies(normalizerEntry, checkerEntry) {
  const [canonicalNormalizer, canonicalChecker] = await Promise.all([
    realpath(normalizerEntry),
    realpath(checkerEntry)
  ]);
  const [normalizerGraph, checkerGraph] = await Promise.all([
    localGraph(canonicalNormalizer),
    localGraph(canonicalChecker)
  ]);
  if (normalizerGraph.has(canonicalChecker) || checkerGraph.has(canonicalNormalizer)) {
    die("normalizer/checker cross-import detected");
  }
  const sharedSemanticModules = [...normalizerGraph].filter(
    (file) => file !== canonicalNormalizer && checkerGraph.has(file)
  );
  if (sharedSemanticModules.length !== 0) {
    die(`shared semantic implementation module: ${sharedSemanticModules.join(", ")}`);
  }
  return { normalizerModules: normalizerGraph.size, checkerModules: checkerGraph.size };
}

const here = dirname(fileURLToPath(import.meta.url));
const self = fileURLToPath(import.meta.url);
const normalizer = join(here, "normalizer.mjs");
const checker = join(here, "checker.mjs");
const casesPath = join(here, "cases.json");
const cases = JSON.parse(await readFile(casesPath, "utf8"));
const catalog = join(here, cases.catalogFile);
const foreign = join(here, cases.foreignFile);
const testCases = [
  "baseline-independent-replay",
  "omitted-semantic-source-field",
  "selector-semantics",
  "profile-semantics",
  "reference-semantics",
  "import-semantics",
  "authored-order-semantics",
  "constant-normalizer-output",
  "coordinated-source-model-replacement",
  "normalizer-checker-co-drift",
  "forbidden-cross-import",
  "dependency-static-obfuscation",
  "dependency-reexport",
  "dependency-symlink-alias",
  "dependency-dynamic-loading",
  "dependency-indirect-loading",
  "dependency-package-loading",
  "source-digest-mismatch",
  "model-digest-mismatch",
  "normalizer-verdict-output",
  "normalizer-certificate-output"
];

function invoke(script, args, env = {}) {
  const runtimeArgs = script === self ? process.execArgv : [];
  return spawnSync(process.execPath, [...runtimeArgs, script, ...args], {
    cwd: here,
    encoding: "utf8",
    env: { ...process.env, ...env }
  });
}

function requireImplementations() {
  if (!existsSync(normalizer)) die("packet-e/normalizer-unimplemented");
  if (!existsSync(checker)) die("packet-e/checker-unimplemented");
}

function normalize({ catalogPath = catalog, mutation } = {}) {
  const result = invoke(
    normalizer,
    ["--catalog", catalogPath, "--foreign", foreign],
    mutation ? { PACKET_E_NORMALIZER_MUTATION: mutation } : {}
  );
  assert.equal(result.status, 0, result.stderr || result.stdout);
  return JSON.parse(result.stdout);
}

async function check(proof, { checkerMutation } = {}) {
  const temporary = await mkdtemp(join(tmpdir(), "packet-e-normalization-"));
  const proofPath = join(temporary, "proof.json");
  await writeFile(proofPath, `${JSON.stringify(proof)}\n`);
  return invoke(
    checker,
    ["--proof", proofPath, "--cases", casesPath],
    checkerMutation ? { PACKET_E_CHECKER_MUTATION: checkerMutation } : {}
  );
}

async function expectRejected(proof, expected, options = {}) {
  const result = await check(proof, options);
  assert.notEqual(result.status, 0, `mutation survived: ${expected}`);
  assert.match(result.stderr, new RegExp(expected));
}

async function expectDependencyRejected(prefix, injectedSource, expected) {
  const temporary = await mkdtemp(join(tmpdir(), `packet-e-${prefix}-`));
  const badNormalizer = join(temporary, "normalizer.mjs");
  const badChecker = join(temporary, "checker.mjs");
  await copyFile(normalizer, badNormalizer);
  const checkerSource = (await readFile(checker, "utf8")).replace(/^#![^\n]*\n/, "");
  await writeFile(badChecker, `${injectedSource}\n${checkerSource}`);
  const result = invoke(self, [
    "--normalizer",
    badNormalizer,
    "--checker",
    badChecker
  ]);
  assert.notEqual(result.status, 0, `dependency mutation survived: ${prefix}`);
  assert.match(result.stderr, new RegExp(expected));
}

async function runTestCase(name) {
  requireImplementations();
  switch (name) {
    case "baseline-independent-replay": {
      const proof = normalize();
      const result = await check(proof);
      assert.equal(result.status, 0, result.stderr || result.stdout);
      assert.match(result.stdout, /normalization replay: PASS/);
      const audit = invoke(self, [
        "--normalizer",
        normalizer,
        "--checker",
        checker
      ]);
      assert.equal(audit.status, 0, audit.stderr || audit.stdout);
      break;
    }
    case "omitted-semantic-source-field":
      await expectRejected(normalize({ mutation: "omit-reachability" }), "reachability");
      break;
    case "selector-semantics":
      await expectRejected(normalize({ mutation: "selector" }), "model bytes");
      break;
    case "profile-semantics":
      await expectRejected(normalize({ mutation: "profile" }), "model bytes");
      break;
    case "reference-semantics":
      await expectRejected(normalize({ mutation: "reference" }), "model bytes");
      break;
    case "import-semantics":
      await expectRejected(normalize({ mutation: "import" }), "model bytes");
      break;
    case "authored-order-semantics":
      await expectRejected(normalize({ mutation: "order" }), "model bytes");
      break;
    case "constant-normalizer-output": {
      const temporary = await mkdtemp(join(tmpdir(), "packet-e-constant-"));
      const alternateCatalog = join(temporary, "catalog.json");
      const bytes = await readFile(catalog, "utf8");
      await writeFile(
        alternateCatalog,
        bytes.replace('"outcome":"observed"', '"outcome":"denied"')
      );
      await expectRejected(
        normalize({ catalogPath: alternateCatalog, mutation: "constant" }),
        "model bytes"
      );
      break;
    }
    case "coordinated-source-model-replacement": {
      const temporary = await mkdtemp(join(tmpdir(), "packet-e-coordinated-"));
      const alternateCatalog = join(temporary, "catalog.json");
      const bytes = await readFile(catalog, "utf8");
      await writeFile(
        alternateCatalog,
        bytes.replace('"outcome":"observed"', '"outcome":"denied"')
      );
      await expectRejected(
        normalize({ catalogPath: alternateCatalog }),
        "literal source digest mismatch"
      );
      break;
    }
    case "normalizer-checker-co-drift":
      await expectRejected(
        normalize({ mutation: "profile" }),
        "literal expected model",
        { checkerMutation: "profile" }
      );
      break;
    case "forbidden-cross-import": {
      const temporary = await mkdtemp(join(tmpdir(), "packet-e-dependency-"));
      const badNormalizer = join(temporary, "normalizer.mjs");
      const badChecker = join(temporary, "checker.mjs");
      await copyFile(normalizer, badNormalizer);
      await writeFile(
        badChecker,
        `import "./normalizer.mjs";\n${(await readFile(checker, "utf8")).replace(/^#![^\n]*\n/, "")}`
      );
      const result = invoke(self, [
        "--normalizer",
        badNormalizer,
        "--checker",
        badChecker
      ]);
      assert.notEqual(result.status, 0, "forbidden cross-import survived");
      assert.match(result.stderr, /cross-import/);
      break;
    }
    case "dependency-static-obfuscation":
      await expectDependencyRejected(
        "static-obfuscation",
        'import/* hidden edge */"./normalizer.mjs";',
        "cross-import"
      );
      break;
    case "dependency-reexport":
      await expectDependencyRejected(
        "reexport",
        'export { default as hidden } from "./normalizer.mjs";',
        "cross-import"
      );
      break;
    case "dependency-symlink-alias": {
      const temporary = await mkdtemp(join(tmpdir(), "packet-e-symlink-"));
      const badNormalizer = join(temporary, "normalizer.mjs");
      const alias = join(temporary, "alias.mjs");
      const badChecker = join(temporary, "checker.mjs");
      await copyFile(normalizer, badNormalizer);
      await symlink(badNormalizer, alias);
      await writeFile(
        badChecker,
        `import "./alias.mjs";\n${(await readFile(checker, "utf8")).replace(/^#![^\n]*\n/, "")}`
      );
      const result = invoke(self, [
        "--normalizer",
        badNormalizer,
        "--checker",
        badChecker
      ]);
      assert.notEqual(result.status, 0, "dependency mutation survived: symlink-alias");
      assert.match(result.stderr, /cross-import/);
      break;
    }
    case "dependency-dynamic-loading":
      await expectDependencyRejected(
        "dynamic-loading",
        'await import("./normalizer.mjs");',
        "dynamic dependency"
      );
      break;
    case "dependency-indirect-loading":
      await expectDependencyRejected(
        "indirect-loading",
        'import { createRequire as factory } from "node:module";\n' +
          'const load = factory(import.meta.url);\nload("./normalizer.mjs");',
        "indirect dependency"
      );
      break;
    case "dependency-package-loading":
      await expectDependencyRejected(
        "package-loading",
        'import "unlisted-semantic-package";',
        "unpinned package"
      );
      break;
    case "source-digest-mismatch": {
      const proof = normalize();
      proof.sourceSetSha256 = "0".repeat(64);
      await expectRejected(proof, "source digest");
      break;
    }
    case "model-digest-mismatch": {
      const proof = normalize();
      proof.modelSha256 = "f".repeat(64);
      await expectRejected(proof, "model digest");
      break;
    }
    case "normalizer-verdict-output":
      await expectRejected(
        normalize({ mutation: "verdict" }),
        "forbidden normalizer output"
      );
      break;
    case "normalizer-certificate-output":
      await expectRejected(
        normalize({ mutation: "certificate" }),
        "forbidden normalizer output"
      );
      break;
    default:
      die(`unknown normalization case: ${name}`);
  }
}

try {
  if (process.argv[2] === "--all" || process.argv[2] === "--case") {
    const requested = process.argv[2] === "--case" ? [process.argv[3]] : testCases;
    for (const name of requested) {
      if (!testCases.includes(name)) die(`unknown normalization case: ${name}`);
      await runTestCase(name);
      process.stdout.write(`PASS normalization/${name}\n`);
    }
    process.stdout.write(`normalization tests: ${requested.length} passed\n`);
  } else {
    const args = parseAuditArgs(process.argv.slice(2));
    const result = await auditDependencies(args.normalizer, args.checker);
    process.stdout.write(
      `dependency audit: PASS normalizerModules=${result.normalizerModules} ` +
        `checkerModules=${result.checkerModules}\n`
    );
  }
} catch (error) {
  process.stderr.write(`dependency audit: ${error.message}\n`);
  process.exitCode = 1;
}
