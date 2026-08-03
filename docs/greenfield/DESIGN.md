# Foampit

## Declarative Agent Sandbox Design and Product Specification

Status: **Active design**

This document defines Foampit as a greenfield product. It does not inherit the
architecture, terminology, protocols, or implementation constraints of its
predecessor. Sections marked **Locked** are approved design decisions and must
not be weakened or reinterpreted during later design or implementation.

Unless a section explicitly locks a spelling, code snippets, JSON shapes,
option paths, CLI commands, and internal type names are semantic illustrations,
not stable public names. The four configuration-resource labels describe
architectural ownership and do not by themselves lock SDK type names. The
`workspace-edit-offline` profile identity is explicitly locked below.

Every research-dependent decision in this specification follows the locked
[Research and Evidence Standard](./research/RESEARCH-STANDARD.md): current
primary contracts, proven production patterns, recent academic or novel work,
and adversarial counterexamples must be reconciled without confusing their
maturity or guarantees.

## Locked: Configuration Ownership and Runtime Boundary

The product has four distinct configuration resources:

1. **Artifact Definition** — a declarative source definition that produces an
   immutable Sandbox Artifact Set and fully expanded manifest. Its final
   authoring language is subject to the locked configuration-language research
   gate below; Nix remains the artifact construction substrate.
2. **CreateSandbox input** — a typed Core Sandbox API request that realizes one
   live Sandbox from an Artifact.
3. **Operator Configuration** — configuration for the daemon, drivers, hosts,
   provider connections, credentials, capacity, and global policy.
4. **Managed-Sandbox Service Definition** — an optional, separate NixOS surface
   that declaratively manages live Sandboxes by calling the same Core Sandbox
   API.

The separation is based on resource identity, not whether a value is written
declaratively.

### Artifact Definition

The Artifact Definition owns immutable content, reproducible defaults, hard
policy, required capabilities, binding-slot contracts, target construction,
and build provenance. Changing it changes the Artifact identity or manifest
contract.

It may declare logical workspace, mount, volume, device, port, and secret
slots. It never contains a concrete current-host path, provider credential,
secret value or reference, live device ID, provider placement, or lifecycle
choice for one Sandbox.

### Artifact compilation and construction boundary

The flake remains the shareable, pinned program that deterministically produces
the Sandbox Artifact Set. That path contains three distinct representations:

```text
Artifact Definition source
  -> fully expanded, validated portable Artifact value
  -> Nix construction
  -> Sandbox Artifact Set plus built manifest
```

The middle value is an internal compiler and trust-boundary representation, not
a deployable resource, runtime object, or generic `ResolvedPlan`. It contains
the complete language-neutral Artifact-owned semantics needed for construction.
It may identify pinned Nix inputs, attributes, flake outputs, or registered
native handles through typed references. It never serializes arbitrary Nix
source, derivations, Nix functions, or store paths as though they were portable
source identities.

Nix construction resolves those references and emits the actual target
artifacts. The built manifest may then record store identities, target-member
identities, runtime requirements, and construction evidence. The portable
semantic digest and the built Artifact identities are distinct facts; exact
public names for them remain part of the manifest/identity ADR.

Every supported authoring frontend must reach one product-owned validator for
the portable value before Nix construction. A frontend may reject an invalid
state earlier and preserve richer source spans, but it does not replace that
defensive boundary or own a divergent copy of the semantic rules. The
canonical comparison encoding used during language research is not yet the
stable public manifest encoding.

This is a semantic boundary, not a requirement to serialize every Nix-authored
value through an external process. A Nix authoring path may validate the
portable projection and construct target outputs in one evaluator invocation
while retaining separately scoped native values whose declared references are
checked against that projection. A non-Nix frontend crosses the same boundary
through a serialized portable value. The configuration-language ADR must
select one authoritative semantic implementation and must not leave
independent handwritten Nix and runtime validators to drift.

The alternatives and deciding experiments are tracked in
[Semantic Validation Authority](./research/SEMANTIC-VALIDATION-AUTHORITY.md).

### Composition paths are explicit review coordinates

A `CompositionPath` is a route by which a value or operation can contribute
to, transform, transport, or attempt to bypass a product-owned resource
contract. It is an internal review coordinate, not necessarily a public option
or API name.

The closed Packet D registry is
[`PACKET-D-COMPOSITION-PATHS.json`](./research/invariants/PACKET-D-COMPOSITION-PATHS.json).
Its candidate universe contains exactly 54 first-class paths. Every one of the
354 registered invariants is evaluated against every path, producing 19,116
unique cells in
[`PACKET-D-COMPOSITION-COVERAGE.json`](./research/invariants/PACKET-D-COMPOSITION-COVERAGE.json).
The source-resource branches are distinct:

```text
Artifact:                    P1 -> A0/A1/W0
Operator Configuration:     P1 -> OC0/O0
Managed-Service Definition: P1 -> MS0/S0
serialized resolved reentry: RW0 -> C0/O0/H0/D0
```

`OC0`, `MS0`, and `RW0` are not aliases for Artifact phases. Every cell has
one of these results:

- `may-contribute` — the path may add a value within its owner and schema;
- `may-narrow` — the path may reduce authority or bounds;
- `may-select` — the path may select among explicitly declared alternatives;
- `no-authority` — the path cannot author the invariant and a named boundary
  rejects a forged value; or
- `boundary-input` — the entire input is untrusted and revalidated.

There is no “not applicable” cell. Adding a new import form, adapter,
frontend transform, native escape, target lowerer, cache, provider path, raw
configuration hook, or direct-driver route changes the closed path universe
and reopens Packet D.

For serialized frontends, W0 first performs strict bounded decoding and then
invokes the same final Artifact semantic rule set conceptually named A1.
`A1` describes the first point at which complete Artifact semantics exist; it
does not authorize trusting a renderer or adapter before W0 decoding.

Frontend evaluation, renderer output, renderer-to-wire adaptation, canonical
wire input, schema migration, Nix-native side-table values, built manifests,
provider build results, resolved handoff, serialized resolved reentry,
generated runtime configuration, direct driver invocation, and raw runtime
configuration are separate trust states. Success at one boundary never
constructs or vouches for the next validated stage.

Serialized resolved reentry is wholly untrusted. It must replay the exact 89
built-member/load invariants and the exact 30 C0–D0 resolved-stage invariants
recorded in `PACKET-D-CASE-CONTRACTS.json` before authoritative constructors
create fresh private stages. Generated backend configuration is D0 output,
not driver input authority, and suppresses every undeclared backend default.
Drivers accept only the private product-owned `PreparedLaunch` stage. Direct
driver invocation and raw runtime configuration have no admitted value.

`prebuilt-member-transfer` and `oci-descriptor-transfer` finish at H0;
`provider-cache-hit` finishes at D0; and `provider-side-construction`,
`provider-build-cache`, and `corrupted-provider-build-result` finish at N1.
Each then hands off to `built-artifact-load`, which begins a separate C0 path.
These are cross-path handoff records, not phase-edge assertions and not
authority to skip C0 manifest loading.

Hard-policy composition cannot rely on final values alone when the invalid
state depends on discarded definitions. Security-sensitive Nix option
families reject winning priorities outside their declared composition
contract, and the frontend preserves the required contribution ledger.
Replaceable defaults remain explicit, named schema/profile contributors.
Arbitrary frontend-native override, FFI, external-reader, and open-value
mechanisms have no product authority.

### CreateSandbox input

`CreateSandbox` is part of the Core Sandbox API, not the Artifact Definition
module. Its typed input owns the Artifact reference and concrete bindings,
allocations, placement, timeouts, initial runtime state, and target/provider
extensions for one live Sandbox.

Related fields compose only through explicit refinement:

```text
artifact minimum <= create allocation <= artifact maximum
create network authority is a subset of artifact network authority
create filesystem access is equal to or narrower than artifact access
concrete devices satisfy artifact device-class requirements
secret delivery satisfies the declared secret-slot contract
```

There is no generic last-writer-wins behavior. Contradictions fail before the
untrusted workload starts.

### Operator Configuration

Operator Configuration owns daemon listeners and authentication, enabled
drivers, provider endpoints and credentials, host preparation, state and cache
locations, network and storage infrastructure, capacity, global ceilings,
admission, cleanup, logging, and evidence sinks.

An API caller selects an allowed runtime profile or placement class. Operator
Configuration maps that selection to a concrete driver. The caller does not
receive the operator's provider credential.

### Managed-Sandbox Service Definition

Nix may declaratively manage runtime state without making that state part of an
Artifact. A separate NixOS module may reference an Artifact and declare
concrete bindings, resources, autostart, restart/recreate behavior, probes,
retention, and service dependencies.

This surface compiles to systemd units or a reconciler that calls the canonical
Core Sandbox API. It never defines a second sandbox semantics.

The Artifact/API core may ship before this optional managed-service surface.
The architectural boundary nevertheless supports both.

### Framework and process ownership

Framework adapters own framework sessions, fresh-versus-reused Sandbox
choices, Manifest translation, tool presentation, framework lifecycle
ergonomics, approvals, tracing, and error conversion.

The live Sandbox API owns operations on an existing Sandbox. `Exec` input owns
one Process: argv, cwd, environment delta, streams, timeout, PTY, signals, and
allowed per-process identity. Neither layer may widen immutable Artifact
policy.

Framework adapters and the CLI share the same typed translation into
`CreateSandbox`, live-operation, and `Exec` Core API inputs. They do not own
parallel request semantics. Packet E owns the detailed transition, cleanup,
and conformance inventory.

### Locked: Durable operations and runtime identity

The Core uses one writable `Sandbox` aggregate. It does not expose a writable
`Session`, `Incarnation`, `Run`, or `Deployment` beneath that Sandbox.
Framework-level Sessions remain adapter-owned.

One Sandbox has several deliberately independent coordinates:

- optional human `name`, immutable after Create and reusable only after
  deletion;
- immutable, never-reused Sandbox `id`;
- representation `etag` for optimistic concurrency;
- monotonically increasing runtime `epoch` for one continuous guest/process
  runtime;
- durable `Operation.id` for one accepted Core mutation other than Exec;
- durable `Process.id` for one accepted execution;
- `idempotencyKey` for canonical-request deduplication; and
- event/output cursors for observation.

Snapshot has its own immutable, never-reused `Snapshot.id`. Its
`manifestDigest` commits the immutable manifest and retained-component digests
for integrity/deduplication and never substitutes for resource identity.

The value `{ sandboxId, epoch }` identifies a runtime but is not a separately
writable resource. A future read-only runtime-history projection may be derived
from immutable Operations, Processes, events, and tombstones; it may not gain
independent desired state or lifecycle authority. The epoch is server
allocated and output-only; no Create input, lifecycle request, native
extension, or adapter can set or preserve it.

Every accepted Sandbox lifecycle mutation and Process signal/termination
mutation returns a durable `Operation`, including fast local mutations that
can return an already-terminal record. Its tagged target is the exact
Sandbox/runtime, Process/Sandbox/runtime, immutable Snapshot, or Fork
source-runtime/child tuple selected by the method and never changes during
retry. Signal/termination Operations do not implicitly acquire the Sandbox
lifecycle lane. Sequenced input, close, and terminal-resize commands instead
return Process-control receipts under the exact writer lease and sequence.
Reads are synchronous observations. Wait and watch are observational and
their deadlines never cancel underlying work. `Exec` returns a durable,
epoch-bound `Process`, the specialized handle required for streams, signals,
and exit status.

The Core durably records an Operation and allocates any new runtime epoch
before effect-producing launch work. Failed or ambiguous launches consume
their epoch. Stop/start, cold restart or recovery, same-Sandbox restore or
replacement that loses Process continuity allocate a new epoch. Fork and
running restore-as-create allocate a new Sandbox ID at epoch one; stopped
restore-as-create allocates no runtime epoch until Start.
Memory-preserving pause/resume or live migration may retain an epoch only when
Process continuity and exclusive authority are proven. Uncertain continuity
never defaults to preservation.

Every live mutation targets an exact expected runtime epoch. A stale reference
returns a typed `StaleRuntime` result and is never silently applied to the
current runtime. A Process belongs permanently to one Sandbox ID and epoch.
Replacing or losing that runtime terminates its nonterminal Processes with a
machine-readable replacement, loss, or fencing reason.

The runtime maintains a separate internal monotonic authority epoch. It is
never reused within a Sandbox ID, advances durably before a driver, host,
VMM, reconciler, or provider-binding successor receives authority, and is
validated at every product-controlled effect boundary. External-effect
exclusivity additionally requires target-enforced fencing or a verifiable
drain boundary; otherwise the outcome remains `unknown` and overlapping
successor authority is forbidden. This fences obsolete actors without falsely
declaring a new public runtime when a correctly performed migration-style
handoff preserves Process continuity.

Idempotency is defined over a caller key and canonical semantic request. The
same pair returns the same Operation or Process; reuse with a different request
is a typed conflict. Cancellation is a request, not a fact. RPC timeout or
disconnect stops observation, not execution. When the Core cannot establish
whether an external effect occurred, a terminal Operation result is explicitly
`unknown`. A Process `unknown` state is instead a reconcilable observation of
that same accepted execution; neither state authorizes automatic Exec replay.
Relevant Operations record their expected runtime epoch and any previous and
resulting epochs. Attachment/stream continuity is reported separately from
runtime continuity and never becomes another resource or authority token.

The complete rationale, alternatives, provider counterexamples, academic
evidence, registry obligations, and unresolved Packet E work are locked in
[Packet E: Durable Operations and Sandbox Runtime Identity](./research/invariants/PACKET-E-OPERATION-IDENTITY-DESIGN.md).

### Locked: Sandbox and Process lifecycle state

The Core keeps Operation, Sandbox, and Process as three separate state
machines. Operation records mutation progress and result; Sandbox status
reports conservative runtime facts; Process records one accepted execution
permanently bound to one Sandbox ID and runtime epoch.

The locked Sandbox runtime states are:

```text
provisioning | running | suspended | stopped | unknown
```

- `provisioning` means a new epoch is durably allocated but its usable runtime
  postcondition is not proven.
- `running` means the exact epoch is observed executing under current fenced
  authority. It does not imply execution admission or application readiness.
- `suspended` requires proven quiescence and same-epoch memory and Process
  continuity.
- `stopped` requires proof that no Process-bearing runtime from the prior epoch
  can continue acting.
- `unknown` is the mandatory result when presence, absence, continuity,
  containment, or exclusive authority cannot be proven.

Execution admission is a separate `accepting | closed` fact. Only a running
runtime may accept Exec, but running does not imply accepting. Core closes
admission and revokes new Process launch authority durably before Stop or
another quiescing operation captures the set of accepted Processes. In-flight
launches must be drained or target-fenced before absence can be proven.
Continuity-preserving Suspend instead withholds launch authority while
preserving undispatched accepted Processes; Resume may regrant it only after
same-epoch continuity is proven.

There is no caller-writable desired runtime state. The Core is an explicit
lifecycle API; an optional Managed-Sandbox Service may own desired-state
reconciliation above it. There are also no authoritative verb-specific
Sandbox states such as `starting`, `stopping`, or `deleting`. SDKs and the CLI
derive those presentation labels from the current durable Operation and
Sandbox status.

Deletion is not a live runtime state. `DeleteSandbox` requires `stopped`,
succeeds only after cleanup is proven, removes the Sandbox from the live
collection, and retains an internal tombstone plus independently retained
Operations, Processes, output, events, and evidence. It never silently
force-stops a running Sandbox.

The locked Process states are:

```text
accepted | starting | running | unknown | terminated
```

A terminated Process carries a typed outcome distinguishing ordinary exit,
signal termination, start failure, deadline or termination-request outcome,
runtime loss or replacement, fencing, and deliberate Sandbox Stop. Nonzero
command exit is not infrastructure failure. An ambiguous Process is never
automatically relaunched and can resolve only by reconciling the same backend
execution identity in the same runtime epoch.

`SignalProcess` and `TerminateProcess` return durable Operations. Successful
signal dispatch does not prove delivery or Process exit. Process terminality,
output sealing, and retained-stream expiry are separate facts.

One effectful lifecycle Operation holds fenced Sandbox authority at a time
unless an exact capability explicitly permits an operation pair. Concurrent
Exec is allowed while admission is accepting. Provider phases and events are
decoded evidence, never serialization or portable-state authority.

The complete state graphs, proof obligations, Stop protocol, concurrency and
crash matrices, provider/runtime counterexamples, academic rationale,
verification plan, references, registry obligations, and remaining Packet E
work are locked in
[Packet E: Sandbox and Process Lifecycle State](./research/invariants/PACKET-E-LIFECYCLE-STATE-DESIGN.md).

### Locked: Core lifecycle and control operation taxonomy

The Core exposes named, typed, resource-oriented methods. It does not expose a
provider-verb superset, public generic Action/Command invocation, or
caller-writable desired runtime state. Desired-state controllers remain above
Core; provider-native calls remain behind the validated private driver
boundary.

Every conforming execution driver supports:

- `CreateSandbox`, with an explicit resolved initial runtime state of
  `running` or `stopped`;
- `StartSandbox`;
- `StopSandbox`;
- `DeleteSandbox`;
- `Exec`, which returns a durable Process; and
- `TerminateProcess`.

`StopSandbox` never silently deletes. `DeleteSandbox` requires stopped and
never silently stops. Create-running allocates epoch one and proves control,
conformance, and execution admission before success. Create-stopped allocates
no runtime epoch until Start.

Reads use resource-oriented `Get` and `List` methods over Sandboxes,
Operations, Processes, and Snapshots. Observational `Wait` is currently
defined for Sandboxes, Operations, and Processes. A wait deadline does not
cancel underlying work. `CancelOperation` requests cancellation on the
existing Operation rather than creating an Operation-of-Operation.

Process transport uses `ReadProcessOutput` plus sequenced
`WriteProcessInput`, `CloseProcessInput`, and conditional
`ResizeProcessTerminal` commands. The three control commands bind the exact
Process, Sandbox, runtime epoch, writer lease, and monotonically increasing
sequence. Equal sequence and equal content recover one durable receipt;
conflicting or stale sequences are rejected. A receipt proves Core admission,
deduplication, and ordering, not application consumption. A framework or SDK
may combine these operations into `attach`, but attachment remains client
state. `Shell` is Exec with a terminal and shell argv. Neither is another Core
resource or lifecycle operation.

The following are capability-gated with exact, non-approximable semantics:

- `SignalProcess`, with an advertised closed signal set;
- paired `SuspendSandbox` and `ResumeSandbox`, only for proven same-epoch
  Process continuity;
- `ResizeSandboxResources`, for atomic in-place same-epoch mutation while
  running or validated next-runtime allocation while stopped;
- `CreateSnapshot` and `DeleteSnapshot`;
- same-Sandbox `RestoreSandbox`; and
- `ForkSandbox`.

Cold fallback, lazy recreation, restore, or provider replacement is never
reported as Resume. A resize that requires reboot or replacement is
unsupported while running; callers explicitly Stop, resize the stopped
Sandbox's next-runtime allocation, and Start a new epoch.

Snapshot is a first-class immutable retained-state resource. CreateSnapshot
requires:

```text
snapshotClass = exact capability identity
sourceAfterCapture = runtimeStatePreserved | stopped
```

The resolved class fixes filesystem versus runtime kind, complete component
set, external-storage and secret treatment, compatibility, quiescence,
device-state treatment, portability, and Process handling. There is no omitted
or provider-selected value. Filesystem Snapshot makes no runtime-continuity
claim. Runtime Snapshot records complete included, referenced, and excluded
components. `runtimeStatePreserved` preserves Sandbox runtime state and epoch
but reports attachment/connection disruption separately; `stopped` includes
the full Stop postcondition.

Core v1 rejects Snapshot and Fork while any Core Process is nonterminal.
Process-bearing restore requires a future reviewed successor-Process
capability that creates new epoch-bound Process IDs and restores control,
deadline, stream, and termination semantics before execution resumes.

`RestoreSandbox` requires a stopped Sandbox, allocates a new epoch, and
returns it running and usable without reusing old Core Process identity.
Restore-as-create is `CreateSandbox(source = SnapshotRef)` and creates a new
Sandbox. Fork creates a new independently running Sandbox at epoch one,
preserves the source, and records Snapshot-equivalent ancestry and uniqueness
handling.

There is no generic `UpdateSandbox`. `UpdateSandboxMetadata` is limited to
labels and non-authoritative correlation metadata under etag; Sandbox name is
immutable until Delete. `SetSandboxExpiration` selects
`none | { at, action = stop | delete }` subject to declarative hard ceilings.
At expiry, admission closes before any new Exec. The system Stops an extant
runtime, skips redundant Stop when stopped is already proven, and links Delete
only after that proof. Provider-native TTL cannot bypass that sequence.
Network policy, mounts, runtime profile, image, environment, devices, and
secrets cannot use either method. Live resource resize has its own capability
and Operation.

The following names are rejected from portable Core v1 because they hide
materially different effects: Restart, Wake, KillSandbox, Destroy, Rollback,
Connect, Attach, Detach, Session, generic Update, generic Copy, bare TTL,
Archive, and public Migration. A future public migration contract requires
exclusive target-enforced handoff and Process continuity; cold relocation is
a new epoch.

The complete alternatives, exact method semantics, Snapshot and operation
target contracts, provider/runtime counterexamples, framework and
desired-state boundaries, compile-time/runtime rejection split, references,
registry obligations, and remaining work are locked in
[Packet E: Lifecycle and Control Operation Taxonomy](./research/invariants/PACKET-E-OPERATION-TAXONOMY-DESIGN.md).

### Locked: request, result, error, and recovery contract

The Core separates five authoritative branches:

1. `RequestError` proves that no durable acceptance or effect-producing
   dispatch occurred;
2. `RecoveryError` proves that a replay dispatched no new effect but its
   historical recovery coordinate is outside the guaranteed recovery state;
3. a successful read-only observation returns its synchronous observation
   result and creates no acceptance commit;
4. an accepted call returns the result required by its exact class: durable
   `Operation`, durable `Process`, committed Core-record result, or durable
   Process-control receipt; and
5. a client-side transport failure does not establish any Core branch and is
   recovered by the call class—identical request/idempotency key for durable
   and atomic calls, or identical writer lease/sequence/command for Process
   control.

Acceptance is one semantic commit point with class-specific records, not one
universal transaction shape. Durable Operation mutations and `Exec` commit a
new handle plus exact effect intent before dispatch. Atomic Core-record
updates commit the representation change, idempotency binding, and recoverable
response together and have no handle or dispatch intent. `CancelOperation`
commits monotonic cancellation intent on the existing Operation.
Process-control calls commit an ordered receipt under their writer lease and
sequence. Each commit also binds the method, origin, canonical request and
digest, exact target and freshness conditions, accepted time, and applicable
admission and precondition witnesses. A crash or lost response cannot
retroactively turn any committed class-specific acceptance into a request
rejection.

Packet E uses a shared sealed semantic registry with generated
operation-specific subsets. Public SDKs expose tagged variants with exact
detail schemas; there is no open string reason, provider-defined error,
generic detail map, or `retryable` boolean. Caller recovery is one of:

```text
DoNotRetry
RetrySameRequest
RefreshThenSubmit
WaitThenSubmit
ObserveHandle
OperatorAction
```

Core's private native resolution distinguishes retrying the same idempotent
native execution, adopting the exact execution, reconciliation, compensation,
and cleanup. Compensation is a new recorded effect, not rollback.

The Operation terminal outcomes remain `succeeded`, `failed`, `cancelled`,
and `unknown`. Success requires the exact postcondition. Failure and
cancellation require exclusion of unfenced acting authority. Any remaining
effect or authority ambiguity is terminal Operation `unknown`; linked
reconciliation or cleanup never rewrites it. Process `unknown` remains a
nonterminal observation state of the same accepted execution.

An internal evidence-refinement model tracks possible effect state
`none | partial | complete` and mutation-attempt authority
`quiesced | mayStillAct`. This is the authority of the accepted mutation or a
stale native actor, not necessarily the intended workload: a proven failed
Suspend may leave the Sandbox running. Evidence may only narrow
possibilities. This model mechanically gates the public outcome while the SDK
receives concise typed failures and missing-proof variants.

Every method belongs to one exact call class:

- durable Operation mutation;
- durable Process mutation;
- observation;
- atomic Core-record update;
- existing-handle intent such as `CancelOperation`; or
- sequenced Process control.

Authorization precedes detailed validation and existence disclosure.
Idempotent replay precedes mutable lifecycle and capacity checks so an equal
retry returns its original handle even after the target state changes.
Idempotency and result retention are distinct explicit service contracts;
expired records never silently authorize a new effect.

HTTP Problem Details and gRPC canonical status/details are generated
projections. They never override product semantics. Native provider status and
payloads remain bounded, redacted protected evidence. Adapters may translate
and present the Core contract but cannot add variants, replay ambiguous
effects, retarget stale runtimes, or convert transport timeout into failure or
cancellation.

The complete architecture, alternatives, provider counterexamples, formal
model, machine-ledger dimensions, references, registry obligations, and
remaining work are locked in
[Packet E: Request, Result, Error, and Recovery Contract](./research/invariants/PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md).

### Native extension ownership

There is no single unrestricted `targets.<target>.native` surface. Native
extensions are scoped to the resource and lifecycle they affect:

- Artifact-native target construction;
- CreateSandbox driver extensions;
- Operator/driver configuration;
- Managed-service driver configuration;
- Live-operation extensions;
- Exec extensions;
- Framework-adapter configuration.

For example, arbitrary guest NixOS modules may be Artifact-native for the
microVM target, while host share sources, TAP interfaces, concrete devices,
control sockets, credentials, and resource allocations are not. OCI image
configuration and OCI runtime configuration are separate. Bubblewrap artifact
construction and hard policy are separate from runtime host bindings. The
conforming bubblewrap path uses the owned direct driver; jail.nix is prior art,
not an extension surface.

Exact human-facing names for these scoped native extension points remain a
separate design decision.

An external frontend may refer to Nix-native content only through a typed
handle. A Nix-authored one-evaluation path may retain the actual evaluator
value in a private side table, but the portable projection carries the same
typed identity. That identity binds this exact machine-owned tuple:

- `sourceGraphClosureDigest`, the complete pinned transitive source graph;
- `registryNamespace`;
- `registryVersion`;
- `registryDigest`, independently of `sourceGraphClosureDigest`;
- `exportAttribute`;
- `nativeInterfaceVersion`;
- `targetSystem`;
- `affectedMember`; and
- `expectedSemanticProjection`.

The `semanticIdentityComparison` is required before construction.

A current store path, provider object ID, or digest of one registry file is
not a source identity. N0 resolves and compares the complete tuple before any
derivation is constructed, and the built manifest is checked independently at
C0.

## Locked: Artifact-Native Target Configuration and Cross-Target Invariants

Artifact-native target configuration is supported, but it is a checked
extension layer, not an unchecked override. Common Artifact configuration is a
hard contract. Artifact-native configuration fills in target-specific build
and guest details without weakening that contract.

### Native configuration composition

For the microVM target, the target builder evaluates:

```text
Generated NixOS module from common configuration
+ user-supplied native NixOS/microvm.nix modules
= final NixOS/microVM configuration
             ↓
outer validation
             ↓
microVM artifact
```

This uses ordinary Nix module composition for guest construction.
`microvm.nix` itself exposes a wider mixed-lifecycle option tree, but the
Artifact-native surface accepts only guest/build configuration and statically
fixed compatibility choices. Runtime allocations and host bindings are
rejected from this surface even though upstream microvm.nix represents them in
the same module.

The microVM Artifact-native escape hatch includes arbitrary guest NixOS modules.
The syntax below is illustrative until the scoped native extension names are
locked:

```nix
targets.microvm.guest.modules = [
    ({ pkgs, ... }: {
      services.postgresql.enable = true;
      environment.systemPackages = [ pkgs.strace ];
    })
];
```

Host shares, interfaces, device IDs, credentials, runtime allocations, and
other create/operator concerns are not accepted through this Artifact-native
escape hatch. Hypervisor/runtime-profile selection is also not guest NixOS
configuration. Equivalent Artifact-native surfaces for bubblewrap and OCI must
likewise contain only target construction or hard policy, not live host
bindings.

### Validation phases

Not every property can be checked during source configuration and Nix artifact
evaluation because some properties depend on the eventual host. Every conflict
must nevertheless fail at the earliest phase where it can be determined
soundly.

#### Evaluation validation

Before producing derivations, validation covers:

- Types and required fields
- Cross-field invariants
- Common-policy compatibility with every enabled target
- Conflicts between native configuration and common policy
- Unsupported target capabilities known statically
- Invalid target combinations
- Platform and architecture mismatches known to Nix

The selected authoring system must provide types, constructors or contracts,
and final validation that cause invalid definitions to fail during evaluation.
The Nix-module baseline uses typed options, constructors, and assertions.

Because Nix is lazy, the flake integration must generate checks that deliberately
force validation for every enabled target. `nix flake check` validates the
complete sandbox set rather than only whichever package happened to be built.

The public construction API returns no forgeable “validated” record shape.
Only the authoritative boundary owns each stage constructor:

```text
decoded wire --W0--> ValidatedArtifact
ValidatedArtifact + native identities --N0/N1--> BuiltMember
BuiltMember manifest --C0--> VerifiedManifest
VerifiedManifest + CreateSandbox --C0/O0/H0--> ResolvedCreation
ResolvedCreation --D0--> PreparedLaunch
```

A bridge, cache, provider result, lowerer, framework adapter, service
controller, or direct driver call cannot skip a constructor. Each boundary
revalidates untrusted bytes or foreign objects before producing its next
private product type.

At D0 the product also derives and validates the complete generated backend
configuration from `PreparedLaunch`; this total configuration is output of
the private chain. It cannot be supplied by a raw map, raw argument vector, or
direct driver caller.

#### Artifact validation

Artifact construction validates:

- Every required package exists for the target system
- The runtime command dispatcher closes over all dependencies
- The artifact manifest matches the produced output
- Required users, paths, and entrypoints exist
- Target-native configuration produces a valid artifact
- A minimal launch and conformance probe succeeds where build infrastructure
  permits it

#### Runtime preflight

Immediately before creating a sandbox, runtime preflight validates the
following items when required by the selected target profile and request:

- KVM and the selected hypervisor are available for KVM-backed profiles
- Unprivileged user namespaces are enabled for profiles that require them
- Required cgroup controllers exist
- Workspace sources exist and have acceptable ownership
- The runtime can enforce the declared network policy
- Required mount, device, PTY, snapshot, and resource capabilities exist
- Driver and guest protocol versions are compatible

A failed preflight creates no sandbox and runs no untrusted process.

### Common configuration is a contract

If three targets are enabled, every common field must have compatible semantics
on all three.

For example:

```nix
policy.network.access = "none";
```

can map to:

- No network attachment in the owned bubblewrap driver
- No network interface in the microVM
- An isolated network namespace in an OCI runtime

By contrast:

```nix
policy.network.egress.allow = [
  "api.github.com:443"
];
```

cannot be implemented by bubblewrap namespace construction alone. The
bubblewrap target must fail validation unless a compatible, operator-enabled
egress-control implementation is selected and the creation request binds it.

The diagnostic must be specific and actionable:

```text
sandbox "development": target "bubblewrap" cannot enforce
policy.network.egress.allow.

The selected bubblewrap runtime profile provides namespace isolation but no
destination-aware egress enforcement.

Remedies:
- select policy.network.access = "none"
- select and bind a supported egress-control profile
- disable the bubblewrap target
```

There is no silent downgrade.

### Native extensions cannot override common policy

Module priority alone is insufficient because an advanced Nix module can use
`mkForce` or a stronger override priority.

For Artifact-native modules, the target builder validates the final evaluated
configuration from outside the native module set:

```text
evaluate generated + native modules
              ↓
inspect final target configuration
              ↓
assert portable invariants
              ↓
build
```

Examples:

- `policy.network.access = "none"` requires the final microVM to have no
  externally connected network interface, regardless of what a native module
  attempted to configure.
- A guest module cannot reintroduce a denied Linux capability or device into
  the guest contract.

At runtime, the same outer-validation rule is applied after combining the
Artifact manifest, CreateSandbox input, Operator Configuration, and
driver-native configuration:

- A read-only workspace slot cannot become a writable `microvm.shares` entry.
- A denied host path cannot appear in generated bubblewrap binds.
- A denied Linux capability cannot reappear in generated OCI runtime
  configuration.

The user cannot override these checks through a supplied native extension
because validation occurs around the completed Artifact evaluation or completed
runtime configuration, as appropriate.

There is a fundamental limit: arbitrary NixOS modules can start arbitrary
services and express behavior the validator does not semantically understand.
No configuration compiler can prove the complete security behavior of arbitrary
programs. Security claims therefore rest primarily on the outer isolation
boundary—VMM configuration, namespaces, mounts, devices, network attachment,
and runtime capabilities—not on trusting guest services.

### Practical portability limits

#### Environment

A `devShell` is a build and development environment, not inherently a root
filesystem. `nix develop` constructs an environment close to a derivation's
build environment, including variables and shell functions, and may run
shell-oriented initialization.

The sandbox system can normalize:

- Packages and their closures
- Environment variables
- Executable search paths
- Explicit activation scripts

Potential conflicts include:

- Host-specific paths
- Architecture-specific packages
- Interactive `shellHook` behavior
- Hooks that inspect or mutate the host
- Services assumed to exist outside the shell
- Linux-kernel dependencies unavailable in a microVM or OCI runtime

`environment.devShell` is therefore a convenience importer. The evaluated
environment manifest records exactly what was retained. Unsupported or
host-dependent values fail validation rather than disappearing silently.

#### Workspace

The portable workspace contract describes observable behavior:

- Destination path
- Read-only or read-write access
- Protected paths and subpath access
- Ownership expectations

The runtime create request supplies the actual workspace source and chooses a
supported binding mechanism. Retention, synchronization, and result export are
runtime/API concerns, not workspace properties in the Nix definition.

The implementation mechanism may differ:

- bubblewrap bind mount
- microVM virtiofs or 9p share
- OCI bind mount or volume
- remote upload and download

`microvm.nix` exposes multiple share and store strategies with different
performance and isolation characteristics. If two mechanisms cannot provide
the requested observable semantics, that target fails validation.

#### OCI

An OCI image can declare defaults such as environment, user, working directory,
entrypoint, and volumes. `nix2container` accepts that OCI image configuration
directly.

Mount enforcement, Linux capabilities, resource controls, devices, namespaces,
and seccomp belong to runtime configuration rather than merely the image.

An OCI Sandbox Artifact therefore contains both:

- The OCI image
- The sandbox manifest describing requirements the eventual OCI driver must
  enforce

Building the image alone does not prove its runtime policy.

#### Runtime lifecycle capabilities

The core runtime API can describe pause, resume, snapshot, and fork, but these
are not Nix environment options. An artifact may require or advertise
capabilities needed to run it, and each created sandbox reports the operations
its selected driver and host actually support:

- bubblewrap may support only create, connect, exec, and terminate
- Filesystem snapshots may be implementable independently
- microVM memory snapshots depend on the selected hypervisor and device
  configuration
- OCI checkpointing depends on the runtime and host

Calling an unsupported lifecycle operation returns a capability error. It never
approximates one operation with another.

### Strict multi-target rule

The locked rule is:

> Common configuration has identical required semantics across every enabled
> target. Native configuration may add target-specific functionality, but it
> may not weaken or contradict the common environment, workspace, policy,
> resource-bound, or required-capability contract.

If the author intentionally wants different behavior, they define two named
sandboxes that share a common reusable definition. The following uses the Nix
baseline syntax illustratively; authoring syntax is not locked until the
configuration-language ADR:

```nix
sandboxes.local = {
  imports = [ ./common.nix ];
  policy.network.access = "host";
  targets.bubblewrap.enable = true;
};

sandboxes.secure = {
  imports = [ ./common.nix ];
  policy.network.access = "none";
  targets.microvm.enable = true;
};
```

This is clearer than pretending divergent artifacts are equivalent members of
one sandbox definition.

Common fields are hard cross-target requirements. Native configuration is
checked after merging. Unsupported semantics always fail rather than degrade.

### References

- [Nix module-system deep dive](https://nix.dev/tutorials/module-system/deep-dive.html)
- [Nix `develop`](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-develop.html)
- [microvm.nix configuration options](https://microvm-nix.github.io/microvm.nix/options.html)
- [microvm.nix module source](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/options.nix)
- [jail.nix combinators](https://alexdav.id/projects/jail-nix/combinators/)
- [nix2container](https://github.com/nlewo/nix2container)
- [OCI Image Configuration](https://specs.opencontainers.org/image-spec/config/)
- [OCI Runtime Configuration](https://specs.opencontainers.org/runtime-spec/config/)

## Locked: Target Implementation and Dependency Boundary

The product owns its public semantic model, validation, manifests, runtime API,
supervision, evidence, and target drivers. It reuses isolation mechanisms and
deterministic artifact builders behind versioned, tested adapters. An upstream
library's complete configuration tree never becomes the portable product
model.

The complete normative decision, alternatives analysis, validation phases,
dependency policy, and conformance requirements are defined in
[Target Implementation Strategy](./TARGET-IMPLEMENTATION-STRATEGY.md). That
document is part of this locked design.

### Bubblewrap

The bubblewrap target uses the `bubblewrap` implementation directly and owns a
small compiler from validated sandbox semantics to an exact argument vector.
It invokes bubblewrap without a shell.

`jail.nix` is prior art, not a foundational compiler dependency. Its private
state representation, runtime host expansion, replaceable base permissions,
arbitrary host shell, and raw argument escape hatches do not provide the
inspectable semantic boundary this product requires.

`nsjail`, `syd`, and similar mechanisms may later become
capability-distinct drivers or defense-in-depth layers. They do not define the
portable schema.

systemd and cgroup v2 may provide managed-host supervision, process-tree
containment, and outer resource ceilings. They are not the portable sandbox
mechanism.

### microVM artifacts

The microVM target uses a pinned `microvm.nix` adapter for guest artifact
construction. It may reuse guest kernel, initrd, immutable NixOS closure,
read-only store/root filesystem, boot-parameter, and required-device
construction.

The adapter emits a product-owned, versioned Artifact manifest. It does not
export the `microvm.nix` option tree or runner layout as the manifest schema.

The core runtime does not invoke `config.microvm.declaredRunner`.

The product's runtime driver owns:

- vCPU and host-memory allocation;
- cgroups and host resource ceilings;
- instance identity;
- workspace, data, and volume materialization;
- host paths;
- interfaces, routing, DNS, proxies, and ports;
- vsock CIDs and control sockets;
- secret injection;
- the VMM process user and jail;
- logging destinations and bounds;
- lifecycle, snapshots, termination, and cleanup.

Advanced users may supply guest NixOS modules. The fully merged guest
configuration is validated from outside the user module set. Host shares,
host disk paths, interfaces, forwarding, passthrough devices, control sockets,
host users, store-bound credentials, pre-start shell, runtime argument scripts,
and raw VMM configuration are rejected from the Artifact-native guest surface.

`microvm.nix` is pinned to an exact revision and isolated behind one versioned
adapter. Updates require a compatibility change and boot/conformance tests.
If required artifact outputs are unstable, the preferred order is an upstream
artifact-bundle contribution, a small version-specific adapter, and only then a
minimal fork. A wholesale fork is not the default.

### Initial microVM runtime profiles

Firecracker is the first high-assurance microVM runtime profile. It uses the
Firecracker jailer or an equal-or-stronger process sandbox.

Firecracker does not provide a live 9p/virtiofs workspace through
`microvm.nix`. Its workspace is therefore materialized through explicit
copy-in/copy-out using the guest runtime or through a prepared block volume.
A request for a live workspace fails capability validation. It never silently
degrades to copied semantics.

Cloud Hypervisor is the next microVM profile, intended for explicit live
virtiofs workspaces and workloads requiring its broader device, hotplug, or
long-lived VM capabilities.

The selected VMM is part of the target capability identity. QEMU, Kata,
libkrun, crosvm, vfkit, and other implementations may be added only as
capability-distinct profiles that pass the applicable conformance suite.

Runtime-profile ownership is split without duplication:

1. The Artifact Definition selects or requires target runtime-profile
   identities and hard requirements that every creation must satisfy. This is
   a construction request, not an author-minted support or passing-conformance
   claim.
2. Builders construct zero or more profile-compatible members and emit the
   support facts, conformance-suite identities, results, and evidence in each
   member manifest. Construction fails if a requested mandatory profile or
   semantic cannot be proven. Distinct boot/device bytes require distinct
   members; byte-identical members may advertise multiple independently proven
   compatible profiles.
3. `CreateSandbox` selects one proven profile advertised by a member and
   supplies the concrete bindings and allocations for that live Sandbox.
4. Operator Configuration enables and maps that profile to a pinned driver
   implementation, compatible hosts, helpers, and placement.

The Artifact does not choose a current host or live instance. `CreateSandbox`
cannot select a VMM profile absent from the Artifact. Operator Configuration
cannot reinterpret a selected profile as a weaker implementation.

Because workspace materialization may be either a hard Artifact requirement or
a creation-time choice within Artifact bounds, capability failure occurs at the
earliest applicable phase:

- an Artifact requiring a live workspace cannot enable only the Firecracker
  profile and fails during Artifact evaluation;
- an Artifact permitting both live and copy-in materialization can support
  multiple profiles, but a creation selecting Firecracker plus live
  materialization fails during creation resolution.

### Invalid states and validation phases

The strongest honest validity guarantee is enforced at every boundary:

1. Public configuration types, constructors, and final assertions reject
   malformed and cross-field-invalid declarations during evaluation.
2. Only a successfully built, structurally verified, versioned manifest is an
   Artifact Set.
3. Runtime code parses manifests as untrusted wire data and converts them
   fallibly into validated target-specific values.
4. Artifact capabilities, creation input, and operator constraints must
   construct a valid target-specific creation value before reaching a driver.
5. Host preparation checks and reserves dynamic resources. Only prepared state
   can be started.
6. Post-start probes and evidence distinguish declared, lowered, observed, and
   runtime facts.

Nix's module graph is open. An invalid input can be syntactically written, but
it cannot evaluate and build into a valid Artifact Set. Dynamic facts such as
KVM availability, free ports, allocatable CIDs, and current capacity cannot be
proved by Nix evaluation; they are explicit structured preparation failures.

There is no implicit fallback to a weaker driver.

Discovery and proof of these rules follows the normative
[Invariant Inventory and Enforcement Protocol](./research/INVARIANT-ENFORCEMENT.md).
Its machine-readable registry is the research traceability source of truth.
Gate 2A must enumerate and classify every supported invariant before candidate
implementations are treated as complete. Gate 4B must link every in-scope rule
to authoritative enforcement and executable evidence before blind review,
scoring, or the authoring-language ADR.

The conforming v1 surface contains no raw bubblewrap arguments, raw VMM
arguments, arbitrary host shell, or OCI hooks. Any later expert escape hatch is
target- and lifecycle-scoped, visibly non-conforming, recorded in effective
configuration evidence, and unable to claim guarantees it may invalidate.

### Reproducibility

Nix store identity and a locked dependency graph do not by themselves prove
that every produced filesystem, kernel, or initrd is bit-for-bit reproducible.
Reproducibility claims require independent rebuild checks and artifact
comparison.

## Locked: Configuration-Language Research Gate

The configuration ownership model is locked, but the final public Artifact
Definition authoring language is not.

Before stable Artifact Definition syntax or option names are implemented, the
project must complete
[Configuration Language and Type-System Research](./CONFIGURATION-LANGUAGE-RESEARCH.md)
and record the result in an approved ADR.

That research includes the two mandatory gates in
[Invariant Inventory and Enforcement](./research/INVARIANT-ENFORCEMENT.md).
Neither a locked fixture corpus nor a green prototype subset is sufficient:
the invariant inventory must be complete before candidate implementation, and
enforcement traceability must be closed before scoring.

The research compares the Nix module baseline with Nickel, CUE, Dhall, Pkl,
schema-gated Nix, a purpose-built typed DSL, and justified additional
candidates. Every serious candidate must implement the same vertical slice and
process the same invalid-state corpus.

The decision is based on executable evidence covering:

- closed choices and refinement;
- composition and conflict behavior;
- error quality and source provenance;
- determinism and import pinning;
- Nix package, derivation, dev-shell, and flake interoperability;
- separately scoped native NixOS guest modules;
- canonical manifest production and schema evolution;
- tooling, distribution, security, implementation cost, and ongoing
  maintenance;
- whether the result preserves one authoritative configuration and keeps Nix
  understandable and central to the product.

A non-Nix language is selected only if it demonstrates a material correctness
or usability advantage across the complete slice. Syntactic
unrepresentability alone is insufficient if it creates two sources of truth or
makes native Nix integration opaque.

If no alternative materially outperforms the baseline, the public surface
remains Nix modules strengthened by constructors, final merged-configuration
validation, canonical manifest validation, source-aware diagnostics, and
strong runtime types.

Language-neutral manifest work, invalid-state corpus construction, target
capability modeling, runtime API work, and throwaway language prototypes may
proceed before the ADR. Stable public Artifact Definition syntax may not.

## Locked: Visible Profiles and the Initial Coding Profile

The system has a selected profile when the author does not specify one, but
there are no invisible defaults. No profile is named `default`. Every profile
has a descriptive behavioral name.

The initial selected profile mirrors the common Codex workspace-editing use
case rather than copying the OpenAI Agents SDK's tool capabilities. Codex's
model is a useful product precedent: writable workspace, routine local command
execution, network disabled, and protected project-control paths. The Agents
SDK's default filesystem, shell, and compaction capabilities describe
agent-facing tools rather than a complete isolation policy.

### Visible profile selection

The initial profile is:

```nix
profile = "workspace-edit-offline";
```

When the author omits `profile`, evaluation still materializes the selection in
the Sandbox Artifact manifest:

```json
{
  "profile": {
    "name": "workspace-edit-offline",
    "selection": "implicit",
    "source": "pinned-flake-reference",
    "digest": "sha256:..."
  }
}
```

`implicit` means only that the author did not type the selection. It never
means invisible behavior.

The locked rules are:

- No profile is named `default`.
- Every profile has a descriptive behavioral name.
- Exactly one documented profile is selected when `profile` is omitted.
- The selected name, source, version, digest, and complete expansion appear in
  the artifact manifest.
- `sandbox explain` displays every resulting field and whether it came from the
  profile or an explicit override.
- Target builders receive only the fully expanded configuration.
- Backend defaults never participate.
- Updating the pinned flake may update a profile; doing so changes the artifact
  digest.
- The project may eventually ship multiple named profiles, but it never selects
  among them through hidden environment or target heuristics.

### Initial profile: `workspace-edit-offline`

`workspace-edit-offline` is more informative than names such as
`workspace-write`, `coding`, or `default`.

Its intended complete expansion includes:

| Area | Behavior |
|---|---|
| Workspace | Available at `/workspace` |
| Workspace contents | Read-write |
| Host filesystem | Unavailable except declared mounts |
| Project control state | `.git`, `.agents`, and `.codex` read-only |
| Network | No IP network access |
| Host sockets | None |
| Home | Private ephemeral home |
| Temporary storage | Private writable temporary directories |
| Process execution | Allowed |
| Identity | Unprivileged sandbox user |
| Privilege escalation | Denied |
| Linux capabilities | None unless explicitly granted |
| Devices | Minimal virtual or pseudo devices required for normal CLI operation |
| Secrets | None unless explicitly injected |
| Workspace retention/writeback | Chosen by the runtime caller through workspace binding or result export; not set by this profile |

This profile targets the largest initial use case: a coding agent can inspect a
project, edit its files, run its Nix-provided toolchain, and execute tests
without reaching the rest of the host or the internet.

The sandbox is a hard enforcement layer. Interactive approval behavior does not
belong inside the profile. If an agent wants more access, its orchestrator can
ask the user and create or select a sandbox with a different named profile. A
running sandbox never weakens itself.

Possible future profile names include:

- `workspace-read-offline`
- `workspace-edit-networked`
- `workspace-full-control-offline`
- `isolated-batch-offline`
- `service-preview-networked`

These future profiles are illustrative and are not yet locked.

Artifact resource requirements use typed, scoped minimums and optional hard
maxima. An optional positive finite maximum lifetime is also an Artifact hard
security ceiling; omission means no Artifact-imposed lifetime ceiling.
Networked-profile semantics still require a separate named profile decision.
Runtime allocation, actual TTL, renewal, idle/end behavior, snapshot timing,
and persistence are create/API or framework-adapter choices; they do not belong
to the environment profile. No Artifact policy field is left to a target
default.

### References

- [Codex sandboxing](https://developers.openai.com/codex/concepts/sandboxing)
- [Codex approvals and security](https://developers.openai.com/codex/agent-approvals-security)
- [Codex permissions](https://developers.openai.com/codex/permissions)
- [OpenAI Sandbox Agents](https://developers.openai.com/api/docs/guides/agents/sandboxes)
- [Agents SDK sandbox concepts](https://openai.github.io/openai-agents-python/sandbox/guide/)
- [Agents SDK sandbox clients](https://openai.github.io/openai-agents-python/sandbox/clients/)
