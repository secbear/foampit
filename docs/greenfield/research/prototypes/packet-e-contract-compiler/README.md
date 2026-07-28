# Foampit Packet E contract compiler prototype

Status: **research vertical slice — architecture recommendation: revise**

This prototype tests one narrow architectural hypothesis: a strict TypeSpec
source can lower once into a product-owned, canonical `ContractModel`, and
language, transport, validation, and formal artifacts can then be generated
from that model without giving downstream generators access to TypeSpec
compiler objects.

The measured evidence and recommendation are in [RESULTS.md](./RESULTS.md).
The implementation follows the
[vertical-slice plan](../../../plans/2026-07-27-packet-e-contract-compiler-prototype.md).

## What the slice contains

The selected `packet-e-contract-prototype` profile contains:

- four representative operations: `StartSandbox`, `CancelOperation`,
  `WriteProcessInput`, and `WaitOperation`;
- 14 closed state/registry sums containing 34 explicitly tagged variants;
- one total 4 × 4 Sandbox-state/operation matrix with 16 explicit cells;
- five terminal state IDs;
- a canonical JSON `ContractModel`, a digest-bearing `ContractBundle`, and a
  non-semantic source map; and
- 16 generated files across CUE, Go, OpenAPI, Protobuf, Python, Quint, Rust,
  and TypeScript.

The source is
[fixtures/valid/packet-e-slice/main.tsp](./fixtures/valid/packet-e-slice/main.tsp).
The normalized shape is defined in [src/model.ts](./src/model.ts), lowering is
implemented in [src/lower.ts](./src/lower.ts), and the composed generator
entrypoint is [src/generate/index.ts](./src/generate/index.ts).

## Architecture under test

```text
TypeSpec Program
    │
    ├── lowerContract(program)
    ▼
validated, canonical ContractModel
    │
    ├── canonical ContractBundle + semantic digest
    ├── Rust / Go / TypeScript / Python boundaries
    ├── Protobuf / OpenAPI projections
    └── CUE / Quint formal artifacts
```

Every semantic, language, transport, and formal generator accepts only
`Readonly<ContractModel>`. No file under `src/generate/` imports
`@typespec/compiler`.

There is one intentional non-semantic exception to the diagram:
[src/lower.ts](./src/lower.ts) retains TypeSpec `Type` objects in a `WeakMap`
for source targets, and [src/emitter.ts](./src/emitter.ts) combines those
targets with the TypeSpec `Program` to emit relative-path source provenance.
That source map is not an input to generators and is excluded from the
semantic digest. The defensible boundary is therefore “no semantic generator
consumes TypeSpec objects,” not “nothing touches TypeSpec after
`lowerContract` returns.”

## Reproduce

Run the complete pinned harness from this directory:

```sh
./test.sh
```

The development shell is locked by [flake.lock](./flake.lock), and JavaScript
dependencies are locked by [pnpm-lock.yaml](./pnpm-lock.yaml). Component
checks can also be run directly:

```sh
nix develop --command pnpm install --frozen-lockfile
nix develop --command pnpm format:check
nix develop --command pnpm typecheck
nix develop --command pnpm test --run
nix develop --command pnpm golden:check
```

Committed generated artifacts live under
[test/golden/generated/](./test/golden/generated/). They are checked by exact
path and byte, including equality across repeated generation and a source
fixture with reordered declarations.

## Generated boundaries

| Family | Files | Executable evidence |
|---|---:|---|
| CUE | 1 | `cue vet -E -c -d '#ContractBundle'` accepts the bundle and rejects assigned structural and relational mutants |
| Go | 3 | generated code compiles and its validators execute against the shared outcome bytes |
| OpenAPI | 1 | JSON parses as a closed OpenAPI 3.1 projection with exact discriminators |
| Protobuf | 1 | `protoc` produces a non-empty descriptor set |
| Python | 3 | `unittest` and the generated runtime decoder execute against the shared outcome bytes |
| Quint | 1 | vocabulary composes with the independent machine/invariants and passes bounded checks |
| Rust | 2 | generated code compiles and its validator executes against the shared outcome bytes |
| TypeScript | 4 | `tsc` checks static exclusions and Node executes strict decoders against the shared outcome bytes |

## Reading the prototype

- [lib/main.tsp](./lib/main.tsp) defines the strict TypeSpec decorator/value
  vocabulary.
- [src/definition.ts](./src/definition.ts) converts TypeSpec value metadata
  into ordinary immutable values.
- [src/validate.ts](./src/validate.ts) owns selected-profile and normalized
  model validation.
- [src/canonical.ts](./src/canonical.ts) canonicalizes the restricted semantic
  JSON domain and computes its SHA-256 digest.
- [test/handwritten/adversarial-outcomes.json](./test/handwritten/adversarial-outcomes.json)
  is the exact CUE/Quint mutation-ownership ledger.
- [test/formal.test.ts](./test/formal.test.ts) checks ledger completeness,
  generated formal artifacts, and direct CUE/Quint CLI composition.

## Scope and limitations

This prototype is evidence about a compiler architecture. It is explicitly
not:

- Packet E inventory or enforcement closure, and it does not close Gate 2A or
  Gate 4B;
- the complete Packet E method, operation-pair, registry, retention,
  writer-lease, Snapshot, or lifecycle contract;
- backend or runtime conformance evidence;
- a runtime implementation;
- an unbounded formal proof—Quint exploration is reproducible but bounded; or
- a commitment to TypeSpec or this source vocabulary as final public syntax.

The flake currently selects `aarch64-darwin`; portability of the evaluation
shell itself was not established. Protobuf exclusions describe the current
slice and do not prove historical wire compatibility.

See [RESULTS.md](./RESULTS.md) for the observed evidence, friction, remaining
semantic duplication, and the reasons for the **revise** recommendation.
