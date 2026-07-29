#!/usr/bin/env node

import assert from "node:assert/strict";
import { copyFile, mkdtemp, readFile, symlink, writeFile } from "node:fs/promises";
import { realpath } from "node:fs/promises";
import { existsSync, realpathSync } from "node:fs";
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
const allowedBuiltinMembers = new Map([
  ["node:crypto", new Set(["createHash"])],
  ["node:fs/promises", new Set(["readFile"])],
  ["node:path", new Set(["dirname", "resolve"])],
  ["node:url", new Set(["fileURLToPath"])]
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
  const safeGlobalMembers = new Map([
    ["Array", new Set(["isArray"])],
    ["Object", new Set(["entries", "keys"])],
    ["JSON", new Set(["parse", "stringify"])]
  ]);
  const safeDirectCalls = new Set(["Number"]);
  const safeConstructors = new Set(["Error", "Map", "Set"]);
  const sensitiveProperties = new Set(["__proto__", "constructor", "prototype"]);

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

  class Scope {
    constructor(parent = null) {
      this.parent = parent;
      this.bindings = new Map();
    }

    declare(name) {
      if (!this.bindings.has(name)) {
        this.bindings.set(name, { constantString: null });
      }
    }

    resolve(name) {
      if (this.bindings.has(name)) return this.bindings.get(name);
      return this.parent?.resolve(name) ?? null;
    }
  }

  function declarePattern(pattern, scope) {
    if (!pattern) return;
    switch (pattern.type) {
      case "Identifier":
        scope.declare(pattern.name);
        return;
      case "ArrayPattern":
        for (const element of pattern.elements) declarePattern(element, scope);
        return;
      case "ObjectPattern":
        for (const property of pattern.properties) {
          declarePattern(
            property.type === "RestElement" ? property.argument : property.value,
            scope
          );
        }
        return;
      case "AssignmentPattern":
        declarePattern(pattern.left, scope);
        return;
      case "RestElement":
        declarePattern(pattern.argument, scope);
        return;
      default:
        die(`binding syntax is outside the closed subset: ${pattern.type}`);
    }
  }

  function predeclareStatements(statements, scope) {
    for (const statement of statements) {
      const declaration =
        statement.type === "ExportNamedDeclaration" ||
        statement.type === "ExportDefaultDeclaration"
          ? statement.declaration
          : statement;
      if (!declaration) continue;
      if (declaration.type === "ImportDeclaration") {
        for (const specifier of declaration.specifiers) {
          scope.declare(specifier.local.name);
        }
      } else if (declaration.type === "FunctionDeclaration") {
        if (declaration.id) scope.declare(declaration.id.name);
      } else if (declaration.type === "VariableDeclaration") {
        for (const declarator of declaration.declarations) {
          declarePattern(declarator.id, scope);
        }
      }
    }
  }

  function staticString(node, scope) {
    if (!node) return null;
    if (node.type === "Literal" && typeof node.value === "string") {
      return node.value;
    }
    if (
      node.type === "TemplateLiteral" &&
      node.expressions.length === 0 &&
      node.quasis.length === 1
    ) {
      return node.quasis[0].value.cooked;
    }
    if (node.type === "BinaryExpression" && node.operator === "+") {
      const left = staticString(node.left, scope);
      const right = staticString(node.right, scope);
      return left === null || right === null ? null : left + right;
    }
    if (node.type === "Identifier") {
      return scope.resolve(node.name)?.constantString ?? null;
    }
    return null;
  }

  function scopedPropertyName(node, scope) {
    if (node?.type !== "MemberExpression") return null;
    if (!node.computed && node.property?.type === "Identifier") {
      return node.property.name;
    }
    return node.computed ? staticString(node.property, scope) : null;
  }

  function analyzePatternExpressions(pattern, scope, ancestors) {
    if (!pattern) return;
    switch (pattern.type) {
      case "Identifier":
        return;
      case "ArrayPattern":
        for (const element of pattern.elements) {
          analyzePatternExpressions(element, scope, ancestors);
        }
        return;
      case "ObjectPattern":
        for (const property of pattern.properties) {
          if (property.type === "RestElement") {
            analyzePatternExpressions(property.argument, scope, ancestors);
          } else {
            if (property.computed) {
              const member = staticString(property.key, scope);
              if (member === null) {
                die("unresolved computed property is forbidden");
              }
              if (sensitiveProperties.has(member)) {
                die("prototype or constructor introspection is forbidden");
              }
              analyzeNode(property.key, scope, ancestors);
            }
            analyzePatternExpressions(property.value, scope, ancestors);
          }
        }
        return;
      case "AssignmentPattern":
        analyzePatternExpressions(pattern.left, scope, ancestors);
        analyzeNode(pattern.right, scope, ancestors);
        return;
      case "RestElement":
        analyzePatternExpressions(pattern.argument, scope, ancestors);
        return;
      default:
        die(`binding syntax is outside the closed subset: ${pattern.type}`);
    }
  }

  function validateSafeGlobal(name, ancestors) {
    const parent = ancestors.at(-1);
    const grandparent = ancestors.at(-2);
    if (name === "undefined") {
      if (
        parent?.type === "CallExpression" ||
        parent?.type === "NewExpression" ||
        (parent?.type === "MemberExpression" && parent.object?.type === "Identifier")
      ) {
        die("safe global use is outside the closed subset: undefined");
      }
      return;
    }
    if (safeGlobalMembers.has(name)) {
      const allowedMembers = safeGlobalMembers.get(name);
      if (
        parent?.type !== "MemberExpression" ||
        parent.object?.type !== "Identifier" ||
        parent.object.name !== name ||
        parent.computed ||
        parent.property?.type !== "Identifier" ||
        !allowedMembers.has(parent.property.name) ||
        grandparent?.type !== "CallExpression" ||
        grandparent.callee !== parent
      ) {
        die(`safe global member is forbidden: ${name}`);
      }
      return;
    }
    if (safeDirectCalls.has(name)) {
      if (
        parent?.type !== "CallExpression" ||
        parent.callee?.type !== "Identifier" ||
        parent.callee.name !== name ||
        parent.arguments.length !== 1
      ) {
        die(`safe global use is outside the closed subset: ${name}`);
      }
      return;
    }
    if (safeConstructors.has(name)) {
      const maximumArguments = name === "Error" ? 1 : 1;
      const minimumArguments = name === "Error" ? 1 : 0;
      if (
        parent?.type !== "NewExpression" ||
        parent.callee?.type !== "Identifier" ||
        parent.callee.name !== name ||
        parent.arguments.length < minimumArguments ||
        parent.arguments.length > maximumArguments
      ) {
        die(`safe global use is outside the closed subset: ${name}`);
      }
      return;
    }
    die(`unbound ambient identifier is forbidden: ${name}`);
  }

  function validateImport(node) {
    const allowedMembers = allowedBuiltinMembers.get(node.source?.value);
    if (!allowedMembers) return;
    for (const specifier of node.specifiers) {
      if (
        specifier.type !== "ImportSpecifier" ||
        specifier.imported?.type !== "Identifier" ||
        !allowedMembers.has(specifier.imported.name)
      ) {
        die(`builtin import member is forbidden: ${node.source.value}`);
      }
    }
  }

  function validateBuiltinReexport(node) {
    const allowedMembers = allowedBuiltinMembers.get(node.source?.value);
    if (!allowedMembers) return;
    for (const specifier of node.specifiers) {
      if (
        specifier.type !== "ExportSpecifier" ||
        specifier.local?.type !== "Identifier" ||
        !allowedMembers.has(specifier.local.name)
      ) {
        die(`builtin re-export member is forbidden: ${node.source.value}`);
      }
    }
  }

  function analyzeFunction(node, scope, ancestors) {
    const functionScope = new Scope(scope);
    if (node.type === "FunctionExpression" && node.id) {
      functionScope.declare(node.id.name);
    }
    for (const parameter of node.params) declarePattern(parameter, functionScope);
    for (const parameter of node.params) {
      analyzePatternExpressions(parameter, functionScope, [...ancestors, node]);
    }
    if (node.body.type === "BlockStatement") {
      analyzeNode(node.body, functionScope, ancestors);
    } else {
      analyzeNode(node.body, functionScope, [...ancestors, node]);
    }
  }

  function analyzeNode(node, scope, ancestors = []) {
    if (!node) return;
    const nestedAncestors = [...ancestors, node];
    switch (node.type) {
      case "Program":
        predeclareStatements(node.body, scope);
        for (const statement of node.body) analyzeNode(statement, scope, nestedAncestors);
        return;
      case "BlockStatement": {
        const blockScope = new Scope(scope);
        predeclareStatements(node.body, blockScope);
        for (const statement of node.body) {
          analyzeNode(statement, blockScope, nestedAncestors);
        }
        return;
      }
      case "ImportDeclaration":
        validateImport(node);
        return;
      case "ExportNamedDeclaration":
        if (node.source) validateBuiltinReexport(node);
        analyzeNode(node.declaration, scope, nestedAncestors);
        if (!node.source) {
          for (const specifier of node.specifiers ?? []) {
            if (specifier.local) analyzeNode(specifier.local, scope, nestedAncestors);
          }
        }
        return;
      case "ExportDefaultDeclaration":
        analyzeNode(node.declaration, scope, nestedAncestors);
        if (!node.source) {
          for (const specifier of node.specifiers ?? []) {
            if (specifier.local) analyzeNode(specifier.local, scope, nestedAncestors);
          }
        }
        return;
      case "ExportAllDeclaration":
        if (node.source?.value?.startsWith("node:")) {
          die(`builtin export-star is forbidden: ${node.source.value}`);
        }
        return;
      case "ImportSpecifier":
      case "ImportDefaultSpecifier":
      case "ImportNamespaceSpecifier":
      case "TemplateElement":
      case "Literal":
      case "EmptyStatement":
        return;
      case "VariableDeclaration":
        if (!["const", "let"].includes(node.kind)) {
          die(`variable declaration is outside the closed subset: ${node.kind}`);
        }
        for (const declarator of node.declarations) {
          if (declarator.init) analyzeNode(declarator.init, scope, nestedAncestors);
          analyzePatternExpressions(declarator.id, scope, nestedAncestors);
          if (node.kind === "const" && declarator.id.type === "Identifier") {
            scope.resolve(declarator.id.name).constantString =
              staticString(declarator.init, scope);
          }
        }
        return;
      case "FunctionDeclaration":
      case "FunctionExpression":
      case "ArrowFunctionExpression":
        analyzeFunction(node, scope, ancestors);
        return;
      case "Identifier":
        if (scope.resolve(node.name)) return;
        if (node.name === "process" && exactAllowedProcessUse(ancestors)) return;
        if (node.name === "process") {
          die("privileged capability is forbidden: process");
        }
        validateSafeGlobal(node.name, ancestors);
        return;
      case "ExpressionStatement":
        analyzeNode(node.expression, scope, nestedAncestors);
        return;
      case "CallExpression":
      case "NewExpression":
        analyzeNode(node.callee, scope, nestedAncestors);
        for (const argument of node.arguments) {
          analyzeNode(argument, scope, nestedAncestors);
        }
        return;
      case "MemberExpression": {
        const member = scopedPropertyName(node, scope);
        if (node.computed && member === null) {
          die("unresolved computed member is forbidden");
        }
        if (sensitiveProperties.has(member)) {
          die("prototype or constructor introspection is forbidden");
        }
        analyzeNode(node.object, scope, nestedAncestors);
        if (node.computed) analyzeNode(node.property, scope, nestedAncestors);
        return;
      }
      case "MetaProperty":
        if (node.meta.name !== "import" || node.property.name !== "meta") {
          die("meta property is outside the closed subset");
        }
        return;
      case "ChainExpression":
        analyzeNode(node.expression, scope, nestedAncestors);
        return;
      case "AwaitExpression":
      case "UnaryExpression":
      case "UpdateExpression":
      case "SpreadElement":
        analyzeNode(node.argument, scope, nestedAncestors);
        return;
      case "BinaryExpression":
      case "LogicalExpression":
        analyzeNode(node.left, scope, nestedAncestors);
        analyzeNode(node.right, scope, nestedAncestors);
        return;
      case "ConditionalExpression":
        analyzeNode(node.test, scope, nestedAncestors);
        analyzeNode(node.consequent, scope, nestedAncestors);
        analyzeNode(node.alternate, scope, nestedAncestors);
        return;
      case "AssignmentExpression":
        analyzeNode(node.left, scope, nestedAncestors);
        analyzeNode(node.right, scope, nestedAncestors);
        return;
      case "AssignmentPattern":
        analyzePatternExpressions(node, scope, nestedAncestors);
        return;
      case "ArrayExpression":
        for (const element of node.elements) analyzeNode(element, scope, nestedAncestors);
        return;
      case "SequenceExpression":
        for (const expression of node.expressions) {
          analyzeNode(expression, scope, nestedAncestors);
        }
        return;
      case "ObjectExpression":
        for (const property of node.properties) analyzeNode(property, scope, nestedAncestors);
        return;
      case "Property":
        if (node.computed) {
          const member = staticString(node.key, scope);
          if (member === null) {
            die("unresolved computed property is forbidden");
          }
          if (sensitiveProperties.has(member)) {
            die("prototype or constructor introspection is forbidden");
          }
          analyzeNode(node.key, scope, nestedAncestors);
        }
        analyzeNode(node.value, scope, nestedAncestors);
        return;
      case "ObjectPattern":
      case "ArrayPattern":
      case "RestElement":
        analyzePatternExpressions(node, scope, nestedAncestors);
        return;
      case "ReturnStatement":
      case "ThrowStatement":
        analyzeNode(node.argument, scope, nestedAncestors);
        return;
      case "IfStatement":
        analyzeNode(node.test, scope, nestedAncestors);
        analyzeNode(node.consequent, scope, nestedAncestors);
        analyzeNode(node.alternate, scope, nestedAncestors);
        return;
      case "ForStatement": {
        const loopScope = new Scope(scope);
        if (node.init?.type === "VariableDeclaration") {
          for (const declarator of node.init.declarations) {
            declarePattern(declarator.id, loopScope);
          }
        }
        analyzeNode(node.init, loopScope, nestedAncestors);
        analyzeNode(node.test, loopScope, nestedAncestors);
        analyzeNode(node.update, loopScope, nestedAncestors);
        analyzeNode(node.body, loopScope, nestedAncestors);
        return;
      }
      case "ForOfStatement":
      case "ForInStatement": {
        const loopScope = new Scope(scope);
        if (node.left?.type === "VariableDeclaration") {
          for (const declarator of node.left.declarations) {
            declarePattern(declarator.id, loopScope);
          }
        }
        analyzeNode(node.left, loopScope, nestedAncestors);
        analyzeNode(node.right, loopScope, nestedAncestors);
        analyzeNode(node.body, loopScope, nestedAncestors);
        return;
      }
      case "TemplateLiteral":
        for (const expression of node.expressions) {
          analyzeNode(expression, scope, nestedAncestors);
        }
        return;
      default:
        die(`syntax is outside the closed scope-aware subset: ${node.type}`);
    }
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
    });
    analyzeNode(syntax, new Scope());
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

function hardenedRuntimeArgs(readPaths, omittedFlag = null) {
  const flags = [];
  if (omittedFlag !== "permission") {
    flags.push("--permission");
    for (const path of new Set(readPaths.map((entry) => realpathSync(resolve(entry))))) {
      flags.push(`--allow-fs-read=${path}`);
    }
  }
  if (omittedFlag !== "code-generation") {
    flags.push("--disallow-code-generation-from-strings");
  }
  if (omittedFlag !== "fetch") flags.push("--no-experimental-fetch");
  if (omittedFlag !== "websocket") flags.push("--no-experimental-websocket");
  return flags;
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
  "dependency-async-function-constructor",
  "dependency-function-prototype-constructor",
  "dependency-ambient-fetch",
  "dependency-ambient-websocket",
  "dependency-safe-global-member",
  "dependency-lexical-shadowing-control",
  "dependency-unresolved-let-computed-member",
  "dependency-unresolved-join-computed-member",
  "dependency-resolved-computed-members-control",
  "dependency-builtin-named-reexport-member",
  "dependency-builtin-export-all",
  "dependency-builtin-named-reexport-control",
  "dependency-local-export-all-reexport",
  "runtime-permission-hardening",
  "runtime-code-generation-hardening",
  "runtime-fetch-hardening",
  "runtime-websocket-hardening",
  "runtime-hardening-flags",
  "dependency-package-loading",
  "source-digest-mismatch",
  "model-digest-mismatch",
  "normalizer-verdict-output",
  "normalizer-certificate-output"
];

function invoke(script, args, env = {}, omittedRuntimeFlag = null) {
  const runtimeScript = script === self ? script : realpathSync(script);
  const runtimeCallArgs =
    script === self
      ? args
      : args.map((entry, index) =>
          index % 2 === 1 ? realpathSync(resolve(entry)) : entry
        );
  const runtimeArgs =
    script === self
      ? process.execArgv
      : hardenedRuntimeArgs(
          [
            runtimeScript,
            ...runtimeCallArgs.filter((_, index) => index % 2 === 1),
            ...(script === normalizer ? [catalog] : []),
            ...(script === checker
              ? [resolve(here, cases.expectedModelFile)]
              : [])
          ],
          omittedRuntimeFlag
        );
  return spawnSync(
    process.execPath,
    [...runtimeArgs, runtimeScript, ...runtimeCallArgs],
    {
      cwd: here,
      encoding: "utf8",
      env: { ...process.env, ...env }
    }
  );
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

async function expectDependencyAccepted(prefix, injectedSource) {
  const temporary = await mkdtemp(join(tmpdir(), `packet-e-${prefix}-`));
  const acceptedNormalizer = join(temporary, "normalizer.mjs");
  const acceptedChecker = join(temporary, "checker.mjs");
  await copyFile(normalizer, acceptedNormalizer);
  const checkerSource = (await readFile(checker, "utf8")).replace(/^#![^\n]*\n/, "");
  await writeFile(acceptedChecker, `${injectedSource}\n${checkerSource}`);
  const result = invoke(self, [
    "--normalizer",
    acceptedNormalizer,
    "--checker",
    acceptedChecker
  ]);
  assert.equal(result.status, 0, result.stderr || result.stdout);
}

async function invokeRuntimeProbe(flag, omittedRuntimeFlag = null) {
  const temporary = await mkdtemp(join(tmpdir(), "packet-e-runtime-hardening-"));
  const secret = join(temporary, "forbidden-read.txt");
  await writeFile(secret, "closed\n");
  const probes = [
    {
      flag: "permission",
      source:
        'import { readFileSync } from "node:fs";\n' +
        "let exposed = false;\n" +
        `try { readFileSync(${JSON.stringify(secret)}); exposed = true; } catch {}\n` +
        'process.stdout.write(`${exposed ? "EXPOSED" : "BLOCKED"} permission\\n`);\n' +
        "if (exposed) process.exit(23);\n"
    },
    {
      flag: "code-generation",
      source:
        "let exposed = false;\n" +
        'try { Function("return 1")(); exposed = true; } catch {}\n' +
        'process.stdout.write(`${exposed ? "EXPOSED" : "BLOCKED"} code-generation\\n`);\n' +
        "if (exposed) process.exit(23);\n"
    },
    {
      flag: "fetch",
      source:
        'const exposed = typeof fetch !== "undefined";\n' +
        'process.stdout.write(`${exposed ? "EXPOSED" : "BLOCKED"} fetch\\n`);\n' +
        "if (exposed) process.exit(23);\n"
    },
    {
      flag: "websocket",
      source:
        'const exposed = typeof WebSocket !== "undefined";\n' +
        'process.stdout.write(`${exposed ? "EXPOSED" : "BLOCKED"} websocket\\n`);\n' +
        "if (exposed) process.exit(23);\n"
    }
  ];
  const probe = probes.find((candidate) => candidate.flag === flag);
  assert.ok(probe, `unknown runtime hardening probe: ${flag}`);
  const probePath = join(temporary, `${probe.flag}.mjs`);
  await writeFile(probePath, probe.source);
  return invoke(probePath, [], {}, omittedRuntimeFlag);
}

async function assertRuntimeHardeningFlag(flag) {
  const baseline = await invokeRuntimeProbe(flag);
  assert.equal(
    baseline.status,
    0,
    `runtime hardening baseline failed for ${flag}: ${baseline.stderr}`
  );
  assert.equal(baseline.stdout, `BLOCKED ${flag}\n`);
  const mutation = await invokeRuntimeProbe(flag, flag);
  assert.equal(
    mutation.status,
    23,
    `runtime hardening flag mutation survived: ${flag}`
  );
  assert.equal(mutation.stdout, `EXPOSED ${flag}\n`);
}

async function assertRuntimeBackedDependencyRejected(prefix, injectedSource) {
  const temporary = await mkdtemp(join(tmpdir(), `packet-e-${prefix}-runtime-`));
  const probePath = join(temporary, "prototype-mutation.mjs");
  await writeFile(probePath, `${injectedSource}\n`);
  const runtime = invoke(probePath, []);
  assert.equal(
    runtime.status,
    0,
    `prototype mutation probe did not execute: ${prefix}: ${runtime.stderr}`
  );
  assert.equal(runtime.stdout, `MUTATED ${prefix}\n`);
  try {
    await expectDependencyRejected(
      prefix,
      injectedSource,
      "unresolved computed member"
    );
  } catch (error) {
    throw new Error(
      `${error.message}; prototypeEvidenceStatus=${runtime.status} ` +
        `prototypeEvidenceStdout=${JSON.stringify(runtime.stdout)}`
    );
  }
}

async function assertRuntimeHardeningFlags() {
  for (const flag of ["permission", "code-generation", "fetch", "websocket"]) {
    await assertRuntimeHardeningFlag(flag);
  }
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
    case "dependency-async-function-constructor":
      await expectDependencyRejected(
        "async-function-constructor",
        'const key = "con" + "structor";\n' +
          "const AsyncFunction = Object.getPrototypeOf(async function () {})[key];\n" +
          'const load = AsyncFunction(\'return import("./normalizer.mjs")\');\n' +
          "await load();",
        "prototype or constructor introspection"
      );
      break;
    case "dependency-function-prototype-constructor":
      await expectDependencyRejected(
        "function-prototype-constructor",
        'const key = "con" + "structor";\n' +
          "const FunctionConstructor = (function () {})[key];\n" +
          'const load = FunctionConstructor(\'return import("./normalizer.mjs")\');\n' +
          "await load();",
        "prototype or constructor introspection"
      );
      break;
    case "dependency-ambient-fetch":
      await expectDependencyRejected(
        "ambient-fetch",
        'await fetch("https://example.invalid/");',
        "unbound ambient identifier"
      );
      break;
    case "dependency-ambient-websocket":
      assert.equal(
        typeof WebSocket,
        "function",
        "the pinned Node runtime does not expose the WebSocket global"
      );
      await expectDependencyRejected(
        "ambient-websocket",
        'new WebSocket("ws://127.0.0.1:9");',
        "unbound ambient identifier"
      );
      break;
    case "dependency-safe-global-member":
      await expectDependencyRejected(
        "safe-global-member",
        "const merged = Object.assign({}, { value: 1 });\n" +
          "void merged;",
        "safe global member"
      );
      break;
    case "dependency-lexical-shadowing-control":
      await expectDependencyAccepted(
        "lexical-shadowing-control",
        "function localNetwork(fetch, WebSocket) {\n" +
          "  return fetch(WebSocket);\n" +
          "}\n" +
          'localNetwork((value) => value, "closed");'
      );
      break;
    case "dependency-unresolved-let-computed-member":
      await assertRuntimeBackedDependencyRejected(
        "unresolved-let-computed-member",
        "const target = {};\n" +
          'let constructorKey = "constructor";\n' +
          'let prototypeKey = "prototype";\n' +
          "target[constructorKey][prototypeKey].packetERound5LetMutation = true;\n" +
          "if (({}).packetERound5LetMutation !== true) {\n" +
          '  throw new Error("prototype mutation was not observed");\n' +
          "}\n" +
          'process.stdout.write("MUTATED unresolved-let-computed-member\\n");'
      );
      break;
    case "dependency-unresolved-join-computed-member":
      await assertRuntimeBackedDependencyRejected(
        "unresolved-join-computed-member",
        "const target = {};\n" +
          'const constructorKey = ["con", "structor"].join("");\n' +
          'const prototypeKey = ["proto", "type"].join("");\n' +
          "target[constructorKey][prototypeKey].packetERound5JoinMutation = true;\n" +
          "if (({}).packetERound5JoinMutation !== true) {\n" +
          '  throw new Error("prototype mutation was not observed");\n' +
          "}\n" +
          'process.stdout.write("MUTATED unresolved-join-computed-member\\n");'
      );
      break;
    case "dependency-resolved-computed-members-control":
      await expectDependencyAccepted(
        "resolved-computed-members-control",
        'const key = "value";\n' +
          'const literalData = { ["value"]: 7 };\n' +
          "const templateData = { [`value`]: 7 };\n" +
          'const joinedData = { ["val" + "ue"]: 7 };\n' +
          "const constantData = { [key]: 7 };\n" +
          'const left = literalData["value"];\n' +
          "const middle = templateData[`value`];\n" +
          'const joined = joinedData["val" + "ue"];\n' +
          "const right = constantData[key];\n" +
          "if (left + middle + joined + right !== 28) {\n" +
          '  throw new Error("resolved computed-member control failed");\n' +
          "}"
      );
      break;
    case "dependency-builtin-named-reexport-member":
      await expectDependencyRejected(
        "builtin-named-reexport-member",
        'export { writeFile } from "node:fs/promises";',
        "builtin re-export member"
      );
      break;
    case "dependency-builtin-export-all":
      await expectDependencyRejected(
        "builtin-export-all",
        'export * from "node:path";',
        "builtin export-star"
      );
      break;
    case "dependency-builtin-named-reexport-control":
      await expectDependencyAccepted(
        "builtin-named-reexport-control",
        'export { readFile as exactRead } from "node:fs/promises";'
      );
      break;
    case "dependency-local-export-all-reexport":
      await expectDependencyRejected(
        "local-export-all-reexport",
        'export * from "./normalizer.mjs";',
        "cross-import"
      );
      break;
    case "runtime-permission-hardening":
      await assertRuntimeHardeningFlag("permission");
      break;
    case "runtime-code-generation-hardening":
      await assertRuntimeHardeningFlag("code-generation");
      break;
    case "runtime-fetch-hardening":
      await assertRuntimeHardeningFlag("fetch");
      break;
    case "runtime-websocket-hardening":
      await assertRuntimeHardeningFlag("websocket");
      break;
    case "runtime-hardening-flags":
      await assertRuntimeHardeningFlags();
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
