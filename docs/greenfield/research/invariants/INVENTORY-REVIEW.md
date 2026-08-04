# Gate 2A Invariant Inventory Review

Status: **Open — Packets A through E reviewed; Packet F remains, and the
dynamic-state row carries an undischarged Packet E remainder**

Two dimension rows are still `partial`. Security and disclosure is Packet F's
scope. Dynamic state is not: acquisition, reservation, and rollback, together
with the dynamic reservation and time-of-check/time-of-use protocol, were
explicitly deferred during the Packet E walk because all four locked Packet E
records list that protocol as still unlocked. Gate 2A cannot close on Packet F
alone.

This is the working review record for Gate 2A in the
[Invariant Inventory and Enforcement Protocol](../INVARIANT-ENFORCEMENT.md).
It records coverage, omissions, and review work. It does not define semantic
rules outside [`invariants.json`](./invariants.json). A locked architecture
decision may create explicit registry obligations, but they do not count as
inventory coverage: each must receive a registry/corpus identifier before
Gate 2A classifies it, Packet E closes, or implementation consumes it.

## Current Machine-Checked Baseline

As of 2026-07-24:

- 354 corpus invariant identifiers are present in the registry;
- the corpus and registry identifier sets match exactly;
- 354 entries are `specified`;
- 354 authoritative hooks are planned;
- 1,206 tests are planned;
- no entry is marked `closed`;
- Gate 2A structure passes;
- Packet A has reviewed 117 public resource/operation surface groups;
- Packet B has reviewed 81 Artifact field rows across 17 required families and
  introduced 45 invariant cases;
- Packet C has reviewed 4 initial target profiles, all 324 Artifact
  field/profile cells, 85 structurally complete ordered value cases, and 3
  provider transport contracts, introducing 7 invariant cases;
- Packet D has reviewed 17 composition/trust-boundary invariant cases and its
  exact matrix covers 54 paths × 354 invariants = 19,116 unique cells in 948
  complete-contract groups, with 92 focused validator checks;
- Gate 2A review is open; and
- Gate 4B correctly fails.

Current owner distribution (354 across 9 owners):

| Owner | Registered invariants |
|---|---:|
| Core Sandbox API control plane | 128 |
| Artifact Definition | 94 |
| Live Sandbox operation | 36 |
| Runtime/driver boundary | 28 |
| `CreateSandbox` | 18 |
| `Exec` / Process | 15 |
| Framework/CLI adapter | 14 |
| Operator Configuration | 13 |
| Managed-Sandbox Service Definition | 8 |

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
| Composition semantics | reviewed through Packet D | Packet D: 54 paths × 354 invariants = 19,116 cells; 948 complete-contract groups; 92 focused checks; three clean final verdicts. Widened by Packet E registration; the reviewed path and classification semantics stand, the new cells are Packet E's | Packet F additions reopen affected composition coordinates |
| Escape mechanisms | reviewed through Packet D | resource-qualified native escapes, typed/direct Nix values, unsafe opaque input, raw wire, and five driver trust states | Packet E/F additions reopen the affected path universe |
| Trust boundaries | reviewed through Packet D | exact 89+30 serialized replay sets, private stage chain, total D0 output, direct/raw rejection, six separate-path handoffs | Packet E must still walk operation-specific API, guest, restore, teardown, and evidence decoding |
| Lifecycle semantics | reviewed | Packet E: 214 registered invariants in 16 families; 37 operations × 6 lifecycle states = 222 contract cells; 625 operation-pair concurrency cells; all 20 Packet A surfaces and 5 Packet B fields delegating to E are claimed | Packet F adds disclosure and evidence obligations over the same operations |
| Dynamic state | partial — ruled, deferred to F | Packet C profiles classify host prerequisites, object-handle retention, resources, networking, devices, and provider admission; Packet E discharges retry, cancellation, mutation, and teardown transitions through the operation ledger | **Acquisition, reservation, and rollback remain undischarged**, together with the dynamic reservation and time-of-check/time-of-use protocol all four locked Packet E records list as still unlocked. This row cannot close on Packet E alone |
| Security and disclosure | partial | secret ownership/redaction, offline policy, host paths | Walk ambient environment, sockets, protected paths, logs, evidence, provenance, diagnostics, process inheritance, metadata services, and side-channel claims |
| Valid expressiveness | reviewed through Packets D-E | `VAL-001` through `VAL-256`; Packet D adds pinned closed Operator Configuration, Managed-Service Definition, and revalidated resolved reentry controls | Packets E-F add complete lifecycle and disclosure witnesses |

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

The digest-bound machine snapshot is reconstructable from (digests recomputed after Packet E registration widened the invariant axis; the Packet D review verdicts stand for the path universe and classification semantics, not for the Packet E cells)
[`PACKET-D-COMPOSITION-PATHS.json`](./PACKET-D-COMPOSITION-PATHS.json),
[`PACKET-D-CASE-CONTRACTS.json`](./PACKET-D-CASE-CONTRACTS.json), and
[`PACKET-D-COMPOSITION-COVERAGE.json`](./PACKET-D-COMPOSITION-COVERAGE.json):
54 paths, 354 invariants, 19,116 cells, 948 complete-contract groups, exact
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

The final focused validator passes 92 cases. Independent reviewers
reconstructed all totals and contracts, rejected coordinated mutations after
neutralizing digest pins, and verified the real Nix/Rust prototype mechanisms
and exact counters. The reviewed snapshot is bound to path
`65322c7c30f4c75222a36793b8d1b877fa5813df4d1c83f236bb18884c364a65`,
case-contract
`52feb46769b058401fc14e73198635c71abfad6789e50b3fd7de260741c59401`,
invariant
`7cd71ffdd40be3f61744704731b6de8acee30f91c060c51b9caa6f8f81c2b517`
(reviewed as `d798c8fd…3284c2`; amended by the 2026-07-31 coherence repair
without changing any classification, path, phase, owner, or effect),
and coverage
`bee8df000f15578079ef2723edb85a26edcb621b384a432b346449681da44248`
SHA-256 values.

All 140 production hooks and 560 production tests remain planned. Gate 4B
therefore remains open; Gate 2A remains open only for Packets E and F.

### Packet E: Runtime lifecycle and trust boundaries

Status: **Reviewed — 214 invariants registered, operation ledger complete,
independent verification pending.** See
[`PACKET-E-OBLIGATION-PARTITION-REVIEW.md`](./PACKET-E-OBLIGATION-PARTITION-REVIEW.md)
and the machine records
[`PACKET-E-OBLIGATION-PARTITION.json`](./PACKET-E-OBLIGATION-PARTITION.json),
[`PACKET-E-OPERATION-REGISTRY.json`](./PACKET-E-OPERATION-REGISTRY.json),
[`PACKET-E-CASE-CONTRACTS.json`](./PACKET-E-CASE-CONTRACTS.json),
[`PACKET-E-OPERATION-CONTRACTS.json`](./PACKET-E-OPERATION-CONTRACTS.json), and
[`PACKET-E-CONCURRENCY-MATRIX.json`](./PACKET-E-CONCURRENCY-MATRIX.json).

The four locked decision records — operation identity, lifecycle state,
operation taxonomy, and the request/result/error/recovery contract — listed 178
registry obligations between them. Those obligations are now discharged:

| Disposition | Count |
|---|---:|
| Registered as invariants | 214 entries in 16 families |
| Governed by a generated operation contract | 201 |
| Covered only by a stated absence (`FRK-005` via `deferred.migration`) | 1 |
| Assigned to the driver, adapter, artifact, or service ledger | 12 |
| Source obligations cited at least once | 178 / 178 |

The ledger closes what earlier packets delegated: all 20 Packet A surfaces
marked `delegatedPacket: "E"` are claimed by an operation, all 5 Packet B fields
delegating `"E"` are resolved, and Packet D's
`delegatedConcernTaxonomy.E` — operation-transition, retry, cancellation,
cleanup — is resolved by the transition matrix, the recovery contracts, and the
system-originated `cleanup` operation kind.

Four structural rulings were required and are recorded with their evidence:

1. **A ninth owner, `core`,** for the Core Sandbox API control plane. Every
   existing `runtime` entry is `DRV-*`/`WIRE-*` at the driver boundary, so
   overloading it would have made that family mean two things at two phases.
2. **No phase or edge added.** The graph is a validation-order model over a
   single traversal, not runtime history. Every candidate restart edge creates a
   cycle *and* makes `L0 -> E0` reachable, contradicting this protocol directly.
3. **Specification-totality meta-rules became validator rules** over the ledger
   rather than registry entries, following Packet C/D precedent.
4. **The locked token `unknown` is namespaced** in ledger encodings
   (`state-unknown`, `outcome-unknown`) because every ledger validator rejects
   `^UNKNOWN$` as placeholder content. Vocabulary entries carry a
   `lockedSourceRef` citation so the correspondence is checkable.

Known open work, stated rather than absorbed:

- the `create-native-extension` surface is defined nowhere in `DESIGN.md`, so
  six `CRT-*` cells carry rejection-only evidence as a deliberate hedge;
- no `ERR` arm exists for Process or Operation *observation*, so four
  observation records state the gap rather than cite an arm scoped to Exec;
- `OPA-002` does not enumerate Process termination and `ADM-007` is ambiguous
  between set-time and fire-time; both need amendment before closure;
- the Packet A-owned data-plane families (file, directory, copy, transfer,
  endpoint, port) have deferral markers because their method names are not yet
  closed;
- the 12 non-operation invariants require the driver, adapter, artifact, and
  service ledgers they are assigned to actually to exist.

Additional open work found by the Task 14 independent verification and recorded
rather than absorbed:

- ~~`PACKET-E-OPERATION-CONTRACT-REVIEW.md` does not exist.~~ **Closed
  2026-08-03**: the decision record now exists with the ledger digests, the
  rulings, the scope, and what Packet E does not close.
- **The gate still prints `Gate 2A remains open for Packets E-F`.** That is
  deliberate and correct while the decision record is missing and the
  dynamic-state row carries an undischarged Packet E remainder, but it means
  the gate output and a bare reading of "Packets A through E reviewed" disagree
  unless both caveats are read.
- **`FRK-005` is governed by no generated operation contract**, only by the
  `deferred.migration` stated-absence marker, because public Migration is a
  rejected v1 name.
- **Four of the eight digest pins have no second copy**, contradicting the
  lockstep table in `CONTRIBUTING.md`. Both Packet E pins are in that group.
- **The Packet E validator anchors cell structure but not cell semantics.**
  Adversarial review confirmed that a transition target, error variant, or
  terminal outcome can be rewritten in the catalog and the generated matrix
  together and survive, because the generated document is checked against the
  catalog rather than against an independent statement of the rule. The cell
  kind and its transition-vector position are likewise two copies of one fact,
  so their agreement proves consistency and not correctness. Closing this needs
  a semantic anchor the ledger does not yet have.

Packet E does not close Gate 4B. All 354 authoritative hooks and 1,206 tests
remain `planned`.

### Dynamic-state remainder: ruled 2026-08-03

Acquisition, reservation, and rollback, together with the dynamic reservation
and time-of-check/time-of-use protocol that all four locked Packet E records
list as still unlocked, are **reassigned to Packet F** rather than left as an
unowned remainder.

The reasoning is that these are not lifecycle-semantics questions. Acquisition
and reservation are about *what the product may take from a host it does not
own, and on whose evidence*; rollback is about *what it may claim to have
undone*. Their invalid states are disclosure and evidence failures — a
reservation claimed without host evidence, a capacity fact read at check time
and relied on at use time, a rollback reported that the target never performed.
That is Packet F's declared scope: claimed versus measured, and evidence
integrity.

Packet E's own boundary supports this. The locked records place the reservation
protocol outside the operation contract, and Packet E's ledger already carries
the *operation-side* halves — retry, cancellation, mutation, and teardown
transitions — through the transition matrix and the recovery contracts. What
remains is the host-evidence side.

Consequence, stated plainly: **Packet F's scope is wider than its original
statement.** Packet F must walk acquisition, reservation, rollback, and the
TOCTOU protocol in addition to secrets, ambient environment, sockets, protected
paths, redaction, provenance, and side channels. The row stays `partial` until
Packet F closes it, and Gate 2A cannot close before then.

### Packet F: Security, disclosure, and evidence

**Scope widened 2026-08-03** by the dynamic-state ruling above: Packet F also
owns acquisition, reservation, rollback, and the dynamic reservation and
time-of-check/time-of-use protocol. These are evidence-integrity questions —
a reservation claimed without host evidence, a capacity fact read at check time
and relied on at use time, a rollback reported that the target never performed.

Walk:

- secret values and references;
- ambient environment and inherited descriptors;
- host sockets, metadata endpoints, protected paths, and control state;
- diagnostic, log, provenance, trajectory, and evidence redaction;
- artifact identity versus non-hashed explanation records;
- claimed versus measured isolation/conformance;
- host resource acquisition and reservation, and the evidence a reservation
  claim rests on;
- time-of-check/time-of-use between a host fact and its use;
- rollback claims versus what a target actually performed;
- process inheritance from the supervisor, and inherited descriptors after
  launch;
- side-channel claims;
- authentication and tenancy, delegated by
  [`PACKET-A-RESOURCE-OPERATION-REVIEW.md`](./PACKET-A-RESOURCE-OPERATION-REVIEW.md);
- metadata services, including the host-side carve-out where an endpoint is
  reachable by the supervisor but not by the guest.

**Where each part of F's scope comes from (ruled 2026-08-03).** Three
independent delegations feed Packet F, and they are not the same list:

| Source | What it delegates | Scope of the delegation |
|---|---|---|
| `PACKET-D-CASE-CONTRACTS.json` `delegatedConcernTaxonomy` | `disclosure`, `redaction`, `evidence-visibility` | Per **composition path**, expanded mechanically onto all 54. |
| `PACKET-A-RESOURCE-OPERATION-REVIEW.md:184-185` | authentication, tenancy | Per **public surface group**. |
| The dimension row above | process inheritance, side channels, metadata services | Per **runtime boundary**. |

Packet F's scope is their union. The Packet D taxonomy is **not** widened to
match it, and that is deliberate: `delegatedConcerns` is a per-path expansion,
so adding `authentication` would assert that `artifact-ordinary-authoring`
delegates authentication to F. An authoring path has no process and no
authentication. The taxonomy is correct as a statement about composition paths
and false as a statement about F's scope; conflating the two would corrupt
Packet D's model to fix a bookkeeping mismatch that is not a mismatch.

**Scope reconciled 2026-08-03.** The dimension row above requires walking
process inheritance, metadata services, and side-channel claims, and Packet A
delegates authentication and tenancy here; the walk list named only metadata
endpoints. The four omissions are added rather than left to be rediscovered
during the walk. The E/F disclosure seam is ruled separately in
[`PACKET-E-F-DISCLOSURE-SEAM.md`](./PACKET-E-F-DISCLOSURE-SEAM.md).

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
