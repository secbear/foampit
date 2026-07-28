# Packet C Target Realization Research Notes

Status: **Reconciled**

Date: 2026-07-24

These notes record primary-source facts and Packet C consequences. They do not
define a second schema. Normative invalid and valid states belong in the
executable corpus, registry traceability belongs in `invariants.json`, and the
machine-checkable target classification belongs in
`PACKET-C-TARGET-REALIZATION.json`.

## Research method

- Upstream specifications, project documentation, APIs, and source are primary.
- Product consequences are explicitly marked as design inferences.
- Artifact requirements, builder facts, operator mappings, provider facts, and
  observed runtime evidence remain distinct.
- Every mechanism-specific fact is mapped to a Packet B field or rejected as
  outside Artifact ownership.
- Current provider behavior informs adapters and unsupported outcomes; it never
  becomes the portable schema.

## Bubblewrap

The complete 81-field source review, exact upstream pin, lowering/default
classes, evidence obligations, invalid states, contradictions, and sources are
preserved in
[Packet C Bubblewrap Research](./PACKET-C-BUBBLEWRAP-RESEARCH.md).

### Primary facts

Bubblewrap is a low-level isolation construction tool. It always creates a new
mount namespace, but the caller's argument vector determines the filesystem,
namespace, capability, process, device, and seccomp policy. Bubblewrap does not
itself define network policy, cgroup limits, lifecycle deadlines, provenance,
or product conformance:

- [Bubblewrap v0.11.2 README](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/README.md)
- [Bubblewrap v0.11.2 manual](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bwrap.xml)
- [Bubblewrap v0.11.2 implementation](https://raw.githubusercontent.com/containers/bubblewrap/v0.11.2/bubblewrap.c)

The reviewed implementation is Bubblewrap `v0.11.2`, commit
`1b80120ef26a28e065e67f89bfef873f13bdd317`, released 2026-04-23. The profile
requires a non-setuid build and rejects an installed executable carrying the
setuid bit. Version equality alone is insufficient because build features and
file mode alter the security boundary:

- [Bubblewrap v0.11.2 release](https://github.com/containers/bubblewrap/releases/tag/v0.11.2)

Bubblewrap 0.11.2 `--unshare-all` expands through try/fallback user and cgroup
namespace behavior, and the manual also exposes `--bind-try`,
`--ro-bind-try`, and `--dev-bind-try`. Required isolation must use individually
emitted strict operations; none of those operations is conforming for a
mandatory resource. Dynamic mount sources must remain safely resolved by file
descriptor through mount setup, using the FD bind facilities added to close
source-path replacement races.

### Packet C consequences

`bubblewrap-linux-v1` denotes this complete versioned bundle:

1. a pinned non-setuid Bubblewrap executable;
2. an owned typed mount-graph and argv compiler;
3. an owned non-shell pre-exec launcher for identity, capabilities,
   activation, and secret descriptors;
4. an FD-safe path resolver;
5. a cgroup v2 and complete-process-tree supervisor;
6. a network namespace/policy/DNS/ingress/channel broker;
7. a secret broker; and
8. a post-start evidence collector and conformance suite.

The baseline explicitly does not advertise a separate workload-memory bound,
bounded private writable root, generic logical-path I/O throttling, snapshots,
or identity/capability/device/channel shapes the bundle cannot install exactly.
An outer cgroup can prove total Sandbox memory but not workload-only memory.
Bubblewrap's private root tmpfs and tmp-overlay cannot prove the Artifact's hard
writable-root capacity without a separately registered quota-backed extension.

`jail.nix` remains useful prior art but not the product compiler. Its private
state, runtime environment/path expansion, arbitrary host-side shell, raw
Bubblewrap arguments, and base-permission replacement prevent the product from
proving the same typed cross-target contract:

- [jail.nix combinators at revision `404e7da9`](https://alexdav.id/projects/jail-nix/combinators/)
- [jail.nix revision](https://git.sr.ht/~alexdavid/jail.nix/commit/404e7da9da5ab9aa643666682b2ba1312fa5fbe8)

## microVM targets

The complete 81-field Firecracker/Cloud Hypervisor review, authorities,
manifest projections, target defaults, evidence mapping, candidate invalid
states, contradictions, recommendations, and 47 primary sources are preserved
in [Packet C microVM Research](./PACKET-C-MICROVM-RESEARCH.md).

### Reviewed revisions

- microvm.nix:
  `fa5340ac684cdce8a22b6d4a0bcebb0cc999275e`
- Firecracker:
  `c1490c7983644f68facfc267c20156546e81bd4f`
- Cloud Hypervisor:
  `aa19811139aeab74baf7065784b24fd66f6e32e2`
- virtiofsd:
  release `v1.14.0`, commit
  `c2540f8db14caba81c1e37fba23fc7bf2cd7f0dd`
  ([release](https://gitlab.com/virtio-fs/virtiofsd/-/releases/v1.14.0))

These are research snapshots, not permission for an operator to choose a
different implementation silently. Production registrations must identify the
exact selected builds and pass the profile conformance suites.

### Research-to-product phase crosswalk

The detailed source reports used compact research phase names before Packet
C's product phase vocabulary was finalized. They map exactly as follows:

| Research phase | Product phase |
|---|---|
| Bubblewrap `B` | `N0`/`N1` |
| Bubblewrap `C` | `C0` |
| Bubblewrap `O` | `O0` |
| Bubblewrap `P` | `H0` |
| Bubblewrap `D` | `D0` |
| Bubblewrap `S` | `R1` |
| microVM `B` | `N0`/`N1` |
| microVM `ML` | `C0` manifest load |
| microVM `C` | `C0` Create resolution |
| microVM `O` | `O0` |
| microVM `P` | `H0` |
| microVM `D` | `D0` |
| microVM `R` | `R1` |

For an `observed-conformance` case, `firstSoundPhase` means the first phase
that can soundly classify the requirement into the observed path and begin
its obligations. It does not mean conformance is already true. Only the
declared `R1` authority and post-start probe can establish that outcome.

### microvm.nix boundary

The product can cleanly reuse a pinned microvm.nix adapter to build guest
kernel, initrd, system closure, immutable filesystem images, boot parameters,
and guest runtime. It cannot reuse the full option tree or generated runner as
the product contract:

- the Firecracker runner rejects shares, invokes Firecracker directly instead
  of through jailer, and supplies serial-console behavior;
- the Cloud Hypervisor runner permits raw extra arguments and owns a different
  virtiofsd supervision model;
- upstream assertions catch useful local inconsistencies but leave several
  product requirements as warnings or runner-time errors.

The owned final-config validator therefore rejects host shares, host paths,
interfaces, forwarding, credentials, pre-start scripts, runtime argument
scripts, raw VMM arguments/configuration, OEM strings, and other runtime state
even when an upstream option can represent them.

### Firecracker profile

The initial Firecracker profile requires:

- exact Firecracker and jailer builds;
- cgroup v2 with explicit parent and parameters;
- explicit UID/GID and PID/mount/network namespaces;
- no live host-directory sharing;
- no MMDS, passthrough, undeclared pmem/hotplug/device behavior, or unbounded
  serial output;
- registered block, network, vsock, and entropy devices only;
- separate outer VMM and guest workload resource accounting; and
- an exact snapshot component and compatibility envelope.

Workspace materialization is copy-in or prepared block. Firecracker snapshot
APIs capture memory and VMM state while disks remain externally managed, so
they do not imply filesystem-inclusive, secret-excluding, clone-safe, or
portable-host snapshots. Clone/restore additionally requires identity,
entropy, token, network, TAP, and vsock refresh.

### Cloud Hypervisor profile

The initial Cloud Hypervisor profile requires:

- exact Cloud Hypervisor and virtiofsd builds;
- an outer UID/mount/PID/network namespace and cgroup boundary;
- fail-closed seccomp and Landlock admission, without claiming that Landlock
  isolates AF_UNIX;
- `nested=false`;
- an explicit unavoidable plus requested device baseline;
- no raw arguments, OEM credentials, passthrough, undeclared console/debug, or
  helper sockets; and
- exact-build snapshot compatibility until executable evidence proves a wider
  envelope.

Live virtiofs is supported only when shared memory, safe source resolution,
helper confinement/accounting, ownership translation, and read-only/read-write
conformance all pass. `virtiofsd` is part of the runtime profile bundle, not an
incidental helper.

### Shared microVM consequences

VMM network devices do not implement portable egress/DNS/ingress policy.
Owned host TAP/network-namespace/firewall/proxy enforcement and guest
configuration remain required. VMM memory sizing does not by itself prove
total Sandbox or workload-only memory bounds. Directional storage I/O support
is advertised only for exact representable dimensions with dedicated,
verified device attribution.

Secrets enter through authenticated guest-runtime/vsock channels into guest
tmpfs or exec-time delivery; they never enter guest images, Nix store content,
MMDS, OEM strings, or VMM configuration. Snapshot operations are rejected
while a `forbid capture` secret is resident unless a proven quiesce/scrub
protocol completes.

Firecracker and Cloud Hypervisor normally receive distinct member manifests
even when kernel, initrd, store, or root blobs are byte-identical. Their hard
runtime requirements differ in device baseline, workspace support,
jailer/helper boundary, snapshot compatibility, and driver protocol. Content
blobs may deduplicate; member identity and support facts may not collapse.

## OCI image, distribution, and runtime

### Primary facts

The OCI Image Configuration describes immutable image content plus execution
defaults. Its `Env`, `Entrypoint`, `Cmd`, `WorkingDir`, `User`, `Volumes`, and
related execution values act as defaults and may be replaced when a container
is created. Changing the image JSON changes its content identity:

- [OCI Image Configuration](https://specs.opencontainers.org/image-spec/config/)

The OCI Runtime Specification consumes a bundle containing `config.json` and a
root filesystem. That runtime configuration includes process, mounts, hooks,
and Linux host-specific settings such as namespaces and cgroups. The runtime
must error if it cannot create the specified environment:

- [OCI Runtime Configuration v1.3.0](https://specs.opencontainers.org/runtime-spec/config/?v=v1.3.0)
- [OCI Linux Runtime Configuration v1.3.0](https://specs.opencontainers.org/runtime-spec/config-linux/?v=v1.3.0)
- [OCI Runtime and Lifecycle v1.3.0](https://specs.opencontainers.org/runtime-spec/runtime/?v=v1.3.0)

The Linux configuration provides mechanisms for namespaces, cgroups,
capabilities, LSM labels, devices, device access, seccomp, masked/read-only
paths, UID/GID mappings, and other host-specific controls. Several omitted
fields deliberately allow runtime defaults, including cgroup placement.
Lifecycle hooks execute external programs in runtime or container namespaces
at defined phases.

OCI Distribution transfers content-addressed manifests, descriptors, and blobs.
Clients fetching by digest are expected to verify returned content. The
referrers mechanism can associate signatures, attestations, SBOMs, or other
typed artifacts with a subject digest:

- [OCI Distribution Specification](https://github.com/opencontainers/distribution-spec/blob/main/spec.md)

### Packet C consequences

1. The OCI target member is an OCI image plus a product-owned Sandbox Artifact
   manifest. Neither alone is sufficient.
2. The product driver generates `config.json` from the validated Artifact,
   Create input, and Operator Configuration. A stored runtime bundle is not the
   reusable portable Artifact.
3. All image execution defaults are neutralized. Present Artifact values are
   emitted exactly; absent Artifact values stay absent and cannot reactivate
   `Entrypoint`, `Cmd`, image environment, user, cwd, volumes, ports, or another
   image default.
4. Conforming v1 emits no OCI lifecycle hook supplied by Artifact or provider
   input. Required helper behavior is product-owned, versioned driver logic.
5. OCI support is a product conformance profile, not a claim that every
   nominally OCI-compatible runtime supplies identical security, networking,
   resource, Exec, snapshot, or evidence behavior.
6. OCI descriptor transfer is a valid provider transport because content can
   be addressed and verified independently. Tags alone are not Artifact
   identities.

## Remote-provider transport

Remote-provider transport is a deployment boundary, not a target family. A
provider may run an OCI member, accept another prebuilt member type, or build a
provider-native image from a source definition. Those are different contracts
and must not share one opaque `deployment` or `environment` input.

### Modal

Modal Sandboxes accept a Modal Image and separately accept environment,
secrets, network filesystems, timeout, CPU/memory, placement, network allowlist,
and other live creation options. Modal can construct images through its own
Python-defined build graph and can reference registry images. It uses
definition/layer caching. Sandboxes and snapshots have provider object IDs;
filesystem and directory snapshots default to finite provider retention unless
the caller explicitly changes it:

- [Modal Images](https://modal.com/docs/guide/images.md)
- [Modal Sandbox API](https://modal.com/docs/sdk/py/latest/modal.Sandbox)
- [Modal Sandbox resources](https://modal.com/docs/guide/sandbox-resources)
- [Modal Sandbox snapshots](https://modal.com/docs/guide/sandbox-snapshots)

Design inference: the clean initial Modal path is a digest-pinned OCI image plus
the product manifest and adapter-side capability checks. Modal's Python image
definition and provider object ID are not substitutes for the portable semantic
digest or member content digest. Provider resource and retention defaults must
be replaced by explicit Create/operator values before a conforming claim.

### E2B

E2B templates are declarative provider build definitions, currently built from
a Dockerfile or template SDK and selected by template identity/alias. Template
builds expose provider CPU/memory defaults, build arguments, and cache controls.
Snapshots are captured live state, distinct from reproducible templates, and
may include filesystem and memory:

- [E2B template CLI](https://e2b.dev/docs/sdk-reference/cli/v2.2.6/template)
- [E2B Sandbox snapshots](https://e2b.dev/docs/sandbox/snapshots)

Design inference: a generated E2B template is provider-side construction, not
prebuilt Artifact transfer. It is conforming only if the adapter consumes a
content-identified product construction request, suppresses provider defaults,
returns a provider artifact identity linked to the requested member, and
supplies sufficient build and runtime evidence. Otherwise it is an explicitly
non-conforming provider-native adapter.

## Provider-neutral transport modes

Packet C reviews three distinct contracts:

1. **Prebuilt member transfer** — transmit a product target member, its
   manifest, content identities, and attestations to a provider that natively
   accepts that member kind.
2. **OCI descriptor transfer** — publish/fetch a digest-addressed OCI image and
   associated product manifest/referrers, then verify both before creation.
3. **Provider-side construction** — send pinned source/construction inputs,
   receive a provider artifact, and verify an evidence-linked equivalence
   relation before advertising conformance. This is an `N0`/`N1` remote
   target-member build. Its returned member and Artifact Set pass manifest
   verification before `C0`; it cannot create a replacement member after
   `CreateSandbox` has selected a profile.

No mode accepts a mutable tag, provider alias, source checkout path, or
provider object ID as the portable or member identity. Cache hits are
performance facts, not proof of identity. Provider secrets, accounts,
credentials, live regions, placement, retention, and deletion remain
Create/operator/provider facts.

Every provider contract also carries a closed safety policy: fail closed,
explicit-only defaults, warning-only decisions forbidden, mandatory
verification, and caches treated as untrusted optimizations. Admission
authority is fixed by contract, not a caller-supplied component name.
Verification consists of a closed contract-specific set of typed obligation
IDs. Human-readable explanations are non-normative and cannot replace or
weaken those obligations.

## Reconciliation into Packet C

The research is materialized rather than left as prose:

- [Target profile registry](./PACKET-C-TARGET-PROFILES.json) records the whole
  implementation bundle, exact research pins, default suppression, baseline
  unsupported set, and support-advertisement preconditions for each profile.
- [Target realization matrix](./PACKET-C-TARGET-REALIZATION.json) expands all
  81 Packet B fields across four profiles into exactly 324 non-overlapping
  cells with structurally complete, ordered value cases and stable predicate
  coordinates.
- [Provider contracts](./PACKET-C-PROVIDER-CONTRACTS.json) keep prebuilt
  transfer, OCI descriptor transfer, and provider-side construction separate.
- `MAN-005`, `MAN-006`, `HOST-004`, `HOST-005`, `SNP-002`, `PRV-001`, and
  `PRV-002` capture genuinely new invalid states. `TGT-003` and `DRV-001` were
  strengthened instead of duplicating their existing boundaries.

No target or provider research fact changes Artifact ownership. Builders
produce member and support facts; Create selects a proven profile and supplies
per-Sandbox bindings; operators map that profile to exact implementations and
hosts; drivers prepare total target configuration; post-start and live
operation gates produce evidence only at the first sound phase.
