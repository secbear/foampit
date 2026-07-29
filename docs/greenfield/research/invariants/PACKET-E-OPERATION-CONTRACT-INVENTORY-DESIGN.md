# Packet E: Machine-Readable Operation Contract and Inventory Architecture

Status: **Locked architecture — inventory implementation and exhaustive review
remain required**

Date: 2026-07-28

## Decision

Packet E will be represented by a product-owned, language-neutral semantic
catalog that normalizes into one canonical `ContractModel`. The semantic
catalog, not TypeSpec, JSON Schema, CUE, generated code, a transport schema, or
a provider API, owns Core lifecycle and control meaning.

The catalog covers the already named Packet E lifecycle and control surface.
Packet A continues to own file, directory, transfer, endpoint, and port method
semantics. Those methods still participate in Packet E concurrency coverage as
opaque, revision-bound foreign references. Packet F continues to own evidence
collection, redaction, disclosure, and secret-safe presentation. Packet E owns
which provider-neutral proof is required, which inferences are forbidden,
authorization-before-existence-sensitive validation, and the public outcome
that follows.

The semantic and coverage pipeline has four distinct products:

1. `PacketEScopeManifest` independently fixes what must be covered.
2. `CoreContractCatalog` is the sole authored semantic authority.
3. `ContractModel` is the canonical normalized compiler and runtime input.
4. `CoverageLedger` is generated verification evidence and has no runtime
   authority.

`ContractModelInterpreter` is a pinned compiler/runtime implementation of the
catalog-owned formal denotation, not a fifth authored authority. Kernel-checked
equivalence, exact field reachability, totality, and mutation checks prohibit
independent meanings or defaults in its clauses.

Auxiliary verification and governance artifacts include the interaction
manifest, review baseline, semantic change records, witnesses, explanation
map, proof assumptions, transition-oracle vocabulary/rules, assurance change
records, backend semantic trials, Packet C conformance-protocol bindings,
backend measurements/evaluations, and generated review/conformance reports.
They do not add semantic authorities or expand the four-product pipeline.

No generated completeness claim may define the universe it measures.

## Scope

### Packet E-owned methods

The initial scope manifest contains these 32 public Core methods:

| Family | Methods |
|---|---|
| Portable lifecycle | `CreateSandbox`, `StartSandbox`, `StopSandbox`, `DeleteSandbox`, `TerminateProcess` |
| Execution | `Exec` |
| Sandbox observation | `GetSandbox`, `ListSandboxes`, `WaitSandbox` |
| Operation observation | `GetOperation`, `ListOperations`, `WaitOperation` |
| Process observation | `GetProcess`, `ListProcesses`, `WaitProcess` |
| Snapshot observation | `GetSnapshot`, `ListSnapshots` |
| Process I/O and terminal control | `ReadProcessOutput`, `WriteProcessInput`, `CloseProcessInput`, `ResizeProcessTerminal` |
| Operation cancellation | `CancelOperation` |
| Core-record update | `UpdateSandboxMetadata`, `SetSandboxExpiration` |
| Capability-gated control | `SignalProcess`, `SuspendSandbox`, `ResumeSandbox`, `ResizeSandboxResources`, `CreateSnapshot`, `DeleteSnapshot`, `RestoreSandbox`, `ForkSandbox` |

This list is an exact set. Adding, removing, renaming, or changing the meaning
of a member changes the semantic digest and requires the change protocol
defined below.

System-originated work is separately enumerated as `SystemTriggerContract`
records. A system trigger may initiate or reconcile a named durable Operation,
commit an observation, seal output, or expire retained state. It cannot create
an unnamed public method or bypass the corresponding method's target, epoch,
authority, result, and proof rules.

### Packet A handoff

Packet A owns the payload and result semantics of:

- file and directory operations;
- upload, download, and other transfer operations;
- endpoint and port operations; and
- any future data-plane family explicitly assigned to Packet A.

Packet E imports each closed Packet A method identity with:

- owning packet;
- stable method ID;
- semantic revision;
- catalog digest;
- concurrency participant class; and
- a digest-bound request-to-concurrency-envelope projection yielding the
  normalized target identities, target kind, incoming lane, capability class,
  and state-affecting class needed by Packet E;
- active-action IDs and the method-to-active-action projection required for
  incumbent concurrency coordinates;
- a digest-bound active-action-to-concurrency-envelope projection yielding
  normalized target identities, lane, lifecycle state, and active lifetime;
  and
- review status.

Packet E does not copy the request or result schemas. It classifies both
directions of every Packet E/Packet A concurrency boundary from these typed
envelopes. Packet A validates the projection against its request/action
schemas; Packet E rejects absent, stale, ambiguous, or unverifiable envelopes.
Packet A owns Packet A/Packet A compatibility.

### Packet F handoff

Packet E defines:

- authorization ordering;
- existence-sensitive validation ordering;
- provider-neutral proof predicates;
- evidence freshness and authority requirements;
- forbidden inference;
- outcome observational-equivalence constraints; and
- the Packet F disclosure-class reference required by an outcome.

Packet F defines:

- evidence acquisition and storage;
- secret and personal-data classification;
- redaction;
- diagnostic, log, provenance, trajectory, and evidence visibility;
- audience-specific disclosure; and
- retention or deletion rules whose sole purpose is security or disclosure;
  and
- measurement-acquisition trust policies, acquisition/observer issuer keys,
  harness-artifact correlation, independent execution-control attestation,
  rotation, and revocation; and
- evidence-decoder attestation trust policies, issuer keys, independence,
  rotation, and revocation; and
- conformance-log issuer/witness key custody, authentication, and revocation
  facts imported by Packet E's policy.

Packet F imports are bound by stable ID, semantic revision, and catalog digest.
An in-place Packet F semantic change is a Packet E semantic change whenever it
alters an imported contract.

### Packet B and Packet C handoff

Packet E owns portable Snapshot meaning: component classification, quiescence,
source disposition, identity, ancestry, reference, Process handling, and
uniqueness obligations.

It imports:

- Packet B Artifact Snapshot requirements and immutable identity fields; and
- Packet C capability, runtime-profile, compatibility-domain, and conformance
  identities, including revision/digest-bound protocol bindings and reports.

Target realization, provider bindings, concrete conformance protocols, and
assembled backend reports remain Packet C-owned. Packet E owns the semantic
trial obligation and validates completeness, but cannot claim that a target
implements it. Packet F owns raw measurement/evidence storage and permitted
report disclosure.

## Alternatives rejected

### Extend the TypeSpec prototype directly

The prototype proved that strict source can lower into a canonical model and
drive deterministic projections. It also found unresolved diagnostic
integration and fixed-semantic-literal coupling. Making TypeSpec the inventory
authority now would conflate the semantic review with one replaceable
frontend, and shared omissions could pass both the compiler and its generated
tests.

TypeSpec remains a candidate frontend and projection technology. It does not
define the Packet E universe.

### One monolithic expanded matrix

A single exhaustive file makes each cell visible but duplicates meanings,
encourages copy errors, and makes changes to shared rules difficult to review.
It also does not solve the Goodhart problem: deleting an axis from the same
file shrinks both the claimed universe and the measured output.

Foampit instead uses compact semantic declarations plus independently fixed
coverage families and generated explicit cells.

### Generated coverage as runtime input

The generated ledger is deliberately redundant verification evidence. If a
driver, SDK generator, or runtime consumes it, a verifier artifact becomes a
second semantic authority and can drift from the normalized model.

Only `ContractModel` may feed product code generation or runtime
authorization. `CoverageLedger` is rejected as an input at those boundaries.

## Naming

The following names are locked:

| Name | Meaning |
|---|---|
| `PacketEScopeManifest` | Independently reviewed exact coverage universe |
| `CoreContractCatalog` | Sole authored Packet E semantic authority |
| `MethodContract` | Contract of one public Core API method |
| `SystemTriggerContract` | Contract of one internally originated semantic action |
| `DurableOperationKind` | Kind of a public durable `Operation` resource |
| `SemanticVariantRegistry` | Shared sealed request-error, recovery-error, known-failure, ambiguity, and control-outcome definitions |
| `RecoveryContract` | Call-class-specific replay and recovery coordinate |
| `RetentionPolicy` | Tagged lifetime contract for one subject and clock |
| `EvidenceRequirement` | Provider-neutral proof and forbidden-inference contract |
| `EvidenceDecodingContract` | Core-owned accepted evidence envelope and semantic decoding contract |
| `VerificationDecoderArtifact` | Immutable Packet E-approved implementation of one Core evidence-decoding contract |
| `ProcessCompletionContract` | Durable Process terminal-state, exit-interpretation, and output-sealing contract |
| `ObservationCommitContract` | Atomic internal observation-record commit and visibility contract |
| `AcceptanceCommitContract` | Call-class-tagged atomic acceptance and recovery-binding commit contract |
| `IdempotencyNamespaceContract` | Durable namespace epoch, key-binding history, rotation, and garbage-collection contract |
| `SnapshotClass` | Portable retained-state capability definition |
| `SnapshotCompatibilityContract` | Compatibility and rebinding rules for Snapshot use |
| `CatalogDenotation` | Catalog-owned total formal meaning of exact source schemas, parser, selectors, and profiles |
| `ContractModel` | Canonical normalized semantic model |
| `CatalogNormalizationCertificate` | Full-domain proof that exact catalog sources and canonical model bytes denote the same relation |
| `CatalogNormalizationChecker` | Independently pinned verifier/replayer for normalization proof material |
| `ContractModelInterpreter` | Pinned executable implementation proven equivalent to the catalog-owned formal model denotation |
| `CoverageLedger` | Generated verification-only explicit/symbolic coverage inventory |
| `CoverageShardSpec` | Proof-independent coordinate, region, semantic-owner, and comparison-carrier commitment |
| `CoverageShard` | Canonical explicit or symbolic partition of one coverage domain |
| `FamilyInstanceUniverse` | Independently derived complete concrete instance algebra for one coverage family |
| `MultiplicityContract` | Catalog-owned semantics of repeated instances for one coverage family |
| `PopulationAbstractionContract` | Catalog-owned concrete-participant to symbolic-aggregate semantics |
| `ParameterizedProofCertificate` | Kernel-checked unbounded population, abstraction, composition, or shard theorem |
| `PacketEReviewBaseline` | Independently approved identities, formulas, symbolic commitments, proof/checker pins, witnesses, and trust policies |
| `InteractionObligationManifest` | Independently reviewed cross-family and aggregate-population interaction requirements |
| `ProofAssumptionSet` | Closed, satisfiable, entailed, non-circular assumptions admitted by verification proofs |
| `TransitionOracleVocabulary` | Independently pinned closed state, action, and coordinate vocabulary for the oracle |
| `TransitionOracleRules` | Independently authored transition and postcondition rules |
| `SemanticComparisonCarrier` | Independently pinned canonical coordinate and full semantic-relation representation shared only for verification |
| `SemanticChangeRecord` | Predecessor-bound explanation of every semantic digest change |
| `AssuranceChangeRecord` | Predecessor-bound explanation of every verification-only digest change |
| `BackendSemanticTrialSet` | Packet E-owned semantic witnesses and trial obligations for a support scope |
| `BackendConformanceProtocolBinding` | Packet C-owned binding from semantic trials to a concrete backend harness and protocol |
| `BackendMeasurement` | Immutable observation for one concrete backend trial realization |
| `BackendConformanceEvaluation` | Independently derived result for one immutable measured trial |
| `SlotEvaluation` | Packet E-derived aggregate over the complete attempt history of one evaluation slot |
| `BackendConformanceReport` | Packet C-owned aggregate report over one trial set and protocol binding |
| `EvaluationEvidenceLog` | Packet E-required, Packet F-protected witnessed append-only sequence of every evaluation attempt, state, and result |
| `EvaluationSlot` | Stable required-trial/repetition key whose head aggregates every admitted attempt |
| `EvaluationAttemptCoordinate` | Immutable pre-execution identity and planned coordinates of one slot attempt |
| `EvaluationAttemptState` | Witnessed mutable phase, lease owner/epoch, and predecessor state of one attempt |
| `SupportEvidenceLog` | Packet C-owned append-only fork-evident sequence of every report summary |
| `CurrentSupportEvidenceView` | Deterministically derived unique current support state per protocol coordinate |
| `ConformanceEvidenceTrustPolicy` | Packet E-owned cross-log publication, quorum-witness, freshness, anti-rollback, and revocation contract |
| `QuorumPublicationReceipt` | Durable threshold proof that one extending log checkpoint committed |
| `WitnessSetTransition` | Old/new-quorum continuity proof for one trust-policy epoch change |
| `MeasurementAcquisitionTrustPolicy` | Packet F-owned measurement issuer, artifact-binding, execution-control attestation, rotation, and revocation contract |
| `EvidenceAttestationTrustPolicy` | Packet F-owned decoder-attestation issuer, independence, key, rotation, and revocation contract |

`MethodContract` is intentionally not named `OperationContract`. `Operation`
already names a durable public resource, while reads, atomic Core-record
updates, Process-control commands, and `Exec` have different result carriers.

No semantic profile, enum member, selector, or policy may be named `default`.
Canonical records express absence and choices explicitly.

## Authority model

### `PacketEScopeManifest`

The scope manifest owns membership, not meaning. It contains exact sets of:

- public Packet E method IDs;
- system-trigger IDs;
- durable Operation kind IDs;
- semantic-variant IDs;
- Snapshot-class IDs;
- recovery-contract IDs;
- acceptance-commit-contract IDs;
- idempotency-namespace-contract IDs;
- retention-policy IDs;
- evidence-requirement IDs;
- evidence-decoding-contract IDs;
- Process-completion-contract IDs;
- observation-commit-contract IDs;
- population-abstraction-contract IDs and multiplicity-domain signatures;
- parameterized-proof-certificate IDs;
- invariant and semantic-rule IDs with revisions;
- partition-contract IDs;
- state and finite-partition axis IDs;
- transition-oracle vocabulary/rule IDs;
- semantic-comparison-carrier ID and schema digest;
- catalog-denotation ID/revision/digest, source-schema/parser digests, and
  selector/profile-semantics digests;
- contract-model-interpreter/parser/extraction-or-translation pipeline and
  extensional-equivalence-certificate IDs, revisions, and digests;
- catalog-normalization-certificate and independent checker IDs/digests;
- catalog-source-field-reachability commitment/checker IDs/digests;
- family-instance-universe IDs/digests;
- multiplicity-contract IDs and expected family bindings;
- proof-assumption-set IDs;
- backend-semantic-trial-set and Packet E evaluator IDs;
- conformance-evidence-trust-policy and Packet E log-witness IDs;
- verification-decoder-artifact IDs/revisions/digests;
- imported Packet F measurement-acquisition-trust-policy IDs;
- imported Packet F evidence-attestation-trust-policy IDs;
- Packet A, Packet B, Packet C, and Packet F imports; and
- required coverage-family definitions.

Each coverage-family definition fixes:

- stable family ID;
- ordered axis IDs;
- expected family kind: `population-bearing` or `logical-only`, which must
  exact-match the referenced catalog-owned `MultiplicityContract`;
- the multiplicity-contract ID/digest;
- for `population-bearing`, one population-abstraction-contract ID and
  multiplicity-domain signature;
- for `logical-only`, structural absence of population axes from ordinary
  products, plus the referenced repetition proof;
- incoming and incumbent participant projections where applicable;
- output classification schema;
- exact expected-cell formula; and
- whether the family is required for Packet E scope closure, Core API closure,
  Gate 4B, or backend conformance.

The manifest is not derived from `CoreContractCatalog`. Exact-set validation
requires the catalog to define every required identity exactly once and no
unregistered identity. The catalog, interaction manifest, partition contracts,
and oracle artifacts must each match their corresponding independently pinned
identity set exactly.

`InteractionObligationManifest` is independently authored alongside the scope
manifest. It maps every stable invariant and semantic rule to:

- the coverage families that own it;
- the exact within-family axis interactions that must exist;
- every required interaction product; and
- one classification for every tuple in the independently pinned candidate
  interaction universe: required product or machine-checked independence.

The candidate universe is constructive:

1. let `N` be the independently pinned exact number of required base
   families;
2. generate every non-empty unordered family subset, using the manifest's
   family-ID order as canonical tuple order;
3. retain every singleton, including every family expected to be
   `logical-only`;
4. attach a symbolic positive-integer multiplicity and referenced catalog
   abstraction to `population-bearing` members; logical-only members have
   multiplicity one only after their catalog classification and repetition
   proof validate; and
5. require exactly `2^N - 1` candidate tuples.

A singleton population-bearing tuple represents same-family aggregate
interaction with multiplicity `>= 2`; the ordinary base-family product owns
the multiplicity-1 case. A singleton logical-only tuple is a required proof
obligation that repetition is non-denotable or reduces semantics-preservingly
to the ordinary multiplicity-one base product. In multi-family tuples each
population-bearing member has multiplicity `>= 1`; a validated logical-only
member has multiplicity exactly one because its singleton proof already
discharges repetition. Thus three or more concurrent `Exec`/control actions,
mixed repeated families, and unbounded runtime populations are not encoded as
duplicate tuple names but as parameterized multiplicity/aggregate axes, while
logical classification grids acquire no meaningless runtime population.

At this revision `N = 19` and the exact logical-only families are
`method-variant-admissibility`, `snapshot-compatibility`,
`transport-projection`, and `domain-partition-totality`. Their classifications
remain provisional until the catalog records and repetition proofs validate;
they do not reduce the universe. The other 15 families are expected
population-bearing. The exact candidate count is 524,287. Direction remains
an axis inside a family, not tuple order. Every candidate must become a
required parameterized product or carry a valid non-interference/composition
proof over all admitted multiplicities. No kind relabeling, known-rule filter,
cost threshold, selected arity bound, fixed concurrency cutoff, or human
omission may shrink this universe or its cardinality domains. If a proof uses
a finite cutoff, it must also prove the induction/symmetry theorem lifting
that cutoff to all larger populations. Solver `unknown`/timeout leaves the
parameterized product required.

Deleting a family, dropping an axis, or failing to bridge two individually
total families therefore changes an independently pinned obligation.

### `ProofAssumptionSet`

Every formal proof consumes one closed assumption set. Each assumption:

- references an authoritative `ContractModel` predicate or a
  revision/digest-bound Packet A/B/C/F import;
- has an independent entailment proof from that authority;
- participates in one joint satisfiability witness for the complete set;
- preserves the full domain bounds pinned by `PacketEScopeManifest`; and
- cannot reference the theorem result, proof status, coverage outcome, or a
  predicate derived from them.

The assumption dependency graph is acyclic. An independent verifier checks
joint satisfiability, per-assumption entailment, domain preservation, and that
every positive, negative, ambiguity, crash, and boundary witness assigned to
the theorem/product coordinate remains denotable. Contradiction, any excluded
witness, an unproved strengthening, a conclusion encoded as an assumption,
stale authority, or solver `unknown`/timeout invalidates the proof.
Verification never applies the principle of explosion to close coverage.

An assumption set declares its purpose. `transition-oracle` and
`oracle-equivalence` assumptions may reference only scope-allowlisted
exogenous wire/domain facts and revision-bound foreign-import invariants. A
machine-computed dependency taint must prove the complete transitive dependency
cone of every hypothesis and imported lemma excludes Core catalog transitions,
semantic variants, outcomes, evidence requirements, postconditions, coverage
classifications, selectors, witness expectations, and proof conclusions.

Every `ContractModel`/oracle carrier-equivalence certificate must use an
`oracle-equivalence` set. Exact model semantics and oracle definitions may
appear only as the two theorem operands; the shard may supply only its region
predicate. No catalog-derived semantic bridge lemma or
outcome/postcondition assumption may enter the proof dependency closure.
Ledger/model projection-faithfulness is a separate certificate and cannot
replace the direct model/oracle theorem. Any tainted, unresolved, or
dynamically computed dependency invalidates the assumption/certificate. Other
formal-proof purposes remain subject to the theorem-conclusion prohibition
above.

Before kernel checking, a declaration-interface verifier extracts every free
proposition, proposition-valued theorem parameter, and externally supplied
local premise from the elaborated certificate. Their canonical identities and
types must exactly equal the complete validated `ProofAssumptionSet`: no
additional proposition, implicit typeclass proposition, unresolved
metavariable, or omitted assumption is permitted. Premises introduced
internally by induction, case analysis, abstraction, simulation, or
composition must be derived from those exact boundary assumptions and closed
definitions, and must be discharged in the proof term or by a fully applied
earlier checked certificate. The verifier rejects an unresolved goal/premise,
an extra proposition parameter, or a certificate whose declared and
elaborated interfaces differ.

External certificate data parameters are restricted to a closed, recursively
proof-free grammar of pinned algebraic data, primitive scalars, and finite
containers with canonical serialized values in the certificate manifest. The
interface verifier recursively rejects any external type with a `Prop`-valued
field or codomain, subtype/refinement proof, dependent proof-carrying pair,
`Exists`/`Nonempty` witness, semantic `Decidable` or other typeclass evidence,
quotient soundness payload, opaque function, or nested structure containing
one. Required decidability and data functions are computed internally from
pinned closed definitions. The finalized certificate constant has no
externally supplied evidence other than the propositions that exactly match
its validated `ProofAssumptionSet`; wrapping an undeclared premise in `Type`
is invalid.

### Transition-oracle artifacts

`TransitionOracleVocabulary` independently pins the closed state, action,
coordinate, effect, and outcome symbols the oracle may consume.
`TransitionOracleRules` independently defines enabledness, transition,
may/must outcome, postcondition, evidence, effect, and observable-order
relations over that vocabulary. Neither artifact is generated from or
permitted to import catalog outcome tables, selectors, coverage
classifications, or witness expectations.

Their stable IDs and digests are part of `PacketEScopeManifest` and
`PacketEReviewBaseline`. Any change requires `AssuranceChangeRecord` and
adversarial re-review. Mutation tests must demonstrate that changing a catalog
outcome alone is rejected, changing an oracle result alone is rejected, and
co-changing them without the required predecessor-bound assurance record is
rejected.

### `SemanticComparisonCarrier`

Ledger/oracle comparison uses one independently pinned representation, not an
informal agreement that two products happen to use similarly named fields.
`SemanticComparisonCarrier` is a closed verification-only schema containing:

- the complete normalized coordinate;
- enabledness and admission classification;
- the ordered admission/validation/commit/dispatch/response gates;
- may- and must-next-state relations;
- may- and must-outcome relations;
- postconditions;
- evidence requirements;
- observable ordering; and
- effects.

For every field the carrier pins the canonical type, tag set, sort order,
normalization rule, and byte encoding. It defines representation only; it
contains no rule selecting a value and owns no Core meaning. The
catalog/ledger semantics and the independently authored oracle rules must each
emit this carrier directly. Their definitions, rules, and dependency closures
remain separate.

If an implementation cannot consume the carrier directly, its adapter must be
independently pinned and prove a fieldwise, outcome-independent, total
bijection between the native representation and the carrier. Adapter
definitions enter dependency-taint analysis and may not inspect expected
outcomes, coverage classifications, witnesses, or proof status. Coordinate
or result-tag permutation, omitted fields, lossy projection, non-total
conversion, or an adapter that inspects the opposite operand invalidates the
comparison. It may depend only on its own source value and the pinned
field/tag mapping.

### `CoreContractCatalog`

The catalog is a logical aggregate of focused source files. It owns:

- closed domains and discriminated unions;
- shared semantic variants;
- public methods;
- system triggers;
- durable Operation kinds;
- Process completion and observation-commit contracts;
- acceptance-commit and idempotency-namespace contracts;
- multiplicity contracts;
- population-abstraction contracts;
- recovery coordinates;
- retention contracts;
- evidence predicates and Core decoding contracts;
- authorization and non-disclosure constraints;
- Snapshot classes and compatibility rules;
- transition classifications;
- concurrency classifications; and
- transport-neutral success predicates.

No transport or provider string is authoritative unless it is itself a
reviewed Core stable identity. Provider error codes, status text, native
payloads, resource IDs, and event names live in conformance bindings.

### `CatalogDenotation`

`CoreContractCatalog` owns one closed, total formal
`CatalogDenotation`. Its semantic identity includes:

- stable denotation ID/revision and formal-definition digest;
- every exact catalog source-schema/grammar digest;
- the normative source parser/AST definition and digest;
- selector, profile-expansion, reference-resolution, ordering, and restricted-
  value semantics; and
- the total `catalogDenotationCarrier` definition over admitted source sets
  and coordinates.

These are Core semantics, not checker configuration. Their aggregate digest is
included in the catalog semantic identity and every resulting
`ContractModel` semantic identity. Any definition/parser/schema/selector/
profile change that can alter the carrier relation requires
`SemanticChangeRecord`. An executable parser, reachability checker, normalizer,
or normalization checker may change under assurance governance only with a
full-domain certificate that it remains equivalent to the exact unchanged
`CatalogDenotation`; co-changing the checker cannot redefine the pinned
relation.

### `ContractModel`

Normalization:

- expands all named profiles and selectors;
- resolves every internal and external reference;
- inserts no semantic defaults;
- canonicalizes ordering and restricted JSON values;
- includes semantic revisions and import digests;
- derives wire identities only from registered closed variants;
- rejects unknown, duplicate, unreachable, or unused definitions; and
- computes a digest over the complete semantic model.

The model contains no source locations. A separate non-hashed explanation map
retains logical repository-relative source spans. Contributor identity is
included only through an explicit Packet F disclosure-class reference.
Non-hashed data remains authenticated and access-controlled; exclusion from
the semantic digest grants no disclosure authority.

### `CatalogNormalizationCertificate`

Normalization is a compiler step, not trusted semantics. First, every closed
`CoreContractCatalog` source-schema path is classified exactly once as:

- semantic, with one reachable `catalogDenotationCarrier` clause and
  authoritative owner; or
- nonsemantic, stored outside the catalog semantic digest and unavailable to
  normalization/runtime behavior.

An independent catalog-field-reachability checker exact-joins all admitted
source paths to those clauses and rejects missing, duplicate, wildcard/
fallback, unreachable, or unclassified paths. Every semantic source-field
path has at least one independently selected distinguishing mutation that must
change the formal carrier on a denotable coordinate. Other old/new values on
that path may compare equal only with a checked denotational-equivalence proof;
they cannot be accepted by declaring the entire field irrelevant. A checked
whole-field irrelevance theorem proves misclassification and leaves the gate
open until a semantic revision removes that field.

For the exact raw-preflight source-set digest and emitted canonical model
bytes, the normalizer emits proof material for:

```text
for every admitted coordinate c,
  catalogDenotationCarrier(exactCatalogSources, c) =
    contractModelDenotationCarrier(exactContractModelBytes, c)
```

The generator is proof-producing only and cannot accept its own output. The
independently implemented/pinned `CatalogNormalizationChecker` consumes exact
catalog/model bytes and either kernel-checks the proof term or replays it with
a complete decision procedure for the declared fragment. It shares no
normalizer code, expected output, catalog selector expansion, or generated
acceptance bit. Checker/kernel/toolchain/source/build/executable IDs/digests
and the closed proof fragment are pinned in scope and baseline.

Only a successfully checked artifact becomes
`CatalogNormalizationCertificate`. It binds the catalog/model semantic DSL
revisions, exact `CatalogDenotation` ID/revision/formal/source-schema/parser/
selector/profile-semantics digests, catalog-source-reachability commitment/
checker digest, every source and import digest, normalizer and independent-
checker identities/digests, exact model bytes/digest, and complete coordinate
universe. The normalizer may expand profiles/selectors and canonicalize
representation but cannot add, omit, or reinterpret meaning. Runtime/code
generation rejects a model without its matching checked certificate and
CatalogDenotation identity. Normalizer/checker implementation changes over
unchanged catalog/model denotations are assurance-only only with old/new
full-domain equivalence to that pinned definition; a denotation change follows
the semantic change protocol.

### `ContractModelInterpreter`

The catalog's closed semantic DSL and its normalized `ContractModel`
representation own a formal denotation,
`contractModelDenotationCarrier(exactModelBytes, coordinate)`. That relation,
not executable interpreter behavior, is authoritative and is included in the
model semantic revision/digest. The `ContractModelInterpreter` is a versioned
executable implementation of that relation. The scope manifest and review
baseline pin its parser, canonical serializer, semantic schema revision,
source/build/formal-definition/executable digests, extraction/translation
pipeline, and extensional-equivalence certificate.

The `ContractModel` schema classifies every field exactly once as:

- semantic, with one reachable formal model-denotation clause and authoritative
  owner; or
- nonsemantic, excluded from the canonical model or carried in a separate
  representation that runtime and product generators cannot inspect for
  behavior.

An independent field-reachability verifier exact-joins the closed semantic
field paths to formal denotation clauses and rejects missing, duplicate,
wildcard/fallback, unreachable, or unclassified paths. Parser/serializer
proofs establish byte-to-value-to-byte canonical round-trip and injectivity
over admitted model values. The formal denotation's totality proof covers
every model variant and coordinate; it may not read the oracle, ledger,
witness outcomes, or proof status.

The executable and every runtime/code generator must be produced by verified
extraction from that formal definition or carry a kernel-checked translation-
validation certificate proving, for every admitted canonical model byte
sequence and coordinate:

```text
executableInterpreter(bytes, coordinate) =
  contractModelDenotationCarrier(bytes, coordinate)
```

Runtime artifacts bind the exact verified executable/parser/certificate
digests and reject any other interpreter. Pinning digests without extensional
equivalence is insufficient.

For every semantic field/owner, assigned mutations must either change the
formal complete carrier relation on an independently constructed
denotable coordinate or be rejected by a checked, owner-bound semantic-
irrelevance theorem proving that field cannot affect runtime behavior. An
irrelevance theorem proves the field is misclassified and the gate remains
open until a semantic revision removes it from `ContractModel`; it is not
permission for runtime consumers to attach hidden meaning. A decoder that
ignores a semantic field, returns a constant/expected relation, or interprets
bytes not equal to the exact runtime/code-generation input fails this gate.

A formal denotation or carrier-relation change is always a
`SemanticChangeRecord` and changes the model semantic identity. An interpreter,
parser, extraction, or code-generation implementation may change under an
`AssuranceChangeRecord` only when an old/new extensional-equivalence
certificate proves both implement the same unchanged formal relation for the
complete domain. Otherwise it is rejected, not treated as an assurance-only
semantic change.

### `CoverageLedger`

The ledger:

- partitions every cell in every required base family and interaction product
  first into proof-independent `CoverageShardSpec` records, then into
  finalized `CoverageShard` evidence records;
- materializes finite cells only when their independently pinned exact
  cardinality is below the representation threshold;
- otherwise records canonical symbolic constraints in the supported proof
  fragment, finite cardinality formulas or `unbounded`, parameter domains, and
  deterministic bounded-expansion rules;
- records `applicable`, `inapplicable`, or `delegated` for every explicit cell
  or symbolic region;
- links each region's complete `SemanticComparisonCarrier` relation or total
  carrier-relation partition;
- links the non-denotability proof for an inapplicable region;
- links the owning packet and revision for a delegated cell;
- links positive, negative, unsupported, or delegated witnesses;
- records coverage maturity; and
- reports separate base-family and interaction-product formulas, counts or
  symbolic cardinalities, applicability commitments, shard digests, and one
  Merkle root.

`CoverageShardSpec` contains only the family/product and coordinate domains,
region predicate, applicability claim, semantic-owner references, comparison-
carrier schema digest, canonical complete carrier relation/partition formula
and digest, cardinality formula, and deterministic expansion rule. Its digest
contains no witness, proof, certificate, maturity, or finalized shard digest.
A proof certificate binds this spec digest and proves equality for that exact
relation commitment. After checking, the finalized `CoverageShard` binds the
spec ID/digest, copies no replaceable semantic formula, and adds only witness
IDs/digests, certificate IDs/digests, maturity, and evidence digest. The
ledger's `ledgerSemanticCarrier` dereferences the spec commitment directly;
any different formula/digest is invalid. The ledger Merkle root commits
finalized shards. This one-way construction makes the dependency graph
acyclic.

Symbolic shards are coverage representation, not sampling. An independent
solver proves that their constraints are pairwise disjoint and exhaustive over
the complete domain and that carrier-relation partitions are total. A
deterministic expander can emit every cell for any finite bounded
instantiation; the independent validator compares expansions, formulas, and
Merkle commitments. Every applicable finite cell or symbolic region consumes
the global first certificate and proves the latter two equations:

```text
for every admitted coordinate c,
  catalogDenotationCarrier(exactCatalogSources, c) =
    contractModelDenotationCarrier(exactContractModelBytes, c)

for every concrete coordinate c,
  region(c) ->
    ledgerSemanticCarrier(c) =
      contractModelDenotationCarrier(exactContractModelBytes, c)

for every concrete coordinate c,
  region(c) ->
    contractModelDenotationCarrier(exactContractModelBytes, c) =
      independentOracleSemanticCarrier(c)
```

The equality covers every field of `SemanticComparisonCarrier`, including
enabledness/admission, ordered gates, may/must next-state transitions,
may/must outcomes, postconditions, evidence requirements, observable
ordering, and effects. The global first equation proves catalog-normalization
semantic preservation. The shard-scoped ledger/model equation proves coverage
projection faithfulness. The final equation compares the exact canonical
serialized `ContractModel` consumed by runtime/code generation directly with
the independent oracle; its formal denotation and model digest are pinned
inputs. The shard supplies only `region(c)` and cannot stand in for runtime
semantics.

A unit may use exhaustive certified enumeration only after a checked proof
that its complete concrete coordinate domain—not merely its finite partition
grid—is finite. A finite partition over unbounded raw quantities, clocks,
strings, histories, or populations still requires a universal symbolic
certificate, unless a consumer-specific theorem proves every concrete tuple in
each partition has the same complete carrier relation. A replayable
finite-solver certificate is valid only within its proved complete finite
domain. Witnesses alone are insufficient. An unbounded/symbolic unit requires
a kernel-checked universal certificate. A function equality may replace
relation equality only when a
separate kernel-checked functionality theorem proves the entire
carrier-valued relation, not merely its result variant, is single-valued for
the fully normalized coordinate. The oracle relation and digest remain
independent inputs and cannot be generated from the ledger formula. Witness
agreement is necessary but not sufficient. An unsupported/unproved equality,
including an off-witness disagreement or a model-to-ledger projection drift,
leaves the unit and gate open.

The representation threshold affects file materialization only and is pinned
in `PacketEScopeManifest`; it cannot alter the domain, applicability, outcome,
or closure claim. Resource exhaustion, a cardinality overflow, or an
unprovable symbolic shard aborts generation and leaves the gate open.

It is generated after semantic validation. Product generators and runtime code
must reject it as a semantic input.

## Catalog records

### Closed domains

Raw values are never treated as finite axes. A `PartitionContract` declares a
closed typed input tuple, its finite semantic partitions, and the classifier
from that complete tuple. Wire parsing and contextual semantic classification
are separate contracts.

Examples:

- wire idempotency key parses as absent, well-formed, or malformed; the
  relational tuple
  `{ key, namespaceEpoch, bindingHistory, storedRecordOrTombstone,
  requestDigest, now }` classifies key-absent, new-unbound-live, equal-live,
  conflicting-live, equal-expired, conflicting-expired, or
  stale-unrecoverable-unbound;
- `{ suppliedEpoch, currentEpoch, omissionAllowed }` classifies
  absent-allowed, absent-forbidden, exact-current, stale, future, or malformed;
- `{ suppliedEtag, currentEtag, omissionAllowed }` classifies absent-allowed,
  absent-forbidden, exact-current, stale, or malformed;
- `{ suppliedDeadline, admissionObservedAt, acceptanceTime?,
  completionTime? }`, with tagged optional times and declared ordering
  constraints, classifies absent-explicit, future,
  reached-before-acceptance, reached-after-acceptance, or malformed;
- `{ now, expiry, holds }` classifies before-expiry, at-expiry,
  after-expiry-with-hold, or after-expiry-without-hold;
- `{ cursor, retainedRange, sealedEnd }` classifies exact-retained,
  before-earliest-retained, at-sealed-end, after-sealed-end, or malformed; and
- `{ rawQuantity, minimum, maximum }` classifies exact-minimum,
  valid-interior, exact-maximum, below-minimum, above-maximum, non-integral,
  or overflow.

Partitions are named, disjoint, and exhaustive over the declared typed input
tuple, not merely the wire token. Every contract supplies a total executable
classifier and an independently checked exactly-one-partition law. Bounded
tuples are exhaustively enumerated. Symbolic integer, duration, byte-count,
sequence, cursor, clock, and stored-record relations are proved with a
decision procedure over their declared constraints, then exercised with
boundary, overflow, history, and partition-overlap mutations. String grammars
are checked through their complete automaton or equivalent decision procedure.
Property tests provide additional concrete evidence but are never the
exhaustiveness oracle.

### `FamilyInstanceUniverse`

No family contract may define the concrete universe over which its own
totality is proved. For every base family, an independent universe builder
mechanically derives a sealed concrete instance algebra from:

- every independently pinned family axis and its complete typed domain;
- every participant constructor and incoming/incumbent projection;
- every target, lane, state, capability, authority, evidence, ordering, and
  effect fact reachable from those projections; and
- every revision/digest-bound foreign participant/import constructor.

The resulting `FamilyInstanceUniverse` has a stable ID/digest, closed
constructor/field set, and exact source-axis/import dependency set.
`InteractionObligationManifest` derives repeated-coordinate predicates and
candidate population domains from it. Independent exact-set checks require
every constructor and fact field once and reject extras, omissions, stale
foreign revisions, or catalog-authored substitutes.

### `MultiplicityContract`

Multiplicity meaning belongs to `CoreContractCatalog`; a scope-manifest kind
tag cannot erase repetition obligations. Every coverage family references
exactly one closed contract:

```text
MultiplicityContract =
  | population-abstraction {
      familyId,
      familyInstanceUniverseRef,
      admittedMultiplicityDomain,
      populationAbstractionContractRef
    }
  | repetition-non-denotable {
      familyId,
      independentlyDerivedRepeatedCoordinateRef,
      nonDenotabilityCertificateRef
    }
  | repetition-reduces-to-one {
      familyId,
      independentlyDerivedRepeatedCoordinateRef,
      canonicalSingleProjection,
      contextualCompleteCarrierCongruenceCertificateRef
    }
```

The first arm classifies a family as `population-bearing`; the other two
classify it as `logical-only`. The scope manifest independently pins the
expected family/contract binding and kind, but the catalog record owns only
the selected multiplicity semantics; it cannot author the predicate tested by
its own proof.

For each singleton candidate, the interaction validator mechanically derives
the repeated-coordinate predicate from the independently pinned complete
`FamilyInstanceUniverse` and `cardinality >= 2`, commits its
ID/digest in `InteractionObligationManifest`, and exact-matches the contract
reference. A catalog-supplied substitute, `False`, omitted runtime instance,
or narrowed domain is invalid. A `repetition-non-denotable` certificate proves
that exact predicate has no oracle-denotable trace—mere absence from authored
examples is insufficient.

A `repetition-reduces-to-one` certificate must prove contextual congruence:
for every admitted repeat count, permutation, well-typed population of every
other family, and interleaving, replacing `repeat(F,n)` with its canonical
single projection preserves and reflects every
`SemanticComparisonCarrier` field and enabled context transition. Isolated
carrier equality is insufficient. The certificate binds the exact complete
current family-ID set, every `FamilyInstanceUniverse` ID/digest, the sealed
context-composition algebra ID/digest, and every transitive context semantic
dependency—not merely the singleton's own contract. Adding or changing any
family invalidates it.

Without this theorem, logical-family
multiplicity remains unresolved and closure stays open until the catalog
revises that family to the `population-abstraction` arm with exact abstraction
and increment semantics; a logical arm cannot borrow a population proof
calculus it does not define. An absent, stale, circular, or failed certificate
leaves the singleton and every affected multi-family candidate open.
Relabeling the manifest cannot remove them.

### `PopulationAbstractionContract`

Population meaning belongs to `CoreContractCatalog`; the scope manifest pins
only its stable ID and domain signature. Every family contract references,
but cannot redefine, the exact independently derived
`FamilyInstanceUniverse`. It declares:

- concrete domain: finite multisets over that complete sealed instance
  algebra and every derived target, lane, state, capability, authority,
  evidence, ordering, and effect fact;
- abstract domain: symbolic multiplicity plus aggregate state;
- total abstraction function and exact concretization relation;
- permutation/symmetry keys;
- aggregate read/write/effect and observable-order summaries; and
- revision/digest-bound references to the existing catalog owners of concrete
  transition, outcome, evidence, ordering, and postcondition relations; and
- abstract relations derived from those references.

The contract cannot restate concrete behavior. Its only semantic ownership is
population composition, abstraction/concretization, and the derived abstract
relations.

An independently authored, kernel-checked abstraction theorem proves:

1. exact domain equality with the independent `FamilyInstanceUniverse`, then
   totality: every multiset in that universe maps to one abstract state;
2. permutation invariance;
3. congruence: if two concrete populations map to the same abstract state,
   their complete `SemanticComparisonCarrier` relations are equal, including
   enabledness/admission, ordered gates, may/must next-state transitions,
   may/must outcomes, postconditions, evidence requirements, observable
   ordering, and effects;
4. forward and backward simulation preserves and reflects the complete
   carrier relation, including must semantics and gate observations;
   and
5. preservation under adding one participant and under cross-family
   composition.

An under-approximation, invalid symmetry merge, missing concrete state,
one-way simulation that introduces an unclassified outcome, proof timeout, or
checker `unknown` leaves the population exact/unabstracted and the gate open.
Mutations must merge semantically distinct concrete populations and be
rejected.

### `MethodContract`

Every public method declares:

```text
MethodContract {
  methodId
  callClass
  origins
  requestSchema
  requestTargetSchema
  orderedAdmissionRules
  idempotencyKeyPolicy
  acceptanceCommitContractRef
  preAcceptanceVariantRefs
  recoveryContract
  preAcceptanceEvidenceRequirementRefs
  preAcceptanceRetentionPolicyRefs
  capabilityRequirements
  concurrencyLane
  transportMethodProjection
  authorizationDisclosureConstraint
  resultContract:
    | DurableOperationResult {
        carrierTag: "durable-operation"
        acceptanceResponseSchema
        durableOperationKindRef
      }
    | DurableProcessResult {
        carrierTag: "durable-process"
        acceptedProcessSchema
        processCompletionContractRef
      }
    | CommittedRecordResult {
        carrierTag: "committed-record"
        committedResultSchema
        successPredicate
        resultVariantRefs
        evidenceRequirementRefs
        retentionPolicyRefs
      }
    | ProcessControlReceiptResult {
        carrierTag: "process-control-receipt"
        receiptSchema
        successPredicate
        resultVariantRefs
        evidenceRequirementRefs
        retentionPolicyRefs
      }
    | ObservationResult {
        carrierTag: "observation"
        observationSchema
        successPredicate
        resultVariantRefs
        evidenceRequirementRefs
        retentionPolicyRefs
      }
}
```

The tagged union makes exactly one accepted carrier representable. A
rejected-before-acceptance row names no carrier instance.

`idempotencyKeyPolicy` is a closed union:

- `prohibited` — a supplied key returns the named `RequestError`;
- `required` — a missing key returns the named `RequestError`, otherwise the
  policy references one `IdempotencyNamespaceContract`; or
- `optional` — a missing key follows an explicit unkeyed-admission contract
  with no key-based recovery promise, while a supplied key references one
  `IdempotencyNamespaceContract`.

Request-schema optionality cannot select this behavior.

Field ownership is singular:

- `MethodContract` owns request, target, pre-acceptance behavior,
  result-carrier selection, admission order, method-level transport, and
  method-level authorization;
- `preAcceptanceVariantRefs` alone owns request/recovery variant membership
  for the method;
- each committed-record, Process-control-receipt, and observation result arm
  alone owns its carrier-specific result variant membership, schema, and
  success predicate;
- `ProcessCompletionContract` alone owns durable-Process terminal result
  variants, completion predicate, exit interpretation, terminal evidence,
  retention, and output-sealing behavior;
- for a durable Operation arm, `DurableOperationKind` alone owns terminal
  result variants, schema, postcondition, and observation contract;
- `SemanticVariantRegistry` owns variant payload, intrinsic applicability
  conditions that never name a method, variant-level transport tag/status,
  caller recovery, and Packet F disclosure reference;
- `EvidenceRequirement` owns proof predicates and forbidden inferences;
- `RetentionPolicy` owns lifetime semantics; and
- methods and variants only reference evidence and retention records.

The `method-variant-admissibility` family derives the effective variant set
from `preAcceptanceVariantRefs` plus exactly one carrier-tagged owner: the
referenced `DurableOperationKind.terminalOutcomeVariantRefs` or the selected
committed-record/receipt/observation result arm's variant refs, or the
referenced `ProcessCompletionContract.terminalOutcomeVariantRefs`. It also
consumes result/acceptance coordinates and each referenced variant's intrinsic
conditions. It contains no authored allow/deny decision. The normalized
effective method contract is an exact composition of these references.
Conflicting duplicate definitions are invalid; there is no precedence or
last-writer rule.

### `ProcessCompletionContract`

Every durable Process completion contract declares:

- stable contract ID;
- terminal Process state schema;
- terminal outcome variant references;
- completion/success predicate;
- exit-code, signal, timeout, resource-loss, cancellation, and `unknown`
  interpretation;
- output sealing and terminal cursor postcondition;
- terminal evidence-requirement references; and
- Process/output retention-policy references.

`Exec` references exactly one completion contract. Neither `Exec` nor a
provider binding may restate its terminal semantics.

### `DurableOperationKind`

Every durable Operation kind declares:

```text
DurableOperationKind {
  operationKindId
  operationTargetSchema
  acceptedState
  targetPostcondition
  terminalResultSchema
  terminalOutcomeVariantRefs
  cancellationContract
  ambiguityContract
  terminalEvidenceRequirementRefs
  retentionPolicyRefs
  operationObservationContractRef
}
```

Each durable-Operation `MethodContract` references exactly one kind and
structurally has no method-owned terminal success fields. Method-to-kind and
trigger-to-kind edges are authored only at the referring method or trigger;
generated inverse indexes prove reachability and report all referrers. The kind
is the only owner of its terminal postcondition, result schema, terminal
variants, cancellation/ambiguity behavior, terminal evidence, Operation
retention, and public Operation-observation contract. A method or trigger
cannot restate or override those fields.

### `SystemTriggerContract`

Every system trigger declares:

- stable trigger ID;
- owning subsystem;
- authenticated internal authority;
- triggering fact and freshness rule;
- target and expected epoch;
- durable intent requirement;
- exactly one `TriggerOutcomeContractRef` arm:
  - public method;
  - durable Operation kind;
  - `RetentionPolicy` expiry transition;
  - `ProcessCompletionContract` output-sealing transition; or
  - observation-commit contract;
- trigger-specific ordered admission rules;
- acceptance-commit-contract reference;
- trigger-fact evidence-requirement references;
- retry, reconciliation, and cleanup behavior; and
- observable event or Operation link.

Each tagged arm references exactly one semantic owner that supplies its target
postcondition, result/commit rule, evidence, retention, and observation
semantics. Observation-commit contracts are closed catalog records with stable
IDs, target/record schema, atomic commit predicate, evidence, retention, and
public visibility. Trigger-fact evidence can prove only admission and
freshness of the internal trigger. A trigger cannot restate or override linked
outcome semantics.

Provider notification is evidence for a trigger, never the serialization
authority.

### `ObservationCommitContract`

An internal observation commit declares one stable record/transition ID,
target and record schema, authority/freshness preconditions, atomic commit
predicate, evidence requirements, retention policy, authorization-before-
existence-sensitive-validation order, observational-equivalence constraint,
Packet F disclosure-class import, secret-safe public projection, and public
visibility. It cannot create an unnamed public resource, leak hidden target
existence/evidence, or convert an observation into durable mutation
acceptance. System triggers use it for provider observation, reconciliation
facts, and other internal record commits that have no public method or durable
Operation kind.

### `SemanticVariantRegistry`

Each shared variant declares:

- stable variant and family IDs;
- family: request error, recovery error, accepted known failure, ambiguity, or
  Process-control outcome;
- closed payload schema;
- intrinsic applicability predicate that cannot reference a method;
- evidence-requirement references;
- caller recovery;
- private Core resolution;
- Packet F disclosure-class import;
- variant-level transport tag/status; and
- retention references.

Membership is authored only by the carrier-tagged fields defined above:
`MethodContract.preAcceptanceVariantRefs`, the selected
committed-record/receipt/observation result arm,
`ProcessCompletionContract.terminalOutcomeVariantRefs`, or
`DurableOperationKind.terminalOutcomeVariantRefs`. A method-local open error
object, provider error code, `retryable` boolean, or unregistered detail is
invalid.

### `AcceptanceCommitContract`

Acceptance is a catalog-owned tagged union, not a coverage-only phase label:

| Tag | Atomic Core commit |
|---|---|
| `new-effect-intent` | durable effect intent, accepted result-carrier identity, recovery binding, and authority epoch |
| `atomic-record-update` | Core-record mutation, committed response, accepted prior revision, and recovery binding |
| `existing-operation-cancellation` | cancellation intent/state on the exact Operation and cancellation recovery binding |
| `process-control-receipt` | durable receipt, sequence binding, command digest, and initial delivery state |
| `observation-no-acceptance` | explicitly no acceptance record, recovery binding, or effect-producing dispatch |
| `system-trigger-outcome` | authenticated trigger intent, linked outcome-contract transition, trigger recovery binding, and observable event/Operation link |

Each method and system trigger references exactly one compatible contract.
The contract defines its atomic durability boundary, transaction participants,
pre-commit/no-effect guarantee, post-commit recovery facts, dispatch ordering,
response ordering, and crash-phase partition. `ContractModel`, not
`CoverageLedger`, supplies these rules to the runtime. Crash coverage projects
the exact tagged contracts and cannot invent or weaken their phases.

### `IdempotencyNamespaceContract`

Every key-accepting idempotency policy references a durable namespace
contract containing:

- stable namespace ID and monotonically increasing namespace epoch;
- closed wire coordinate: either explicit authenticated namespace ID/epoch
  plus caller token, or a self-describing authenticated key carrying them;
- authenticated scope plus compatible method IDs/semantic revisions and
  canonical-request algorithm IDs/digests;
- durable key-binding history states: never-bound, live binding, retained
  tombstone, expired-unrecoverable tombstone, and garbage-collected epoch;
- exact binding fields: canonical content digest, carrier/record identity,
  method semantic revision, canonicalization algorithm digest, acceptance
  commit, result/recovery state, and retention;
- rotation admission/fencing and authority;
- tombstone and namespace-epoch retention policies;
- garbage-collection proof and post-GC outcome; and
- recovery and diagnostics for every state.

The lookup identity is
`{ authenticatedScope, method, namespaceId, namespaceEpoch, idempotencyKey }`.
The namespace ID/epoch is never inferred as “current” for an unversioned key.
A missing, malformed, unauthenticated, future, retired, or garbage-collected
epoch has an explicit non-admission outcome. Rotation publishes a new epoch
without changing how delayed/retried old coordinates route.
The binding history is committed atomically through the referenced
`AcceptanceCommitContract`; a crash cannot expose accepted work without its
binding or a binding without its accepted work. Rotation never reclassifies a
key from an older or unprovable epoch as new. Loss of history yields
stale-unrecoverable behavior, never ordinary admission. Namespace rotation,
binding/tombstone retention, garbage collection, and crashes at every boundary
are explicit coverage coordinates.

Any request-schema meaning or canonical-request algorithm change fences the
old epoch and atomically publishes a new namespace epoch before new admission.
The old canonicalizer remains addressable by digest for retained replay
comparison. An unbound key in a retired epoch is non-admissible and never
inherits new method meaning. `SemanticChangeRecord` and migration validation
include the required epoch rotation and retained-recovery window.

### `RecoveryContract`

Recovery is a tagged union by call class:

| Tag | Lookup or identity key | Stored or compared facts |
|---|---|---|
| `idempotent-request` | authenticated scope, method, namespace ID, namespace epoch, idempotency key | method revision, canonicalization digest, canonical request digest, accepted carrier identity, acceptance/result state, retention |
| `process-control-sequence` | Process, Sandbox, runtime epoch, writer lease, sequence | canonical command digest, receipt identity, delivered/discarded offsets, retention |
| `existing-operation-cancellation` | exact durable Operation ID | canonical cancellation-intent digest and committed cancellation state |
| `atomic-record-update` | authenticated scope, method, namespace ID, namespace epoch, idempotency key | method revision, canonicalization digest, resource identity, accepted prior etag/revision, canonical update digest, committed response, retention |
| `observation` | resource identity plus cursor, condition, or freshness coordinate | no acceptance or deduplication record |

Recovery behavior is tag-specific:

- `idempotent-request` defines equal/conflicting live replay, equal/conflicting
  expired replay, compares the stored canonical digest after lookup, and
  performs lookup before mutable preconditions; key-absent follows the
  method's `idempotencyKeyPolicy`, new-unbound-live continues to ordinary
  admission through the atomic acceptance-commit contract, and
  stale-unrecoverable-unbound returns `RecoveryError` without dispatch;
- `atomic-record-update` uses the same idempotency behavior and recovers the
  committed response before evaluating the now-stale etag; a different stored
  resource, prior revision, or update digest is a conflict and never a new
  coordinate;
- `process-control-sequence` defines equal/conflicting sequence behavior,
  writer-lease fencing, receipt recovery, and delivered/discarded offsets;
- `existing-operation-cancellation` repeats intent against the same Operation
  and never allocates a second Operation; and
- `observation` re-evaluates the resource, cursor, condition, and freshness
  coordinate without creating an acceptance or deduplication record.

Observation deadlines never mutate the observed resource. Output cursor expiry
is an observation result, not an idempotency conflict. Each tag defines only
the malformed, deletion, freshness, result-carrier, expiry, and retention
branches meaningful to that call class; structurally impossible branches are
absent rather than populated with a generic replay rule.

### `RetentionPolicy`

Retention is a closed tagged family, not one duration:

| Tag | Subject |
|---|---|
| `operation-result` | Operation and terminal result |
| `idempotency-record` | request digest, coordinate, and replay result |
| `idempotency-namespace` | live/retired namespace epoch, binding-history summary, and post-GC proof |
| `tombstone` | deleted identity and conflict/recovery facts |
| `process-record` | Process request, state, and terminal outcome |
| `process-output` | stream chunks, cursor range, sealing, and truncation |
| `process-control-receipt` | accepted/delivered/discarded command receipt |
| `snapshot` | Snapshot manifest and retained components |
| `reference-hold` | exact protection preventing deletion or expiry |
| `event` | lifecycle and reconciliation event record |
| `evidence` | provider-neutral proof record |

Every policy declares:

- subject;
- clock start;
- minimum contract;
- value binding: immutable fixed or snapshot-at-subject-creation;
- operator-configuration revision and effective selected value where
  snapshotted;
- computed expiry;
- allowed holds;
- expiry transition;
- access after expiry;
- deletion interaction;
- diagnostic;
- post-expiry recovery; and
- Packet F retention/disclosure reference where applicable.

V1 has no dynamically reinterpreted retention value. An operator-configurable
value is explicit in effective Operator Configuration and is atomically bound
with the subject's creation/acceptance commit as
`{ policyId, policyRevision, operatorConfigurationRevision, effectiveValue,
clockStart, computedExpiry }`. A concurrent configuration change is ordered
against that commit: the stored revision either remains valid at commit or the
admission retries/rejects before acceptance. Configuration changes affect only
later subjects. Existing expiry changes require the explicit typed Core method
and its etag/idempotency contract. Returned retention facts expose the bound
revision and value. An omitted runtime value never selects a hidden duration.

### `EvidenceRequirement`

Evidence requirements contain only Core predicates:

- fact being proved;
- minimum authority;
- semantic identity and target;
- runtime and authority epoch;
- freshness;
- completeness;
- correlation requirements;
- Core evidence-decoding-contract references;
- conflicting-observation behavior; and
- forbidden inference.

Provider adapters bind native observations to these predicates. Packet F
controls collection, storage, redaction, and disclosure. A provider
acknowledgement, command return, event, or absence is not proof unless its
binding establishes the exact predicate. Packet C owns provider adapter,
mechanism, and native-envelope adapter versions; they never define or select
the accepted Core decoding implementation.

### `EvidenceDecodingContract`

Every Core evidence decoder contract declares:

- stable contract ID and semantic revision;
- closed authenticated evidence-envelope schema;
- supported Core envelope/version tags;
- semantic identity, target, epoch, freshness, completeness, and correlation
  extraction rules;
- canonical provider-neutral fact output;
- duplicate, delayed, reordered, conflicting, malformed, unsupported-version,
  ambiguous, and unauthenticated outcomes;
- forbidden inference; and
- exact `EvidenceRequirement` compatibility.

`EvidenceRequirement` references these stable contract IDs.
`decoding-and-freshness` coverage uses the Core contract revision as its
version coordinate. Packet C owns revision/digest-bound native-adapter
bindings into the Core evidence envelope; it cannot add a Core decoding
outcome, select the verifier's decoder, or bypass
authentication/ambiguity handling.

### `VerificationDecoderArtifact`

Each accepted verifier implementation is an immutable artifact record with:

- stable artifact ID, revision, source digest, build/store digest, and
  executable digest;
- exactly one implemented `EvidenceDecodingContract` ID/revision/digest;
- an independently checked compatibility/conformance certificate covering the
  complete envelope and outcome domain;
- deterministic input/output serialization and resource bounds;
- allowed evaluator IDs and execution modes; and
- Packet E approval plus Packet F execution/storage authority.

`BackendSemanticTrialSet` selects the exact artifact, not an open version
range. Both `direct-recompute` and `attested-decode` execute that same pinned
artifact; the latter additionally requires the Packet F service signature to
bind its exact identity/digests. A Packet C native adapter may construct the
envelope but cannot substitute, wrap, configure, or authorize the verification
decoder. Rotation to another artifact is an assurance change and requires its
own compatibility certificate and affected-trial remeasurement.

### `SnapshotClass` and compatibility

Every Snapshot class declares:

- kind: filesystem or runtime;
- component set;
- included, referenced, and excluded components;
- external-storage treatment;
- secret treatment reference;
- compatibility domain;
- quiescence protocol;
- device-state treatment;
- portability;
- Core Process handling;
- source disposition;
- reference and hold rules;
- ancestry;
- uniqueness regeneration requirements; and
- imported Packet B/C identities and digests.

Every compatibility contract classifies:

- Artifact/member/profile identity match;
- source and target system;
- architecture and CPU feature compatibility;
- kernel, VMM, runtime, guest protocol, device, and storage compatibility;
- included/referenced component availability;
- rebindable dynamic bindings;
- source disposition;
- restore count and uniqueness state;
- reference holds; and
- exact success, rejection, unsupported, or ambiguity outcome.

## Coverage families

Coverage is a discriminated sum of finite or symbolically partitioned
families, not one impossible global product. Structural discrimination makes
meaningless combinations unrepresentable. Each family still covers the
complete Cartesian/parameterized product of its declared axes.

At this revision the scope manifest requires exactly these 19 base families:

| Family | Required axes |
|---|---|
| `method-admission` | method, origin, authorization, target visibility, capability, request validity, recovery coordinate, state precondition, epoch/etag freshness, ordered gate |
| `method-variant-admissibility` | method, result branch, acceptance state, semantic variant; outputs: admissibility, carrier compatibility, exact reason |
| `system-trigger-admission` | trigger, authority freshness, target state, triggering-fact freshness, incumbent lane, durable-intent state, ordered gate |
| `lifecycle-transition` | action, Sandbox state, execution admission, Process aggregate, Snapshot state, Operation state, target relation, result |
| `durable-acceptance-crash` | acceptance-commit contract, call-class projection, commit state, crash phase, dispatch certainty, provider effect class, native identity, authority certainty, cancellation state |
| `recovery-and-idempotency` | recovery tag, coordinate state, canonical-content relation, retention state, target freshness, observed fact, recovery result |
| `idempotency-namespace-lifecycle` | namespace, epoch relation, binding-history state, rotation state, garbage-collection phase, crash phase, retention state, admission/recovery outcome |
| `process-control` | command, Process state, runtime epoch, writer lease, sequence relation, command relation, spool state, delivery fact |
| `process-output` | stream kind, Process state, cursor relation, retention, truncation, follow mode, output limit, sealing state |
| `snapshot-capture` | Snapshot class, source state, source disposition, Process aggregate, component completeness, quiescence, external resources, reference state |
| `snapshot-compatibility` | class, Artifact identity, profile identity, target compatibility, component availability, rebinding, source/target relation |
| `restore-fork-uniqueness` | action, source state, source disposition, restore count, uniqueness state, epoch allocation, ancestry, external connection state |
| `retention-and-expiry` | policy tag/revision, operator-configuration revision relation, concurrent configuration change, subject binding/commit state, clock partition, holds, deletion state, post-expiry access |
| `directional-concurrency` | incoming participant, incumbent participant multiset, symbolic cardinality vector, aggregate target relation/lane/state/capability, admission, coordination outcome |
| `evidence-and-inference` | claimed outcome, proof predicate, authority, freshness, decoding, conflicting evidence, forbidden inference, disclosure reference |
| `decoding-and-freshness` | boundary, version, authenticity, semantic identity, duplicate/delay/reorder state, accepted fact |
| `cleanup-orphan-reconciliation` | effect certainty, intent state, authority, provider-resource fact, adoption proof, compensation, deadline, final disposition |
| `transport-projection` | method, result branch, protocol, acceptance point, deadline layer, disconnect point, projected status |
| `domain-partition-totality` | partition contract, typed-input-tuple class, classifier branch, partition ID, exactly-one proof, boundary witness |

The exact ordered axes and cell formulas are stored independently in
`PacketEScopeManifest`; the table above is the exact required membership.
Adding, removing, or renaming a base family changes the assurance digest and
powerset formula, and requires semantic change review when Core meaning also
changes.
`callClass` in method-variant coverage is a validated projection of `method`,
not an independently varied axis.

The acceptance-commit axis projects only catalog-declared, call-class-valid
`AcceptanceCommitContract` arms:

- new-effect durable intent commit;
- atomic Core-record commit;
- existing-Operation cancellation-intent commit;
- Process-control receipt commit; and
- observation/no-acceptance-record; and
- system-trigger outcome commit.

Each arm partitions pre-commit, committed-before-dispatch where applicable,
dispatched/effect-uncertain where applicable, terminally recorded, and
response-emitted boundaries without inventing impossible phases for another
call class.

### Cross-family and aggregate interactions

Family factorization is accepted only as a tractability technique. It is not
evidence that interactions between individually total families are safe.

`InteractionObligationManifest` independently pins, for every stable
invariant and semantic rule:

- its owning family or families;
- the required within-family axis interactions;
- every required interaction product and its exact projections;
- its positive, negative, ambiguity, and crash-boundary witness obligations;
  and
- a machine-checked independence proof for every candidate family tuple
  intentionally excluded from an interaction product.

Finite/bounded independence and partition proofs are admitted only over the
Packet E relational solver fragment:

- finite enums and explicitly bounded products;
- declared partition predicates over typed tuples;
- quantifier-free equality, finite-set membership, bit-vector arithmetic, and
  linear integer arithmetic;
- explicit state read/write/effect sets; and
- explicit finite transition and outcome relations.

Unbounded population, abstraction, cutoff lifting, and symbolic-shard
equivalence use a separate parameterized proof-certificate format checked by a
pinned Lean 4 kernel. `PacketEScopeManifest` and `PacketEReviewBaseline` pin the
Lean toolchain/store derivation, kernel/version/source digest, allowed axiom
set, certificate IDs, and certificate digests. The axiom set is a closed,
audited foundational allowlist, not “anything from a pinned dependency.” An
independent checker computes each certificate's transitive
`#print axioms`-equivalent closure and requires it to be a subset. All
package/application semantic axioms, `False`/inconsistency axioms,
`sorryAx`, oracle-result axioms, unclassified axioms, unsafe declarations,
unverified external-oracle results, and proof terms with unpinned dependencies
are rejected regardless of provenance.

Each parameterized certificate contains:

- concrete and abstract domain definitions;
- the exact candidate family tuple and multiplicity-domain signature;
- every participating `MultiplicityContract`, independently derived repeated-
  coordinate predicate, and repetition-certificate ID/digest;
- base cases for the minimum admitted population-bearing multiplicity vector;
- scalar `n -> n + 1` induction for population-bearing singleton candidates;
- the exact non-denotability or contextual reduction theorem for
  logical-only singleton candidates;
- well-founded multi-index induction for multi-family candidates, with an
  increment-preservation proof for every multiplicity component;
- mixed-component increment commutation/composition lemmas;
- symmetry/permutation and quotient-congruence lemmas;
- the population abstraction simulation invariant;
- cross-family composition premises;
- the universal non-interference or outcome-equivalence conclusion; and
- exact links to one valid `ProofAssumptionSet`,
  `TransitionOracleRules`, `SemanticComparisonCarrier`,
  the catalog-owned formal ContractModel-denotation ID/digest, complete
  `ContractModel`, every participating `MultiplicityContract` and repetition
  certificate, every participating `PopulationAbstractionContract`, every
  transitively referenced concrete-relation semantic owner, every derived
  repeated-coordinate predicate/domain digest, the complete current
  family-ID/`FamilyInstanceUniverse`/context-composition commitment for a
  contextual reduction, every transitive context semantic dependency, and
  every proof-independent `CoverageShardSpec` digest.

Every link carries the referenced stable ID, semantic revision, and digest.
An independent certificate-interface verifier reconstructs the transitive
dependency set from the exact candidate tuple and checked proof term and
requires set equality with the manifest—subset declarations are invalid. The
certificate dependency graph is acyclic: certificates may reference shard
specs, while finalized shards reference certificates, never the reverse.
Abstraction, base, increment,
mixed-commutation, simulation, symmetry, composition, and final-equivalence
obligations must be kernel-proved in the certificate or reference an earlier
fully checked certificate with all arguments and assumptions applied. No
unresolved premise, free proposition outside the validated assumption set,
unbound concrete relation, or partial `ContractModel` digest is admissible.

Finite SMT results used inside a parameterized proof must produce a certificate
replayed by the pinned checker or be re-proved in the kernel.

For candidate families `F1..Fn`, the proof obligation is non-interference:
under one valid revision-bound `ProofAssumptionSet`, every legal combined
transition must preserve and factor each family's complete
`SemanticComparisonCarrier` projection—enabledness/admission, ordered gates,
may/must next-state transitions, may/must outcomes, postconditions, evidence
requirements, observable ordering, and effects—without a new semantic
variant. A syntactic disjoint-read/write proof is sufficient only when
authority, retention, evidence, target identity, gates, state-transition
relations, and observable-order sets are also disjoint and the resulting
complete-carrier factorization is kernel-checked. Otherwise the solver must
prove the complete relational obligation.

The assumption-set revision, bounds, read/write/effect projections,
solver/checker versions, and proof digest are independently pinned. Unsupported
theories, an unbounded obligation without a valid parameterized certificate,
timeout, solver `unknown`, an invalid or stale assumption set, or a failed
proof requires an explicit product plus a successful universal shard
certificate; otherwise closure remains open. It can never be converted into
`inapplicable`, `delegated`, warning-only coverage, or a finite sample.

The minimum required multi-family products include:

- durable acceptance × crash phase × recovery × retention;
- directional concurrency × cleanup/reconciliation × evidence;
- Snapshot capture × compatibility × restore/fork uniqueness;
- authorization × semantic variant × transport projection × disclosure;
- Process control × output visibility × termination/sealing; and
- system-trigger admission × durable intent × public Operation observation.

This list is a normative minimum, not permission for an unlisted interaction
to disappear. `PacketEScopeManifest` independently pins the complete non-empty
family-subset universe, including singleton aggregate-population and all
multi-family candidates.
`InteractionObligationManifest` must classify each candidate exactly once as
a required product or proved-independent tuple. Every catalog invariant and
semantic rule must be reachable from at least one interaction obligation. An
unmapped rule, an unclassified candidate, a missing required product, or a
missing/invalid independence proof is invalid even when every individual
family is total.

Every required interaction product becomes an interaction-product section of
`CoverageLedger` with an independently pinned stable ID, axis projections,
population/multiplicity domains, expected-cardinality formula, complete
explicit or symbolic applicability partition, semantic-outcome links,
witness/proof links, shard commitments, and digest. The interaction validator
reconstructs finite expansions and independently proves symbolic partition
coverage without consuming recorded outcomes. Merely declaring that a product
exists cannot satisfy coverage.

### Directional concurrency

Concurrency axes use tagged participants.

Incoming participants:

- `MethodRef`;
- `SystemTriggerRef`; and
- revision-bound `PacketAMethodRef`.

Incumbent participants:

- `ActiveMethodRef`;
- `ActiveSystemTriggerRef`;
- `ActiveDurableOperationKindRef`;
- `ActiveProcessControlRef`; and
- revision-bound `PacketAActionRef`.

The incumbent coordinate is a symbolic multiset over these tags, not one
handle. The manifest pins only participant/projection IDs, the referenced
`PopulationAbstractionContract` ID/digest, and multiplicity-domain signature.
That catalog contract exclusively owns symmetry keys, target/lane/state/
capability aggregation, and effect/ordering summaries; its kernel-checked
certificate validates them. Coverage includes:

- every Packet E/Packet E ordered pair and self-pair;
- every same-family and mixed-family incumbent population, including
  cardinalities above two through parameterized aggregate rules;
- every Packet E-to-Packet A boundary direction; and
- every Packet A-to-Packet E boundary direction.

Packet E owns the compatibility outcome at both Packet E/Packet A boundary
directions. Packet A supplies revision-bound method IDs, active-action IDs,
the method-to-active-action projection, and the two typed concurrency-envelope
projections; Packet E supplies and verifies the incoming/incumbent
compatibility classification. Until those imports resolve and every
cross-direction row is classified, `packetEScopeTotal` is false. These rows
are never closed as `delegated`.

Packet A/Packet A remains Packet A-owned. `coreApiTotal` therefore remains
false until Packet A's own concurrency inventory is closed and its closure
claim is imported. Packet E cannot turn Packet A's internal rows into Packet E
coverage.

### Applicability

The generator first creates each family's complete unconditional coordinate
product as explicit cells or proven symbolic shards. Only then may a cell or
symbolic region be classified:

- `applicable` — links one exact complete `SemanticComparisonCarrier`
  relation or total carrier-relation partition;
- `inapplicable` — links a machine-checked non-denotability proof under a valid
  `ProofAssumptionSet` and independently pinned structural constraints; or
- `delegated` — links an owner, semantic revision, digest, and closure status.

Selectors are authoring compression only. They must be disjoint and exhaustive
over the pre-existing product. A selector cannot define the product, introduce
a fallback, or make an unclassified cell disappear.

Every denotable coordinate is `applicable`, including behavior Foampit rejects
or intentionally does not support. Rejection and unsupported are explicit
semantic outcomes with negative witnesses; they are never applicability
statuses. Human review approves the proof obligation and assumptions but
cannot mark an inhabitable coordinate inapplicable.

Delegation is valid only for an entire semantic obligation whose owner lies
outside Packet E, such as Packet A/Packet A behavior or Packet F collection
mechanics. It cannot delegate a Packet E boundary outcome. A delegated cell
prevents any closure claim whose declared scope includes that obligation until
the imported owner reports a matching closed revision.

`PacketEReviewBaseline` pins the exact applicability-vector digest or symbolic
partition commitment for each family. Changing an applicable cell/region to
inapplicable always requires an
`AssuranceChangeRecord`; if the cause changes Core meaning or imported domain
bounds, it also requires `SemanticChangeRecord`. Equal counts never exempt the
change.

### Reachability

Every explicit finite cell has its required independently authored witnesses.
It also has exhaustive certified enumeration or a replayable finite-solver
certificate proving complete ContractModel/ledger/oracle carrier equality;
traces cannot prove absence of extra `may` transitions or presence of every
`must` transition.
Every applicable symbolic region has an independently authored parameterized
witness obligation plus finite boundary, negative, ambiguity, crash, and
representative positive witnesses. A kernel-checked theorem proves the witness
constructor yields a denotable oracle trace for every admitted parameter/
equivalence class. Inapplicable regions require only their exact
non-denotability certificate; delegated regions require owner/revision/digest
and closure evidence. Every rejection or unsupported applicable result has its
corresponding negative witness.

Witnesses are checked by a transition oracle implemented independently of the
catalog normalizer. The oracle consumes only `TransitionOracleVocabulary`,
typed input coordinates, a valid `ProofAssumptionSet`, and
`TransitionOracleRules`. It must reject `ContractModel`,
`CoverageLedger`, witness expected outcomes, catalog selectors, and generated
traces as semantic input. The ledger's recorded outcome is compared with the
oracle's independently computed result. Catalog-outcome mutations must fail
while oracle inputs remain byte-identical. A generated trace is not its own
proof.

Coverage maturity is explicit:

| Maturity | Meaning |
|---|---|
| `specified` | Exact explicit cell or symbolic region, diagnostic, and finite/parameterized witness obligations exist and pass inventory validation |
| `model-verified` | Independent oracle accepts required traces, every finite cell or symbolic region has complete ContractModel/ledger/oracle carrier-equivalence evidence appropriate to its domain, and assigned mutants are rejected |

Coverage cells stop at `model-verified`. Concrete execution does not change an
abstract cell's maturity.

Packet E owns `BackendSemanticTrialSet`. It pins:

- exact semantic witness and coverage coordinates;
- expected provider-neutral predicates;
- abstract crash, fault, race, and schedule boundaries that must be exercised;
- minimum repetitions and coverage/confidence requirements;
- exact per-slot attempt admission/retry/resume limits and deterministic
  complete-history `SlotEvaluation` aggregation rule/schema digest;
- acceptable variance and the semantic decision rule when nondeterminism
  cannot be eliminated; and
- freshness/expiry requirements;
- exact measurement-acquisition mode and revision/digest-bound
  `MeasurementAcquisitionTrustPolicy` import;
- exact `VerificationDecoderArtifact` ID/revision/source/build/executable
  digests and its Core-contract compatibility-certificate digest;
- exact decoding-verification mode; `attested-decode` requires a
  revision/digest-bound `EvidenceAttestationTrustPolicy` import; and
- Packet E-owned independent evaluator ID, version, source digest, normalized
  input schema, and evaluation-rule digest.

Packet C owns a revision-bound `BackendConformanceProtocolBinding` for one
target/runtime/provider binding. It maps every Packet E semantic trial to:

- `targetRuntimeProfileRef` and Packet C revision/digest;
- backend/runtime/VMM/kernel or provider mechanism versions;
- concrete trial IDs and repetition ordinals;
- deterministic seed derivation or realized-seed requirements;
- controlled schedule exploration;
- crash and fault-injection mechanisms/points;
- permitted environment ranges;
- harness identity/version/digest;
- protocol validity interval.

The Packet C binding must demonstrate that its concrete protocol satisfies
every Packet E semantic-trial requirement; it cannot weaken or reinterpret the
expected predicate.

The imported `MeasurementAcquisitionTrustPolicy` defines two closed modes:

- `direct-observation`: a Packet E/F-authorized observer independently
  orchestrates or observes the pinned Packet C harness and directly binds the
  realized seed, schedule, fault/crash point, environment, target/epoch,
  harness artifact digest, and raw evidence; or
- `attested-acquisition`: a Packet F-authorized acquisition service
  administratively independent of Packet C attests those exact facts and
  their correlation to the raw evidence.

For either mode the policy pins accepted observer/acquisition issuer
identities and keys, administrative failure domains, harness-artifact binding,
coordinate-to-evidence correlation algorithm, anti-replay nonce and time
rules, validity windows, rotation, and prospective/retroactive revocation
semantics. The signed acquisition statement covers the complete realized
coordinate, protocol-binding digest, target epoch, harness
ID/version/source/executable digest, raw-evidence digest, measurement-payload
digest, and execution-control observations. A Packet C self-assertion,
unobserved schedule/fault claim, unpinned harness, ambiguous revocation state,
or broken evidence correlation is not an authenticated measurement and cannot
pass.

Before launching a concrete harness attempt, the authorized acquisition
observer must obtain the quorum-witnessed pending receipt described below for
the exact trial/protocol/repetition/target reservation. The harness start is
invalid without it. Measurement finalization binds exactly one realized
seed/schedule/fault/environment/evidence record to that reservation and
delivers it through the durable evaluator handoff; it cannot return a
standalone measurement to Packet C for optional forwarding. A start without a
pending receipt, a reservation with no terminal evaluation, or an unmatched
finalized measurement leaves support fail closed.

Each immutable `BackendMeasurement` records one realized trial:

- content-addressed measurement ID and whole-record digest;
- pre-attestation measurement-payload ID/digest over the complete realized
  trial coordinate and observations;
- authenticated harness and issuer identities/signatures;
- Packet E trial-set ID, revision, digest, semantic trial ID, and witness;
- Packet C protocol-binding ID, revision, digest, and concrete trial ID;
- repetition ordinal, realized seed, realized schedule, and realized
  fault/crash point;
- exact target, backend, runtime, mechanism, and harness identities/versions;
- measurement-acquisition mode, trust-policy ID/revision/digest, issuer,
  signature, nonce, and complete execution-control attestation digest;
- approved normalized execution-environment observation;
- Core `EvidenceDecodingContract` ID, revision, and digest;
- Packet F-authenticated raw-evidence digest and provenance attestation;
- decoded provider-neutral fact digest and normalized-observation digest;
- immutable provider-neutral observations;
- measurement time and evidence-validity interval; and
- Packet F disclosure-class, storage-policy, and evidence-retention imports.

A measurement never records `conforming`. The measurement store is
append-only: correction creates a new content-addressed record with an
authenticated `supersedes` edge; tombstoning preserves the original digest and
reason under Packet F retention rather than mutating or reusing identity.

The Packet E-owned, independently implemented evaluator derives
`BackendConformanceEvaluation` as pass, fail, inconclusive, or expired from
the immutable normalized observation, pinned semantic expectation, and Packet
C protocol realization. Before evaluation it verifies the complete chain from
the pinned Packet F measurement-acquisition policy and authenticated realized
execution controls/raw-evidence provenance, through the pinned Core
`EvidenceDecodingContract` and exact `VerificationDecoderArtifact`, to the
decoded-fact and normalized-observation digests. Each semantic trial selects
exactly one verification mode:

- `direct-recompute` grants the evaluator least-privilege, audited, ephemeral
  access to the protected raw envelope; it verifies the raw digest and runs
  the exact pinned `VerificationDecoderArtifact` itself; or
- `attested-decode` requires a Packet F-authorized decoder service independent
  of Packet C to execute and sign the exact pinned
  `VerificationDecoderArtifact` ID/revision/source/build/executable and
  compatibility-certificate digests, raw digest, decoded-fact digest,
  normalized-observation digest, Packet C protocol-binding digest, concrete
  trial ID, repetition ordinal, realized seed/schedule/fault point,
  target/epoch, pre-attestation measurement-payload ID/digest, evaluator
  freshness nonce, freshness, and provenance.

The imported `EvidenceAttestationTrustPolicy` pins accepted decoder issuer
identities/keys, organizational and control-plane independence from Packet C,
key rotation, prospective/retroactive revocation semantics, validity windows,
nonce/freshness rules, and the exact set of `VerificationDecoderArtifact`
identities/digests each issuer may execute. The trial-set selection and trust
policy authorization must exact-match. An unpinned issuer, decoder
substitution, compatibility mismatch, or ambiguous revocation state cannot
attest a passing observation.

Missing, stale, unauthenticated, mismatched, untrusted, or unprovable chains
are inconclusive or failed according to the trial rule, never passing. Packet
C cannot supply the attestation, select/version the evaluator, or override its
decoder. The evaluation records all input and evaluator/decoder digests and
cannot discard failed or inconclusive trials.

Before a concrete trial attempt is launched, the acquisition observer
authenticates the reservation authority and structurally validates protocol/
trial membership, repetition/retry eligibility, target-profile membership,
attempt sequence, and policy limits. Only then does it use the publication
protocol in the pinned `ConformanceEvidenceTrustPolicy` to append a
`reserved` attempt under the stable slot in the Packet F-protected
`EvaluationEvidenceLog` and obtain a durable `k-of-n` witness publication
receipt. Untrusted or malformed intake cannot create a reservation.

That witnessed pending state immediately makes the slot and any report
depending on its older head non-current. After execution, the observer
authenticates and structurally validates the complete acquisition statement,
then compare-and-appends a witnessed `measurement-bound` transition containing
the measurement/payload digests before any decode/evaluation. The evaluator
computes the result and compare-and-appends the terminal transition under the
same protocol. It returns only the content-addressed evaluation ID, inclusion
proof, extending checkpoint, and quorum publication receipt. A crash or quorum
failure after reservation leaves support explicitly fail closed until recovery
terminates the attempt. A failed, inconclusive, or expired evaluation follows
the same mandatory path as a pass. Packet C has no write, omission, selection,
or filtering authority over this log.

There is exactly one trust-policy-bound evaluation log for each allowed
protocol coordinate. Within it, `EvaluationSlot` is the stable unique
required-trial/repetition key:

```text
{
  trialSetId, trialSetRevision, trialSetDigest,
  evaluatorId, evaluatorRevision, evaluatorRuleDigest,
  protocolBindingId, protocolBindingRevision, protocolBindingDigest,
  semanticTrialId, concreteTrialId, repetitionOrdinal
}
```

Realized seed/schedule/fault, concrete target/epoch, measurement, nonce,
observation/publication time, signature, and result are deliberately excluded;
none can create a parallel selectable slot.

`EvaluationAttemptCoordinate` contains the slot plus a monotonic attempt
sequence, stable attempt ID, derived/planned seed, schedule class, fault point,
target reservation, and acquisition-observer identity. It is immutable and
excludes facts knowable only after execution or any mutable lease field. The
trial set defines a closed retry/attempt-admission and aggregation rule. A
second attempt is admissible only after the prior attempt is terminal and the
rule explicitly permits it; it cannot replace or hide that result.

`EvaluationAttemptState` is a separate witnessed record containing attempt
phase, monotonic state revision, predecessor-state digest, evaluator lease
owner/epoch, lease validity interval, authenticated clock-contract
ID/revision/digest, permitted takeover/resolver identity set, and revocation
facts. Every state change is an extending log entry and CASes the exact prior
state digest.

Evaluation-log entries are a closed discriminated union:

- `reserved` carries `EvaluationSlot`, `EvaluationAttemptCoordinate`, prior
  slot-head digest, and initial `EvaluationAttemptState`;
- `lease-taken-over` carries the slot/attempt reference, predecessor-state
  digest, old/new lease owners and epochs, lease-expiry or revocation evidence,
  authenticated clock observation, resolver authority, and successor state;
- `measurement-bound` carries the slot/attempt reference, authenticated
  acquisition statement, immutable measurement/payload digests, exact realized
  seed/schedule/fault/target/epoch/environment, predecessor-state digest, and
  complete successor `EvaluationAttemptState` ID/digest;
- `completed` carries the slot/attempt reference, measurement/decoder/
  attestation inputs, immutable evaluation ID/digest/result,
  predecessor-state digest, complete terminal successor
  `EvaluationAttemptState` ID/digest, and successor `SlotEvaluation` ID/digest
  over the complete history;
- `resolved-inconclusive` carries the slot/attempt reference, reason,
  recovery/revocation evidence, resolver authority, predecessor-state digest,
  complete terminal successor `EvaluationAttemptState` ID/digest, and
  successor `SlotEvaluation` ID/digest;
- `conflict` carries the slot, prior slot-head digest, and every competing
  entry/digest; and
- `conflict-resolved` carries the predecessor conflict/head digest, every
  conflicting entry, resolution authority/evidence, pinned precedence-rule
  ID/digest, affected predecessor-state digests, complete successor attempt
  states, and successor `SlotEvaluation` ID/digest.

Every entry also contains monotonic log sequence, prior entry/root digest,
publication time, and authenticated issuer. Signed checkpoints commit the log
ID, protocol coordinate, size, Merkle root, unique slot-head map digest, and
pending/conflict-set digest.

For every state-changing arm, the validator exact-matches the current durable
state to `predecessorStateDigest`, requires state revision and lease epoch to
advance according to the closed transition table, and commits the complete
successor state. A terminal slot aggregate binds that exact successor terminal
state. A missing successor, stale predecessor, illegal phase edge, or hidden
state mutation is invalid.

`conflict-resolved` uses one atomic multi-CAS over the exact current slot/
conflict-head digest and every affected attempt predecessor state. The
provided predecessor set must equal the conflict record's independently
reconstructed affected-state set—no omitted or extra attempt—and every member
gets one legal complete successor state in the same append. Partial,
sequential, or singular-state resolution is invalid.

Publication atomically compares and updates the unique attempt state and
`EvaluationSlot` head while appending:

- processing retry first reads the slot/attempt state and resumes it
  idempotently; the same valid terminal inputs return their existing inclusion
  proof and quorum receipt even if a fresh nonce/time would change incidental
  bytes;
- a corrected measurement or new harness attempt must name the unique slot
  head, satisfy the closed supersession/retry rule, and preserve every earlier
  attempt in the slot history;
- concurrent compare-and-append permits at most one successor; a semantically
  equivalent loser adopts the winning head, while a different result or
  incomparable input appends a conflict record and makes the slot
  non-current;
- after lease expiry or evaluator-instance revocation, an authorized replica
  of the exact pinned evaluator artifact may verify the pinned authenticated
  clock/revocation proof and takeover identity, append `lease-taken-over` with
  the exact predecessor-state digest, CAS-increment the lease epoch, obtain a
  witnessed takeover receipt, and resume the durable attempt; stale owners are
  fenced; if compatible execution cannot resume, an identity in the pinned
  resolver set appends `resolved-inconclusive`, never pass; and
- the same evaluation ID with different bytes, slot, or attempt is always an
  integrity failure.

The unique `EvaluationSlot` head contains one content-addressed
`SlotEvaluation`, a deterministic Packet E-derived aggregate over the complete
ordered attempt/evaluation history under the pinned retry/aggregation rule. It
records the slot ID, complete attempt-set/history digest, aggregation-rule
digest, aggregate pass/fail/inconclusive/expired result, evidence inputs, and
Packet E evaluator identity/digest. It is not a
`BackendConformanceEvaluation` and not one Packet C-selected attempt. Any
nonterminal attempt makes the slot pending. Conflict resolution is an
authenticated compare-and-append transition that references every conflicting
entry and follows the pinned total precedence rule; it never deletes history.
Thus every slot has one linear aggregate head, pending state, or explicit
fail-closed conflict state, never multiple selectable heads. Supersession
appends authenticated history; it never mutates or hides a prior result.

The `SlotEvaluation` hash preimage is acyclic: it is the canonical ordered set
of immutable slot/attempt-coordinate, predecessor/successor attempt-state,
measurement, per-attempt evaluation, and prior `SlotEvaluation` objects plus
the aggregation-rule/evaluator digests. It explicitly excludes the enclosing
terminal/conflict-resolution log entry, slot-head reference, quorum receipt,
checkpoint, and its own ID/digest. The enclosing entry references the already
computed aggregate; the aggregate never hashes that entry.

Raw environment details, native payloads, logs, evidence, and protected
handles remain solely in Packet F-controlled storage. They do not appear in
repository artifacts. Repository review and conformance reports contain only
Packet F-approved normalized summaries, semantic coordinates, digests, and
evaluations; a digest grants no disclosure authority.

Packet C owns the assembled `BackendConformanceReport`, because it owns the
realization/protocol binding. The report exact-joins every required
`EvaluationSlot` to its complete ordered attempt/measurement/evaluation
history and unique independently derived `SlotEvaluation` ID/digest,
binds the latest witnessed `EvaluationEvidenceLog` checkpoint for its protocol
coordinate, proves inclusion and supersession resolution for every evaluation
required through that checkpoint and completeness against the
trial/protocol set, then applies the Packet E decision rule across all results.
It must select the unique slot head committed by that checkpoint. A
missing head, conflict state, incomparable successor, stale head-map digest,
or multiple purported current evaluations makes the report invalid rather
than allowing Packet C to choose one.
Packet E
recomputes/validates evaluation and semantic-trial completeness before
accepting the imported report summary; Packet C cannot self-certify. Packet F
validates disclosure, storage, and retention. A representative witness, one
happy execution, one backend version, or one partition member cannot lift an
abstract coverage cell or neighboring coordinates into backend support. Gate
2A requires `specified`; Gate 4B and a production support statement require
all applicable model verification, integration hooks, and an entirely passing
current report.

## Semantic change protocol

Every `ContractModel` semantic digest change requires one
`SemanticChangeRecord`, including additive changes.

The record contains:

- predecessor model digest;
- successor model digest;
- predecessor/successor `CatalogDenotation` IDs/revisions/formal/source-
  schema/parser/selector/profile-semantics digests;
- predecessor/successor formal model-denotation IDs/digests;
- field-level canonical semantic diff;
- added, removed, renamed, and tombstoned stable IDs;
- changed imports and predecessor/successor foreign digests;
- affected coverage families and exact cells;
- affected witnesses, diagnostics, generated targets, and formal actions;
- migration and wire-compatibility impact;
- review rationale; and
- required remeasurement.

A stable ID cannot acquire a different meaning without an explicit semantic
change. A removed wire identity remains tombstoned and cannot be reused.

Every authored assurance-definition or pinned-baseline digest change requires
one `AssuranceChangeRecord`, even when `ContractModel` is byte-identical. The
record contains:

- predecessor and successor scope-manifest digests;
- predecessor and successor interaction-obligation digests;
- predecessor and successor proof-assumption digests;
- predecessor and successor parameterized-certificate and proof-checker
  digests;
- predecessor and successor transition-oracle vocabulary/rule digests;
- predecessor/successor catalog-source-reachability commitment/checker,
  normalizer source/build/executable, independent normalization checker/
  kernel/toolchain/proof-fragment, and checked
  `CatalogNormalizationCertificate` digests, plus proof that catalog/model
  denotations are unchanged for an assurance-only implementation change;
- predecessor/successor interpreter/parser/extraction/executable and
  extensional-equivalence-certificate digests, plus proof that the formal
  model-denotation digest is unchanged;
- predecessor and successor review-baseline digests;
- predecessor and successor witness-set digests;
- required `WitnessSetTransition` ID/digest and exact predecessor/successor
  policy epochs whenever issuer/witness/trust-policy membership changes;
- predecessor and successor Packet E semantic-trial-set digests;
- predecessor and successor Packet E evaluator IDs/source/rule digests;
- affected Packet C protocol-binding and report digests;
- exact added, removed, weakened, strengthened, or rebound assurance
  obligations;
- mutation, re-review, and remeasurement impact; and
- review rationale.

When one change affects both semantic and assurance artifacts, linked
`SemanticChangeRecord` and `AssuranceChangeRecord` entries are both required.
Neither record can stand in for the other.

Append-only measurements/evaluations and regenerated reports are operational
evidence state, not authored assurance definitions. They use content-addressed
identity, authenticated provenance, supersession/tombstone rules, exact input
digests, and report regeneration history. They require
`AssuranceChangeRecord` only when the governing trial set, protocol import,
evaluator, schema, decision rule, or pinned baseline changes; an ordinary new
trial result does not.

Packet C maintains every pass, fail, inconclusive, and expired report summary
in `SupportEvidenceLog`. Each entry has one protocol coordinate, monotonic
sequence, previous-entry/root digest, report/evaluation digests, validity,
supersession, and authenticated issuer. Signed monotonic checkpoints commit the
log size and root. A report is published and eligible for a current view only
after its extending checkpoint receives the same durable `k-of-n` witness
publication receipt. Failure or refusal to publish cannot preserve older
support because the newer witnessed Evaluation-log pending/completed
checkpoint already makes that report non-current.

`ConformanceEvidenceTrustPolicy` pins:

- Evaluation- and Support-log IDs/issuers, externally anchored genesis
  checkpoints, checkpoint consistency algorithms, and the atomic
  quorum-witnessed publication protocol for both logs;
- a separate Packet E log-witness implementation identity/digest;
- independent witness identities and administrative failure domains, tolerated
  Byzantine faults `f`, and threshold `k-of-n`, requiring `n >= 3f + 1`,
  `k >= 2f + 1`, and quorum intersection; multiple identities controlled by
  one operator/failure domain count as one witness;
- verifier-challenge nonce format;
- authenticated freshness-clock contract and maximum checkpoint age;
- evaluator-lease clock, validity bounds, permitted takeover/resolver
  identities, state-CAS, and revocation-proof rules;
- durable anti-rollback state and atomic update rule; and
- issuer/witness revocation semantics;
- policy-epoch and old/new-quorum witness-set handoff; and
- optional predecessor-pinned external recovery authority and mandatory
  support invalidation/remeasurement semantics.

Packet E owns the acceptance, quorum, freshness, and fail-closed semantics in
this policy. Packet F owns the imported issuer/witness key-custody,
authentication, and revocation facts. The policy binds those Packet F facts by
stable ID/revision/digest; neither packet may silently redefine the other's
fields.

For either log, append is committed only when the issuer checkpoint and
`k-of-n` signatures over the exact extending log ID, protocol coordinate,
size, root, slot-head/pending-set digest where applicable, prior
witnessed checkpoint, and observation time form one
`QuorumPublicationReceipt`. Each witness durably persists the new checkpoint
before signing. The evaluator, report publisher, and view derivation reject an
issuer-only checkpoint, partial quorum, hidden later checkpoint, or receipt
whose signers do not satisfy the pinned independent-failure-domain threshold.
No evaluation or report success may return before its receipt exists.

The immutable log entry and issuer checkpoint are finalized first. The
`QuorumPublicationReceipt` is a separate content-addressed proof envelope that
references their exact IDs/digests and checkpoint root; its bytes and witness
signatures are never part of the entry or Merkle root they attest. Consumers
require the immutable entry/checkpoint plus the matching external receipt.
Altering either invalidates the reference; no receipt-association rewrite of a
committed log entry is permitted.

Every witness durably persists its last signed size/root before acknowledging
a signature and refuses to sign rollback, a non-extension, or a root
inconsistent with its prior head. A witness that loses anti-equivocation state
is unavailable; it cannot bootstrap itself from an untrusted log view.

Every checkpoint, receipt, and witness signature binds the
`ConformanceEvidenceTrustPolicy` ID/digest and monotonically increasing policy
epoch. Witness-set rotation/rekey requires one `WitnessSetTransition`
co-signed by valid old and new quorums over:

- the exact latest Evaluation- and Support-log IDs, sizes, roots, slot/head/
  pending-set digests, and consistency proofs from the old accepted
  checkpoints;
- predecessor and successor policy IDs/digests/epochs and witness-set digests;
- the effective time, revocations, and external-recovery-authority status; and
- proof that each new witness durably initialized both exact heads and its
  anti-equivocation state before signing.

Verifiers require an unbroken transition chain from their accepted policy
epoch or pinned genesis and atomically persist the successor policy plus heads.
A new quorum cannot sign operational checkpoints before the handoff commits.
The successor `PacketEReviewBaseline` must bind the transition ID/digest and
use its exact co-signed heads as the successor epoch genesis; a fresh verifier
cannot treat a newly authored baseline as continuity by itself.
If an old quorum is unavailable, ordinary rotation fails closed. Only an
external recovery authority explicitly pinned in the predecessor policy may
create a recovery transition; it starts new log epochs, permanently marks all
predecessor support reports non-current, preserves the old roots as forensic
history, and requires complete remeasurement before any support claim.

Packet E derives `CurrentSupportEvidenceView` only after verifying entry
inclusion, no sequence gap, completeness against required trials/evaluations,
issuer authorization/revocation, no pending/conflicted evaluation slot,
quorum publication receipts, and evaluation-time expiry. The selected report
must bind the latest independently witnessed `EvaluationEvidenceLog`
checkpoint; a newer pending or completed evaluation without a covering report
makes support non-current and fail closed. A verifier with durable state
requires consistency proofs from its last accepted checkpoints for both logs
and atomically persists newer checkpoints before accepting the view.

For first bootstrap or lost local state, the verifier sends a fresh nonce to
the threshold witnesses. Each response signs the nonce, log ID, claimed latest
size/root, observation time, and max-age and supplies consistency from the
pinned genesis. The quorum must agree on one latest head or a mutually
consistent chain with one deterministic maximum for each log; the separate
Packet E log witness verifies it. There is exactly one deterministic
Support-log head per protocol coordinate and one latest Evaluation-log
checkpoint. A stale prefix, rollback, omitted required evaluation/report,
competing/incomparable heads, fork, equivocation, missing/stale quorum,
untrusted time, revoked issuer/witness, or expired head fails closed.

`PacketEReviewBaseline` pins the log/view schemas, accepted issuers/witnesses
and trust policy, and allowed protocol coordinates—not dynamic entries,
checkpoints, report digests, or derived views. Appending or expiring a report
therefore changes operational evidence without changing the assurance
baseline. Changing the schema, trust policy, protocol coordinate, or decision
rule requires `AssuranceChangeRecord`.

The review baseline pins:

- exact stable identity sets;
- family definitions, axis signatures, and catalog-owned
  multiplicity-contract bindings/digests plus independently derived
  family-instance-universe/context-composition commitments;
- per-family cell formulas and counts;
- exact applicability-vector or symbolic-partition commitments;
- interaction-obligation identities, candidate universe, required product
  formulas/counts or symbolic cardinalities/applicability commitments,
  population domains, proof assumptions, solver versions,
  proof-independent shard-spec commitments, finalized shard/Merkle roots, and
  aggregate digest;
- domain-classifier and exactly-one-proof identities;
- parameterized-proof-certificate identities/digests and pinned Lean
  checker/kernel/toolchain identities/digests;
- transition-oracle vocabulary/rule/assumption identities and digests;
- semantic-comparison-carrier identity/schema digest;
- catalog-denotation ID/revision/formal/source-schema/parser/selector/profile-
  semantics identities and digests;
- catalog-source-field-reachability commitment/checker, catalog-normalizer
  source/build/executable, independent normalization checker/kernel/toolchain,
  proof-fragment, and checked normalization-certificate IDs/digests;
- contract-model-interpreter parser/schema/source/build/formal/executable,
  extraction-or-translation pipeline, and extensional-equivalence-certificate
  identities/revisions/digests plus exact semantic-field reachability
  commitment;
- required witness identities;
- Packet E semantic-trial-set and imported Packet C protocol-binding
  identities/digests;
- Packet E evaluator identities/digests and Packet C report-import
  schema/protocol-coordinate identities/digests, plus attempt-admission and
  `SlotEvaluation` schema/aggregation-rule digests;
- Verification-decoder artifact identities/source/build/executable/
  compatibility-certificate digests;
- Packet F measurement-acquisition issuer/key/artifact-binding/
  execution-control/rotation/revocation trust-policy identities/digests;
- Evaluation-/Support-log schemas, conformance-evidence trust-policy, genesis,
  policy-epoch/handoff/external-recovery rules, separate log-witness,
  quorum-witness, freshness-clock, and anti-rollback contract
  identities/digests;
- Packet F evidence-attestation issuer/key/independence/rotation/revocation
  trust-policy identities/digests;
- semantic-model digest;
- generated-ledger digest; and
- authored foreign contract/import-definition digests, explicitly excluding
  operational log entries, checkpoints, measurements, evaluations, reports,
  and derived current views.

Changing the semantic model or any assurance baseline without the matching
typed change record is invalid.

## Validation architecture

The implementation uses independent mechanisms:

1. a raw-byte JSON preflight validates UTF-8 and RFC 8259 token structure and
   rejects duplicate object keys recursively before any source value is
   constructed, then emits the exact ordered source-set digest;
2. a dependency-free Node generator normalizes the source catalog and emits
   `ContractModel`, `CoverageLedger`, and normalization proof material, but
   only after rechecking the same source-set digest; it emits no acceptance
   decision;
3. the independent pinned `CatalogNormalizationChecker` exact-checks catalog-
   source-field reachability and kernel-checks or completely replays the
   normalization proof material before issuing
   `CatalogNormalizationCertificate`;
4. an independent model-interpreter verifier checks canonical parser round-
   trip/injectivity, exact semantic-field-to-clause reachability, total
   formal denotation, executable/runtime-generator extensional equivalence,
   runtime-input byte identity, and field mutations;
5. a separately implemented `jq` validator reconstructs required sets and
   coverage coordinates without importing generator code;
6. CUE validates closed structural and relational constraints over the
   generated products;
7. a separate transition oracle computes outcomes from independently authored
   rules and replays witnesses without consuming catalog or ledger outcomes;
8. a symbolic decision procedure or equivalently complete finite-state
   procedure proves total, disjoint typed-tuple partitions and the declared
   non-interference obligations within the supported proof fragment,
   failing closed on unsupported or unknown results;
9. the pinned Lean kernel checks population-abstraction, induction/symmetry,
   composition, and universal ledger/oracle complete-semantic-relation
   equivalence certificates;
10. an independent interaction validator reconstructs every required
   cross-family or aggregate-population product from
   `InteractionObligationManifest`;
11. an independent shard/cardinality verifier proves symbolic coverage
   partitions, checks Merkle commitments, and compares deterministic bounded
   expansions without consuming recorded outcomes; and
12. mutation tests attack raw sources, the catalog, generator output, formal
   obligations, measurements, and review baseline independently.

The preflight operates on every JSON source as bytes, before Node, `jq`, CUE,
or a generic JSON parser can silently collapse duplicate keys. Canonical
round-trip and nested duplicate-key mutations independently check this gate.
Generated formal vocabulary may consume `ContractModel`; the independent
transition oracle consumes only its separately pinned vocabulary, assumptions,
and rules.

Required mutations include:

- delete or add a catalog identity;
- shrink or expand a scope axis;
- delete a coverage family;
- remove an axis from one family;
- delete a `method-variant-admissibility` row or make a method-local variant
  subset inconsistent with the registry;
- alter a family participant projection;
- change an expected-cell formula;
- delete a required cross-family interaction or replace it with an invalid
  independence proof;
- omit one powerset tuple at any arity from `1..N`, remove any singleton
  obligation, relabel a family logical-only without a valid catalog
  repetition proof, assign runtime multiplicity to a validated logical-only
  family, or alter `2^N - 1`;
- cap a symbolic population without a lifting theorem, create symbolic shard
  gaps/overlaps, corrupt a cardinality formula/Merkle root, or let resource
  pressure reduce the covered domain;
- omit any participant constructor, foreign participant, or target/lane/state/
  capability/authority/evidence/ordering/effect fact from a
  `FamilyInstanceUniverse`, or let a population contract substitute its own
  concrete type;
- merge two concrete populations with different admission, outcome,
  postcondition, evidence, ordering, or effect semantics under one aggregate;
- change a symbolic shard outcome only outside authored witness points;
- change only the ContractModel-to-ledger projection while preserving
  ledger/oracle agreement, or change exact runtime model bytes without
  changing the comparison operand;
- drop/rewrite a catalog field, selector, profile, or import during
  normalization while keeping the emitted model internally valid, or bind a
  normalization certificate to different source/model digests;
- ignore or misclassify a catalog source field in
  `catalogDenotationCarrier`, omit its reachability clause, corrupt
  normalization proof material, bypass/replace the independent checker, or
  let the normalizer emit its own acceptance result;
- co-change catalog parser/reachability/checker interpretation under unchanged
  catalog bytes/semantic identity, omit a `CatalogDenotation` digest from the
  certificate, or govern a relation-changing denotation edit as assurance-
  only;
- delete/ignore any semantic model field in the interpreter, map two admitted
  model values to the same canonical bytes, return an expected constant
  carrier, misclassify a field as nonsemantic, or interpret bytes different
  from the runtime/code-generation input;
- mutate only the executable interpreter/parser/runtime generator while
  preserving the formal denotation, omit its extensional-equivalence
  certificate, or treat a relation-changing implementation edit as
  assurance-only;
- replace a nondeterministic may/must outcome relation with one convenient
  function result;
- omit enabledness, admission, an ordered gate, may/must next-state
  transitions, or any other `SemanticComparisonCarrier` field from universal
  equality;
- permute coordinate/result tags between ledger and oracle, use a lossy or
  non-total comparison adapter, or make adapter behavior depend on the
  expected result;
- admit a parameterized certificate with `sorry`, a project/package semantic
  or `False` axiom, an unclassified third-party axiom, unpinned dependency,
  failed induction step, or invalid symmetry quotient;
- add an unlisted free proposition/local premise, leave a certificate premise
  unresolved, partially apply an earlier certificate, or omit one transitive
  concrete-relation/abstraction/`ContractModel` dependency from the
  certificate manifest;
- smuggle a premise through a subtype, proof-bearing structure,
  `Nonempty`/`Exists`, semantic `Decidable` instance, opaque function, or
  nested `Type`-valued parameter;
- bind a certificate to a finalized shard digest and create a certificate/
  shard content-addressing cycle, or change a `CoverageShardSpec` after proof;
- omit one multiplicity-component step or mixed-increment commutation lemma;
- remove an independence assumption, change its digest, force solver
  `unknown`, or introduce an unsupported theory;
- introduce contradictory assumptions, exclude an assigned witness, or encode
  the theorem conclusion as an assumption;
- taint a transition-oracle assumption through a catalog outcome,
  postcondition, variant, or evidence dependency;
- import a catalog-derived semantic bridge lemma into an oracle-equivalence
  certificate;
- create selector gaps or overlaps;
- mark a denotable rejected/unsupported coordinate `inapplicable`;
- create a domain-partition gap or overlap;
- change a boundary classifier result while leaving property-test samples
  unchanged;
- flip applicable and inapplicable;
- corrupt a foreign revision or digest;
- reverse an ordered pair;
- remove a self-pair;
- make a variant unreachable;
- delete a positive or negative witness;
- mutate a catalog outcome without changing oracle inputs;
- allow the transition oracle to consume an expected catalog, ledger, or
  witness outcome;
- co-mutate catalog and oracle rules without an `AssuranceChangeRecord`;
- collapse a class-specific acceptance-commit arm into generic intent;
- remove the atomic recovery binding from an acceptance-commit contract;
- rotate or garbage-collect an idempotency namespace across a crash and
  reclassify an old/unprovable key as new;
- omit a method idempotency-key policy or change its absent-key outcome;
- remove namespace-epoch/history retention or post-GC proof;
- reinterpret an existing subject's snapshotted retention after an operator-
  configuration change or omit the admission/commit revision race;
- remove or corrupt a Packet A concurrency-envelope projection;
- treat same-key/different-content idempotency as a new coordinate;
- change semantics under a stable ID;
- change the canonical digest without a change record;
- change a scope, interaction, assumption, oracle, witness, trial-set, or
  protocol-binding digest without an `AssuranceChangeRecord`;
- alter a pinned applicability vector while preserving counts;
- substitute provider evidence for a Core proof;
- pass a normalized backend observation without the authenticated
  evidence-decoder/provenance/digest chain;
- substitute a different verification decoder, change its source/build/
  executable or compatibility-certificate digest, or let an authorized issuer
  attest an artifact outside its policy;
- accept a Packet C self-asserted measurement, unpinned/revoked acquisition
  issuer, mismatched harness artifact, or unattested realized
  seed/schedule/fault/environment/evidence correlation;
- accept an unpinned, revoked, ambiguously valid, or Packet-C-controlled
  decoder-attestation issuer;
- replay a decoding attestation across a different repetition, seed, schedule,
  fault point, protocol binding, measurement payload, or freshness nonce;
- expose an observation commit without authorization ordering,
  observational equivalence, Packet F disclosure class, or secret-safe
  projection;
- submit a nested duplicate JSON key;
- use one measurement/evaluation to satisfy a different backend,
  target-runtime profile, version, trial, witness, or partition coordinate;
- omit a required repetition, seed, schedule, fault point, environment bound,
  or statistical decision rule from a backend report;
- mutate a measurement under the same content-addressed identity, accept an
  unauthenticated issuer, or drop a failed/inconclusive evaluation;
- suppress an evaluation before publication, omit it from
  `EvaluationEvidenceLog`, reuse an evaluation ID with different bytes, or
  bind a report to a non-latest/mismatched Evaluation-log checkpoint;
- retry one realized evaluation with a new nonce/time to create a second
  selectable slot head, key a slot by realized seed/schedule/fault, race two
  non-equivalent slot-head successors, bypass compare-and-append, omit a prior
  attempt from the aggregate, or let a report choose from a conflict state;
- include a terminal log entry, slot-head, receipt, checkpoint, or
  `SlotEvaluation`'s own digest in its hash preimage and create an aggregate/
  entry content-addressing cycle;
- let a Packet C binding select or replace the Packet E evaluator;
- pin a current dynamic report/checkpoint digest in the assurance baseline,
  mutate an existing `SupportEvidenceLog` entry, present a stale/forked head,
  or omit a failed/inconclusive report;
- bootstrap from an old valid checkpoint without a fresh nonce-bound witness
  quorum/genesis consistency proof or roll back durable last-seen state;
- treat an issuer-only or partial-quorum checkpoint as published, evaluate
  or launch a harness before a witnessed pending claim, bind a measurement to
  another attempt reservation, return without a quorum publication receipt,
  or withhold a newer checkpoint while keeping an older report current;
- embed a quorum receipt/signature in the log entry/root it attests, associate
  a receipt with different entry/checkpoint bytes, mutate lease state without
  an extending takeover entry, or permit takeover without valid
  clock/revocation/resolver proof;
- omit a predecessor/successor attempt-state digest, reuse a stale state,
  skip a phase/revision, terminate without a complete successor state, or
  promise conflict resolution without a `conflict-resolved` entry;
- resolve a conflict with a singular/partial CAS, omit or add an affected
  attempt state, or update the slot head separately from successor states;
- configure non-intersecting witness quorums, count one operator as multiple
  independent witnesses, or allow an honest witness to sign a rollback,
  non-extension, or inconsistent root;
- rotate/rekey to a new witness set without old/new quorum co-signature,
  initialize it from a stale prefix, omit policy epoch from a receipt, or use
  external recovery without invalidating old support and remeasurement;
- import `CoverageLedger` into a product generator; and
- regenerate expected identities or counts from the catalog under test.

No test may derive its expected identity universe, axis signature, cell count,
or applicability digest from the catalog it is testing.

## Diagnostics

Every invalid source or generated state produces:

- stable diagnostic ID;
- primary semantic path;
- related paths and foreign references;
- coverage-family and coordinate where applicable;
- authoritative phase;
- non-secret explanation;
- explicit remediation; and
- Packet F disclosure-class reference.

Diagnostics never render:

- secret values;
- provider credentials;
- raw provider payloads;
- unrestricted host paths;
- native stack traces; or
- unredacted evidence.

Authorization failure remains observationally equivalent across hidden target
existence states. This constraint belongs to Packet E even though Packet F
owns its presentation.

## Storage layout

The logical catalog is split by responsibility:

```text
docs/greenfield/research/invariants/packet-e/
  scope-manifest.json
  interaction-obligations.json
  proof-assumption-sets.json
  transition-oracle-vocabulary.json
  transition-oracle-rules.json
  semantic-comparison-carrier.json
  catalog-denotation.json
  catalog-source-field-reachability.json
  catalog-normalization-checker.json
  contract-model-interpreter.json
  parameterized-proof-certificates.json
  proofs/lean/
  review-baseline.json
  semantic-change-records.json
  assurance-change-records.json
  explanations.json
  domains.json
  semantic-variants.json
  methods.json
  system-triggers.json
  durable-operation-kinds.json
  process-completion-contracts.json
  observation-commit-contracts.json
  acceptance-commit-contracts.json
  idempotency-namespace-contracts.json
  recovery-contracts.json
  retention-policies.json
  evidence-requirements.json
  evidence-decoding-contracts.json
  multiplicity-contracts.json
  population-abstraction-contracts.json
  snapshot-classes.json
  snapshot-compatibility.json
  coverage-rules.json
  non-denotability-proofs.json
  backend-semantic-trial-sets.json
  backend-conformance-evaluators.json
  verification-decoder-artifacts.json
  conformance-evidence-trust-policies.json
  packet-c-conformance-protocol-imports.json
  packet-c-backend-report-imports.json
  packet-c-support-evidence-log-imports.json
  packet-f-measurement-acquisition-trust-imports.json
  packet-f-evidence-attestation-trust-imports.json
  witnesses/
    positive.json
    negative.json
    delegated.json
  schemas/
    scope-manifest.schema.json
    interaction-obligations.schema.json
    proof-assumption-sets.schema.json
    transition-oracle-vocabulary.schema.json
    transition-oracle-rules.schema.json
    semantic-comparison-carrier.schema.json
    catalog-denotation.schema.json
    catalog-source-field-reachability.schema.json
    catalog-normalization-checker.schema.json
    normalization-proof-material.schema.json
    catalog-normalization-certificate.schema.json
    contract-model-interpreter.schema.json
    parameterized-proof-certificates.schema.json
    review-baseline.schema.json
    semantic-change-records.schema.json
    assurance-change-records.schema.json
    explanations.schema.json
    domains.schema.json
    semantic-variants.schema.json
    methods.schema.json
    system-triggers.schema.json
    durable-operation-kinds.schema.json
    process-completion-contracts.schema.json
    observation-commit-contracts.schema.json
    acceptance-commit-contracts.schema.json
    idempotency-namespace-contracts.schema.json
    recovery-contracts.schema.json
    retention-policies.schema.json
    evidence-requirements.schema.json
    evidence-decoding-contracts.schema.json
    multiplicity-contracts.schema.json
    population-abstraction-contracts.schema.json
    snapshot-classes.schema.json
    snapshot-compatibility.schema.json
    coverage-rules.schema.json
    non-denotability-proofs.schema.json
    backend-semantic-trial-sets.schema.json
    backend-conformance-evaluators.schema.json
    verification-decoder-artifacts.schema.json
    conformance-evidence-trust-policies.schema.json
    packet-c-conformance-protocol-imports.schema.json
    packet-c-backend-report-imports.schema.json
    packet-c-support-evidence-log-imports.schema.json
    packet-f-measurement-acquisition-trust-imports.schema.json
    packet-f-evidence-attestation-trust-imports.schema.json
    evaluation-evidence-log-entry.schema.json
    evaluation-evidence-checkpoint.schema.json
    evaluation-slot.schema.json
    evaluation-attempt-coordinate.schema.json
    evaluation-attempt-state.schema.json
    slot-evaluation.schema.json
    support-evidence-log-entry.schema.json
    support-evidence-checkpoint.schema.json
    quorum-publication-receipt.schema.json
    witness-set-transition.schema.json
    current-support-evidence-view.schema.json
    backend-normalized-observation.schema.json
    backend-conformance-evaluation.schema.json
    witnesses.schema.json
    contract-model.schema.json
    family-instance-universe.schema.json
    coverage-shard-spec.schema.json
    coverage-shard.schema.json
    coverage-ledger.schema.json
    review-summary.schema.json
  generated/
    contract-model.json
    normalization-proof-material.json
    catalog-normalization-certificate.json
    family-instance-universes.json
    coverage-ledger.json
    review-summary.json
```

`normalization-proof-material.json` and
`catalog-normalization-certificate.json` are generated outputs with closed
schemas and their own canonical digests. They are excluded from the authored
catalog source-set digest they attest. The proof material binds that prior
source-set digest and emitted model digest; the checked certificate binds the
proof-material digest. Neither output can be reintroduced into its own hash
preimage.

JSON is an internal review and interchange representation, not Foampit's
public configuration language. JSON Schema validates closed structural shape;
the independent validators own relational and temporal checks. The revised
contract compiler may later consume or produce the same canonical
`ContractModel`.

Full `BackendMeasurement` and `BackendConformanceReport` instances live in
Packet C/F-controlled conformance and protected-evidence stores, not this
repository tree. Packet E owns only the provider-neutral normalized-observation
and evaluation/log-verification envelope schemas plus closed
revision/digest-bound Packet C protocol/report import summaries permitted by
Packet F. Operational measurement bodies and live log entries remain in
protected stores: Packet F controls their storage/disclosure, Packet E
controls Evaluation-log admission semantics, and Packet C controls
Support-log report publication. The repository pins only the closed envelopes
needed for independent verification.

## Data flow

```text
PacketEScopeManifest ─────────────┐
PacketEReviewBaseline ────────────┤
InteractionObligationManifest ────┤── verification only
ProofAssumptionSets ──────────────┤
TransitionOracleVocabulary/Rules ─┤
SemanticComparisonCarrier ────────┘

CoreContractCatalog ── normalizer ── ContractModel + normalization proof material
         │                                      │
         │                                      └── CatalogNormalizationChecker
         │                                                      │
         │                                      checked certificate + runtime-eligible model
         │                                                      │
         │                                                      ├── formal denotation
         │                                                      ├── verified interpreter/runtime tables
         │                                                      └── verified SDK/protocol generators
         │
         └── independent coverage expansion ── CoverageLedger
                                                   │
                                                   ├── jq exact-set validator
                                                   ├── CUE relational oracle
                                                   ├── interaction validator
                                                   ├── partition decision procedure
                                                   ├── witness transition oracle
                                                   └── mutation and review reports

BackendSemanticTrialSets ── requirements ── PacketCProtocolBindings
          │                                     │
          │                                     └── pinned harness ── raw evidence
          │                                                               │
MeasurementAcquisitionTrustPolicy ── observe/attest controls ──────────────┤
                                                                          └── BackendMeasurement
                                                                                   │
VerificationDecoderArtifact ───────────────────────────────────────────────────────┤
EvidenceAttestationTrustPolicy ── direct/attested decode trust ────────────────────┤
                                                                                   └── verified normalized observation
                                                                                                  │
          └─────────────────────────────────────────────── PacketE evaluator ◀─────┘
                                                                  │
                                                                  └── BackendConformanceEvaluation
                                                                                 │
ConformanceEvidenceTrustPolicy ── pending + quorum publication ── EvaluationEvidenceLog
                                                                                 │
                                                                                 └── PacketCBackendConformanceReport
                                                                                                │
ConformanceEvidenceTrustPolicy ── quorum publication ─────────────── SupportEvidenceLog
                                                                                                │
                                                                                                └── CurrentSupportEvidenceView
```

Neither scope/interaction/assumption/oracle manifests, review baseline,
coverage ledger, witnesses, backend measurements/evaluations, nor support
reports are accepted by a runtime or product code generator as semantic input.

## Exit conditions

This architecture record is implemented only when:

1. every JSON source/generated file has a closed schema, and every Lean source
   is dependency-pinned and kernel-checked;
2. the 32-method, system-trigger, invariant, semantic-rule, partition-contract,
   multiplicity-contract, population-abstraction, parameterized-certificate,
   proof-assumption, catalog-denotation, verification-decoder-artifact,
   trust-policy, and oracle-rule exact sets are independently pinned;
3. every shared variant, carrier-tagged result contract, durable Operation
   kind, Process completion, observation commit, acceptance commit,
   idempotency namespace, recovery coordinate, retention policy, evidence
   predicate/decoder, population abstraction, and Snapshot class is defined
   exactly once;
4. every Packet A/B/C/F import resolves to its pinned semantic revision and
   digest;
5. every required coverage family and axis signature matches the scope
   manifest;
6. every method/result/acceptance/semantic-variant combination has an exact
   admissibility classification;
7. every domain classifier is total and disjoint under an independent
   exactly-one proof;
8. every unconditional family product has an exact classification;
9. every `ProofAssumptionSet` is jointly satisfiable, entailed,
   domain-preserving, non-circular, and witness-preserving, and every
   oracle-equivalence dependency closure is exogenous/foreign-only; every
   certificate interface exactly matches its assumption set and independently
   reconstructed transitive dependency manifest;
10. the interaction candidate universe equals the complete unordered non-empty
    family-subset universe, with every logical-only singleton retained until a
    catalog-owned repetition proof validates and exact tuple count `2^N - 1`;
11. every family instance universe exact-matches the independently pinned axes,
    projections, facts, and imports; every multiplicity classification
    exact-matches the catalog and independent proof; and every population
    abstraction has kernel-checked domain equality/totality, permutation,
    complete-carrier congruence, forward/backward simulation, scalar or
    multi-index induction, mixed-increment commutation, and composition proofs;
12. every required interaction product has complete explicit cells or
    disjoint/exhaustive symbolic shards over all multiplicities, cardinality/
    Merkle commitments, and deterministic bounded expansion; every proved-
    independent candidate has a valid parameterized proof in the supported
    fragment;
13. the exact catalog/model pair has a full-domain normalization-preservation
    certificate, and every applicable finite cell or symbolic region proves
    ledger-to-`ContractModel` faithfulness and direct `ContractModel`-to-oracle
    equality over the complete `SemanticComparisonCarrier` relation, using
    exhaustive/replayable finite evidence or a kernel-checked universal
    certificate as appropriate, plus required witnesses;
14. every inapplicable cell or region has a machine-checked non-denotability
    proof;
15. every delegated cell remains visibly open and counts toward no false
    closure claim;
16. all Packet E/Packet E self-pairs, aggregate populations, and both Packet
    E/Packet A directions are present;
17. acceptance, recovery binding, idempotency namespace rotation/retention/GC,
    and their crash boundaries are atomically specified and covered;
18. every JSON source passes raw-byte duplicate-key preflight before parsing;
19. independent generator, catalog-source and model formal-denotation field
    reachability, independently checked normalization proof,
    parser/serializer round-trip, executable-interpreter/runtime-generator
    extensional equivalence, jq, CUE, Lean-kernel, partition, interaction,
    shard/cardinality, and transition-oracle checks agree;
20. assigned structural and temporal mutations are killed;
21. the review baseline and typed change records detect semantic or assurance
    shrinkage, applicability laundering, oracle co-drift, foreign drift, and
    circular expectations;
22. every backend report exact-joins all required trials, authenticated
    content-addressed measurements, and Packet E evaluations without dropping
    failures or inconclusive results; every evaluation verifies its
    acquisition/execution-control/raw-evidence/decoder/provenance chain under
    valid Packet F trust policies and the exact pinned verification decoder,
    and appears in the unique non-conflicted aggregate slot head in the latest
    quorum-published `EvaluationEvidenceLog` checkpoint with no
    pending/conflicted slot and no nonterminal attempt; and the unique current
    report covers that checkpoint and comes from a complete fork-evident
    `SupportEvidenceLog` under quorum-intersection, quorum-publication, durable
    anti-rollback, continuous witness-set handoff, and fresh
    quorum/genesis-bootstrap rules;
23. Gate 2A inventory validation passes for Packet E; and
24. Gate 4B and every backend support statement remain honestly open until
    their exact production hooks, tests, conformance protocols, required
    trials, and current backend measurements exist.

## Research reconciliation

### Durable operations and idempotency

Google's long-running Operation pattern supports a durable result carrier but
does not by itself prove Foampit's stronger target and postcondition semantics.
Stripe's idempotency contract demonstrates why result retention, exact
parameter comparison, concurrent-request behavior, and key expiry must be
separate explicit coordinates. Temporal documents at-least-once Activity
execution and recommends idempotent external effects; retries cannot create
exactly-once effects without a stronger atomic or adoption boundary.

The formal Durable Functions work proves an observably exactly-once model only
under explicit durable-store atomic-commit assumptions. Foampit therefore
records durable intent, external dispatch, observed evidence, and terminal
commit separately and never treats retry as proof of one effect.

### Runtime and provider lifecycle

OCI defines create, start, kill, and delete state requirements but leaves error
exposure largely unspecified. QEMU QMP includes commands whose return ordering
relative to completion events is undefined and asynchronous jobs that require
subsequent observation. Provider acknowledgement therefore remains weaker
than a Core success predicate.

E2B exposes running, paused, snapshotting, and killed behavior, including
memory-preserving versus filesystem-only pause and timeout-selected pause or
kill. Modal exposes a different created/scheduled/started/ready progression
and separate Snapshot orchestration. These are adapter and conformance inputs,
not a portable Core state vocabulary.

### Snapshot safety and recent architecture

Firecracker documents CPU and snapshot-format compatibility constraints and
warns that restoring one state more than once can duplicate random seeds,
identifiers, secrets, and cryptographic tokens. The `Restoring Uniqueness in
MicroVM Snapshots` work proposes explicit mechanisms for invalidating
snapshot-sensitive state. Fireworks and more recent high-concurrency Snapshot
systems demonstrate that argument injection, mapping, storage, and concurrency
mechanisms differ even when all advertise fast restore.

Foampit therefore makes component completeness, compatibility, source
disposition, restore count, external state, and uniqueness regeneration
separate schema dimensions. `ForkSandbox` cannot be defined as repeated native
restore.

## References

### Primary API and runtime contracts

- [Google AIP-151: Long-running operations](https://google.aip.dev/151)
- [Google AIP-155: Request identification](https://google.aip.dev/155)
- [Google AIP-193: Errors](https://google.aip.dev/193)
- [Google AIP-194: Automatic retry configuration](https://google.aip.dev/194)
- [Google AIP-211: Authorization checks](https://google.aip.dev/211)
- [Google long-running Operations](https://github.com/googleapis/googleapis/blob/master/google/longrunning/operations.proto)
- [OCI Runtime Specification: Runtime and lifecycle](https://github.com/opencontainers/runtime-spec/blob/main/runtime.md)
- [Kubernetes API conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [Temporal Activities and idempotency](https://docs.temporal.io/activities)
- [Stripe idempotent requests](https://docs.stripe.com/api/idempotent_requests)
- [QEMU Machine Protocol specification](https://www.qemu.org/docs/master/interop/qmp-spec.html)
- [QEMU QMP reference](https://www.qemu.org/docs/master/interop/qemu-qmp-ref.html)
- [Firecracker Snapshot support](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md)
- [Firecracker Snapshot versioning](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/versioning.md)
- [CRIU Checkpoint/Restore](https://criu.org/Checkpoint/Restore)
- [E2B Sandbox persistence](https://e2b.dev/docs/sandbox/persistence)
- [Modal Sandboxes](https://modal.com/docs/guide/sandboxes)
- [Modal Sandbox Snapshots](https://modal.com/docs/guide/sandbox-snapshots)

### Academic and formal foundations

- Sebastian Burckhardt et al.,
  [Durable Functions: Semantics for Stateful Serverless](https://dl.acm.org/doi/10.1145/3485510),
  OOPSLA 2021.
- Marc Brooker et al.,
  [Restoring Uniqueness in MicroVM Snapshots](https://arxiv.org/abs/2102.12892),
  2021.
- Dong Du et al.,
  [Catalyzer: Sub-millisecond Startup for Serverless Computing with Initialization-less Booting](https://dl.acm.org/doi/10.1145/3342195.3387532),
  ASPLOS 2020.
- In H. Shin et al.,
  [Fireworks: A Fast, Efficient, and Safe Serverless Framework Using VM-level Post-JIT Snapshot](https://dl.acm.org/doi/10.1145/3492321.3519581),
  EuroSys 2022.
- Lixiang Ao et al.,
  [FaaSnap: FaaS Made Fast Using Snapshot-Based VMs](https://dl.acm.org/doi/10.1145/3492321.3524270),
  HPDC 2022.
- Xingguo Pang et al.,
  [Expeditious High-Concurrency MicroVM SnapStart in Persistent Memory with an Augmented Hypervisor](https://www.usenix.org/conference/atc24/presentation/pang),
  USENIX ATC 2024.

## Consequence

The next artifact is an implementation plan for the exact storage layout,
schemas, independently pinned scope and review baselines, catalog records,
coverage generator, independent validators, witness oracles, mutations, and
Gate 2A review integration described here.

The plan must not expand Packet E into Packet A payload semantics, claim Packet
F disclosure closure, promote TypeSpec to semantic authority, or mark backend
conformance as measured without exercising a real backend.
