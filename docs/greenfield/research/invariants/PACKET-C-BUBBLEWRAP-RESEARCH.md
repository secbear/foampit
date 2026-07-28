# Packet C Bubblewrap Target Realization Research

Status: **Primary-source research complete; executable target conformance not yet run**

Target review coordinate: `bubblewrap-linux-v1`

Research date: 2026-07-24

This report maps all 81 Packet B Artifact fields to the initial Bubblewrap
Linux target profile. It records conforming mechanisms or explicit unsupported
cases, the earliest sound phase and deadline, component ownership, manifest
projection, backend defaults that must be suppressed, and the executable
evidence required before a support claim is valid.

No implementation conformance was executed during this research. Every
evidence class below is an obligation for Packet C and the later implementation
and conformance packets, not an already-earned claim.

## Bottom Line

`bubblewrap-linux-v1` is sound only as a versioned profile bundle, not
"Bubblewrap by itself":

- pinned Bubblewrap;
- owned argv compiler and pre-exec launcher;
- FD-safe path resolver;
- cgroup v2 supervisor;
- network-namespace/policy broker;
- UID/GID mapping support where required;
- secret broker;
- post-start evidence collector.

Bubblewrap is deliberately a low-level toolkit whose security properties are
determined by the caller's arguments. It always creates an empty mount
namespace but does not itself provide network policy, cgroup limits, lifecycle
deadlines, provenance, or profile conformance claims. [Upstream
README](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/README.md)

The recommended initial pin is Bubblewrap `v0.11.2`, commit
`1b80120ef26a28e065e67f89bfef873f13bdd317`, released 2026-04-23, built with
`-Dsupport_setuid=false`, with preflight also rejecting an executable carrying
the setuid bit. The official release says setuid mode is deprecated and the
non-setuid build is the default; current `main` already declares version
`0.12.0`, so moving `main` links are not adequate profile evidence. [v0.11.2
release](https://github.com/containers/bubblewrap/releases/tag/v0.11.2),
[current
`meson.build`](https://raw.githubusercontent.com/containers/bubblewrap/main/meson.build)

## Mapping Notation

### Phases and owners

- `B`: builder, before member manifest publication.
- `C`: Create resolution.
- `O/P`: operator admission and host preflight, before launch.
- `D`: driver/pre-exec launcher, before workload `execve`.
- `S`: post-start probe, before readiness or a conformance claim.
- `U@B`: unsupported alternative rejected while building the target member.

### Manifest projections

- `P-CAN`: canonical common Artifact value or explicit absence.
- `P-BUILD`: member content identities, digests, and sealed construction plan.
- `P-REQ`: required capability/protocol plus builder-produced support/evidence
  references.
- `P-SLOT`: value-free slot contract; no host/provider binding.
- `P-EFF`: runtime binding only in redacted effective configuration/evidence,
  never the Artifact manifest.

### Default-suppression classes

- `D0`: no target/profile/backend fallback.
- `DENV`: no inherited environment, PATH, cwd, entrypoint, shell, or setup FD.
- `DFS`: no host root/store, try-mount, mount precedence, mode, writable-layer,
  or path-string default.
- `DNET`: no host netns, resolver, port, endpoint, or socket inheritance.
- `DRES`: no cgroup `max`, relative weight-as-ceiling, or
  cgroup-namespace-as-limit.
- `DID`: no host account/group/mapping or setuid Bubblewrap fallback.
- `DSEC`: no default capabilities, devices, seccomp, namespace "try", or raw
  arguments.
- `DLIFE`: no parent-death, signal, snapshot, or operation default.
- `DSECRET`: no secret value/provider/store/log/default-environment projection.

### Evidence classes

- `E-M`: manifest parse, exact 81-by-profile expansion, identity/digest, and no
  author-minted support.
- `E-A/F`: pinned binary/build-mode and exact argv goldens; mountinfo/statfs
  plus host-path/read/write/ordering probes.
- `E-P`: argv, cwd, environment, setup-FD, and activation probes.
- `E-ID/S`: UID/GID maps, groups, NNP, capabilities, namespace, seccomp,
  terminal, and device probes.
- `E-N`: netns identity plus positive/negative egress, DNS, ingress, and
  host-channel probes.
- `E-R`: cgroup controller/effective-value/full-tree and exhaustion probes.
- `E-K`: secret absence, audience, permissions, expiry, and cleanup probes.
- `E-L/O`: lifetime, child cleanup, optional-operation, and output-collection
  probes.

## Auditable 81-Field Mapping

### Builder, process, workspace, and identity

| Rule | Explicit field IDs | Realization and unsupported cases | Earliest to deadline; owner | Projection; defaults; evidence |
|---|---|---|---|---|
| G01 | `artifact.profile.selection`, `artifact.profile.expansion`, `artifact.profile.compositionPaths`, `artifact.metadata.descriptive`, `artifact.workspace.runtimeTransferExclusion`, `artifact.provenance.requirements`, `artifact.provenance.profile`, `artifact.provenance.native`, `artifact.provenance.semanticIdentity`, `artifact.provenance.builtIdentities`, `artifact.targets.enabled`, `artifact.targets.runtimeProfiles`, `artifact.targets.commonContract`, `artifact.targets.nativeConstruction`, `artifact.targets.memberConstruction`, `artifact.targets.artifactSet` | Conforming `preserved-no-emission`/manifest-only facts. Builder validates, hashes, and relates them; there is no Bubblewrap argument. Profile support and verified provenance remain builder claims, never author assertions. | `B` to member publication; builder | `P-CAN + P-REQ`; `D0`; `E-M` |
| G02 | `artifact.platform.workload`, `artifact.environment.packages`, `artifact.environment.devShell`, `artifact.filesystem.immutableInputs` | Builder constructs Linux-compatible closure/content and a sealed read-only mount plan; driver uses immutable store paths or FD-pinned `--ro-bind-fd`. `U@B` for non-Linux, incompatible architecture without a registered emulator profile, unresolved/current-host input, or missing closure. `--[ro-]bind-fd` was added specifically to prevent source-path TOCTOU. [v0.10 release](https://github.com/containers/bubblewrap/releases/tag/v0.10.0) | `B` to `D`/pre-exec; builder to driver | `P-BUILD + P-REQ`; `DFS`; `E-M + E-A/F` |
| G03 | `artifact.environment.variables`, `artifact.environment.searchPath`, `artifact.environment.ambientExclusion`, `artifact.process.environment` | Builder records the closed map; driver emits `--clearenv`, then exact `--setenv` values, including explicit PATH and PWD. Bubblewrap's `--clearenv` preserves PWD, so it must be overwritten or removed explicitly. [v0.11.2 manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml) | `B` to `D`/pre-exec; builder to driver | `P-CAN`; `DENV`; `E-P` |
| G04 | `artifact.environment.activation` | Build verifies each executable identity. An owned argv-only launcher runs the sequence under final isolation, in order, without a shell, and fails closed before the main process. `U@B` for a required activation semantic the launcher cannot preserve. | `B` to `D`/before main exec; builder to driver | `P-BUILD` with ordered argv/executable identities; `DENV`; `E-P` |
| G05 | `artifact.process.argv`, `artifact.process.cwd`, `artifact.process.omission` | Presence/absence remains exact. Create must provide any runtime-required missing command/cwd; driver uses direct `execve`-style argv and `--chdir`. It must not permit Bubblewrap's HOME/current-directory fallback or an image/backend entrypoint. [v0.11.2 manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml) | `B` to `C` to `D`/pre-exec; builder to Create to driver | `P-CAN`, resolved value in `P-EFF`; `DENV`; `E-P` |
| G06 | `artifact.workspace.slot`, `artifact.workspace.destination`, `artifact.workspace.access`, `artifact.workspace.materializations`, `artifact.workspace.required`, `artifact.requirements.workspace` | Builder proves profile/materialization compatibility. Create selects a permitted materialization and binding; preflight safely opens/materializes it; driver uses `--bind-fd`/`--ro-bind-fd` or an owned copy-in tree. Mandatory unsupported materialization is `U@B`; an incompatible concrete binding fails at Create. An immutable image requires a registered pre-mounter because Bubblewrap does not mount image formats itself. | `B` to `C` to `O/P` to `D` to `S`/ready; all corresponding owners | `P-SLOT + P-REQ`; binding only `P-EFF`; `D0 + DFS`; `E-M + E-A/F` |
| G07 | `artifact.filesystem.mountSlots`, `artifact.filesystem.volumeSlots`, `artifact.resources.volumeCapacity` | Slot support is conforming; Create binds an allowed source, preflight pins it by FD and proves capacity when required, then driver mounts it. A hard volume maximum requires a quota/preallocated-filesystem mechanism; an arbitrary host directory cannot satisfy it. Unsupported source/capacity classes are `U@B`; incompatible bindings fail at Create/preflight. | `B` to `C` to `O/P` to `D` to `S`; builder to Create to operator/preflight to driver/post-start | `P-SLOT + P-REQ`, runtime source only `P-EFF`; `DFS + DRES`; `E-A/F + E-R` |
| G08 | `artifact.workspace.protectedPaths`, `artifact.filesystem.topology` | Builder produces one conflict-free ordered mount graph. Driver emits masks and read-only mounts after the parent workspace mount. Bubblewrap applies filesystem operations in argv order, and `--remount-ro` affects only one mount point, not submounts, so recursive protection must be compiled explicitly. [v0.11.2 manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml) | `B` to `D` to `S`; builder to driver to post-start | `P-BUILD` topology digest; `DFS`; `E-A/F` |
| G09 | `artifact.workspace.ownership`, `artifact.process.identity`, `artifact.identity.user`, `artifact.identity.groups`, `artifact.identity.hostMappingExclusion` | A single workload UID/GID with no supplementary groups lowers through strict user namespace creation plus `--uid`/`--gid`. Multiple selectable users or non-empty supplementary groups require a precreated mapped user namespace and owned identity launcher; otherwise `U@B` for the base profile. Actual host mappings remain preflight facts. Linux UID/GID maps are one-write mappings, and unprivileged `gid_map` setup commonly requires permanently disabling `setgroups`; this cannot be inferred from passwd/group content. [user_namespaces(7)](https://www.man7.org/linux/man-pages/man7/user_namespaces.7.html) | `B` to `O/P` to `D` to `S`; builder to preflight to driver/post-start | `P-CAN + P-REQ`, never host maps; `DID`; `E-ID/S` |

### Filesystem, network, resources, and security

| Rule | Explicit field IDs | Realization and unsupported cases | Earliest to deadline; owner | Projection; defaults; evidence |
|---|---|---|---|---|
| G10 | `artifact.filesystem.scratch`, `artifact.resources.tmpfsCapacity` | Direct conforming lowering: explicit `--size BYTES --perms MODE --tmpfs DEST`; `--size` is a maximum for only the immediately following tmpfs. Minimum capacity is admission/preflight; maximum is driver-enforced. [v0.11.2 manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml) | `B` to `O/P` to `D` to `S`; builder to preflight to driver/post-start | `P-CAN + P-REQ`; `DFS + DRES`; `E-A/F + E-R` |
| G11 | `artifact.filesystem.writableRoot`, `artifact.resources.writableRootCapacity`, `artifact.security.rootFilesystem` | Immutable root is conforming: assemble the graph, then explicitly remount the root mount read-only while leaving declared writable submounts. Baseline `bubblewrap-linux-v1` should mark bounded private-writable-root `U@B`: Bubblewrap's internal root tmpfs has no size option, and `--size` does not apply to `--tmp-overlay`. A later profile can support it with a quota-backed/preallocated overlay upperdir. | `B` to `D` to `S`; builder to driver/post-start. Optional extension also adds `O/P`. | `P-CAN + P-REQ`; `DFS + DRES`; `E-A/F` |
| G12 | `artifact.network.access`, `artifact.network.egress`, `artifact.network.dns`, `artifact.network.ingressPorts`, `artifact.network.credentialSlots`, `artifact.network.hostChannels` | `none` lowers to strict `--unshare-net`. Unrestricted or controlled egress requires the owned launcher to enter a prepared network namespace before Bubblewrap; controlled rules, ingress/NAT, and DNS enforcement live in operator/preflight components. Resolver content is synthetic `--ro-bind-data`, not host `/etc/resolv.conf`. Host channels require a registered broker/proxy; direct D-Bus/socket binding is not conforming by default because upstream warns any mounted channel can enable privilege escalation. [README limitations](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/README.md), [network_namespaces(7)](https://www.man7.org/linux/man-pages/man7/network_namespaces.7.html) | `B` to `C` to `O/P` to `D` to `S`; all corresponding owners | `P-CAN + P-SLOT + P-REQ`; endpoints/bindings only `P-EFF`; `DNET`; `E-N + E-K` |
| G13 | `artifact.resources.cpuConcurrency`, `artifact.resources.cpuRate`, `artifact.resources.memoryTotal`, `artifact.resources.swap`, `artifact.resources.tasks` | Conforming through an outer cgroup v2 created before Bubblewrap: cpuset for concurrency, `cpu.max` for absolute rate, `cpu.weight` only for relative weight, `memory.max`, `memory.swap.max`, and `pids.max`. Minimums are admission facts; hard maxima are controller settings. Post-start must prove the complete Bubblewrap/reaper/workload tree is contained. Linux documents `cpu.max`, `memory.max`, swap, and PIDs as explicit controllers; default `max` is no limit. [cgroup v2](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html) | `B` to `O/P` to `D` to `S`; builder to operator/preflight to driver/post-start | `P-CAN + P-REQ`; effective cgroup only `P-EFF`; `DRES`; `E-R` |
| G14 | `artifact.resources.memoryWorkload` | `U@B` for the baseline profile. The strategy's single outer cgroup proves total Sandbox memory, not a separate workload-only ceiling excluding Bubblewrap/supervisor overhead. A later extension needs a nested workload cgroup and a race-free pre-exec placement handshake. | `B/B`; builder | `P-CAN + explicit unsupported diagnostic`; `DRES`; unsupported fixture |
| G15 | `artifact.resources.io` | `U@B` by default. cgroup v2 `io.max` is keyed by block-device major/minor, not logical mount path; it cannot independently bound two logical resources sharing one backing device. A later profile may accept only dedicated, preflight-resolved backing devices. [cgroup v2 `io.max`](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html) | `B/B`; builder. Conditional extension adds `O/P` to `S`. | `P-CAN + P-REQ`; `DRES`; unsupported fixture or `E-R` for dedicated-device extension |
| G16 | `artifact.security.noNewPrivileges` | Required NNP is conforming: Bubblewrap 0.11.2 sets `PR_SET_NO_NEW_PRIVS` before parsing arguments. A semantic that actually requires privilege-gaining exec transitions is `U@B`; there is no flag to turn NNP off. Linux says NNP is inherited across fork/exec and prevents exec from granting privilege. [Bubblewrap source](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bubblewrap.c), [Linux NNP documentation](https://docs.kernel.org/userspace-api/no_new_privs.html) | `B` to `D` to `S`; builder to driver/post-start | `P-CAN + P-REQ`; `DSEC`; `E-ID/S` |
| G17 | `artifact.security.capabilities` | Builder validates exact set relations. Bubblewrap supplies an outer ceiling through canonical `--cap-drop ALL` plus ordered `--cap-add`; an owned fail-closed launcher then sets the exact bounding/permitted/effective/inheritable/ambient sets. Without that launcher, only Bubblewrap's equal-set shape is representable. `U@B` for a relationship impossible under userns plus NNP. Post-start must inspect every set because Bubblewrap source ignores `EINVAL`/`EPERM` while attempting ambient raises. [Bubblewrap capability source](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bubblewrap.c), [capabilities(7)](https://www.man7.org/linux/man-pages/man7/capabilities.7.html) | `B` to `O/P` to `D` to `S`; builder to preflight to driver/post-start | `P-CAN + P-REQ`; `DSEC`; `E-ID/S` |
| G18 | `artifact.security.kernelPolicies` | Registered filesystem/namespace policies compile into the sealed mount/namespace plan; syscall policies compile per architecture to cBPF and are passed through `--seccomp`/`--add-seccomp-fd`. Multiple filters have ordering and `PR_SET_SECCOMP` compatibility constraints. Unsupported policy identity, strength, or architecture is `U@B`; kernel support fails preflight. Seccomp requires NNP or appropriate capability and does not dereference syscall pointer arguments. [Bubblewrap manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml), [Linux seccomp](https://docs.kernel.org/userspace-api/seccomp_filter.html) | `B` to `O/P` to `D` to `S`; builder to preflight to driver/post-start | `P-CAN + filter digest/arch + P-REQ`; `DSEC`; `E-ID/S` |
| G19 | `artifact.security.devices` | The profile must enumerate its minimal pseudo-device set rather than inherit `/dev`. Extra logical devices require operator allocation, stable root-owned host nodes, projected capability/seccomp/policy edits, and explicit `--dev-bind`; unsupported or non-isolatable classes are `U@B`/Create rejection. Bubblewrap distinguishes ordinary binds, mounted `nodev` by default, from `--dev-bind` that permits device access. [Bubblewrap manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml) | `B` to `C` to `O/P` to `D` to `S`; all corresponding owners | `P-CAN + P-REQ`, live device identity only `P-EFF`; `DSEC`; `E-ID/S` |

### Secrets, requirements, lifecycle, and outputs

| Rule | Explicit field IDs | Realization and unsupported cases | Earliest to deadline; owner | Projection; defaults; evidence |
|---|---|---|---|---|
| G20 | `artifact.secretSlots.identity`, `artifact.secretSlots.delivery`, `artifact.secretSlots.destination`, `artifact.secretSlots.audienceLifetime` | Builder emits value-free contracts; Create binds a secret; preflight opens a sealed FD. File delivery uses explicit `--perms` plus `--ro-bind-data` into ephemeral namespace storage; environment delivery uses explicit `--setenv`; credential delivery needs the owned FD/broker launcher. Bubblewrap defaults `--file` to mode 0666 and bind-data to 0600, so the driver must never rely on either default. Audience narrower than the complete inheriting process tree, or expiry earlier than enforceable process termination/revocation, is rejected. [Bubblewrap manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml) | `B` to `C` to `O/P` to `D` to `S`; all corresponding owners | `P-SLOT + P-CAN`; value/provider only redacted `P-EFF`; `DSECRET + DENV`; `E-K` |
| G21 | `artifact.secretSlots.snapshotTreatment`, `artifact.lifecycleRequirements.snapshot` | Snapshot requirement is `U@B` for baseline `bubblewrap-linux-v1`; Bubblewrap has no process/memory/device snapshot protocol. Snapshot-treatment metadata is still preserved when the Artifact does not require snapshot support, preventing a later profile from silently capturing secrets. | `B/B`; builder | `P-CAN + explicit unsupported profile relation`; `DLIFE + DSECRET`; unsupported fixture |
| G22 | `artifact.requirements.capabilities`, `artifact.requirements.protocols`, `artifact.requirements.enforcement` | Builder resolves dependencies and checks every mandatory requirement against the versioned profile registry and conformance record. Unsupported mandatory requirement is `U@B`; optional capabilities remain explicitly unclaimed. Runtime load re-verifies support/evidence versions. | `B` to manifest load to `S`; builder to runtime resolver/post-start | `P-REQ`; `D0`; `E-M` plus referenced class evidence |
| G23 | `artifact.lifecycleRequirements.maximumLifetime`, `artifact.lifecycleRequirements.maximumLifetimeEnforcement` | Builder records the immutable ceiling; Create computes a no-later-than expiration; supervisor starts the already-cgrouped process with a monotonic timer, terminates the complete tree, and records enforcement. `--die-with-parent` is defense-in-depth only, not a TTL. [Bubblewrap manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml) | `B` to `C` to `D` to `S`/termination; builder to Create to driver/post-start supervisor | Artifact ceiling `P-CAN`; resolved deadline only `P-EFF`; `DLIFE`; `E-L/O` |
| G24 | `artifact.lifecycleRequirements.optionalOperations` | Builder accepts only operations in the profile's tested whitelist. PTY requires driver-managed PTY/session behavior; pause/resume may use a proven `cgroup.freeze` implementation. Fork/checkpoint/snapshot/resize or any unproven operation is `U@B`. `--new-session` protects against terminal injection but disconnects the controlling terminal, so it is not itself PTY support. [README TIOCSTI limitation](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/README.md) | `B/B` for support; runtime operation handled by driver/post-start | `P-REQ`; `DLIFE + DSEC`; `E-ID/S + E-L/O` |
| G25 | `artifact.outputs.declarations`, `artifact.outputs.filesystemCompatibility` | Builder validates exact paths against the filesystem graph; driver merely preserves those writable paths. No glob, automatic existence, selection, export, or retention semantics are added. Post-run probes verify paths did not cross protected/secret/immutable mounts. | `B` to `D` to `S`; builder to driver/post-start | `P-CAN + topology relation`; `DFS`; `E-A/F + E-L/O` |
| G26 | `artifact.outputs.runtimeCollection` | Manifest-only eligibility. A later typed runtime request selects outputs; driver/post-start collector captures them under operator bounds. Declaration never implies automatic collection, destination, timing, or retention. | `B` to post-process collection; builder to driver/operator/post-start | `P-CAN`; selection/destination only `P-EFF`; `DLIFE`; `E-L/O` |

Coverage cross-check: `81` ledger IDs mapped, `81` occurrences, no omissions,
unknown IDs, or duplicates.

## Backend Defaults That Must Be Sealed Out

The most important Bubblewrap-specific suppressions are:

- Never compile a conforming profile with `--unshare-all`: in 0.11.2 it
  expands to `--unshare-user-try` and `--unshare-cgroup-try`, which are
  explicitly fail-open. Emit each required strict namespace operation
  separately. [v0.11.2
  manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml)
- Never use `--bind-try`, `--ro-bind-try`, or `--dev-bind-try` for required
  resources.
- Never inherit the caller's network namespace for "unrestricted egress";
  enter a prepared sandbox netns first and prove its namespace identity.
- Never inherit environment, PATH, HOME-derived cwd, command, standard-image
  entrypoint, supplementary groups, open setup FDs, resolver files, `/proc`,
  `/sys`, `/dev`, or host `/nix/store`.
- Never treat `--unshare-cgroup` as resource enforcement. Linux defines
  cgroup namespaces as virtualizing the view; no implicit cgroup migration
  occurs. [cgroup v2 namespace
  documentation](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)
- Never treat Bubblewrap defaults--no capabilities, file modes,
  parent-directory modes, tmpfs size, root tmpfs, PID1 behavior--as product
  semantics. Emit and probe the required state.
- Never use `--as-pid-1` unless the workload-facing PID1/reaping/signal
  contract is explicitly proven. Bubblewrap normally provides its own minimal
  reaper. [v0.11.2
  manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml)

## Genuinely New Packet C Invalid States

The three Packet C research inputs expose field-local IDs but not the full
`invariants.json` definitions, so these should receive provisional Packet C
IDs and then undergo the Task 6 exact-registry comparison. They are not
represented by a current field-attached invariant in the Packet B ledger.

| Provisional ID | New invalid state | First sound phase / deadline / owner |
|---|---|---|
| `BWP-001` | Profile identity matches `v0.11.2`, but the runtime executable was built with setuid support or has the setuid bit. Version comparison alone cannot distinguish this security-relevant build variant. [v0.11.2 release](https://github.com/containers/bubblewrap/releases/tag/v0.11.2) | `O/P`; before launch; preflight |
| `BWP-002` | Create/preflight validates a host source by pathname, then the driver passes `--bind SRC`/`--ro-bind SRC`; an attacker replaces an ancestor or final object before Bubblewrap opens it. Upstream added FD binds specifically to avoid this TOCTOU. [v0.10 release](https://github.com/containers/bubblewrap/releases/tag/v0.10.0) | `O/P` to `D`; before argv handoff; preflight/driver |
| `BWP-003` | Namespace, seccomp, secret, status, or synchronization FD aliases stdin/stdout/stderr or is unintentionally inherited into the workload. Upstream 0.11.1 explicitly recommends FDs at least 3 because 0/1/2 are inherited by the command. [release history](https://github.com/containers/bubblewrap/releases) | `D`; before exec; driver |
| `BWP-004` | Driver accepts Bubblewrap exit/start success as proof that a requested ambient capability was installed, although Bubblewrap ignores `EINVAL`/`EPERM` when raising ambient capabilities. [v0.11.2 source](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bubblewrap.c) | `O/P + S`; before readiness; preflight/post-start |
| `BWP-005` | Compiler emits `--as-pid-1` without a profile/workload contract proving zombie reaping, signal forwarding, shutdown, and exit-status semantics. | `B` to `D`; before member support claim and exec; builder/driver |
| `BWP-006` | Runtime overlay sources/upper/work directories become ancestors of one another after symlink resolution; upstream documents resulting overlayfs behavior as undefined on kernels that do not reject it. [v0.11.2 manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml) | `C/O/P`; before driver launch; Create/preflight |

Concrete target witnesses that should reuse existing IDs rather than mint new
ones include:

- fail-open `--unshare-all` or `*-try`: `TGT-004`, `TGT-006`, `DRV-001`,
  `SEC-002`;
- ambient environment/PATH/cwd/entrypoint fallback: `XRS-012`, `XRS-013`,
  `XRS-014`, `MAN-004`;
- inherited host network/resolver/channel: `NET-001`, `NET-002`;
- cgroup namespace or weight presented as a hard bound: `RES-001`, `RES-002`,
  `DRV-001`;
- total memory presented as workload-only memory: `RES-001`, `RES-002`;
- distinct capability sets collapsed to a single set: `SEC-001`, `TGT-004`;
- later mount shadowing a protected/immutable path: `XRS-020`;
- default secret mode or immutable-path secret delivery: `SCT-001`,
  `SCT-002`.

## Contradictions and Under-Specification in the Current Documents

- The strategy requires exact dependency locks but cites moving Bubblewrap
  `main`. `main` now declares `0.12.0`, while the latest release is `0.11.2`;
  Packet C must cite an exact tag/commit and build-feature digest.
- "Construct namespaces explicitly" and "fail closed" are correct, but the
  documents do not explicitly prohibit `--unshare-all`, whose user/cgroup
  components are try/fallback operations.
- "Add runtime paths after host-path resolution" is insufficient. Path
  validation must produce and retain an FD through mount lowering; otherwise
  there is a TOCTOU gap.
- The single outer cgroup design can prove total Sandbox bounds but cannot
  prove `artifact.resources.memoryWorkload`. That field must be explicitly
  unsupported in the baseline profile.
- The strategy allows a bounded writable root conceptually, but Bubblewrap's
  internal root and `--tmp-overlay` do not accept `--size`; a quota-backed
  overlay component is required or the alternative must be build-time
  unsupported.
- Bubblewrap's `--uid`/`--gid` do not realize arbitrary supplementary-group
  or multi-user identity contracts. The profile needs a mapped-userns/launcher
  extension or explicit build-time rejection.
- Bubblewrap's native capability flags do not independently express the five
  declared sets, and ambient installation may fail without a hard error. Exact
  realization needs an owned launcher plus post-start proof.
- "Defined PTY behavior" needs a concrete driver contract. `--new-session`
  prevents TIOCSTI-style terminal injection but intentionally disconnects the
  controlling terminal.
- Secret lowering must mandate explicit modes and lifetime compatibility;
  `--file` defaults to 0666.
- The jail.nix boundary in the strategy is accurate. Its upstream docs state
  that `Permission` is `State -> State` with private `State`, and expose
  arbitrary runtime shell, environment/path expansion, raw Bubblewrap
  arguments, reset of base permissions, and host namespace sharing. [jail.nix
  combinators](https://alexdav.id/projects/jail-nix/combinators/), [advanced
  configuration](https://alexdav.id/projects/jail-nix/advanced-configuration/)

## Recommendations

1. Define `bubblewrap-linux-v1` as an exact multi-component profile; pin
   Bubblewrap `v0.11.2`/`1b80120ef26a28e065e67f89bfef873f13bdd317`,
   non-setuid build, companion protocol versions, minimum kernel capabilities,
   and conformance-suite version.
2. Make the baseline unsupported set explicit: non-Linux/foreign architecture
   without an emulator; separate workload-memory bound; bounded private
   writable root; arbitrary path-scoped I/O; snapshot; unproven optional
   operations; and unsupported identity/capability/device/channel shapes.
3. Compile from a sealed typed mount graph to an argv vector without a shell.
   Ban raw args, all `*-try`, `--unshare-all`, host-root binds, and hidden
   profile fragments.
4. Resolve dynamic filesystem sources with an FD-safe opener and use
   `--[ro-]bind-fd`; record only redacted source identity/evidence.
5. Start Bubblewrap already inside its final outer cgroup and, for
   egress-enabled modes, its final prepared network namespace. Do not
   move/configure the workload after execution begins.
6. Use a small owned pre-exec launcher for exact capability sets, activation,
   identity, and secret-FD semantics; close every non-contract FD and fail on
   every kernel-operation error.
7. Gate support claims on real negative/positive probes. A successful build,
   successful Bubblewrap start, or green argv golden is not isolation
   evidence.

## Sources and Revision Ledger

- [Bubblewrap v0.11.2
  release](https://github.com/containers/bubblewrap/releases/tag/v0.11.2) -
  2026-04-23, commit
  `1b80120ef26a28e065e67f89bfef873f13bdd317`
- [Bubblewrap v0.11.2 manual
  source](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml)
- [Bubblewrap v0.11.2
  README](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/README.md)
- [Bubblewrap v0.11.2 security
  policy](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/SECURITY.md)
- [Bubblewrap v0.11.2
  implementation](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bubblewrap.c)
- [Bubblewrap releases](https://github.com/containers/bubblewrap/releases)
- [Linux user
  namespaces](https://www.man7.org/linux/man-pages/man7/user_namespaces.7.html)
- [Linux
  capabilities](https://www.man7.org/linux/man-pages/man7/capabilities.7.html)
- [Linux PID
  namespaces](https://www.man7.org/linux/man-pages/man7/pid_namespaces.7.html)
- [Linux network
  namespaces](https://www.man7.org/linux/man-pages/man7/network_namespaces.7.html)
- [Linux
  no-new-privileges](https://docs.kernel.org/userspace-api/no_new_privs.html)
- [Linux seccomp filter
  API](https://docs.kernel.org/userspace-api/seccomp_filter.html)
- [Linux cgroup
  v2](https://www.kernel.org/doc/html/latest/admin-guide/cgroup-v2.html)
- [jail.nix combinators, revision
  `404e7da9`](https://alexdav.id/projects/jail-nix/combinators/)
- [jail.nix revision
  commit](https://git.sr.ht/~alexdavid/jail.nix/commit/404e7da9da5ab9aa643666682b2ba1312fa5fbe8) -
  2026-04-15

Linux `latest` pages are moving upstream documentation accessed 2026-07-24;
the rendered man-pages corpus identifies release 6.18/fetch date 2026-05-24
on its current pages. Packet C should pin required kernel behavior/minimum
versions rather than treating those moving URLs as target identity.
