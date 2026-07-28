# Packet D Resource Composition and Driver Boundary Correction

Status: **Approved design correction — implementation and independent review
pending**

Date: 2026-07-24

## Decision

Packet D is reopened. Its first candidate matrix was structurally complete for
its declared 42-path universe, but that universe was semantically incomplete:

1. it modeled declarative source composition only for the Artifact Definition,
   even though Operator Configuration and the Managed-Sandbox Service
   Definition are also declarative Nix resources; and
2. it conflated a private resolved-driver handoff, serialized reentry,
   generated backend configuration, and forbidden direct/raw driver input.

The corrected model uses resource-qualified authoring paths and separates every
driver boundary by trust state. It does not preserve a smaller path count at
the expense of hiding distinct authority or validation behavior in prose.

## Alternatives considered

### Selected: resource-scoped paths and explicit driver trust states

Each declarative resource has its own source-composition paths and final
validator. Private runtime stages, serialized candidates, product-generated
backend configuration, and forbidden external inputs have separate paths.

This produces the largest matrix, but ownership, phase, identity, and rejection
claims remain independently reconstructable.

### Rejected: generic composition paths shared by every resource

A generic import, override, or refinement path could use value cases to switch
between Artifact, Operator, and Service ownership. That reduces the path count
but makes the selector path itself ambiguous and permits owner- or phase-specific
requirements to disappear inside value-case prose.

### Rejected: defer the omitted resources and resolved reentry

Packet D could be narrowed to Artifact composition only, leaving Operator,
Service, and serialized runtime boundaries to later work. That is incompatible
with the claim that Packet D closes all supported configuration and bypass
routes. Packets E and F may own lifecycle and disclosure semantics, but they do
not own composition bypass prevention.

## Resource-scoped source phases

`P1` remains the common language source-semantics phase. It now branches into
three distinct resource pipelines:

```text
Artifact source
  P1 -> A0 -> A1 -> W0 -> N0 -> N1

Operator Configuration source
  P1 -> OC0 -> O0 -> H0

Managed-Sandbox Service Definition source
  P1 -> MS0 -> S0 -> C0 | L0 | E0 | T0
```

The new internal review phases are:

| Phase | Label | Complete information available |
|---|---|---|
| `OC0` | Operator Configuration validation | Fully composed declarative Operator Configuration, its dependency closure, contributor ledger, typed registrations, hard ceilings, credential references, and native-extension summaries |
| `MS0` | Managed-Service Definition validation | Fully composed desired service definition, its dependency closure, contributor ledger, typed Core API intent, and service-owned reconciliation metadata |
| `RW0` | Resolved reentry wire validation | One closed, bounded, versioned serialized runtime-stage candidate before it can reenter creation resolution |

`OC0` and `MS0` are not new public resources. They name the final
product-owned validators for the two resources that already exist.

`RW0` is not Artifact canonical wire. It has a separate envelope, size/depth
limits, schema versions, identity domain, migrations, and diagnostics.

## Corrected path universe

The amended universe contains exactly **54 paths**. Implementations derive the
path and invariant dimensions from the registries, then compare those derived
dimensions with exact independently reviewed pins in the generator and
validator. The pins are review anchors; they do not replace derivation or
semantic relationship checks.

### Artifact source paths

The eight existing unqualified IDs are renamed because their old names encoded
the false assumption that Artifact was the only declarative resource:

- `artifact-ordinary-authoring`
- `artifact-imports`
- `artifact-import-order`
- `artifact-profile-expansion`
- `artifact-explicit-override`
- `artifact-semantic-refinement`
- `artifact-strongest-override`
- `artifact-native-language-escape`

Historical invariant composition-path names remain aliases only. They do not
remain first-class reviewed paths.

### Operator Configuration source paths

- `operator-configuration-authoring`
- `operator-configuration-imports`
- `operator-configuration-precedence`
- `operator-configuration-refinement`
- `operator-configuration-native-escape`

`operator-configuration-precedence` contains ordered definitions, declared
replaceable defaults, ordinary overrides, stronger priority, and
`mkForce`-class attempts as explicit value cases. Creating one path per Nix
operator would add mechanism aliases without changing authority or boundary
semantics.

The path may contribute only Operator-owned configuration. It may select
registered driver, provider, placement, and infrastructure alternatives and
may narrow hard global ceilings. It cannot author Artifact, Create, Service,
live, Exec, framework, or runtime facts.

Named Operator profiles or a distinct Operator default-expansion feature are
not currently supported. Adding either reopens Packet D.

### Managed-Service Definition source paths

- `managed-service-definition-authoring`
- `managed-service-definition-imports`
- `managed-service-definition-precedence`
- `managed-service-definition-refinement`
- `managed-service-definition-native-escape`

Precedence value cases cover declared service defaults, definition order,
ordinary overrides, stronger priority, and force-class attempts. The source
paths may contribute only Service-owned desired state and reconciliation
metadata. Concrete Create, live, Exec, or teardown operations become
boundary-input only after the existing managed-service translation path
constructs the typed Core Sandbox API request.

Named Service profiles or a second lifecycle engine are not supported. Adding
either reopens Packet D.

### Driver and resolved-state paths

The former `corrupted-resolved-input`, `direct-driver-input`, and
`raw-runtime-config` paths are replaced by five unambiguous paths:

| Path | Meaning | Authority contract |
|---|---|---|
| `resolved-driver-handoff` | Product-owned in-process private stage | Only product constructors produce `ResolvedCreation`, admitted/preflighted stages, and `PreparedLaunch`; later stages may narrow or add owned observations but cannot rewrite earlier identity |
| `serialized-resolved-reentry` | Persisted, IPC, network, cache, restore, or otherwise deserialized representation | Entire input is untrusted at `RW0`; it reconstructs fresh private stages only after complete replay |
| `generated-runtime-configuration` | Total backend-specific configuration generated from `PreparedLaunch` at D0 | Product-owned transformation followed by exact closed validation and backend-default suppression |
| `direct-driver-invocation` | Caller, adapter, provider, plugin, or arbitrary object attempts to call a driver directly | No authority; structurally unavailable and defensively rejected before external mutation |
| `raw-runtime-config-input` | Arbitrary map, evaluator value, shell arguments, provider defaults, or deserialized backend configuration | No authority; structurally unavailable and defensively rejected before external mutation |

Generated backend configuration is D0 output. It is never a supported external
input format.

## Serialized resolved reentry

An authenticated envelope proves only who sent bytes. It never proves their
semantic validity or grants a private product type.

Reentry performs, in order:

1. strict bounded `RW0` decoding with an exact closed schema;
2. Artifact and member lookup by immutable product identity;
3. the same 89-invariant built-member/load replay used for an untrusted built
   manifest;
4. construction of a fresh private C0 candidate;
5. replay of the following 30 resolved-stage invariants through their existing
   authorities; and
6. creation of a new `PreparedLaunch` only after current O0 and H0 acquisition.

The 30 resolved-stage invariants are:

| Authority | Invariants |
|---|---|
| `C0` | `XRS-001`, `XRS-002`, `TGT-002`, `TGT-003`, `CRT-001`–`CRT-006`, `IDT-002`, `MAN-001`–`MAN-006` |
| `O0` | `XRS-006`, `OPS-001`, `OPS-002` |
| `H0` | `HOST-001`–`HOST-004`, `PRV-001` |
| `D0` | `XRS-003`, `XRS-004`, `HOST-005`, `WIRE-004`, `DRV-001` |

Profile- or provider-conditional rules remain in the replay set. The selected
profile determines their valid absence or applicable case; “not applicable”
does not remove a cell.

File descriptors, opened objects, leases, provider reservations, and other H0
handles are non-serializable. Reentry reacquires them. A path, token, or
provider object ID cannot recreate retained-object authority.

## Private stage and identity rules

The public construction API exposes no forgeable “validated” record shape:

```text
ResolvedReentryBytes --RW0--> DecodedResolvedCandidate
DecodedResolvedCandidate --C0/O0/H0 replay--> PreparedLaunch

VerifiedManifest + CreateSandbox --C0--> ResolvedCreation
ResolvedCreation --O0/H0--> PreparedLaunch
PreparedLaunch --D0--> GeneratedRuntimeConfiguration
```

The private identity chain binds:

- verified Artifact semantic identity;
- built member identity and runtime-profile identity;
- canonical Create request digest and idempotency scope;
- selected Operator registration and implementation-bundle identity;
- current admission decision;
- retained binding-object identities and current provider/host acquisitions;
  and
- the exact driver protocol and generated-configuration schema version.

Each boundary extends the identity rather than trusting copied downstream
claims. Deserialization can produce only an untrusted candidate.

## New invariants

Packet D registers ten additional invalid states:

| ID | Owner | Invalid state |
|---|---|---|
| `OPS-003` | operator | Operator Configuration dependency closure is mutable, incomplete, ambient, or not reproducible offline |
| `OPS-004` | operator | Operator composition precedence or contributor provenance is ambiguous, incomplete, or permits a force-class bypass |
| `OPS-005` | operator | A native/freeform source escape constructs validated Operator Configuration without the `OC0` validator |
| `SVC-003` | service | Managed-Service Definition dependency closure is mutable, incomplete, ambient, or not reproducible offline |
| `SVC-004` | service | Service composition precedence or contributor provenance is ambiguous, incomplete, or permits a force-class bypass |
| `SVC-005` | service | A native/freeform source escape constructs a validated Managed-Service Definition or direct driver action without `MS0` and the typed Core API |
| `WIRE-007` | runtime | A serialized resolved-stage envelope is open, unbounded, ambiguously decoded, unsupported, or accepted without strict versioned decoding |
| `DRV-002` | runtime | Deserialization, copying, a cache hit, or a foreign object mints a private validated runtime stage |
| `DRV-003` | runtime | `PreparedLaunch` identity omits or fails to rederive an earlier product identity, registration, admission, or retained-object binding |
| `DRV-004` | runtime | A driver accepts anything other than the product-owned private `PreparedLaunch` stage or accepts raw/backend-default configuration as input |

The exact corpus statements, witnesses, hooks, diagnostics, and tests are part
of the implementation plan. All production hooks and tests remain `planned`.

## Machine-proof requirements

The corrected generator and validator must:

- derive the exact path and invariant counts; no literal 42-path assumption
  remains;
- expand every path × invariant cell exactly once;
- reject active contribution, selection, or refinement outside
  `reachableOwners`;
- derive target-profile applicability from the path registry and reject a
  broader case catalog;
- require the exact native-handle tuple wherever `NAT-002` or `NAT-003` is an
  active or boundary-input cell;
- require CLI/framework parity for typed Create, live, and Exec requests;
- encode Packet E/F concern taxonomies, not only packet labels;
- encode separate-path provider handoffs without creating impossible phase
  cycles;
- pin the exact invalid-witness count;
- forbid a path from claiming that an earlier phase rejects corruption
  introduced only after that phase; and
- treat coordinated digest updates as review friction, not as an independent
  semantic proof.

Semantic relationship checks are authoritative. Digest pins detect accidental
drift and force explicit review, but they cannot authorize an otherwise
invalid coordinated rewrite.

## Executable evidence

The research suite must add:

1. Operator and Service Nix module controls for imports, dependency pinning,
   definition precedence, declared defaults, ordinary and force-class
   overrides, semantic narrowing, complete contributor provenance, closed
   outputs, and final-validator replay.
2. Nearby invalid cases in which the Nix module system represents the attempted
   bypass before `OC0` or `MS0` rejects it.
3. A resolved reentry validator that proves strict `RW0` decoding, complete
   89+30 replay, deterministic reconstruction, and reacquisition of
   non-serializable H0 state.
4. A private-stage type witness showing that direct/raw driver entry is not a
   supported construction path.
5. Generated runtime-configuration cases covering total field projection,
   backend-default suppression, exact schema validation, and rejection after
   direct corruption.

These are disposable decision witnesses. They do not become the production
runtime or close Gate 4B.

## Exit condition

Packet D may return to **Reviewed** only when:

- the amended path registry and new invariants are integrated into the real
  inventory;
- all generated cells and semantic relationship checks pass;
- the full prototype suite passes from the pinned environment;
- Gate 4B still fails only for honestly planned production hooks/tests; and
- fresh independent cold-reader and adversarial reviews reconstruct the
  resource ownership, driver trust states, replay sets, phases, and delegation
  without relying on explanatory prose.
