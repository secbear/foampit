# Configuration-Language Primary-Source Review

Status: **Source sweep complete enough to lock the executable corpus; no
language decision**

This document reviews and corrects the broad research report in
[`configuration-language-primary-source.md`](./configuration-language-primary-source.md).
That report is retained as source discovery, not accepted as a recommendation
or scoring result.

The product question is not which language has the most impressive feature
list. It is whether any authoring frontend materially outperforms a deliberately
strengthened Nix baseline while preserving:

- one authoritative Artifact semantic model;
- Nix-native packages, derivations, dev shells, and guest NixOS modules;
- the locked Artifact/Create/Operator/Managed-Service ownership boundaries;
- reproducible evaluation and pinned semantic inputs;
- source-located failures and inspectable provenance;
- target-capability rejection before an invalid value reaches a driver.

## Evidence Policy

This review records only:

- **E2** facts supported by maintained specifications, official documentation,
  or upstream source;
- explicit **unknowns** that require the common executable prototype (**E3**).

No candidate is scored here. Feature availability is not evidence that the
feature composes safely in this product.

The primary sources used in this pass are:

- the NixOS module manual and Nixpkgs module-system behavior;
- the [CUE specification](https://cuelang.org/docs/reference/spec/), [module
  reference](https://cuelang.org/docs/reference/modules/), and
  [`cue export` reference](https://cuelang.org/docs/reference/command/cue-help-export/);
- the Nickel manuals for
  [correctness](https://nickel-lang.org/user-manual/correctness/),
  [contracts](https://nickel-lang.org/user-manual/contracts/),
  [merging](https://nickel-lang.org/user-manual/merging), and
  [package management](https://nickel-lang.org/user-manual/package-management/);
- the Dhall [language tour](https://docs.dhall-lang.org/tutorials/Language-Tour.html),
  [safety guarantees](https://docs.dhall-lang.org/discussions/Safety-guarantees.html),
  and [import
  standard](https://github.com/dhall-lang/dhall-lang/blob/master/standard/imports.md);
- the Pkl [language
  reference](https://pkl-lang.org/main/current/language-reference/index.html)
  and [threat model](https://pkl-lang.org/threat-model.html).

The saved deep-research artifact contains additional references, including
secondary and irrelevant results. Those references do not inherit E2 status
merely by appearing in that report.

## Packet D pin set

The exhaustive composition-path review uses the dated source coordinates in
[`PACKET-D-RESEARCH-NOTES.md`](./invariants/PACKET-D-RESEARCH-NOTES.md):

- `NIX-MODULE-SYSTEM-2026-07-24`;
- `CUE-SPEC-2026-07-24`;
- `NICKEL-MERGE-CONTRACTS-2026-07-24`;
- `PKL-LANGUAGE-EXTERNAL-READERS-2026-07-24`;
- `DHALL-STANDARD-2026-07-24`;
- `JSON-RFC-IJSON-JCS-2026-07-24`; and
- local authority `PACKET-C-TARGET-CONTRACTS-2026-07-24`.

These pins add one important correction to the earlier baseline: a final
merged Nix value does not, by itself, prove the composition history. Nix
exposes the winning priority, and a priority numerically lower than
`mkForce` can discard the ordinary contribution before option-type merge.
The supported frontend must therefore reject unauthorized winning priorities
for security-sensitive option families and preserve the required contribution
ledger. Renderer output and renderer-to-wire adaptation remain separate,
untrusted paths.

## Corrections to the Broad Report

### 1. Nix does not silently choose between ordinary conflicting scalars

The report repeatedly characterizes normal Nix-module composition as
last-writer-wins or silently weakening by default. That is wrong.

Nix option definitions have priorities. Definitions at worse priorities are
discarded; definitions remaining at the winning priority are merged according
to the option type. Equal-priority conflicting non-mergeable scalar definitions
fail evaluation. `mkForce` is an explicit priority operation, not the default
behavior. The [NixOS module
manual](https://nixos.org/manual/nixos/stable/#sec-option-definitions-setting-priorities)
documents that lower numeric priority wins and that `mkForce` is
`mkOverride 50`.

The actual Nix risk is narrower and more actionable:

- a downstream module can deliberately use a stronger override priority;
- permissive types such as `anything`, overly broad `attrsOf`, or an
  inappropriate `freeformType` can erase useful structural checks;
- `_module.check` and the absence of a freeform type help reject undeclared
  fields but are not a security boundary;
- `readOnly` and a final validator can prevent or detect multiple definitions,
  but arbitrary trusted Nix modules can still execute arbitrary Nix language
  code;
- assertions are evaluated checks with textual errors, not proof objects or a
  structured diagnostic protocol;
- lazy evaluation means the validation entrypoint must deep-force the complete
  normalized value.

Therefore the baseline must use closed product-owned module types, product
constructors, final validation over the fully merged result, and a deliberately
forced canonical boundary. It must not expose an unbounded module graph as a
hard-policy security boundary.

### 2. Target compatibility does not require a refinement-type language

The report claims that a Firecracker/live-workspace conflict would be discovered
only when a VM fails to boot if Nix modules are used. That is false.

The Artifact evaluator can hold a target-capability matrix and reject:

```text
required workspace capability
∉ intersection(capabilities of every enabled target/profile)
```

during Nix evaluation. The same invariant can be evaluated by CUE, Nickel,
Dhall, Pkl, or a systems-language validator. A refinement-oriented language may
make the rule easier to compose or harder to omit, but it is not required to
express or evaluate the rule before construction.

The executable comparison must therefore measure:

- whether the rule is structurally attached to every construction path;
- whether later composition can bypass it;
- where the error points;
- whether one semantic implementation or two must be maintained.

It must not award a candidate points merely for using the word "refinement."

### 3. Artifact evaluation does not have to run without Nix

The broad report introduces an unstated requirement that the Artifact
specification be evaluable without invoking Nix. The locked product design has
no such requirement.

Interactive latency and non-Nix inspection are legitimate usability metrics,
not architectural requirements. They must be measured using the same cold and
warm workflow. A claim that Nix evaluation is too slow is E0 until measured.

### 4. "Compile time" is not a sufficient phase description

All candidates parse and evaluate authoring programs. Their enforcement phases
differ:

- Nix option types and assertions fail during forced module evaluation;
- CUE constraints fail when the relevant value is unified/made concrete or
  exported;
- Nickel has static types plus lazy runtime contracts; a delayed contract may
  run only when a field is demanded or exported;
- Dhall type-checks and normalizes a total expression; `assert` checks
  judgmental equality during type checking;
- Pkl type constraints are evaluated as part of module evaluation.

The corpus must name observable product phases rather than flattening these
into "compile time":

1. source parse;
2. source type/contract evaluation;
3. Artifact normalization and final validation;
4. canonical-wire validation;
5. Nix artifact evaluation/construction;
6. `CreateSandbox` resolution;
7. operator admission and host preflight;
8. driver preparation;
9. runtime launch.

The expected result is the earliest **sound** failure phase owned by the
product, not whichever language-internal label sounds strongest.

### 5. JSON output is not automatically a canonical wire representation

`cue export` emits JSON by default and rejects incomplete values, but CUE does
not specify RFC 8785 canonical JSON or stable field ordering. An upstream
[canonical-JSON
discussion](https://github.com/cue-lang/cue/discussions/1285) explicitly notes
the absence of field-order guarantees.

The same caution applies to every frontend serializer. The product must own:

- the versioned canonical schema;
- semantic normalization;
- a specified byte encoding or a content hash computed from a canonical
  representation;
- duplicate-key rejection and numeric/string normalization rules;
- golden cross-version tests.

Source-language serialization is an input to that canonicalizer, not the
canonicalization contract itself.

### 6. A structured wire boundary does not inherently duplicate semantics

A frontend that emits structured data and a Nix consumer that decodes it does
not automatically require two authoritative validators.

The clean architecture is:

1. source frontend evaluates source-language composition and produces a typed,
   versioned Artifact value;
2. a single product-owned normalization/validation implementation converts that
   value to the canonical wire representation;
3. Nix construction consumes only the validated wire representation and checks
   representation integrity/version, not an independently reimplemented copy of
   every product rule;
4. runtime implementations deserialize generated target-specific types and do
   defensive checks at their trust boundary.

Whether a candidate can support that architecture cleanly is an E3 question.
The prototype must count duplicated rules, not assume duplication from the
presence of JSON.

### 7. Generated textual Nix is not an "upgrade path"

The research gate already rejects generated textual Nix as an unavoidable
semantic interface. It creates injection, source-map, formatting, and debugging
problems without improving the language-neutral runtime contract.

Native Nix values may cross an internal, typed Nix API where necessary. The
portable Artifact representation must remain structured. Generated Nix source
is excluded unless a later ADR identifies a capability that structured
interchange provably cannot carry.

## Verified Candidate Facts

### Strengthened Nix modules

E2 findings:

- Ordinary conflicting non-mergeable values at the same winning priority fail;
  Nix is not generally last-writer-wins.
- Override priorities are explicit, but a sufficiently strong override can
  discard earlier definitions.
- Typed options, enums, submodules, `readOnly`, and final assertions can reject
  every known Artifact-owned corpus invariant during evaluation.
- Closed algebraic data types are not first-class Nix language constructs.
  They can be represented with tagged submodules/constructors and a final
  validator, with more boilerplate than in languages with native sums.
- The module system tracks definition/declaration locations, but assertion
  errors are strings and cross-field provenance requires product work.
- Arbitrary author-supplied Nix is trusted code. Module priorities cannot make
  a hostile module safe.
- Native Nix packages, derivations, flake inputs, dev shells, store paths, and
  NixOS guest modules require no foreign encoding.

E3 obligations:

- demonstrate a closed public constructor surface rather than direct
  free-form option mutation;
- deep-force all validation and prove invalid values cannot reach artifact
  construction;
- emit a structured diagnostic with owner, invariant, source definitions, and
  remediation;
- retain provenance for defaults, profiles, and explicit definitions;
- show that hard policy cannot be weakened through the supported composition
  API even though trusted internal modules retain escape hatches;
- measure cold/warm edit-to-diagnostic latency.

### CUE

E2 findings:

- Values and types occupy one constraint lattice.
- Unification is order-independent; incompatible concrete constraints produce
  bottom/error rather than choosing a winner.
- Definitions recursively close structs; ordinary structs are open unless
  closed explicitly. Embedded values and closedness have subtleties that must
  be exercised.
- Disjunctions and defaults can represent alternatives, but export requires a
  concrete value.
- `cue export` rejects incomplete values and emits JSON by default.
- CUE modules are versioned, use minimal version selection, and are distributed
  through OCI-compatible registries. `module.cue` records dependency versions.
- CUE export is not itself a specified canonical-byte contract.
- Source errors can report all conflicting locations, including schema and
  data sites.

E3 obligations:

- model the Artifact sums without accidentally leaving embedded/open fields;
- prove that reusable profiles only add constraints and that defaults do not
  hide a conflict;
- determine how product-specific errors and provenance survive unification;
- pin the complete module graph in the Nix build, including registry content
  digests rather than version labels alone;
- canonicalize frontend output independently of `cue export` ordering;
- encode Nix package/dev-shell references without reducing them to mutable
  strings or permitting arbitrary Nix source injection;
- test schema evolution and source mapping across the CUE-to-wire-to-Nix
  boundary.

### Nickel

E2 findings:

- Nickel provides static types and runtime contracts. Its own manual states
  that interpreted evaluation has no single ahead-of-time phase in which all
  errors are detected.
- Record contracts are closed by default; open record contracts are explicit.
- Contracts may be delayed by laziness and execute when a field is demanded or
  exported. Forcing/exporting the full Artifact is therefore required.
- Symmetric record merge recursively combines equal-priority definitions and
  rejects unequal non-mergeable scalars.
- `default`, numeric `priority`, and `force` explicitly choose winners.
- Contracts attached to a field survive subsequent merges and validate the
  resulting value.
- Validators can supply messages, notes, and blame locations.
- Package management is explicitly experimental and disabled in standard
  Nickel releases as of this source pass.

E3 obligations:

- deep-force every exported field and prove no delayed contract is skipped;
- distinguish trusted product defaults from an author-accessible `force`;
- prove that the supported composition API cannot silently weaken a hard
  contract;
- decide whether semantic imports are pinned entirely by the Nix flake/closure
  or require Nickel's experimental package feature;
- verify deterministic output and implement product canonicalization;
- quantify source-map and provenance quality after merging;
- encode Nix-native references and guest-module handles without textual code
  generation.

Nickel remains a serious semantic candidate, but its package state materially
increases distribution and maintenance risk.

### Dhall

E2 findings:

- Dhall is total and strongly typed, with first-class union types and exhaustive
  handlers.
- Imports can be frozen using semantic SHA-256 hashes over normalized,
  transitively resolved expressions. Integrity failure is mandatory.
- Recursive record merge fails when non-record fields collide.
- Dhall also deliberately provides shallow right-biased record preference
  (`//`) and `with` updates, including updates that change a field's type.
  Therefore "Dhall forbids overlaps" is false without a constrained product API.
- `assert` checks judgmental equality. Concrete cross-field predicates can be
  reduced to a Boolean and asserted equal to `True`; this is evaluation, not a
  general refinement-type system.
- Source failures include spans and assertion diffs.
- `dhall-to-nix` exists and is maintained, but direct translation to Nix source
  is not automatically the desired product boundary.

E3 obligations:

- prevent right-biased preference/`with` from bypassing hard policy within the
  supported authoring API;
- determine whether ergonomic constructors can enforce all cross-field rules
  without requiring every author to thread proof/assertion values manually;
- preserve semantic import hashes while the source is vendored/built by Nix;
- emit the same canonical product wire format rather than treating normalized
  Dhall or generated Nix as the public contract;
- measure diagnostics and profile-composition ergonomics.

Dhall is the strongest determinism/import-integrity control, not automatically
the strongest policy-composition candidate.

### Pkl

E2 findings:

- Typed objects, classes, union types, and arbitrary Boolean type constraints
  can model structural and cross-field rules.
- An amending module retains the amended module's type and cannot add non-local
  properties, methods, or classes. A module cannot both amend and extend.
- Dynamic objects are explicitly schema-less and unvalidated; the public
  Artifact path must exclude them.
- The evaluator client owns module/resource allowlists. Pkl code cannot expand
  its own permissions, and allowlists apply transitively.
- Pkl cannot execute arbitrary system commands or load native code through the
  language runtime.
- Remote packages can be SHA-256 verified through `PklProject.deps.json`, an
  explicit project checksum, or a checksum in the package import URI. Resolved
  lock data without a predeclared checksum is trust-on-first-use; direct
  checksum-less package imports are not integrity verified.
- Pkl has no built-in CPU or memory sandbox controls; untrusted evaluation needs
  external resource isolation.
- Pkl is Turing complete and handles nontermination through evaluator timeouts.

E3 obligations:

- exclude dynamic/untyped escape hatches from the Artifact constructor;
- show whether `amends`, `extends`, `open`, `fixed`, and constraints produce
  understandable hard-policy composition;
- require explicit checksums rather than accepting TOFU or checksum-less direct
  imports;
- run evaluation inside a product-owned resource sandbox;
- canonicalize output independently of renderer formatting;
- prove Nix package/dev-shell and guest-module interoperability without a
  second semantic schema;
- measure the JVM/native evaluator closure and operational burden.

The report's characterization of Pkl as lacking import integrity was incorrect.
Pkl remains a serious candidate, with evaluator resource isolation as a
first-class prototype cost.

### Jsonnet, JSON Schema, Starlark, KCL, and a custom DSL

These remain controls or watch-list candidates, not initial full-slice
front-runners:

- **Jsonnet** is useful as a dynamically typed composition control. It does not
  directly address the central invalid-state and hard-policy goal.
- **JSON Schema** is useful as a portable wire-format validation control. It
  does not provide the desired authoring/composition system or provenance by
  itself.
- **Starlark** provides deterministic restricted evaluation, but no native
  schema/refinement system. The product would own that system on top.
- **KCL** has relevant schemas and checks and deserves a source-level watch-list
  entry, but no verified advantage over the current serious candidates yet
  justifies expanding the full prototype set.
- **A custom typed DSL** is the maximum-control/cost ceiling. It is not an
  initial implementation candidate because the product would own a parser,
  evaluator/type checker, formatter, LSP, package system, compatibility
  policy, and Nix bridge before proving the sandbox product.

Any watch-list candidate is promoted only if it supplies a concrete capability
missing from the serious set, not because it is newer or popular in a neighboring
domain.

## Architecture Conclusions From E2 Evidence

These conclusions are now stable enough to design the corpus and prototypes:

1. **No existing candidate makes every invalid Artifact syntactically
   unwriteable.** Constructors, module APIs, contracts, assertions, or final
   validation remain necessary in every system.
2. **The real guarantee is that no invalid value can cross the validated
   Artifact boundary.** Syntax-level exclusion is valuable only where it
   improves that guarantee and its diagnostics.
3. **The canonical representation is product-owned.** It is not CUE JSON,
   Nickel JSON, normalized Dhall, Pkl output, or a Nix attribute set by accident.
4. **One semantic implementation is mandatory.** Frontend-specific parsing and
   composition may differ, but the normalized Artifact invariant set cannot be
   independently rewritten in every frontend and again in Nix.
5. **Nix construction must not re-run a competing policy engine.** It consumes a
   validated Artifact value, verifies schema/version/integrity, and performs
   Nix-native construction checks.
6. **Native NixOS guest modules remain Nix modules.** They are separate,
   resource-scoped Artifact extensions and are evaluated after the portable
   definition, with product assertions that prevent them from claiming
   host/runtime ownership.
7. **Hard policy is a meet/refinement operation, never an ordinary override.**
   If a language exposes override operators, the product API must keep those
   operators outside hard-policy composition or detect any widening in the
   final validator.
8. **All frontend outputs are deeply forced and canonically encoded.** Lazy or
   incomplete values cannot enter the wire representation.
9. **Dependency integrity is end-to-end.** Source packages, language modules,
   the evaluator/compiler, Nix inputs, and canonical-schema versions are all
   pinned. A version label without immutable content identity is insufficient.
10. **Runtime host facts remain outside this decision.** A language cannot
    statically know current KVM availability, provider quota, host mount
    existence, or credential validity. Those fail at operator admission,
    preflight, or preparation with the Artifact invariant attached.

## Provisional Prototype Set

The baseline and serious non-Nix prototype set is:

1. **Strengthened Nix modules** — mandatory baseline.
2. **CUE** — strongest order-independent constraint/unification candidate.
3. **Nickel** — strongest Nix-adjacent contract and symmetric-merge candidate.
4. **Pkl** — strongest class/template, constrained-type, and evaluator-policy
   candidate.

Dhall receives a focused executable control covering totality, semantic import
hashing, unions, recursive collision, right-biased update, and cross-field
assertion. It is promoted to the complete vertical slice if that control shows
an ergonomic way to prevent hard-policy bypass through the public API.

This ordering is not a preference ranking. It maximizes the distinct semantics
tested:

| Candidate | Distinct hypothesis |
|---|---|
| Strengthened Nix | One language and native interop can match alternatives with a closed constructor/final-validator design |
| CUE | Constraint unification makes compatible composition and conflict rejection materially safer |
| Nickel | Contracts plus symmetric merge give better policy diagnostics without losing Nix-adjacent ergonomics |
| Pkl | Typed templates and constrained objects give the best practical authoring surface with enforceable evaluator permissions |
| Dhall control | Totality and semantic import hashes outweigh weaker refinement ergonomics |

## Required E3 Measurements

Every complete slice must report:

- exact source, command, exit status, stdout, and stderr for every corpus case;
- the earliest product phase at which the case fails;
- whether every source field was forced;
- normalized value and canonical byte hash for valid cases;
- field-level provenance after defaults, profiles, imports, and explicit values;
- the number and location of semantic rules implemented;
- any rule duplicated across frontend, canonicalizer, Nix, and runtime;
- cold and warm parse-to-diagnostic and parse-to-canonical-output latency;
- evaluator/compiler closure size and process count;
- semantic-import resolution with the network unavailable after pinning;
- one real Nix package, derivation/store path, dev shell, and guest NixOS module;
- one rejected guest-module ownership violation;
- schema-version upgrade and downgrade behavior;
- stable diagnostics across a source import boundary.

The prototype must distinguish:

- **language capability** — the language can encode the rule;
- **product guarantee** — every supported construction path necessarily invokes
  the rule;
- **trust-boundary defense** — a later layer defensively rejects a corrupted or
  incompatible value.

Only the second is evidence that an invalid Artifact cannot be produced.

## Source-Sweep Exit Check

The source sweep is complete enough to proceed when:

- no recommendation from the broad report is treated as scored evidence;
- the corrections above are represented in the corpus expectations;
- every serious candidate has explicit E3 obligations;
- the corpus uses product phases and owners rather than language marketing
  terms;
- no public Artifact option names or syntax are locked by the prototypes.

Those conditions are now met. The next artifact is the language-neutral,
executable invalid-state corpus.
