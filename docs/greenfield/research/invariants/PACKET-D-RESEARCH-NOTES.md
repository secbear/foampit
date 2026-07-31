# Gate 2A Packet D Composition and Bypass Research

Status: **Candidate complete — corrected matrix and prototypes green;
independent cold-reader and adversarial sign-off pending**

Research date: **2026-07-24**

This record supports the generic `CompositionPath` review. Exact language
constructs are evidence mappings, not alternate product semantics. A source
frontend may reject earlier and preserve better locations, but a frontend
renderer, adapter, Nix bridge, lowerer, manifest loader, provider, or driver
never gains authority by successfully producing a value.

## Locked conclusions

1. The authoritative rule set is the final normalized Artifact semantic
   validator. For a serialized frontend, strict W0 decoding occurs first and
   then invokes that same A1 rule set; `A1` names conceptual semantic
   completeness, not permission to trust pre-decoded frontend output.
2. Raw canonical input, migrated input, renderer output, adapter output,
   direct Nix side-table values, built manifests, provider build results, and
   the five resolved-handoff/reentry/generated/direct/raw driver states are
   independent trust boundaries.
3. `frontend-adaptation` is distinct from `frontend-output`.
   The pre-Packet-D
   [`comparison-portable-value.jq`](../prototypes/comparison-portable-value.jq)
   projected a selected field set and could erase an unknown semantic field
   before W0. Packet D therefore registers `WIRE-005`; the prototype adapter
   now rejects unknown top-level and nested fields before projection.
4. Nix's ordinary final value is insufficient evidence for every
   composition-history rule. The frontend must preserve contribution
   metadata, and security-sensitive option families must reject winning
   override priorities stronger than their declared composition contract.
   The prototype now rejects `mkOverride (-1)` on hard policy and retains a
   valid order-independent refinement control.
5. External-frontend native handles and the Nix one-evaluation side table are
   different paths. The first transports only a typed identity; the second
   may retain a real package, derivation, dev shell, or module value beside
   the portable projection. Both must agree on the complete native identity
   tuple at N0.
6. A native handle binds the exact machine-owned
   `sourceGraphClosureDigest`, `registryNamespace`, `registryVersion`,
   `registryDigest`, `exportAttribute`, `nativeInterfaceVersion`,
   `targetSystem`, `affectedMember`, and `expectedSemanticProjection` tuple.
   `registryDigest` is distinct from `sourceGraphClosureDigest`, and
   `semanticIdentityComparison` is required before construction.
7. Registered extensions must have a complete product-derived effect
   projection into the Packet C field/profile and identity models.
   Unprojectable effects produce a distinct non-conforming result or are
   rejected; an `unsafe` boolean cannot mint conforming types or evidence.
8. Only a phase's authoritative component constructs its validated stage
   value. Bridges, lowerers, caches, adapters, manifest loaders, and drivers
   accept the prior validated type and cannot manufacture
   `BuiltMember`, `VerifiedManifest`, `ResolvedCreation`, or
   `PreparedLaunch`.
9. `provider-side-construction`, `provider-build-cache`, and
   `corrupted-provider-build-result` are Artifact-owned N0/N1
   construction/verification. Prebuilt-member and OCI-descriptor transfer are
   Operator/runtime H0 concerns; `provider-cache-hit` reaches D0. Runtime
   placement, credentials, and live/Exec operations remain Operator/runtime
   concerns at H0/L0/E0.
10. The phase model is a graph. Packet D checks reachability through the
    Artifact, create, framework, service, live, Exec, and teardown branches;
    it does not treat the phase table as one total order.
11. Artifact, Operator Configuration, and Managed-Service Definition source
    composition are distinct branches:
    `P1 -> A0/A1/W0`, `P1 -> OC0/O0`, and `P1 -> MS0/S0`.
12. The five driver trust states are distinct. Resolved handoff uses
    `C0 -> O0 -> H0 -> D0`; serialized reentry uses
    `RW0 -> C0 -> O0 -> H0 -> D0` and is wholly untrusted; generated backend
    configuration is D0 output; direct/raw driver paths have no admitted
    value.
13. Serialized reentry replays the exact ordered 89 built-member/load and 30
    resolved-stage invariant arrays before fresh private stages are
    constructed.
14. `prebuilt-member-transfer` and `oci-descriptor-transfer` end at H0;
    `provider-cache-hit` ends at D0; and `provider-side-construction`,
    `provider-build-cache`, and `corrupted-provider-build-result` end at N1.
    Each then hands off to `built-artifact-load` as a separate C0 path. These
    are handoff records, not phase-edge assertions or authority to skip C0
    manifest loading.
15. Framework and CLI share typed Create/live/Exec translation. Teardown
    lifecycle semantics remain Packet E work.

## Reconstructable candidate

The current machine records contain 54 paths, 140 invariant IDs, 7,560 unique
cells, 634 complete-contract groups, 76 registry path aliases, 74
frontend/path mappings, 19 native paths, and 50 invalid witnesses with nearby
valid controls. Their copied contracts preserve the exact Packet E taxonomy
(`operation-transition`, `retry`, `cancellation`, `cleanup`), Packet F
taxonomy (`disclosure`, `redaction`, `evidence-visibility`), six
`separate-path-handoff` records, and the target-applicability projection.
These generated facts supersede every earlier Packet D count or unqualified
first-class path name.

## Source pins

The identifiers below are the stable Packet D research coordinates used by
the path registry. A moving manual is pinned by retrieval date for research;
the actual executable witness must also lock the evaluator or repository
revision.

### `NIX-MODULE-SYSTEM-2026-07-24`

- Sources: [NixOS module-system manual](https://nixos.org/nixos/manual) and
  [Nixpkgs module-system reference](https://nixos.org/manual/nixpkgs/stable/),
  release 26.05 documentation retrieved 2026-07-24. The exercised prototype
  pins nixpkgs revision `62c8382960464ceb98ea593cb8321a2cf8f9e3e5`.
- Supported facts: imports are collected before the option fixed point;
  `specialArgs` participates in import resolution while `_module.args` is the
  ordinary overridable route; the numerically lowest override priority wins;
  ordinary definitions are priority 100, `mkForce` is 50, and `mkDefault` is
  1000. `mkOrder` orders surviving definitions and does not decide which
  priority survives. Submodules form another module fixed point.
- Limits: a numeric priority below 50 beats `mkForce`; freeform types and
  module arguments expand the dynamic surface; laziness defers failures until
  the relevant path is forced; surviving definitions are not a complete
  record of discarded contributors.
- Consequence: hard-policy families reject unauthorized priorities, the final
  value and native identity are deep-forced, arbitrary `specialArgs`,
  `_module.args`, freeform/FFI inputs have no Artifact authority, and supported
  dependency inputs belong to the pinned closure.
- Executable N/A/unsupported: `mkOrder` cannot select a winning definition,
  and successful Nix JSON evaluation is not product normalization. The
  prototype pins the nixpkgs flake closure; it does not assign independent
  semantic hashes to each repository-local module import. Post-render mutation
  is a raw-wire/W0 boundary, not an alternate Nix module-authority path.
- Witnesses:
  `D-NIX-OVERRIDE-PRIORITY-NEGATIVE`,
  `D-NIX-ORDER-NOT-OVERRIDE`,
  `D-NIX-SUBMODULE-FREEFORM-UNKNOWN`, and
  `D-NIX-LAZY-FORCE-FINAL-HANDLE`.

### `CUE-SPEC-2026-07-24`

- Sources: [CUE language specification](https://cuelang.org/docs/reference/spec/),
  published 2026-06-29 and retrieved 2026-07-24; official
  [unification](https://cuelang.org/docs/tour/basics/unification/) and
  [closed-struct](https://cuelang.org/docs/tour/types/closed/) documentation.
- Supported facts: conjunction and redeclaration unify recursively;
  incompatible values produce bottom instead of a source-order winner;
  definitions normally provide recursive closedness; export requires a
  concrete result.
- Limits: ordinary structs are open, and embedding can relax the closed
  restriction at the embedding site. Defaults/disjunctions and successful
  `cue export` do not prove product ownership or canonical bytes.
- Consequence: exported output is still untrusted W0 input; embedding,
  patterns, comprehensions, alternate exports, and open reconstruction are
  `artifact-native-language-escape` witnesses.
- Executable N/A/unsupported: package-file conjunction has no source-order
  winner to test; reverse file order must normalize to the same export or reach
  bottom. The exercised standard-library import is pinned by the CUE evaluator
  closure, not by a per-import integrity hash, and `cue export` is not the
  canonical product wire format.
- Witnesses: existing `invalid-embedded-unknown.cue` plus
  `D-CUE-EMBEDDED-REOPEN`, `D-CUE-DEFAULT-EXPORT-CONCRETE`, and
  `D-CUE-IMPORT-EXPORT-HIDDEN`.

### `NICKEL-MERGE-CONTRACTS-2026-07-24`

- Sources: official Nickel manuals for
  [merging](https://nickel-lang.org/user-manual/merging/) and
  [contracts](https://nickel-lang.org/user-manual/contracts/), retrieved
  2026-07-24. The executable prototype independently pins Nickel 1.15.1.
- Supported facts: record merge is recursive; merge metadata includes
  priorities, contracts, defaults, optionality, and non-exported fields;
  contracts attached to a field propagate differently from freestanding
  contracts; evaluation and contract checking are lazy.
- Limits: `force`/numeric priority can discard a lower-priority value;
  missing-field checks may be delayed; `not_exported` and serializers can omit
  semantically relevant values; open/dynamic fields and imports expand the
  input surface.
- Consequence: run the complete candidate through `nickel export`, a total
  frontend adapter, and W0. Typecheck or shallow evaluation is insufficient.
- Executable N/A/unsupported: Nickel merge priority and `force` are explicit
  semantic selection mechanisms, so there is no CUE-like source-order-neutral
  package aggregation control. The local import has no independent frozen
  semantic hash in this prototype, and Nickel JSON export is not product
  canonicalization.
- Witnesses: existing `invalid-force-bypass.ncl` plus
  `D-NICKEL-NUMERIC-PRIORITY-BEATS-POLICY`,
  `D-NICKEL-DELAYED-CONTRACT-EXPORT`,
  `D-NICKEL-IMPORT-DYNAMIC-FIELD`, and
  `D-NICKEL-SERIALIZE-NOT-EXPORTED`.

### `PKL-LANGUAGE-EXTERNAL-READERS-2026-07-24`

- Sources: official [Pkl language reference](https://pkl-lang.org/main/current/language-reference/index.html)
  and [security documentation](https://pkl-lang.org/security.html), retrieved
  2026-07-24. The executable prototype independently pins Pkl 0.29.1.
- Supported facts: typed amendments restrict unknown members;
  `amends` and `extends` are distinct directional operations; `Dynamic`
  permits a wider member space; evaluator policy controls module/resource
  readers.
- Limits: open/dynamic bodies, amendment/extension, hidden/local members,
  imports, external readers, and output rendering all sit outside nominal
  class-shape assurance. Rendering is not authorization or canonicalization.
- Consequence: deny external readers and ambient resources unless explicitly
  pinned, resource-limit the evaluator, and validate rendered bytes through
  the total adapter and W0.
- Executable N/A/unsupported: `amends` is directional rather than an
  order-neutral module merge. The no-project evaluator admits only local file
  modules and rejects the package-module control, so package locking and remote
  import freezing are intentionally not exercised. Pkl rendering is not
  canonical product normalization.
- Witnesses: existing `invalid-amendment-bypass.pkl` plus
  `D-PKL-OPEN-DYNAMIC-UNKNOWN`,
  `D-PKL-EXTERNAL-READER-DENIED`,
  `D-PKL-HIDDEN-LOCAL-RENDER`, and
  `D-PKL-AMENDS-OUTPUT-JSON`.

### `DHALL-STANDARD-2026-07-24`

- Sources: upstream [Dhall import standard](https://github.com/dhall-lang/dhall-lang/blob/master/standard/imports.md),
  [standards documentation](https://docs.dhall-lang.org/), and
  [project documentation](https://dhall-lang.org/), retrieved 2026-07-24.
  Dhall remains a research control, not an initial product frontend.
- Supported facts: imports may carry semantic integrity hashes; normalization,
  recursive merge, and right-biased record preference have distinct standard
  semantics.
- Limits: integrity is opt-in; fallback and unhashed imports remain mutable;
  right-biased preference can replace earlier fields; normalized Dhall is not
  product authorization.
- Consequence: freeze control imports and always pass normalized JSON through
  W0.
- Executable N/A/unsupported: Dhall has neither a module-definition priority
  lattice nor open-row input records in this control. Product-owned defaults
  are explicit `Optional` elimination, import aggregation/order is replaced by
  explicit record preference, and the `Input` function type remains closed.
  Dhall normalization and semantic import hashes prove evaluator stability,
  not Artifact authorization or canonical product bytes.
- Witnesses: existing `invalid-right-biased-weakening.dhall` and
  `invalid-recursive-collision.dhall`,
  `valid-default-selection.dhall`,
  `valid-import-preference.dhall`,
  `invalid-extra-field.dhall`,
  `valid-lexical-scope.dhall`,
  `valid-normalization-import.dhall`, and
  `invalid-rendered-product.dhall` plus
  `D-DHALL-UNHASHED-IMPORT`,
  `D-DHALL-HASH-CHANGED-IMPORT`, and
  `D-DHALL-NORMALIZED-WIRE`.

### `JSON-RFC-IJSON-JCS-2026-07-24`

- Sources: [RFC 8259 / STD 90](https://www.rfc-editor.org/rfc/rfc8259.html),
  [RFC 7493 I-JSON](https://www.rfc-editor.org/rfc/rfc7493.html), and
  [RFC 8785 JCS](https://www.rfc-editor.org/rfc/rfc8785.html).
- Supported facts: ordinary JSON leaves duplicate-name handling
  interoperably unsafe; I-JSON requires UTF-8 and an interoperable domain; JCS
  requires I-JSON input, duplicate rejection, deterministic property ordering,
  and a binary64-compatible numeric domain, and does not Unicode-normalize
  strings.
- Limits: parser acceptance is not canonicalization; exact large quantities
  should not be transported as JSON numbers; visually identical Unicode
  sequences may remain distinct.
- Consequence: W0 rejects duplicates before object materialization, invalid
  UTF-8/Unicode and unsupported numbers, trailing bytes, excessive depth, and
  oversized input. Packet D does not select JCS as the final wire format; that
  remains a wire ADR.
- Witnesses:
  `D-JSON-DUPLICATE-KEY`,
  `D-JSON-NUMBER-2POW53-PLUS1`,
  `D-JSON-LONE-SURROGATE`,
  `D-JSON-CANONICAL-KEY-ORDER`, and
  `D-JSON-UNICODE-NONNORMALIZATION`.

### `PACKET-C-TARGET-CONTRACTS-2026-07-24`

- Local authority:
  [`PACKET-C-TARGET-REALIZATION.json`](./PACKET-C-TARGET-REALIZATION.json),
  [`PACKET-C-CASE-CONTRACTS.json`](./PACKET-C-CASE-CONTRACTS.json), and
  [`PACKET-C-PROVIDER-CONTRACTS.json`](./PACKET-C-PROVIDER-CONTRACTS.json).
- Consequence: every target/native/provider path rederives its applicable
  field/profile case and obligation IDs. An extension-supplied obligation list
  is never authoritative.

## Executed findings

- Nix baseline: the added `mkOverride (-1)` hard-policy replacement is
  representable by the module system and is rejected by the outer product
  priority rule; valid refinement produces the same portable value in forward
  and reverse order.
- The pinned language suites now execute 31 Nix, 16 CUE, 19 Nickel, 18 Pkl,
  and 12 Dhall-control assertions. Each serious foreign frontend renders a
  source-valid invalid candidate, passes it through the total comparison
  adapter, and reaches a product-owned W0 semantic rejection. Language-native
  mechanisms that do not exist or are intentionally unsupported are recorded
  explicitly rather than simulated.
- The native-handle spike now begins with validated W0 output and exercises
  `sourceGraphClosureDigest`, `registryNamespace`, `registryVersion`,
  separate `registryDigest`, `exportAttribute`, `nativeInterfaceVersion`,
  `targetSystem`, `affectedMember`, `expectedSemanticProjection`, unknown
  member, and guest-owner checks. A production closure attestation and private
  stage type remain Gate 4B work.
- The frontend-adaptation prototype now proves exact supported shapes and
  alternatives and rejects unknown, omitted, mistyped, and unsupported values
  at the adapter rather than silently reinterpreting, projecting, or emitting
  `null`.
- The W0 prototype now executes duplicate-key, trailing-data, invalid-UTF-8,
  interoperable-number, exact depth/byte limits, valid surrogate-pair,
  lone-surrogate, and composed/decomposed non-normalization checks.
- The downstream prototype validates an exact old envelope and old semantics,
  performs one deterministic idempotent migration, and revalidates current
  semantics. It also exercises closed protocol/member/evidence-bound manifest
  loading, total generated driver output, direct corruption, and a real
  retained file descriptor that survives pathname replacement. Its current
  runner passes 40 cases.
- The Operator/Service Nix witness passes 14 cases with 172 internal
  assertions at distinct OC0/MS0 validators.
- The resolved-reentry witness passes 13 cases, 18 stable diagnostic probes,
  8 prepared-identity probes, and all 44 generated-projection leaf probes.
  It replays the machine-owned 89+30 arrays before fresh private construction
  and proves raw/direct driver callers cannot construct `PreparedLaunch`.
- These executable research witnesses do not make the planned registry hooks
  production implementations or close Gate 4B.

## Evidence rule

A source-language error alone is not bypass-resistance evidence. The serious
negative witness must first be accepted or representable by the source
mechanism, renderer, bridge, cache, transport, or corrupted-input harness and
then be rejected by the exact product-owned boundary. Each negative witness
has a nearby positive expressiveness control.
