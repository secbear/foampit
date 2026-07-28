# Packet C Target and Provider Realization Review

Status: **Reviewed — independent cold-reader and schema-integrity review complete**

Date: 2026-07-24

Packet C classifies every reviewed Packet B Artifact field against the four
initial runtime-profile review coordinates and separately specifies remote
provider transport. It does not select public product names and does not claim
that planned drivers or conformance suites already exist.

## Reviewed inputs and outputs

Inputs:

- 81 reviewed Artifact fields in
  [`PACKET-B-ARTIFACT-FIELDS.json`](./PACKET-B-ARTIFACT-FIELDS.json);
- the locked ownership and phase model;
- direct Bubblewrap, jail.nix, microvm.nix, Firecracker, Cloud Hypervisor, OCI,
  Modal, and E2B primary-source research; and
- the existing invariant registry and executable corpus.

Outputs:

- 4 complete runtime-profile bundle records in
  [`PACKET-C-TARGET-PROFILES.json`](./PACKET-C-TARGET-PROFILES.json);
- 45 realization selector rules expanding to exactly 324 non-overlapping
  Artifact-field × profile cells in
  [`PACKET-C-TARGET-REALIZATION.json`](./PACKET-C-TARGET-REALIZATION.json);
- 85 structurally complete, ordered value-case definitions across those rules;
- 85 generator-owned exact structured case contracts in
  [`PACKET-C-CASE-CONTRACTS.json`](./PACKET-C-CASE-CONTRACTS.json);
- 3 separate provider transport contracts in
  [`PACKET-C-PROVIDER-CONTRACTS.json`](./PACKET-C-PROVIDER-CONTRACTS.json);
- 7 newly registered invariants plus strengthened `TGT-003` and `DRV-001`; and
- focused validators with positive and negative fixtures.

The generated realization document and exact case-contract catalog are checked
for drift against
[`generate-target-realization.mjs`](./generate-target-realization.mjs).
The validator separately pins the SHA-256 of the complete profile registry and
case catalog. Generation is therefore convenient and reproducible, but is not
its own review authority: a coordinated source/catalog rewrite fails until an
explicit validator-pin review changes the independent anchor.
`fieldTraceability` preserves each Packet B field's exact invariant and
unresolved-packet links even when several fields share one realization rule.

## Locked claim and ownership boundary

Artifact source selects or requires target/profile identities and portable
semantics. It cannot author:

- successful construction;
- target-member identity;
- profile compatibility;
- supported capabilities or operations;
- passing conformance; or
- current host/provider availability.

The target-member builder emits content/member/Artifact Set identities,
compatible runtime profiles, complete implementation requirements, and
member-bound conformance evidence. Manifest load treats those facts as
untrusted and verifies them. Create selects one advertised profile and supplies
per-Sandbox bindings. Operator registration maps that profile to exact
drivers, helpers, executable builds, hosts, and providers. Host preflight
verifies the concrete bundle. Driver preparation emits total target
configuration. Runtime probes establish only facts that cannot be soundly
known before launch.

Transport is never a target. Running an OCI member through a remote provider
does not create a “Modal target” or “E2B target,” and provider selection does
not change portable semantic identity.

## Runtime-profile meaning

A runtime profile names the complete behavior-affecting bundle, not one
backend executable:

| Profile coordinate | Product-owned boundary | Reused mechanism | Distinguishing hard requirements |
|---|---|---|---|
| `bubblewrap-linux-v1` | member builder, mount/argv compiler, pre-exec launcher, path resolver, cgroup/network/secret/lifetime supervisors, evidence | non-setuid Bubblewrap `v0.11.2` at `1b80120…` | strict namespaces; FD-safe mounts; no try/fallback operations; no setuid mode |
| `microvm-firecracker-linux-v1` | microVM build adapter, guest runtime, Firecracker driver, outer supervisors, snapshot orchestration, evidence | microvm.nix guest builder at `fa5340…`; Firecracker at `c1490c…`; jailer | no live directory share; exact device and jail/cgroup/serial baseline; exact snapshot envelope |
| `microvm-cloud-hypervisor-linux-v1` | microVM build adapter, guest runtime, CH/virtiofsd driver integration, outer supervisors, snapshot orchestration, evidence | microvm.nix at `fa5340…`; Cloud Hypervisor at `aa1981…`; virtiofsd `v1.14.0` at `c2540f…` | `nested=false`; fail-closed outer confinement; explicit device baseline; qualified virtiofs only |
| `oci-linux-v1` | Nix image adapter, product manifest, runtime-config generator, descriptor verifier, policy integrations, evidence | registered pinned OCI implementation under Image/Runtime/Distribution contracts | all image/runtime defaults suppressed; no input/provider hooks; implementation-specific capabilities proven |

The profile IDs above are stable review coordinates, not production-advertised
identities. The revisions are research snapshots. A production identity and
digest must bind every exact owned and external builder, driver, launcher,
guest runtime, helper, protocol, conformance suite, kernel/host envelope, and
default-suppression contract. Until that complete registry closure and its
member-bound evidence exist, the profile cannot be advertised. An operator may
register another exact implementation only through a profile-compatible
registration and applicable conformance evidence; no moving branch or nominal
compatibility claim is sufficient.

The profile registry represents this with closed
`productionIdentityContract`, `memberSharingContract`, and `claimAuthority`
objects. Reader-facing identity, bundle, unsupported-set, default-suppression,
precondition, and ownership prose is explicitly named and classified as
non-normative explanation. The complete registry digest is independently
pinned by the validator, while exact support/rejection semantics remain in the
case-contract catalog.

One byte-identical blob may be reused. One member manifest may advertise
multiple profiles only when independent evidence proves each profile
compatible and their immutable hard requirements are identical. Firecracker
and Cloud Hypervisor therefore normally use distinct member manifests even
when their guest content blobs deduplicate.

## Realization outcomes

Each field/profile cell expands into a structurally exhaustive, ordered value
partition. The validator accepts only one all-values case, a predicate followed
by `otherwise`, or omission plus a presence-requiring predicate followed by
`otherwise`. Constraint cases carry a stable `predicateId` equal to their
rule/case diagnostic identity. Those IDs are implementation coordinates for
Gate 4B; the current corpus validates partition shape and traceability but does
not pretend that the semantic predicates are executable yet. Each case has
exactly one primary outcome:

| Outcome | Meaning |
|---|---|
| `conforming-lowering` | The value or explicit absence is preserved in constructed content/manifest without a later target choice. |
| `build-time-unsupported` | The enabled profile cannot meet that value. A profile-static incompatibility rejects at Artifact final validation (`A1`); a fact requiring real construction rejects at target-member build (`N1`). Neither publishes a member/profile support claim. |
| `runtime-requirement` | Reserved for a value-free contract whose complete truth is established before start. No current Packet C case ends here because dynamic binding semantics require effective `R1` evidence. |
| `observed-conformance` | The driver configures the declared semantic, but readiness waits until its `R1` positive/negative probe succeeds. |

There are 36 unsupported, 10 conforming, 0 runtime-requirement, and 39
observed-conformance case definitions. These are case-definition counts, not
capability scores: selectors may apply one case to several fields/profiles, and
partitioned cells contain multiple value alternatives.
Of the unsupported definitions, 26 are profile-static `A1` rejections and 10
require real member construction and reject at `N1`.

Every case also records first-sound phase, deadline, authority, typed
realization steps, stable step and manifest-projection obligation IDs,
forbidden fallback/approximation,
diagnostic paths/remediation, evidence, invariant references, and optional
case-specific later-packet delegation. Exact Packet B invariant and unresolved
Packet D/E/F delegation is recorded per field in `fieldTraceability`; the
case-level `delegatedPackets` array is only for additional case-specific
delegation and is intentionally empty when none exists. The validator rejects
a missing/overlapping cell, unsupported partition shape, missing predicate
coordinate, late unsupported result, authority that names no exact realization
step, missing dynamic ownership phase, mutated fail-closed safety policy,
freeform prose substituted for a structured control/obligation field, unknown
key/traceability reference, or placeholder. The exact 81-field × four-profile
universe and absolute 324-cell count are locked rather than derived from a
shrinkable input set.

Only closed control fields and stable obligation identifiers are normative in
the machine records. Human-readable step/manifest explanations, rationales,
and remediation are explicitly non-normative and cannot override safety,
defaults, evidence, phase, authority, or lowering. This avoids pretending that
a finite phrase scanner can understand arbitrary contradictory prose.
The separate generated, independently digest-pinned case-contract catalog fixes
each case's condition,
outcome, first-sound phase, deadline, authority, ordered phase/mode/component
chain, evidence-class set, and later-packet delegation. A self-consistent
rewrite of the realization record therefore fails rather than becoming its own
source of truth.

For `observed-conformance`, `firstSoundPhase` is the earliest phase that can
soundly classify the value into this realization path and begin its
obligations. It does not claim the outcome is true at that phase. Only the
declared `R1` authority and post-start probe establish conformance.

Dynamic cases record their complete ownership chain instead of jumping from a
member manifest to the driver: workspace/bindings, storage, scratch, network,
resources, devices, secrets, and lifetime traverse their applicable `C0`
Create resolution, `O0` operator binding, `H0` concrete preflight, `D0`
preparation, and `R1` observation. Security policies similarly record
operator binding and host preflight before preparation. A phase is omitted
only when that resource has no fact owned there.

The detailed research phase names map to product phases as follows:

| Research vocabulary | Product vocabulary |
|---|---|
| Bubblewrap `B`, `C`, `O`, `P`, `D`, `S` | `N0/N1`, `C0`, `O0`, `H0`, `D0`, `R1` |
| microVM `B`, `ML`, `C`, `O`, `P`, `D`, `R` | `N0/N1`, `C0` manifest load, `C0` Create, `O0`, `H0`, `D0`, `R1` |

## Explicit baseline unsupported set

The complete condition-level list is in the realization JSON. The important
baseline exclusions are:

### Bubblewrap

- non-Linux or unregistered foreign-architecture workloads;
- an identity/group/capability relationship the non-setuid user-namespace
  launcher cannot install exactly;
- unregistered workspace/binding/ownership semantics;
- a bounded private writable root without a registered quota-backed extension;
- a separate workload-only memory bound;
- logical-path or shared-device I/O performance bounds;
- any snapshot requirement;
- an unregistered network/DNS/ingress/channel, kernel-policy, device,
  secret-delivery, or lifecycle operation.

### Firecracker

- mandatory live host-directory workspace;
- launch without jailer or separately evidenced stronger confinement;
- an undeclared device, MMDS, passthrough, pmem/hotplug, or unbounded serial
  path;
- a memory/resource claim that collapses VMM-total and guest-workload scopes;
- I/O semantics not exactly attributable to a dedicated device/mechanism;
- filesystem-inclusive, secret-excluding, portable-host, or clone-safe
  snapshot claims without complete owned orchestration; and
- any snapshot/restore outside the exact VMM/guest/kernel/CPU/storage/device/
  secret/identity compatibility envelope.

### Cloud Hypervisor

- live virtiofs without shared memory, safe path resolution, helper
  confinement/accounting, exact ownership translation, and access probes;
- AF_UNIX isolation claimed from Landlock alone;
- nested virtualization, OEM credentials, passthrough/vhost-user,
  console/debug, helper sockets, or devices outside the profile baseline;
- best-effort Landlock/seccomp/outer confinement;
- unattributable I/O semantics; and
- filesystem-inclusive or cross-build snapshot claims without owned
  orchestration and evidence.

### OCI

- inability to suppress image entrypoint, command, environment, user, cwd,
  volumes, ports, stop behavior, writable root, and runtime defaults;
- Artifact/provider lifecycle hooks or opaque runtime mutation;
- a bounded private writable root without a registered quota-backed runtime
  profile;
- snapshots, because OCI Runtime v1 defines no complete product snapshot
  contract;
- I/O bounds on shared or unattributable storage; and
- unregistered runtime-specific devices, policies, annotations, channels, or
  lifecycle operations.

Across all targets, a mandatory network, resource, security, device, secret,
operation, or protocol semantic without exact mechanism and evidence is
unsupported. The target never disappears, chooses a different profile,
weakens the value, or emits a warning-only member.

## Target-specific lowering boundaries

### Filesystem and workspace

The Artifact contains destinations, access/ownership ceilings, logical slots,
capacity ranges, and permitted materializations. Concrete paths, volumes,
provider objects, and attachment mechanisms remain Create/operator state.
Dynamic sources are resolved to stable object handles retained through
attachment (`HOST-005`).

Bubblewrap supports owned copy or FD-safe bind classes. Firecracker supports
copy-in or prepared block. Cloud Hypervisor additionally supports qualified
virtiofs. OCI supports only mount/volume classes whose registered runtime
preserves path, ownership, propagation, capacity, and access semantics.

### Network and host channels

Bubblewrap namespaces, VMM network devices, and OCI namespaces are mechanisms,
not the portable policy. Product-owned host enforcement supplies egress, DNS,
ingress, proxy/credential, and typed channel semantics. Resolver files, host
network namespaces, sockets, buses, descriptors, and provider endpoints are
never inherited.

### Resources

Every bound retains unit, dimension, minimum/maximum, and Sandbox/workload
scope. Relative weights do not become hard rates. VMM memory size does not
become total or workload memory evidence. Complete process-tree cgroup
membership, VMM/guest settings, effective readback, and exhaustion probes are
separate obligations. I/O is supported only with exact resource-to-device
attribution and representable direction/dimension.

### Security, devices, and secrets

Workload policy and outer driver/VMM confinement are distinct. Seccomp,
Landlock, VMM jails, namespaces, capabilities, devices, and host channels never
stand in for one another. Device baselines and every authority projection are
explicit.

Secret manifests remain value-free. Bubblewrap/OCI use owned ephemeral
descriptor/file/environment/credential delivery; microVMs use authenticated
guest-runtime/vsock delivery. Values never enter Nix/store/image content,
MMDS, OEM strings, manifests, identity, diagnostics, or evidence. Delivery
audience, mode, expiry, cleanup, and snapshot treatment must all be enforceable.

### Snapshot and operations

Snapshot is a component and compatibility contract, not a boolean. Bubblewrap
and baseline OCI advertise none. microVM support separately accounts for
memory, VMM state, external disks/storage, devices, quiescing, secrets,
VMM/driver/guest/kernel/CPU compatibility, and clone identity refresh. The live
operation rechecks current state under `SNP-002`.

All other optional operations are individually versioned and conformed. PTY,
pause, resume, resize, snapshot, restore, and fork cannot share a generic
capability.

## Provider contracts

Packet C locks three transport modes:

1. **Prebuilt member transfer** verifies the target member before and after
   transfer and cache lookup. Provider object IDs remain runtime metadata.
2. **OCI descriptor transfer** verifies the digest-addressed descriptor graph
   and its linked product manifest. Tags are never identity.
3. **Provider-side construction** requires a versioned product protocol,
   pinned inputs, explicit provider-default suppression, returned output
   identity, provenance, and semantic/runtime conformance evidence. Without
   those, the adapter is explicitly provider-native and non-conforming.
   It is an `N0`/`N1` remote target-member builder: the returned member and
   Artifact Set re-enter manifest verification before `C0`. It never mints a
   new member after Create has selected a profile.

Provider caches are untrusted optimizations. Credentials and workload secret
values stay outside Artifact identity. Retention and deletion are explicit
operator/provider policy and affect availability, never semantic identity.
Each transport contract names its admission window and an exact
contract-specific phase/component authority. Closed safety enums require
fail-closed behavior, explicit-only defaults, mandatory verification,
warning-insufficient decisions, untrusted verified caches, Create-only
workload-secret bindings, credentials owned by Operator Configuration, and
explicit operator retention with no Artifact-identity effect. The validator
rejects an authority outside that window, a wrong adapter, or any undeclared
contract field. Identity behavior, unsupported disposition, verification,
required and forbidden inputs, admission requirements, runtime evidence, and
unsupported conditions are closed contract-specific fields or exact typed
obligation-ID sets. Their accompanying explanations and examples are
non-normative and cannot authorize a substitute.

## New and strengthened invariants

New:

- `MAN-005` — complete target-manifest projection;
- `MAN-006` — profile/member sharing only under identical hard requirements
  and independent evidence;
- `HOST-004` — concrete runtime implementation bundle matches the profile;
- `HOST-005` — filesystem source identity survives preflight-to-driver handoff;
- `SNP-002` — live snapshot/restore matches current compatibility state;
- `PRV-001` — content-preserving provider transfer verifies identity; and
- `PRV-002` — provider-side construction supplies equivalence evidence.

Strengthened:

- `TGT-003` now binds support facts to the exact member, complete profile
  bundle, build features, suppressed defaults, and versioned conformance
  evidence across all enabled targets.
- `DRV-001` now requires total generated target configuration and forbids
  backend defaults, try/fallback behavior, raw hooks, and implicit inheritance.

## Explicit Packet D–F delegation

Packet C resolves all Packet B delegations to Packet C. The following remain:

### Packet D

- `artifact.profile.compositionPaths`
- `artifact.provenance.native`
- `artifact.targets.nativeConstruction`

Packet D must prove every ordinary and strongest profile/import/override/native
path reaches the same final validator and cannot bypass these target results.

### Packet E

- `artifact.workspace.runtimeTransferExclusion`
- `artifact.lifecycleRequirements.maximumLifetimeEnforcement`
- `artifact.lifecycleRequirements.snapshot`
- `artifact.lifecycleRequirements.optionalOperations`
- `artifact.outputs.runtimeCollection`

Packet E must lock and exhaustively walk the operation state machine,
allocation/reservation, mutation, retry, cancellation, partial failure,
rollback, teardown, snapshot/restore, and output-collection behavior.

### Packet F

- `artifact.environment.ambientExclusion`
- `artifact.filesystem.topology`
- `artifact.requirements.enforcement`
- `artifact.provenance.requirements`
- `artifact.provenance.native`
- `artifact.provenance.builtIdentities`

Packet F must prove runtime disclosure, inherited descriptor/socket/environment
exclusion, protected-path behavior, secret-safe diagnostics/logs/evidence, and
claimed-versus-observed conformance.

## Verification and remaining limits

The inventory gate runs:

- 66 target-realization validator cases;
- generator drift checking;
- real 324-cell validation;
- 35 provider-contract validator cases;
- provider/target invariant-reference checks; and
- exact registry/corpus set validation.

The documents and validators prove structural specification coverage and
internal traceability for Packet C. They do not prove semantic predicate
execution or executable isolation. Every new registry hook and conformance test
remains `planned`; Gate 4B must continue to fail until real predicates,
builders, drivers, probes, and original-failure tests exist. The four profile
IDs remain review coordinates until their complete production identity
registries exist. Packet C completion advances but does not close Gate 2A:
Packets D, E, and F remain mandatory.
