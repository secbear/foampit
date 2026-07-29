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
  const allowedEnvironmentReads = new Set([
    "PACKET_E_CHECKER_MUTATION",
    "PACKET_E_NORMALIZER_MUTATION"
  ]);
  const privilegedGlobals = new Set([
    "Function",
    "Proxy",
    "Reflect",
    "WebAssembly",
    "eval",
    "global",
    "globalThis",
    "require"
  ]);

  function walk(node, visitNode, ancestors = []) {
    if (!node || typeof node !== "object") return;
    if (typeof node.type === "string") visitNode(node, ancestors);
    for (const [key, value] of Object.entries(node)) {
      if (key === "start" || key === "end" || key === "loc") continue;
      if (Array.isArray(value)) {
        for (const child of value) walk(child, visitNode, [...ancestors, node]);
      } else {
        walk(value, visitNode, [...ancestors, node]);
      }
    }
  }

  function propertyName(node) {
    if (node?.type !== "MemberExpression") return null;
    if (!node.computed && node.property?.type === "Identifier") {
      return node.property.name;
    }
    if (node.computed && node.property?.type === "Literal") {
      return typeof node.property.value === "string" ? node.property.value : null;
    }
    if (
      node.computed &&
      node.property?.type === "TemplateLiteral" &&
      node.property.expressions.length === 0
    ) {
      return node.property.quasis[0]?.value?.cooked ?? null;
    }
    return null;
  }

  function exactAllowedProcessUse(ancestors) {
    const parent = ancestors.at(-1);
    const grandparent = ancestors.at(-2);
    const greatGrandparent = ancestors.at(-3);
    if (
      parent?.type !== "MemberExpression" ||
      parent.object?.type !== "Identifier" ||
      parent.object.name !== "process" ||
      parent.computed ||
      parent.property?.type !== "Identifier"
    ) {
      return false;
    }
    if (parent.property.name === "argv") {
      return (
        grandparent?.type === "MemberExpression" &&
        grandparent.object === parent &&
        !grandparent.computed &&
        grandparent.property?.name === "slice" &&
        greatGrandparent?.type === "CallExpression" &&
        greatGrandparent.callee === grandparent &&
        greatGrandparent.arguments.length === 1 &&
        greatGrandparent.arguments[0]?.type === "Literal" &&
        greatGrandparent.arguments[0].value === 2
      );
    }
    if (parent.property.name === "env") {
      return (
        grandparent?.type === "MemberExpression" &&
        grandparent.object === parent &&
        !grandparent.computed &&
        grandparent.property?.type === "Identifier" &&
        allowedEnvironmentReads.has(grandparent.property.name)
      );
    }
    if (["stdout", "stderr"].includes(parent.property.name)) {
      return (
        grandparent?.type === "MemberExpression" &&
        grandparent.object === parent &&
        !grandparent.computed &&
        grandparent.property?.name === "write" &&
        greatGrandparent?.type === "CallExpression" &&
        greatGrandparent.callee === grandparent
      );
    }
    if (parent.property.name === "exit") {
      return (
        grandparent?.type === "CallExpression" &&
        grandparent.callee === parent &&
        grandparent.arguments.length === 1 &&
        grandparent.arguments[0]?.type === "Literal" &&
        grandparent.arguments[0].value === 1
      );
    }
    return false;
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
    walk(syntax, (node, ancestors) => {
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
        node.type === "MemberExpression" &&
        (
          ["getBuiltinModule", "createRequire"].includes(propertyName(node)) ||
          (
            node.computed &&
            node.object?.type === "Identifier" &&
            node.object.name === "process"
          )
        )
      ) {
        die(`indirect dependency is forbidden: ${absolute}`);
      }
      if (
        node.type === "MemberExpression" &&
        ["__proto__", "constructor", "prototype"].includes(propertyName(node))
      ) {
        die(`privileged capability is forbidden: ${absolute}`);
      }
      if (
        node.type === "Identifier" &&
        (
          privilegedGlobals.has(node.name) ||
          (node.name === "process" && !exactAllowedProcessUse(ancestors))
        )
      ) {
        die(`privileged capability is forbidden: ${absolute}`);
      }
      if (
        (node.type === "VariableDeclarator" || node.type === "AssignmentExpression") &&
        (node.init ?? node.right)?.type === "Identifier" &&
        (node.init ?? node.right).name === "process"
      ) {
        die(`indirect dependency is forbidden: ${absolute}`);
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
  "dependency-computed-loader-property",
  "dependency-multihop-loader-alias",
  "dependency-capability-array-concat-multihop",
  "dependency-capability-object-destructure",
  "dependency-capability-sequence",
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
    case "dependency-computed-loader-property":
      await expectDependencyRejected(
        "computed-loader-property",
        'const moduleApi = process["getBuiltinModule"]("node:module");\n' +
          'const load = moduleApi["createRequire"](import.meta.url);\n' +
          'load("./normalizer.mjs");',
        "indirect dependency"
      );
      break;
    case "dependency-multihop-loader-alias":
      await expectDependencyRejected(
        "multihop-loader-alias",
        'const access = process["getBuiltinModule"];\n' +
          "const obtain = access;\n" +
          'const moduleApi = obtain("node:module");\n' +
          "const maker = moduleApi.createRequire;\n" +
          "const renamedMaker = maker;\n" +
          "const load = renamedMaker(import.meta.url);\n" +
          "const renamedLoad = load;\n" +
          'renamedLoad("./normalizer.mjs");',
        "indirect dependency"
      );
      break;
    case "dependency-capability-array-concat-multihop":
      await expectDependencyRejected(
        "capability-array-concat-multihop",
        "const vault = [process];\n" +
          "const recovered = vault[0];\n" +
          'const builtinKey = "getBuiltin" + "Module";\n' +
          "const getBuiltin = recovered[builtinKey];\n" +
          'const moduleApi = getBuiltin("node:" + "module");\n' +
          'const requireKey = "create" + "Require";\n' +
          "const create = moduleApi[requireKey];\n" +
          "const makeLoader = create;\n" +
          "const loader = makeLoader(import.meta.url);\n" +
          "const finalLoader = loader;\n" +
          'finalLoader("./normalizer.mjs");',
        "privileged capability"
      );
      break;
    case "dependency-capability-object-destructure":
      await expectDependencyRejected(
        "capability-object-destructure",
        "const vault = { capability: process };\n" +
          "const { capability: recovered } = vault;\n" +
          'const builtinKey = "getBuiltin" + "Module";\n' +
          "const getBuiltin = recovered[builtinKey];\n" +
          'const moduleApi = getBuiltin("node:" + "module");\n' +
          'const requireKey = "create" + "Require";\n' +
          "const create = moduleApi[requireKey];\n" +
          "const loader = create(import.meta.url);\n" +
          "const finalLoader = loader;\n" +
          'finalLoader("./normalizer.mjs");',
        "privileged capability"
      );
      break;
    case "dependency-capability-sequence":
      await expectDependencyRejected(
        "capability-sequence",
        "const recovered = (0, process);\n" +
          'const builtinKey = "getBuiltin" + "Module";\n' +
          "const getBuiltin = recovered[builtinKey];\n" +
          'const moduleApi = getBuiltin("node:" + "module");\n' +
          'const requireKey = "create" + "Require";\n' +
          "const create = moduleApi[requireKey];\n" +
          "const loader = create(import.meta.url);\n" +
          "const finalLoader = loader;\n" +
          'finalLoader("./normalizer.mjs");',
        "privileged capability"
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
