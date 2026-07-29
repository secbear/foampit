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

The machine-readable system has four distinct products:

1. `PacketEScopeManifest` independently fixes what must be covered.
2. `CoreContractCatalog` is the sole authored semantic authority.
3. `ContractModel` is the canonical normalized compiler and runtime input.
4. `CoverageLedger` is generated verification evidence and has no runtime
   authority.

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
| Process transport | `ReadProcessOutput`, `WriteProcessInput`, `CloseProcessInput`, `ResizeProcessTerminal` |
| Operation intent | `CancelOperation` |
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
- review status.

Packet E does not copy the request or result schemas. It classifies both
directions of every Packet E/Packet A concurrency boundary. Packet A owns
Packet A/Packet A compatibility.

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
- retention or deletion rules whose sole purpose is security or disclosure.

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
  identities.

Target realization and provider bindings remain Packet C-owned. Packet E may
require a capability but cannot claim that a target implements it.

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
| `SnapshotClass` | Portable retained-state capability definition |
| `SnapshotCompatibilityContract` | Compatibility and rebinding rules for Snapshot use |
| `ContractModel` | Canonical normalized semantic model |
| `CoverageLedger` | Generated, explicit, verification-only cell inventory |
| `PacketEReviewBaseline` | Independently approved hashes, counts, applicability vectors, and witness identities |
| `SemanticChangeRecord` | Predecessor-bound explanation of every semantic digest change |

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
- retention-policy IDs;
- evidence-requirement IDs;
- state and finite-partition axis IDs;
- Packet A, Packet B, Packet C, and Packet F imports; and
- required coverage-family definitions.

Each coverage-family definition fixes:

- stable family ID;
- ordered axis IDs;
- incoming and incumbent participant projections where applicable;
- output classification schema;
- exact expected-cell formula; and
- whether the family is required for Packet E scope closure, Core API closure,
  Gate 4B, or backend conformance.

The manifest is not derived from `CoreContractCatalog`. Exact-set validation
requires the catalog to define every required identity exactly once and no
unregistered identity.

### `CoreContractCatalog`

The catalog is a logical aggregate of focused source files. It owns:

- closed domains and discriminated unions;
- shared semantic variants;
- public methods;
- system triggers;
- durable Operation kinds;
- recovery coordinates;
- retention contracts;
- evidence predicates;
- authorization and non-disclosure constraints;
- Snapshot classes and compatibility rules;
- transition classifications;
- concurrency classifications; and
- transport-neutral success predicates.

No transport or provider string is authoritative unless it is itself a
reviewed Core stable identity. Provider error codes, status text, native
payloads, resource IDs, and event names live in conformance bindings.

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
retains source spans and contributor provenance.

### `CoverageLedger`

The ledger:

- enumerates every cell in every required coverage family;
- records its exact coordinate;
- records `applicable`, `inapplicable`, or `delegated`;
- links the applicable semantic outcome;
- links the reviewed applicability decision or unsatisfiability proof for an
  inapplicable cell;
- links the owning packet and revision for a delegated cell;
- links positive, negative, unsupported, or delegated witnesses;
- records coverage maturity; and
- reports exact counts and digests.

It is generated after semantic validation. Product generators and runtime code
must reject it as a semantic input.

## Catalog records

### Closed domains

Raw values are never treated as finite axes. Each infinite or large domain is
partitioned by semantic equivalence.

Examples:

- idempotency key: absent, equal-live, conflicting-live, equal-expired,
  conflicting-expired, malformed;
- runtime epoch: absent-allowed, exact-current, stale, future, malformed;
- etag: absent-allowed, exact-current, stale, malformed;
- deadline: absent-explicit, future, reached-before-acceptance,
  reached-after-acceptance, malformed;
- retention clock: before-expiry, at-expiry, after-expiry-with-hold,
  after-expiry-without-hold;
- output cursor: exact-retained, before-earliest-retained, at-sealed-end,
  after-sealed-end, malformed; and
- requested quantity: exact-minimum, valid-interior, exact-maximum,
  below-minimum, above-maximum, non-integral, overflow.

Partitions are named, disjoint, and exhaustive for their wire domain.
Boundary/property tests cover concrete values inside every partition.

### `MethodContract`

Every public method declares:

```text
MethodContract {
  methodId
  callClass
  origins
  requestSchema
  targetSchema
  successSchema
  durableOperationKind?
  orderedAdmissionRules
  acceptedResultCarrier
  allowedSemanticVariants
  recoveryContract
  successPredicate
  evidenceRequirements
  forbiddenInferences
  retentionPolicies
  capabilityRequirements
  concurrencyLane
  transportProjection
  disclosureClass
}
```

`acceptedResultCarrier` is one of:

- durable `Operation`;
- durable `Process`;
- committed Core-record result;
- durable Process-control receipt; or
- synchronous observation.

An accepted row names exactly one carrier. A rejected-before-acceptance row
names none.

### `SystemTriggerContract`

Every system trigger declares:

- stable trigger ID;
- owning subsystem;
- authenticated internal authority;
- triggering fact and freshness rule;
- target and expected epoch;
- durable intent requirement;
- linked public method or durable Operation kind;
- ordered admission rules;
- success predicate;
- evidence and forbidden inference;
- retry, reconciliation, and cleanup behavior; and
- observable event or Operation link.

Provider notification is evidence for a trigger, never the serialization
authority.

### `SemanticVariantRegistry`

Each shared variant declares:

- stable variant and family IDs;
- family: request error, recovery error, accepted known failure, ambiguity, or
  Process-control outcome;
- closed payload schema;
- applicability predicate;
- required proof;
- forbidden inference;
- caller recovery;
- private Core resolution;
- Packet F disclosure-class import;
- transport projection; and
- retention references.

Methods reference subsets of this registry. A method-local open error object,
provider error code, `retryable` boolean, or unregistered detail is invalid.

### `RecoveryContract`

Recovery is a tagged union by call class:

| Tag | Coordinate |
|---|---|
| `idempotent-request` | authenticated scope, method, idempotency key, canonical request digest |
| `process-control-sequence` | Process, Sandbox, runtime epoch, writer lease, sequence, canonical command digest |
| `existing-handle-intent` | exact durable Operation or Process handle plus intent kind |
| `atomic-etag-update` | resource, exact etag, canonical update digest |
| `observation` | resource identity plus cursor, condition, or freshness coordinate |

Every tag defines:

- equal-live replay;
- conflicting-live replay;
- equal-expired replay;
- conflicting-expired replay;
- malformed coordinate;
- target deletion;
- stale epoch or etag;
- result carrier;
- post-expiry recovery; and
- all related retention policies.

### `RetentionPolicy`

Retention is a closed tagged family, not one duration:

| Tag | Subject |
|---|---|
| `operation-result` | Operation and terminal result |
| `idempotency-record` | request digest, coordinate, and replay result |
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
- operator-selected value or immutable fixed value;
- allowed holds;
- expiry transition;
- access after expiry;
- deletion interaction;
- diagnostic;
- post-expiry recovery; and
- Packet F retention/disclosure reference where applicable.

An operator-configurable value is explicit in effective Operator
Configuration and in the affected resource's returned retention facts. An
omitted runtime value never selects a hidden duration.

### `EvidenceRequirement`

Evidence requirements contain only Core predicates:

- fact being proved;
- minimum authority;
- semantic identity and target;
- runtime and authority epoch;
- freshness;
- completeness;
- correlation requirements;
- accepted decoding versions;
- conflicting-observation behavior; and
- forbidden inference.

Provider adapters bind native observations to these predicates. Packet F
controls collection, storage, redaction, and disclosure. A provider
acknowledgement, command return, event, or absence is not proof unless its
binding establishes the exact predicate.

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

Coverage is a discriminated sum of bounded families, not one impossible
21-dimensional global product. Structural discrimination makes meaningless
cross-family combinations unrepresentable. Each family still expands the
complete Cartesian product of its declared finite axes.

The scope manifest requires at least these families:

| Family | Required axes |
|---|---|
| `method-admission` | method, origin, authorization, target visibility, capability, request validity, recovery coordinate, state precondition, epoch/etag freshness, ordered gate |
| `system-trigger-admission` | trigger, authority freshness, target state, triggering-fact freshness, incumbent lane, durable-intent state, ordered gate |
| `lifecycle-transition` | action, Sandbox state, execution admission, Process aggregate, Snapshot state, Operation state, target relation, result |
| `durable-acceptance-crash` | call class, crash phase, durable-intent fact, dispatch certainty, provider effect class, native identity, authority certainty, cancellation state |
| `recovery-and-idempotency` | recovery tag, coordinate state, canonical-content relation, retention state, target freshness, observed fact, recovery result |
| `process-control` | command, Process state, runtime epoch, writer lease, sequence relation, command relation, spool state, delivery fact |
| `process-output` | stream kind, Process state, cursor relation, retention, truncation, follow mode, output limit, sealing state |
| `snapshot-capture` | Snapshot class, source state, source disposition, Process aggregate, component completeness, quiescence, external resources, reference state |
| `snapshot-compatibility` | class, Artifact identity, profile identity, target compatibility, component availability, rebinding, source/target relation |
| `restore-fork-uniqueness` | action, source state, source disposition, restore count, uniqueness state, epoch allocation, ancestry, external connection state |
| `retention-and-expiry` | policy tag, subject state, clock partition, holds, deletion state, post-expiry access |
| `directional-concurrency` | incoming participant, incumbent participant, target relation, lane, state, capability, admission, coordination outcome |
| `evidence-and-inference` | claimed outcome, proof predicate, authority, freshness, decoding, conflicting evidence, forbidden inference, disclosure reference |
| `decoding-and-freshness` | boundary, version, authenticity, semantic identity, duplicate/delay/reorder state, accepted fact |
| `cleanup-orphan-reconciliation` | effect certainty, intent state, authority, provider-resource fact, adoption proof, compensation, deadline, final disposition |
| `transport-projection` | method, result branch, protocol, acceptance point, deadline layer, disconnect point, projected status |

The exact ordered axes and cell formulas are stored independently in
`PacketEScopeManifest`; the table above is normative minimum membership.

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

The manifest fixes the exact projection used by each context. Coverage
includes:

- every Packet E/Packet E ordered pair and self-pair;
- every Packet E-to-Packet A boundary direction; and
- every Packet A-to-Packet E boundary direction.

Packet A/Packet A remains Packet A-owned. Therefore Packet E may report
`packetEScopeTotal = true` while `coreApiTotal` remains false. Delegated
cross-packet cells never count as measured Packet E semantics.

### Applicability

The generator first creates each family's unconditional coordinate product.
Only then may a cell be classified:

- `applicable` — links one exact semantic outcome;
- `inapplicable` — links an independently reviewed applicability decision or
  a machine-checked unsatisfiability proof; or
- `delegated` — links an owner, semantic revision, digest, and closure status.

Selectors are authoring compression only. They must be disjoint and exhaustive
over the pre-existing product. A selector cannot define the product, introduce
a fallback, or make an unclassified cell disappear.

`PacketEReviewBaseline` pins the exact applicability-vector digest for each
family. Changing an applicable cell to inapplicable is a semantic change even
when counts remain equal.

### Reachability

Every admitted method, result variant, conditional partition, transition, and
permitted concurrency case has an independently authored positive witness.
Every rejection, unsupported result, inapplicable partition, and delegation
has its corresponding witness or proof.

Witnesses are checked by a transition oracle implemented independently of the
catalog normalizer. A generated trace is not its own proof.

Coverage maturity is explicit:

| Maturity | Meaning |
|---|---|
| `specified` | Exact cell, diagnostic, and witnesses exist and pass inventory validation |
| `model-verified` | Independent state/transition oracle accepts valid traces and rejects assigned mutants |
| `backend-measured` | The exact trace has been replayed against a real conforming backend/runtime |

Gate 2A requires `specified`. A production support claim requires the relevant
Gate 4B hooks and `backend-measured` evidence.

## Semantic change protocol

Every `ContractModel` semantic digest change requires one
`SemanticChangeRecord`, including additive changes.

The record contains:

- predecessor model digest;
- successor model digest;
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

The review baseline pins:

- exact stable identity sets;
- family definitions and axis signatures;
- per-family cell formulas and counts;
- exact applicability-vector digests;
- required witness identities;
- semantic-model digest;
- generated-ledger digest; and
- external import digests.

Changing the baseline without the matching change record is invalid.

## Validation architecture

The implementation uses independent mechanisms:

1. a dependency-free Node generator normalizes the source catalog and emits
   `ContractModel` plus `CoverageLedger`;
2. a separately implemented `jq` validator reconstructs required sets and
   coverage coordinates without importing generator code;
3. CUE validates closed structural and relational constraints over the
   generated products;
4. a separate transition oracle replays witnesses;
5. formal models consume only the canonical model and handwritten temporal
   properties; and
6. mutation tests attack the source, generator output, and review baseline
   independently.

Required mutations include:

- delete or add a catalog identity;
- shrink or expand a scope axis;
- delete a coverage family;
- remove an axis from one family;
- alter a family participant projection;
- change an expected-cell formula;
- create selector gaps or overlaps;
- flip applicable and inapplicable;
- corrupt a foreign revision or digest;
- reverse an ordered pair;
- remove a self-pair;
- make a variant unreachable;
- delete a positive or negative witness;
- change semantics under a stable ID;
- change the canonical digest without a change record;
- alter a pinned applicability vector while preserving counts;
- substitute provider evidence for a Core proof;
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
  review-baseline.json
  semantic-change-records.json
  domains.json
  semantic-variants.json
  methods.json
  system-triggers.json
  durable-operation-kinds.json
  recovery-contracts.json
  retention-policies.json
  evidence-requirements.json
  snapshot-classes.json
  snapshot-compatibility.json
  coverage-rules.json
  applicability-decisions.json
  witnesses/
    positive.json
    negative.json
    delegated.json
  schemas/
    catalog.schema.json
    contract-model.schema.json
    coverage-ledger.schema.json
  generated/
    contract-model.json
    coverage-ledger.json
    review-summary.json
```

JSON is an internal review and interchange representation, not Foampit's
public configuration language. JSON Schema validates closed structural shape;
the independent validators own relational and temporal checks. The revised
contract compiler may later consume or produce the same canonical
`ContractModel`.

## Data flow

```text
PacketEScopeManifest ───────┐
PacketEReviewBaseline ──────┼── verification only
                            │
CoreContractCatalog ── semantic validation ── normalization ── ContractModel
         │                                                    │
         │                                                    ├── SDK/protocol generators
         │                                                    ├── formal vocabulary
         │                                                    └── runtime contract tables
         │
         └── independent coverage expansion ── CoverageLedger
                                                   │
                                                   ├── jq exact-set validator
                                                   ├── CUE relational oracle
                                                   ├── witness transition oracle
                                                   └── mutation and review reports
```

Neither scope manifest, review baseline, nor coverage ledger is accepted by a
runtime or product code generator as semantic input.

## Exit conditions

This architecture record is implemented only when:

1. every source and generated file has a closed schema;
2. the 32-method exact set and every system trigger are independently pinned;
3. every shared variant, recovery coordinate, retention policy, evidence
   predicate, and Snapshot class is defined exactly once;
4. every Packet A/B/C/F import resolves to its pinned semantic revision and
   digest;
5. every required coverage family and axis signature matches the scope
   manifest;
6. every unconditional family product has an exact classification;
7. every applicable cell has one outcome and required witnesses;
8. every inapplicable cell has a reviewed decision or unsatisfiability proof;
9. every delegated cell remains visibly open and counts toward no false
   closure claim;
10. all Packet E/Packet E self-pairs and both Packet E/Packet A directions are
    present;
11. independent generator, jq, CUE, and transition-oracle checks agree;
12. assigned structural and temporal mutations are killed;
13. the review baseline detects semantic shrinkage, applicability laundering,
    foreign drift, and circular expectations;
14. Gate 2A inventory validation passes for Packet E; and
15. Gate 4B remains honestly open until production hooks, tests, and backend
    measurements exist.

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
