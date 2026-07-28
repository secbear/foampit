# Configuration Language and Type-System Research

Status: **Active research phase — primary-source sweep reviewed; no language
decision is locked**

This research phase determines whether the public Artifact Definition should
remain a Nix module surface or use a more strongly constrained declarative
language that compiles to the same Nix-built Artifact Set.

The motivation is correctness: determine whether a language such as Nickel,
CUE, Dhall, Pkl, or another suitable system can make materially more invalid
configurations syntactically or statically unrepresentable without compromising
Nix integration, native guest configuration, composition, diagnostics, or
product feasibility.

This is a product-boundary decision, not a syntax preference.

The broad source-discovery report and its primary-source correction are retained
under [`research/`](./research/). The
[primary-source review](./research/configuration-language-source-review.md) is
the controlling source-sweep artifact; the generated broad report is not a
recommendation or scoring result.

The common comparison oracle is locked in the
[executable corpus](./research/CONFIGURATION-LANGUAGE-CORPUS.md).
The corpus is governed by the
[Invariant Inventory and Enforcement Protocol](./research/INVARIANT-ENFORCEMENT.md),
which adds a machine-readable invariant registry and two mandatory gates:
inventory completeness before candidate implementations are treated as
complete, and enforcement closure before review or scoring.

Executable prototype evidence is recorded incrementally under
[`research/prototypes/`](./research/prototypes/); the
[first checkpoint](./research/prototypes/PROTOTYPE-NOTES.md) is explicitly
pre-scoring and incomplete. The same checkpoint now includes a disposable
[language-neutral `W0` validator](./research/prototypes/wire-validator/) for
duplicate-safe decoding, corrupted-frontend rejection, structured diagnostics,
and canonical comparison bytes. It is not an additional authoring candidate or
a final wire schema.

The pipeline exposed a separate implementation decision—whether the final
Artifact semantic authority lives before or within Nix construction. The
[semantic-validation authority analysis](./research/SEMANTIC-VALIDATION-AUTHORITY.md)
records the alternatives, provisionally recommends one final product-owned Nix
semantic core, and lists the experiments that must pass before the ADR may lock
that recommendation.

The normative configuration ownership and implementation boundaries are in
[Greenfield Design and Product Specification](./DESIGN.md). This research must
preserve them.

## Locked Context

This research may not change the already locked resource boundaries:

1. Artifact Definition owns immutable content, hard policy, required
   capabilities, binding-slot contracts, and target construction.
2. `CreateSandbox` owns concrete creation-time bindings and allocations.
3. Operator Configuration owns hosts, providers, credentials, infrastructure,
   capacity, and global constraints.
4. The optional managed-service surface declaratively calls the same Core
   Sandbox API.

It may change the source language used to author Artifact Definitions and the
mechanism used to type-check and normalize them.

Regardless of language:

- Nix remains the deterministic package and artifact construction substrate.
- The build result remains the versioned Sandbox Artifact Set and manifest.
- The Core Sandbox API remains language-neutral.
- Runtime drivers accept only validated target-specific values.
- native target configuration remains resource- and lifecycle-scoped;
- no target backend default or invisible fallback participates;
- secret values and current-host facts remain outside immutable build inputs.

## Research Questions

The research must answer:

1. Can the candidate express closed tagged unions so that mutually exclusive
   states cannot coexist?
2. Can it distinguish absent, inherited, explicitly selected, and intentionally
   empty values without null/boolean ambiguity?
3. Does composition preserve constraints, or can later merges silently weaken
   an earlier contract?
4. Can hard policy be modeled as refinement rather than last-writer-wins
   override?
5. Can target capability requirements be checked before artifact construction?
6. Can it produce source-located, human-readable errors for conflicts spanning
   imported modules?
7. Is evaluation deterministic, total, and safely sandboxed?
8. How are imports pinned, cached, versioned, and distributed?
9. Does the language have a stable formatter, language server, documentation
   generator, test tooling, and package story?
10. Can library authors publish reusable, versioned profiles and constructors?
11. Can users inspect the fully expanded result and the provenance of every
    value?
12. Can the candidate interoperate cleanly with flakes, Nix store paths,
    packages, derivations, systems, and dev shells?
13. Can advanced users still supply native NixOS guest modules without creating
    two contradictory sources of truth?
14. Where are Nix evaluation and builds invoked, and how are errors mapped back
    to the source configuration?
15. Would adopting the language clarify or dilute the product proposition of
    bringing Nix to agent environments?
16. What new compiler, schema, runtime, packaging, and maintenance burden would
    the product own?
17. Can stored manifests and APIs evolve independently of source-language
    versions?
18. Does the stronger language eliminate invalid states, or merely move
    validation into another evaluation phase?

## Candidate Architectures

The research must compare architectures, not merely languages.

### A. Nix module surface

Users author Artifact Definitions as Nix modules. The product combines:

- Nix option types;
- tagged constructor functions;
- closed submodules where practical;
- final merged-configuration assertions;
- product-owned normalization;
- versioned manifest schema validation;
- stronger target-specific types in the runtime implementation.

This is the lowest-integration-cost baseline.

Its central limitation is that the Nix module graph is open. Users can write
arbitrary attribute sets and use priority mechanisms such as `mkForce`.
Invalid input may be expressible even when it is rejected before becoming an
Artifact Set.

### B. Typed configuration frontend with Nix backend

Users author the portable Artifact Definition in a separate declarative
language. The frontend evaluates to a canonical, versioned intermediate
representation. Nix consumes that representation and builds target artifacts.

Native NixOS guest modules remain a separately scoped extension and are
validated after their final merge.

This can provide a closed portable schema while retaining Nix as the builder,
but risks:

- two module/composition systems;
- two error models;
- impedance around packages, dev shells, derivations, and store paths;
- duplicated profile and default logic;
- a split between portable configuration and native NixOS configuration.

### C. Typed frontend that generates Nix

The candidate language emits Nix expressions or modules rather than only a
canonical data representation.

This may improve access to existing Nix facilities but creates a generated-code
boundary whose source mapping, security, debuggability, and long-term stability
must be proven.

Generated textual Nix is not acceptable unless there is a compelling reason
that structured interchange cannot satisfy.

### D. Nix authoring with an external schema/compiler gate

Users continue to write Nix, but evaluation must produce a restricted wire
representation that is validated by a stronger schema or type system before
artifact construction.

This may improve correctness at the artifact boundary without introducing a
second authoring language. It does not make invalid Nix syntax unrepresentable,
but it may deliver the more important guarantee that invalid configurations
cannot become artifacts or reach drivers.

### E. Multiple first-class authoring languages

Several frontends compile to one canonical manifest and build interface.

This must be treated as a high-cost option. It is acceptable only if the
canonical contract is demonstrably independent of every frontend and the
maintenance cost is justified by distinct user audiences.

It should not be selected merely to avoid choosing one initial surface.

## Candidate Systems

At minimum, evaluate:

- **Nix modules plus product constructors and validators** — mandatory
  baseline;
- **Nickel** — contract-oriented configuration with record merging and a
  Nix-adjacent design;
- **CUE** — constraint/unification-oriented configuration and validation;
- **Dhall** — total, typed functional configuration with normalized values;
- **Pkl** — schema-oriented programmable configuration;
- **Jsonnet** — composition-oriented control candidate that demonstrates what
  dynamic configuration does and does not solve;
- **a purpose-built typed DSL embedded in a systems language** — cost ceiling
  and maximum-static-guarantee control;
- **schema-only gates** such as JSON Schema or equivalent versioned wire-schema
  validation — boundary-strength control.

Other candidates may be added only when they address a concrete criterion not
covered by this set.

The research must not assume that "more static typing" automatically produces a
better configuration product. Merge semantics, diagnostics, ecosystem,
interoperability, and the ability to express controlled native extensions are
equally important.

## Invalid-State Corpus

Every candidate must process the same corpus. Results must include the exact
error output and the phase in which each case fails.

The corpus intentionally spans the complete product pipeline. An Artifact
Definition frontend directly evaluates only Artifact-owned cases. A shared
test harness supplies `CreateSandbox`, Operator Configuration, host-preflight,
and driver inputs for cases owned by those layers. Each candidate must preserve
the owner and report the earliest correct failure phase; it must not absorb
creation, operator, framework, or host configuration into Artifact authoring.

### Structural invalidity

- mount destination is relative;
- duplicate logical slot names;
- malformed byte quantity or duration;
- secret value supplied where only a secret slot is legal;
- empty command where a non-empty argv is required;
- unknown target capability or schema version.

### Sum-type invalidity

- workspace simultaneously requests live and copy-in materialization;
- storage entry is both ephemeral and externally named;
- snapshot requests memory but omits device/external-state semantics;
- network mode is none while an egress allowlist is also supplied;
- a volume is both immutable artifact content and a runtime writable binding.

### Cross-resource invalidity

- creation allocation is below the Artifact minimum;
- creation access widens the Artifact policy;
- read-only workspace resolves to a writable share or device;
- secret delivery targets the Nix store or immutable image;
- runtime host path appears in Artifact Definition;
- provider credential appears in `CreateSandbox`;
- framework lifecycle configuration appears in the Artifact.

### Cross-target invalidity

- Artifact requires a live virtiofs workspace while supporting only
  Firecracker, which must fail during Artifact evaluation;
- creation selects Firecracker plus a live workspace from an Artifact that
  permits multiple materializations, which must fail during creation
  resolution;
- memory snapshot required from a profile that has not passed snapshot
  conformance;
- a capability is mandatory but unsupported by one enabled target;
- target-native configuration contradicts common network policy;
- one target silently ignores a required resource ceiling;
- a target-specific addition changes the common environment semantics.

### Composition invalidity

- two imported modules select incompatible workspace modes;
- a later module attempts to weaken a hard network policy;
- a profile and explicit field conflict;
- two modules define the same slot with incompatible types;
- a native guest module attempts to set host shares or interfaces;
- an unsafe extension attempts to claim full conformance.

### Valid advanced cases

The corpus must also prove that stronger typing does not reject necessary
expressiveness:

- reusable modules refining minimum and maximum resource bounds;
- multiple named, visible profiles;
- two target artifacts sharing one common environment;
- arbitrary guest NixOS services that do not affect host/runtime ownership;
- target-specific artifact additions that preserve common policy;
- separately scoped runtime/provider extensions;
- user-defined library modules with clear provenance.

## Prototype Requirements

Each serious candidate must implement the same thin vertical slice:

1. Define an environment containing packages, environment variables, and an
   explicit activation entry.
2. Select a visible profile and expand it completely.
3. Define workspace materialization and access.
4. Define network policy.
5. Define one secret slot.
6. Enable bubblewrap and the Firecracker runtime profile as supported Artifact
   targets.
7. Reject during Artifact evaluation a definition that requires a live
   workspace while supporting only Firecracker.
8. Accept an Artifact that permits copy-in and rejects during creation
   resolution a later Firecracker-plus-live binding.
9. Accept a Firecracker creation using copy-in workspace materialization.
10. Produce the same canonical manifest representation.
11. Hand that representation to a trivial Nix builder that references a real
    Nix package.
12. Allow a separately scoped guest NixOS module without allowing it to set a
    host share.
13. Report provenance for all expanded values.

The prototype is not a production compiler. It exists to expose composition,
interop, diagnostic, and maintenance costs using executable evidence.

## Evaluation Matrix

Score every serious candidate against:

| Criterion | Required evidence |
|---|---|
| Invalid-state prevention | Corpus pass/fail phase and exact diagnostics |
| Closed unions and refinement | Executable examples, not feature claims |
| Composition semantics | Conflicting and compatible import examples |
| Error quality | Source spans across imports and generated boundaries |
| Nix interoperability | Real package/derivation/dev-shell references |
| Native NixOS escape hatch | Working guest module plus rejected boundary violation |
| Determinism and purity | Evaluation behavior and import pinning |
| Expanded-value inspection | Canonical output and per-field provenance |
| Tooling | Formatter, LSP, tests, docs, editor and CI integration |
| Distribution | Binary/runtime footprint and bootstrap path |
| Ecosystem maturity | Release cadence, compatibility policy, governance |
| Security | Import model, execution surface, secret leakage risks |
| Schema evolution | Forward/backward compatibility exercise |
| Implementation burden | Compiler/adapter code and owned failure modes |
| User ergonomics | Complete authoring and error-recovery transcript |
| Product coherence | Whether Nix remains understandable and central |

Correctness is the highest-weight category, but correctness includes
understandable failures and one authoritative configuration, not only static
expressiveness.

### Locked scoring weights

The weights are fixed before external findings or prototype results are scored:

| Category | Weight |
|---|---:|
| Semantic correctness and invalid-state prevention | 25 |
| Composition, refinement, and conflict behavior | 15 |
| Nix interoperability and native guest configuration | 15 |
| Diagnostics, source locations, and value provenance | 10 |
| Determinism, import pinning, and evaluation security | 10 |
| Implementation and ongoing maintenance burden | 10 |
| User ergonomics and product coherence | 10 |
| Ecosystem maturity and tooling | 5 |
| **Total** | **100** |

Each category is scored from 0–5 using evidence from the common corpus and
vertical slice. The weighted score is useful for comparison but cannot override
a knockout failure.

### Knockout criteria

A candidate is not viable as the initial authoring surface if it:

- cannot preserve the locked Artifact/Create/Operator/Managed-Service ownership
  boundaries;
- cannot produce the canonical, versioned Artifact specification without
  generated textual Nix as an unavoidable semantic interface;
- cannot pin all semantic imports and evaluate deterministically;
- requires secret values or current-host bindings during immutable artifact
  evaluation;
- cannot preserve a separately scoped, externally validated native NixOS guest
  module boundary;
- permits later composition to silently weaken hard policy without a detectable
  failure;
- requires the runtime drivers to understand source-language-specific values;
- lacks a credible versioning and distribution path for reproducible builds;
- would require independently duplicating the product's semantic rules in two
  authoritative implementations.

Knockout findings require an executable reproducer or direct primary-source
evidence. Popularity, aesthetics, or unfamiliarity are not knockout reasons.

### Evidence grades

Every matrix entry records one of:

- **E3 — executable:** demonstrated by the common corpus or vertical-slice
  prototype;
- **E2 — primary:** directly supported by maintained official documentation,
  language specification, or source;
- **E1 — secondary:** supported only by credible independent analysis;
- **E0 — assertion:** unsupported claim, excluded from scoring.

Material correctness claims require E3 evidence before the ADR is approved.

## Required Deliverables

The research phase produces:

1. a source-backed survey of the candidate systems;
2. a locked invalid-state corpus;
3. a machine-readable invariant registry with exact corpus coverage, owners,
   phases, dispositions, witnesses, planned enforcement hooks, tests, and
   diagnostic obligations;
4. an approved Gate 2A inventory review over every supported state space,
   boundary, target, lifecycle operation, composition path, and escape
   mechanism;
5. executable prototypes for the baseline and serious candidates;
6. an approved Gate 4B enforcement-closure report linking every in-scope
   invariant to concrete hooks and executable evidence;
7. exact evaluation and error transcripts;
8. a weighted comparison matrix;
9. a boundary diagram for every viable architecture;
10. an estimate of implementation and ongoing maintenance cost;
11. a recommendation with explicit rejected alternatives;
12. an ADR locking the source-language and canonical-intermediate-representation
   decision;
13. a migration story if additional frontends may be added later.

## Execution Order

The research executes in this order:

1. **Primary-source sweep** — establish current language semantics, composition,
   contracts/types, import pinning, tooling, release health, and Nix
   interoperability without scoring conclusions.
2. **Corpus lock** — translate every invalid and valid case into
   language-neutral fixtures with one expected owning layer and earliest sound
   failure phase.
3. **Gate 2A: invariant inventory and representation review** — complete the
   machine-readable registry, walk every supported state space and bypass path,
   classify each rule as by-construction exclusion, boundary rejection,
   dynamic preflight, or observed conformance, and freeze its hook, test, and
   diagnostic obligations.
4. **Baseline prototype** — implement strengthened Nix modules plus canonical
   manifest validation first so alternatives are compared against the best Nix
   design, not a strawman.
5. **Alternative spikes** — implement the same vertical slice in every
   candidate that survives source-research knockout checks. At minimum, the two
   strongest non-Nix candidates receive executable spikes.
6. **Gate 4B: enforcement closure** — prove every in-scope registry entry has
   an authoritative hook, defensive trust-boundary validation, applicable
   positive/negative/bypass/target evidence, and executable diagnostic
   assertions. No planned or untraced v1 rule may remain.
7. **Blind transcript review** — compare authoring, error recovery, expanded
   configuration, and provenance without language names where practical.
8. **Scoring** — score only evidenced behavior using the weights above.
9. **Adversarial review** — challenge the leading recommendation for hidden
   dual sources of truth, unsound native escape hatches, migration traps, and
   underestimated maintenance.
10. **ADR** — lock the authoring language, canonical representation, Nix
   boundary, native guest-module boundary, error model, and frontend-extension
   posture.

The primary-source sweep may run concurrently across candidates. Prototype
implementation begins only after the corpus's ownership and expected failure
phases are locked and Gate 2A is closed. Blind review and scoring begin only
after Gate 4B is closed.

## Decision Rules

A non-Nix authoring language should be selected only if it demonstrates a
material correctness or usability advantage that survives the full vertical
slice.

In particular:

- syntax-level unrepresentability alone is insufficient if native Nix
  integration becomes opaque or two sources of truth appear;
- better error messages and safer composition may justify a frontend even when
  it ultimately performs validation rather than literal syntactic exclusion;
- a canonical manifest boundary is required regardless of source language;
- runtime host facts remain preparation-time concerns regardless of source
  language;
- no candidate may place secrets or current-host bindings into immutable Nix
  evaluation;
- no candidate may weaken the locked configuration ownership model;
- no candidate is chosen because it is novel or aesthetically attractive.

If no alternative materially outperforms the Nix baseline, the product keeps
Nix modules and invests in constructors, final validation, diagnostics, and
strong runtime types.

## Implementation Gate

Do not lock or implement the final public Artifact Definition syntax until this
research phase and ADR are complete.

Candidate prototypes may not be promoted to scoring evidence until the
[Invariant Inventory and Enforcement Protocol](./research/INVARIANT-ENFORCEMENT.md)
has closed Gate 2A and Gate 4B. A passing subset of fixtures is not a substitute
for exact registry coverage or enforcement traceability.

Permitted before the decision:

- language-neutral manifest/schema work;
- invalid-state corpus definition;
- throwaway prototypes;
- target capability modeling;
- runtime API and driver-boundary research that does not assume a source
  language.

Not permitted before the decision:

- declaring Nix modules, Nickel, or another language the permanent authoring
  surface;
- publishing stable option names;
- allowing an implementation prototype to become the de facto public schema;
- duplicating semantic rules independently in multiple frontends.

## Open Decision

The research must ultimately choose:

1. the initial Artifact Definition authoring language;
2. the canonical typed/intermediate representation;
3. the boundary between authoring evaluation and Nix artifact construction;
4. the supported native NixOS-module escape hatch;
5. the error/provenance model;
6. whether future additional frontends are supported by design or explicitly
   deferred.
