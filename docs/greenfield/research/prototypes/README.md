# Configuration-Language Prototypes

These are disposable research implementations for
[`CONFIGURATION-LANGUAGE-CORPUS.md`](../CONFIGURATION-LANGUAGE-CORPUS.md).
They are not the product implementation and do not establish public names,
syntax, schemas, profiles, or compatibility guarantees.

## Packet E contract compiler

Status: **evaluated — recommendation: revise**

The [Foampit Packet E contract-compiler vertical slice](./packet-e-contract-compiler/)
tests whether strict TypeSpec source can lower into one product-owned canonical
model and deterministically generate closed language, transport, validation,
and formal boundaries.

Measured scope:

- four representative operations;
- 14 closed sums and 34 variants;
- one total 4 × 4 matrix;
- 16 generated files across eight target families;
- 163 passing compiler/generator/formal tests;
- 20 CUE mutations and 11 Quint mutant/invariant pairs; and
- semantic digest
  `a923de9df33371ac97b77afe63566eba0e75a0bdf82778608c33f4fd6c6cd7f4`.

The evidence supports the normalized `ContractModel` architecture, but the
prototype requires revision before broader adoption. It does not close Packet
E, Gate 2A, or Gate 4B; prove backend/runtime conformance; implement the
runtime; provide an unbounded formal proof; or commit Foampit to TypeSpec as
final public syntax.

- [Prototype guide](./packet-e-contract-compiler/README.md)
- [Measured results and recommendation](./packet-e-contract-compiler/RESULTS.md)
- [Implementation plan](../../plans/2026-07-27-packet-e-contract-compiler-prototype.md)

The standalone Foampit harness contains 21 product-owned stages. Its
predecessor-daemon regression sentinel is retained only as historical
provenance in the results report.

Every complete candidate slice must:

- use the same semantic cases and canonicalizer;
- preserve the locked configuration owners;
- capture exact native diagnostics before adapting them;
- reference real Nix values without emitting arbitrary textual Nix;
- remain removable after the language ADR.

The strengthened Nix baseline is implemented first so alternatives are compared
against the best credible one-language design rather than unrestricted
attribute sets or a permissive module graph.

The first executable checkpoint and its limitations are recorded in
[`PROTOTYPE-NOTES.md`](./PROTOTYPE-NOTES.md).

The shared [`wire-validator/`](./wire-validator/) prototype is not another
authoring candidate. It is the provisional language-neutral trust boundary
through which every serious candidate must pass before Nix construction.

Packet D's corrected candidate adds six shared boundary witness groups:

- [`frontend-adaptation-test.sh`](./frontend-adaptation-test.sh) proves the
  disposable renderer adapter fails closed instead of projecting unknown
  semantic fields away;
- [`native-handles-test.sh`](./native-handles-test.sh) starts with W0-validated
  output and checks the native source/registry/interface/system/member/effect
  identity tuple before Nix construction; and
- the wire-validator suite includes duplicate, trailing, invalid UTF-8,
  interoperable-number, Unicode-domain, nesting-depth, and byte-size cases; and
- [`nix-resource-composition/`](./nix-resource-composition/) exercises the
  distinct `P1 -> OC0/O0` Operator Configuration and
  `P1 -> MS0/S0` Managed-Service Definition branches with 14 cases and 172
  internal assertions; and
- [`resolved-reentry/`](./resolved-reentry/) treats
  `RW0 -> C0/O0/H0/D0` as wholly untrusted, replays the exact 89 built-load
  and 30 resolved-stage arrays, constructs fresh private stages, proves
  direct/raw driver entry has no admitted value, and validates generated
  backend configuration as D0 output; and
- [`downstream-boundaries/`](./downstream-boundaries/) exercises deterministic
  migration, strict built-manifest loading, and total generated-driver output
  validation, including corrupted identity, foreign-field, retained-source,
  raw-argument, and policy-widening attempts.

The native-handle identity tuple is exactly `sourceGraphClosureDigest`,
`registryNamespace`, `registryVersion`, separate `registryDigest`,
`exportAttribute`, `nativeInterfaceVersion`, `targetSystem`,
`affectedMember`, and `expectedSemanticProjection`;
`semanticIdentityComparison` is required before construction.
`registryDigest` is distinct from `sourceGraphClosureDigest`.

The six machine handoffs resume at the `manifest-load` C0 boundary of
`built-artifact-load`: `prebuilt-member-transfer` and
`oci-descriptor-transfer` end at H0; `provider-cache-hit` ends at D0; and
`provider-side-construction`, `provider-build-cache`, and
`corrupted-provider-build-result` end at N1. Each is a
`separate-path-handoff`, never a phase edge or authority to skip manifest
loading.

These are prototype witnesses, not claims that the future production wire,
attestation, migration, or private stage-type implementation is closed.

The current machine inventory is 54 paths × 140 invariants = 7,560 unique
cells in 634 complete-contract groups. Fresh suite totals are 31 strengthened
Nix assertions; 14 resource-composition cases/172 internal assertions; 16
CUE; 19 Nickel; 18 Pkl; 12 Dhall-control; 10 native-handle; 18 frontend
adaptation; 27 wire; 13 resolved-reentry cases with 18 diagnostic, 8 identity,
and 44 projection probes; and 40 downstream-boundary cases. The final
pipeline-equivalence check is also green.

Packet D status is: **Candidate complete — corrected matrix and prototypes
green; independent cold-reader and adversarial sign-off pending**. These
disposable witnesses do not close Gate 4B: all production hooks/tests remain
planned, and teardown semantics remain delegated to Packet E.

## Invariant gates

The full prototype suite begins by running the structural and exact-corpus
checks from the
[Invariant Inventory and Enforcement Protocol](../INVARIANT-ENFORCEMENT.md):

```sh
./test-all.sh
```

The same inventory check can be run directly:

```sh
../invariants/check-inventory.sh
```

That command proves registry structure and exact coverage; it does not close
Gate 2A's human state-space review.

Gate 4B has a separate intentionally strict command:

```sh
../invariants/check-enforcement-closure.sh
```

It must fail while any v1 invariant is still `specified`, any hook/test is
planned, or any concrete reverse reference is absent. It becomes mandatory
before blind transcript review and scoring, not before early prototype work.
