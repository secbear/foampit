# Packet E contract compiler prototype results

Observation window: **2026-07-27–2026-07-28**

Recommendation: **REVISE**

The prototype supports the core architecture: one validated, canonical
`ContractModel` can drive deterministic language, transport, and formal
generation. It does not yet support accepting the implementation as a
candidate product compiler. Semantic validation is not fully integrated into
TypeSpec's diagnostic lifecycle, and target generators still contain
measurable fixed semantic literals.

## Standalone Foampit extraction

On 2026-07-28, the prototype was extracted into the standalone Foampit
repository. The predecessor-daemon regression sentinel was removed because it
tested code outside the product boundary. The harness now manifests only the
contract compiler's inputs and completes 21 product-owned stages.

The extracted harness was observed directly with:

```sh
./test.sh
```

| Evidence | Observed result |
|---|---|
| Complete pinned harness | Exit 0; 21 of 21 product-owned stages completed |
| Complete unit/integration suite | 14 test files, 163 tests passed |
| Canonical generated inventory | 16 files |
| Invalid source fixtures | 7 fixtures assigned stable diagnostics and source targets |
| CUE mutation ownership | 20 named mutations mapped exactly to their rejecting constraint/field |
| Quint mutation ownership | 11 named mutant actions mapped one-to-one to 11 invariants |
| Semantic digest | `a923de9df33371ac97b77afe63566eba0e75a0bdf82778608c33f4fd6c6cd7f4` |
| Compiler-only source manifest | `8a9b2a28f004f053db07a235c9e0092a8e48a4b341d915f801ae3a95dab0a424` |

The repository-level
[`tests/standalone-contract-compiler.sh`](../../../../../tests/standalone-contract-compiler.sh)
also copies only the prototype into a temporary directory, runs its preflight,
proves an unrelated ancestor `daemon/` cannot affect its source manifest, and
proves a compiler-input mutation does affect that manifest.

## Original preserved evidence

The remainder of this report records the two exclusive runs made in the
predecessor repository before extraction. Its 22nd stage was an external
regression sentinel over that repository's daemon; it was never a compiler
input or Foampit product component.

| Evidence | Observed result |
|---|---|
| Complete pinned harness | 2 exclusive runs exited 0; 22 of 22 required stages completed in each run |
| Complete unit/integration suite | 14 test files, 163 tests passed |
| Canonical generated inventory | 16 files, 6,357 lines, 221,638 bytes |
| Reordered source | Byte-identical `ContractModel` and all generated files |
| Semantic digest | `a923de9df33371ac97b77afe63566eba0e75a0bdf82778608c33f4fd6c6cd7f4` |
| Selected-input manifest | `3cc76c138663b56b849be119a10390667d2609e0d647575e59e6092712c97a01` before copy, in the copied snapshot, and after each run |
| Invalid source fixtures | 7 fixtures assigned stable diagnostics and source targets |
| CUE mutation ownership | 20 named mutations mapped exactly to their rejecting constraint/field |
| Quint mutation ownership | 11 named mutant actions mapped one-to-one to 11 invariants |
| Formal baseline | CUE bundle accepted; Quint reference run succeeded; no bounded violation through eight transitions |
| Runtime boundaries | Rust, Go, TypeScript, and Python validators compiled/typechecked and executed over the same eight fixture byte strings |
| Transport boundaries | Protobuf compiled to a descriptor; OpenAPI parsed and passed exact closed-schema assertions |
| Generator input boundary | All eight target generators accept `Readonly<ContractModel>`; none imports TypeSpec |

The result is meaningful architectural evidence, but it is deliberately
narrow. The [limitations](#limitations) are part of the result.

## Evaluated slice

The canonical model contains:

| Model element | Count |
|---|---:|
| Closed sums | 14 |
| Closed variants | 34 |
| Operations | 4 |
| Matrices | 1 |
| Matrix rows | 4 |
| Matrix columns | 4 |
| Matrix cells | 16 |
| Terminal state IDs | 5 |

The four operations cover one example of each selected call class:

| Operation | Call class | Success shape |
|---|---|---|
| `StartSandbox` | durable Operation mutation | accepted/recovery/rejected |
| `CancelOperation` | existing-handle intent | accepted/recovery/rejected |
| `WriteProcessInput` | sequenced Process control | accepted/recovery/rejected |
| `WaitOperation` | observation | observed/rejected |

This is a representative vertical slice, not an exhaustive Packet E method
inventory.

## Toolchain and pins

The Nix input is locked to Nixpkgs revision
`624af665418d3c65d544145b4d34ad696439570e`, with nar hash
`sha256-m0pDuRJG7EDo9ri+4Ksu83VsI+PlxNC9lNBfydejce4=`.

| Tool | Observed version | Pin |
|---|---|---|
| Node.js | `v22.23.1` | Nixpkgs revision |
| pnpm | `10.34.5` | Nixpkgs revision and `packageManager` |
| TypeSpec | `1.14.0` | exact peer/dev dependency and lockfile |
| TypeScript | `6.0.3` | exact dev dependency and lockfile |
| Vitest | `4.1.9` | exact dev dependency and lockfile |
| `@types/node` | `22.20.1` | exact dev dependency and lockfile |
| CUE | language `v0.17.1`; binary reports `cue version (devel)` | Nixpkgs revision |
| Quint | `0.32.0` | Nixpkgs revision |
| Protobuf compiler | `libprotoc 35.1` | Nixpkgs revision |
| Rust | `rustc 1.97.0 (2d8144b78 2026-07-07)` | Nixpkgs revision |
| Cargo | `cargo 1.97.0 (c980f4866 2026-06-30)` | Nixpkgs revision |
| Go | `go1.26.5 darwin/arm64` | Nixpkgs revision |
| Python | `3.13.14` | Nixpkgs revision |

Version evidence was collected with:

```sh
nix develop --command node --version
nix develop --command pnpm --version
nix develop --command pnpm exec tsp --version
nix develop --command pnpm exec tsc --version
nix develop --command pnpm exec vitest --version
nix develop --command cue version
nix develop --command quint --version
nix develop --command protoc --version
nix develop --command rustc --version
nix develop --command cargo --version
nix develop --command go version
nix develop --command python3 --version
```

## Component command evidence

The following commands were observed directly:

| Command | Result |
|---|---|
| `nix develop --command pnpm format:check` | exit 0; TypeSpec reported 2 formatted inputs and 8 ignored inputs |
| `nix develop --command pnpm typecheck` | exit 0 |
| `nix develop --command pnpm test --run` | exit 0; 14 files and 163 tests passed in 75.13 s |
| `nix develop --command pnpm golden:check` | exit 0; `generated goldens match (16 files)` |
| `nix develop --command pnpm exec tsp compile fixtures/valid/packet-e-slice/main.tsp --no-emit` | exit 0; compilation completed successfully |
| `nix develop --command pnpm vitest run test/lowering.test.ts test/cue-oracle.test.ts test/formal.test.ts` | exit 0; 3 files and 41 tests passed in 2.44 s |

## Original end-to-end harness evidence

The completed harness was run twice, serially and without edits between runs:

```sh
./test.sh
./test.sh
```

| Observation | Run 1 | Run 2 |
|---|---:|---:|
| Exit status | 0 | 0 |
| Wall time | 108.87 s | 106.43 s |
| Compiler report | 14/14 files, 163/163 tests | 14/14 files, 163/163 tests |
| Required stage ledger | 22/22 | 22/22 |
| Legacy daemon baseline | 28/28 tests across 3 targets | 28/28 tests across 3 targets |
| Semantic digest | `a923de9df33371ac97b77afe63566eba0e75a0bdf82778608c33f4fd6c6cd7f4` | `a923de9df33371ac97b77afe63566eba0e75a0bdf82778608c33f4fd6c6cd7f4` |
| Selected-input manifest | `3cc76c138663b56b849be119a10390667d2609e0d647575e59e6092712c97a01` | `3cc76c138663b56b849be119a10390667d2609e0d647575e59e6092712c97a01` |

Each run ended with:

```text
HARNESS_SEMANTIC_DIGEST: a923de9df33371ac97b77afe63566eba0e75a0bdf82778608c33f4fd6c6cd7f4
HARNESS_SOURCE_MANIFEST: 3cc76c138663b56b849be119a10390667d2609e0d647575e59e6092712c97a01
HARNESS_GREEN: 22/22 required stages completed
```

The original harness verified no selected compiler/daemon input content-or-mode
manifest delta, and a separate post-run `git status --short` audit found no
status change. It copied those selected inputs into an isolated work tree and
proved that the copy matched the pre-run manifest before executing tests.
Post-run audits found no held lock, work-directory residue, or remaining
harness, Quint, or Apalache process. The intentionally persistent per-user
coordination lock file remained and was immediately reacquirable after both
runs.

The original harness therefore exercised exact Nix-store tool provenance and versions,
frozen dependency installation, supervisor cleanup of an exited leader with a
TERM-ignoring descendant, formatting and typechecking, all compiler/formal
tests, both valid TypeSpec sources, seven invalid diagnostics, two independent
generation roots and their byte comparison, every generated boundary, both
mutation ledgers, and the exact 28-test/3-target legacy daemon baseline without
writing back into the source tree.

The digest was independently recomputed from the exact canonical model bytes:

```sh
shasum -a 256 test/golden/contract-model.json
```

Observed output:

```text
a923de9df33371ac97b77afe63566eba0e75a0bdf82778608c33f4fd6c6cd7f4  test/golden/contract-model.json
```

That value equals `semanticDigest` in
[test/golden/contract-bundle.json](./test/golden/contract-bundle.json). The
digest covers only canonical `ContractModel` bytes. It does not cover the
bundle wrapper, source text, or
[test/golden/source-map.json](./test/golden/source-map.json).

## Invalid-source diagnostics

The seven invalid fixtures have exact expected diagnostics and source targets:

| Fixture | Diagnostic | Asserted target |
|---|---|---|
| `missing-matrix-cell` | `contract/incomplete-matrix` | contract root |
| `extra-error-variant` | `contract/inadmissible-error` | `StartSandbox` |
| `contradictory-outcome` | `contract/contradictory-outcome` | `StartSandbox` |
| `missing-recovery-coordinate` | `contract/missing-recovery-coordinate` | `StartSandbox` |
| `observed-and-accepted` | `contract/conflicting-result-branch` | `WaitOperation` |
| `missing-error-result-branch` | `contract/error-result-branch-mismatch` | `WaitOperation` |
| `wildcard-matrix-cell` | `contract/wildcard-cell-forbidden` | contract root |

There is an important boundary distinction:

- bare `tsp compile --no-emit` reports
  `contract/wildcard-cell-forbidden` with a source location and exits 1;
- the other six fixtures compile successfully in bare TypeSpec because their
  graph-wide rules currently run when `lowerContract` and `validateContract`
  are called; and
- the tests assert each lowering diagnostic against the original TypeSpec
  `Type` source target, but invoking the emitter on an invalid semantic model
  reports `Emitter "contract" crashed! This is a bug.` followed by
  `ContractModelValidationError`.

The emitter observation was reproduced in an isolated temporary output
directory with:

```sh
probe_dir="$(mktemp -d)"
trap 'rm -rf -- "$probe_dir"' EXIT
nix develop --command pnpm exec tsp compile \
  --emit contract \
  fixtures/invalid/missing-matrix-cell/main.tsp \
  --output-dir "$probe_dir"
```

It exited 1 and included `contract/incomplete-matrix`, but as an emitter stack
trace rather than a normal source-targeted TypeSpec diagnostic. This is a
prototype integration defect and a reason for the **revise** recommendation.
The final implementation should report graph-wide validation through TypeSpec's
diagnostic API before emission.

## Mutation ownership

The machine-readable ownership ledger is
[test/handwritten/adversarial-outcomes.json](./test/handwritten/adversarial-outcomes.json).
[test/formal.test.ts](./test/formal.test.ts) runtime-validates its closed shape,
requires 20 CUE and 11 Quint entries, compares both directions against the
actual test/action/invariant inventories, and typechecks a Quint wrapper that
imports both the invariant and mutant modules.

### CUE mutations

| Mutation | Assigned rejecting check |
|---|---|
| deleted matrix cell | `#matrixCoordinatesComplete` |
| duplicate matrix cell | `#matrixCoordinatesUnique` |
| wildcard matrix coordinate | `#matrixCoordinatesDeclared` |
| undeclared matrix coordinate | `#matrixCoordinatesDeclared` |
| duplicate matrix axis | `#rowIdsUnique` |
| operation-inadmissible request error | `#requestErrorsAdmissible` |
| duplicate closed-sum wire tag | `#wireTagSelected` |
| WaitOperation changed to mutation | `#waitOperationObservation` |
| observation changed to an accepted branch | `#observationBranchShape` |
| transition references an undeclared state | `#matrixTransitionsResolve` |
| matrix cell has a valid but source-incorrect kind | `#matrixCellsSelected` |
| transition has a valid but source-incorrect next state | `#matrixCellsSelected` |
| reject has a valid but source-incorrect request error | `#matrixCellsSelected` |
| operation references an undeclared matrix | `#matrixReferencesResolve` |
| bundle identity changed | `bundleVersion` |
| model identity changed | `contractId` |
| undeclared model field | `field not allowed` |
| regenerated schema from an incomplete matrix | `#matrixCoordinatesComplete` |
| regenerated schema from duplicate matrix coordinates | `#matrixCoordinatesUnique` |
| regenerated schema from an extra undeclared matrix cell | `#matrixCoordinatesDeclared` |

The regenerated-schema cases demonstrate that totality, coordinate
uniqueness, and declared-coordinate membership are CUE relations over the
concrete bundle rather than facts copied from generator input.

### Quint mutations

| Mutant action | Assigned invariant |
|---|---|
| `mutantRejectedRequestCreatesEffects` | `rejectedRequestHasNoHandleOrDispatch` |
| `mutantPersistsIntentAndDispatchesAtomically` | `dispatchRequiresDurableIntent` |
| `mutantEqualReplayReturnsDifferentHandle` | `equalReplayReturnsSameHandle` |
| `mutantConflictingReplayMutatesResource` | `conflictingReplayHasNoEffect` |
| `mutantStaleEpochRetainsAuthority` | `staleEpochHasNoAuthority` |
| `mutantSuccessWithoutExactPostcondition` | `successRequiresExactPostcondition` |
| `mutantFailureWhilePossiblyActing` | `failedOrCancelledHasNoPossiblyActingAuthority` |
| `mutantUnknownDispatchesBlindSuccessor` | `terminalUnknownHasNoBlindSuccessor` |
| `mutantRewritesTerminalOperation` | `terminalOperationIsImmutable` |
| `mutantWaitTimeoutMutatesResource` | `waitTimeoutDoesNotMutateResource` |
| `mutantProviderAcknowledgementEstablishesSuccess` | `providerAcknowledgementDoesNotEstablishSuccess` |

Each Quint mutant is typechecked and produces an Apalache violation with a
non-empty trace for its assigned invariant.

## Generated boundary results

The committed output inventory is:

| Family | Files | Lines | Bytes | Observed boundary result |
|---|---:|---:|---:|---|
| CUE | 1 | 542 | 21,702 | selected `#ContractBundle` accepted; 20 assigned mutations rejected |
| Go | 3 | 1,620 | 54,118 | generated tests compile and execute validators over eight exact fixture bytes |
| OpenAPI | 1 | 1,401 | 42,367 | JSON parses; OpenAPI 3.1 discriminators, closed objects, required fields, and exclusions match |
| Protobuf | 1 | 528 | 17,783 | `protoc` emits a non-empty descriptor set; exact tags and current exclusions match |
| Python | 3 | 916 | 31,949 | `unittest` succeeds and generated runtime decoder classifies all eight exact fixture bytes |
| Quint | 1 | 116 | 11,546 | generated vocabulary typechecks with handwritten machine, invariants, and mutants |
| Rust | 2 | 640 | 20,498 | generated validator compiles and classifies all eight exact fixture bytes |
| TypeScript | 4 | 594 | 21,675 | `tsc` checks four static construction exclusions; Node decoder classifies all eight exact fixture bytes |
| **Total** | **16** | **6,357** | **221,638** | exact committed path and byte inventory |

Rust, Go, TypeScript, and Python consume the same eight unique JSON byte
strings: one valid and one invalid outcome for each selected operation. The
cross-language tests also reject duplicate JSON object keys, non-flat values,
and trailing input instead of relying on each host parser's default behavior.

The generated artifacts prove boundary construction and validation behavior.
They do not prove that a real daemon, provider, or backend implements the
contracts.

## Formal boundary results

CUE is invoked directly with:

```sh
cue vet -E -c -d '#ContractBundle' contract.cue bundle.json
```

The selected valid bundle passes. Structural, relational, source-selection,
identity, and regenerated-schema mutants fail with their assigned markers.
Changing only the semantic digest remains admissible, demonstrating that the
CUE oracle checks the contract boundary rather than recomputing a digest.

The independently authored Quint machine:

- typechecks with the generated `PacketEContract` vocabulary;
- completes a deterministic reference run with seed `0x5061636b`, 10,000
  samples, and at most 20 steps;
- returns `ok` from bounded Apalache verification through eight transitions;
  and
- kills all 11 assigned mutant actions with non-empty violation traces.

The randomized reference run is reproducible exploration. The eight-transition
Apalache result is a bounded result. Neither is an unbounded proof.

## Determinism and canonical identity

`generateAll` validates the model, composes all targets, rejects unsafe or
portable-path-colliding outputs, and sorts by portable relative path.

Tests establish:

- two generations from the same model are byte-identical;
- the reordered TypeSpec fixture lowers to the same model and all 16 generated
  files;
- committed goldens match generated paths and bytes exactly;
- generated output contains no package-root path, source fixture path, or
  timestamp-shaped value;
- the source map contains 20 entries and only the relative source path
  `fixtures/valid/packet-e-slice/main.tsp`; and
- the semantic digest is over the restricted canonical JSON model domain, not
  source order, source locations, or the bundle wrapper.

## Generator boundary and source-map exception

All generator entrypoints have the shape:

```ts
generateTarget(model: Readonly<ContractModel>): readonly GeneratedFile[]
```

The check:

```sh
rg -n 'from "@typespec/compiler"' src/generate
```

returns no matches. `generateAll` accepts a `Readonly<ContractModel>`,
revalidates it, and passes that model to Rust, Go, TypeScript, Python,
Protobuf, OpenAPI, CUE, and Quint generators.

The plan's phrase “no emitter consumed TypeSpec objects after lowering” needs a
precise qualification. No **semantic/language/transport/formal generator**
consumes them. `lower.ts` keeps source `Type` objects in a `WeakMap`, and
`emitter.ts` calls `buildSourceMap(context.program, model)` after lowering to
recover source provenance. That source-diagnostic path is an explicit
non-semantic frontend exception and is excluded from both `ContractModel` and
its digest.

## Code size and duplicated semantic logic

Generator source size was measured with `wc -l` and an `awk 'NF'` nonblank
line count:

| Generator source | Physical lines | Nonblank lines |
|---|---:|---:|
| `common.ts` | 144 | 130 |
| `cue.ts` | 452 | 418 |
| `go.ts` | 843 | 764 |
| `index.ts` | 27 | 26 |
| `openapi.ts` | 378 | 355 |
| `protobuf.ts` | 424 | 394 |
| `python.ts` | 772 | 691 |
| `quint.ts` | 269 | 259 |
| `rust.ts` | 593 | 548 |
| `typescript.ts` | 581 | 535 |
| **Total** | **4,483** | **4,120** |

Target-specific files excluding `common.ts` and `index.ts` contain 4,312
physical lines and 3,964 nonblank lines.

To quantify fixed semantic coupling, a model-driven scan collected every
dotted stable-like string from canonical `contract-model.json`, then counted
exact JSON-quoted occurrences of those values in `src/generate/*.ts`.
The model contains 61 such strings. Generator sources contain 42 literal
occurrences spanning 11 of them:

| Source | Literal occurrences | Unique model literals |
|---|---:|---:|
| `cue.ts` | 5 | 5 |
| `openapi.ts` | 9 | 6 |
| `protobuf.ts` | 12 | 6 |
| `python.ts` | 11 | 8 |
| `typescript.ts` | 5 | 4 |
| `common.ts`, `go.ts`, `index.ts`, `quint.ts`, `rust.ts` | 0 | 0 |
| **Total** | **42** | **11** |

The exact scan is reproducible from the prototype root:

```sh
node - <<'NODE'
const fs = require("fs");
const path = require("path");
const model = JSON.parse(
  fs.readFileSync("test/golden/contract-model.json", "utf8"),
);
const modelStrings = new Set();
function visit(value) {
  if (
    typeof value === "string" &&
    /^[a-z][a-z0-9]*(?:\.[a-z][a-z0-9]*)+$/.test(value)
  ) {
    modelStrings.add(value);
  } else if (Array.isArray(value)) {
    value.forEach(visit);
  } else if (value && typeof value === "object") {
    Object.values(value).forEach(visit);
  }
}
visit(model);
let total = 0;
const unique = new Set();
for (
  const file of fs
    .readdirSync("src/generate")
    .filter((name) => name.endsWith(".ts"))
    .sort()
) {
  const source = fs.readFileSync(path.join("src/generate", file), "utf8");
  let occurrences = 0;
  const fileUnique = new Set();
  for (const value of modelStrings) {
    const literal = JSON.stringify(value);
    let offset = 0;
    while ((offset = source.indexOf(literal, offset)) >= 0) {
      occurrences += 1;
      total += 1;
      unique.add(value);
      fileUnique.add(value);
      offset += literal.length;
    }
  }
  console.log(`${file}: ${occurrences} occurrences, ${fileUnique.size} unique`);
}
console.log(`total: ${total} occurrences, ${unique.size} unique`);
NODE
```

Of the 42 occurrences, 35 are registry-role lookup literals, one is the
independent WaitOperation CUE rule, and six are Python generated negative-test
fixture literals. The generated values still come from `ContractModel`; this
metric does not show that generators read TypeSpec. It does show semantic
coupling that should be revised: registry roles should be typed or derived
once, and source-specific generated test cases should be generated from
model-relative mutations rather than fixed IDs.

This is a semantic-literal metric, not a general clone detector. Target
validators necessarily repeat equivalent boundary behavior in their host
languages; this prototype did not measure generated-code clone similarity.

## TypeSpec friction and diagnostic quality

Positive findings:

- decorators attach explicit stable IDs, wire tags, operation contracts,
  recovery coordinates, and matrix cells;
- declaration reordering does not change the normalized model;
- local decorator errors such as wildcard coordinates report a stable
  `contract/` diagnostic at the source target;
- lowering retains source targets without serializing TypeSpec objects into
  the model; and
- source provenance uses relative paths and is excluded from identity.

Friction and revision work:

- the four-operation fixture is 340 lines because the source explicitly spells
  34 variant tags and all 16 matrix cells;
- six graph-wide fixture failures are not reported by bare TypeSpec
  compilation because semantic validation currently runs at lowering;
- emitter-time validation failure surfaces as an emitter crash and stack trace,
  not a normal source-targeted TypeSpec diagnostic; and
- generator role selection contains 42 fixed semantic-literal occurrences as
  quantified above.

The verbosity is partly deliberate evidence that no semantic default or
wildcard is hiding in the source. Whether a final syntax can preserve that
explicitness with less repetition remains an open design question.

## Limitations

This result is not:

1. **Packet E closure.** Four representative operations do not constitute the
   exhaustive Packet E method, operation-pair, state, registry, retention,
   writer-lease, Snapshot, lifecycle, and error inventory. Gate 2A and Gate 4B
   remain open.
2. **Backend or runtime conformance.** No jail, microVM, provider, daemon, guest
   agent, or live Process was exercised against the generated contracts.
3. **A runtime implementation.** Generated validators and service interfaces
   are boundaries, not operation orchestration, storage, reconciliation, or
   authority management.
4. **An unbounded proof.** Quint randomized exploration and eight-transition
   Apalache verification are explicitly bounded.
5. **A final syntax commitment.** TypeSpec and the prototype decorator/value
   vocabulary remain replaceable research choices.
6. **Historical wire-compatibility evidence.** Protobuf reservations express
   current exclusions; they do not prove prior schema history.
7. **Cross-platform shell evidence.** The flake currently selects
   `aarch64-darwin`.

## Recommendation: revise

Retain the architectural direction for a second spike:

- preserve the single product-owned `ContractModel`, restricted canonical JSON
  digest, exact-set validation, and ContractModel-only target generator APIs;
- preserve byte-determinism checks, shared cross-language fixture bytes, CUE
  relational oracle, and independently authored Quint machine/mutants;
- integrate lowering validation with TypeSpec's normal diagnostic reporting so
  every invalid source fails cleanly before emitter execution;
- replace fixed registry/source IDs in generators with typed model roles and
  model-derived mutation/test construction; and
- expand only after the Packet E inventory assigns complete operations,
  invariants, ownership, and conformance obligations.

Rejecting the architecture would ignore the successful deterministic and
cross-target evidence. Accepting it without revision would ignore the
diagnostic integration defect, semantic-literal coupling, narrow slice, and
absence of runtime conformance. **Revise** is the evidence-supported decision.
