# Packet E: Durable Operations and Sandbox Runtime Identity

Status: **Locked Packet E foundation — lifecycle state, operation taxonomy,
and request/result/error contract locked separately; transition inventory and
enforcement closure remain open**

Locked: 2026-07-25

Evidence reviewed: 2026-07-25. This date applies to every source in the
evidence tables below unless a row states otherwise.

This record locks the durable-mutation and identity substrate on which Packet
E's lifecycle model is built. The Sandbox, execution-admission, and Process
state model is now locked in
[Packet E: Sandbox and Process Lifecycle State](./PACKET-E-LIFECYCLE-STATE-DESIGN.md).
The lifecycle/control method vocabulary, Snapshot boundary, naming rules, and
adapter/driver split are now locked in
[Packet E: Lifecycle and Control Operation Taxonomy](./PACKET-E-OPERATION-TAXONOMY-DESIGN.md).
The durable acceptance boundary, public outcome algebra, recovery semantics,
and evidence-refinement rule are now locked in
[Packet E: Request, Result, Error, and Recovery Contract](./PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md).
None of these records closes Packet E. Every operation's exhaustive
legal-transition inventory, resource retention, cleanup deadlines, complete
Snapshot schema, and enforcement registry still require review.

The research follows the locked
[Research and Evidence Standard](../RESEARCH-STANDARD.md). It reconciles
current provider contracts, established distributed-systems patterns, and
recent work on microVM identity and agent checkpoint/restore.

## Question

The Core Sandbox API must safely represent all of these without changing its
meaning by target or provider:

- a local bubblewrap process that starts almost immediately;
- an OCI container with a runtime-managed lifecycle;
- a microVM that may be paused, snapshotted, restored into another VMM, or
  migrated;
- a remote provider whose create or stop call outlives one RPC connection;
- an agent framework that reconnects after losing its client attachment;
- a retry after the caller cannot tell whether an effect occurred;
- stale SDK handles surviving a stop/start, rollback, failover, or deletion;
  and
- future adapter-level conversation or tool sessions that may span several
  Sandboxes or several executions of one Sandbox.

The design therefore needs separate answers to four questions:

1. Which durable Sandbox does the caller mean?
2. Which continuous runtime of that Sandbox does the caller mean?
3. Which internal actor currently has authority to produce effects?
4. Which mutation, Process, or observation does the caller mean?

A single “session,” provider instance ID, version number, or RPC cannot answer
all four.

## Locked Public Model

### Resources and coordinates

The public model uses these nouns:

| Concept | Meaning | Lifetime and reuse |
|---|---|---|
| `Sandbox` | The only writable aggregate for one live sandbox resource | Stable from create through delete |
| `Sandbox.name` | Optional human alias | May be reused only after the former Sandbox is deleted |
| `Sandbox.id` | Immutable identity of one Sandbox lifetime | Never reused |
| `Sandbox.etag` | Optimistic-concurrency token for one representation | Changes independently of runtime continuity |
| `Sandbox.status.runtime.epoch` | Monotonic identity of one continuous guest/process runtime | Never reused within a Sandbox |
| `Operation.id` | Identity of one accepted durable Core mutation other than Exec | Independent of the target and runtime epoch |
| `Process.id` | Identity of one accepted execution | Bound to exactly one Sandbox ID and runtime epoch |
| `Snapshot.id` | Immutable identity of one retained Snapshot resource | Never reused, even after Snapshot deletion |
| `Snapshot.manifestDigest` | Integrity coordinate committing the immutable Snapshot manifest and retained-component digests | May be equal for distinct Snapshot resources; never substitutes for Snapshot ID |
| event or output cursor | Position in an observation stream | Observation only; never identity or authority |
| `idempotencyKey` | Caller-selected deduplication coordinate for one canonical request | Never used as a resource ID |
| `correlationMetadata` | Caller metadata for tracing related work | No deduplication or authorization meaning |

`Sandbox.name` is selected, if present, during Create and is immutable for the
Sandbox lifetime. It remains reserved until Delete and is never part of
`UpdateSandboxMetadata`.

An illustrative response shape is:

```text
Sandbox {
  id
  name?
  etag
  status {
    phase
    runtime? {
      epoch
      startedAt
    }
  }
}
```

The exact wire encoding and field spelling remain API-encoding decisions. The
semantic distinctions in the table are locked.

The runtime epoch is server-allocated, output-only state. A caller cannot set,
reset, preserve, or decrement it through Create input, a lifecycle request, a
native provider extension, or an adapter.

### `SandboxRuntimeRef` is a value, not a resource

The semantic coordinate:

```text
SandboxRuntimeRef {
  sandboxId
  epoch
}
```

identifies one continuous runtime. It is carried by SDK handles, Process
records, relevant Operations, events, and evidence. It is not a separately
writable `Session`, `Incarnation`, `Run`, or `Deployment`.

The Core may later expose a read-only historical projection such as:

```text
/sandboxes/{sandboxId}/runtimes/{epoch}
```

if users need direct runtime-history queries. Such a projection must be derived
from immutable Operations, Processes, events, and tombstones. It may not own
desired state, independent policy, or lifecycle authority.

### `Session` remains outside the Core resource model

`Session` is reserved for adapter- or attachment-level concepts. Depending on
the framework, it may mean an agent conversation, one client attachment, a
stateful shell, a reusable tool context, or a provider-specific boot. It may
span one runtime, reconnect to one runtime, deliberately rebind to a new
runtime, or use multiple Sandboxes.

The framework adapter owns that choice and must make rebinding explicit. The
Core never silently retargets a Session, SDK handle, Process request, or stale
runtime reference to the newest epoch.

## Locked Durable Mutation Model

### Durable mutations return `Operation`

Every accepted Sandbox lifecycle mutation and Process signal/termination
mutation returns a durable `Operation`, including mutations that a local
driver can complete synchronously. A fast implementation returns an
already-terminal Operation; it does not create a different synchronous
contract. Sequenced input, close, and terminal-resize commands instead use the
Process-control receipt contract locked separately.

`CreateSandbox` returns an Operation whose eventual result identifies the
Sandbox. Stop, suspend, resume, snapshot, restore, and delete use the same
durable observation model if the capability is supported.

Accepted Process signal/termination mutations such as `SignalProcess` and
`TerminateProcess` also return Operations. An Operation has an explicit
tagged target equivalent to:

```text
SandboxOperationTarget {
  sandboxId
  expectedRuntimeEpoch?
}

ProcessOperationTarget {
  processId
  sandboxId
  runtimeEpoch
}

SnapshotOperationTarget {
  snapshotId
}

ForkOperationTarget {
  source {
    sandboxId
    runtimeEpoch
  }
  childSandboxId
}
```

A Process-targeted Operation never acquires a different Process target,
Sandbox, or runtime epoch during retry or reconciliation. It does not
implicitly hold the Sandbox lifecycle-mutation lane; exact concurrency is
defined by the operation compatibility contract.

`Exec` is deliberately specialized: it returns a durable `Process`, because
the caller needs process state, signals, exit information, and replayable
stdout/stderr rather than a generic lifecycle result. The accepted Process is
the durable handle for the execution. This does not authorize a second
execution semantics.

Reads such as get, list, inspect, and capability discovery are synchronous
observations. Wait and watch are separate observational calls over Operations,
Processes, Sandboxes, or event streams.

The Snapshot target is added by the separately approved operation-taxonomy
decision. Snapshot capture remains Sandbox-targeted and returns a Snapshot;
`DeleteSnapshot` targets that immutable Snapshot. `CancelOperation` requests a
state change on the existing Operation and does not create an
Operation-of-Operation.

Fork uses its sealed two-resource target. The Core allocates the child Sandbox
ID durably before capture or child-creation effects; the exact source runtime
and child ID never change during retry or reconciliation.

### Operation state semantics

The semantic state graph is:

```text
accepted -> running -> succeeded
                    -> failed
                    -> unknown

accepted/running -> cancel_requested -> cancelled
                                     -> succeeded
                                     -> failed
                                     -> unknown
```

These names are semantic; final protocol spelling remains open.

- Acceptance means the service has durably recorded the operation before
  effect-producing work begins.
- A terminal result is immutable.
- Cancellation is a request, not proof that the effect did not occur.
- A wait or watch deadline stops observation. It does not cancel the Operation,
  Process, provider request, or Sandbox mutation.
- An operation execution deadline may produce `failed` only when effects and
  required cleanup are known. Otherwise it produces `unknown` and records that
  effects may have occurred.
- The Operation remains queryable for its independently defined retention
  period after target deletion so that deletion, cleanup, or orphan outcomes
  do not disappear with the target.
- Each Operation records its exact tagged target. Every live target includes
  the Sandbox ID and expected runtime epoch; a Process target additionally
  includes the Process ID. A runtime-replacing result records its previous and
  resulting epochs rather than requiring callers to infer continuity from
  mutable status.

The design does not promise exactly-once external effects. It promises durable
request identity, explicit ambiguity, fencing, and deterministic retry
semantics at the Core boundary.

### Idempotency and ambiguity

An idempotency key is interpreted together with the canonical semantic request
and the authenticated scope chosen by the API design:

```text
same key + same canonical request -> same Operation or Process
same key + different request      -> typed idempotency conflict
```

Canonicalization excludes transport-only details and correlation metadata. A
caller retrying after disconnect receives the original durable handle rather
than launching a second effect.

If the Core cannot prove whether an external provider or guest effect occurred,
the terminal Operation result is `unknown`; it is never rewritten to success
or failure for ergonomics. `Process.state = unknown` is different: it is a
reconcilable observation state of the same accepted execution, not a terminal
Operation result or replay permission. An accepted `Exec` is never
automatically replayed merely because its outcome is ambiguous. Filesystem
rollback cannot roll back an email, network call, payment, or other external
side effect.

## Locked Runtime-Epoch Semantics

### Allocation rule

The runtime epoch is a positive, monotonically increasing integer scoped to one
Sandbox ID:

- the first runtime is epoch `1`;
- the Core allocates and durably commits an epoch before launch or any external
  mutation that can create that runtime;
- a failed or ambiguous launch consumes its allocated epoch;
- an epoch is never reused;
- after epoch `e + 1` exists, epoch `e` can never regain mutation authority.

Consuming failed epochs is intentional. Reusing one would make a stale handle
indistinguishable from a later launch.

### Continuity rule

An epoch represents continuity of the guest/process runtime, not continuity of
filesystem contents, provider identity, VMM process, host placement, client
connection, or control-plane record.

| Event | Identity result |
|---|---|
| Initial create and launch | Sandbox ID is new; runtime epoch is `1` |
| Snapshot capture without replacement | Current epoch is unchanged |
| Memory-preserving pause and resume with proven Process continuity | Retain epoch |
| Filesystem-only pause followed by cold boot | Allocate new epoch |
| Stop followed by start | Allocate new epoch |
| Cold restart or recovery | Allocate new epoch |
| Provider replacement that loses Process continuity | Allocate new epoch |
| Same-Sandbox rollback or restore | Allocate new epoch |
| Fork or running restore-as-create | New Sandbox ID; epoch `1` |
| Stopped restore-as-create | New Sandbox ID; no runtime epoch until Start |
| Live migration with fenced source and uninterrupted Process authority | May retain epoch |
| Any uncertain continuity | Allocate a new epoch or report `unknown`; never assume preservation |

Snapshot contents can reproduce an earlier machine state, but they do not
reanimate the authority of that earlier epoch. Restore into the same Sandbox
creates a new epoch even if memory and PIDs resemble the snapshot source.

Client attachment and stream continuity are separate observed facts. A
memory-preserving runtime may require client streams to reconnect, while a
control transport may reconnect without preserving guest Processes. A
lifecycle operation capable of changing attachment continuity must report an
outcome equivalent to `preserved` or `reconnectRequired`; that outcome is not a
resource, identity coordinate, or authority token and does not decide the
runtime epoch.

### Provider binding is not runtime identity

A provider, host, or VMM binding may change while the guest and Processes
remain continuous, as in a correctly fenced live migration or a
migration-style transfer implemented through snapshot state without a
user-visible Restore. This is distinct from `RestoreSandbox`, which always
allocates a new runtime epoch. Conversely, one provider object or machine ID
may cold boot and lose all Process continuity.

The public runtime epoch therefore cannot double as the internal provider
ownership token.

## Locked Internal Authority Fencing

The Core maintains an internal, never-reused `authorityEpoch`, monotonic within
one Sandbox ID across all of its runtimes. The name is internal and does not
add a public writable resource.

An effect-producing actor receives a capability equivalent to:

```text
{
  sandboxId
  runtimeEpoch
  authorityEpoch
}
```

The Core durably allocates the next authority epoch before a successor actor
can receive effect authority. It advances on driver, host, VMM, reconciler, or
provider-binding handoff whenever an obsolete actor could still produce or
report effects. Every product-controlled effect boundary validates the complete
capability before committing:

- guest-control commands;
- provider mutations;
- Process launch and signal;
- storage or network attachment changes;
- lifecycle completion;
- status and evidence writes that can advance authoritative state.

At most one authority epoch may commit authoritative Core state. Exclusivity
of an external effect additionally requires the target to validate a fencing
token atomically or to provide a product-verifiable drain/termination
boundary. When it provides neither, handoff cannot claim exclusive effect
authority: the Core must quarantine or reconcile the affected resources and
retain an `unknown` outcome rather than authorizing overlapping successors.
Old actors may therefore finish work physically, but their completions are
fenced from authoritative Core state and cannot be reported as a new actor's
success.

Runtime epoch and authority epoch can evolve independently:

| Scenario | Runtime epoch | Authority epoch |
|---|---:|---:|
| Client reconnect only | unchanged | unchanged |
| Control-plane ownership handoff, same continuous runtime | unchanged | advances |
| Fenced live migration preserving Processes | may remain | advances |
| Cold recovery on a new host | advances | advances |
| Same binding, cold stop/start | advances | advances |

This applies the fencing-token pattern rather than trusting clocks, leases
alone, transport disconnects, or provider instance IDs.

## Locked Stale-Handle and Process Rules

Every live mutation that acts on a runtime targets the exact expected runtime
epoch. SDK handles carry this automatically:

```text
Exec(sandboxId, expectedRuntimeEpoch, ...)
Stop(sandboxId, expectedRuntimeEpoch, ...)
Suspend(sandboxId, expectedRuntimeEpoch, ...)
Snapshot(sandboxId, expectedRuntimeEpoch, ...)
```

A mismatch returns a typed `StaleRuntime` result containing the requested
Sandbox ID and expected epoch and, where disclosure permits, the current
epoch. The Core never silently applies the call to a replacement runtime.

Name-only lookup may intentionally resolve the current Sandbox with that alias,
but a stored SDK handle pins the immutable Sandbox ID. A mutation that changes
the Sandbox representation may also require an `etag` precondition. `etag` and
runtime epoch solve different races and neither substitutes for the other.

A Process is bound permanently to one Sandbox ID and runtime epoch. Runtime
replacement makes every nonterminal Process from the old epoch terminal with a
machine-readable reason such as:

- `sandbox_runtime_replaced`;
- `runtime_lost`; or
- `fenced`.

Exact public reason spelling remains part of the error/status ADR, but the
distinctions are required. Native PIDs and provider execution IDs may be
recorded as scoped observations; they never become durable public Process
identity.

An adapter may explicitly establish a new higher-level framework Session on a
replacement runtime. The Core never treats that as continuation of an old
Process.

## Why This Model

### Stable Sandbox identity is useful

Callers need one stable object for policy, artifact provenance, bindings,
human alias, audit history, and desired lifecycle. Requiring a new Sandbox ID
for every cold restart would make reconciliation and audit correlation
needlessly indirect.

Stable identity does not imply continuous execution. The runtime epoch makes
that discontinuity explicit and safe.

### Runtime continuity is the compatibility boundary callers need

The dangerous question for `Exec`, signal, snapshot, or stop is not whether
some Sandbox with the same name still exists. It is whether the caller is
addressing the same process-bearing runtime it observed.

Filesystem state, guest memory, provider identity, host placement, transport
attachment, and Process continuity vary independently across real backends.
The epoch records the one fact required to prevent accidental retargeting.

### Internal fencing needs finer granularity

A new VMM may reconstitute the current guest memory during a fenced
migration-style handoff, and a live migration may preserve Processes while
moving control to another host. If public runtime epoch were also the ownership
token, the old and new actors could both appear current.

An internal authority epoch permits handoff without falsely claiming runtime
replacement and prevents obsolete actors from committing effects.

### Durable Operations make local and remote behavior composable

The caller should not need a different correctness strategy merely because one
driver is local and fast while another is remote and asynchronous. A durable
Operation preserves the result across RPC deadlines, daemon restarts, provider
latency, cleanup, and target deletion. Returning a terminal Operation keeps the
local path ergonomic without weakening the contract.

### `Process` deserves a specialized durable handle

Process execution has long-lived streams, signals, exit status, and cursor
semantics that a generic Operation would obscure. Making Process durable keeps
retry safe while preserving the familiar execution abstraction used by
sandbox providers and agent SDKs.

## Alternatives Rejected or Deferred

### Writable `Session` or `Incarnation`

Rejected. `Session` already means incompatible things across agent frameworks
and providers. A writable child would introduce a second lifecycle authority
and force ambiguous answers about multiple active Sessions, Sandbox deletion,
autowake, pause, restore, and which child receives an unqualified `Exec`.

`Incarnation` is precise distributed-systems terminology but unfamiliar on the
human-facing sandbox surface. Runtime epoch expresses the required fact without
another aggregate.

### Public `Deployment`

Rejected. It reads as a rollout process or orchestration object rather than one
continuous runtime, and it would collide with platform deployment concepts.

### One version or generation counter

Rejected. Representation changes, runtime replacement, ownership handoff,
operation identity, and watch progress have independent lifecycles. Combining
them causes either false invalidation or unsafe stale acceptance.

### Use `etag` for runtime continuity

Rejected. Metadata or status changes may update a representation without
replacing Processes; a cold replacement might otherwise preserve an object
version. Optimistic concurrency and runtime identity are distinct.

### Provider instance ID as public identity

Rejected. Provider objects can cold boot, restore, migrate, or be replaced with
semantics that do not match Process continuity. Native identifiers also make
portable clients backend-aware.

### Always create a new Sandbox on restore or restart

Rejected as the only model. Clone, fork, and restore-as-create do create a new
Sandbox. Same-Sandbox Restore and explicit Stop followed by Start preserve the
stable policy and audit identity while receiving the new epoch required by
their exact semantics. Public Restart and Rollback remain rejected by the
operation-taxonomy decision.

### First-class read-only `SandboxRuntime`

Deferred, not forbidden. It becomes justified when users require direct
history queries or when the product introduces semantics such as per-runtime
IAM, quota, billing, retention, or attachment to non-current runtimes. Until
then, Operations, Processes, events, and tombstones provide the history without
adding another lifecycle owner.

If the product ever admits multiple simultaneously mutable runtime branches
under one Sandbox, this decision must reopen. The current rule is one active
execution lineage per Sandbox; parallel branches are separate Sandboxes.

## Evidence and Counterexamples

### Current provider and runtime behavior

| Evidence | Maturity | Relevant fact | Product consequence |
|---|---|---|---|
| [E2B snapshots](https://e2b.dev/docs/sandbox/snapshots) | Current production-provider contract | Pause/snapshot modes preserve different subsets of filesystem, memory, running state, and connection behavior | “Resume” is insufficient to infer Process or attachment continuity |
| [Vercel persistent Sandboxes](https://vercel.com/docs/sandbox/concepts/persistent-sandboxes) and [SDK reference](https://vercel.com/docs/sandbox/sdk-reference) | Current production-provider contract | Persistent Sandbox identity and running-session behavior are distinct concepts | Do not adopt provider-specific `Session` as the portable runtime aggregate |
| [Fly suspend and resume](https://fly.io/docs/reference/suspend-resume/) | Current production-provider contract | Resume may preserve memory, while fallback can cold boot the same Machine | Provider object identity does not prove runtime continuity |
| [Firecracker snapshot support](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md) | Official implementation contract | Snapshot state can be loaded into a new VMM process | VMM identity and guest runtime continuity are separate |
| [Cloud Hypervisor live migration](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/live_migration.md) | Official implementation contract | Runtime state can move between VMMs and hosts | Binding handoff may preserve the public epoch but must advance internal authority |
| [OCI Runtime Specification](https://specs.opencontainers.org/runtime-spec/runtime/) | Normative runtime specification | OCI defines a container lifecycle around runtime state and operations | The Core can map target states without exposing native IDs as portable identity |
| [containerd Sandbox API](https://github.com/containerd/containerd/blob/main/docs/sandbox-api.md) and [CRI API](https://github.com/kubernetes/cri-api/blob/master/pkg/apis/runtime/v1/api.proto) | Official implementation contract and API specification | Container ecosystems distinguish sandbox aggregates, containers, and executions | `Sandbox` and `Process` are useful portable nouns, but native lifecycle structure is not copied wholesale |

These systems are counterexamples to any model that equates filesystem
persistence, memory persistence, provider identity, VMM identity, client
attachment, and Process continuity.

### Proven distributed-systems patterns

| Evidence | Maturity | Relevant pattern | Product consequence |
|---|---|---|---|
| [Temporal Workflow ID and Run ID](https://docs.temporal.io/workflow-execution/workflowid-runid) | Current production-system contract | Stable logical identity is separate from one execution run | Stable Sandbox ID and replaceable runtime epoch are compatible |
| [Kubernetes object names and UIDs](https://kubernetes.io/docs/concepts/overview/working-with-objects/names/) and [API concepts](https://kubernetes.io/docs/reference/using-api/api-concepts/) | Normative production API contract | Human name, immutable object identity, and representation concurrency are separate | Keep name, ID, and `etag` distinct |
| [The Chubby Lock Service](https://research.google.com/archive/chubby-osdi06.pdf) | Peer-reviewed foundational production-system paper | Sequencers/fencing tokens prevent stale lock holders from acting | Lease or disconnect alone cannot establish mutation authority |
| [Kafka KIP-98](https://cwiki.apache.org/confluence/display/KAFKA/KIP-98+-+Exactly+Once+Delivery+and+Transactional+Messaging) | Adopted production design proposal | A stable producer identity plus an advancing epoch fences obsolete producers | Advance internal authority on ownership handoff |
| [Orleans grain identity](https://learn.microsoft.com/en-us/dotnet/orleans/grains/grain-identity) | Current production-system contract | Logical identity can outlive an activation | A stable Sandbox need not imply one continuous host process |
| [Nomad allocation API](https://developer.hashicorp.com/nomad/api-docs/allocations) | Current production API contract | Scheduler resources retain durable identities around replaceable execution state | Provider allocation identity is evidence, not the portable runtime coordinate |
| [Google long-running Operations](https://github.com/googleapis/googleapis/blob/master/google/longrunning/operations.proto), [AIP-151](https://google.aip.dev/151), [AIP-154](https://google.aip.dev/154), and [AIP-155](https://google.aip.dev/155) | Normative protocol plus API-design guidance | Mutations can return durable resources; request IDs and freshness preconditions solve different problems | Keep Operation, idempotency, and `etag` semantics separate |
| [gRPC deadlines](https://grpc.io/docs/guides/deadlines/) | Current protocol guidance | A deadline bounds an RPC, not necessarily the remote work it initiated | Observation timeout never implies mutation cancellation |

The product adopts these concepts, not the source systems' complete APIs.

### Academic and novel architecture

| Evidence | Maturity | Relevant result | Product consequence |
|---|---|---|---|
| [Restoring Uniqueness in MicroVM Snapshots](https://arxiv.org/abs/2102.12892) | 2021 research preprint and implementation analysis | Snapshot cloning can duplicate entropy, tokens, identifiers, and connection state; a generation identifier is not itself a complete machine identity | Restore must create fresh runtime authority and must not treat copied guest state as current Core identity |
| [Crab: A Semantics-Aware Checkpoint/Restore Runtime for Agent Sandboxes](https://arxiv.org/abs/2604.28138) | 2026 preprint/novel system | Useful agent checkpoints include filesystem, Process, and runtime state; branching and rollback are OS-level concerns | The Core must preserve distinct runtime history, but must not infer that external side effects rolled back or auto-replay ambiguous Exec |
| [Firecracker: Lightweight Virtualization for Serverless Applications](https://www.usenix.org/conference/nsdi20/presentation/agache) | Peer-reviewed production-system architecture | A deliberately narrow VMM surface improves isolation and startup density | Reuse the VMM mechanism while keeping portable lifecycle and identity semantics product-owned |
| [Beldi](https://www.usenix.org/conference/osdi20/presentation/zhang-haoran), [Durable Functions](https://dl.acm.org/doi/10.1145/3485510), [Netherite](https://www.vldb.org/pvldb/vol15/p1591-burckhardt.pdf), and [Boki](https://dl.acm.org/doi/10.1145/3477132.3483541) | Peer-reviewed durable-execution systems | Durable orchestration relies on stable request identity, persisted progress, and explicit replay/effect models | Core mutation records must survive transport failure; external effects cannot be assumed exactly once |

The Crab paper is treated as novel evidence, not a provider guarantee. In
particular, a research system may reissue a command as part of its controlled
replay model; the portable Core cannot do so for an already accepted Exec
unless a future explicit effect model proves that replay safe.

## Consequences for API and SDK Design

- An SDK `Sandbox` handle stores immutable Sandbox ID and the observed current
  runtime epoch.
- Refreshing a handle is explicit. A stale mutation fails before retargeting.
- Name-based convenience methods resolve once and then return an ID-pinned
  handle.
- Framework adapters own whether a higher-level agent Session reconnects,
  rebinds, or creates another Sandbox.
- Wait and watch helpers can hide polling mechanics but cannot convert their
  deadline into cancellation.
- The API exposes durable Operation and Process retrieval independently of the
  original RPC.
- Events and evidence carry Sandbox ID, relevant runtime epoch, Operation or
  Process ID, and internal provenance sufficient to detect stale completions.
- Cold fallback from a memory-preserving resume is opt-in and reports a new
  epoch. It is never an invisible approximation.

## Registry Obligations Introduced

The exhaustive Packet E registry walk must partition or combine the following
candidate invalid states at the granularity of one owner and one
earliest-sound boundary, then assign stable identifiers and witnesses. These
are explicit obligations under the
[Invariant Inventory and Enforcement Protocol](../INVARIANT-ENFORCEMENT.md);
they are not yet registry entries and provide no Gate 2A coverage:

1. reuse of a Sandbox ID or runtime epoch;
2. launch before durable Operation and epoch allocation;
3. old runtime regaining authority after a newer epoch exists;
4. authoritative Core-state commit by a stale authority epoch;
5. live mutation without an expected runtime epoch;
6. stale runtime reference silently retargeted;
7. `etag`, idempotency key, runtime epoch, Operation ID, Process ID, or cursor
   substituted for another coordinate;
8. same idempotency key accepted for different canonical requests;
9. ambiguous provider or guest outcome reported as definite;
10. accepted Exec automatically replayed after ambiguity;
11. old Process left nonterminal after runtime loss or replacement;
12. native PID or provider ID reused as durable public identity;
13. cold resume represented as memory-preserving continuation;
14. restore or rollback reactivating an old epoch;
15. clone or fork sharing the source Sandbox ID;
16. cancellation request reported as cancellation fact;
17. observation deadline cancelling underlying work;
18. terminal Operation or Process result mutated;
19. cleanup outcome lost when the target is deleted;
20. framework Session semantics leaking into Core lifecycle authority;
21. successor effect authority granted without atomic target fencing or a
    verifiable predecessor drain;
22. an unfenced external handoff reported as a definite outcome instead of
    quarantined or reconciled `unknown` state;
23. a lifecycle Operation omitting or misrecording its expected, previous, or
    resulting runtime epoch;
24. attachment continuity omitted or conflated with runtime continuity;
25. an Operation missing its tagged Sandbox, Process, or Snapshot target;
26. a Process-targeted Operation retargeted to a different Process, Sandbox,
    or runtime epoch; and
27. terminal Operation `unknown` conflated with reconcilable Process
    `unknown`;
28. Snapshot ID reused or Snapshot manifest digest substituted for resource
    identity;
29. deleted or stale Snapshot handle retargeted to equal content; and
30. Fork accepted without an immutable source-runtime and preallocated-child
    target.

These are review obligations, not yet registry entries. Packet E remains open
until each declared operation and transition has been exhaustively classified
and the registry, hooks, tests, diagnostics, and conformance evidence satisfy
their respective gates.

## Remaining Packet E Decisions

The separate lifecycle-state, operation-taxonomy, and result/error decisions
now lock the portable Sandbox and Process states, execution admission, Stop
proof protocol, signal/termination distinction, sequenced Process-control
semantics, conservative concurrency, Core transition postconditions, public
method names, capability division, Snapshot kinds and source dispositions,
durable acceptance, typed outcomes, recovery, evidence refinement, and
adapter/driver ownership. Packet E still must lock:

- complete request/result fields, final per-operation error/failure/ambiguity
  subsets, and condition types;
- every operation-pair compatibility result;
- complete retained-state, Snapshot component, compatibility, and reference
  contracts;
- Operation, Process, idempotency-binding, event, and tombstone retention
  durations and post-retention retry behavior;
- cleanup, orphan adoption, and reconciliation deadlines;
- dynamic reservation and time-of-check/time-of-use protocol;
- guest-control request sequencing and acknowledgement beyond the locked
  Process-control coordinate;
- provider/guest/status/evidence decoding boundaries;
- exact wire field spelling; and
- target conformance tests proving continuity and fencing claims.

Those decisions must build on this identity model and may not silently add a
second lifecycle authority.
