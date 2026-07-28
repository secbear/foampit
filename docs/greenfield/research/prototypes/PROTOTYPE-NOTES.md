# Configuration-Language Prototype Checkpoint

Status: **First common vertical slice and provisional `W0` validator complete;
full corpus and scoring not complete**

These notes record executable findings from the first strengthened-Nix, CUE,
Nickel, Pkl, and Dhall-control implementations. They are not the language ADR
and are not a weighted score.

Run the checkpoint with:

```sh
./test-all.sh
./measure.sh
```

All evaluators and Nixpkgs are pinned by the prototype harness to Nixpkgs
revision `62c8382960464ceb98ea593cb8321a2cf8f9e3e5`.

## Implemented Common Slice

The strengthened Nix, CUE, Nickel, and Pkl prototypes currently demonstrate:

- one visible, descriptively named profile;
- environment package references, variables, and activation argv;
- workspace materialization and access;
- disabled/egress network semantics;
- one secret-slot descriptor;
- bubblewrap and Firecracker target declarations;
- Artifact-time Firecracker/live-workspace rejection;
- creation-time Firecracker/live-binding rejection;
- a valid Firecracker/copy-in creation;
- relative destination rejection;
- disabled-network-plus-egress rejection;
- hard-policy widening rejection;
- selected-profile/explicit-value conflict rejection;
- structured package-reference handoff through one shared `W0` validator and
  one shared Nix bridge;
- resolution of a real pinned `pkgs.hello` and creation of a real Nix
  derivation without generated Nix source;
- one comparison digest and one instantiated Nix builder derivation across
  strengthened Nix, CUE, Nickel, and Pkl.

The Nix baseline additionally demonstrates in this checkpoint:

- compositional minimum/maximum memory refinement using product-specific option
  merge types;
- definition-location provenance for both resource bounds;
- a native guest module that is rejected when it claims host-share ownership;
- creation allocation below the Artifact minimum;
- a native `pkgs.hello` value paired with a false portable package reference is
  rejected before construction.

The dedicated Nix resource-composition witness additionally demonstrates:

- distinct closed Operator Configuration and Managed-Service Definition module
  surfaces terminating at `OC0` and `MS0`, respectively;
- actual pinned imports, `mkDefault`, ordered definitions, `mkOverride`,
  `mkForce`, and `mkOverride (-1)` under pure evaluation;
- import-order-neutral valid results in fresh evaluator processes, warm-cache
  evaluation, and offline evaluation;
- two substantive modules in every valid graph, with the complete result
  compared after actually reversing their import order;
- product-registered complete typed contributor manifests that retain defaults,
  winners, losers, narrowing, `mkForce`, and stronger-than-force definitions;
  the final validator requires exact coverage, uniqueness, values, priorities,
  definition order, roles, and source identities;
- immutable dependency evidence derived from the pinned flake input itself:
  exact revision, canonical SHA-256 SRI NAR hash, and realized closure path;
- Operator hard ceilings merged by semantic narrowing and checked against
  product-owned anchors outside the contributor graph;
- hostile closed-option, `_module.args`, and `_module.freeformType` attempts,
  malformed/fabricated dependency identities, and omitted/extra/duplicate/
  wrong-role ledgers, including a force-class ledger replacement;
- import-aware structural key preflights that reject unknown option paths with
  stable `OPS-005`/`SVC-005` diagnostics without forcing or rendering their
  leaf values, while leaving `_module.args` and deliberate freeform cases to
  the final validator;
- product-controlled native-extension summaries normalized through an exact
  closed typed schema, with missing, unknown-field, and wrong-type mutations;
- a discriminating shallow-versus-deep forcing control plus deep forcing of
  each accepted normalized result and stable, secret-safe delayed rejection.

The CUE, Nickel, and Pkl prototypes additionally reject an undeclared nested
field using their closed schema/contract/class surface.

The Dhall control demonstrates:

- closed unions and exhaustive handlers;
- valid concrete evaluation;
- a concrete top-level assertion rejecting policy widening;
- the same rejection after Dhall's right-biased record preference operator;
- recursive record-merge collision;
- repeatable semantic import freezing with a SHA-256 integrity hash.

The complete locked corpus is larger. In particular, snapshot semantics,
offline module/package graphs, full composition provenance, and complete
operator/host fixtures remain to be implemented. Packet D now includes focused
schema-migration, built-manifest, and resolved-driver corruption witnesses, but
those disposable boundary validators are not production implementations.
The resolved-reentry witness additionally separates strict serialized
candidate decoding from private `C0`/`O0`/`H0` stages, reacquires a real live
file handle, and accepts only an opaque `PreparedLaunch` at the driver API.

## Verification Result

The original checkpoint passed on 2026-07-23. Packet D extended the shared
boundaries and added the Operator/Service resource-composition and resolved
reentry/private-driver-stage witnesses on 2026-07-24; the complete pinned
`test-all.sh` suite passed again after those changes:

| Candidate | Passing checkpoint cases | Scope note |
|---|---:|---|
| Strengthened Nix | 31 | Adds import/order, default/selection, module-argument, lazy-force, closed-option, native-value, and strongest-priority controls |
| Nix resource composition | 14 | Runs 172 internal assertions across distinct `OC0`/`MS0` schemas, substantive reverse import order, cold/warm/offline valid evaluation, exact pin/manifest/summary checks, secret-safe structural preflight, and strongest-bypass probes |
| CUE | 16 | Adds package-order unification, defaults/patterns/hidden output, conflicting defaults, and rendered-invalid W0 evidence |
| Nickel | 19 | Adds import/default/dynamic/recursive/hidden/forced-export/priority controls and rendered-invalid W0 evidence |
| Pkl | 18 | Adds imports/defaults/hidden/local/dynamic/amend/extend/open-module/external-reader controls and rendered-invalid W0 evidence |
| Dhall | 12 | Adds default/selection, preference, closure, scope, import normalization, stable freezing, changed-frozen-import rejection, and rendered-invalid controls; still research-only |
| Native-handle boundary | 10 | Validates registry, closure, interface, export, system, member, and effect; the validated tuple changes builder content and derivation identity deterministically |
| Frontend adaptation | 18 | Requires the exact versioned key/value shape and rejects unknown, omitted, mistyped, and unsupported values before projection |
| Shared `W0` validator | 27 | Covers trailing data, invalid UTF-8, interoperable integers, exact byte/depth edges, and the locked Unicode scalar/non-normalization domain |
| Resolved reentry | 13 | Includes 18 stable diagnostic-category probes, 8 per-profile prepared-identity mutations, and exact one-to-one mutation coverage of all 44 generated projection leaves while checking strict `RW0`, exact 89+30 replay, live reacquisition, and the private driver type boundary |
| Downstream boundaries | 40 | Validates old/current migration, protocol/member/evidence-bound manifests, retained source handles, exact prepared-stage identity, seven named valid-shaped substitutions, and the total closed expected driver projection |

The number of cases is not a score because the slices do not yet have equal
coverage.

## Preliminary Measurements

Measured on the same aarch64-darwin host with already fetched Nix store paths.
Every timing starts fresh evaluator processes with warm filesystem/Nix caches
and does not include editor/LSP startup. Frontend-only and end-to-end
measurements are reported separately.

### Pinned evaluator closure size

| Evaluator package | Nix closure |
|---|---:|
| CUE 0.15.4 | 24.4 MiB |
| Nickel 1.15.1 | 67.6 MiB |
| Pkl 0.29.1 | 354.0 MiB |
| Dhall 1.42.3 | 128.7 MiB |
| `dhall-json` 1.7.12 | 274.1 MiB |

The system Nix evaluator is already a product prerequisite, so its closure is
not counted as an incremental frontend cost.

### Fresh-process valid evaluation

Three consecutive runs:

| Candidate | Run 1 | Run 2 | Run 3 |
|---|---:|---:|---:|
| Strengthened Nix | 0.55 s | 0.41 s | 0.46 s |
| CUE | 0.05 s | <0.01 s | <0.01 s |
| Nickel | 0.03 s | 0.01 s | 0.01 s |
| Pkl | 0.74 s | 0.59 s | 0.58 s |
| Dhall control | 0.09 s | 0.02 s | 0.01 s |

The Nix case imports pinned Nixpkgs, retains a real package value, evaluates
modules, and emits the normalized result. CUE/Nickel/Pkl/Dhall rows do not
resolve the package through Nix in these frontend-only timings.

### Fresh-process frontend plus `W0` plus Nix construction evaluation

The end-to-end command evaluates the frontend, applies the common-slice shape
adapter where needed, invokes the prebuilt release-mode Rust `W0` validator,
passes only the validator's Artifact output to the shared Nix bridge, resolves
`pkgs.hello`, and instantiates the manifest builder derivation. It does not run
the derivation builder.

| Path | Run 1 | Run 2 | Run 3 |
|---|---:|---:|---:|
| Strengthened Nix, serialized/two-eval control | 0.96 s | 0.92 s | 0.80 s |
| Strengthened Nix, one construction evaluation | 0.45 s | 0.43 s | 0.43 s |
| CUE | 0.44 s | 0.41 s | 0.40 s |
| Nickel | 0.42 s | 0.42 s | 0.40 s |
| Pkl | 1.00 s | 1.02 s | 0.99 s |

All five execution paths across the four serious candidate languages emitted
semantic digest
`db4d9e1c788df52ba6274dd09c68d554c8bc623046f65b7e2b38d145039e4f22`,
the same `hello` store path, and the same builder derivation path.

These timings expose architecture as well as evaluator speed. The serialized
Nix control invokes Nix once to emit the portable projection and again for
construction. The one-evaluation Nix control runs the Nix final semantic
validator, retains a checked native `pkgs.hello` value, and instantiates the
same builder in that evaluation; the Rust validator runs afterward only to
compare the portable digest. Each external frontend invokes its evaluator once,
then the Rust boundary and Nix bridge once.

The one-evaluation result demonstrates that the provisionally recommended Nix
semantic authority is feasible for this slice and removes the apparent Nix
latency penalty. It does not prove the complete model or source-aware
diagnostics.

The common adapter now projects all semantics implemented by the first common
slice: hard policy, allowed materializations, derived required capabilities,
runtime profiles, packages, environment, workspace, network, secret slots,
resource bounds, and targets. The built derivation contains that complete
portable projection plus resolved package store paths.

It still omits profile source/version/digest metadata, target-advertised
capability records, native handles and guest summaries, target-specific
additions, storage/snapshot/device/port contracts, and the separately hashed
provenance record. Digest equality therefore proves equivalence of the complete
implemented slice, not a final Artifact identity.

Peak memory is still unmeasured. BSD `time` around the multi-process shell
pipeline does not provide a trustworthy per-stage peak, so the complete
measurement needs direct child-process sampling rather than a misleading
aggregate.

### Prototype lines

Implementation, fixtures, and tests:

| Candidate | Lines |
|---|---:|
| Strengthened Nix | 950 |
| CUE | 750 |
| Nickel | 733 |
| Pkl | 754 |
| Dhall focused control | 226 |
| Shared `W0` validator | 1,520 |

This is not a maintainability score. The candidates duplicate fixtures and
currently duplicate the semantic validator intentionally to expose each
language. A production architecture is prohibited from keeping independent
copies of those rules. The shared `W0` prototype is the first extraction of
that single product-owned implementation; its line count includes Rust,
fixtures, and the shell oracle.

## Executable Findings by Candidate

### Strengthened Nix

The baseline can reject all implemented Artifact-owned conflicts during forced
module evaluation. The Firecracker/live rule requires no foreign refinement
type. A product-specific final validator over the complete merged value is
sufficient.

The credible safe shape is narrower than "Artifact Definitions are arbitrary
NixOS modules":

1. closed typed options and constructors collect contributions;
2. resource bounds use semantic merge types (`max` for minima, `min` for
   maxima);
3. profiles remain named and the normalized output records the selection;
4. hard-policy inputs retain role/source metadata, reject unauthorized winning
   override priorities, and a final validator rejects widening;
5. the complete normalized value is deep-forced before it becomes an Artifact;
6. definition locations are retained as provenance;
7. native guest modules use a separate module evaluation and ownership
   assertions.

This avoids the strawman in which a scalar silently changes because a later
ordinary assignment wins. Equal-priority conflicting scalar definitions still
fail in the module system.

Remaining risks:

- arbitrary trusted modules can use arbitrary Nix language code, while each
  security-sensitive option family still needs an explicit supported-priority
  and contribution-provenance contract;
- the public constructor/module boundary must prevent those mechanisms from
  being treated as policy authority;
- custom assertion text is not yet a structured diagnostic and often points
  first at validator code;
- deriving precise cross-field provenance is possible but product work;
- the prototype has not yet tested flake/module package distribution or schema
  evolution.

The first explicit bypass case used `lib.mkForce` to replace the inherited
workspace materialization. The module system accepted the forced winning value,
but the product final validator still rejected its contradiction with the
selected profile. This confirms both sides of the boundary: option priority is
not hard-policy enforcement, and final normalized validation remains effective.

Packet D added the stronger concrete case `lib.mkOverride (-1)`, which replaces
ordinary definitions before the option type's merge. The pre-Packet-D
hard-policy validator accepted the forged replacement base. The strengthened
outer rule inspects the winning option priority and rejects every priority
stronger than an ordinary hard-policy definition. A nearby valid refinement
evaluates to the same portable value in forward and reverse module order and
records both effective contributors.

### Operator and Managed-Service Nix resource composition

The disposable resource-composition flake copies the strengthened Artifact
baseline's exact Nixpkgs revision and NAR hash. At evaluation time it constructs
the product dependency record from `nixpkgs.rev`, `nixpkgs.narHash`, and
`nixpkgs.outPath`; callers cannot supply those fields. The runner checks the
exact lock revision and NAR hash and performs real pure Nix module evaluation;
it does not inspect source text to simulate module behavior. Each of the fixed
14 reported labels contains a nearby valid graph with at least two substantive
modules, evaluated in forward and actually reversed module order in cold, warm,
and offline modes.

Operator Configuration has exactly six public option roots: drivers, providers,
placement classes, hard ceilings, credential references, and the contributor
ledger. Driver, provider, placement, ceiling, credential-reference,
source-identity, dependency, and contributor records are closed and typed.
`OC0` rejects credential values represented as literal references, unregistered
selections, ceiling widening, unsupported winning priorities, incomplete
ledgers, malformed or fabricated dependency identity, and semantic native
escapes. Unknown options remain a separate structural rejection. Hard-ceiling
anchors are product constants outside module composition, so neither
force-class priority can replace them.

Managed-Service Definition has exactly five public option roots: Artifact
reference, typed Create request, desired lifecycle, service metadata, and the
contributor ledger. Its nested records are closed and typed. `MS0` rejects
driver calls, raw runtime arguments, Artifact-policy mutation candidates,
unversioned/non-Core operations, incomplete ledgers, mutable dependencies, and
semantic native escapes. The valid normalized result retains only typed Core
Sandbox API intent; it does not create a second driver or lifecycle path.

Before invoking the public module schemas, each constructor recursively
inspects the registered wrapper/import surfaces and their option-key paths.
Declared leaf values remain opaque: the unknown-field witnesses deliberately
store secret-bearing failing thunks, yet rejection is the stable `OPS-005` or
`SVC-005` invariant and never forces or renders the marker. `_module.args`
surfaces and a same-module `_module.freeformType` declaration remain explicit
preflight exceptions so their separate final-validator witnesses still
exercise the intended semantic boundary.

Native-extension validation metadata is also product controlled. Each summary
is first evaluated through a closed typed schema with exactly `name`,
`interfaceVersion`, and a closed `sourceIdentity`, then projected into that
minimal shape before normalization. Valid summaries survive unchanged;
missing fields, unknown nested/raw fields, and wrong field types produce a
stable product-summary invariant without leaking the rejected value.

Callers select only a product-registered composition identity. The product
registry owns the module graph and a complete contribution manifest containing
defaults, winners, losers, narrowing, `mkForce`, and `mkOverride (-1)`
definitions. Module source identities contain canonical SHA-256 SRI hashes of
the actual flake-source files. The final validator requires the evaluated
ledger to equal that manifest exactly, including unique definition indexes,
values, priorities, order, roles, and source identities, and cross-checks
surviving Nix definitions against the registered source, priority, and value
digests. Separate mutations prove omitted, extra, duplicate, and wrong-role
records fail; a combined `mkForce` plus incomplete-ledger mutation proves
ledger completeness is forced before later priority validation.

Dependency records in the ledger must equal the dependency record derived from
the actual flake input. The validator rejects missing identity fields,
non-canonical or malformed SHA-256 SRI (including `sha256-x`), and
well-formed-looking fabricated revision/hash pairs. The exact product
dependency and closure path are retained in normalized validation metadata,
never accepted as public module options.

These witnesses do not make arbitrary Nix code safe, implement production
source-span diagnostics, independently attest the full production transitive
dependency closure, or close Gate 4B. The product manifest is bound to the
registered module graph and actual source-file hashes, and surviving Nix
definition metadata is checked at runtime; Nix does not expose discarded
losing definitions after merge, so the complete losing-definition inventory
remains product-registry evidence. A production implementation still needs an
independently generated and attested transitive source/definition graph and
structured diagnostics rather than prototype throw strings. The structural
preflight is likewise a decision witness over this registered module subset,
not a general static analyzer for arbitrary dynamic Nix module functions.

### CUE

CUE's recursive closed definition rejected the misspelled nested field without
additional validator code. Constraint loops made policy and capability checks
compact, and `error(...)` carried stable invariant identities with source
locations.

An important representation result appeared immediately: optional fields
cannot be selected as normal concrete values. The prototype introduced an
explicit `"inherit"` alternative for materialization, access, and network mode.
This is not proposed public spelling, but it validates the product requirement
to distinguish inherited from concrete values.

CUE unification did not eliminate the need for a product final validator. The
validator still owns:

- selected-profile consistency;
- hard-policy authority/refinement;
- target-capability quantification;
- owner boundaries;
- canonical output.

`cue export` is not the canonical byte contract. The prototype deliberately
hands its structured result to the product bridge, and the eventual
canonicalizer must independently define key ordering, numbers, duplicate keys,
and digest bytes.

Remaining risks:

- CUE closedness and embedded-value edge cases need explicit `CMP-008` fixtures;
- provenance is not yet emitted from CUE syntax nodes;
- CUE module versions and OCI content digests need an offline pinning fixture;
- native Nix values require the handle boundary described below;
- the current output repeats some input structures rather than proving full
  normalization and schema migration.

An embedded CUE definition attempted to inject an undeclared nested field.
Recursive closedness at `#ArtifactInput` rejected it as `field not allowed`.
This passes the first embedded-value bypass fixture, but more embedding/pattern
field combinations remain in the full corpus.

### Nickel

Nickel's closed record contracts rejected the nested typo. The full
`nickel export` forced the delayed contracts exercised by this slice. Its
symmetric record merge and explicit priority annotations make conflict intent
more visible than order-based override systems.

The prototype still needed the same explicit product validator as CUE/Nix.
Contracts did not replace target capability, hard-policy authority, or owner
rules.

Nickel-specific facts confirmed by execution/source review:

- shorthand-looking record fields without `=` are requirements, not value
  capture;
- records are recursive, so exporting outer bindings under the same names
  caused recursion until the bindings were renamed;
- formatter and source diagnostics are usable;
- official package management remains experimental and disabled in standard
  releases;
- all relevant delayed checks must be forced/exported before the canonical
  boundary.

Remaining risks:

- `force`/numeric priorities require explicit bypass fixtures;
- package pinning probably has to be owned by Nix until Nickel package
  management stabilizes;
- exact provenance across contract propagation/merge is unimplemented;
- no native Nix value can cross Nickel's JSON serializer directly.

A raw Nickel record used the highest `force` priority to replace the policy
refinement list. The compiler observed the forced final value and the product
validator rejected the widening. This confirms that contracts/merge priority
alone are not the authority boundary; forced values must still cross final
semantic validation.

### Pkl

Closed Pkl classes rejected the unknown property and produced readable source
locations. Classes, string unions, defaults, and collection predicates make the
thin Artifact model familiar and direct.

Execution exposed several costs not visible in a feature table:

- Pkl 0.29.1 in the pinned Nixpkgs revision has no `pkl format` command despite
  claims in the broad report;
- the Nix closure is 354.0 MiB because this package uses a JVM runtime;
- fresh process startup was about 0.53 s before invoking Nix;
- a property named `output` collides with Pkl's built-in `Module.output`;
- nested calls to an `ensure` helper evaluated inner arguments early enough to
  report a later capability error before the intended profile conflict. An
  ordered `if`/`else if` validator was required to guarantee the product's
  earliest error;
- the first manifest implementation unconditionally emitted
  `bubblewrap-live`, even when `allowedMaterializations` contained only
  `copy`. The expanded cross-language digest oracle exposed the mismatch.
  Conditional `Mapping` members now derive exactly the usable runtime
  profiles, matching the other candidates.

The evaluator I/O allowlist and package checksums remain meaningful advantages,
but CPU/memory isolation remains an external product responsibility.

Remaining risks:

- the positive `Dynamic` fixture proves that untyped extension members are
  representable; the separate open-module `extends` fixture proves that an
  invalid extended result still reaches and is rejected by W0. Native
  extensions remain a product handle-boundary concern rather than arbitrary
  Pkl values;
- the evaluator must run inside a resource-limited sandbox;
- dependency tests must require explicit checksums rather than TOFU;
- formatter/tooling claims must be version-specific;
- Nix-native values use the handle boundary, not Pkl code generation.

A typed Pkl `ArtifactInput` instance was amended to replace its inherited
workspace materialization. Amendment succeeded as a language operation, and the
product validator then rejected the selected-profile contradiction. Typed
classes prevent unknown structure; they do not make semantically conflicting
amendments impossible.

### Dhall control

Dhall's strongest confirmed advantages are totality, closed unions, exhaustive
handlers, normalization, and semantic import hashes.

The control also found a central mismatch for this product: an `assert` inside
a function is type-checked while the function input is abstract. Dhall could
not prove the relationship between two independently selected union values for
all inputs, so it rejected the validator function itself. The working shape is:

1. a total `analyze` function returns computed validity booleans and a manifest;
2. a product-owned top-level wrapper applies it to a concrete imported value;
3. concrete `assert` bindings require each Boolean to equal `True`;
4. only then is the manifest exported.

That wrapper caught a policy widening even after a right-biased `//` update.
However, the failure is a generic assertion diff; Dhall has no equivalent of
the stable custom invariant errors used in the other prototypes.

This is enough E3 evidence not to promote Dhall to the full slice now. A tagged
`Valid | Invalid` result could carry structured errors, but the product would
then own more validator plumbing and every call site must unwrap it. Dhall
remains the import-integrity/totality control and may be revisited if other
candidates fail those criteria.

## The Nix-Native Value Boundary

The shared bridge proves one clean path:

```text
frontend source
  -> concrete structured Artifact value
  -> package reference { pinned input identity, output attribute, system }
  -> product-owned Nix bridge
  -> real package/store path/derivation
```

The bridge allowlists pinned inputs and attributes. It does not evaluate
frontend-generated Nix source.

This works well for packages, dev shells, and modules exported through flakes,
but it exposes the sharpest external-frontend limitation:

- a Nix derivation is an evaluator value, not portable JSON;
- an inline NixOS module is a Nix function, not portable JSON;
- an arbitrary user-defined dev shell may close over Nix values that cannot be
  reconstructed from a string.

A non-Nix frontend therefore needs explicit native handles:

```text
portable frontend references a native handle
native Nix companion exports the handle's package/devShell/guest-module value
Nix bridge resolves the handle from a pinned flake/module registry
portable validation and native-module validation remain separately scoped
```

This is feasible and preserves full functionality, but it is real glue and a
second source file for advanced native extensions. It must be compared against
the Nix baseline's direct values in the complete vertical slice.

The checkpoint now includes an executable native-handle registry:

- a separate prototype handle document names a registry, its SHA-256 content
  digest, a dev shell handle, and guest-module handles after the portable
  manifest has passed W0;
- the shared bridge accepts only the product-known registry and exact digest;
- the registry resolves a real `pkgs.mkShell` derivation and a real Nix module
  function;
- the guest module is evaluated under a separate guest schema;
- a safe module contributes an in-guest service;
- an unsafe module that contributes a host share is rejected with
  `artifact.native_guest.owner_boundary`;
- the complete validated registry/closure/interface/export/system/member/effect
  tuple is embedded in builder content, so a valid handle changes the builder
  derivation identity and repeating the identical handle is deterministic.

This confirms that the frontend limitation is not a feasibility blocker.
Portable policy remains in the portable Artifact value; Nix-native evaluator
values remain in the native companion; the digest/handle is the explicit join.
It also confirms the tradeoff: advanced users author and review two differently
typed, separately scoped sources, and the product must make their provenance
and navigation feel like one Artifact without pretending they are one data
model.

The native registry is trusted Nix code and is pinned as an immutable Artifact
input. It is not a sandbox for hostile Nix expressions. The production design
must carry the same typed tuple through the portable identity/private stage
boundary instead of a separate prototype argument, replace the local closure
digest with a production closure attestation, and independently verify the
built member identity at manifest load.

The rejected alternatives are:

- serializing store paths as if they were stable source references;
- accepting arbitrary Nix source strings in the portable manifest;
- generating textual Nix from CUE/Nickel/Pkl/Dhall;
- pretending arbitrary Nix evaluator values fit a language-neutral wire schema.

The eventual ADR must explicitly decide whether the correctness/ergonomic gain
of a frontend justifies native handles, or whether direct Nix values make
strengthened Nix the more coherent surface.

## The Portable-Value and Built-Manifest Boundary

Implementing the first wire-corruption fixtures exposed a representation
distinction that a language feature table can hide:

```text
Artifact Definition source
  -> normalized portable Artifact value
  -> product W0 validator and comparison digest
  -> Nix construction
  -> built Sandbox Artifact Set and built manifest
```

The normalized portable value is not another deployable resource and is not a
general runtime plan. It is the complete Artifact-owned compiler boundary
before construction. It carries typed pinned references or native-handle
identities. It cannot carry derivations, Nix functions, or resolved store paths
as though they were portable source identities.

The built manifest is different: it is an output of Nix construction and may
record the store paths, target-member identities, runtime requirements, and
construction evidence that the Artifact Set actually contains. Runtime code
continues to parse that manifest as untrusted data and convert it into
target-specific product types.

This does not displace the flake as the thing a user shares. A flake may contain
the Artifact Definition, pinned dependencies, native companion definitions,
and the build that deterministically produces the Artifact Set. The
language-neutral value is an internal validation/join boundary that makes
multiple frontends and defensive corruption checks feasible.

The disposable Rust validator now proves:

- recursive duplicate-key rejection before generic JSON decoding;
- byte and nesting limits at both the accepted edge and first rejected value;
- UTF-8 and Unicode-scalar rejection while preserving composed and decomposed
  strings as intentionally distinct values;
- one canonical comparison byte string and digest for reordered inputs;
- `W0` rejection of unsupported majors, unknown fields, unregistered
  extensions, secret values, non-integral byte quantities, relative workspace
  paths, empty targets, and disabled-network/egress contradictions;
- structured diagnostics containing the `artifact` owner, `W0` phase, stable
  invariant, primary/related paths, constraint, remediation, cause chain, and
  secret-safe actual values.

The serialized strengthened-Nix, CUE, Nickel, and Pkl fixtures now traverse
this validator before the shared Nix bridge. Each produces the same digest,
package store path, and builder derivation. A separate strengthened-Nix control
runs its final semantic validator and construction in one Nix evaluation,
retains its native package value, and produces that same derivation; the Rust
validator then confirms its portable projection digest. The Nix baseline pairs
its native package value with a portable pinned reference and rejects a
deliberately false pair.

That success does not by itself justify making the Rust prototype the
authoritative semantic implementation. Doing so would force the Nix path to
serialize or export handles for every native value and usually evaluate twice.
The separately documented
[semantic-validation authority analysis](../SEMANTIC-VALIDATION-AUTHORITY.md)
provisionally recommends keeping one final Artifact semantic core in Nix while
using a strict systems-language component for structural decoding,
canonicalization, and built-manifest/runtime boundaries. The complete corpus
must decide this before the ADR.

`artifact-comparison-json-v0` and every field spelling in this prototype remain
comparison-only. It does not claim RFC 8785 conformance or settle the final
wire ADR.

## Resolved Reentry and the Private Driver Stage

The disposable Rust library and CLI use a separate
`resolved-reentry-v1` envelope with exactly six top-level fields:
`schemaVersion`, `artifact`, `create`, `admissionContext`,
`retainedSourceReferences`, and `integrity`. Byte length is checked before
parsing; a duplicate-aware, depth-bounded visitor runs before every nested
closed typed record is deserialized. Authentication context admits bytes only:
an authenticated candidate with stale Artifact, Create, admission, profile, or
retained-source identity still fails complete current semantic replay.

The replay authority loads the reviewed Packet D case catalog and requires
ordered equality, set equality, and uniqueness for the exact 89 built-member
load IDs and 30 resolved-stage IDs. Separate missing, extra, duplicate, and
reordered mutations fail both arrays. Only successful replay can pass through
private `ResolvedCreation` and `AdmittedCreation` values to construct the
publicly nameable but opaque `PreparedLaunch`.

Every `WIRE-007` and `DRV-001` diagnostic now selects a fixed product-owned
category and static message. Third-party serde text, object keys, values,
duplicate/depth paths, and replay IDs are never emitted. Adversarial unknown,
duplicate, nested, value, malformed-JSON, replay-extra, replay-duplicate, and
non-string-ID markers are absent from stderr; malformed envelope JSON and the
depth limit have permanent exact-category assertions. Only numeric
byte/count/index context may accompany the fixed category.

`PreparedLaunch` has private fields and no `Deserialize` or `Clone`
implementation. It owns a real `std::fs::File` acquired from the current H0
inputs; serialized path hints and tokens are retained only as untrusted
candidate data and are never opened. Repeating identical replay produces equal
semantic identity and equal generated configuration while two simultaneously
live results have distinct file descriptors. Temporary external consumer
crates compile and run the positive `decode -> revalidate -> driver` path, and
compile-fail probes lock the stable Rust error categories for struct literals,
deserialization, cloning, JSON values, maps, and raw argument vectors.

The generated runtime configuration is a total closed projection over
identity, profile, retained source, workspace, network, resources,
identity/security, devices, secrets, snapshots, output, protocol versions, and
an explicit backend-default suppression inventory. It represents valid absence
with empty typed collections or `null`, binds each required Packet C profile to
its target and protocols, and is checked again by the downstream jq boundary.
The downstream boundary receives the expected semantic identity from the
admitted opaque `PreparedLaunch` and requires exact equality, preserving the
`DRV-003` private identity chain under the `DRV-001` corruption invariant.
Each profile's real generated configuration rejects both a different
well-formed 64-hex identity and a malformed identity, and all four admitted
profile identities are distinct.
After closed-schema checks, the validator compares the entire candidate with a
separately retained product-owned expected configuration derived from the
admitted `PreparedLaunch`; it never derives expectations from the mutated
candidate. The runner proves that the expected configuration has exactly 44
non-object leaves, the mutation inventory has 44 unique matching paths, and a
valid-shaped substitution at every path is rejected. Named downstream cases
independently lock workspace destination, CPU, memory, disk, UID, GID, and
output-byte limits.
Unknown or omitted structure, raw host paths/arguments, and implicit defaults
fail `DRV-004`; identity, profile, protocol, admission, retained-source, or
constraint corruption fails `DRV-001`.

This proves the API and trust-state shape for the decision, not a production
runtime, real authentication implementation, production host/provider
acquisition, backend execution, or Gate 4B closure. The witness's concrete
resource values and protocol strings remain prototype fixtures.

## Next Prototype Work

Before scoring:

1. close Gate 2A from the
   [Invariant Inventory and Enforcement Protocol](../INVARIANT-ENFORCEMENT.md):
   finish the exhaustive state-space review, seed the machine-readable registry,
   and freeze every invariant's representation, hook, test, diagnostic, target,
   and bypass obligations;
2. implement the rest of the Artifact-owned corpus in a shared fixture
   generator;
3. add strongest-escape-hatch fixtures for every candidate;
4. expand the common portable projection to the complete Artifact-owned model,
   remove the temporary `jq` shape adapter, and preserve frontend source spans
   in the diagnostic cause chain;
5. extend the native-handle spike from the prototype guest schema to a real
   NixOS module evaluation and multiple systems;
6. implement source-aware provenance extraction as a separate, non-hashed
   explanation record;
7. test pinned module/package graphs offline;
8. test the semantic-authority alternatives, including a single-evaluation Nix
   path, then measure per-stage peak memory;
9. exercise schema migration, remaining number-domain cases, and import-order
   permutations;
10. close Gate 4B by linking every registry entry to concrete enforcement and
    evidence;
11. perform blind transcript review before assigning weights.

No source-language decision is warranted until those checks are complete.
