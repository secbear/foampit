# Packet B Artifact Field Research Notes

Status: **Reconciled**

Date: 2026-07-24

These notes record the evidence and reconciliation behind
[`PACKET-B-ARTIFACT-FIELDS.json`](./PACKET-B-ARTIFACT-FIELDS.json). They are not
an additional normative schema. The executable corpus defines each invalid and
valid witness, while `invariants.json` is the traceability source of truth.

## Inputs

Three independent read-only reviews covered:

1. profile, metadata, platform, environment, default Process, workspace, and
   filesystem;
2. network, resources, identity, security, and devices;
3. secret slots, capabilities, snapshot/persistence requirements, outputs,
   provenance, identities, targets, and native construction.

The reviews were reconciled against all 71 pre-Packet-B registry rules rather
than accepted additively. Packet B introduced 45 rules, strengthened four
existing rules, and rejected or delegated proposals whose first complete
information belongs to a later resource or phase.

## Primary-source checks

### Nix development environments

The Nix reference manual defines `nix develop` as a Bash shell providing an
interactive build environment close to that used to build an installable. Its
environment includes variables and shell functions. This supports a typed,
closed `devShell` importer but does not make the devShell a deployable root
filesystem or justify silently retaining arbitrary shell state:

- [Nix `develop` reference](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-develop.html)

Accepted consequence: `XRS-011` requires a lossless closed projection of
packages/closures, explicit non-secret variables, executable search paths, and
explicit argv-form activation. Unsupported or host-dependent state fails at
Nix construction evaluation.

### OCI image versus runtime configuration

OCI defines the image format as sufficient to carry application launch
defaults, while the runtime specification consumes an unpacked filesystem
bundle and low-level host/platform configuration. Runtime configuration owns
process, mounts, namespaces, resources, devices, security, and lifecycle
details. The runtime must error when it cannot create the specified
environment:

- [OCI Image Specification](https://github.com/opencontainers/image-spec)
- [OCI Runtime Specification](https://specs.opencontainers.org/runtime-spec/)
- [OCI Runtime Configuration](https://specs.opencontainers.org/runtime-spec/config?v=v1.3.0)

Accepted consequence: OCI image environment, user, cwd, entrypoint, and volume
metadata never fill omitted Artifact fields. `XRS-014` gives absence a portable
meaning and rejects any source-level inheritance sentinel. `MAN-004` checks
exact built projection, and Packet C must prove the OCI lowerer suppresses
conflicting image/runtime defaults.

### Linux security mechanisms

Linux kernel documentation explicitly says seccomp system-call filtering is
not itself a sandbox; it reduces exposed kernel surface and is intended to be
combined with other hardening and potentially an LSM. Landlock is a stackable
LSM for restricting ambient filesystem/network rights and has ABI-dependent
coverage and limitations:

- [Linux seccomp filter documentation](https://cdn.kernel.org/doc/html/latest/userspace-api/seccomp_filter.html)
- [Linux Landlock userspace API](https://github.com/torvalds/linux/blob/master/Documentation/userspace-api/landlock.rst)

Accepted consequence: `SEC-002` uses separate registered, versioned semantic
requirements for seccomp, LSM/Landlock, syd, namespaces, and similar controls.
No single mechanism may claim the complete sandbox policy.

### Resource dimensions

The cgroup v2 interface distinguishes relative `cpu.weight` from the absolute
bandwidth limit `cpu.max`, and distinguishes relative `io.weight` from
BPS/IOPS `io.max`. Its pids controller has its own task-counting and enforcement
semantics:

- [Linux cgroup v2 documentation](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)

Accepted consequence: `RES-001` forbids generic `cpu`, `memory`, `disk`, or
`io` numbers. Every resource field names its unit, dimension, scope, and bound
kind; Packet B enumerates CPU concurrency, CPU quota/weight, total and workload
memory, swap, tasks, root/volume/tmpfs capacities, and directional BPS/IOPS.

### Device contracts

CDI models a device by a qualified identity, but CDI injection can update an
OCI configuration with device nodes, mounts, hooks, and environment values;
resource management is deliberately outside CDI:

- [CNCF Container Device Interface](https://github.com/cncf-tags/container-device-interface)

Accepted consequence: an opaque CDI/device name cannot be the portable device
policy. `DEV-001` keeps live allocation outside the Artifact, and `DEV-002`
requires every induced environment, mount, hook, group, capability, and
host-channel effect to project through ordinary Artifact policy.

## Reconciliation

| Finding family | Disposition | Reason |
|---|---|---|
| Relative non-mount resource destinations | Strengthened `STR-001` | Same invalid state, authority, phase, and remediation as the original mount-only rule |
| Secret/provider data in Artifact | Strengthened `STR-004` | Provider references, account identities, and lookup expressions violate the same immutable-input boundary |
| Activation ordering and imported `shellHook` | Strengthened `STR-005` | Same argv/shell ambiguity; broader construction paths and diagnostic paths |
| Workspace materialization alternatives | Strengthened `SUM-001` | Original wording incorrectly implied the Artifact must choose one run's materialization |
| Platform, visible profiles, metadata, Nix references, devShell, ambient environment, default Process | Accepted | Existing rules did not state these field semantics or their omission behavior |
| Workspace/filesystem resource shapes and path graph | Accepted | Slot/cardinality rules did not define complete resource alternatives or cross-resource topology |
| Network policy and host channels | Accepted | `SUM-004` covered only one contradiction and did not define a complete closed policy |
| Resource dimensions and internal ranges | Accepted | Creation/operator bound rules did not validate Artifact self-consistency or resource meaning |
| Identity, privilege, kernel policies, devices | Accepted | Exec narrowing and target-capability rules did not define Artifact-owned ceilings |
| Secret delivery, destination, snapshot compatibility | Accepted | Generic slot and immutable-secret rules did not define complete secret interfaces |
| Snapshot requirement | Accepted | `SUM-003` covered only part of memory-snapshot completeness |
| Generic persistence, declared outputs | Accepted | No preexisting rule separated all persistence meanings or defined output eligibility |
| Semantic/member/set identities, target/profile structure, native scope | Accepted | Existing identity and native rules did not define typed domains or complete declaration shape |
| Actual target lowering and conformance | Delegated to Packet C | Target-specific mechanisms and successful construction are not Artifact field semantics |
| Override/import/native bypass enumeration | Delegated to Packet D | Packet B states final invariants; Packet D proves every construction path reaches them |
| Create/live/restore/collection timing and retention | Delegated to Packet E | These are operations against a live or retained Sandbox |
| Runtime disclosure, symlink/descriptor escape, evidence claims | Delegated to Packet F | Static policy is Packet B; observed enforcement and safe disclosure require runtime state |

## Locked Packet B decisions

1. A `devShell` is an optional typed importer, not a root filesystem.
2. A default Process field is explicit/profile-derived or absent. Absence never
   imports an OCI image, provider, or backend default.
3. There is no intra-Artifact behavioral `variant`. Intentionally different
   common semantics are separate named Artifact Definitions that may import a
   shared module. One Artifact Set contains target members for one common
   semantic identity.
4. Output declarations use exact normalized paths and file/directory kinds in
   v1. Globs and patterns are not supported. Declaration means eligible for
   collection, not selected or required to exist for every run.
5. Snapshot requirements are capability contracts. Concrete snapshot timing,
   destination, retention, restore, and lifecycle operations remain outside the
   Artifact.
6. File, credential, and explicitly permitted environment delivery are the v1
   secret alternatives. Every alternative is typed, value-free, and has an
   explicit positive finite maximum delivery lifetime.
7. An optional Artifact maximum lifetime is supported as a positive finite hard
   security ceiling. Omission means no Artifact-imposed ceiling; operator
   policy may still impose a narrower maximum. Create TTL, renewal, idle action,
   Process deadline, and teardown remain runtime-owned.
8. Target, runtime profile, target member, portable semantic identity, and
   Artifact Set identity are distinct concepts and typed identity domains.
9. Artifact source selects required runtime-profile identities and conformance
   versions; it cannot author support or passing-suite claims. Builders emit
   those facts and evidence, and manifest load verifies them.
10. DNS omission normalizes to denied only when IP access is denied. Under
    unrestricted or controlled access, DNS must be explicit.

## Independent review corrections

Two independent cold reviews were performed without conversation context.
Their actionable findings were incorporated as follows:

| Finding | Locked correction |
|---|---|
| Static Process absence overstated target enforcement | `XRS-014` now rejects only portable inheritance requests at `A1`; `MAN-004` and Packet C own target preservation |
| Artifact source appeared able to mint conformance facts | Profile fields now contain requirements only; `TGT-003` uses builder evidence at `N1` and manifest verification at `C0` |
| `MAN-004` used an indirect positive witness | Its positive-boundary witness is now `VAL-022`, which exercises explicit and absent Process projection |
| DNS omission could hide a resolver default | The exact mode-to-omission rule is explicit and normalized |
| Secret delivery lifetime omission was ambiguous | Every delivery alternative requires a positive finite maximum |
| Static lifetime ceiling was mislabeled delegated | The ceiling field is `covered`; a separate derived row delegates runtime enforcement to Packet E |
| Packet D coverage was visible only in prose | `artifact.profile.compositionPaths` explicitly delegates every import/profile/override/native/raw path to Packet D |
| Field-ledger validation accepted ambiguous data | The validator now trims semantic strings and rejects duplicate introduced IDs, invariant references, delegated packets, and Packet A surface references |

## Coverage correction to Packet A

The Packet A ledger was reopened and refined because it lacked separate rows
for profile selection, secret slots, snapshot/persistence requirements,
declared outputs, and portable semantic identity. It also conflated target and
runtime-profile structure with target-native configuration.

Packet A now has separate Artifact rows for those surfaces and separate
manifest rows for snapshot/persistence and output declarations. Packet B's
validator proves that every Artifact/manifest Packet A surface is refined by at
least one field row.
