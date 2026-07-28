# Gate 2A Packet A: Public Resources and Operations

Status: **Reviewed — Packet A ownership inventory complete; delegated semantic
work remains mandatory in Packets B–F**

Reviewed: 2026-07-23; coverage corrected by Packet B on 2026-07-24

This packet walks every public resource, field group, operation family, trust
boundary, and native-extension scope declared by the controlling greenfield
design and boundary research.

The machine-readable review is
[`PACKET-A-SURFACE-COVERAGE.json`](./PACKET-A-SURFACE-COVERAGE.json).
It is validated against the invariant registry on every inventory check.

## Result

Packet A reviewed 117 surface groups across:

| Resource | Total | Covered in Packet A | Delegated | No new rule |
|---|---:|---:|---:|---:|
| Artifact Definition | 24 | 0 | 23 | 1 |
| Built manifest | 11 | 5 | 6 | 0 |
| Operator Configuration | 15 | 4 | 11 | 0 |
| Managed-Sandbox Service Definition | 8 | 3 | 3 | 2 |
| `CreateSandbox` | 16 | 8 | 7 | 1 |
| Live Sandbox operations | 13 | 4 | 9 | 0 |
| `Exec` / Process | 12 | 7 | 4 | 1 |
| Framework/CLI adapter | 10 | 5 | 4 | 1 |
| Core runtime/driver mechanism | 8 | 0 | 8 | 0 |
| **Total** | **117** | **36** | **75** | **6** |

“Delegated” does not mean omitted. It means Packet A resolved ownership and
assigned the remaining semantic walk to exactly one later packet:

| Destination packet | Surface groups |
|---|---:|
| B — Artifact field families | 20 |
| C — target/provider realization | 14 |
| D — composition and escape mechanisms | 5 |
| E — runtime lifecycle and trust boundaries | 20 |
| F — security, disclosure, and evidence | 16 |

Every covered or delegated row cites existing registry identifiers where a
rule is already known. A covered row must cite at least one invariant.
Delegated rows name `B`–`F` explicitly. Rows marked “no new rule” include a
review rationale and remain subject to ordinary schema/authorization rules.

## New Invariants

The review expanded the common corpus from 47 to 71 invalid-state invariants
and added five valid boundary witnesses.

### Built Artifact and manifest

- `MAN-001` — manifest identity/content mismatch;
- `MAN-002` — unsupported target/guest protocol in a built manifest;
- `MAN-003` — secret or provider reference in a built manifest.

### Creation

- `CRT-001` — required binding absent;
- `CRT-002` — undeclared or incompatible binding;
- `CRT-003` — duplicate binding for a single-cardinality slot;
- `CRT-004` — idempotency-key semantic conflict;
- `CRT-005` — target/profile absent from the Artifact;
- `CRT-006` — initial Process bypasses the Exec contract.

### Managed service

- `SVC-001` — service-specific second sandbox policy;
- `SVC-002` — direct driver invocation outside the Core API.

### Live Sandbox

- `LIVE-001` — live mutation widens immutable policy;
- `LIVE-002` — capability-gated operation without conformed support;
- `LIVE-003` — file operation crosses the Sandbox file contract;
- `LIVE-004` — port operation exceeds resolved network authority.

### Process / Exec

- `EXE-001` — empty Process argv;
- `EXE-002` — cwd outside the Sandbox namespace;
- `EXE-003` — ordinary environment bypasses secret/reserved channels;
- `EXE-004` — Process identity or privileges widen the Sandbox;
- `EXE-005` — Exec-native extension changes Sandbox isolation;
- `EXE-006` — PTY request without conformed support;
- `EXE-007` — Process deadline exceeds remaining Sandbox lifetime.

### Framework/CLI adapter

- `FWK-001` — adapter bypasses the Core API;
- `FWK-002` — adapter advertises unsupported capability.

Valid cases `VAL-015` through `VAL-019` prove manifest loading, idempotent
creation, managed-service equivalence, bounded live operations, and narrow
per-Process execution remain expressible.

## Architectural Corrections

### The product phases are a graph

The previous corpus ended at sandbox launch and used a linear phase order. That
was insufficient for the declared public API.

Packet A added:

- `F0` — framework/CLI translation;
- `S0` — managed-service reconciliation;
- `R1` — post-create conformance;
- `L0` / `L1` — live-operation validation and mutation;
- `E0` / `E1` — Exec validation and Process launch;
- `T0` — teardown and final evidence.

Live and Exec are repeatable sibling branches. The registry validator now
checks reachability in the product-phase graph and rejects impossible
cross-branch deadlines.

### Live and Exec are first-class owners

The previous owner set described configuration sources but not post-create
resources. Packet A added:

- `live` for one operation against an existing Sandbox;
- `exec` for one Process request;
- `runtime` for trusted implementation mechanisms and driver boundaries.

This makes diagnostics point at the surface the caller can fix. `DRV-001` is
now correctly runtime-owned rather than forced into Operator Configuration.

### Initial Process is not a second command model

`CreateSandbox` may optionally contain an initial Process, but that nested value
uses the same semantic Process contract as `Exec`. Create does not gain a shell
string, weaker environment channel, broader identity, or separate timeout
model.

### Managed services are typed API callers

The service layer owns desired state, reconciliation, autostart, restart,
retention, and cleanup choices. It does not own a second sandbox policy or a
direct driver lifecycle. Generated units call the Core Sandbox API.

### The manifest is output and untrusted input

The built manifest is immutable Artifact output, never another authoring
surface. Runtime loading treats it as untrusted: identity, digests, protocols,
claims, and absence of secret/provider data are checked before creation
resolution.

## Machine Checks

Packet A adds:

- a surface-ledger validator;
- seven focused surface-validator cases;
- resource-category completeness;
- registry-reference validation;
- outcome/delegation validation;
- duplicate surface detection; and
- placeholder rejection.

The controlling inventory command now validates:

1. registry structure;
2. exact corpus/registry ID coverage;
3. focused registry regression cases;
4. Packet A surface-ledger structure; and
5. all 117 surface-to-invariant/delegation references.

## Packet A Exit Decision

Packet A is reviewed for resource ownership and operation boundaries.

This does **not** close Gate 2A. The 75 delegated surface groups are required
inputs to Packets B–F. In particular:

- Artifact field semantics are intentionally left to Packet B;
- target-specific correctness and post-create conformance remain in Packet C;
- native and language escape mechanisms remain in Packet D;
- lifecycle transitions, retries, cancellation, cleanup, snapshots, and
  restore remain in Packet E; and
- authentication, tenancy, secrets, diagnostics, logs, evidence, and
  disclosure remain in Packet F.

Gate 2A closes only when those packets are reviewed and the working inventory
record contains no `partial` or `unwalked` dimension.

Packet B reopened the machine ledger after finding eight missing or conflated
Artifact/manifest surfaces. Profile selection, secret slots,
snapshot/persistence requirements, declared outputs, portable semantic
identity, supported targets/runtime profiles, and target-native construction
now have separate traceable rows. The correction changed only delegated
coverage; covered and no-new-rule counts are unchanged.
