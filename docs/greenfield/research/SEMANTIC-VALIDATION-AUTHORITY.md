# Semantic Validation Authority

Status: **Research finding and provisional recommendation; final selection
belongs to the configuration-language ADR**

## Why This Decision Exists

The first end-to-end prototypes established that Nix, CUE, Nickel, and Pkl can
produce the same provisional portable value, pass one strict decoder, resolve a
real pinned Nix package, and instantiate the same derivation.

They also exposed a more consequential issue than frontend syntax: where the
single authoritative Artifact semantic validator lives.

The product needs all of these properties simultaneously:

1. corrupted frontend output fails before target construction;
2. duplicate object keys fail before a generic decoder can discard one;
3. Nix packages, derivations, dev shells, and guest modules remain native Nix
   values during construction;
4. the portable semantic digest never hashes process-local evaluator values or
   treats store paths as source identities;
5. a Nix author does not need to split every ordinary package reference and
   native guest module into unrelated sources merely to satisfy an internal
   compiler phase;
6. runtime code never receives a Nix/CUE/Nickel/Pkl evaluator value;
7. two handwritten semantic implementations cannot silently diverge.

The `W0` boundary is a product phase, not necessarily a process boundary.
Requiring one external executable between Nix evaluation and Nix construction
would be an accidental architecture decision.

## The Value Pair at the Nix Boundary

Nix construction needs two related but non-interchangeable facts:

```text
portable identity
  pinned input + output/attribute/handle identity + declared semantics

native value
  derivation/package/devShell/module function available to this Nix evaluator
```

For a non-Nix frontend, the frontend supplies only the portable identity. The
product-owned Nix resolver obtains the native value from pinned inputs.

For a Nix frontend, a product constructor may retain both in one evaluator
invocation. Final validation must prove that the native value resolves from or
matches the portable identity. The prototype now rejects a `pkgs.hello` value
paired with a different declared attribute.

The portable semantic digest hashes the identity and semantics. The built
Artifact manifest records the store/output identities that construction
actually produced. Those are deliberately different identity layers.

## Alternative A: Runtime-Language Validator Is Authoritative Before Nix

Pipeline:

```text
any frontend
  -> serialized portable value
  -> Rust validator/canonicalizer
  -> second Nix invocation resolves every handle and constructs outputs
```

### Advantages

- exactly one semantic implementation before construction;
- natural duplicate-safe decoding, structured diagnostics, canonical bytes,
  migrations, and API reuse;
- every frontend, including Nix, traverses exactly the same serialized
  boundary;
- fuzzing and hostile-input hardening fit a systems-language parser.

### Costs and correctness risks

- native Nix values cannot cross the serialized boundary;
- every direct package, dev shell, and inline guest module needs a reconstructible
  identity or exported handle;
- a Nix authoring path generally performs one evaluation to emit the portable
  value and another to construct outputs;
- inline native modules become companion exports or registries, increasing
  authoring and provenance glue;
- the product proposition weakens if Nix is used only after another compiler
  has erased its native values.

This architecture is feasible and the prototype demonstrates its handle path.
It is not currently preferred because it makes the hardest Nix integration
case the universal case.

## Alternative B: Nix Construction Core Owns Artifact Semantics

Pipeline:

```text
non-Nix source
  -> frontend early checks
  -> strict structural decode/canonical input
  -> product Nix adapter
  -> one final Nix semantic validator
  -> target construction

Nix source
  -> product Nix constructors/modules
  -> portable projection + checked native-value side table
  -> the same final Nix semantic validator
  -> target construction in the same evaluation
```

The strict outer decoder owns syntax, duplicate keys, schema-major admission,
restricted scalar domains, canonical bytes, and secret-safe transport
handling. It does not grow a second handwritten copy of every cross-resource
Artifact rule.

The final Nix core owns profile expansion, refinement, hard-policy authority,
capability quantification, portable/native-reference equality, native guest
module boundaries, and target construction admission. It validates the
complete value before constructing derivations. For a serialized frontend,
this validation is the semantic part of `W0` even when it executes inside the
same `nix eval` process that will perform `N0`; product phases do not require
separate operating-system processes.

Runtime code later parses the *built* manifest as untrusted data. It validates
manifest structure, identity, target-specific driver input, and all
creation/operator/host refinements. It does not reimplement authoring-language
profile expansion or hard-policy composition.

### Advantages

- native Nix values stay native for Nix authors;
- external frontends still disappear before construction;
- one final merged validator and target compiler serve every frontend;
- Nix remains visibly central rather than becoming a package lookup service;
- one evaluator invocation can validate and construct the Nix-authored path;
- separately scoped guest NixOS modules remain practical.

### Costs and correctness risks

- hostile portable input reaches the Nix evaluator after structural decoding;
- Nix diagnostics require deliberate product adaptation to stable structured
  errors;
- canonicalization and semantic validation are separate components and their
  phase contract must be explicit;
- runtime manifest validation remains a second implementation of the *manifest
  schema*, though not of the authoring semantics;
- semantic rules must be written in a disciplined, closed product core rather
  than scattered through target builders;
- Nix evaluation is trusted code execution, so Artifact Definitions are trusted
  build inputs, not a sandbox for hostile authors.

This is the provisional recommendation for the first complete implementation.
It best preserves Nix's native-value and module-system strengths while keeping
external frontends replaceable.

## Alternative C: Generate Nix and Runtime Validators From One Rule Model

A language-neutral schema and constraint IR could generate:

- Nix option types, constructors, and final assertions;
- Rust wire/manifest types and validators;
- frontend contracts or bindings;
- documentation and migration skeletons.

This offers the strongest mechanical drift control. It also creates a new
purpose-built language, code generator, source-map system, and debugging layer
before the product semantics have stabilized. Cross-resource rules,
provenance, native-module validation, and refinement diagnostics are not
trivial schema-generation problems.

This remains an optimization path if conformance testing demonstrates real
drift. It is not the feasibility baseline.

## Alternative D: Two Handwritten Authoritative Validators

Nix and Rust each implement all Artifact semantics, with a corpus expected to
keep them aligned.

Independent defensive checks are valuable, but two components cannot both be
the semantic authority. A test corpus can detect sampled divergence; it cannot
make unsampled rule evolution impossible. This option is rejected as the
stable architecture.

The runtime may defensively reject an impossible built manifest. Such checks
are defense in depth and target-input validation, not a second source of
profile/default/composition truth.

## Provisional Recommendation

Use Alternative B for the complete vertical slice:

1. define one closed, fully normalized portable Artifact model;
2. use a strict systems-language decoder/canonicalizer for serialized values;
3. keep final Artifact semantic validation and construction admission in one
   product-owned Nix core;
4. let Nix constructors pair portable identities with native values and verify
   the pair;
5. let external frontends emit only portable identities;
6. emit a separately versioned built manifest with generated or strongly typed
   runtime readers;
7. use the shared corpus to verify frontend early errors, Nix authority, wire
   corruption, built-manifest corruption, and runtime refinement independently;
8. reconsider generated validators only after the complete rule set and
   diagnostics stabilize.

This recommendation is conditional on the complete corpus proving that Nix can
produce adequate structured diagnostics and that no rule requires an unsafe or
opaque evaluator escape hatch.

## Executed Feasibility Evidence

The 2026-07-23 common-slice control now executes both Nix shapes:

1. serialized/two-evaluation Nix emits the portable value, passes the Rust
   comparison validator, and invokes the shared Nix bridge;
2. one-evaluation Nix runs its final semantic validator, retains the native
   `pkgs.hello` value paired with its portable reference, and instantiates the
   builder without serializing that native value.

The one-evaluation Nix path, serialized Nix path, CUE, Nickel, and Pkl all emit
the same comparison digest, resolve the same package store path, and instantiate
the same builder derivation. A Nix fixture that pairs `pkgs.hello` with a false
portable attribute is rejected as
`artifact.nix.package_reference_matches_value`.

On the measured warm-cache slice, one-evaluation Nix took 0.43–0.45 seconds;
the serialized/two-evaluation control took 0.80–0.96 seconds. This establishes
feasibility and the evaluation-count consequence. It does not yet establish
the complete portable model, native dev-shell/module pairing, structured Nix
diagnostics, or peak memory.

## Required Deciding Experiments

Before the ADR locks this recommendation:

- pass corrupted but structurally valid CUE/Nickel/Pkl output into the Nix
  semantic core and prove rejection before derivation construction;
- run the same corruption through the Nix-authored path's portable projection;
- pair at least one native package, dev shell, and guest module with a false
  portable identity and prove rejection (package complete; dev shell and guest
  module remain);
- preserve frontend spans and Nix definition locations in one diagnostic cause
  chain;
- extend the proven single-evaluation Nix path from the common projection to the
  complete Artifact model;
- demonstrate that a non-Nix frontend plus Nix construction produces the same
  complete portable digest and target outputs as the Nix frontend;
- test schema-major migration and duplicate-key rejection without invoking
  arbitrary frontend or Nix code;
- fuzz the strict decoder and built-manifest parser separately;
- measure end-to-end latency, peak memory, and evaluation count for both the
  single-evaluation Nix path and external-frontend path;
- document exactly which runtime defensive checks intentionally overlap and
  which Artifact authoring rules exist only in the Nix semantic core.
