# Packet E: Sandbox and Process Lifecycle State

Status: **Locked Packet E decision — operation taxonomy and
request/result/error contract locked separately; exhaustive transition
inventory and enforcement closure remain open**

Locked: 2026-07-26

Evidence reviewed: 2026-07-25 through 2026-07-26. This date applies to every
source below unless a row states otherwise.

This record locks the portable Sandbox runtime-state model, execution-admission
model, Process state model, and the relationship of all three to the durable
Operation model. It builds on
[Packet E: Durable Operations and Sandbox Runtime Identity](./PACKET-E-OPERATION-IDENTITY-DESIGN.md)
and is refined by
[Packet E: Lifecycle and Control Operation Taxonomy](./PACKET-E-OPERATION-TAXONOMY-DESIGN.md).
Its outcome proof rules and public error/recovery boundary are refined by
[Packet E: Request, Result, Error, and Recovery Contract](./PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md).
It follows the
[Research and Evidence Standard](../RESEARCH-STANDARD.md).

It does not close Packet E. Exact request/result fields and final
per-operation variant subsets beyond the separately locked contracts, the
complete operation compatibility matrix, retention durations, complete
Snapshot schemas, provider-event ingestion, cleanup policy, and executable
invariant registry remain subject to the exhaustive Packet E walk.

## Decision

The Core uses three separate state machines:

1. `Operation` records the progress and result of one accepted durable
   mutation other than Exec, with the exact sealed target type declared by its
   kind, including the source-runtime/child tuple required by Fork.
2. `Sandbox` reports conservative, currently supportable runtime facts.
3. `Process` records one accepted execution permanently bound to one Sandbox
   ID and runtime epoch.

The Core does not expose caller-writable desired state. It is an explicit
lifecycle API, not a perpetual desired-state orchestrator. A Managed-Sandbox
Service or another higher-level controller may declare desired state and call
the same Core operations, but it may not change their semantics.

The following semantic state names are locked:

```text
Sandbox runtime:
  provisioning | running | suspended | stopped | unknown

Execution admission:
  accepting | closed

Process:
  accepted | starting | running | unknown | terminated
```

The spelling and meaning of those values are stable design vocabulary. Exact
JSON nesting, casing in non-JSON protocols, generated type names, and condition
wire encoding remain protocol-design work.

There are no public verb-specific Sandbox states such as `creating`,
`starting`, `stopping`, `resuming`, `restoring`, or `deleting`. Those are
human-facing projections derived from a durable Operation and current Sandbox
status. They are not independently stored or writable facts.

## Why Three State Machines Are Necessary

A single phase cannot answer all of these independently:

- Was the request durably accepted?
- Is effect-producing work still running?
- Did the requested postcondition succeed?
- Does a runtime currently exist?
- Is that runtime executing or quiesced?
- May the Core accept a new Process?
- Did one previously accepted Process exit?
- Was deletion proven?
- Can an older authority still act?

For example, while `StopSandbox` is running:

```text
Operation.state          = running
Sandbox.runtime.state    = running or unknown
Sandbox.execution.state  = closed
Process.state            = running, unknown, or terminated per Process
```

The Stop Operation can be running while the runtime remains observably present.
It can later become `unknown` if observation or authority becomes ambiguous.
Only proof of containment absence permits `Sandbox.runtime.state = stopped`
and successful completion of the Operation.

Likewise, a Process exiting with code `1` is a known Process outcome, not a
failed lifecycle Operation or a failed Sandbox.

## Alternatives Rejected

### One flat provider-style phase enum

Rejected:

```text
creating | created | starting | ready | pausing | paused | resuming |
stopping | stopped | snapshotting | restoring | deleting | deleted | failed
```

This is superficially familiar but unsound as the portable state model:

- it duplicates the active Operation's kind and progress;
- every added lifecycle verb expands the enum and transition graph;
- it cannot express runtime presence, execution admission, cleanup, and
  operation result independently;
- `failed` does not say whether a runtime is absent, live, or ambiguous;
- provider meanings for `pause`, `stop`, `sleep`, `standby`, `resume`, and
  `snapshot` materially disagree; and
- it encourages callers to treat an acknowledged transition as a proven
  runtime fact.

SDKs and the CLI may render these labels for ergonomics, but only as a derived
view.

### Caller-writable desired and observed state

Rejected for the Core:

```text
spec.desiredRuntime = running
status.observedRuntime = stopped
```

This is appropriate for a Kubernetes-style resource controller that
continually attempts to restore a desired state. It is not appropriate for the
Core's explicit command contract. A perpetual reconciler could silently create
a replacement after a failed or ambiguous Start, thereby replaying an
external effect that the caller did not reauthorize.

The Managed-Sandbox Service may implement desired-state behavior above the
Core. Its reconciler issues distinct, durable Core Operations and owns its
restart/recreate policy explicitly.

### One state machine with no durable Operations

Rejected because a mutable Sandbox status cannot preserve:

- request identity and idempotency binding;
- cancellation races;
- immutable terminal results;
- retry classification;
- previous and resulting runtime epochs;
- cleanup outcomes after Sandbox deletion; or
- observation after the initiating RPC disconnects.

## Locked Sandbox Status Semantics

An illustrative representation is:

```text
Sandbox {
  id
  etag
  status {
    runtime {
      state
      epoch?
    }
    execution {
      state
      reason?
    }
    lifecycleOperation?
    conditions[]
  }
}
```

`lifecycleOperation` is an output-only reference to the nonterminal Operation
currently holding the Sandbox lifecycle-mutation lane. It is not desired state
and cannot be set by a caller.

### `provisioning`

`provisioning` means:

- the Core has durably allocated a new runtime epoch;
- the runtime's required success postcondition has not yet been proven; and
- execution admission is `closed`.

The epoch is consumed even if launch later fails or becomes ambiguous. The
state does not promise that the provider, VMM, container, guest control plane,
or workload has started.

The Core uses `provisioning` for initial launch, cold Start, same-Sandbox
Restore, and any other operation that creates a new runtime epoch.
Backend checkpoints such as OCI `created`, containerd task registration,
Firecracker configuration, Cloud Hypervisor VM creation, or provider request
acceptance are internal evidence; none alone establishes Core `running`.

If launch is proven not to have established a live runtime and cleanup is
complete, the Sandbox becomes `stopped`. If the outcome or remaining authority
cannot be proven, it becomes `unknown`.

### `running`

`running` means the exact current runtime epoch is observed present and
executing under the current fenced authority.

It does not mean:

- new Exec requests are accepted;
- the control channel is healthy;
- an application readiness probe passed;
- every declared service is available; or
- a lifecycle Operation is absent.

Those are separate facts. A running Sandbox may have
`execution.state = closed` during lifecycle serialization, control-path loss,
operator admission, or readiness establishment.

Create, Start, Resume, and Restore Operations that promise a usable Sandbox
do not succeed merely because `running` is observed. They also require their
declared control, conformance, and execution-admission postconditions.

### `suspended`

`suspended` means all of the following are proven:

- workload execution is quiesced;
- the same runtime epoch remains the current runtime;
- memory and Process continuity required by the capability are retained;
- no Process can execute while suspended; and
- execution admission is `closed`.

This state is capability-gated. A filesystem-retaining stop, terminated Pod,
provider standby that may cold boot, or sleep that discards processes is not
`suspended`.

If a provider promises memory resume but performs a cold fallback, the Core
must not report a successful `ResumeSandbox`. It either:

- reports the Resume outcome as failed or unknown and leaves recovery to a
  separate operation; or
- performs an explicitly authorized cold Start that consumes a new epoch.

It never silently represents the replacement as same-epoch continuation.

### `stopped`

`stopped` means:

- the logical Sandbox still exists;
- no current runtime is authoritative;
- the Core has proven that no Process-bearing runtime from the previous epoch
  can continue acting; and
- execution admission is `closed`.

A guest shutdown acknowledgement, initial child exit, VMM power-down request,
or provider stop acknowledgement is insufficient. The driver must prove its
containment-specific absence boundary.

Filesystem, archive, or other retained state is orthogonal. A later Packet E
record must lock its typed representation, but retention never changes the
meaning of `stopped`.

### `unknown`

`unknown` means the Core cannot safely establish one of:

- runtime presence or absence;
- continuity of the claimed epoch;
- exclusive effect authority;
- containment emptiness;
- or whether an external effect remains live.

It is not an alias for `failed`, `probably stopped`, or `temporarily
unreachable`. Execution admission is always `closed`.

An `unknown` Sandbox can later become `running`, `suspended`, or `stopped`
through a system-created reconciliation Operation that obtains fenced
evidence. This Operation is readable like other Operations but is not a new
caller-authored v1 lifecycle request. Adding a public Reconcile request later
reopens the public surface and transition inventory. The terminal result of
the earlier Operation remains immutable. Reconciliation may append a linked
resolution record; it never rewrites history.

### Deletion is not a runtime state

`DeleteSandbox` requires `runtime.state = stopped`. Its successful
postcondition is proven removal of the live Sandbox and all resources covered
by that Operation.

After success:

- the Sandbox leaves the live resource collection;
- normal live-Sandbox lookup returns the protocol's typed not-found result;
- an internal retained tombstone prevents ID reuse and preserves audit
  coordinates;
- the deletion Operation remains readable for its independent retention
  period; and
- Processes, output, events, and evidence follow their own retention
  contracts.

There is therefore no live `deleted` runtime state and no successful “deleted
with cleanup pending” result. If cleanup is incomplete or an orphan may still
act, deletion has not been proven.

`DeleteSandbox` never silently stops a running Sandbox. A future
`DestroySandbox` convenience operation may explicitly compose Stop and Delete,
recording both stages and their separate outcomes.

## Execution Admission

The locked values are:

```text
accepting
closed
```

`accepting` means a new Exec request may pass Sandbox lifecycle admission. It
does not bypass Artifact policy, request validation, operator policy, resource
availability, or per-Process validation.

`closed` means Core rejects a new Exec before launch with a typed reason.
Reasons include lifecycle mutation, suspended runtime, stopped runtime,
unknown runtime, control unavailable, quarantine, and operator admission.

Only `runtime.state = running` can be `accepting`. Running does not imply
accepting.

The Core durably closes execution admission before a lifecycle operation can
establish a quiescence or absence boundary. This is the serialization point
for Stop versus Exec:

```text
Exec accepted before the close -> belongs to the current epoch and Stop set
Stop closes admission first    -> later Exec receives AdmissionClosed
```

Admission closure alone is not sufficient. Every accepted Process launch also
requires a fenced launch-authority grant validated immediately before its first
external dispatch. After Stop, Suspend, or another operation requiring
quiescence or absence closes admission:

- an absence-producing operation such as Stop revokes launch authority and
  terminalizes an accepted Process whose launch has not been externally
  dispatched;
- a continuity-preserving Suspend withholds launch authority while leaving an
  undispatched Process `accepted`; only a successful same-epoch Resume may
  regrant it, subject to the Process's original deadline and any intervening
  termination request;
- an in-flight launch must be observed, drained, or fenced before Stop can
  prove containment absence, or proven quiesced as part of the retained runtime
  before Suspend can succeed; and
- no Process worker can dispatch after the quiescence or absence proof until an
  operation with current authority explicitly reopens its launch path.

There is therefore no interval in which a Process can be accepted after Stop
captures its set, or launch after Stop has proven that set unable to act.

## Durable Operation Overlay

The previously locked Operation graph remains:

```text
accepted -> running -> succeeded
                    -> failed
                    -> unknown

accepted/running -> cancel_requested -> cancelled
                                     -> succeeded
                                     -> failed
                                     -> unknown
```

The Operation's kind, target state, and progress create ergonomic derived
labels:

| Operation | Derived presentation | Authoritative facts remain |
|---|---|---|
| `CreateSandbox` | creating | Operation plus `provisioning` |
| `StartSandbox` | starting | Operation plus `provisioning` |
| `SuspendSandbox` | suspending | Operation plus `running` or `unknown` |
| `ResumeSandbox` | resuming | Operation plus `suspended`, `running`, or `unknown` |
| `StopSandbox` | stopping | Operation plus `running`, `suspended`, or `unknown` |
| same-Sandbox restore | restoring | Operation plus new-epoch `provisioning` |
| `DeleteSandbox` | deleting | Operation plus `stopped` until deletion is proven |
| snapshot capture | snapshotting | Operation plus the independently observed source state |
| migration | migrating | Operation plus independently proven runtime and authority facts |

These derived words must never be accepted as writeable status input or used
as the serialization oracle.

### Result proof obligations

- `succeeded` — the requested postcondition is proven.
- `failed` — the requested postcondition is proven not established, and no
  unfenced effect can later make it true.
- `cancelled` — cancellation won, the requested postcondition is proven not
  established, and no unfenced effect can continue.
- `unknown` — the Core cannot prove which postcondition holds or whether an
  effect remains live.

Known cleanup debt can be recorded independently, but a possibly live stale
authority requires `unknown`, not “failed with cleanup pending.”

An RPC or wait deadline is only an observation deadline. An internal execution
deadline may initiate cancellation and reconciliation, but the timer itself
cannot prove failure or cancellation.

## Lifecycle Transition Core

The following is the capability-independent semantic center. Snapshot,
restore, fork, migration, archive, and provider-triggered behavior add
capability-specific preconditions but cannot weaken these rows.

| Request | Required starting fact | Epoch rule | Required success postcondition |
|---|---|---|---|
| Create, initially running | Sandbox ID absent | allocate epoch `1` before launch effects | `running`, execution `accepting`, required control/conformance proven |
| Create, initially stopped | Sandbox ID absent | no runtime epoch allocated until first Start | durable Sandbox in `stopped` |
| Start | `stopped` | allocate next epoch before launch effects | `running`, execution `accepting`, required control/conformance proven |
| Suspend | `running`, capability present | retain epoch only with proven continuity | `suspended`, execution `closed` |
| Resume | `suspended` | retain epoch | `running`, execution `accepting`, continuity and control re-proven |
| Stop | any extant runtime state | end current epoch authority | `stopped`, all Processes terminalized, containment absence proven |
| system reconciliation | `unknown` or an ambiguous external observation | retain only if exact continuity and fencing are proven | one proven state permits Operation success; unresolved state terminates the Operation as `unknown` |
| Same-Sandbox Restore | compatible retained state and source fenced | allocate next epoch | new epoch `running` and usable; old epoch never reactivated |
| Fork or running restore-as-create | compatible retained state | new Sandbox ID at epoch `1` | new Sandbox independently usable; source disposition unchanged |
| Stopped restore-as-create | compatible retained state | new Sandbox ID; no runtime epoch until Start | durable stopped Sandbox referencing compatible retained state; source disposition unchanged |
| Live migration | `running`, exact capability | may retain only with atomic authority handoff and Process continuity | exclusive successor authority and required continuity proven |
| Delete | `stopped` | no runtime | live Sandbox absent and cleanup proof durable |

Public `RestartSandbox` is rejected by the operation-taxonomy decision.
“Restart” can mean guest reboot, Stop/Start, provider recovery, cold
replacement, or Delete/Create, with different epoch and Process consequences.
Callers use the precise operations or an SDK composite that exposes them.

Public `KillSandbox` is rejected as a portable noun. Providers use “kill” for
SIGKILL, force-stop, runtime termination, and permanent Sandbox deletion.

`Wake` is a trigger or policy, not a portable result. A provider auto-wake
that creates a new runtime must be durably sequenced before Core accepts a
Process against its new epoch.

## Stop Completion Protocol

A portable Stop driver must implement the following semantic sequence:

1. durably accept the Stop Operation;
2. close execution admission;
3. revoke new Process launch authority and snapshot every Process accepted in
   the current epoch;
4. terminalize accepted-but-undispatched Processes and drain or fence in-flight
   launch attempts;
5. request graceful termination where supported;
6. observe exits until the grace deadline;
7. force all remaining execution units;
8. prove the driver-specific containment is empty or dead and prove that no
   Process worker retains valid launch authority;
9. reap Process outcomes and drain then seal retained output;
10. terminalize every remaining nonterminal Process with an exact reason;
11. publish `stopped`; and
12. complete the Stop Operation successfully.

The grace deadline does not prove absence. Failure to prove containment yields
`unknown`, preserves evidence, and prevents overlapping successor authority.

For Linux process/container targets, exact PID identity and cgroup-wide
termination should use pidfds and cgroup v2 where available. `cgroup.kill`
followed by `cgroup.events` reporting `populated=0` is stronger evidence than
the initial child exit. Bubblewrap reports the initial application child's
status and therefore needs product-owned subtree supervision.

For VM targets, guest ACPI or control-agent acknowledgement is the graceful
request, not the completion proof. The Core must also observe guest/VMM
termination and host containment, or force the VMM and wait for its absence.

## Locked Process Model

One accepted Exec creates one durable Process:

```text
Process {
  id
  sandboxRuntimeRef {
    sandboxId
    epoch
  }
  status {
    state
    termination?
    output?
  }
}
```

The state graph is:

```text
accepted -> starting | terminated
starting -> running | unknown | terminated
running -> unknown | terminated
unknown -> running | terminated
```

### State meanings

- `accepted` — the canonical Exec request is durably bound to its Process ID
  and exact Sandbox runtime, but launch work has not begun.
- `starting` — launch intent has been durably recorded and external launch may
  be in progress.
- `running` — the exact execution is proven instantiated and nonterminal in its
  bound epoch. It need not be scheduled on a CPU at this instant. While its
  Sandbox is `suspended`, the Process remains `running` but Sandbox-level
  quiescence prevents it from executing.
- `unknown` — launch or execution outcome cannot currently be proven. This
  reconcilable observation state is not terminal and is not replay
  authorization.
- `terminated` — the Process has an immutable terminal outcome.

An `unknown` Process may resolve to `running` or `terminated` only by
reconciling the same Core launch token and, once known, the same backend
execution identity in the same epoch. A provider-assigned execution identity
may be learned after dispatch; the Core launch token, request, Process ID, and
effect intent are durable before dispatch. The Core never creates a replacement
execution for an accepted Process.

### Termination outcomes

`terminated` carries one typed outcome:

```text
exited { exitCode }
signaled { signal }
startFailed { error }
deadlineExceeded
terminatedByRequest
runtimeLost
runtimeReplaced
fenced
stoppedBySandbox
```

The exact result schema and error taxonomy remain API work, but these semantic
distinctions are locked:

- nonzero exit is still `exited`;
- `startFailed` proves the command did not become a running Process;
- `deadlineExceeded` is used only when the original Process deadline won and
  the Core proved the Process cannot later launch or continue;
- `terminatedByRequest` is used when a Process-control termination won but no
  more specific observed signal outcome applies;
- `runtimeLost` does not invent an exit code;
- `runtimeReplaced` identifies deliberate epoch replacement only after
  target-side execution fencing or containment absence proves the old Process
  cannot act;
- `fenced` identifies proven target-side execution fencing, not merely
  rejection of stale Core commits; and
- `stoppedBySandbox` may be used only when deliberate Stop causality is proven.

Internal `authorityEpoch` advancement by itself cannot terminalize a Process.
If a workload may still execute or produce external effects, the Process and
Sandbox remain `unknown`, and successor effect authority is forbidden until
target fencing or a verifiable drain boundary is established.

### Signal and termination

`SignalProcess` returns a durable Process-targeted Operation. Operation
acceptance means only that Core durably recorded the request. Operation success
requires all of:

1. Sandbox ID, Process ID, runtime epoch, and authority were validated;
2. the exact target was selected; and
3. the driver proved it invoked the target-specific signal action and that the
   backend accepted that dispatch.

It does not prove delivery, handling, obedience, or exit. Natural Process
termination may race with signal dispatch; the immutable terminal Process
outcome wins. A provider acknowledgement that only queues an unspecified future
signal is insufficient for success; the Operation remains nonterminal or
becomes `unknown` according to what can be proven.

`TerminateProcess` is a separate convergent Process-targeted Operation with
explicit graceful and force stages. It succeeds only when the Process is
terminal and cannot continue acting. Generic signal dispatch never silently
gains wait-for-exit semantics.

Portable generic signals are rejected while a Sandbox is suspended unless the
driver advertises deterministic delivery semantics. `StopSandbox` remains
legal.

## Process Stream Contract

Because Exec returns a durable Process, Core—not a provider FIFO or transient
streaming URL—owns any promise of replayable output.

The locked semantic requirements are:

- stdout and stderr have independent monotonic cursors;
- ordering is preserved within each stream;
- no cross-stream ordering is promised unless PTY mode explicitly merges them;
- output is persisted before its durable cursor advances;
- reattachment supplies a cursor and may receive duplicate chunks carrying
  stable sequence identities for deduplication;
- stdin is never replayed;
- at most one live stdin writer lease exists;
- Process termination and output sealing are independent facts;
- EOF is authoritative only after backend exit and output drain;
- retention duration, byte limit, truncation, and expiry are explicit;
- an expired cursor returns a typed output-expired result and reports the
  earliest retained cursor where partial output remains;
- output retention is independent of Sandbox deletion; and
- a same-epoch Resume may still require attachment reconnection.

CRI's synchronous Exec output cap and containerd's FIFO-based transport are
counterexamples to treating a backend stream as complete durable output.

## Concurrency Rules

The conservative default is one effectful Sandbox lifecycle Operation at a
time. The machine ledger must contain one explicit row for every operation
pair; a missing row is a specification error. A reviewed row may permit an
exact capability-gated pair. Every other complete row explicitly yields
conflict at runtime.

| Concurrent actions | Locked rule |
|---|---|
| Stop versus Exec | serialize at durable execution-admission close |
| concurrent Exec | allowed when both are independently accepted into the same current epoch |
| lifecycle mutation versus lifecycle mutation | one fenced lane; incompatible request returns conflict with active Operation ID |
| signal versus natural exit | either may occur first; terminal Process result is immutable |
| signal versus Stop | Stop owns force escalation; Core coordinates dispatch identities where the target supports it, otherwise records possible at-least-once dispatch rather than claiming backend deduplication |
| output replay versus lifecycle | retained read replay may continue; live stdin closes on suspension, stop, loss, or fencing |
| delete versus retained Process/output read | retention is independent; deletion cannot erase records early |
| reconcile versus mutation | observation may be concurrent; only current authority may commit |
| Resume versus Stop | the request that durably acquires the fenced Sandbox lifecycle lane wins; the other conflicts with its active Operation ID |

Provider event delivery is evidence, not the serialization oracle. Events may
be delayed, duplicated, reordered, rate-limited, or produced by a stale actor.

## Crash and Reconciliation Outcomes

| Failure | Immediate Core state | Required recovery rule |
|---|---|---|
| driver actor crashes while workload may continue | Sandbox `unknown`, execution `closed` | advance internal authority before adoption; retain epoch only with exact continuity and fencing |
| guest control channel fails while VM remains proven alive | runtime may remain `running`, execution `closed`, typed condition; every Process whose only fresh observer was that channel becomes `unknown` | reconnect under current authority; restore a Process to `running` only from fresh same-epoch evidence; use Sandbox `unknown` if runtime presence or continuity cannot be proven |
| VMM crashes | `unknown` until host absence is proven | then `stopped`; remaining Processes terminate as `runtimeLost` |
| guest silently reboots | `unknown` immediately | never hide reboot in the old epoch; terminate old Processes and allocate a new epoch before returning to `running` |
| Exec RPC times out | Process remains accepted, starting, running, or becomes `unknown` from durable evidence | reconcile the durable launch token and any learned backend execution identity; never relaunch |
| stale actor emits a late event | no authoritative state transition | reject commit by authority epoch; retain only as non-authoritative evidence |
| Delete cleanup is partial | Sandbox remains present; Operation failed or unknown according to proof | retain cleanup obligation/tombstone evidence; never claim successful deletion |
| snapshot restore preserves memory but loses control attachment | new epoch `provisioning` for restore | re-establish control and conformance; report attachment reconnection separately |

A reconciliation deadline is an escalation policy, not a truth-producing
timer. At expiry, unsafe retries stop, evidence remains durable, and the result
is `unknown` if no safe proof is available.

## External-Effect Protocol

No portable transaction includes both the Core database and an arbitrary OCI
daemon, VMM, guest command, or cloud provider. Each nonlocal effect therefore
uses:

1. an atomically persisted accepted Operation or Process, canonical request,
   idempotency binding, preconditions, epoch allocation, and effect intent;
2. fenced lifecycle authority;
3. a durable effect-attempt record with exact parameters, provider
   idempotency scope where available, and adoption or compensation strategy;
4. external dispatch;
5. durable returned or observed evidence; and
6. a fenced commit of the resulting Sandbox, Process, and Operation facts.

Recovery classifies the effect:

- no durable intent: dispatch cannot have begun;
- provider supports the same idempotency token: retry only with that token;
- external identity is deterministic or discoverable: inspect and adopt;
- neither: do not retry blindly; report `unknown`, quarantine, and reconcile.

Compensation is another fallible effect, not rollback. Exactly-once-style
execution is only possible when every relevant effect participates in the same
transactional substrate. The Core makes no such portable promise for shell
commands or provider APIs.

## Provider Counterexamples

Provider vocabulary is retained as decoded evidence, never mapped by name
alone.

| Provider or API | Current documented behavior | Consequence |
|---|---|---|
| E2B — production provider contract | memory-preserving pause may retain Processes, while filesystem-only pause loses Processes and cold-boots on resume; snapshot briefly interrupts connections and source continues | only continuity-proven memory pause can satisfy Core Suspend; snapshot source disposition is provider-specific |
| Modal — production Sandbox contract; directory snapshots beta, memory snapshots alpha | Created may precede compute; alpha memory snapshot can terminate source and may not retain background Exec processes | create acceptance is not readiness; snapshot is not uniformly source-retaining |
| Daytona — production lifecycle contract; snapshot/fork experimental | exposes many transient states; stopped containers retain filesystem and lose memory, while pause/resume memory retention is VM-only; deletion may be initially fire-and-forget | provider phase enums and acknowledgement cannot define Core facts |
| Fly Machines — mature production API | suspend may cold boot after snapshot loss or migration; mutation leases and version checks are explicit | provider ID does not prove runtime continuity |
| Vercel Sandbox — production v2 contract | one logical Sandbox spans new VM sessions; an eligible new SDK call can start a new VM and retry that triggering call, but old Processes do not resume; manual snapshot shuts down the source; an expired snapshot can cause name-based `getOrCreate` to delete and recreate | logical name, Sandbox identity, runtime epoch, Process identity, and snapshot source disposition are distinct |
| Cloudflare Sandbox SDK — open beta | `getSandbox(id)` returns before a container exists and first effectful use creates it lazily; idle sleep then loses files, processes, shell state, and interpreter state before a fresh container appears behind one Durable Object ID | provider handle acceptance is not Core `running`; “sleep” cannot imply Suspend |
| CodeSandbox — production SDK; lifecycle redesign ongoing | hibernate may resume clean without memory; live forks have concurrency and scalability restrictions | Resume and Fork require capability-specific continuity proofs |
| Kubernetes Agent Sandbox — emerging `v1beta1` SIG API | desired Running/Suspended is reconciled; current Suspend terminates the Pod and persistence is separate | desired state belongs above Core; Suspend cannot be inferred from its name |
| OpenAI hosted Containers — production; Sandbox Agents — beta | Containers expire and cannot reactivate; framework Sandbox Session remains client/workflow state | provider/framework Session is not a Core runtime child |
| Blaxel — official operational description | platform-controlled Standby and automatic resume can happen without a caller lifecycle request | provider-triggered transitions need durable observation and reconciliation |
| OpenSandbox — public OpenAPI specification; implementation maturity not established by the cited page | Pending/Running/Pausing/Paused/Stopping/Terminated/Failed is useful provider UX | a flat provider enum is not sufficient portable truth |

## Runtime and Kernel Counterexamples

| Source | Counterexample | Consequence |
|---|---|---|
| OCI Runtime Specification | `created` means the user process has not run | OCI `created` is not Core `running` or usable |
| containerd Task API | Exec registration and Start are separate operations | successful registration does not prove execution |
| Kubernetes CRI | removal may force a running container; synchronous Exec may truncate output | Delete cannot silently force Stop; truncation must be observable |
| bubblewrap | status follows the initial application child | initial-child exit does not prove subtree absence |
| Linux signals | signal delivery and handling are asynchronous and configurable | successful Signal does not prove Process exit |
| Linux cgroup v2 and pidfds | subtree emptiness and exact Process identity require explicit kernel evidence | Stop proof is stronger than waiting on a reused PID or one child |
| QEMU QMP | power-down acknowledgement does not prove guest shutdown; events may race commands | command acknowledgement and event arrival are evidence, not final truth |
| Firecracker | snapshot loading starts paused and connections such as vsock may not survive | runtime continuity and attachment continuity are separate |
| Cloud Hypervisor | restore prepares a non-running VM; live migration has an explicit phased handoff | Restore is not old authority; migration needs source fencing |

## Formal, Production, and Academic Rationale

### Proven patterns

- Kubernetes API conventions recommend conditions for orthogonal observations
  and warn against indefinitely growing phase enums.
- Crossplane stops reconciliation when a provider creation may have succeeded
  but its external identity was not persisted, avoiding duplicate leaked
  resources.
- Google long-running Operations treat wait and cancellation as observational
  and best-effort rather than proof of termination.
- AWS EC2 and Google AIP-155 scope idempotency to a request token and matching
  parameters.
- Temporal demonstrates why activity retry does not make an opaque external
  effect exactly once.
- Sagas establish compensation as forward recovery, not atomic rollback.

### Formal controller work

Anvil verifies level-triggered Kubernetes controllers from arbitrary
intermediate states. Its eventually stable reconciliation result supports
recovering from durable facts and observations rather than assuming complete
event history. It does not justify a Core caller-writable desired state:
Core Operations have immutable terminal results and must not silently recreate
an ambiguous external effect.

Sieve and Acto demonstrate that controller bugs concentrate in stale,
intermediate, reordered, and unobserved transitions. Kivi further shows the
need to model concurrent controller, cleanup, and reaper interactions rather
than one controller in isolation.

### Limits of certainty

FLP and failure-detector theory explain why timeout cannot distinguish a slow
or partitioned actor from a failed one without additional assumptions.
`unknown` is therefore a necessary public truth value, not an implementation
defect.

Durable execution systems such as Beldi, Boki, Durable Functions, Netherite,
and Histrio can approach exactly-once semantics when state, effects, logs,
inboxes, and outboxes share a controlled transactional substrate. They do not
prove exactly-once behavior for arbitrary VMM commands, provider APIs, or shell
commands.

### Snapshot and migration research

Restoring Uniqueness in MicroVM Snapshots shows that clones can duplicate
entropy, identifiers, secrets, clocks, and connection state. REAP, FaaSnap,
and Groundhog demonstrate major snapshot performance benefits without erasing
those identity constraints.

Crab and DeltaBox explore semantics-aware or transactional checkpointing of
filesystem, Process, and runtime state for branching agent workloads. They
support treating checkpoints as explicit durable resources and publishing
them only after complete manifests are durable. They do not roll back external
services.

Styx shows that continuity-preserving online migration requires explicit
phases, routing coordination, and ownership transfer. This reinforces the
locked rule that same-epoch live migration requires proven source fencing and
exclusive successor authority.

## Verification Consequences

The normative lifecycle model should be encoded in TLA+ before implementation
is treated as complete. Quint is worth evaluating as an ergonomic typed
frontend and trace generator, but should not initially be the only assurance
basis.

The model must include:

- API acceptor;
- lifecycle controller;
- stale controller from an older authority epoch;
- idempotent, adoptable, and opaque provider-effect classes;
- Process supervisor;
- output spool;
- snapshot store;
- cleanup/reconciliation worker;
- crashes at every persistence/effect boundary;
- lost, duplicated, delayed, and reordered messages;
- cancellation, delete, restore, fork, signal, and Stop/Exec races.

At minimum, model checking and implementation tests must prove:

1. no external effect without a durable accepted Operation or Process and
   effect intent;
2. at most one current effect-producing lifecycle authority per Sandbox;
3. runtime epochs increase monotonically and are never reused;
4. stale actors cannot mutate newer runtime or representation state;
5. terminal Operation and Process outcomes never change;
6. the same idempotency key and canonical request map to one durable handle;
7. a wait timeout changes no underlying state;
8. `cancelled` is impossible while an unfenced target effect may remain live;
9. a Process never retargets or automatically replays across ambiguity;
10. only `running` may have execution admission `accepting`;
11. execution admission and Process launch authority close before a quiescing
    operation captures accepted Processes; no late launch can follow its proof,
    and launch authority can be regranted only after the same-epoch Resume
    Operation succeeds, while the original Process deadline remains unexpired
    and no intervening TerminateProcess request exists;
12. `stopped` is impossible before containment absence and Process
    terminalization are proven;
13. `suspended` is impossible without same-epoch Process continuity;
14. Delete cannot succeed before Stop and complete cleanup proof;
15. Operation, Process, output, and evidence retention survive Sandbox deletion
    according to their independent contracts;
16. same-Sandbox restore cannot reactivate an old epoch;
17. Fork never changes source disposition;
18. unknown external effects never trigger blind retry;
19. unsupported operation interleavings fail atomically; and
20. reconciliation cannot let stale evidence oscillate current authority.

Liveness claims require explicit fairness and provider-observability
assumptions. No timer can force a permanently opaque provider outcome to
become known.

Close the model-to-code gap with:

- generated lifecycle traces replayed against the implementation;
- Sieve-style deterministic crashes at every database/effect boundary;
- Acto-style generated lifecycle sequences;
- backend conformance tests for idempotency, observation, adoption,
  cancellation, fencing, containment, signal, and snapshot completeness; and
- fault tests exercising real ambiguous effects rather than mocks alone.

## Registry Obligations Introduced

The exhaustive Packet E walk must partition or combine the following candidate
invalid states by owner and earliest-sound boundary, assign stable registry
identifiers, and add positive and negative witnesses. These are obligations,
not registry entries and not Gate 2A coverage:

1. caller-writable Sandbox desired runtime state reaching Core;
2. provider or adapter phase treated as authoritative Core runtime state;
3. verb-specific presentation state stored independently of its Operation;
4. `running` treated as execution or application readiness;
5. execution `accepting` while runtime state is not `running`;
6. new Exec accepted after lifecycle admission closure;
7. lifecycle operation capturing its Process set before admission and launch
   authority close;
8. accepted or starting Process dispatching after a quiescing or
   absence-proving operation revokes launch authority or publishes its proof;
9. continuity-preserving Suspend terminalizing an accepted-but-undispatched
   Process instead of withholding its launch authority;
10. Resume regranting withheld Process launch authority before the same-epoch
    Resume Operation succeeds, after the original Process deadline expires, or
    after an intervening TerminateProcess request;
11. `suspended` reported without quiescence and same-epoch Process continuity;
12. cold fallback reported as same-epoch Resume success;
13. `stopped` reported before containment absence is proven;
14. guest shutdown, provider acknowledgement, or initial-child exit treated as
    Stop proof;
15. Delete accepted against a non-stopped Sandbox without an explicit
    composite operation;
16. successful Delete with incomplete cleanup or possibly live orphan;
17. Sandbox deletion erasing retained Operation, Process, output, event, or
    evidence records early;
18. unknown Sandbox state approximated as stopped or running;
19. reconciliation rewriting an immutable terminal Operation;
20. incompatible concurrent lifecycle mutations both receiving authority;
21. absent compatibility entry interpreted as concurrency permission;
22. Operation accepted without the exact sealed target required by its kind;
23. Process-targeted Operation retargeted across Process, Sandbox, or runtime
    epoch;
24. Process created without exact Sandbox ID and runtime epoch;
25. ambiguous Process automatically relaunched;
26. terminal Operation `unknown` conflated with reconcilable Process
    `unknown`;
27. Process `unknown` resolved using a different backend execution identity or
    runtime epoch;
28. nonzero exit represented as infrastructure failure;
29. Process terminal outcome mutated;
30. internal authority fencing alone used to terminalize a Process that may
    still execute;
31. stale Process `running` observation retained after its only observer is
    lost;
32. Signal Operation reported successful before exact target-specific dispatch
    is proven;
33. successful signal dispatch represented as delivery, handling, or exit;
34. generic Signal accepted while suspended without deterministic capability;
35. duplicate signal or termination dispatch assumed idempotent without target
    support or Core coordination;
36. Process termination reported before it can no longer act;
37. output cursor advanced before durable output persistence;
38. cross-stream ordering promised without an explicitly merged PTY stream;
39. stdin replay or multiple simultaneous stdin writer leases;
40. Process termination conflated with output sealing;
41. output truncation or expiry hidden from the caller;
42. stale provider event treated as serialization authority;
43. effect retry without provider idempotency or adoption proof;
44. compensation represented as rollback;
45. provider auto-wake creating a replacement epoch before Core durably
    sequences identity and admission;
46. restore, fork, or migration violating their locked Sandbox-ID, epoch,
    source-disposition, or fencing semantics; and
47. timer expiry converted into definite failure, cancellation, Stop, or
    deletion proof.

## Remaining Packet E Work

This decision does not yet lock:

- full request/result fields and final per-operation
  error/failure/ambiguity subsets beyond the semantic architecture locked in
  the operation-taxonomy and result/error decisions;
- exact condition types and freshness representation;
- complete retained-state and Snapshot component, compatibility, reference,
  and quiescence schemas;
- the complete operation-pair compatibility table;
- provider-triggered lifecycle event records and interception requirements;
- Operation, Process, output, event, evidence, idempotency, and tombstone
  retention durations;
- cleanup, orphan-adoption, and reconciliation policies and deadlines;
- dynamic reservation and time-of-check/time-of-use protocol;
- guest-control sequencing and acknowledgement beyond the locked
  Process-control coordinate;
- provider/guest/event/evidence decoding boundaries;
- target conformance probes for every continuity and absence claim; and
- exhaustive machine-readable transition cases, registry entries, hooks,
  tests, and diagnostics.

## References

### Normative specifications and protocol contracts

- [OCI Runtime Specification lifecycle](https://github.com/opencontainers/runtime-spec/blob/main/runtime.md)
- [Kubernetes CRI API](https://github.com/kubernetes/cri-api/blob/master/pkg/apis/runtime/v1/api.proto)
- [Linux cgroup v2](https://docs.kernel.org/admin-guide/cgroup-v2.html)
- [Linux PID namespaces](https://man7.org/linux/man-pages/man7/pid_namespaces.7.html)
- [Linux pidfd signal dispatch](https://man7.org/linux/man-pages/man2/pidfd_send_signal.2.html)
- [Linux waitid](https://man7.org/linux/man-pages/man2/waitid.2.html)
- [Linux signal semantics](https://man7.org/linux/man-pages/man7/signal.7.html)
- [QEMU QMP protocol](https://www.qemu.org/docs/master/interop/qmp-spec.html)
- [QEMU QMP reference](https://www.qemu.org/docs/master/interop/qemu-qmp-ref.html)
- [Google long-running Operations](https://github.com/googleapis/googleapis/blob/master/google/longrunning/operations.proto)
- [Google AIP-155 request identification](https://google.aip.dev/155)
- [AWS EC2 idempotency](https://docs.aws.amazon.com/ec2/latest/devguide/ec2-api-idempotency.html)

### Official implementation contracts and kernel-facing manuals

- [containerd Task API](https://github.com/containerd/containerd/blob/main/api/services/tasks/v1/tasks.proto)
- [containerd task types](https://github.com/containerd/containerd/blob/main/api/types/task/task.proto)
- [containerd Runtime v2 I/O](https://github.com/containerd/containerd/blob/main/docs/runtime-v2.md)
- [bubblewrap manual](https://github.com/containers/bubblewrap/blob/main/bwrap.xml)
- [Firecracker actions](https://github.com/firecracker-microvm/firecracker/blob/main/docs/api_requests/actions.md)
- [Firecracker snapshot support](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md)
- [Cloud Hypervisor API](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/api.md)
- [Cloud Hypervisor snapshot and restore](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/snapshot_restore.md)
- [Cloud Hypervisor live migration](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/live_migration.md)

### Production provider and framework contracts

- [E2B lifecycle](https://e2b.dev/docs/sandbox)
- [E2B persistence](https://e2b.dev/docs/sandbox/persistence)
- [E2B snapshots](https://e2b.dev/docs/sandbox/snapshots)
- [E2B lifecycle events](https://e2b.dev/docs/sandbox/lifecycle-events-api)
- [Modal Sandbox lifecycle](https://modal.com/docs/guide/sandboxes)
- [Modal Sandbox snapshots](https://modal.com/docs/guide/sandbox-snapshots)
- [Daytona Sandbox states](https://www.daytona.io/docs/en/sandboxes/)
- [Daytona SDK lifecycle](https://www.daytona.io/docs/en/typescript-sdk/sandbox/)
- [Daytona operation-conflict changes](https://www.daytona.io/changelog/sandbox-operations)
- [Fly Machine states](https://fly.io/docs/machines/machine-states/)
- [Fly suspend and resume](https://fly.io/docs/reference/suspend-resume/)
- [Fly Machines API leases and versions](https://fly.io/docs/machines/api/machines-resource/)
- [Vercel persistent Sandboxes](https://vercel.com/docs/sandbox/concepts/persistent-sandboxes)
- [Vercel snapshots](https://vercel.com/docs/sandbox/concepts/snapshots)
- [Vercel Sandbox SDK](https://vercel.com/docs/sandbox/sdk-reference)
- [OpenAI Code Interpreter containers](https://developers.openai.com/api/docs/guides/tools-code-interpreter)
- [OpenAI Container API](https://developers.openai.com/api/reference/ruby/resources/containers)

### Beta, experimental, emerging, or maturity-unestablished provider evidence

- [Cloudflare Sandbox lifecycle](https://developers.cloudflare.com/sandbox/api/lifecycle/)
- [Cloudflare Sandbox state loss](https://developers.cloudflare.com/sandbox/concepts/sandboxes/)
- [Cloudflare Sandbox beta status](https://developers.cloudflare.com/sandbox/platform/beta-info/)
- [CodeSandbox create and fork](https://codesandbox.io/docs/sdk/create)
- [CodeSandbox resume](https://codesandbox.io/docs/sdk/resume)
- [CodeSandbox restart and shutdown](https://codesandbox.io/docs/sdk/restart-shutdown)
- [CodeSandbox SDK v2.3.0 lifecycle findings](https://github.com/codesandbox/codesandbox-sdk/releases/tag/v2.3.0)
- [Kubernetes Agent Sandbox API](https://agent-sandbox.sigs.k8s.io/docs/api)
- [Kubernetes Agent Sandbox v0.4.6 condition source](https://github.com/kubernetes-sigs/agent-sandbox/blob/v0.4.6/api/v1beta1/sandbox_types.go)
- [Kubernetes Agent Sandbox v0.4.6 release](https://github.com/kubernetes-sigs/agent-sandbox/releases/tag/v0.4.6)
- [Kubernetes Agent Sandbox overview](https://agent-sandbox.sigs.k8s.io/docs/getting_started/overview/)
- [OpenAI Sandbox Agents](https://developers.openai.com/api/docs/guides/agents/sandboxes)
- [OpenAI Agents SDK Sandbox concepts](https://openai.github.io/openai-agents-js/guides/sandbox-agents/concepts/)
- [Blaxel Sandbox lifecycle](https://blaxel.ai/blog/understand-the-lifecycle-of-a-blaxel-sandbox)
- [OpenSandbox API](https://open-sandbox.ai/api/)

### Production patterns and formal methods

- [Kubernetes API conventions](https://github.com/kubernetes/community/blob/master/contributors/devel/sig-architecture/api-conventions.md)
- [Kubernetes node unknown-state behavior](https://kubernetes.io/docs/concepts/architecture/nodes/)
- [Crossplane managed-resource leak protection](https://docs.crossplane.io/latest/managed-resources/managed-resources/)
- [Temporal Activity execution and retry](https://docs.temporal.io/activity-execution)
- [Sagas](https://dl.acm.org/doi/10.1145/38713.38742)
- [Anvil: Verifying Liveness of Cluster Management Controllers](https://www.usenix.org/conference/osdi24/presentation/sun-xudong)
- [Anvil implementation summary](https://www.usenix.org/publications/loginonline/anvil-building-formally-verified-kubernetes-controllers)
- [Sieve](https://www.usenix.org/publications/loginonline/sieve-chaos-testing-kubernetes-controllers)
- [Acto](https://dl.acm.org/doi/10.1145/3600006.3613161)
- [Kivi](https://www.usenix.org/conference/atc24/presentation/liu-bingzhe)
- [FLP impossibility](https://dl.acm.org/doi/10.1145/3149.214121)
- [Chandra-Toueg failure detectors](https://dl.acm.org/doi/10.1145/226643.226647)
- [Beldi](https://www.usenix.org/conference/osdi20/presentation/zhang-haoran)
- [Boki](https://dl.acm.org/doi/10.1145/3477132.3483541)
- [Durable Functions semantics](https://dl.acm.org/doi/10.1145/3485510)
- [Netherite](https://dl.acm.org/doi/10.1007/s00778-024-00898-1)
- [Histrio](https://dl.acm.org/doi/10.1145/3701717.3730541)
- [Apalache](https://dl.acm.org/doi/10.1145/3360549)
- [AWS use of formal methods](https://cacm.acm.org/research/how-amazon-web-services-uses-formal-methods/)
- [Quint](https://github.com/informalsystems/quint/blob/main/quint/README.md)

### Snapshot, restore, and migration research

- [Restoring Uniqueness in MicroVM Snapshots](https://arxiv.org/abs/2102.12892)
- [REAP](https://dl.acm.org/doi/10.1145/3445814.3446714)
- [FaaSnap](https://dl.acm.org/doi/10.1145/3492321.3524270)
- [Groundhog](https://dl.acm.org/doi/10.1145/3552326.3567503)
- [Crab](https://arxiv.org/abs/2604.28138)
- [DeltaBox](https://arxiv.org/abs/2605.22781)
- [Styx state migration](https://link.springer.com/article/10.1007/s00778-026-00971-x)
- [CRIU command reference](https://github.com/checkpoint-restore/criu/blob/criu-dev/Documentation/criu.txt)
