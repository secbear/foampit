# Packet E: Lifecycle and Control Operation Taxonomy

Status: **Locked Packet E decision — request/result/error contract locked
separately; exhaustive transition and compatibility inventory remains open**

Locked: 2026-07-26

Evidence reviewed: 2026-07-26. This date applies to every source below unless
a row states otherwise.

This record locks Packet E's public Core lifecycle, execution-control,
retained-state, and related observation vocabulary; its division into portable
and capability-gated semantics; the Snapshot resource boundary; the
relationship between Core operations and framework adapters; and the
operations deliberately excluded from that portable surface.

It does not claim to close the file, directory, transfer, endpoint, or port
data-plane vocabulary already owned as separate operation families by Packet
A. Those methods must be named and reviewed before the complete public Core
API is closed, and they participate in Packet E's concurrency inventory.

It builds on:

- [Packet E: Durable Operations and Sandbox Runtime Identity](./PACKET-E-OPERATION-IDENTITY-DESIGN.md);
- [Packet E: Sandbox and Process Lifecycle State](./PACKET-E-LIFECYCLE-STATE-DESIGN.md);
- [Packet E: Request, Result, Error, and Recovery Contract](./PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md);
- [Packet A: Public Resources and Operations](./PACKET-A-RESOURCE-OPERATION-REVIEW.md); and
- the [Research and Evidence Standard](../RESEARCH-STANDARD.md).

This record does not close Packet E. The separate result/error decision locks
the acceptance, outcome, recovery, and Process-control sequencing architecture.
The complete request-field, final variant, retention, transition, concurrency,
cancellation, crash, cleanup, and conformance inventories must still be
expressed in machine-readable form.

## Decision

The Core lifecycle and control surface exposes named, typed,
resource-oriented methods. Every effectful method has one closed request type,
one exact target type, one declared result type, and one reviewed semantic
contract.

The product does not expose:

- the union of every provider's verbs;
- a public generic `Action`, `Command`, `Invoke`, or provider-method resource;
- a caller-writable desired runtime state;
- an independently writable runtime, session, deployment, or incarnation
  resource; or
- a provider-specific verb masquerading as portable behavior.

The architecture is:

```text
Framework SDK / CLI adapter
  -> typed Core methods
     -> class-specific result:
          durable Operation or Process
          committed Core-record result
          durable Process-control receipt
          observation
        -> private typed driver interface
           -> provider/runtime-native calls and evidence
```

A future desired-state service may reconcile through the same typed Core
methods. A private driver may invoke native provider operations. Neither layer
changes the Core methods' meanings.

## Alternatives Rejected

### Provider-superset API

A surface containing every provider verb is rejected. Similar names do not
provide similar postconditions:

- E2B `connect` may resume a paused Sandbox;
- Cloudflare obtaining a Sandbox handle may lazily create a fresh container;
- Vercel may auto-resume a stopped logical Sandbox while executing the
  triggering SDK method;
- Modal `terminate` ends the runtime;
- E2B `kill` is permanent;
- Fly `suspend` may later cold-boot instead of preserving memory;
- CodeSandbox `resume` may report a clean boot rather than restoration; and
- provider `snapshot` methods disagree about whether the source continues,
  stops, or is destroyed.

Names are therefore admitted only when the Core can define one exact,
target-independent postcondition.

### Public generic action invocation

The following public shape is rejected:

```text
InvokeAction {
  target
  name
  payload
}
```

It leaves invalid target, request, capability, result, epoch, and concurrency
combinations syntactically representable. Schema validation, idempotency,
authorization, evidence, and operation-pair rules would become undocumented
conventions keyed by strings.

A private driver interface may contain an equivalent internal escape for
provider integration. It is not serialized through the public API, cannot
bypass Core validation, and returns evidence to a typed Core operation rather
than defining the operation's meaning.

### Desired state as the Core mutation API

A caller-writable `desiredRuntimeState` is rejected from the Core. Desired
state is useful for a NixOS module, systemd service, Kubernetes controller, or
managed long-lived service, but it cannot replace request identity:

- it does not identify which caller requested a transition;
- it loses per-request result and ambiguity history;
- it does not naturally return a newly created Snapshot or Sandbox;
- it makes cancellation ownership unclear;
- intermediate controller observations can be stale; and
- multiple controllers introduce separate interleaving and liveness
  obligations.

The optional Managed-Sandbox Service Definition remains above Core. It issues
the same named operations and observes their durable results.

## Naming Rules

Public names obey all of these rules:

1. The resource being acted on is explicit when omission would be ambiguous.
2. A verb names a required postcondition, not a mechanism or trigger.
3. A single name cannot hide runtime replacement, deletion, or continuity
   loss.
4. A compound effect is either decomposed or represented explicitly in the
   request.
5. Provider vocabulary does not establish portable semantics.
6. A capability-gated method remains fully specified; capability gating does
   not permit provider-defined behavior.
7. There is no `providerDefault`, hidden fallback, or unrecorded default.
8. Names familiar from sandbox providers are retained when their meaning can
   be made exact.
9. Presentation conveniences may be shorter than the wire method, but cannot
   introduce another semantic operation.

`Sandbox`, `Operation`, `Process`, and `Snapshot` are public resource nouns.
`Session` remains adapter-owned. A `{ sandboxId, epoch }` runtime reference
remains a value rather than a writable resource.

## Packet E Public Method Inventory

### Portable lifecycle mutations

These methods are required for every conforming execution driver:

| Method | Target | Durable result | Exact success postcondition |
|---|---|---|---|
| `CreateSandbox` | newly allocated Sandbox | `Operation<CreateSandboxResult>` | a stable Sandbox exists in the explicitly requested initial runtime state |
| `StartSandbox` | stopped Sandbox | `Operation<StartSandboxResult>` | a new runtime epoch is running, controllable, conforming, and accepting Exec |
| `StopSandbox` | extant Sandbox runtime | `Operation<StopSandboxResult>` | execution admission and launch authority are closed, every Process is terminal, and runtime containment absence is proven |
| `DeleteSandbox` | stopped Sandbox | `Operation<DeleteSandboxResult>` | the live Sandbox aggregate and all required Core-owned live resources are absent; independently retained records remain |
| `TerminateProcess` | exact Process and runtime epoch | `Operation<TerminateProcessResult>` | the Process has an immutable terminal outcome and can no longer act |

`CreateSandbox` has an explicit initial runtime selection:

```text
initialRuntime = running | stopped
```

The canonical request always contains the resolved value. A CLI, SDK, or named
profile may choose `running` for an omitted ergonomic input, but the accepted
request and Operation never contain an invisible default.

Creating initially running allocates epoch `1` before launch effects. Creating
initially stopped allocates no runtime epoch until the first `StartSandbox`.
The Sandbox ID is allocated and durable in both cases.

`StopSandbox` never silently deletes. `DeleteSandbox` never silently stops.
Callers that want both issue and observe the two exact operations. An SDK may
offer an explicit composite helper, but its returned result must expose both
underlying Operations.

Delete also cannot erase independently retained Snapshot bytes. If a provider
deletes Snapshots with its aggregate Sandbox object, Core Delete is rejected
until every dependent Snapshot is deleted, exported/mirrored into
Core-controlled retention, or otherwise proven independent.

### Execution

`Exec` is the one specialized effectful method:

```text
Exec(SandboxRuntimeRef, ExecRequest) -> Process
```

It returns a durable `Process` rather than a generic Operation. Acceptance
means:

- the exact Sandbox ID and current runtime epoch were validated;
- execution admission was `accepting`;
- the Core Process ID, canonical request, launch token, and effect intent were
  durably allocated before dispatch;
- the request is bound to its idempotency coordinate; and
- retries can only recover that same Process.

It does not mean the Process has started. `accepted`, `starting`, `running`,
`unknown`, and `terminated` remain distinct Process facts.

A backend execution identity may be assigned only by the external launch
effect. When so, the driver records it durably after the response and
reconciles the crash window using provider idempotency, a caller-selected
launch token understood by a Core guest supervisor, or exact adoption. If none
can identify the one attempted execution, the Process becomes `unknown`; the
Core never dispatches a replacement.

Every conforming execution driver implements `TerminateProcess`. A driver
cannot claim Core `Exec` support while offering no way to prove that an
accepted Process can no longer act during Process termination or Sandbox
Stop.

Full Core Exec conformance also requires:

- a targetable execution containment unit covering the Process and its owned
  descendants;
- durable output spooling with stable byte cursors and explicit truncation;
- exact terminal evidence;
- stdin ownership and close semantics; and
- recovery/adoption of the same attempted execution after control-plane
  failure.

A native provider command API may satisfy those requirements directly.
Otherwise the adapter requires a Core-managed in-guest supervisor plus durable
Core or guest spool. A direct SDK adapter that cannot supply them does not
advertise full Core Exec even if the provider can run a command.

### Portable observations

Reads are synchronous observations and never create Operations:

| Resource | Read surface |
|---|---|
| Sandbox | `GetSandbox`, `ListSandboxes`, `WaitSandbox` |
| Operation | `GetOperation`, `ListOperations`, `WaitOperation` |
| Process | `GetProcess`, `ListProcesses`, `WaitProcess` |
| Snapshot | `GetSnapshot`, `ListSnapshots` |

`Wait*` is an observational call with an observation deadline. Its deadline
does not cancel or mutate the observed resource. Streaming watch projections
may later share the same event transport, but cannot have stronger semantics
than repeated `Get` or `Wait`.

Effective capabilities are immutable facts returned with the relevant built
Artifact member, runtime profile, Create resolution, and Sandbox. Capability
discovery is not a lifecycle mutation and does not need a generic
`GetCapabilities` action detached from the resource whose capabilities are
being described.

### Process I/O

The Core exposes precise Process transport operations:

| Method | Contract |
|---|---|
| `ReadProcessOutput` | reads stdout, stderr, or the merged terminal stream from an explicit durable cursor; follow, expiry, truncation, and byte limits remain observable |
| `WriteProcessInput` | admits bytes into the ordered control stream of the one active stdin writer lease for a Process whose accepted stream contract permits input |
| `CloseProcessInput` | admits an irreversible ordered close record into that Process control stream |
| `ResizeProcessTerminal` | admits an ordered rows-and-columns change for a nonterminal Process that was created with a terminal |

`ResizeProcessTerminal` is conditionally available when `Exec` selected a
terminal. It is not `ResizeSandboxResources`.

`WriteProcessInput`, `CloseProcessInput`, and `ResizeProcessTerminal` are
sequenced Process-control commands, not ordinary retryable RPCs. Their exact
Process, Sandbox, runtime epoch, writer lease, and monotonically increasing
sequence number are part of the command coordinate. Equal sequence and equal
canonical command recover the same durable receipt; equal sequence with
different content is a typed conflict. A receipt proves durable
deduplication and ordering, not that the application consumed input or acted
on a terminal resize.

The command union, acceptance, delivery, deduplication, and remaining
writer-lease obligations are locked in
[Packet E: Request, Result, Error, and Recovery Contract](./PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md).

There is no Core `AttachProcess` method. An SDK `attach()` may combine output
following, an input writer lease, terminal resizing, and state observation.
That attachment is client/transport state, not a durable resource or lifecycle
transition.

### Operation cancellation

`CancelOperation` requests cancellation of one nonterminal Operation and
returns the updated observation of that same Operation. It does not create an
Operation whose target is another Operation.

The name follows established long-running-operation conventions, while the
state model prevents the name from becoming a false claim:

```text
accepted/running -> cancel_requested
```

Only proven exclusion of the requested effect permits terminal `cancelled`.
The original Operation may instead become `succeeded`, `failed`, or `unknown`
if the race or external effect resolves differently.

There is no caller-facing `DeleteOperation`. Operation retention is
independent of target deletion and is enforced by the service.

### Portable control-plane updates

The Core does not expose a generic `UpdateSandbox`.

Two narrow, representation-level operations are portable:

| Method | Semantics |
|---|---|
| `UpdateSandboxMetadata` | etag-guarded update of labels and explicitly non-authoritative correlation metadata |
| `SetSandboxExpiration` | etag-guarded assignment of an exact absolute expiration schedule or explicit removal of the caller-managed schedule |

`Sandbox.name` is immutable after Create. It remains reserved to that Sandbox
until Delete, avoiding hidden release, historical-alias reservation, and
rename races.

The canonical expiration value is:

```text
expiration =
    none
  | {
      at
      action = stop | delete
    }
```

Neither the time nor action has a provider-selected default.

These mutate Core-owned control records, not the running workload. They do not
change runtime epoch or grant runtime authority. Their successful update may
be returned synchronously because the postcondition is a committed Core
representation rather than an asynchronous lifecycle effect.

An expiration instant is not a generic TTL:

- absolute expiration;
- maximum age from creation;
- idle duration;
- maximum runtime duration;
- Snapshot retention; and
- Operation, Process, event, or output retention

are distinct facts. Artifact hard ceilings and Managed-Sandbox lifecycle
policies remain declarative and cannot be widened by
`SetSandboxExpiration`; `none` removes only the caller-managed schedule.

When the instant passes, the service atomically closes execution admission and
durably records the system trigger before accepting another Exec. If an extant
runtime remains, it creates a system-originated `StopSandbox` Operation. If the
Sandbox already has a current durable stopped proof, no redundant Stop is
created. For `action = delete`, it creates a linked `DeleteSandbox` Operation
only after stopped is durably proven, whether by initially-stopped Create, an
earlier Stop, or the expiry-triggered Stop. A failed or `unknown` Stop cannot
be bypassed by Delete. `expired` is an event/reason, not another Sandbox
runtime state.

Provider-native TTL, auto-stop, and auto-delete mechanisms must be disabled or
fenced behind that exact durable sequence. An unpreventable provider expiry is
an uncontrolled provider-loss event requiring reconciliation; it is never
retrospectively labeled a successful Core Stop or Delete.

Network policy, mounts, workspace materialization, devices, secrets, runtime
profile, image, kernel, and immutable environment are not metadata. They
cannot be changed through either method.

## Capability-Gated Methods

Capability gating means that the method retains one exact Core contract while
some target profiles reject it synchronously as unsupported. It does not
permit approximation.

### Process signals

`SignalProcess` targets one exact Process, Sandbox, and runtime epoch and
returns a durable Operation.

Its request selects one signal from the effective capability's closed
advertised set. Success proves exact target-specific dispatch was invoked and
accepted. It does not prove delivery, handling, or Process exit.

Arbitrary numeric provider or host signals are not portable. A target may
advertise a reviewed extended signal set, but it cannot emulate a missing
Process signal with VM power controls or Sandbox deletion.

### Suspend and Resume

`SuspendSandbox` and `ResumeSandbox` are a paired capability:

| Method | Required start | Epoch rule | Required success |
|---|---|---|---|
| `SuspendSandbox` | running and accepting or running and closed under compatible control | retain current epoch | all execution is quiesced, same-epoch Process continuity is proven, admission is closed |
| `ResumeSandbox` | suspended | retain current epoch | execution resumes under exclusive authority, control/conformance are re-proven, admission becomes accepting |

The following are not Core Resume:

- filesystem-only recreation;
- restoring from a Snapshot;
- provider cold fallback;
- lazy creation behind a connect call;
- auto-wake that creates a new runtime;
- restart after runtime loss; or
- a provider handle reconnecting to a replacement instance.

Those outcomes use `StartSandbox`, `RestoreSandbox`, or
`CreateSandbox(source = snapshot)` and allocate the required new epoch.

An attachment may need to reconnect after a valid same-epoch Resume.
Attachment continuity is never implied.

### Sandbox resource resize

`ResizeSandboxResources` is capability-gated, typed by resource family, and
returns a durable Operation. It has two state-specific postconditions:

| Starting state | Required success |
|---|---|
| `running` | apply the requested resources atomically in place without reboot, runtime replacement, or Process identity loss; retain the current epoch and prove the applied resources |
| `stopped` | commit the validated concrete allocation for the next Start; allocate no runtime epoch and claim no current provider capacity |

Partial provider updates are not success. A provider that cannot resize a
running runtime in place rejects that starting-state combination. The caller
may explicitly Stop, resize the stopped Sandbox's next-runtime allocation, and
Start a new epoch. The canonical Resize request always contains the complete
resolved allocation; it cannot defer meaning to provider defaults.

Disk growth, CPU hotplug, memory hotplug, accelerator changes, and provider
tier changes are separate capability members even if an SDK groups them under
`resize` or `update`.

### Snapshot

`Snapshot` is an immutable retained-state resource, not an Artifact,
deployment, runtime epoch, or provider image.

`Snapshot.id` is server-allocated and never reused, including after deletion.
Its `manifestDigest` commits the immutable manifest and retained-component
digests for integrity and deduplication; it is not resource identity. Two
Snapshot resources may have equal manifests without becoming the same
resource, and a stale handle is never retargeted to equal content.

Every Snapshot manifest carries the exact source Artifact Set/member,
runtime-profile identity, and relevant immutable manifest digests. A Snapshot
does not become a second way to redefine Artifact policy. Restore and
restore-as-create either use those exact immutable identities or fail
compatibility validation; supplying a different Artifact is a new Sandbox
construction problem, not Restore.

`CreateSnapshot` targets an exact Sandbox runtime and returns:

```text
Operation<CreateSnapshotResult {
  snapshotId
  sourceSandboxId
  sourceRuntimeEpoch
  sourceAfterCapture
}>
```

The request selects one exact resolved Snapshot capability and one source
postcondition:

```text
snapshotClass = exact capability identity
sourceAfterCapture = runtimeStatePreserved | stopped
```

The selected Snapshot class is a content-addressed capability definition that
contains at least:

```text
kind = filesystem | runtime
componentSet
externalStorageTreatment
secretTreatment
compatibilityDomain
quiescenceProtocol
deviceStateTreatment
portability
coreProcessHandling
```

There is no omitted or provider-selected value. A named authoring profile or
SDK convenience may select a class, but its exact identity and complete
resolved definition appear in the canonical request and Snapshot manifest.
The class, its `kind`, and the Artifact's declared Snapshot requirements must
match before acceptance.

A `filesystem` class captures the declared mutable filesystem state needed for
later materialization. It does not claim memory, Process, open-descriptor,
clock, network-connection, or device continuity.

A `runtime` class captures the complete class-defined state required to
reconstruct the Sandbox runtime: its manifest identifies filesystem, memory,
guest/runtime services, device, kernel/VMM, and external components as
included, referenced, or excluded. It is successful only when every required
component is durable and compatible metadata is committed.

Core v1 Snapshot classes support only:

```text
coreProcessHandling = rejectNonterminal
```

`CreateSnapshot` therefore rejects while any Core Process in the source epoch
is nonterminal. Restore, restore-as-create, and Fork cannot recreate an acting
Exec process without a new durable Process identity and control contract. A
future `successorProcesses` class requires a separate reviewed design covering
new Process IDs, provenance, deadlines, termination requests, containment,
stdin, durable output cursors, and terminal evidence before restored execution
can resume.

`sourceAfterCapture = runtimeStatePreserved` requires the source to finish in
its original Sandbox runtime state and epoch. Temporary quiescence is
permitted only when the original state and authority are restored. Broken
attachments or external connections are recorded separately; a target whose
capture necessarily terminates or replaces the runtime cannot claim this
postcondition.

`sourceAfterCapture = stopped` explicitly includes the Stop postcondition:
all Processes are terminal, containment absence is proven, and the prior
epoch cannot act. This is not a hidden provider side effect.

`DeleteSnapshot` always targets the immutable Snapshot and returns
`Operation<DeleteSnapshotResult>`. A fast local deletion returns an
already-terminal Operation. It cannot delete a Snapshot still protected by a
Sandbox source reference, accepted restore, retention hold, or other exact
reference contract.

### Restore and restore-as-create

`RestoreSandbox` has one meaning:

- the target is the same stable Sandbox;
- the Sandbox must already be `stopped`;
- the Snapshot must be compatible and complete;
- the Core allocates a new runtime epoch before restore effects;
- old Process handles are never retargeted and the v1 Snapshot contains no
  nonterminal Core Process to resurrect;
- success means the new epoch is running, controllable, conforming, and
  accepting; and
- old runtime authority cannot be reactivated.

Restoring as a new Sandbox is represented by:

```text
CreateSandbox {
  source = SnapshotRef
  initialRuntime = running | stopped
  ...
}
```

It creates a new Sandbox ID. Running creation begins at epoch `1`; stopped
creation holds the immutable Snapshot source and allocates no epoch until
Start.

The Snapshot source supplies its pinned Artifact identity. The request may
provide new dynamic bindings only where the Snapshot manifest explicitly
marks them rebindable and the original Artifact permits them. It cannot
replace or widen immutable environment, filesystem, network, identity,
device, secret, or target-profile policy.

### Fork

`ForkSandbox` is capability-gated and has one strict meaning:

- the source is an exact Sandbox and runtime epoch;
- the source Sandbox runtime state and epoch are preserved; attachment or
  external-connection disruption is reported separately;
- no Core Process in the source epoch is nonterminal under the v1
  `rejectNonterminal` Snapshot rule;
- the child receives a new Sandbox ID;
- the child is independently running at epoch `1`;
- the result records complete Snapshot-equivalent provenance and ancestry;
- the child shares no Core Process identity or mutation authority with the
  source; and
- duplicated guest uniqueness, secrets, entropy, clocks, identifiers, and
  external connections are regenerated, invalidated, or explicitly rejected
  according to the target contract.

If a driver cannot prove those properties, it does not advertise Fork. Core
may internally lower one accepted Fork Operation to capture plus child
creation while preserving its sealed target and atomic contract. An SDK may
offer `CreateSnapshot` followed by `CreateSandbox(source = snapshot)` as an
explicit convenience returning both Operations, but that composite is not a
`ForkSandbox` Operation.

## Operation Targets

The durable Operation target union includes immutable Snapshot mutation and
the two-resource Fork coordinate:

```text
OperationTarget =
    SandboxOperationTarget {
      sandboxId
      expectedRuntimeEpoch?
      expectedEtag?
    }
  | ProcessOperationTarget {
      processId
      sandboxId
      runtimeEpoch
    }
  | SnapshotOperationTarget {
      snapshotId
    }
  | ForkOperationTarget {
      source {
        sandboxId
        runtimeEpoch
      }
      childSandboxId
    }
```

Create, Start, Stop, Suspend, Resume, Snapshot capture, Restore, Resize, and
Delete use a Sandbox target. Signal and Terminate use a Process target.
DeleteSnapshot uses a Snapshot target. Fork uses the sealed Fork target.

CreateSandbox allocates the target Sandbox ID before effect-producing work and
records it in the Operation. It may additionally reference an Artifact or
Snapshot source, but the source is not substituted for the mutation target.
Fork likewise allocates its child Sandbox ID durably before capture or
child-creation effects and permanently binds it to the exact source runtime.

Each operation kind has sealed kind-specific metadata and result types. An
open authorable `Any`, JSON object, native payload, or string-keyed union is
not part of the public contract.

## Operations Deliberately Outside Core v1

### No portable Restart, Wake, Kill, Destroy, or Rollback

| Rejected name | Ambiguity | Exact replacement |
|---|---|---|
| `RestartSandbox` | guest reboot, Stop/Start, cold replacement, recovery, or delete/create | observe `StopSandbox`, then `StartSandbox` |
| `WakeSandbox` | same-epoch Resume, cold Start, restore, lazy creation, or HTTP trigger | use the exact resulting operation |
| `KillSandbox` | Process signal, force Stop, runtime termination, or permanent deletion | `SignalProcess`, `TerminateProcess`, `StopSandbox`, or `DeleteSandbox` |
| `DestroySandbox` | compound Stop/Delete or provider permanent kill | explicit Stop then Delete |
| `RollbackSandbox` | restore of local state falsely presented as reversal of external effects | `RestoreSandbox`; external compensation remains separate |

### No portable Connect, Attach, Detach, Shell, or Session

These names describe client/framework ergonomics:

- `connect` resolves or authenticates a client handle;
- `attach` binds streams;
- `detach` releases a local binding;
- `shell` is Exec with a terminal and shell argv; and
- `session` may mean an agent conversation, VM epoch, shell context, browser
  credential, or provider object.

They remain SDK helpers over Sandbox reads, Exec, Process I/O, and explicit
lifecycle methods.

### No portable generic Update, Copy, or TTL

`UpdateSandbox` is rejected because metadata, expiration, resources, network
policy, runtime replacement, and provider tier changes have different
authorization, capability, epoch, and failure contracts.

`Copy` is rejected because it may mean:

- guest-local path copy;
- host-to-Sandbox upload;
- Sandbox-to-host download;
- cross-Sandbox transfer;
- Snapshot clone;
- Artifact copy; or
- Sandbox fork.

Packet A's file and port data-plane operations remain separately owned and
will participate in the Packet E concurrency matrix. Their direction and
namespace must be explicit.

`TTL` is rejected as a field or operation name unless qualified by the exact
clock and subject.

### Archive and migration remain out of public v1

`ArchiveSandbox` and `UnarchiveSandbox` are not portable lifecycle methods.
Provider archives range from cold filesystem storage to provider-specific
hibernation. A later design may add an exported retained-state package with a
checksummed manifest, compatibility contract, and explicit relationship to
Snapshot.

Migration is initially system/operator-owned. A future public
`MigrateSandbox` may retain an epoch only when it proves:

- compatible source and destination;
- exclusive target-enforced authority transfer;
- fenced or terminated source;
- Process continuity;
- routing handoff;
- exact handling of open attachments and external connections; and
- a definite terminal outcome.

Cold relocation or replacement is not migration and allocates a new epoch.

## Driver Interface Consequences

The private driver interface may decompose one Core operation into native
steps such as:

```text
resolve -> reserve -> prepare -> materialize -> launch
        -> connect-control -> verify -> admit

quiesce -> capture -> package -> persist -> restore-source

close-admission -> revoke-launch -> drain -> terminate
                -> prove-absence -> clean

observe -> adopt -> reconcile -> fence -> quarantine
```

These are internal phases, not public Sandbox states or methods.

The driver:

- receives only validated typed input;
- cannot change a requested postcondition;
- cannot silently invoke a colder or more destructive fallback;
- returns structured evidence rather than a provider phase as truth;
- declares the effect class of each native step as idempotent, adoptable,
  compensable, or opaque;
- participates in authority fencing and epoch validation;
- records native identifiers as evidence, not public identity; and
- reports unsupported capability before effect-producing work.

microvm.nix, jail.nix, bubblewrap, an OCI runtime, a VMM API, or a provider SDK
is a lowering mechanism. None defines Core operation semantics by itself.

## Provider Reconciliation

The table records why provider verbs are evidence and adapter inputs rather
than the portable vocabulary.

| Provider | Relevant native surface | Core consequence |
|---|---|---|
| E2B | create, connect, pause, kill, set timeout, update network, create Snapshot, command run/connect/kill | connect is attachment plus possible Resume; permanent kill is not Stop; process-bearing native Snapshot is rejected by the v1 Core class; PID kill and provider streams alone do not prove descendant containment or durable output, so full Exec requires additional supervisor/spool conformance |
| Modal | create, from ID, exec, terminate, detach, wait, tunnels, filesystem and memory Snapshot | detach is local; terminate ends an epoch; filesystem and memory Snapshot have different completeness/source contracts and process-bearing restore is outside v1; ContainerProcess lacks the complete targeted termination/durable-output proof required for direct full Core Exec |
| Daytona | start, stop, pause, recover, resize, archive, delete, TTL and lifecycle policies, experimental Snapshot/Fork | closest direct lifecycle mapping, but archive, recover, TTL, hot resize, disk resize, and experimental state transfer remain distinct capabilities; PTY/session controls do not by themselves prove general Process containment and durable output |
| Fly Machines | create, start, stop, suspend, update, lease, cordon, delete, wait | acknowledgement requires later observation; suspend can cold-fallback; running update may replace runtime identity |
| Vercel | logical Sandbox with successive VM Sessions, create/get/fork/stop/update/delete/extend/snapshot | validates stable Core Sandbox plus replaceable epoch; auto-resume and snapshot-triggered Stop must not replay old Processes; native Fork uses an existing possibly stale Snapshot or fresh-create fallback and cannot satisfy exact-runtime Core Fork; native Delete also removes provider Snapshots and is forbidden while retained Core Snapshots depend on them |
| Cloudflare | lazy Durable Object handle, keep-alive, destroy, exec/process, expose port, directory backup | obtaining a handle is not Connect; idle sleep loses state and is Stop/new Start, not Suspend; directory backup is not a Sandbox Snapshot |
| CodeSandbox | create/connect/session, hibernate/resume/restart/shutdown/delete, tier and timeout update | clean fallback is not Resume; restart is compound; client Session is not Core lifecycle |
| Kubernetes Agent Sandbox | desired `Running` or `Suspended`, shutdown time/policy, Conditions | useful desired-state adapter; CRD does not itself supply Process, file, copy, port, signal, or Snapshot semantics |
| OpenAI hosted Containers | create/list/get/delete and managed files; model-mediated code execution | create/delete/files may adapt; no caller-controlled durable Process means it cannot claim full Core Exec |
| OpenAI Sandbox Agents | client create/close/resume, serialized Session state, Snapshot and optional exec/PTY capabilities | framework adapter SPI; `resume` must choose reattach, genuine Resume, or replacement based on identity proof |
| Blaxel | create/get/delete, expiration, Process/files, automatic standby/resume | provider standby may preserve memory while losing external connections; exact continuity capability and epoch evidence remain required |
| OpenSandbox | create/delete/pause/resume/renew/metadata/endpoint/Snapshot plus execd Process and files | close vocabulary match, but interrupt, diagnostic events, and maturity do not weaken durable Operation and evidence requirements |

### Adversarial provider examples

The design must retain these counterexamples as conformance fixtures:

1. E2B `connect` to a paused Sandbox resumes retained state; Cloudflare
   obtaining the same logical handle may lead to a fresh container with lost
   state.
2. Modal creation can precede readiness; Daytona start waits for readiness.
3. Vercel Stop preserves filesystem through Snapshot; Cloudflare idle Stop
   loses all ephemeral state.
4. E2B Snapshot resumes its source; Modal memory Snapshot can terminate it;
   Vercel Snapshot shuts it down.
5. CodeSandbox Resume can result in an exact resume or a clean boot.
6. Fly Update may reboot or replace; Daytona CPU/memory growth may be hot.
7. OpenAI Code Interpreter can execute model-selected code without exposing a
   durable caller-controlled Process.
8. Kubernetes Pod exec, copy, and port-forward are not methods of the Agent
   Sandbox CRD.
9. Blaxel may preserve guest processes while external network connections are
   lost.
10. Cloudflare backup/restore is directory overlay state, not a complete
    runtime Snapshot.
11. E2B, Modal, Daytona, and OpenSandbox commonly restore as a new provider
    Sandbox, while Vercel can retain a logical name across a new VM Session.
12. Provider `kill` spans Process SIGKILL, forced runtime termination, and
    permanent logical deletion.
13. Vercel native Fork does not prove derivation from the exact current source
    epoch; capturing a new native Snapshot first stops the source.
14. Vercel native Delete removes its provider Snapshots and cannot lower Core
    Delete while independently retained Core Snapshot bytes depend on them.
15. E2B, Modal, and Daytona command surfaces require added containment,
    terminal-evidence, adoption, and durable-output machinery before claiming
    full Core Exec.

## Runtime and Mechanism Reconciliation

| Mechanism | Native lifecycle facts | Product consequence |
|---|---|---|
| OCI Runtime Specification | state, create, start, kill, delete; delete normally requires stopped | established named-method precedent, but no portable Exec, wait, attach, suspend, Snapshot, restore, or migration contract |
| containerd Runtime v2 | create/start/delete, exec then start, wait, kill, pause/resume, checkpoint, update, terminal resize, I/O FIFOs | useful driver mechanisms; provider acknowledgements and client-owned streams do not replace Core durability |
| Kubernetes CRI | pod Sandbox/container create/start/stop/remove, exec/attach endpoints, resource update, evolving checkpoint/restore | Stop semantics and streaming endpoints require Core proof and durable Process identity above the CRI call |
| Linux pidfd and cgroup v2 | stable Process targeting, signal dispatch, wait evidence, freeze, subtree kill, `populated=0` | strong local proof mechanisms for Process identity, quiescence, termination, and containment absence |
| bubblewrap | one-shot namespace/process launch, optional PID 1, initial-child status | product supervision supplies durable multi-Exec, Process, Stop, streams, and any Suspend semantics |
| Firecracker | preboot configuration, one-shot start, pause/resume, Snapshot load/create, guest-dependent shutdown | a guest control plane is required for Process semantics; restored VMs begin paused and Snapshot packaging is integrator-owned |
| Cloud Hypervisor | VM create/boot/shutdown/delete, pause/resume, resize/hotplug, Snapshot/restore, migration | typed VMM controls are mechanisms; guest Process, fencing, readiness, and evidence remain product-owned |
| QEMU QMP/QGA | VM power/run state, asynchronous jobs, migration, guest exec/status/shutdown | command acknowledgement does not prove shutdown, Snapshot, migration, or Process exit |
| CRIU | dump/restore, pre-dump, lazy pages, external-resource and source-disposition controls | supplies checkpoint mechanisms, not Sandbox identity, fencing, completeness, external-effect rollback, or durable Operations |
| microvm.nix | construction and systemd integration over heterogeneous VMMs | does not provide one common Snapshot, migration, guest Process, or lifecycle proof contract |

## Framework and SDK Boundary

Framework adapters own:

- framework Session identity;
- whether a tool call uses a fresh or reused Sandbox;
- reconnect versus rebind behavior;
- translating framework cancellation and cleanup policy;
- presenting shell, terminal, and file tools;
- framework tracing and error conversion; and
- explicit composites such as Stop then Delete.

They do not own:

- Core Sandbox identity or runtime epoch;
- lifecycle state semantics;
- Process acceptance or replay;
- capability approximation;
- idempotency binding;
- mutation serialization;
- external-effect ambiguity; or
- provider fencing and cleanup proof.

For OpenAI Sandbox Agents specifically, `SandboxSession.resume()` cannot map
blindly to `ResumeSandbox`. The adapter first determines whether the provider
can prove:

1. attachment to the same runtime epoch;
2. genuine same-epoch suspended Process continuity; or
3. replacement from retained Snapshot/filesystem state.

The three results map respectively to reattachment, `ResumeSandbox`, or
`CreateSandbox`/`RestoreSandbox` with a new epoch.

## Desired-State Boundary

The optional managed layer may declare facts such as:

```text
artifact
bindings
allocation
placement
autostart
restart or recreate policy
probes
expiration and idle policy
retention
dependencies
```

Its reconciler:

- reads current Core resources;
- issues the named Core operations;
- records its own desired-state revision;
- never rewrites an existing Operation result;
- never interprets a provider phase as Core state;
- uses etag and runtime epoch preconditions; and
- exposes system-originated Operations to users.

Controller verification is a separate obligation because stale observations,
multiple controllers, intermediate states, and liveness are not solved by the
Core method vocabulary.

## Compile-Time and Runtime Rejection

The declarative Artifact and target-profile capability model reject
structurally impossible operation requirements before construction:

- a profile requiring Suspend cannot target a driver without proven
  same-epoch Suspend/Resume;
- every declared Snapshot component, external-storage and secret treatment,
  compatibility domain, quiescence protocol, device treatment, portability,
  and Process-handling requirement must match at least one exact target
  Snapshot class;
- a multi-target definition cannot require a capability absent from one
  selected target unless the target branch is explicit;
- a resource range cannot request live resize beyond the Artifact hard
  maximum or target capability; and
- a required Process signal set must be supported by every selected target.

Dynamic facts remain runtime preconditions and cannot be proved during Nix
evaluation:

- current Sandbox or Process state;
- current runtime epoch and etag;
- resource capacity and provider admission;
- concurrent Operations;
- Snapshot retention/reference state;
- expiration races;
- provider availability; and
- evidence freshness.

These fail synchronously before Operation or Process acceptance when the Core
already knows the request is invalid. Failure discovered after durable
acceptance is recorded on that same Operation or Process.

## System-Originated Operations

Expiry, cleanup, provider-event recovery, orphan adoption, and reconciliation
are not automatically caller-invocable methods.

When they use a public lifecycle semantic, they create the same typed
Operation with `origin = system` or `origin = managedService`.

Any system-specific work represented as a user-readable Operation uses a
closed, wire-visible, non-caller-invocable kind with declared metadata and
result types, such as reconcile, adopt, fence, quarantine, or cleanup. An
activity whose schema is not part of that public decoding union remains an
internal evidence/activity record rather than an Operation.

System work:

- cannot rewrite an earlier terminal result;
- links successor reconciliation or cleanup Operations;
- uses the same target, epoch, authority, and proof rules;
- remains readable for the normal Operation retention period; and
- cannot turn a previous `unknown` into a different terminal result by
  mutation.

## Verification and Machine-Inventory Consequences

The next Packet E ledger must close the Cartesian product of:

1. method or system-operation kind;
2. tagged target kind;
3. starting Sandbox, execution-admission, Process, Snapshot, and Operation
   state;
4. capability profile;
5. expected runtime epoch and etag freshness;
6. caller, managed-service, and system origin plus authorization;
7. idempotency-key absence, equality, and canonical-request conflict;
8. every concurrent operation pair;
9. observation deadline, execution deadline, cancellation, and client
   disconnect;
10. crash before durable intent, after intent, before dispatch, after
    dispatch, before evidence, and before terminal commit;
11. provider effect class: idempotent, adoptable, compensable, or opaque;
12. Snapshot kind, completeness, source disposition, ancestry, and reference
    state;
13. restore/fork identity and uniqueness regeneration;
14. cleanup, orphan, and retention state;
15. declared, lowered, prepared, observed, and recorded facts; and
16. required success evidence and forbidden approximation.

The compatibility ledger is total: an absent entry is a specification error,
not permission. Every non-permitted complete row explicitly denies
concurrency and yields the declared conflict. An implementation missing its
generated row fails closed and is non-conforming. Unsupported capabilities
fail before effect. No cell may inherit behavior from a provider verb or a
generic fallback.

The formal model must include:

- API acceptor;
- lifecycle authority;
- Process supervisor and output spool;
- Snapshot store;
- desired-state controller;
- stale controller;
- cleanup/reconciliation worker;
- provider and guest event channels;
- target-side fencing; and
- crashes and reordered, duplicated, delayed, or lost observations.

Generated model traces must be replayed against the implementation. Backend
conformance tests must exercise real provider/runtime behavior, including the
adversarial cases above.

## Registry Obligations Introduced

The exhaustive Packet E walk must partition these candidate invalid states by
owner and earliest-sound boundary, assign stable identifiers, and add positive
and negative witnesses. They are obligations, not current registry coverage:

1. public generic action or provider method bypassing typed Core semantics;
2. provider verb admitted as portable without one exact postcondition;
3. unsupported capability approximated instead of rejected;
4. omitted initial runtime selection remaining invisible in the canonical
   Create request;
5. Create-running succeeding before control, conformance, and admission are
   proven;
6. Stop silently deleting or Delete silently stopping;
7. Delete erasing independently retained Snapshot bytes;
8. public Restart, Wake, Kill, Destroy, or Rollback bypassing exact component
   semantics;
9. Attach, Connect, Detach, Shell, or Session gaining independent lifecycle
   authority;
10. Exec returning only an ephemeral blocking result instead of one durable
   Process;
11. accepted Exec driver unable to prove Process termination;
12. Process I/O without exact stream contract, cursor, truncation, expiry, or
    writer ownership;
13. terminal resize accepted for a Process without a terminal or after
    termination;
14. cancellation creating an Operation-of-Operation or reporting cancellation
    before exclusion is proven;
15. caller deleting an Operation before retention expiry;
16. generic Update changing metadata, policy, resources, or runtime under one
    contract;
17. metadata or expiration mutation changing runtime authority or epoch, or
    metadata update mutating the immutable Sandbox name;
18. bare TTL conflating distinct clocks, subjects, or retention contracts;
19. expiration widening an Artifact hard maximum;
20. expiration omitting its action, accepting Exec after its durable trigger,
    issuing redundant Stop against already-proven stopped, issuing Delete
    before stopped is proven, or treating provider-native expiry as a
    successful Core lifecycle sequence;
21. arbitrary or unsupported signal accepted;
22. signal dispatch represented as delivery, handling, or exit;
23. cold fallback or replacement reported as Resume;
24. Suspend or Resume accepted without the paired same-epoch continuity
    capability;
25. running Sandbox resize hiding reboot, replacement, partial application, or
    epoch change, or stopped Sandbox resize claiming current capacity;
26. Snapshot class or source-after-capture omitted or provider-selected;
27. Snapshot class identity disagreeing with kind, components, external
    storage, secrets, compatibility, quiescence, devices, portability, or
    Process handling;
28. filesystem Snapshot claiming runtime continuity;
29. runtime Snapshot succeeding with incomplete required components;
30. v1 Snapshot or Fork accepted while a Core Process is nonterminal;
31. restored execution acting without a newly reviewed successor Process
    contract;
32. runtime-state-preserved Snapshot changing source Sandbox runtime state or
    epoch;
33. source-stopped Snapshot succeeding before the Stop postcondition;
34. Snapshot omitting or overriding its pinned Artifact/member/profile
    identity;
35. Snapshot deleted while protected by an exact reference or retention hold;
36. Restore accepted against a non-stopped Sandbox;
37. Restore reusing an old runtime epoch or Core Process identity;
38. restore-as-create reusing the source Sandbox ID or widening immutable
    Artifact policy;
39. Fork changing source disposition or sharing Sandbox, Process, or mutation
    authority;
40. Fork omitting provenance, ancestry, completeness, or uniqueness handling;
41. Archive or Migration admitted publicly without their separately reviewed
    contract;
42. native provider action exposed through the public wire or used to widen a
    validated request;
43. provider acknowledgement treated as the required Core postcondition;
44. framework Session resume silently retargeting an old Process or runtime
    handle;
45. desired-state controller rewriting Core lifecycle or terminal Operation
    semantics;
46. statically absent cross-target capability deferred to workload launch;
47. dynamic state guessed during Artifact compilation;
48. system-originated work hidden from Operation observation;
49. reconciliation rewriting an earlier terminal Operation; and
50. absent operation-pair compatibility interpreted as permission.

## Remaining Packet E Work

This decision does not yet lock:

- every request and result field beyond the semantic fields fixed above and
  by the result/error contract;
- the exhaustive final error/failure/ambiguity variant subsets and exact
  protocol field spelling;
- Operation, Process, Snapshot, event, output, tombstone, and idempotency
  retention durations;
- Process writer-lease issue, renewal, transfer, expiry, fencing, delivery,
  discard, and spool-retention rules;
- complete Snapshot component and compatibility schemas;
- full file, port, transfer, and endpoint concurrency behavior;
- cleanup, orphan adoption, and reconciliation deadlines;
- provider-triggered transition interception and event records;
- dynamic reservation and time-of-check/time-of-use sequencing;
- guest-control request and acknowledgement protocol;
- the complete operation-pair compatibility table;
- the exhaustive transition ledger;
- stable registry entries, diagnostics, production hooks, and tests; or
- backend conformance evidence.

Those artifacts must use this closed Packet E lifecycle/control vocabulary
and the separately locked request/result/error/recovery architecture.
Adding, renaming, or changing the semantics of one of these methods reopens
the affected Packet E inventory. Closing separately owned file, directory,
transfer, endpoint, and port names extends the complete Core API without
silently changing this vocabulary.

## References

### API and protocol design

- [Google AIP-136: Custom methods](https://google.aip.dev/136)
- [Google AIP-151: Long-running operations](https://google.aip.dev/151)
- [Google AIP-155: Request identification](https://google.aip.dev/155)
- [Google long-running Operations protocol](https://github.com/googleapis/googleapis/blob/master/google/longrunning/operations.proto)
- [Kubernetes API conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [Temporal message passing](https://docs.temporal.io/sending-messages)

### Runtime specifications and mechanisms

- [OCI Runtime Specification lifecycle](https://github.com/opencontainers/runtime-spec/blob/main/runtime.md)
- [containerd Task API](https://github.com/containerd/containerd/blob/main/api/services/tasks/v1/tasks.proto)
- [containerd Runtime v2](https://github.com/containerd/containerd/blob/main/docs/runtime-v2.md)
- [Kubernetes CRI API](https://github.com/kubernetes/cri-api/blob/master/pkg/apis/runtime/v1/api.proto)
- [Linux cgroup v2](https://docs.kernel.org/admin-guide/cgroup-v2.html)
- [Linux pidfd open](https://man7.org/linux/man-pages/man2/pidfd_open.2.html)
- [Linux pidfd signal](https://man7.org/linux/man-pages/man2/pidfd_send_signal.2.html)
- [Linux waitid](https://man7.org/linux/man-pages/man2/waitid.2.html)
- [bubblewrap manual](https://github.com/containers/bubblewrap/blob/main/bwrap.xml)
- [Firecracker actions](https://github.com/firecracker-microvm/firecracker/blob/main/docs/api_requests/actions.md)
- [Firecracker Snapshot support](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md)
- [Cloud Hypervisor API](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/api.md)
- [Cloud Hypervisor Snapshot and restore](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/snapshot_restore.md)
- [Cloud Hypervisor live migration](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/live_migration.md)
- [QEMU QMP protocol](https://www.qemu.org/docs/master/interop/qmp-spec.html)
- [QEMU QMP reference](https://www.qemu.org/docs/master/interop/qemu-qmp-ref.html)
- [QEMU Guest Agent](https://www.qemu.org/docs/master/interop/qemu-ga-ref.html)
- [CRIU command reference](https://github.com/checkpoint-restore/criu/blob/criu-dev/Documentation/criu.txt)
- [microvm.nix](https://microvm-nix.github.io/microvm.nix/)

### Provider and framework contracts

- [E2B Sandbox SDK reference](https://e2b.dev/docs/sdk-reference/js-sdk/v2.29.1/sandbox.md)
- [E2B command SDK reference](https://e2b.dev/docs/sdk-reference/js-sdk/v2.2.0/commands)
- [E2B persistence](https://e2b.dev/docs/sandbox/persistence)
- [E2B Snapshots](https://e2b.dev/docs/sandbox/snapshots)
- [Modal Sandbox reference](https://modal.com/docs/reference/modal.Sandbox)
- [Modal ContainerProcess reference](https://modal.com/docs/sdk/py/latest/modal.container_process)
- [Modal Sandbox Snapshots](https://modal.com/docs/guide/sandbox-snapshots)
- [Daytona Sandbox SDK](https://www.daytona.io/docs/en/typescript-sdk/sandbox/)
- [Daytona Process SDK](https://www.daytona.io/docs/en/typescript-sdk/process)
- [Fly Machines API](https://fly.io/docs/machines/api/machines-resource/)
- [Fly Machine states](https://fly.io/docs/machines/machine-states/)
- [Vercel Sandbox SDK](https://vercel.com/docs/sandbox/sdk-reference)
- [Vercel persistent Sandboxes](https://vercel.com/docs/sandbox/concepts/persistent-sandboxes)
- [Vercel Snapshots](https://vercel.com/docs/sandbox/concepts/snapshots)
- [Cloudflare Sandbox lifecycle](https://developers.cloudflare.com/sandbox/api/lifecycle/)
- [Cloudflare Sandbox commands](https://developers.cloudflare.com/sandbox/api/commands/)
- [Cloudflare Sandbox backups](https://developers.cloudflare.com/sandbox/api/backups/)
- [CodeSandbox create and fork](https://codesandbox.io/docs/sdk/create)
- [CodeSandbox resume](https://codesandbox.io/docs/sdk/resume)
- [CodeSandbox restart and shutdown](https://codesandbox.io/docs/sdk/restart-shutdown)
- [Kubernetes Agent Sandbox API](https://agent-sandbox.sigs.k8s.io/docs/api)
- [OpenAI hosted Containers and Code Interpreter](https://developers.openai.com/api/docs/guides/tools-code-interpreter)
- [OpenAI Sandbox Agents](https://developers.openai.com/api/docs/guides/agents/sandboxes)
- [OpenAI Sandbox Agents client interface](https://openai.github.io/openai-agents-js/guides/sandbox-agents/clients/)
- [Blaxel Sandbox overview](https://docs.blaxel.ai/Sandboxes/Overview)
- [Blaxel expiration](https://docs.blaxel.ai/Sandboxes/Expiration)
- [OpenSandbox API](https://open-sandbox.ai/api/)

### Formal methods and research

- [Sagas](https://dl.acm.org/doi/10.1145/38713.38742)
- [Anvil](https://www.usenix.org/conference/osdi24/presentation/sun-xudong)
- [Sieve](https://www.usenix.org/publications/loginonline/sieve-chaos-testing-kubernetes-controllers)
- [Acto](https://dl.acm.org/doi/10.1145/3600006.3613161)
- [Kivi](https://www.usenix.org/conference/atc24/presentation/liu-bingzhe)
- [Beldi](https://www.usenix.org/conference/osdi20/presentation/zhang-haoran)
- [Boki](https://dl.acm.org/doi/10.1145/3477132.3483541)
- [Restoring Uniqueness in MicroVM Snapshots](https://arxiv.org/abs/2102.12892)
- [Crab](https://arxiv.org/abs/2604.28138)
- [DeltaBox](https://arxiv.org/abs/2605.22781)
- [Styx state migration](https://link.springer.com/article/10.1007/s00778-026-00971-x)

Provider APIs and recent research are evidence for the distinctions above,
not authorities that can redefine the Core contract.
