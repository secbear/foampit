# Gate 2A Invariant Inventory Review

Status: **Open — Packets A through D reviewed; Packet E identity, lifecycle,
operation taxonomy, and result/error contract locked; Packets E and F remain**

This is the working review record for Gate 2A in the
[Invariant Inventory and Enforcement Protocol](../INVARIANT-ENFORCEMENT.md).
It records coverage, omissions, and review work. It does not define semantic
rules outside [`invariants.json`](./invariants.json). A locked architecture
decision may create explicit registry obligations, but they do not count as
inventory coverage: each must receive a registry/corpus identifier before
Gate 2A classifies it, Packet E closes, or implementation consumes it.

## Current Machine-Checked Baseline

As of 2026-07-24:

- 140 corpus invariant identifiers are present in the registry;
- the corpus and registry identifier sets match exactly;
- 140 entries are `specified`;
- 140 authoritative hooks are planned;
- 560 tests are planned;
- no entry is marked `closed`;
- Gate 2A structure passes;
- Packet A has reviewed 117 public resource/operation surface groups;
- Packet B has reviewed 81 Artifact field rows across 17 required families and
  introduced 45 invariant cases;
- Packet C has reviewed 4 initial target profiles, all 324 Artifact
  field/profile cells, 85 structurally complete ordered value cases, and 3
  provider transport contracts, introducing 7 invariant cases;
- Packet D has reviewed 17 composition/trust-boundary invariant cases and its
  exact matrix covers 54 paths × 140 invariants = 7,560 unique cells in 634
  complete-contract groups, with 89 focused validator checks;
- Gate 2A review is open; and
- Gate 4B correctly fails.

Current owner distribution:

| Owner | Registered invariants |
|---|---:|
| Artifact Definition | 91 |
| `CreateSandbox` | 13 |
| Operator Configuration | 11 |
| Managed-Sandbox Service Definition | 5 |
| Live Sandbox operation | 5 |
| `Exec` / Process | 7 |
| Framework/CLI adapter | 3 |
| Runtime/driver boundary | 5 |

Packet A's complete field/operation ledger and decision record are
[`PACKET-A-SURFACE-COVERAGE.json`](./PACKET-A-SURFACE-COVERAGE.json) and
[`PACKET-A-RESOURCE-OPERATION-REVIEW.md`](./PACKET-A-RESOURCE-OPERATION-REVIEW.md).
Packet B's field ledger, research reconciliation, and decision record are
[`PACKET-B-ARTIFACT-FIELDS.json`](./PACKET-B-ARTIFACT-FIELDS.json),
[`PACKET-B-RESEARCH-NOTES.md`](./PACKET-B-RESEARCH-NOTES.md), and
[`PACKET-B-ARTIFACT-FIELD-REVIEW.md`](./PACKET-B-ARTIFACT-FIELD-REVIEW.md).
Packet C's profile registry, realization corpus, provider contracts, research,
and decision record are
[`PACKET-C-TARGET-PROFILES.json`](./PACKET-C-TARGET-PROFILES.json),
[`PACKET-C-TARGET-REALIZATION.json`](./PACKET-C-TARGET-REALIZATION.json),
[`PACKET-C-CASE-CONTRACTS.json`](./PACKET-C-CASE-CONTRACTS.json),
[`PACKET-C-PROVIDER-CONTRACTS.json`](./PACKET-C-PROVIDER-CONTRACTS.json),
[`PACKET-C-RESEARCH-NOTES.md`](./PACKET-C-RESEARCH-NOTES.md), and
[`PACKET-C-TARGET-REALIZATION-REVIEW.md`](./PACKET-C-TARGET-REALIZATION-REVIEW.md).

## Inventory-Dimension Review

The status labels mean:

- **seeded** — the current corpus has multiple relevant entries;
- **partial** — at least one relevant entry exists, but the declared product
  state space has not been walked completely;
- **unwalked** — the current corpus does not yet represent the dimension as a
  complete review unit.
- **reviewed** — the packet's declared scope has a complete machine-readable
  surface ledger and all remaining work is delegated explicitly.

| Protocol dimension | Status | Current evidence | Required review before approval |
|---|---|---|---|
| Resource ownership | reviewed | Packet A: 117 surface groups; `MAN-*`, `CRT-*`, `SVC-*`, `LIVE-*`, `EXE-*`, `FWK-*` | Preserve the Packet A ledger as later packets refine semantics |
| Representation structure | reviewed for Artifact | Packet B: 81 fields; `STR-*`, `SUM-*`, `NET-*`, `RES-*`, `IDN-*`, `SEC-*`, `DEV-*`, `SCT-*`, `OUT-*` | Packets C-F must perform the same complete walk for their scoped resources and boundaries |
| Single-resource semantics | reviewed for Artifact | Packet B covers profiles, defaults, environment, filesystem, network, resources, identity/security, secrets, lifecycle requirements, outputs, provenance, and targets | Preserve Packet B as Packets C-F refine realization, lifecycle, and disclosure |
| Cross-resource semantics | reviewed through composition | Packet D owner/effect checks cover distinct Artifact, Operator Configuration, Managed-Service Definition, Create, and runtime branches | Packets E-F must preserve these ownership exclusions while completing lifecycle and disclosure |
| Cross-target semantics | reviewed for initial targets | Packet C: 81 fields × Bubblewrap, Firecracker, Cloud Hypervisor, and OCI; provider transport remains separate | Packet D-F must preserve the matrix while adding bypass, lifecycle, and evidence detail; every later profile repeats Packet C |
| Composition semantics | reviewed through Packet D | Packet D: 54 paths × 140 invariants = 7,560 cells; 634 complete-contract groups; 89 focused checks; three clean final verdicts | Packets E/F additions reopen affected composition coordinates |
| Escape mechanisms | reviewed through Packet D | resource-qualified native escapes, typed/direct Nix values, unsafe opaque input, raw wire, and five driver trust states | Packet E/F additions reopen the affected path universe |
| Trust boundaries | reviewed through Packet D | exact 89+30 serialized replay sets, private stage chain, total D0 output, direct/raw rejection, six separate-path handoffs | Packet E must still walk operation-specific API, guest, restore, teardown, and evidence decoding |
| Lifecycle semantics | partial | Packet E durable Operation/runtime identity, Sandbox/Process state models, typed operation taxonomy, and request/result/error/recovery architecture are locked; exhaustive operation contracts and transition cases remain unregistered | Inventory every legal and illegal transition, operation pair, admission rejection, idempotency/cancellation/recovery outcome, cleanup state, restore/fork/migration contract, Process-control command, and deletion proof |
| Dynamic state | partial | Packet C profiles classify host prerequisites, object-handle retention, resources, networking, devices, and provider admission | Packet E must walk acquisition, reservation, rollback, retry, cancellation, mutation, and teardown transitions |
| Security and disclosure | partial | secret ownership/redaction, offline policy, host paths | Walk ambient environment, sockets, protected paths, logs, evidence, provenance, diagnostics, process inheritance, metadata services, and side-channel claims |
| Valid expressiveness | reviewed through Packet D | `VAL-001` through `VAL-042`; Packet D adds pinned closed Operator Configuration, Managed-Service Definition, and revalidated resolved reentry controls | Packets E-F add complete lifecycle and disclosure witnesses |

No row may remain `partial` or `unwalked` when Gate 2A closes.

## Required Review Packets

The review proceeds in packets so that scope is explicit and changes remain
auditable.

### Packet A: Public resources and operations

Status: **Reviewed.** See
[`PACKET-A-RESOURCE-OPERATION-REVIEW.md`](./PACKET-A-RESOURCE-OPERATION-REVIEW.md)
and
[`PACKET-A-SURFACE-COVERAGE.json`](./PACKET-A-SURFACE-COVERAGE.json).

Inputs:

- `DESIGN.md`;
- `CONFIGURATION-BOUNDARY-AUDIT.md`;
- the option-surface research;
- the Core Sandbox API resource and lifecycle model.

Output:

- one field/operation inventory for every public resource;
- one ownership decision per field;
- a registry link for every semantic restriction;
- an explicit decision where no additional invariant exists.

### Packet B: Artifact field families

Status: **Reviewed.** See
[`PACKET-B-ARTIFACT-FIELD-REVIEW.md`](./PACKET-B-ARTIFACT-FIELD-REVIEW.md),
[`PACKET-B-ARTIFACT-FIELDS.json`](./PACKET-B-ARTIFACT-FIELDS.json), and
[`PACKET-B-RESEARCH-NOTES.md`](./PACKET-B-RESEARCH-NOTES.md).

Reviewed:

- environment and activation;
- filesystem, workspace, mounts, content, and storage;
- network, DNS, proxy, ports, and host channels;
- CPU, memory, process, time, and I/O resources;
- identity, users, capabilities, devices, and security policy;
- secrets and binding-slot contracts;
- snapshot, persistence, and declared outputs;
- profile expansion, target selection, provenance, and identity.

Every field family is checked for structure, omission, forbidden inputs,
manifest projection, refinement, cross-field conflicts, cross-resource
binding, multi-target meaning, diagnostics, and valid advanced use. Remaining
target, composition, lifecycle, and disclosure obligations are delegated
explicitly to Packets C-F in the ledger.

### Packet C: Target and provider realization

Status: **Reviewed.** See
[`PACKET-C-TARGET-REALIZATION-REVIEW.md`](./PACKET-C-TARGET-REALIZATION-REVIEW.md),
[`PACKET-C-TARGET-REALIZATION.json`](./PACKET-C-TARGET-REALIZATION.json),
[`PACKET-C-CASE-CONTRACTS.json`](./PACKET-C-CASE-CONTRACTS.json),
[`PACKET-C-TARGET-PROFILES.json`](./PACKET-C-TARGET-PROFILES.json),
[`PACKET-C-PROVIDER-CONTRACTS.json`](./PACKET-C-PROVIDER-CONTRACTS.json), and
[`PACKET-C-RESEARCH-NOTES.md`](./PACKET-C-RESEARCH-NOTES.md).

Reviewed every declared semantic requirement through:

- bubblewrap argument lowering and host supervision;
- the microVM artifact adapter;
- Firecracker and Cloud Hypervisor runtime profiles;
- OCI artifact/runtime separation;
- remote-provider capability and artifact-transfer contracts.

Each result is one of:

- conforming lowering;
- explicit build-time unsupported outcome;
- creation/operator/preflight requirement; or
- observed runtime conformance requirement.

No “best effort,” warning-only, or implicit fallback result is permitted.
The selector rules expand to exactly 324 non-overlapping field/profile cells
and each cell has a closed, ordered partition shape with stable predicate
coordinates. Executable semantic predicates remain planned Gate 4B hooks;
structural coverage does not claim executable conformance. Remote-provider
transport is reviewed as three separate contracts and never becomes a target
profile.

### Packet D: Composition, native configuration, and bypasses

Status: **Reviewed — cold reconstruction, adversarial semantic review, and
prototype-evidence sign-off complete.** See
[`PACKET-D-COMPOSITION-REVIEW.md`](./PACKET-D-COMPOSITION-REVIEW.md).

The reviewed, digest-bound machine snapshot is reconstructable from
[`PACKET-D-COMPOSITION-PATHS.json`](./PACKET-D-COMPOSITION-PATHS.json),
[`PACKET-D-CASE-CONTRACTS.json`](./PACKET-D-CASE-CONTRACTS.json), and
[`PACKET-D-COMPOSITION-COVERAGE.json`](./PACKET-D-COMPOSITION-COVERAGE.json):
54 paths, 140 invariants, 7,560 cells, 634 complete-contract groups, exact
89 built-member/load and 30 resolved-stage replay arrays, six separate-path
handoffs, and exact Packet E/F concern taxonomies.

The distinct resource branches are `P1 -> A0/A1/W0`,
`P1 -> OC0/O0`, and `P1 -> MS0/S0`; serialized reentry is untrusted at
`RW0 -> C0/O0/H0/D0`. Generated backend configuration is D0 output.
Direct/raw driver entry has no admitted value. `prebuilt-member-transfer` and
`oci-descriptor-transfer` end at H0; `provider-cache-hit` ends at D0; and
`provider-side-construction`, `provider-build-cache`, and
`corrupted-provider-build-result` end at N1. Each then records a
`separate-path-handoff` to the `manifest-load` C0 boundary of
`built-artifact-load`. These handoffs are never phase edges or authority to
skip manifest loading. Framework and CLI share typed Create/live/Exec
translation; teardown remains Packet E work.

For every supported frontend and native extension, walk:

- imports and reversed import order;
- profiles and explicit fields;
- priorities, force/override/update/amendment operations;
- open records and arbitrary values;
- native guest modules and typed Nix handles;
- namespaced unsafe extensions;
- raw canonical input and corrupted resolved input.

The output lists both ordinary and strongest supported construction paths for
each invariant.

The final focused validator passes 89 cases. Independent reviewers
reconstructed all totals and contracts, rejected coordinated mutations after
neutralizing digest pins, and verified the real Nix/Rust prototype mechanisms
and exact counters. The reviewed snapshot is bound to path
`488bf76167461b52766dd9fa8a9b1756d084f1ebc08c795315fd2baf2fbab6e0`,
case-contract
`955c3dd8c03927be6876c58b2c3c67210f1fc0710ecf5f5ea2a4a2c59bc3f5b0`,
invariant
`8901d7f384a8fea6b5c8bec82271b4456b4052b988ba74ff1947adda5a768ee2`
(reviewed as `d798c8fd…3284c2`; amended by the 2026-07-31 coherence repair
without changing any classification, path, phase, owner, or effect),
and coverage
`16b156ef2d39c10f55f5aedb5abc025385b865e7d92f9a8ccbb2dd4bf635e532`
SHA-256 values.

All 140 production hooks and 560 production tests remain planned. Gate 4B
therefore remains open; Gate 2A remains open only for Packets E and F.

### Packet E: Runtime lifecycle and trust boundaries

The durable-mutation and identity substrate is locked in
[Packet E: Durable Operations and Sandbox Runtime Identity](./PACKET-E-OPERATION-IDENTITY-DESIGN.md):

- one writable Sandbox aggregate with stable ID and optional human alias;
- a public monotonically increasing runtime epoch distinct from `etag`;
- a separate internal authority epoch that fences stale effect producers;
- durable Operations for Sandbox lifecycle and Process signal/termination
  mutations, with tagged targets, plus durable epoch-bound Processes for Exec;
- explicit idempotency, cancellation, deadline, ambiguity, and stale-handle
  semantics; and
- no writable Core `Session` or independently authoritative runtime child.

The portable lifecycle state model is locked in
[Packet E: Sandbox and Process Lifecycle State](./PACKET-E-LIFECYCLE-STATE-DESIGN.md):

- separate Operation, Sandbox, and Process state machines;
- Sandbox runtime states `provisioning`, `running`, `suspended`, `stopped`,
  and `unknown`;
- independent execution admission `accepting` or `closed`;
- no caller-writable desired state and no authoritative verb-specific
  transition phases;
- Process states `accepted`, `starting`, `running`, `unknown`, and
  `terminated`, with typed terminal outcomes;
- proof-based Stop and Delete completion;
- signal dispatch distinct from Process exit;
- durable replayable-output obligations; and
- conservative concurrency, crash, and reconciliation rules.

The lifecycle/control method taxonomy is locked in
[Packet E: Lifecycle and Control Operation Taxonomy](./PACKET-E-OPERATION-TAXONOMY-DESIGN.md):

- required Create, Start, Stop, Delete, Exec, and Terminate semantics;
- precise Get/List/Wait and Process-I/O observations;
- capability-gated Signal, Suspend/Resume, in-place Resize, Snapshot,
  Restore, and Fork;
- immutable, exact Snapshot capability classes with filesystem/runtime kind,
  complete component semantics, explicit source disposition, and v1 rejection
  of nonterminal Core Processes;
- narrow metadata and exact absolute-expiration `{ at, action }` schedules
  instead of generic Update or TTL;
- rejection of portable Restart, Wake, KillSandbox, Destroy, Rollback,
  Connect, Attach, Session, Archive, and Migration; and
- desired-state adapter and private native-driver ownership.

The request/result/error/recovery architecture is locked in
[Packet E: Request, Result, Error, and Recovery Contract](./PACKET-E-RESULT-ERROR-CONTRACT-DESIGN.md):

- synchronous `RequestError` only with proof of no durable acceptance and no
  effect-producing dispatch;
- distinct `RecoveryError` when no new effect was dispatched but an old
  idempotency or Process-control coordinate is outside its recovery window;
- class-specific ownership of every post-acceptance outcome by durable
  Operation, durable Process, committed Core-record result, or retained
  Process-control receipt;
- transport uncertainty recovered through the identical canonical request and
  idempotency key;
- a shared sealed reason registry with generated per-method subsets and no
  open provider error or `retryable` boolean;
- proof-gated `succeeded`, `failed`, `cancelled`, and terminal Operation
  `unknown`;
- separate caller recovery, private native resolution, and protected provider
  evidence;
- six exact call classes, including sequenced Process-control commands; and
- fail-closed machine generation and formal-model obligations.

These foundations do not close Packet E. The next review must turn all four
decision records' registry obligations into an exhaustive machine-readable
operation-contract, transition, and compatibility inventory, then walk:

- Create, prepare, Start, Exec, Process I/O, Signal, Terminate, Suspend,
  Resume, Stop, Snapshot, Restore, Fork, Resize, expiration, Delete,
  provider-native kill, inspect, and copy/data-plane interaction;
- ordered admission, rejection, retry, recovery, cancellation, timeout,
  partial failure, orphan cleanup, idempotency, and Process-control sequence;
- manifest/API/provider/guest/evidence decoding;
- dynamic reservation and time-of-check/time-of-use behavior;
- declared, lowered, prepared, observed, and recorded facts.

This packet cannot be closed by authoring-language fixtures alone.

### Packet F: Security, disclosure, and evidence

Walk:

- secret values and references;
- ambient environment and inherited descriptors;
- host sockets, metadata endpoints, protected paths, and control state;
- diagnostic, log, provenance, trajectory, and evidence redaction;
- artifact identity versus non-hashed explanation records;
- claimed versus measured isolation/conformance.

Each rule records the earliest phase that has the relevant information and the
trust boundary that revalidates external input.

## Review Mechanics

For each packet:

1. enumerate the complete declared state space from the controlling design;
2. classify every state transition or combination as valid, invalid, or
   intentionally unsupported;
3. assign a stable ID before adding a new normative rule;
4. add invalid and valid witnesses;
5. choose the first-sound phase, deadline, and disposition;
6. enumerate target, trust-boundary, composition, and escape-hatch
   applicability;
7. plan exactly one authority and all defensive/observational hooks;
8. plan the tests and structured diagnostic;
9. rerun exact corpus/registry validation; and
10. perform a reader review for ownership or phase leakage.

The review record must not infer completeness from invariant count. Completion
comes from every declared field, operation, state, target, boundary, and escape
mechanism having an explicit reviewed outcome.

## Gate 2A Exit Record

The eventual approval must state:

- design revision and registry digest reviewed;
- packets completed;
- resources, operations, targets, and extensions included;
- intentionally unsupported or future scope;
- reviewer findings and their disposition;
- inventory-validator result; and
- zero remaining `partial` or `unwalked` rows.

Until that record is completed, prototype work is exploratory and no candidate
may be treated as having implemented the full corpus.
