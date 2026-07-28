# Packet E: Request, Result, Error, and Recovery Contract

Status: **Locked Packet E decision — exhaustive operation-contract and
transition ledgers remain open**

Locked: 2026-07-27

Evidence reviewed: 2026-07-27. Source maturity is recorded below.

This record locks:

- the boundary between a request rejected before acceptance and a call
  accepted under its class-specific durable result;
- the distinct recovery error returned when a historical coordinate is older
  than its guaranteed recovery state;
- the authoritative Operation and Process result domains;
- the separation between semantic outcomes and transport failures;
- the closed public error and recovery architecture;
- the internal evidence-refinement rule that permits `succeeded`, `failed`,
  `cancelled`, or `unknown`;
- the call classes required by the complete Packet E surface;
- ordered Process-control command acceptance;
- the division between public Core semantics, transport projections, and
  protected provider evidence; and
- the machine-ledger obligations needed to make the decision exhaustive.

It builds on:

- [Packet E: Durable Operations and Sandbox Runtime Identity](./PACKET-E-OPERATION-IDENTITY-DESIGN.md);
- [Packet E: Sandbox and Process Lifecycle State](./PACKET-E-LIFECYCLE-STATE-DESIGN.md);
- [Packet E: Lifecycle and Control Operation Taxonomy](./PACKET-E-OPERATION-TAXONOMY-DESIGN.md);
- [Packet A: Public Resources and Operations](./PACKET-A-RESOURCE-OPERATION-REVIEW.md); and
- the [Research and Evidence Standard](../RESEARCH-STANDARD.md).

This record does not close Packet E. Every method still requires an exhaustive
machine-readable operation contract and every dynamic transition,
concurrency pair, crash point, cleanup disposition, and evidence obligation
must still be enumerated.

## Decision

Packet E uses a closed hybrid outcome architecture:

1. a shared, sealed semantic registry owns every public error, known failure,
   ambiguity, detail payload, disclosure rule, and recovery action;
2. each method admits an explicit generated subset of those variants and has
   its own success type;
3. an internal evidence-refinement model determines which Operation or
   Process state may be asserted; and
4. HTTP and gRPC status are generated projections, never the semantic
   discriminator.

The public boundary is:

```text
request
  |
  +-- Core proves that no acceptance or effect occurred
  |     -> typed RequestError
  |
  +-- recovery coordinate is older than its guaranteed recovery state
  |     -> typed RecoveryError; no new effect is dispatched
  |
  +-- a read-only observation succeeds
  |     -> synchronous observation result; no acceptance commit
  |
  +-- Core durably accepts the request
  |     -> durable Operation
  |     -> durable Process for Exec
  |     -> committed Core-record result
  |     -> durable Process-control receipt
  |
  `-- caller loses transport before learning which branch occurred
        -> local TransportError; recover by the call class
```

Durable Operation, Process, and atomic-record calls recover with the identical
canonical request and idempotency key. Process-control calls recover with the
same writer lease, sequence, and canonical command. Observations repeat from
their last durable cursor or current resource identity.

There is no nullable handle, generic provider error, `retryable` boolean,
open string reason, or catch-all public detail object.

## Naming and Authority

The following semantic names are locked:

| Name | Meaning |
|---|---|
| `RequestError` | a Core-authored proof that the invocation was not accepted and no effect-producing work was dispatched |
| `RecoveryError` | a Core-authored result that no new effect was dispatched but the submitted recovery coordinate is outside its guaranteed recoverable state and therefore cannot safely be treated as a new invocation |
| `OperationOutcome` | the immutable terminal outcome of one accepted durable mutation |
| `ProcessTermination` | the immutable terminal outcome of one accepted Exec |
| `ProcessControlOutcome` | the retained delivery outcome of one accepted sequenced Process-control command |
| `CallerRecovery` | a closed instruction describing what a caller may safely do next |
| `CoreResolution` | a private closed instruction describing what Core may do with the same native effect or with linked cleanup/reconciliation work |
| `TransportError` | an SDK- or transport-local failure that does not itself establish whether Core accepted the invocation |
| `ProviderEvidence` | protected native observations that may justify a Core classification but never become its public meaning |

Exact language-specific casing and protocol field spelling remain generated
surface concerns. These semantic distinctions may not be renamed into a
single generic `Error`, `Failure`, `Status`, `Result`, or provider-native code.

`Rejected`, `RecoveryUnavailable`, and `Accepted` are useful formal branches,
not mandatory wrapper objects in every SDK. An idiomatic SDK may expose:

```text
Result<
  Operation<StartSandboxResult>,
  RequestErrorFor<StartSandbox> | RecoveryErrorFor<StartSandbox>
>
```

instead of:

```text
InvocationOutcome<StartSandbox> =
    Rejected<RequestErrorFor<StartSandbox>>
  | RecoveryUnavailable<RecoveryErrorFor<StartSandbox>>
  | Accepted<Operation<StartSandboxResult>>
```

The two forms must retain identical semantics. In this example,
`AcceptedResultFor<StartSandbox>` is
`Operation<ResultFor<StartSandbox>>`; `ResultFor<StartSandbox>` alone is the
terminal success payload embedded in that Operation. `RecoveryErrorFor<K>`
may be the empty type only for a method whose contract has no historical
recovery coordinate. A transport-local `TransportError` remains outside this
Core union because it cannot establish which Core branch occurred.

## Alternatives Rejected

### Canonical code plus open details as the semantic source

Canonical HTTP and gRPC codes are interoperable, but they collapse materially
different conditions. `RESOURCE_EXHAUSTED` may mean a hard account quota,
short-term rate limiting, host disk exhaustion, or temporary global capacity.
`ABORTED`, `FAILED_PRECONDITION`, and HTTP 409 are similarly overloaded.

Open `Any`, arbitrary metadata, or string reason fields also permit
contradictions such as:

- a stale runtime error advising replay against the stale epoch;
- permission denial containing resource-existence details;
- quota exhaustion carrying provider-capacity fields;
- a cancellation transport code claiming a remote effect was cancelled; or
- a deadline status claiming that an accepted mutation did not happen.

Canonical codes are therefore derived transport projections only.

### One universal public failure union

A single global sealed union provides exhaustiveness but admits nonsensical
method/reason combinations. For example, `WriteProcessInput` cannot fail with
Snapshot compatibility and `GetSandbox` cannot terminalize as a cleanup
failure.

The shared registry remains global, but every method exposes only its exact
admissible subset.

### Handwritten per-method unions

Handwritten unions provide a precise public shape but duplicate reason,
detail, disclosure, recovery, and transport definitions. Duplicated
definitions will drift.

Per-method unions are generated from one registry and one operation ledger.

### Public effect/evidence lattice

An evidence lattice is required internally to distinguish definite failure
from ambiguous external effect. It is not suitable as the ordinary SDK
surface. The public API exposes concise terminal outcomes and closed
missing-proof variants derived from that model.

## Complete Call Classification

Every Core method belongs to one and only one call class. The classification
is semantic, not a transport implementation choice.

### Durable Operation mutation

These calls durably accept one mutation and return its `Operation`:

- `CreateSandbox`;
- `StartSandbox`;
- `StopSandbox`;
- `DeleteSandbox`;
- `TerminateProcess`;
- capability-gated `SignalProcess`;
- capability-gated `SuspendSandbox` and `ResumeSandbox`;
- capability-gated `ResizeSandboxResources`;
- `CreateSnapshot`;
- `DeleteSnapshot`;
- `RestoreSandbox`;
- `ForkSandbox`; and
- any closed system-originated reconciliation, adoption, fencing,
  quarantine, cleanup, or expiry operation represented on the public wire.

A local or provider implementation that completes immediately still returns
an already-terminal Operation. It does not use another synchronous contract.

### Durable Process mutation

`Exec` returns one durable `Process`. The Process is the idempotency,
observation, control, termination, and stream handle for that accepted
execution.

### Observation

Observations create no mutation handle:

- `GetSandbox`, `ListSandboxes`, `WaitSandbox`;
- `GetOperation`, `ListOperations`, `WaitOperation`;
- `GetProcess`, `ListProcesses`, `WaitProcess`;
- `GetSnapshot`, `ListSnapshots`, `WaitSnapshot` if later admitted;
- `ReadProcessOutput`; and
- immutable capability and manifest observations returned with their owning
  resources.

Observation timeout ends only that observation. It does not cancel or
terminalize the observed resource.

### Atomic Core-record update

`UpdateSandboxMetadata` and `SetSandboxExpiration` update Core-owned
representations rather than an external runtime. They may return a
synchronous result only when the requested postcondition and idempotency
binding commit atomically.

They require the same lost-response discipline as durable mutations. A retry
with the same canonical request and idempotency key recovers the committed
response; it must not apply the update again.

### Existing-handle intent

`CancelOperation` records `cancel_requested` on the existing Operation and
returns an observation of that Operation. It does not allocate an
Operation-of-Operation.

Repeated cancellation requests are monotonic and idempotent. The original
Operation remains the only outcome authority and may finish as `succeeded`,
`failed`, `cancelled`, or `unknown`.

### Sequenced Process control

The following are commands within the exact Process control coordinate:

- `WriteProcessInput`;
- `CloseProcessInput`; and
- `ResizeProcessTerminal`.

They do not create one Operation per interactive command. They use an ordered,
durably deduplicated Process-control stream described below.

File, directory, copy, transfer, endpoint, and port operations remain
Packet A-owned families. Each must receive one of these call classes or a
separately reviewed class before the complete Core API closes.

## Durable Acceptance

### Acceptance proof

An effectful or atomic call may return `RequestError` only when Core proves all
of:

1. no Operation, Process, atomic-update commit/result record, or
   Process-control receipt committed;
2. no effect intent capable of dispatch exists;
3. no provider, runtime, guest, kernel, or external effect was invoked; and
4. no accepted result exists that the caller must observe or recover.

Otherwise the request is accepted and every later outcome belongs to its
class-specific durable handle, committed result, or retained receipt.

### Common acceptance invariant

Acceptance is a semantic commit point, not one universal storage record. Every
non-observation call atomically commits its class-specific accepted result
with:

- method and origin;
- canonical request and digest;
- exact target and every freshness precondition applicable to that class;
- accepted time;
- admission and precondition witnesses;
- the class-specific recovery coordinate; and
- every fact that later dispatch, deduplication, result recovery, or evidence
  interpretation is allowed to use.

Nothing required to establish those facts may first be inferred after an
external effect. The accepted result and its recovery binding are one atomic
commit. Observations have no acceptance commit because they create no durable
result or effect.

### Class-specific acceptance commits

Durable Operation mutations and `Exec` commit a new-effect intent before
dispatch:

```text
NewEffectIntent {
  commonAcceptance
  handle = OperationId | ProcessId
  initialState
  exactEffectTarget
  expectedRuntimeEpoch?
  idempotencyCoordinate
  effectIntent
  effectAuthorityEpoch
}
```

The exact target is the locked tagged Operation target or exact
Sandbox-runtime reference for `Exec`. Create and fork include their
preallocated Sandbox identity. A runtime-creating mutation includes its
already-consumed new runtime epoch.

An atomic Core-record update instead commits the representation change,
idempotency binding, and recoverable response together:

```text
AtomicRecordCommit {
  commonAcceptance
  idempotencyCoordinate
  priorRevision
  resultingRevision
  committedRepresentation
  committedResponse
}
```

It has no effect intent, dispatch identity, mutation authority epoch, or new
handle.

`CancelOperation` commits intent on the existing Operation:

```text
ExistingOperationIntentCommit {
  commonAcceptance
  operationId
  cancellationRequestDigest
  cancellationRequestedAt
  resultingOperationRevision
}
```

The commit monotonically records `cancel_requested`; it creates no
Operation-of-Operation. Cancellation dispatch and recovery remain work of the
existing Operation.

A sequenced Process-control command commits the receipt and ordered command
under its writer lease and sequence:

```text
ProcessControlReceiptCommit {
  commonAcceptance
  processRuntime
  writerLeaseId
  sequence
  canonicalCommand
  receipt
}
```

It has no idempotency key or new Operation/Process handle. The lease,
sequence, and command digest are its recovery coordinate.

These are a closed tagged union in the machine contract. Fields belonging to
one commit kind are not nullable fields on another.

### Class-specific crash boundaries

| Call class | Before class commit | After class commit but before further work | After work but before response |
|---|---|---|---|
| durable Operation / `Exec` | no handle; a known Core response may be `RequestError` | accepted handle; resume or reconcile only the committed effect intent | retry recovers the same handle; evidence alone determines its later outcome |
| atomic Core-record update | no representation change or accepted result; a known response may be `RequestError` | representation, dedupe binding, and response are already committed; there is no dispatch | retry returns the same committed response |
| `CancelOperation` | existing Operation unchanged by this request; a known response may be `RequestError` | existing Operation durably records `cancel_requested`; cancellation dispatch resumes from that Operation | retry or observation returns the same Operation; its outcome is never inferred from response loss |
| sequenced Process control | no receipt or command; a known response may be `RequestError` | receipt and ordered command are durable; delivery resumes under the same coordinate | retry returns the same receipt and never enqueues a duplicate |

For a new-effect intent, a crash after dispatch but before learning the native
identity requires reconciliation with the same launch token or terminal
`unknown`; a crash after native success requires exact evidence before
success is committed. For every class, an internal crash is not authority to
retroactively return a request rejection for a committed acceptance.

## Ordered Admission and Error Precedence

Every operation contract declares its exact checks and any method-specific
refinement, but the global order is:

1. transport framing, size, route, and API-version recognition;
2. authentication;
3. authorization at a disclosure-safe operation and parent scope;
4. semantic decoding and canonicalization;
5. idempotency lookup;
6. target existence and reference resolution;
7. runtime-epoch and representation-revision freshness;
8. Artifact, profile, capability, and sealed-policy compatibility;
9. lifecycle state, execution admission, operation-pair concurrency, and
   dependency/retention checks;
10. quota, rate, capacity, and service admission; and
11. the atomic class-specific acceptance commit.

The first applicable declared error wins. No driver or provider chooses the
public error by returning first.

### Authorization before validation

The transport layer may perform only the parsing required to route and
authenticate the call before authorization. Detailed semantic validation and
existence disclosure occur only after the caller is authorized at the
appropriate non-leaking scope.

Unauthorized requests against an existing resource and an absent resource
must have observationally equivalent public responses. Protected internal
audit evidence may retain the exact decision.

### Idempotent replay before mutable preconditions

After authorization and canonicalization, idempotency lookup precedes mutable
state and capacity checks:

```text
same coordinate + same canonical digest
  -> reauthorize handle visibility and return original handle/result

same coordinate + different canonical digest
  -> IdempotencyConflict

retired or stale coordinate
  -> RecoveryError.IdempotencyRecordExpired

new coordinate
  -> continue ordinary admission
```

This ordering is required. A retry of an accepted Start may arrive after the
Sandbox is already running; it must recover the original Operation instead of
being rejected as an invalid new Start.

## Idempotency Scope and Retention

The idempotency coordinate contains:

```text
IdempotencyCoordinate {
  authenticatedScope
  method
  key
}
```

Canonicalization excludes transport-only fields, trace identifiers, and
presentation metadata. It includes every field that can change target,
authority, effect, policy, result, or postcondition.

Rules:

- the same key is never rebound within its coordinate;
- equal replay recovers the original handle or committed synchronous result;
- conflicting replay dispatches no effect;
- an accepted terminal failure is still recovered rather than retried as a
  new mutation;
- operation/result retention and deduplication retention are distinct;
- the service publishes its deduplication window and stale-key rule;
- acceptance tombstones and the key-age rule cover the entire published
  recovery window;
- expiry returns `RecoveryError` and never claims that the historical effect
  did not occur;
- expiry never silently converts an old retry into a new mutation; and
- creating a genuinely new attempt requires a new key and operation-specific
  authority to do so.

The exact key format, stale-request boundary, retention durations, and
tombstone representation remain ledger work. They are Managed-Sandbox
Service or Core deployment policy, not Artifact Definition fields.

## Closed Public Error Architecture

### Tagged variants, not correlated fields

The semantic source is a tagged variant with its sole legal payload:

```text
RequestError =
    MalformedRequest { violations }
  | InvalidArgument { violations }
  | Unauthenticated
  | PermissionDenied
  | TargetNotFound { targetKind, safeTargetRef? }
  | OutputCursorExpired { earliestCursor, sealedAt? }
  | NameConflict { safeName? }
  | IdempotencyConflict { originalDigest, submittedDigest }
  | StaleRevision { expected, current }
  | StaleRuntime { sandboxId, expectedEpoch, currentEpoch? }
  | InvalidState { required, observed }
  | AdmissionClosed { reason }
  | ConcurrentOperation { conflictingOperationId, relation }
  | DependencyNotFound { safeDependencyRef? }
  | DependencyUnavailable { safeDependencyRef? }
  | ReferenceProtected { references }
  | RetentionHold { holds }
  | MethodUnavailable { method }
  | CapabilityUnsupported { capabilityId, profileId? }
  | ArtifactIncompatible { compatibility }
  | PolicyMismatch { policyCoordinate }
  | RateLimited { retryAfter? }
  | QuotaExceeded { subject, metric, resetAt? }
  | CapacityUnavailable { placement?, retryAfter? }
  | ServiceUnavailable { retryAfter? }
  | ProcessControlConflict { sequence, originalDigest, submittedDigest }
  | SequenceOutOfRange { expected, submitted }
  | StaleWriterLease { writerLeaseId }
  | ProcessInputLimitExceeded { limit, current }
  | InternalInvariantViolation { evidenceId }
  | EvidenceCorrupt { evidenceId }
```

This is the minimum required family, not permission for runtime extension.
The exhaustive operation ledger must split, refine, or prove inapplicable
every candidate while preserving the distinctions below.

There is no public `Other`, `UnknownProviderError`, arbitrary string reason,
or generic detail map. A future variant changes the closed registry, expected
counts, generated SDK unions, mappings, fixtures, and model constants.

### Expired recovery coordinates

Expired recovery state is not `RequestError`, because the historical
coordinate may already have produced an effect:

```text
IdempotentAcceptedResultReference =
    OperationResult { operationId }
  | ProcessResult { processId }
  | CoreRecordResult {
      resource
      resultingRevision
      committedResponseDigest
    }

ProcessControlAcceptedResultReference = {
  processId
  writerLeaseId
  sequence
}

PriorAcceptanceEvidence<R> =
    Unknown
  | ProvenWithoutRetainedResult
  | ProvenWithRetainedResult {
      acceptedResult: R
    }

RecoveryError =
    IdempotencyRecordExpired {
      key
      recoveryWindowEndedAt
      priorAcceptance:
        PriorAcceptanceEvidence<IdempotentAcceptedResultReference>
    }
  | ProcessControlRecordExpired {
      writerLeaseId
      sequence
      recoveryWindowEndedAt
      priorAcceptance:
        PriorAcceptanceEvidence<ProcessControlAcceptedResultReference>
    }
```

`RecoveryError` proves only that this replay dispatched no new effect. It does
not prove that the historical invocation was unaccepted. Its caller recovery
is `ObserveHandle` when the retained accepted result is an Operation or
Process and otherwise `OperatorAction`; it never authorizes resubmission with
a new key or sequence. A retained Core-record or Process-control reference
may support class-specific inspection, but does not make replay safe.

The tagged evidence union makes it impossible to claim both unknown prior
acceptance and a retained accepted result. It also avoids treating every
accepted result as a handle.

The final retention design must ensure that the published recovery guarantee
and acceptance tombstones overlap without a gap. A request coordinate older
than that published guarantee is rejected as recovery-unavailable even when
its original acceptance record has been compacted.

### Required distinctions

The final registry must not collapse:

- malformed structure versus semantically invalid content;
- unauthenticated versus unauthorized;
- unauthorized existence versus authorized absence;
- name conflict versus idempotency conflict;
- stale representation revision versus stale runtime epoch;
- stale observation cursor versus absent target;
- invalid lifecycle state versus incompatible concurrent operation;
- execution admission closed versus service unavailable;
- unavailable method, target/profile capability incompatibility, and
  dynamically unavailable capacity;
- Artifact incompatibility versus immutable policy mismatch;
- account quota versus short-term rate limit versus global capacity;
- missing dependency versus unavailable dependency;
- retention reference versus administrative hold;
- retained Process-control replay versus expired replay versus future sequence
  gap;
- definite provider rejection before effect versus ambiguous provider
  dispatch; and
- internal invariant failure versus evidence/data corruption.

### Per-method admissibility

For each method `K`, code generation produces:

```text
RequestErrorFor<K> = exact subset of RequestError
RecoveryErrorFor<K> = exact subset of RecoveryError
KnownFailureFor<K> = exact subset of accepted-operation failures
AmbiguityFor<K>    = exact subset of missing-proof variants
ResultFor<K>       = exact terminal success payload for a durable Operation
AcceptedResultFor<K> =
  exact Operation, Process, Core-record, existing-Operation, or receipt
  result returned after a non-observation acceptance commit
ObservationResultFor<K> =
  exact synchronous result for an observation method
InvocationOutcome<K> =
    Rejected<RequestErrorFor<K>>
  | RecoveryUnavailable<RecoveryErrorFor<K>>
  | Observed<ObservationResultFor<K>>  // observation class only
  | Accepted<AcceptedResultFor<K>>     // every non-observation class only
```

Code generation eliminates the inapplicable success branch: no method admits
both `Observed` and `Accepted`. The global registry does not make every reason
legal for every method. Missing, duplicate, unreachable, or extra variants
are schema errors.

### Accepted known failures

`RequestError` is never reused as the outcome envelope of an accepted
mutation. The shared semantic registry also owns tagged accepted-failure
variants from which each `KnownFailureFor<K>` is generated. The minimum
families that the operation ledger must refine or prove inapplicable are:

```text
KnownFailure =
    ArtifactMaterializationFailed { stage, cause }
  | CapacityUnavailable { placement?, cause }
  | RuntimeProvisioningFailed { stage, cause }
  | RuntimeReadinessFailed { check, cause }
  | RuntimeControlFailed { phase, cause }
  | ConformanceFailed { probe, cause }
  | SnapshotCaptureFailed { phase, cause }
  | SnapshotVerificationFailed { requirement, cause }
  | RestoreFailed { phase, cause }
  | ResourceResizeFailed { resourceFamily, cause }
  | TerminationFailed { targetKind, cause }
  | CleanupIncomplete { obligations }
  | ProviderRejected { phase, cause }
  | DependencyFailed { dependencyClass, cause }
  | InternalFailure { phase, evidenceId }
  | IntegrityFailure { evidenceId }
```

Every nested `stage`, `phase`, `cause`, `check`, `probe`, requirement, and
obligation is itself a closed operation-specific type. None is an open
provider string. A failure variant is legal only with proof that the success
postcondition was not established and no unfenced authority can later
establish it. The same proximate provider condition with uncertain dispatch,
identity, effect, or authority yields `Unknown<AmbiguityFor<K>>`.

### Detail and disclosure rules

Every variant owns:

- one semantic domain;
- one exact payload schema;
- accepted or pre-accept applicability;
- allowed methods;
- required evidence;
- forbidden inference;
- public disclosure class;
- one `CallerRecovery`;
- permitted private `CoreResolution` actions; and
- derived HTTP and gRPC mappings.

Public messages are safe human text and never parsing authority. Public
details contain no:

- stack trace;
- secret or credential;
- host path;
- raw provider payload;
- unbounded native metadata;
- protected resource existence;
- unredacted command environment; or
- arbitrary protobuf `Any`.

A bounded opaque evidence identifier may link authorized operators to a
protected evidence record.

## Caller Recovery

There is no `retryable: boolean`.

```text
CallerRecovery =
    DoNotRetry
  | RetrySameRequest { after? }
  | RefreshThenSubmit
  | WaitThenSubmit { after?, condition? }
  | ObserveHandle { handle }
  | OperatorAction { actionClass }
```

Meanings:

- `DoNotRetry` — repeating the invocation cannot repair it or would be unsafe;
- `RetrySameRequest` — submit the identical canonical request and key to
  recover the same semantic attempt;
- `RefreshThenSubmit` — obtain current state, form new intent, and use a new
  key only after the prior invocation is proven unaccepted or terminal under
  an operation-specific rule;
- `WaitThenSubmit` — wait for a named condition such as rate-limit reset,
  capacity, or conflicting Operation completion before forming a new attempt;
- `ObserveHandle` — do not resubmit an effect; observe the known Operation or
  Process; and
- `OperatorAction` — safe automated recovery is unavailable.

`after` or `Retry-After` modifies a recovery action. It never independently
authorizes replay.

## Private Core Resolution

Provider and driver recovery is not caller recovery:

```text
CoreResolution =
    None
  | RetrySameNativeExecution
  | AdoptExactNativeExecution
  | Reconcile
  | Compensate
  | Cleanup
```

Rules:

- `RetrySameNativeExecution` requires native idempotency for the same provider
  effect;
- `AdoptExactNativeExecution` requires exact external identity, target,
  runtime epoch, and fencing proof;
- `Reconcile` may gather evidence or create a linked reconciliation
  Operation, but cannot rewrite a terminal predecessor;
- `Compensate` is a new recorded effect and never erases external history;
- `Cleanup` discharges known residual obligations under current authority;
  and
- an opaque or ambiguous native effect is never blindly replayed.

The driver effect classes remain:

```text
idempotent | adoptable | compensable | opaque
```

They constrain legal resolution mechanisms; they do not themselves determine
the observed outcome.

## Operation Outcomes

The locked Operation graph remains:

```text
accepted -> running -> succeeded
                    -> failed
                    -> unknown

accepted/running -> cancel_requested -> cancelled
                                     -> succeeded
                                     -> failed
                                     -> unknown
```

The terminal representation is:

```text
OperationOutcome<K> =
    Succeeded<ResultFor<K>>
  | Failed<KnownFailureFor<K>>
  | Cancelled<CancellationProofFor<K>>
  | Unknown<AmbiguityFor<K>>
```

### `Succeeded`

Every possibility remaining under Core's evidence satisfies the exact
method-specific success postcondition.

### `Failed`

No remaining possibility satisfies the success postcondition, no unfenced
authority can later establish it, and all residual effects are known.

A known partial residual may create cleanup debt while the Operation remains
failed. That debt is an independently observable condition and may create a
linked cleanup Operation.

### `Cancelled`

Cancellation won, the requested postcondition was not established, and no
unfenced requested effect can continue.

Receiving a cancellation request, sending a native cancellation call, or
observing a transport cancellation is insufficient.

### `Unknown`

Core cannot prove the requested postcondition, effect outcome, or exclusion of
acting authority. It is an immutable terminal Operation outcome.

Reconciliation and cleanup may use successor Operations. They never rewrite
the predecessor from `unknown` to success or failure.

### Retrieval and wait

Reading a failed, cancelled, or unknown Operation is a successful
observation. The terminal outcome remains embedded in the Operation resource.

`WaitOperation` returns a wait result containing the latest Operation and
whether the requested observation condition was met. Its deadline does not
turn the Operation into transport `DEADLINE_EXCEEDED` and does not request
cancellation.

The same observation rule applies to the admitted Sandbox and Process waits.
If a Snapshot wait is later added to the taxonomy, it must use the same rule;
this record does not add `WaitSnapshot`.

## Process State and Termination

The locked Process graph remains:

```text
accepted -> starting | terminated
starting -> running | unknown | terminated
running -> unknown | terminated
unknown -> running | terminated
```

The terminal union remains:

```text
ProcessTermination =
    exited { exitCode }
  | signaled { signal }
  | startFailed { failure }
  | deadlineExceeded
  | terminatedByRequest
  | runtimeLost
  | runtimeReplaced
  | fenced
  | stoppedBySandbox
```

Rules:

- nonzero exit remains `exited`;
- `startFailed` proves the command never became running;
- `deadlineExceeded` requires proof that the original Process can no longer
  launch or continue;
- request or observation timeout alone never establishes it;
- `runtimeLost` contains no invented exit code;
- Process `unknown` is reconcilable and nonterminal;
- reconciliation may bind only the same Core launch token and exact backend
  execution identity in the same runtime epoch; and
- Process ambiguity never authorizes replacement Exec.

An SDK may translate `ProcessTermination` into language-specific convenience
exceptions only as an opt-in helper. The authoritative Process resource and
typed termination remain available.

## Evidence Refinement

### Internal model

The minimum semantic effect model is:

```text
effect            = none | partial | complete
mutationAuthority = quiesced | mayStillAct
```

Core knowledge is a nonempty set of possible tuples. Evidence may only refine
that set by set inclusion. Stale, contradictory, or weaker evidence cannot
widen authority or establish a stronger public fact.

`mutationAuthority` means authority held by this accepted mutation, one of its
native attempts, or a stale actor that could still advance that mutation. It
does not mean that the target workload must always be stopped. For example, a
failed Suspend may leave the exact Sandbox runtime proven running, and a
cancelled Terminate may leave the exact Process proven running, provided the
Suspend or termination attempt itself can no longer take effect later.

For an operation-specific success predicate `P`, cancellation is:

```text
cancellation =
    notRequested
  | requested
  | won
  | lost
```

- `succeeded` is legal only when every remaining possibility satisfies `P`
  and cancellation is exactly `notRequested` or proven `lost`;
- `cancelled` is legal only when no remaining possibility satisfies `P`,
  cancellation is proven `won`, every possibility has
  `mutationAuthority = quiesced`, and residual effects are known;
- `failed` is legal only when no remaining possibility satisfies `P`,
  cancellation is `notRequested` or proven `lost`, every possibility has
  `mutationAuthority = quiesced`, and residual effects are known; and
- every other nonempty knowledge set yields `unknown` if a terminal result
  must be committed. In particular, unresolved `cancellation = requested`
  permits no terminal result other than `unknown`.

A known quiesced partial effect may accompany `failed` or `cancelled` when its
exact residual state and cleanup obligations are known. Cancellation causality
selects between those outcomes. An unknown partial effect or possibly acting
mutation authority requires `unknown`.

### Public ambiguity variants

The public surface exposes a closed operation-specific subset of missing
proofs such as:

```text
DispatchOutcomeUnknown
ExternalIdentityUnknown
RuntimePresenceUnknown
RuntimeContinuityUnknown
ProcessLivenessUnknown
EffectCompletionUnknown
CleanupAuthorityUnknown
SnapshotCompletenessUnknown
EvidenceIntegrityUnknown
```

These are not provider error strings. Each variant names the proof Core lacks,
the actions blocked by that absence, the evidence required for any successor,
and the permitted `CoreResolution`.

### Forbidden inference

The ledger must explicitly reject:

- provider acknowledgement as a Core postcondition;
- RPC timeout as effect failure;
- RPC cancellation as remote cancellation;
- missing observation as target absence;
- native resource absence as proof that descendants cannot act;
- cleanup attempt as cleanup completion;
- compensation as rollback;
- filesystem restoration as external-effect rollback;
- stale evidence as current runtime continuity; and
- ambiguous failure as permission to create a replacement effect.

## Sequenced Process Control

### Coordinate

Process-control commands use:

```text
ProcessControlCoordinate {
  processId
  sandboxId
  runtimeEpoch
  writerLeaseId
  sequence
}
```

The lease is bound to one Process and epoch. It cannot be retargeted after
runtime replacement, Process termination, attachment reconnection, or SDK
Session rebinding.

### Command union

```text
ProcessControlCommand =
    WriteInput { coordinate, bytes }
  | CloseInput { coordinate }
  | ResizeTerminal { coordinate, rows, columns }
```

The canonical command digest includes the command kind and payload.

### Deduplication and ordering

After authentication and authorization, exact retained-coordinate recovery
precedes current Process and lease validation:

```text
retained prior sequence + same canonical command
  -> same receipt, regardless of later Process or lease state

retained prior sequence + different canonical command
  -> ProcessControlConflict

prior sequence whose deduplication record expired
  -> RecoveryError.ProcessControlRecordExpired

no retained prior sequence
  -> validate current Process, epoch, lease, and new sequence
```

Only a genuinely new command reaches active-lease sequencing:

```text
stale or fenced lease
  -> StaleWriterLease

exact next sequence
  -> accept after prior sequence

future sequence with a gap
  -> SequenceOutOfRange
```

Commands are delivered in accepted sequence order. Terminal resize shares the
control order because its relation to later interactive input can be
semantically visible.

An expired prior command is never accepted again. Process-control receipt
retention and the stale-sequence boundary are explicit service contracts and
must be long enough for the supported attachment-recovery window.

### Receipt meaning

A successful command receipt proves:

- the command was durably deduplicated and ordered by Core;
- a retry cannot enqueue a duplicate command; and
- Core owns the obligation to deliver, discard under an exact terminal rule,
  or expose an unresolved delivery condition.

It does not prove:

- the process consumed input bytes;
- an application reacted to a terminal resize;
- a shell interpreted the bytes as one logical command; or
- the Process remains alive after the receipt.

`CloseInput` is an irreversible ordered record. A later input write is
rejected. A pending accepted command may be discarded only under a declared
Process-terminal rule and must remain observable through the Process control
status or retained evidence.

### Control outcome carrier

The receipt is the durable carrier for the command's later delivery outcome:

```text
ProcessControlReceipt {
  coordinate
  canonicalCommandDigest
  acceptedAt
  state =
      accepted
    | deliveryRetrying {
        lastFailure
        lastAttemptAt
      }
    | terminal<ProcessControlOutcome>
}

ProcessControlOutcome =
    delivered { deliveredAt, deliveredCoordinate }
  | discarded {
      processTermination
      neverDeliveredProof
      discardedAt
    }
  | failed {
      failure
      neverDeliveredProof
      deliveryAuthority = quiesced
      failedAt
    }
  | unknown { missingProofs }
```

`delivered` proves that the guest supervisor or equivalent target control
boundary accepted the ordered command. It still does not prove application
consumption or reaction. `deliveryRetrying` is nonterminal: Core still owns
delivery and may retry the same ordered command, never enqueue a replacement.
`discarded` proves the command was never delivered and that an exact
Process-terminal rule made delivery permanently inapplicable. `failed`
proves the command was never delivered, all delivery authority is quiesced,
and a non-Process-terminal closed failure made later delivery impossible.
Thus `delivered`, `discarded`, and `failed` are disjoint.

Terminal `unknown` is immutable history: delivery or remaining command
authority could not be proven at the terminalization boundary. Later evidence
may justify a linked reconciliation or cleanup record, but may not rewrite
the receipt. It never authorizes a new sequence with the same semantic
command.

The receipt is retained in the Process control log and recoverable by exact
coordinate during its published recovery window. The operation ledger must
choose the explicit observation method or Process projection; this record
does not create a new independently writable Process-control resource.

### Remaining Process-control work

The following remain open and must be closed before the operation ledger is
complete:

- how an initial writer lease is issued;
- lease expiry, renewal, transfer, and fencing;
- takeover after client loss;
- exact accepted, delivered, and discarded offsets;
- input-spool retention and limits;
- terminal-resize coalescing, if any;
- delivery evidence across guest-supervisor restart; and
- SDK attachment helpers over this protocol.

No target may advertise full interactive Exec conformance until its
supervisor and spool satisfy the final contract.

## Atomic Core-Record Updates

`UpdateSandboxMetadata` and `SetSandboxExpiration` are linearizable Core
record updates:

- request includes an exact expected revision where required;
- idempotency binding and new representation commit atomically;
- success returns the committed representation and resulting revision;
- equal replay returns the committed response even if later updates occurred;
- conflicting key reuse is rejected;
- a stale revision on a genuinely new invocation is `StaleRevision`; and
- neither update changes runtime epoch, authority, Artifact policy, or a
  running workload.

If storage cannot provide the atomic result/idempotency commit, that Core
implementation is non-conforming for these methods and may not advertise or
expose them. Build, startup, or capability admission must fail closed. The
implementation must never change the method's stable result shape by
returning a durable Operation as a fallback.

## Transport Projection

### General rule

Transport status projects a product-owned variant. It never creates or
overrides one.

After acceptance, the initiating method returns its class-specific durable
Operation or Process handle, committed Core-record result, or durable
Process-control receipt. A subsequent retrieval of an accepted handle or
receipt uses a successful transport status even when its embedded terminal
outcome is failed, cancelled, discarded, or unknown.

Transport `UNKNOWN`, `CANCELLED`, `DEADLINE_EXCEEDED`, or `UNAVAILABLE` never
becomes the corresponding Operation or Process outcome without independent
Core evidence.

### HTTP

Synchronous `RequestError` uses RFC 9457 Problem Details:

```text
type      = stable URI derived from the semantic variant
title     = stable safe summary
status    = derived HTTP status
detail    = safe human message
instance  = request occurrence
reason    = stable product variant extension
recovery  = typed recovery extension
details   = exact variant payload
```

The resource representation, not Problem Details, carries an accepted
Operation or Process outcome.

`RecoveryError` also uses Problem Details but carries a distinct stable type
and recovery payload. Its detail explicitly states that no new effect was
dispatched and that the historical effect is not negated. It normally projects
to HTTP 410, never to a fresh `RequestError` reason.

Exact success status codes and URI layout remain wire-design work. A method
must not vary between returning a direct domain result and returning an
Operation based on execution speed.

### gRPC

Synchronous `RequestError` projects to:

- one canonical gRPC code;
- `google.rpc.ErrorInfo` or an equivalent stable reason/domain record;
- applicable bounded standard details such as `BadRequest`,
  `PreconditionFailure`, `ResourceInfo`, or `RetryInfo`; and
- at most one product-owned exact detail message.

Canonical codes are lossy categories. SDKs branch on the product variant,
not the canonical code or human message.

`RecoveryError` projects to `FAILED_PRECONDITION` plus its exact typed reason
unless the final wire registry selects a more precise canonical category. A
canonical client that discards the typed reason is not permitted to
automatically retry.

### Illustrative projections

These are projection guidance, not the semantic source:

| Product variant | HTTP | gRPC |
|---|---:|---|
| `MalformedRequest` | 400 | `INVALID_ARGUMENT` |
| `InvalidArgument` | 422 | `INVALID_ARGUMENT` plus exact reason |
| `Unauthenticated` | 401 | `UNAUTHENTICATED` |
| `PermissionDenied` | 403 | `PERMISSION_DENIED` |
| `TargetNotFound` | 404 | `NOT_FOUND` |
| `RecoveryError.IdempotencyRecordExpired` | 410 | `FAILED_PRECONDITION` plus exact reason |
| `RecoveryError.ProcessControlRecordExpired` | 410 | `FAILED_PRECONDITION` plus exact reason |
| `NameConflict` | 409 | `ALREADY_EXISTS` |
| `IdempotencyConflict` | 409 | `ALREADY_EXISTS` plus exact reason |
| `StaleRevision` | 409 or 412 by request form | `ABORTED` or `FAILED_PRECONDITION` |
| `StaleRuntime` | 409 | `ABORTED` plus exact epoch detail |
| `InvalidState` | 409 or 412 | `FAILED_PRECONDITION` |
| `ConcurrentOperation` | 409 | `ABORTED` |
| `MethodUnavailable` | 501 | `UNIMPLEMENTED` |
| `CapabilityUnsupported` | 422 | `FAILED_PRECONDITION` |
| `RateLimited` | 429 | `RESOURCE_EXHAUSTED` |
| `QuotaExceeded` | 429 | `RESOURCE_EXHAUSTED` |
| `CapacityUnavailable` | 503 | `RESOURCE_EXHAUSTED` or `UNAVAILABLE` by exact ownership |
| `ServiceUnavailable` | 503 | `UNAVAILABLE` |
| `InternalInvariantViolation` | 500 | `INTERNAL` |
| `EvidenceCorrupt` | 500 | `DATA_LOSS` |

The final machine registry selects one exact projection per variant and
transport context. The table does not permit runtime choice.

## Provider and Driver Evidence

The protected evidence record retains, where available:

- provider and API/SDK version;
- Core method and internal phase;
- provider resource, operation, Process, Snapshot, and revision identifiers;
- native HTTP/gRPC status and structured provider code;
- request, trace, and client-request identifiers;
- rate-limit and `Retry-After` metadata;
- transport disposition: definitely unsent, sent without response, partial
  response, or complete response;
- timeout layer: transport, admission, observation, readiness, execution, or
  lifetime;
- cancellation requested, acknowledged, and terminally observed times;
- ordered native state and event observations;
- bounded redacted payload and digest; and
- the decoding adapter/version that produced the evidence.

Unknown native codes and future provider states remain protected evidence and
map conservatively. They never extend the public union dynamically.

### Provider counterexamples

The following current contracts demonstrate why native status cannot define
Core semantics:

- Cloudflare documents that an Exec timeout closes the connection while the
  underlying Process continues;
- Modal operations may complete after a client timeout, and image or Snapshot
  failure may be discovered lazily;
- Daytona Delete may return when destruction is only accepted unless the
  caller explicitly waits;
- Fly Create returns before launch completes and `/wait` 408 is an observation
  timeout;
- CodeSandbox Resume may return a clean boot rather than preserved
  continuity;
- Vercel abort/cancellation wording spans request, command, and operation
  layers;
- Kubernetes HTTP 409 spans name collision, stale revision, field-ownership,
  and state conflict;
- OpenAI HTTP 429 spans temporary rate pressure and exhausted quota;
- E2B timeout errors combine unavailable service, request cancellation,
  execution deadline, and unknown causes; and
- OpenSandbox lifecycle endpoints acknowledge transitions before their final
  postconditions.

A driver must use native identities, state observations, target fencing,
guest supervision, and provider-specific idempotency to justify one Core
variant. Status-only mapping is non-conforming.

## Artifact Validation and Runtime Ownership Boundary

The frontend-independent Artifact/profile validation pipeline owns declarative
facts and rejects structurally impossible target combinations before an
Artifact Set is built:

- absent target capability;
- incompatible Snapshot class;
- impossible multi-target capability requirement;
- invalid immutable policy composition;
- unsupported resource range; and
- other closed Artifact/profile incompatibilities.

The runtime API owns dynamic facts:

- current Sandbox, Process, Snapshot, and Operation state;
- runtime epoch and representation revision;
- current operation-pair compatibility;
- admission closure;
- live retention references;
- capacity, quota, and provider availability;
- expiry races;
- evidence freshness; and
- provider effect ambiguity.

Every authoring frontend reaches the product-owned semantic validator. Nix
remains the construction substrate and may perform defensive validation during
construction, but is not a separate semantic authority. The runtime
revalidates signed or content-addressed Artifact and profile identity
defensively. It does not accept runtime widening of declarative policy.

Framework and SDK adapters may:

- translate native exceptions into declared Core calls;
- recover the same handle using Core idempotency;
- derive convenience helpers such as `attach` or Stop-then-Delete; and
- present language-specific typed errors.

They may not:

- add error variants;
- reinterpret a timeout as failure or cancellation;
- auto-replay an ambiguous effect;
- retarget a stale runtime reference;
- collapse Process exit into infrastructure failure; or
- bypass the Core operation contract with a provider-native call.

## Formal and Machine-Inventory Consequences

### Operation-contract record

Every method and system-operation kind must declare:

```text
OperationContract {
  method
  callClass
  originSet
  requestSchema
  targetSchema
  successSchema
  orderedAdmissionChecks
  acceptedResultKind?
  allowedRequestErrors
  allowedRecoveryErrors
  allowedKnownFailures
  allowedAmbiguities
  allowedProcessControlOutcomes
  successPredicate
  requiredEvidence
  forbiddenInference
  callerRecoveryByOutcome
  coreResolutionByOutcome
  idempotencyContract
  retentionContract
  concurrencyLane
  transportProjection
}
```

### Required dimensions

The exhaustive ledger must cover:

1. method or system-operation kind;
2. call class;
3. tagged target and exact runtime epoch;
4. origin, authenticated scope, and authority;
5. starting Sandbox, admission, Process, Snapshot, and Operation state;
6. capability profile;
7. idempotency state, canonical digest, revision, and epoch preconditions;
8. ordered admission gate and exact rejection;
9. intent, dispatch, observation, commit, cancellation, and cleanup phase;
10. effect certainty and authority certainty;
11. provider effect class;
12. native identity and provider idempotency token;
13. disconnect, timeout layer, cancellation, and crash point;
14. native evidence, decoding version, and public redaction;
15. public outcome, detail payload, and recovery;
16. cleanup, compensation, fencing, quarantine, and orphan obligation;
17. resulting Operation, Process, Sandbox, and Snapshot facts;
18. transport projection;
19. retention and tombstone state;
20. predecessor and successor Operation links; and
21. required evidence plus every forbidden inference.

Every row states whether acceptance occurred. Every accepted row identifies
the durable Operation/Process handle, committed Core-record result, or durable
Process-control receipt.

### Fail-closed generation

The machine source generates:

- protocol discriminated unions;
- sealed SDK types;
- operation-specific reason subsets;
- HTTP/gRPC projections;
- disclosure and redaction fixtures;
- acceptance and transition matrices;
- ordered operation-pair matrices, including self-pairs;
- backend conformance fixtures;
- formal-model constants and actions; and
- documentation tables.

Validation requires:

- exact set equality;
- no wildcard or default outcome;
- no open provider reason;
- no missing, extra, duplicate, or unreachable cell;
- conditional predicates expanded into total concrete cells;
- absent operation-pair entries treated as specification errors; a generated
  explicit deny row yields the runtime conflict;
- mutation tests for deleted, added, renamed, duplicated, and remapped
  variants; and
- changed counts whenever a method, reason, state, capability, or evidence
  category changes.

### Formal model

The temporal model must verify:

1. rejection implies no durable handle and no effect-producing dispatch;
2. accepted intent is durable before dispatch;
3. equal replay returns the same handle;
4. conflicting replay produces no effect;
5. stale epoch never acquires current authority;
6. success requires the exact postcondition;
7. failure and cancellation never hide possibly acting authority;
8. unknown never authorizes blind successor effect;
9. cleanup never rewrites terminal history;
10. unauthorized existence is not observable;
11. Process-control commands deduplicate and preserve sequence;
12. wait timeout never mutates the observed resource;
13. provider acknowledgement alone proves no Core postcondition; and
14. an absent operation-pair or outcome cell makes the specification invalid,
    while an explicit deny cell produces the declared runtime conflict.

TLA+/Quint with TLC or Apalache is the primary temporal-state exploration
candidate. Alloy 6 may supplement bounded structural and relation checks.
Typed effect systems may ensure declared implementation effects are handled,
but cannot prove whether a remote effect occurred after a lost response.

## Registry Obligations Introduced

The exhaustive Packet E walk must assign stable identifiers, ownership,
earliest-sound boundary, positive and negative witnesses, hooks, tests, and
diagnostics for at least:

1. request rejection after durable intent exists;
2. effect dispatch before durable handle, canonical request, idempotency
   binding, and authority commit;
3. transport failure represented as Core rejection;
4. accepted failure returned only as transport error rather than embedded
   outcome;
5. terminal Operation failure, cancellation, or unknown returned as failed
   retrieval;
6. generic canonical status used as semantic authority;
7. open string or provider-defined public reason;
8. reason/detail, reason/recovery, or reason/transport contradiction;
9. public arbitrary detail map or provider payload;
10. permission response leaking resource existence;
11. semantic validation preceding required authorization;
12. mutable lifecycle check preceding recovery of an identical accepted
    request;
13. same idempotency coordinate rebound to different intent;
14. conflicting idempotency replay dispatching an effect;
15. retired idempotency record silently authorizing a new mutation;
16. terminal failed Operation automatically replayed as a new attempt;
17. `retryable` boolean standing in for exact recovery scope;
18. `Retry-After` treated as effect-replay permission;
19. provider retry without same native idempotency or exact adoption proof;
20. compensation represented as rollback;
21. known cleanup debt hiding possibly acting authority under `failed`;
22. cancellation request, acknowledgement, RPC cancellation, or timer
    reported as proven `cancelled`;
23. RPC deadline reported as Operation failure or Process deadline outcome;
24. terminal Operation unknown rewritten after reconciliation;
25. terminal Operation unknown conflated with reconcilable Process unknown;
26. nonzero Process exit reported as API or infrastructure failure;
27. Process start failure reported without proof that it never ran;
28. runtime loss inventing an exit code;
29. Process ambiguity triggering replacement Exec;
30. observation timeout mutating or terminalizing the observed resource;
31. atomic Core-record update committing representation without its
    idempotency result or vice versa;
32. Process input without exact writer lease and sequence;
33. repeated Process-control sequence duplicating a command;
34. repeated sequence accepting different canonical content;
35. out-of-order Process-control command accepted without explicit policy;
36. stale writer lease controlling another Process or epoch;
37. input receipt represented as application consumption;
38. terminal resize outside the ordered Process-control contract;
39. CloseProcessInput followed by accepted input;
40. accepted Process-control command silently lost without delivered,
    discarded, or unresolved evidence;
41. unknown provider code extending the public union;
42. raw provider evidence escaping redaction or size bounds;
43. provider status alone proving success, absence, cancellation, or failure;
44. declarative incompatibility deferred to runtime without an explicit
    target branch;
45. runtime request widening Artifact policy;
46. framework adapter adding semantics, replay, retargeting, or error
    variants;
47. wildcard/default operation outcome;
48. missing operation-specific error or ambiguity subset;
49. missing ordered admission precedence;
50. absent evidence requirement or forbidden-inference declaration; and
51. absent operation-contract cell treated as implementation discretion.

These are decision obligations, not current registry coverage.

## Remaining Packet E Work

This decision does not yet lock:

- exact request/result and condition/freshness schemas beyond the fields
  locked here;
- the exhaustive final variant set after every operation row is walked;
- exact language and wire field spelling;
- exact HTTP success status and URI conventions;
- idempotency key format, stale-request mechanism, retention durations, and
  tombstone representation;
- Operation, Process, Snapshot, event, output, evidence, and tombstone
  retention durations;
- Process writer-lease issue, renewal, transfer, expiry, and fencing;
- Process-control delivered/discarded offsets and spool limits;
- complete Snapshot component, compatibility, and reference schemas;
- the complete operation-pair compatibility table;
- dynamic reservation and time-of-check/time-of-use protocol;
- guest-control sequencing and acknowledgement beyond the Process-control
  rules locked here;
- cleanup, orphan-adoption, and reconciliation deadlines;
- provider-triggered lifecycle interception and event schemas;
- provider, guest, event, and evidence decoding boundaries;
- final Packet A file, directory, transfer, endpoint, and port method names
  and their concurrency contracts;
- backend conformance evidence; or
- stable registry entries, production hooks, tests, and diagnostics.

The next Packet E artifact is the machine-readable operation-contract schema
and complete inventory for the currently named Packet E lifecycle/control
surface, with explicit unresolved handoffs to the Packet A-owned data-plane
families. It must use this record as its semantic source. The complete Core
method inventory cannot close until those Packet A method names close.

## Research Reconciliation

### Mature production patterns retained

- Google long-running Operations separate failures that prevent an Operation
  from starting from failures stored on an accepted Operation.
- Google AIP-193 requires stable structured reasons because canonical status
  codes are insufficient.
- Google AIP-194 distinguishes safe unary retry, higher-level transaction
  retry, state repair, and non-retryable failure.
- Google AIP-211 requires authorization before validation to avoid existence
  disclosure.
- AWS idempotency compares caller token and semantic parameters and rejects
  mismatched reuse.
- Temporal separates handler/task failure, accepted execution failure,
  cancellation, timeout, and retry state.
- Kubernetes demonstrates revision conflicts, retry hints, and controller
  reconciliation, while also demonstrating why open-world Status details are
  insufficient for this closed Core.
- FoundationDB and CockroachDB expose ambiguous effect/commit separately from
  known retryable failure.

### Academic and formal patterns retained

- RIFL motivates durable request identity, atomic completion records, and an
  explicit stale-request boundary.
- Sagas establish compensation as a later effect rather than erasure of
  external history.
- Beldi and ExoFlow demonstrate durable workflow execution and recovery
  annotations while leaving application-specific semantic proof to the
  product.
- algebraic effect systems can make unhandled implementation effects
  statically visible but cannot establish remote outcome after message loss;
  and
- TLA+/Apalache and Alloy provide complementary temporal and structural
  counterexample search.

### Provider research retained

The provider sweep covered E2B, Modal, Daytona, Fly Machines, Vercel Sandbox,
Cloudflare Sandbox, CodeSandbox, Kubernetes Agent Sandbox, OpenAI hosted
Containers and Sandbox Agents, Blaxel, and OpenSandbox. Provider contracts
were used as adversarial evidence, not as a public vocabulary source.

## References

### API, transport, and durable execution contracts

- [Google AIP-151: Long-running operations](https://google.aip.dev/151)
- [Google AIP-154: Resource freshness validation](https://google.aip.dev/154)
- [Google AIP-155: Request identification](https://google.aip.dev/155)
- [Google AIP-193: Errors](https://google.aip.dev/193)
- [Google AIP-194: Automatic retry configuration](https://google.aip.dev/194)
- [Google AIP-211: Authorization checks](https://google.aip.dev/211)
- [Google long-running Operations](https://github.com/googleapis/googleapis/blob/master/google/longrunning/operations.proto)
- [Google RPC status](https://github.com/googleapis/googleapis/blob/master/google/rpc/status.proto)
- [Google RPC error details](https://github.com/googleapis/googleapis/blob/master/google/rpc/error_details.proto)
- [gRPC status codes](https://github.com/grpc/grpc/blob/master/doc/statuscodes.md)
- [gRPC richer error model](https://grpc.io/docs/guides/error/)
- [RFC 9110: HTTP Semantics](https://www.rfc-editor.org/rfc/rfc9110.html)
- [RFC 9457: Problem Details for HTTP APIs](https://www.rfc-editor.org/rfc/rfc9457.html)
- [Nexus RPC HTTP Specification](https://github.com/nexus-rpc/api/blob/main/SPEC.md)
- [Temporal failure schema](https://github.com/temporalio/api/blob/master/temporal/api/failure/v1/message.proto)
- [Temporal failure reference](https://docs.temporal.io/references/failures)
- [AWS EC2 idempotency](https://docs.aws.amazon.com/ec2/latest/devguide/ec2-api-idempotency.html)
- [AWS Builders' Library: Making retries safe with idempotent APIs](https://aws.amazon.com/builders-library/making-retries-safe-with-idempotent-APIs/)
- [IETF Idempotency-Key draft](https://datatracker.ietf.org/doc/html/draft-ietf-httpapi-idempotency-key-header)
- [Kubernetes API concepts](https://kubernetes.io/docs/reference/using-api/api-concepts/)
- [Kubernetes API errors](https://github.com/kubernetes/apimachinery/blob/master/pkg/api/errors/errors.go)
- [Kubernetes StatusDetails](https://kubernetes.io/docs/reference/kubernetes-api/definitions/status-details-v1-meta)
- [FoundationDB developer guide](https://apple.github.io/foundationdb/developer-guide.html)
- [CockroachDB transaction retry and ambiguity](https://www.cockroachlabs.com/docs/stable/transactions)

### Runtime and mechanism contracts

- [OCI Runtime Specification lifecycle](https://github.com/opencontainers/runtime-spec/blob/main/runtime.md)
- [containerd error projection](https://github.com/containerd/errdefs/blob/main/pkg/errgrpc/grpc.go)
- [Kubernetes CRI v1 API](https://github.com/kubernetes/cri-api/blob/master/pkg/apis/runtime/v1/api.proto)
- [Container Storage Interface specification](https://github.com/container-storage-interface/spec/blob/master/spec.md)
- [Container Network Interface specification](https://github.com/containernetworking/cni/blob/main/SPEC.md)
- [Linux wait semantics](https://man7.org/linux/man-pages/man2/waitpid.2.html)
- [Linux errno](https://man7.org/linux/man-pages/man3/errno.3.html)

### Provider contracts

- [E2B SDK errors](https://e2b.dev/docs/sdk-reference/js-sdk/v2.29.1/errors.md)
- [E2B Sandbox SDK](https://e2b.dev/docs/sdk-reference/js-sdk/v2.29.1/sandbox.md)
- [Modal exceptions](https://modal.com/docs/reference/modal.exception)
- [Modal Sandbox](https://modal.com/docs/reference/modal.Sandbox)
- [Modal Sandbox snapshots](https://modal.com/docs/guide/sandbox-snapshots)
- [Daytona SDK errors](https://www.daytona.io/docs/en/typescript-sdk/errors)
- [Daytona Sandbox lifecycle](https://www.daytona.io/docs/en/typescript-sdk/sandbox/)
- [Fly Machines API](https://fly.io/docs/machines/api/working-with-machines-api/)
- [Fly Machine states](https://fly.io/docs/machines/machine-states/)
- [Vercel Sandbox SDK](https://vercel.com/docs/sandbox/sdk-reference)
- [Vercel Sandbox snapshots](https://vercel.com/docs/sandbox/concepts/snapshots)
- [Cloudflare Sandbox commands](https://developers.cloudflare.com/sandbox/api/commands/)
- [Cloudflare Sandbox backups](https://developers.cloudflare.com/sandbox/api/backups/)
- [CodeSandbox lifecycle](https://codesandbox.io/docs/sdk/lifecycle)
- [CodeSandbox resume](https://codesandbox.io/docs/sdk/resume)
- [Kubernetes Agent Sandbox lifecycle](https://agent-sandbox.sigs.k8s.io/docs/sandbox/lifecycle)
- [OpenAI Containers](https://developers.openai.com/api/docs/guides/tools-code-interpreter)
- [OpenAI API errors](https://developers.openai.com/api/docs/guides/error-codes)
- [OpenAI Sandbox Agents](https://openai.github.io/openai-agents-js/guides/sandbox-agents/clients/)
- [Blaxel Create Sandbox API](https://docs.blaxel.ai/api-reference/compute/create-sandbox)
- [OpenSandbox lifecycle specification](https://github.com/opensandbox-group/OpenSandbox/blob/main/specs/sandbox-lifecycle.yml)
- [OpenSandbox execd specification](https://github.com/opensandbox-group/OpenSandbox/blob/main/specs/execd-api.yaml)

### Academic and formal foundations

- [RIFL: Implementing Linearizability at Large Scale and Low Latency](https://web.stanford.edu/~ouster/cgi-bin/papers/rifl.pdf)
- [Sagas](https://dl.acm.org/doi/10.1145/38713.38742)
- [Beldi: A Fault-tolerant Serverless Platform for Stateful Applications](https://www.usenix.org/conference/osdi20/presentation/zhang-haoran)
- [ExoFlow: A Universal Workflow System for Exactly-Once DAGs](https://www.usenix.org/system/files/osdi23-zhuang.pdf)
- [Koka algebraic effects](https://www.microsoft.com/en-us/research/wp-content/uploads/2016/08/algeff-tr-2016-v2.pdf)
- [Apalache model checker](https://apalache-mc.org/)
- [Alloy 6](https://alloytools.org/alloy6.html)
