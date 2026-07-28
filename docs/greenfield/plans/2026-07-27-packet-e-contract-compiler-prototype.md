# Packet E Contract Compiler Vertical Slice Implementation Plan

> **For agentic workers:** REQUIRED SUB-SKILL: Use superpowers:subagent-driven-development (recommended) or superpowers:executing-plans to implement this plan task-by-task. Steps use checkbox (`- [ ]`) syntax for tracking.

**Goal:** Build a disposable but executable vertical slice proving that a strict TypeSpec contract source can lower into one product-owned Contract Model and deterministically generate closed language boundaries, transport schemas, an independent CUE oracle, and Quint vocabulary consumed by an independently authored formal reference machine.

**Architecture:** TypeSpec is only the human authoring and source-diagnostic frontend. A custom TypeSpec library validates local and graph-wide rules, lowers every accepted source into a closed normalized `ContractModel`, and emits a canonical `ContractBundle` plus a non-semantic `SourceMap`. Every language, transport, validation, documentation, and formal emitter consumes only the normalized model; no downstream emitter reads TypeSpec compiler objects.

**Tech Stack:** Nixpkgs revision `624af665418d3c65d544145b4d34ad696439570e`; Node.js 22.23.1; pnpm 10.34.5; TypeSpec 1.14.0; TypeScript 6.0.3; Vitest 4.1.9; `@types/node` 22.20.1; Rust 1.96 or newer; Go 1.26 or newer; Python 3.13 or newer; CUE 0.17.1; Quint 0.32.0; Protobuf 35.1.

**Execution status (2026-07-28):** Complete as a research prototype. All
37 planned steps were executed; the measured result and architecture
recommendation are recorded in
[RESULTS.md](../research/prototypes/packet-e-contract-compiler/RESULTS.md).
Completion of this plan does not close Packet E, Gate 2A, or Gate 4B.

**Standalone extraction note (2026-07-28):** The original run included one
external predecessor-daemon regression sentinel. Foampit preserves that
measurement as historical provenance but removes the sentinel from the current
harness. The standalone harness has 21 product-owned stages and manifests only
the compiler prototype's own inputs.

## Global Constraints

- This is a research prototype under `docs/greenfield/research/prototypes/packet-e-contract-compiler/`; it must not import or modify the legacy daemon, create a root Cargo/npm workspace, or claim production readiness.
- This prototype is evidence about the compiler architecture only. It does not close Packet E, Gate 2A, or Gate 4B and must state that the exhaustive per-method inventory, operation-pair matrix, registry identifiers, retention details, writer-lease lifecycle, Snapshot schemas, and backend conformance remain open.
- Semantic names are exactly `RequestError`, `RecoveryError`, `OperationOutcome`, `ProcessTermination`, `ProcessControlOutcome`, `CallerRecovery`, `CoreResolution`, `TransportError`, and `ProviderEvidence`.
- The vertical slice contains exactly `StartSandbox`, `CancelOperation`, `WriteProcessInput`, and `WaitOperation`, representing durable Operation mutation, existing-handle intent, sequenced Process control, and observation respectively.
- Sandbox runtime states are exactly `stopped`, `provisioning`, `running`, and `unknown` in this slice. Operation states are exactly `accepted`, `running`, `cancel_requested`, `succeeded`, `failed`, `cancelled`, and `unknown`. Process states are exactly `accepted`, `starting`, `running`, `unknown`, and `terminated`.
- Every stable contract and wire identity is explicit. Source names, declaration order, object insertion order, absolute paths, timestamps, host information, and locale may not affect semantic identity.
- Contract Source explicitly selects `packet-e-contract-prototype`; the selected profile materializes the exact four operations, one matrix, fourteen closed sums, their exact variants, and terminal state IDs. There is no absent-profile fallback.
- There is no wildcard/default matrix entry, nullable semantic handle, generic provider error, open string reason, arbitrary detail object, or `retryable` boolean in Contract Source, Contract Model, or generated boundaries.
- `WaitOperation` has `observed` as its only success branch plus the
  pre-acceptance `rejected` branch. It never admits `accepted` or `recovery`.
  The three non-observation methods have only accepted/rejected/recovery
  branches appropriate to their call class. No method admits both `Observed`
  and `Accepted`.
- Semantic validation uses exact-set equality. Missing, extra, duplicate, unreachable, remapped, or wildcard cells and variants are compilation errors.
- The semantic digest is SHA-256 over canonical JSON bytes of `ContractModel`, not over `ContractBundle` and not over source text. The source map is excluded from that digest.
- The semantic JSON domain uses strings, booleans, null, arrays, and objects. Semantically relevant integers such as wire tags and sequence bounds are canonical decimal strings, avoiding cross-language number ambiguity.
- Generated files are never edited. Tests regenerate them into a fresh temporary directory and compare them with committed goldens byte-for-byte.
- All dependencies are exact-version pinned and the lockfile is frozen. Compiler and emitter execution uses the locally installed TypeSpec compiler, never a global npm package.
- Production code follows red-green-refactor. Every semantic rejection test must be observed failing because the rule is absent before its validator is added.

---

### Task 1: Pinned TypeSpec Package and Strict Contract Vocabulary

**Files:**
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/flake.nix`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/package.json`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/pnpm-lock.yaml`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/tsconfig.json`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/tspconfig.yaml`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/lib/main.tsp`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/lib.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/decorators.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/accessors.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/index.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/library.test.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/fixtures/strict-valid/main.tsp`

**Interfaces:**
- Consumes: TypeSpec `Program`, decorator contexts, named models, named unions, operations, and TypeSpec values.
- Produces: `$lib`, `$decorators`, `getContractRoot(program)`, `getStableId(program, target)`, `getWireTag(program, target)`, `getOperationDefinition(program, operation)`, and diagnostics with the `contract/` prefix.

- [x] **Step 1: Write the failing library tests**

  First create the package metadata and Nix development shell so the tests can
  execute. `package.json` must use `"type": "module"`,
  `"private": true`, `"packageManager": "pnpm@10.34.5"`, exact development
  dependencies `@typespec/compiler@1.14.0`, `typescript@6.0.3`,
  `vitest@4.1.9`, and `@types/node@22.20.1`, plus an exact
  `@typespec/compiler` peer dependency. Generate and retain a frozen
  `pnpm-lock.yaml`. The flake input must be the exact Nixpkgs revision from
  the Tech Stack and its development shell must expose the exact Node, pnpm,
  CUE, Quint, and Protobuf versions listed there.

  Add TypeSpec compiler tests using only `createTester` from `@typespec/compiler/testing`. The tests must assert:

  ```ts
  expect(await diagnose(`@contractRoot namespace Slice;`)).toEqual([]);
  expectDiagnostic(
    await diagnose(`@stableId("core.start") @stableId("core.other") op Start(): void;`),
    "contract/conflicting-stable-id",
  );
  expectDiagnostic(
    await diagnose(`@stableId("core.start") op Start(): void; @stableId("core.start") op Other(): void;`),
    "contract/duplicate-stable-id",
  );
  expectDiagnostic(
    await diagnose(`@wireTag("1") union Outcome { @wireTag("1") ok: void, @wireTag("1") failed: void }`),
    "contract/duplicate-wire-tag",
  );
  ```

  The valid fixture must use explicit stable IDs and decimal-string wire tags for all named state, result, error, evidence, and method variants.

- [x] **Step 2: Run the tests and verify RED**

  Run:

  ```sh
  nix develop --command pnpm install --frozen-lockfile
  nix develop --command pnpm test --run test/library.test.ts
  ```

  Expected: the test command fails because the library and decorators do not yet exist.

- [x] **Step 3: Implement the minimal TypeSpec library**

  Define ordinary `extern dec` decorators, not experimental auto-decorators:

  ```typespec
  extern dec contractRoot(target: Namespace);
  extern dec stableId(target: unknown, id: valueof string);
  extern dec wireTag(target: UnionVariant | ModelProperty, tag: valueof string);
  extern dec operationContract(target: Operation, definition: valueof OperationDefinition);
  ```

  Implement local argument validation in decorators, conflicting-decorator validation in `onTargetFinish`, and duplicate graph identities in `onGraphFinish`. Store metadata only through `$lib.stateKeys` with `program.stateMap` or `program.stateSet`.

- [x] **Step 4: Run formatter, typecheck, and focused tests**

  Run:

  ```sh
  nix develop --command pnpm format:check
  nix develop --command pnpm typecheck
  nix develop --command pnpm test --run test/library.test.ts
  ```

  Expected: all commands exit zero and the focused suite reports no failed tests.

- [x] **Step 5: Commit**

  Stage only Task 1 files and commit:

  ```sh
  git commit -m "prototype: establish strict TypeSpec contract vocabulary"
  ```

### Task 2: Define Explicit Vertical-Slice Metadata and a Valid Contract Source

**Files:**
- Modify: `docs/greenfield/research/prototypes/packet-e-contract-compiler/lib/main.tsp`
- Modify: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/lib.ts`
- Modify: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/decorators.ts`
- Modify: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/accessors.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/definition.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/definition.test.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/fixtures/valid/packet-e-slice/main.tsp`

**Interfaces:**
- Consumes: the strict decorator/state infrastructure from Task 1.
- Produces:

  ```ts
  export type OperationDefinitionValue = {
    operationId: string;
    callClass: CallClass;
    resultBranches: readonly ResultBranch[];
    allowedRequestErrors: readonly string[];
    allowedRecoveryErrors: readonly string[];
    allowedKnownFailures: readonly string[];
    allowedAmbiguities: readonly string[];
    recoveryCoordinates: readonly RecoveryCoordinate[];
    matrixIds: readonly string[];
    result: {
      carrier:
        | "newOperation"
        | "existingOperationObservation"
        | "processControlReceipt"
        | "observation";
      schemaStableId: string;
    };
  };

  export function getOperationDefinition(
    program: Program,
    operation: Operation,
  ): OperationDefinitionValue | undefined;

  export function getMatrixDefinitions(
    program: Program,
  ): readonly MatrixDefinitionValue[];
  ```

- [x] **Step 1: Write failing explicit-metadata tests**

  Use `createTester` to compile one source containing the four methods and all
  closed state/error/outcome unions from Global Constraints. Every operation
  must pass a complete TypeSpec object value to `@operationContract`; matrices
  must use complete arrays of explicit row/column/cell object values.

  Tests must assert literal accessor output for:

  - `StartSandbox`: `durableOperationMutation`, accepted/rejected/recovery
    branches, explicit runtime-epoch and idempotency coordinates;
  - `CancelOperation`: `existingHandleIntent`, the existing Operation as its
    accepted result, no Operation-of-Operation;
  - `WriteProcessInput`: `sequencedProcessControl`, the exact process/runtime/
    writer-lease/sequence recovery coordinate;
  - `WaitOperation`: `observation`, observed-only success with a
    pre-acceptance rejected branch, and no acceptance/recovery coordinate.

  Add one case omitting each required `OperationDefinition` field and assert a
  TypeSpec structural diagnostic. Add one case using `"*"` as a state
  coordinate and assert `contract/wildcard-cell-forbidden`.

- [x] **Step 2: Run the focused tests and verify RED**

  Run:

  ```sh
  nix develop --command pnpm test --run test/definition.test.ts
  ```

  Expected: failures identify the empty `OperationDefinition`, absent matrix
  vocabulary/accessors, and absent wildcard validation.

- [x] **Step 3: Implement the explicit closed TypeSpec value vocabulary**

  Define literal unions for call class, result branch, matrix cell kind, and
  recovery-coordinate kind. Define closed TypeSpec models for operation and
  matrix values with every semantic field required; do not use optional
  semantic properties or an open record. Decorator implementations convert
  TypeSpec object/array values into immutable plain `definition.ts` values and
  retain them in program state.

  No call class, state, outcome, allowed error, coordinate, matrix ID, stable
  identity, or wire identity may be inferred from a source declaration name,
  declaration order, or missing field.

- [x] **Step 4: Run Task 1 regressions and Task 2 checks**

  Run:

  ```sh
  nix develop --command pnpm format:check
  nix develop --command pnpm typecheck
  nix develop --command pnpm test --run test/library.test.ts test/definition.test.ts
  nix develop --command pnpm exec tsp compile fixtures/valid/packet-e-slice/main.tsp --no-emit
  ```

  Expected: all commands exit zero with no unexpected diagnostics.

- [x] **Step 5: Commit**

  Stage only Task 2 files and commit:

  ```sh
  git commit -m "prototype: define explicit Packet E contract metadata"
  ```

### Task 3: Normalize the Vertical Slice into a Product-Owned Contract Model

**Files:**
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/model.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/lower.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/validate.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/lowering.test.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/fixtures/valid/packet-e-slice/main.tsp`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/fixtures/invalid/missing-matrix-cell/main.tsp`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/fixtures/invalid/wildcard-matrix-cell/main.tsp`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/fixtures/invalid/extra-error-variant/main.tsp`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/fixtures/invalid/contradictory-outcome/main.tsp`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/fixtures/invalid/missing-recovery-coordinate/main.tsp`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/fixtures/invalid/observed-and-accepted/main.tsp`

**Interfaces:**
- Consumes: accessor results and explicit metadata values from Tasks 1–2.
- Produces:

  ```ts
  export function lowerContract(program: Program): ContractModel;
  export function validateContract(model: ContractModel): readonly ContractDiagnostic[];
  export type MatrixCell =
    | { kind: "transition"; nextStateId: StableId }
    | { kind: "replay" }
    | { kind: "reject"; requestErrorId: StableId }
    | { kind: "noop" };
  ```

- [x] **Step 1: Write failing normalization and mutation tests**

  The valid case must normalize the four methods and the exact closed state sets from Global Constraints. Assert literal operation IDs, call classes, exact per-method error subsets, and matrix-cell counts.

  Each invalid fixture must produce exactly one primary diagnostic:

  | Fixture | Diagnostic |
  |---|---|
  | `missing-matrix-cell` | `contract/incomplete-matrix` |
  | `wildcard-matrix-cell` | `contract/wildcard-cell-forbidden` |
  | `extra-error-variant` | `contract/inadmissible-error` |
  | `contradictory-outcome` | `contract/contradictory-outcome` |
  | `missing-recovery-coordinate` | `contract/missing-recovery-coordinate` |
  | `observed-and-accepted` | `contract/conflicting-result-branch` |

  Every diagnostic assertion must check its source target, not only its code.

- [x] **Step 2: Run the focused tests and verify RED**

  Run:

  ```sh
  nix develop --command pnpm test --run test/lowering.test.ts
  ```

  Expected: failures identify missing lowering and validation behavior.

- [x] **Step 3: Implement closed model types and normalization**

  Define `ContractModel` as a deeply readonly closed object containing:

  ```ts
  {
    contractModelVersion: "0.1.0";
    contractId: "packet-e-vertical-slice";
    semanticProfile: "packet-e-contract-prototype";
    terminalStateIds: readonly StableId[];
    closedSums: readonly ClosedSum[];
    operations: readonly OperationContract[];
    matrices: readonly TotalMatrix[];
  }
  ```

  `closedSums` is the sole serialized authority for every state, registry
  variant, stable ID, and wire tag. Do not serialize convenience projections
  such as `states`, `registries`, or `wireIdentities`; those can diverge while
  remaining individually well-typed. Expose deterministic, non-serialized query
  functions:

  ```ts
  export function closedSum(model: ContractModel, id: StableId): ClosedSum;
  export function wireIdentities(
    model: ContractModel,
  ): readonly WireIdentity[];
  ```

  Normalize inherited/template-expanded TypeSpec entities into plain values. Retain no TypeSpec object, node, symbol, or absolute path. Sort every unordered collection by fully qualified stable ID.

- [x] **Step 4: Implement exact semantic validators**

  Exact matrix validation must compare two sets:

  ```ts
  const required = cartesian(rowIds, columnIds);
  const actual = new Set(cells.map(({ rowId, columnId }) => `${rowId}\0${columnId}`));
  requireExactSet(required, actual, "contract/incomplete-matrix", "contract/extra-matrix-cell");
  ```

  There must be no wildcard variant in `MatrixCell`; wildcard syntax is rejected
  before construction. Reject duplicate matrix cells and duplicate row/column
  axes before set comparison. Validate exact method contracts for the selected
  profile, accepted-versus-observed exclusivity, transition target reachability,
  terminal-state immutability (including terminal Operation `unknown`), explicit
  recovery coordinates, and wire-tag uniqueness within each closed sum.

  The validated model is also a canonical normal form. Reject reordered or
  duplicated semantically unordered collections—including matrix axes/cells,
  result branches, recovery coordinates, and matrix references—before bundle
  construction. Validate the runtime model/version/profile discriminants before
  any graph rule. This prevents untyped or deserialized callers from producing
  multiple semantic digests for the same contract.

- [x] **Step 5: Run focused and complete TypeSpec tests**

  Run:

  ```sh
  nix develop --command pnpm test --run test/library.test.ts test/lowering.test.ts
  nix develop --command pnpm typecheck
  ```

  Expected: all tests and typechecking pass with no warnings.

- [x] **Step 6: Commit**

  Stage only Task 3 files and commit:

  ```sh
  git commit -m "prototype: lower Packet E slice into a closed contract model"
  ```

### Task 4: Canonical Contract Bundle, Semantic Digest, and Source Map

**Files:**
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/canonical.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/emitter.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/canonical.test.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/emitter.test.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/golden/contract-model.json`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/golden/contract-bundle.json`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/golden/source-map.json`

**Interfaces:**
- Consumes: `ContractModel` from Task 3.
- Produces:

  ```ts
  export function canonicalizeSemanticJson(value: SemanticJson): Uint8Array;
  export function semanticDigest(model: ContractModel): string;
  export function buildContractBundle(model: ContractModel): ContractBundle;
  export function buildSourceMap(program: Program, model: ContractModel): ContractSourceMap;
  export async function $onEmit(context: EmitContext<EmitterOptions>): Promise<void>;
  ```

- [x] **Step 1: Write failing canonicalization and determinism tests**

  Tests must prove:

  - object key and declaration reordering yield identical bytes and digest;
  - array order changes only when the array is semantically ordered;
  - the semantic domain rejects JavaScript numbers, `undefined`, non-plain objects, and host paths;
  - changing a stable ID, wire tag, matrix outcome, or allowed error changes the digest;
  - changing source file location or line/column changes only `SourceMap`;
  - two fresh compiler processes produce byte-identical model and bundle files.

- [x] **Step 2: Run focused tests and verify RED**

  Run:

  ```sh
  nix develop --command pnpm test --run test/canonical.test.ts test/emitter.test.ts
  ```

  Expected: failures identify the absent canonicalizer/emitter.

- [x] **Step 3: Implement the restricted RFC 8785-compatible canonicalizer**

  Recursively emit `null`, booleans, strings, arrays, and plain objects. Sort object keys by UTF-16 code unit order. Reject all numeric JavaScript values; semantically relevant integers are already canonical decimal strings. Encode UTF-8 without a byte-order mark or trailing newline before hashing.

  `ContractBundle` contains the complete model, `digestAlgorithm: "sha256"`, and `semanticDigest`. The digest input is exactly the canonical bytes of the model. The source map uses source-root-relative POSIX paths and is never embedded in the bundle.

- [x] **Step 4: Emit and compare goldens**

  Run:

  ```sh
  nix develop --command pnpm build
  nix develop --command pnpm emit -- fixtures/valid/packet-e-slice
  nix develop --command pnpm test --run test/canonical.test.ts test/emitter.test.ts
  ```

  Expected: generated files match committed goldens byte-for-byte.

- [x] **Step 5: Commit**

  Stage only Task 4 files and commit:

  ```sh
  git commit -m "prototype: emit canonical contract bundle and source map"
  ```

### Task 5: Generate Language and Transport Boundaries from Contract Model Only

**Files:**
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/common.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/rust.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/go.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/typescript.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/python.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/protobuf.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/openapi.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/generation.test.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/fixtures/outcomes/*.json`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/golden/generated/**`

**Interfaces:**
- Consumes only `Readonly<ContractModel>`.
- Produces `readonly GeneratedFile[]`, where:

  ```ts
  type GeneratedFile = {
    relativePath: string;
    bytes: Uint8Array;
  };
  ```

  The driver rejects absolute paths, `..`, duplicate paths, and nondeterministic duplicate content.

- [x] **Step 1: Write failing generation tests**

  Assert that:

  - Rust uses closed enums and private validated constructors;
  - Go uses package-marked interfaces plus mandatory exact-concrete-type
    decode/validate/inspect functions. Exported Go interfaces are not a strong
    sealing boundary because external code can embed them and inherit
    unexported methods; no semantic accessor or service result is trusted
    before exact runtime validation;
  - TypeScript uses discriminated unions plus runtime decoders;
  - Python uses dataclasses/type aliases plus mandatory runtime validation;
  - each language exposes exact per-method request/recovery/error unions;
  - `WaitOperation` cannot construct an accepted mutation branch;
  - `StartSandbox` cannot construct `SequenceOutOfRange`;
  - Protobuf emits explicit field numbers and reservations from wire identities;
  - OpenAPI uses discriminators and never becomes the semantic digest input;
  - output paths are safe and unique.

- [x] **Step 2: Run generation tests and verify RED**

  Run:

  ```sh
  nix develop --command pnpm test --run test/generation.test.ts
  ```

  Expected: failures identify absent generators.

- [x] **Step 3: Implement minimal generators**

  Emit types, validators/decoders, service interfaces, and exhaustive handler skeletons only. Do not generate backend effects or claim provider conformance. All names and variants derive from stable model identities through one shared deterministic naming module.

  Generate one positive and one negative runtime outcome fixture per method. The same fixture corpus must be consumed by every generated language validator.

  The Packet E slice does not yet contain concrete request or payload fields.
  Therefore this prototype may generate only opaque schema-stable-ID carriers
  and exact closed envelopes; it must not invent request/result fields or
  claim complete payload validation. Known-failure and ambiguity subsets are
  generated as terminal-operation marker types, not as immediate invocation
  branches.

  Protobuf reservations in this prototype mean excluded, currently known tags
  in method-specific projections. Historical removed tags/names require an
  explicit reservation ledger in `ContractModel` and are not proven here.

- [x] **Step 4: Compile and execute generated boundaries**

  Run generated checks from a fresh directory:

  ```sh
  rustc --edition 2024 generated/rust/lib.rs --crate-type lib
  go test ./generated/go/...
  pnpm exec tsc --noEmit --project generated/typescript/tsconfig.json
  python3 -m unittest discover generated/python
  nix develop --command protoc --proto_path=generated/protobuf --descriptor_set_out=/tmp/packet-e-contract.pb generated/protobuf/contract.proto
  ```

  Expected: every command exits zero. Then execute—not merely compile—the
  generated Rust, Go, TypeScript, and Python validators against the identical
  shared fixture bytes and prove all four reject each invalid fixture with the
  same stable diagnostic category.

- [x] **Step 5: Commit**

  Stage only Task 5 files and commit:

  ```sh
  git commit -m "prototype: generate closed multi-language contract boundaries"
  ```

### Task 6: Independent CUE Oracle and Quint Reference Model

**Files:**
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/cue.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/src/generate/quint.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/formal.test.ts`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/handwritten/machine.qnt`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/handwritten/invariants.qnt`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/handwritten/adversarial-outcomes.json`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/golden/generated/cue/contract.cue`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test/golden/generated/quint/contract.qnt`

**Interfaces:**
- The CUE and Quint generators consume only `Readonly<ContractModel>`.
- CUE owns the independently executable structural and relational projection.
- Generated Quint owns only contract vocabulary present in `ContractModel`: closed
  universes, operation constants, terminal-state constants, and matrix constants.
- The handwritten `machine.qnt` owns the explicit Packet E temporal/effect reference
  semantics that the current Contract Source and `ContractModel` do not encode.
- The separately handwritten `invariants.qnt` owns the correctness properties.
- No generator may infer temporal behavior from `semanticProfile` or hard-code an
  invisible profile switch. A future generated machine requires the missing
  temporal/effect semantics to become explicit source/model fields or an explicit,
  versioned, digested profile input.

- [x] **Step 1: Write failing independent-oracle tests**

  Tests must mutate the generated bundle independently of Contract Source:

  - delete a matrix cell;
  - add a wildcard or undeclared matrix coordinate;
  - duplicate a matrix coordinate;
  - add an inadmissible error;
  - duplicate a wire tag;
  - change `WaitOperation` into an accepted mutation;

  CUE must reject each structural/relational mutation with its intended diagnostic,
  not merely any error. Missing matrix cells are TypeScript/CUE compilation
  failures, not a synthetic Quint runtime property.

  Add one type-correct Quint mutant for each lifecycle/effect property:

  - rejected request creates a handle or dispatches;
  - dispatch occurs before durable intent;
  - equal replay returns a different handle;
  - conflicting replay dispatches another effect;
  - stale epoch acquires current authority;
  - success is committed without the exact postcondition;
  - failure or cancellation is committed while authority may still act;
  - a blind successor is dispatched after terminal Operation `unknown`;
  - a terminal result is rewritten;
  - wait timeout mutates the resource;
  - provider acknowledgement alone establishes success.

  For every Quint mutant, first require `quint typecheck` to pass, then require a
  counterexample for the specifically assigned invariant. This prevents malformed
  mutants and unrelated failures from masquerading as oracle coverage.

- [x] **Step 2: Run focused formal tests and verify RED**

  Run:

  ```sh
  nix develop --command pnpm test --run test/formal.test.ts
  ```

  Expected: failures show the missing CUE and Quint generators.

- [x] **Step 3: Implement the CUE projection, Quint vocabulary, and reference machine**

  The handwritten reference machine must represent at least:

  - request outcome, durable handle, returned handle, and replay class;
  - durable-intent state, dispatch count, and the prior-event snapshot;
  - current epoch, actor epoch, authority ownership, effect certainty, and
    possibly-acting authority;
  - provider acknowledgement and exact postcondition evidence as distinct facts;
  - public Operation state, terminal snapshot/commit state, resource revision,
    prior resource revision, last event, and blind-successor dispatch state.

  It must expose type-correct actions for rejection, accepting/persisting intent,
  dispatch, equal/conflicting replay, epoch advancement, authority acquisition,
  provider acknowledgement, exact-success evidence, known-failure/quiescence
  evidence, each terminal commit, wait timeout, and safe observation/reconciliation.

  Internal ambiguity and committing terminal Operation `unknown` are separate
  moments. Once published, Operation `unknown` is immutable; later reconciliation
  cannot rewrite that Operation and any cleanup work requires separate identity.

  Keep all correctness properties in `invariants.qnt`, separate from both generated
  vocabulary and handwritten transitions, so no component defines its own oracle.

- [x] **Step 4: Run real CUE and Quint tools**

  Run:

  ```sh
  nix develop --command cue vet \
    -E -c -d '#ContractBundle' \
    test/golden/generated/cue/contract.cue \
    test/golden/contract-bundle.json

  nix develop --command quint typecheck \
    test/handwritten/invariants.qnt

  nix develop --command quint run \
    test/handwritten/invariants.qnt \
    --main=PacketEInvariants \
    --init=init \
    --step=step \
    --invariant=allInvariants \
    --max-samples=10000 \
    --max-steps=20 \
    --n-threads=1 \
    --seed=0x5061636b \
    --backend=rust \
    --verbosity=1

  nix develop --command quint verify \
    test/handwritten/invariants.qnt \
    --main=PacketEInvariants \
    --init=init \
    --step=step \
    --invariant=allInvariants \
    --max-steps=8 \
    --backend=apalache \
    --verbosity=1
  ```

  Quint imports must omit the `.qnt` suffix. The CUE `-d '#ContractBundle'`
  selection is mandatory so a hidden definition cannot pass vacuously at the root.
  Typecheck the handwritten invariant entrypoint, not only generated vocabulary.

  Expected: the valid bundle passes; every adversarial mutation is rejected by its
  assigned independent oracle. `quint run` provides reproducible randomized traces;
  it is not exhaustive. `quint verify` is the bounded symbolic claim and may be
  reported only as “no violation through eight transitions,” never as an unbounded
  proof.

- [x] **Step 5: Commit**

  Stage only Task 6 files and commit:

  ```sh
  git commit -m "prototype: add independent CUE and Quint contract oracles"
  ```

### Task 7: End-to-End Harness, Mutation Campaign, and Evidence Report

**Files:**
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/test.sh`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/README.md`
- Create: `docs/greenfield/research/prototypes/packet-e-contract-compiler/RESULTS.md`
- Modify: `docs/greenfield/research/prototypes/README.md`

**Interfaces:**
- Consumes: every compiler and generator path from Tasks 1–6.
- Produces: one reproducible verification command and an evidence report separating proven behavior, limitations, and remaining design work.

- [x] **Step 1: Write the failing end-to-end harness test**

  `test.sh` must run in a clean temporary output directory and fail if any required stage is skipped. Before implementing the final harness, invoke it and observe failure because the verification ledger is absent.

- [x] **Step 2: Implement the complete verification command**

  The harness must:

  1. install only from the frozen pnpm lock through the Nix development shell;
  2. format-check and typecheck compiler sources;
  3. run all TypeSpec/compiler tests;
  4. compile the valid Contract Source;
  5. assert every invalid source fixture fails with its stable diagnostic;
  6. regenerate all outputs twice in separate directories and compare bytes;
  7. compile/typecheck and execute Rust, Go, TypeScript, and Python validators;
  8. compile Protobuf and parse OpenAPI;
  9. run CUE validation;
  10. run Quint typechecking and bounded invariant exploration;
  11. execute deleted, added, renamed, duplicated, remapped, wildcard, contradictory, stale-epoch, ambiguous-effect, and recovery-coordinate mutations;
  12. historically, confirm the predecessor daemon baseline remained unchanged;
      this external sentinel is not part of the standalone Foampit harness.

- [x] **Step 3: Write the evidence report**

  `RESULTS.md` must contain:

  - exact tool versions and pins;
  - exact commands and observed counts;
  - the semantic digest of the valid slice;
  - a mutation table naming which independent check killed each mutation;
  - generated-output compile/typecheck results;
  - TypeSpec friction and source-diagnostic quality;
  - generator code size and duplicated semantic logic;
  - explicit confirmation that no emitter consumed TypeSpec objects after lowering;
  - explicit limitations: this is not Packet E inventory closure, backend conformance, runtime implementation, unbounded formal proof, or a final public syntax commitment;
  - recommendation to accept, revise, or reject the architecture based on evidence.

- [x] **Step 4: Run the complete harness twice**

  Run:

  ```sh
  ./test.sh
  ./test.sh
  ```

  Expected: both runs exit zero, report identical semantic digests, and leave no generated or dependency files outside ignored/cache locations.

- [x] **Step 5: Run the predecessor baseline before extraction**

  The predecessor repository's 28-test daemon baseline passed before
  extraction. Foampit does not contain or resolve that daemon. The current
  standalone regression instead copies the compiler prototype without its
  ancestor repository and verifies `./test.sh --preflight` remains
  self-contained.

- [x] **Step 6: Commit**

  Stage only Task 7 files and commit:

  ```sh
  git commit -m "docs: record contract compiler prototype evidence"
  ```

## Plan Self-Review

- **Spec coverage:** Tasks 1–2 exercise the strict TypeSpec frontend and explicit source metadata. Tasks 3–4 exercise the product-owned normalized model, canonical bundle, source map, exact-set validation, and deterministic identity. Task 5 covers four language boundaries plus Protobuf/OpenAPI projections. Task 6 supplies independent CUE and formal checks. Task 7 performs cross-output and mutation verification while preserving the explicit research-only scope.
- **Known deliberate reduction:** The slice covers four representative methods rather than the unfinished complete Packet E method inventory. This reduction is visible in the source, model version, README, results, and every completion claim.
- **Type consistency:** All downstream generators accept only `Readonly<ContractModel>` and return `readonly GeneratedFile[]`. Stable identifiers are strings; wire tags and semantic integers are canonical decimal strings. `ContractBundle` hashes only `ContractModel`; `SourceMap` is separate.
- **Placeholder scan:** No task contains `TBD`, deferred implementation placeholders, or an unspecified “write tests” step. Each negative fixture, diagnostic, output family, and verification command is named.
