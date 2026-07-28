# Packet C microVM Target Realization Research

Status: **Packet C primary-source research**

Research date: **2026-07-24**

Scope:

- `microvm-firecracker-linux-v1`
- `microvm-cloud-hypervisor-linux-v1`
- all 81 Packet B Artifact fields
- microvm.nix only as a pinned guest artifact builder
- product-owned Firecracker and Cloud Hypervisor runtime drivers

This report is a realization recommendation, not a claim that upstream feature
presence proves product conformance.

## Executive finding

Packet C should treat both microVM profiles as product-owned runtime contracts
over a shared, pinned microvm.nix guest builder, not as aliases for upstream
runners.

The Firecracker member must reject mandatory live-directory semantics. The
Cloud Hypervisor member may advertise live virtiofs only when shared-memory,
helper confinement, ownership, and read/write conformance all pass. Upstream
snapshot APIs are not "full Sandbox snapshots": memory and VMM state are
captured, while disks, external filesystems, identity refresh, and secret
treatment remain product responsibilities.

Artifact source states requirements. Builder/member manifests alone advertise
supported mechanisms and passing conformance facts. These are separate manifest
namespaces and trust domains.

## Source baseline and exact upstream pins

This research reflects upstream `main` at the following exact revisions:

- **microvm.nix**
  `fa5340ac684cdce8a22b6d4a0bcebb0cc999275e`, committed
  2026-07-21T20:36:30Z. Its option surface mixes guest construction with
  runtime host paths, vCPU/memory, shares, volumes, interfaces, sockets, users,
  shell and raw arguments. The generated runner is therefore not an Artifact
  boundary. Sources:
  [options](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/options.nix),
  [common runner](https://github.com/microvm-nix/microvm.nix/blob/main/lib/runner.nix).
- **Firecracker**
  `c1490c7983644f68facfc267c20156546e81bd4f`, committed
  2026-07-24T14:13:02Z. Its current API includes block, net, vsock, entropy,
  pmem, memory hotplug, rate limiting, pause/resume, and snapshots. These are
  upstream mechanisms, not automatically proven profile capabilities. Sources:
  [README](https://github.com/firecracker-microvm/firecracker),
  [OpenAPI](https://github.com/firecracker-microvm/firecracker/blob/main/src/firecracker/swagger/firecracker.yaml).
- **Cloud Hypervisor**
  `aa19811139aeab74baf7065784b24fd66f6e32e2`, committed
  2026-07-24T15:16:11Z. It supports x86-64/AArch64, virtiofs, vsock, hotplug,
  snapshots, and a REST API, but requires outer cgroups for hard process
  resource limits and external filtering for guest I/O. Sources:
  [README](https://github.com/cloud-hypervisor/cloud-hypervisor),
  [API](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/api.md),
  [threat model](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/threat-model.md).
- **virtiofsd**
  release `v1.14.0`, commit
  `c2540f8db14caba81c1e37fba23fc7bf2cd7f0dd`. The qualified Cloud
  Hypervisor profile treats this exact helper build as part of the isolation,
  path-translation, and resource-accounting boundary rather than as an
  incidental host executable. Source:
  [virtiofsd v1.14.0 release](https://gitlab.com/virtio-fs/virtiofsd/-/releases/v1.14.0).

The product dependency pins may choose different exact revisions. If so, every
capability, default, limitation, assertion, and conformance conclusion in this
report must be rechecked against those pins.

## Realization vocabulary

### Authorities and deadlines

- `B` — builder/final evaluated configuration. Unsupported semantics fail
  before an Artifact Set exists.
- `ML` — manifest load. Signatures, hashes, versions, and support facts must
  verify before Create.
- `C` — Create resolver. One permitted materialization, allocation, or binding
  is selected.
- `O` — operator policy or external-resource binding.
- `P` — host preflight/reservation. It must complete before start.
- `D` — owned driver/API lowering and guest-agent preparation. It must complete
  before start or the relevant operation.
- `R` — post-start/operation evidence. Readiness or operation success is
  withheld until the required fact is observed.

### Defaults that must be suppressed

- `μ` — explicitly set the microvm.nix guest/build subset. Never inherit
  `hypervisor = qemu`, `vcpu = 1`, `mem = 512`, share/store inference,
  `preStart`, `extraArgsScript`, raw VMM arguments/configuration, host paths,
  users, sockets, interfaces, volumes, devices, or `credentialFiles`. Never
  invoke `declaredRunner`.
- `FC` — explicitly set every Firecracker machine field and optional device.
  Disable MMDS and unrequested devices. Use production seccomp and an explicit
  jailer-equivalent with cgroup v2, UID/GID, netns, PID namespace, rlimits,
  bounded output, and cleanup. Firecracker does not filter guest traffic.
  Sources:
  [production host guidance](https://github.com/firecracker-microvm/firecracker/blob/main/docs/prod-host-setup.md),
  [jailer](https://github.com/firecracker-microvm/firecracker/blob/main/docs/jailer.md).
- `CH` — explicitly set CPU `boot=max`, `nested=false`, core scheduling,
  memory/shared/THP/hotplug, console/serial/debug console, devices, seccomp,
  Landlock, and API socket. Declare the unavoidable RTC/ACPI/RNG baseline.
  Cloud Hypervisor defaults include nested virtualization, 512 MiB, a tty
  virtio-console, RNG, RTC/ACPI, seccomp on, and Landlock off. Sources:
  [configuration source](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/cloud-hypervisor/src/main.rs),
  [device model](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/device_model.md),
  [Landlock](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/landlock.md).
- `H` — no ambient host environment, paths, DNS, interfaces, ports, CIDs,
  identifiers, users, credentials, volume handles, or controller availability.
- `G` — no guest/image defaults for environment, process, identity, mounts,
  swap, policy, or network.
- `S` — no generic snapshot claim. Record the exact capture class, VMM/build
  version, host/CPU compatibility, storage handling, secret treatment, and
  identity-refresh contract.

### Conformance evidence classes

- `EM` — canonical manifest/schema/hash and requirement-versus-fact separation.
- `EB` — independent rebuild, closure scan, and forbidden-final-config tests.
- `EG` — exact API/argv golden plus VMM readback.
- `EH` — negative preflight/reservation tests.
- `ER` — boot-to-ready and guest-agent protocol evidence.
- `EN` — negative filesystem, environment, identity, security, and network
  probes.
- `EQ` — resource exhaustion and accounting tests.
- `EX` — workspace, volume, output, and secret-transfer tests.
- `EL` — timeout, signal, crash, and cleanup tests.
- `ES` — snapshot, restore, clone, compatibility, and security matrix.

In every field mapping below:

- `A:` identifies Artifact-authored requirement or semantic content.
- `F:` identifies builder-emitted support or conformance facts.

Artifact authors must never supply `F:` facts.

## All 81 Packet B field mappings

### Profile, metadata, and platform

1. **`artifact.profile.selection`**
   - Firecracker: select only the registered `microvm-firecracker-linux-v1`
     coordinate.
   - Cloud Hypervisor: select only the registered
     `microvm-cloud-hypervisor-linux-v1` coordinate.
   - Authority/deadline: `B` validates the exact registered pin before
     construction.
   - Manifest: `A:` selected profile identity and explicit/implicit origin.
     `F:` exact microvm.nix, VMM, adapter, driver, guest-runtime, and
     conformance-set identities.
   - Defaults/evidence: suppress `μ,FC/CH`; require `EM,EB`.

2. **`artifact.profile.expansion`**
   - Both profiles fully expand all portable values before target lowering.
     No microvm.nix or VMM default may fill an unresolved field.
   - Authority/deadline: `B`.
   - Manifest: `A:` complete expansion and field origins. `F:` normalized
     profile digest and adapter version.
   - Defaults/evidence: suppress all target defaults; require `EM`.

3. **`artifact.profile.compositionPaths`**
   - Both profiles route imports, overrides, guest modules, native handles,
     and canonical wire input through the same final validator.
   - Authority/deadline: `B`, with construction-path equivalence proved in
     Packet D.
   - Manifest: `A:` final expanded semantics and contributing-source
     provenance. `F:` validator and construction-path coverage identity.
   - Defaults/evidence: suppress `μ`; require `EM,EB`.

4. **`artifact.metadata.descriptive`**
   - Both preserve descriptive metadata only in the semantic manifest. No
     runtime consumer may reinterpret it as policy, placement, lifecycle, or
     credential data.
   - Authority/deadline: `B`.
   - Manifest: `A:` canonical descriptive map. `F:` no capability claim beyond
     manifest verification.
   - Defaults/evidence: suppress `H`; require `EM`.

5. **`artifact.platform.workload`**
   - Both builders produce a Linux/NixOS kernel, initrd, and closure for an
     explicit x86_64 or aarch64 workload.
   - Both profiles require matching KVM and host architecture/capabilities at
     `P`. Other workload OS/architecture combinations are explicit build-time
     unsupported states for these profiles.
   - Authority/deadline: `B` for profile/platform compatibility; `P` before
     start for current-host KVM facts.
   - Manifest: `A:` resolved workload OS/architecture/Nix system tuple. `F:`
     built architecture, kernel ABI/device requirements, and boot-tested
     profile/architecture.
   - Defaults/evidence: suppress `μ,H`; require `EB,EH,ER`. KVM extensions must
     be queried rather than inferred from a kernel version. Source:
     [KVM API](https://docs.kernel.org/virt/kvm/api.html).

### Environment

6. **`artifact.environment.packages`**
   - Both lower the ordered package set and its closures into immutable guest
     system/store content.
   - Authority/deadline: `B`.
   - Manifest: `A:` ordered package and closure identities. `F:` exact store
     closure paths and content digests.
   - Defaults/evidence: suppress `μ,G`; require `EB,ER`.

7. **`artifact.environment.devShell`**
   - Both convert the closed importer result into immutable guest content and
     explicit environment metadata. Unsupported or silently dropped importer
     state fails at `B`.
   - Authority/deadline: `B`.
   - Manifest: `A:` importer version, source, retained categories, and resolved
     content identities. `F:` exact built closure identities.
   - Defaults/evidence: suppress `μ,G`; require `EB,EN`.

8. **`artifact.environment.variables`**
   - Both store the non-secret map in the manifest and guest-runtime
     configuration; the guest agent applies it to workload Processes.
   - Authority/deadline: `B+D`; observed before Process readiness at `R`.
   - Manifest: `A:` canonical non-secret map and classification. `F:` guest
     runtime protocol supporting a closed environment.
   - Defaults/evidence: suppress `G,H`; require `EM,EN`.

9. **`artifact.environment.searchPath`**
   - Both derive the complete path solely from declared closure content and
     apply it through the guest agent.
   - Authority/deadline: `B+D`; `R` observes exact order.
   - Manifest: `A:` canonical ordered path. `F:` executable identities and
     guest-agent capability.
   - Defaults/evidence: suppress `G,H`; require `EB,EN`.

10. **`artifact.environment.activation`**
    - Both require every trusted argv executable to exist in the built closure.
      The guest agent runs activation without a shell at the defined lifecycle
      point.
    - An activation lifecycle unsupported by the pinned guest runtime is
      explicit `B` unsupported.
    - Authority/deadline: `B+D`; proof at `R`.
    - Manifest: `A:` ordered argv and executable identities. `F:` activation
      protocol and version.
    - Defaults/evidence: suppress `G`; require `EB,ER,EN`.

11. **`artifact.environment.ambientExclusion`**
    - Both drivers and the guest agent construct an empty environment and then
      add only declared values and reserved runtime channels.
    - Authority/deadline: `B+D`; proof at `R`.
    - Manifest: `A:` closed-environment policy and reserved-name version.
      `F:` negative-probe conformance result.
    - Defaults/evidence: suppress `μ,H,G`; require `EN`.

### Process

12. **`artifact.process.argv`**
    - Both preserve the Artifact default or explicit absence. Create/Exec
      selects it or supplies a complete Process, and the guest agent invokes
      argv directly.
    - Authority/deadline: `B+C+D`.
    - Manifest: `A:` explicit argv or absence. `F:` argv execution protocol.
    - Defaults/evidence: suppress `G`; require `EM,ER,EN`.

13. **`artifact.process.cwd`**
    - Both preserve cwd or explicit absence. The guest agent validates the
      absolute path against the prepared topology immediately before exec.
    - Authority/deadline: `B+C+D`; reject by Process start.
    - Manifest: `A:` normalized cwd or absence. `F:` cwd-validation
      capability.
    - Defaults/evidence: suppress `G,H`; require `EN`.

14. **`artifact.process.environment`**
    - Both preserve the canonical delta and apply it within the Artifact
      environment ceiling.
    - Authority/deadline: `B+C+D`; `R` validates the effective map.
    - Manifest: `A:` canonical Process delta. `F:` guest-runtime environment
      protocol.
    - Defaults/evidence: suppress `G,H`; require `EN`.

15. **`artifact.process.identity`**
    - Both resolve only a workload identity already permitted by the Artifact
      and apply it through the guest agent.
    - Host/VMM process identity remains unrelated operator/preflight state.
    - Authority/deadline: `B+D`; host identity `O/P`.
    - Manifest: `A:` resolved workload identity reference. `F:` agent
      set-credentials capability.
    - Defaults/evidence: suppress `H,G`; require `EN`.

16. **`artifact.process.omission`**
    - Explicit absence remains absent. Neither VMM, guest image, nor guest agent
      may synthesize an entrypoint, cwd, or environment fallback.
    - Authority/deadline: `B+C`; a missing complete runtime Process fails at
      Create/Exec.
    - Manifest: `A:` explicit presence/absence for every member. `F:`
      omission-conformance result.
    - Defaults/evidence: suppress `G`; require `EM,EN`.

### Workspace

17. **`artifact.workspace.slot`**
    - Firecracker supports copy transfer or prepared block binding.
    - Cloud Hypervisor supports those mechanisms plus qualified live virtiofs.
    - Authority/deadline: concrete source binding is `C/O/P/D`.
    - Manifest: `A:` value-free workspace slot contract. `F:` exact
      per-profile materialization support.
    - Defaults/evidence: suppress `H`; require `EX`.

18. **`artifact.workspace.destination`**
    - Both build the normalized destination into topology and guest-runtime
      configuration; runtime materialization mounts exactly there.
    - Authority/deadline: `B+D`; ready-state deadline.
    - Manifest: `A:` normalized destination. `F:` mount-target support.
    - Defaults/evidence: suppress `G`; require `EN,EX`.

19. **`artifact.workspace.access`**
    - Firecracker: use a read-only block flag, read-only guest mount, or
      read-only copied tree.
    - Cloud Hypervisor: use the same mechanisms or virtiofsd read-only mode plus
      a read-only guest mount.
    - Authority/deadline: `D`; observed at `R`.
    - Manifest: `A:` access ceiling. `F:` mechanism-specific enforcement fact.
    - Defaults/evidence: suppress `H,G`; require `EN,EX`.

20. **`artifact.workspace.materializations`**
    - Firecracker advertises only copy-in/copy-out and prepared block-volume
      forms. Mandatory live sharing is explicit `B` unsupported.
    - Cloud Hypervisor may advertise live virtiofs only after helper,
      shared-memory, ownership, access, and confinement tests pass.
    - A permitted set is intersected with profile support at `B`; an empty
      intersection fails. Create selects one remaining alternative explicitly.
    - Authority/deadline: `B` for the supported intersection; `C` for explicit
      selection before materialization.
    - Manifest: `A:` mandatory or permitted materialization set. `F:` exact
      supported subset per profile.
    - Defaults/evidence: suppress implicit target choice; require `EX,ER`.
      microvm.nix itself documents no 9p/virtiofs for Firecracker. Source:
      [microvm.nix README](https://github.com/microvm-nix/microvm.nix).

21. **`artifact.workspace.ownership`**
    - Copy/block paths are populated or formatted for the declared guest
      UID/GID in both profiles.
    - Cloud Hypervisor live virtiofs additionally requires proven UID/GID
      translation or matching ownership. Otherwise the live alternative is
      build-time unsupported.
    - Authority/deadline: `B+C/P/D`; ready-state proof.
    - Manifest: `A:` workload-visible ownership expectations. `F:`
      ownership-mapping capability, never a live host mapping.
    - Defaults/evidence: suppress `H`; require `EX,EN`. Current microvm.nix
      exposes per-share translation knobs, confirming that this is a runtime
      helper concern. Source:
      [shares](https://github.com/microvm-nix/microvm.nix/blob/main/doc/src/shares.md).

22. **`artifact.workspace.required`**
    - Both record the binding cardinality. Create must provide one compatible
      binding or fail.
    - Authority/deadline: `B+C`; Create deadline.
    - Manifest: `A:` required/optional cardinality. `F:` supported binding
      kinds.
    - Defaults/evidence: suppress `H`; require `EM,EX`.

23. **`artifact.workspace.protectedPaths`**
    - Both use deterministic guest bind/remount/mask topology after workspace
      materialization.
    - Cloud Hypervisor live virtiofs still requires guest-side subpath
      protection; protecting only the virtiofs root is insufficient.
    - Authority/deadline: `B+D`; observed before ready.
    - Manifest: `A:` canonical protected paths and modes. `F:` guest topology
      enforcement version and result.
    - Defaults/evidence: suppress `G`; require `EN`.

24. **`artifact.workspace.runtimeTransferExclusion`**
    - Both preserve only transfer eligibility. Synchronization, writeback,
      export, retention, and snapshot timing remain operation requests.
    - Authority/deadline: `B+C/operation`.
    - Manifest: `A:` workspace contract only. `F:` supported transfer
      protocols, separate from Artifact identity.
    - Defaults/evidence: suppress `H,S`; require `EM,EX`.

### Filesystem

25. **`artifact.filesystem.immutableInputs`**
    - Both build content into the immutable closure/store disk or a separate
      digest-addressed read-only image.
    - Authority/deadline: `B+D`; ready proof.
    - Manifest: `A:` identities, digests, destinations, and read-only contract.
      `F:` exact built paths/images and read-only enforcement.
    - Defaults/evidence: suppress `μ,G`; require `EB,EN`.

26. **`artifact.filesystem.mountSlots`**
    - Firecracker supports copy/block-backed bindings. A requirement that is
      live-host-directory-only fails at `B`.
    - Cloud Hypervisor can additionally bind qualified virtiofs.
    - Authority/deadline: `B` for supported mechanism; concrete source
      `C/O/P/D`.
    - Manifest: `A:` slot and access ceiling. `F:` exact supported mechanisms.
    - Defaults/evidence: suppress `H`; require `EX,EN`.

27. **`artifact.filesystem.scratch`**
    - Both use private tmpfs or an ephemeral block image prepared by the owned
      driver, with explicit guest mount options and mandatory bounds.
    - Authority/deadline: `B+D`; ready proof.
    - Manifest: `A:` destination, medium, and hard maximum. `F:` supported
      medium and accounting semantics.
    - Defaults/evidence: suppress `G,H`; require `EQ,EN`.

28. **`artifact.filesystem.volumeSlots`**
    - Both resolve the external volume handle at `O/C`, validate and reserve it
      at `P`, then attach it as virtio-block at `D`.
    - No concrete host path enters Artifact semantics.
    - Authority/deadline: `O/C/P/D`; attachment must finish before ready.
    - Manifest: `A:` slot contract and bounds. `F:` supported image,
      filesystem, and device formats.
    - Defaults/evidence: suppress `H`; require `EH,EX`.

29. **`artifact.filesystem.writableRoot`**
    - Both construct the immutable store/root at `B` and allocate any private
      writable overlay or block device at `D`.
    - No VMM or image writable layer is inferred.
    - Authority/deadline: `B+D`; effective root topology is proven before
      ready.
    - Manifest: `A:` root alternative, scope, and bound. `F:` overlay/block
      implementation and conformance result.
    - Defaults/evidence: suppress `μ,G`; require `EB,EQ,EN`.

30. **`artifact.filesystem.topology`**
    - Both validate the entire destination graph at `B`; the guest runtime
      applies a deterministic mount order at `D`.
    - No upstream mount order or shadowing default is inherited.
    - Authority/deadline: `B+D`; effective topology is proven before ready.
    - Manifest: `A:` canonical graph, nesting, and protection constraints.
      `F:` topology executor version.
    - Defaults/evidence: suppress `G`; require `EM,EN`.

### Network

31. **`artifact.network.access`**
    - In both profiles, `none` means no guest IP NIC and denied DNS.
      Unrestricted or controlled modes allocate TAP/netns state at `P/D`.
    - Both rely on host enforcement. Firecracker explicitly forwards packets
      to TAP without filtering. Cloud Hypervisor likewise states that filtering
      must occur outside the VMM.
    - Authority/deadline: `B` for mode support, `P/D` before start, `R` for
      observed policy.
    - Manifest: `A:` resolved access mode and authority ceiling. `F:` host
      policy implementation/version.
    - Defaults/evidence: suppress `H,G`; require `EH,EN`. Sources:
      [Firecracker guidance](https://github.com/firecracker-microvm/firecracker/blob/main/docs/prod-host-setup.md),
      [Cloud Hypervisor threat model](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/threat-model.md).

32. **`artifact.network.egress`**
    - Both compile registered rules into owned nftables, netns, and/or proxy
      policy. Neither VMM's virtio-net device is the semantic enforcement
      mechanism.
    - Authority/deadline: `B` rejects unsupported rule/enforcement versions;
      `P/D` installs atomically; `R` probes allow and deny cases.
    - Manifest: `A:` canonical rules and required enforcement version. `F:`
      compiler/enforcer version and observed result.
    - Defaults/evidence: suppress `H`; require `EN`.

33. **`artifact.network.dns`**
    - Both drivers supply an explicit denied or policy-coupled resolver
      configuration. Host resolver inheritance is forbidden.
    - Authority/deadline: `B+C/P/D`; ready deadline.
    - Manifest: `A:` resolved DNS alternative and enforcement requirement.
      `F:` resolver/enforcement support and result.
    - Defaults/evidence: suppress `H,G`; require `EN`.

34. **`artifact.network.ingressPorts`**
    - Both manifests contain only logical guest-port slots.
    - Host port/address allocation is `C/O/P`; NAT or proxy binding is `D`.
    - Authority/deadline: `B+C/O/P/D`; observed binding and policy proof are
      required before ready at `R`.
    - Manifest: `A:` port/protocol slot and policy ceiling. `F:` supported
      ingress mechanism, never the allocated endpoint.
    - Defaults/evidence: suppress `H`; require `EH,EN`.

35. **`artifact.network.credentialSlots`**
    - Both store only secret-slot identities and audiences.
    - Secret binding is `C`; proxy or guest delivery is `D`.
    - Authority/deadline: `B+C+D`; delivery and audience enforcement are
      proven before first credential-mediated access at `R`.
    - Manifest: `A:` slot identities and audience contracts. `F:`
      credential-mediated network-policy capability.
    - Defaults/evidence: suppress `H`; require `EX,EN`.

36. **`artifact.network.hostChannels`**
    - Both initial profiles use registered vsock channels.
    - CID and socket are allocated and collision-checked at `C/P`.
      Firecracker receives a UDS path; Cloud Hypervisor receives CID and socket.
    - Snapshot restore must reset/rebind the channel.
    - Authority/deadline: `B` for channel support, `C/P/D` before start, `R` for
      handshake.
    - Manifest: `A:` typed channel and capability contract. `F:` exact
      vsock/guest-agent protocol support.
    - Defaults/evidence: suppress `H,S`; require `EH,ER,ES`. Cloud Hypervisor
      requires CID >= 3. Source:
      [Cloud Hypervisor OpenAPI](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/vmm/src/api/openapi/cloud-hypervisor.yaml).
      Firecracker documents open connections resetting on snapshot. Source:
      [Firecracker vsock](https://github.com/firecracker-microvm/firecracker/blob/main/docs/vsock.md).

### Resources

37. **`artifact.resources.cpuConcurrency`**
    - Create selects a vCPU count inside the Artifact and operator range.
    - Firecracker explicitly receives `vcpu_count`.
    - Cloud Hypervisor explicitly receives `boot=max` unless a separately
      required and proven CPU-resize capability is in use.
    - Authority/deadline: `C/O/P/D`; ready readback.
    - Manifest: `A:` normalized concurrency range and enforcement scope. `F:`
      supported vCPU range and API version.
    - Defaults/evidence: suppress `FC,CH,H`; require `EG,ER`.

38. **`artifact.resources.cpuRate`**
    - Both use outer cgroup v2 `cpu.max` and optional `cpu.weight` containing
      the VMM and all helper processes. VCPU count does not prove CPU rate.
    - Authority/deadline: `P/D`; post-start containment proof.
    - Manifest: `A:` quota, weight, and scope. `F:` controller and enforcement
      version.
    - Defaults/evidence: suppress `H`; require `EH,EQ`. Linux defaults are
      unlimited quota and weight 100. Source:
      [cgroup v2](https://docs.kernel.org/admin-guide/cgroup-v2.html).

39. **`artifact.resources.memoryTotal`**
    - Both select guest RAM plus an explicit runtime/helper overhead budget
      below the total ceiling.
    - The driver sets VMM memory and an outer `memory.max` for the VMM and
      helpers. Cloud Hypervisor virtiofsd/shared memory is included.
    - Authority/deadline: `C/O/P/D`; observed at `R`.
    - Manifest: `A:` total-memory range and scope. `F:` accounting model and
      overhead-model version.
    - Defaults/evidence: suppress `FC,CH,H`; require `EQ`.

40. **`artifact.resources.memoryWorkload`**
    - Both use an in-guest cgroup controlled by the guest runtime. An outer VM
      memory allocation is not proof of workload memory enforcement.
    - Authority/deadline: `B` requires guest-runtime support; `D` applies;
      `R` exercises exhaustion.
    - Manifest: `A:` workload bound and scope. `F:` guest-controller protocol
      and conformance.
    - Defaults/evidence: suppress `G`; require `EQ`.

41. **`artifact.resources.swap`**
    - Both enforce the named scope through some combination of no guest swap
      devices, in-guest `memory.swap.max`, and outer VMM cgroup swap policy.
    - Authority/deadline: `P/D/R`.
    - Manifest: `A:` swap alternative and scope. `F:` controller and guest
      policy support.
    - Defaults/evidence: suppress `H,G`; require `EQ`. Linux defines
      `memory.swap.max` as the cgroup hard swap limit. Source:
      [cgroup v2](https://docs.kernel.org/admin-guide/cgroup-v2.html).

42. **`artifact.resources.tasks`**
    - Both enforce workload task/TID bounds with in-guest `pids.max`.
      Outer VMM/helper thread counts are a different scope and not proof.
    - Authority/deadline: `B+D/R`.
    - Manifest: `A:` normalized bound and counting semantics. `F:` guest
      cgroup semantics and result.
    - Defaults/evidence: suppress `G`; require `EQ`.

43. **`artifact.resources.writableRootCapacity`**
    - Both drivers create a bounded ephemeral block image or overlay and the
      guest verifies effective filesystem capacity.
    - Authority/deadline: `C/P/D`; ready deadline.
    - Manifest: `A:` root-capacity range and scope. `F:` storage/accounting
      implementation.
    - Defaults/evidence: suppress `H,G`; require `EQ,EX`.

44. **`artifact.resources.volumeCapacity`**
    - Both require the operator binding to satisfy the Artifact range.
      Preflight queries/verifies actual capacity before attachment.
    - No implicit auto-size is permitted.
    - Authority/deadline: `C/O/P/D`.
    - Manifest: `A:` per-slot capacity range. `F:` query/resize capability if
      advertised.
    - Defaults/evidence: suppress `H`; require `EH,EQ`.

45. **`artifact.resources.tmpfsCapacity`**
    - Both guest runtimes mount tmpfs with an explicit size and account it
      within workload/VM memory.
    - Authority/deadline: `D/R`.
    - Manifest: `A:` per-root tmpfs bounds. `F:` guest mount/controller
      support.
    - Defaults/evidence: suppress `G`; require `EQ`.

46. **`artifact.resources.io`**
    - Firecracker provides per-drive token buckets.
    - Cloud Hypervisor provides virtio-block throttling and rate-limit groups.
    - Neither generic device token bucket should be claimed to implement
      arbitrary independent read/write constraints. A dedicated host block
      device may use directional cgroup `io.max`; file-backed per-volume
      directional enforcement needs explicit attribution evidence or is `B`
      unsupported.
    - Authority/deadline: `B` for representability, `C/P/D` for allocation and
      configuration, `R` for rate probes.
    - Manifest: `A:` per-resource directional byte/operation limits. `F:` exact
      representable dimensions and mechanism.
    - Defaults/evidence: suppress target no-limit defaults; require `EG,EQ`.
      Firecracker's rate limiter is token-bucket based. Source:
      [Firecracker OpenAPI](https://github.com/firecracker-microvm/firecracker/blob/main/src/firecracker/swagger/firecracker.yaml).
      Cloud Hypervisor documents device/group throttling. Source:
      [I/O throttling](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/io_throttling.md).

### Identity

47. **`artifact.identity.user`**
    - Both build numeric/name resolution into guest content and use the guest
      runtime to execute with the exact UID/GID.
    - VMM launcher identity remains separate operator state.
    - Authority/deadline: `B+D/R`; VMM user `O/P`.
    - Manifest: `A:` resolved workload UID/GID and optional canonical name.
      `F:` guest-runtime credential-setting capability.
    - Defaults/evidence: suppress `H,G`; require `EB,EN`.

48. **`artifact.identity.groups`**
    - Both build the complete group set and apply it with no ambient
      supplementary groups.
    - Authority/deadline: `B+D/R`.
    - Manifest: `A:` canonical complete group set. `F:` guest-runtime
      group-setting support.
    - Defaults/evidence: suppress `H,G`; require `EN`.

49. **`artifact.identity.hostMappingExclusion`**
    - Neither manifest contains a live host mapping.
    - VMM UID/GID and Cloud Hypervisor virtiofs translation are `O/P/D` facts
      and must preserve guest-visible IDs.
    - Authority/deadline: `B+O/P/D`; guest-visible identity is verified before
      ready at `R`.
    - Manifest: `A:` workload identity and required mapping capability only.
      `F:` runtime mapping support and evidence, never a portable mapping.
    - Defaults/evidence: suppress `H`; require `EH,EN`.

### Security

50. **`artifact.security.noNewPrivileges`**
    - Both use the guest runtime to apply `PR_SET_NO_NEW_PRIVS` to the workload.
      VMM seccomp/jailing is a separate host boundary.
    - Initial high-assurance profiles should build-reject an Artifact requiring
      privilege-transition permission unless a separately proven profile
      supports it.
    - Authority/deadline: `B+D/R`.
    - Manifest: `A:` privilege-transition contract and conformance identity.
      `F:` guest-runtime enforcement.
    - Defaults/evidence: suppress `G`; require `EN`. Linux makes NNP inherited
      and irreversible across fork, clone, and exec. Source:
      [kernel NNP documentation](https://docs.kernel.org/userspace-api/no_new_privs.html).

51. **`artifact.security.capabilities`**
    - Both validate known Linux capability names and set relationships, then
      install the exact guest bounding, permitted, effective, inheritable, and
      ambient state through the guest runtime.
    - Host/VMM capabilities are never imported into workload semantics.
    - Authority/deadline: `B+D/R`.
    - Manifest: `A:` canonical capability ceiling and semantic version. `F:`
      guest kernel/runtime capability support.
    - Defaults/evidence: suppress `H,G`; require `EN`.

52. **`artifact.security.kernelPolicies`**
    - Both compile registered semantic policies into guest-runtime/kernel
      mechanisms.
    - Firecracker or Cloud Hypervisor host-process seccomp does not satisfy a
      workload policy. An unknown policy, version, scope, or unavailable
      mechanism is build-time unsupported.
    - Authority/deadline: `B+D/R`.
    - Manifest: `A:` policy identities, versions, scopes, and required
      conformance. `F:` compiler, mechanism, and conformance results.
    - Defaults/evidence: suppress `G`; require `EB,EN`. Seccomp filters inherit
      only under explicit kernel conditions and are not a complete sandbox.
      Source:
      [kernel seccomp documentation](https://docs.kernel.org/userspace-api/seccomp_filter.html).

53. **`artifact.security.devices`**
    - Firecracker declares its exact minimal controllers plus explicitly
      requested block, net, vsock, or entropy devices. Serial, MMDS, pmem, and
      hotplug stay off unless separately registered and proven.
    - Cloud Hypervisor declares its unavoidable RTC/ACPI/RNG baseline,
      explicitly disables console/serial/debug, and enables only registered
      block, net, vsock, or fs devices.
    - VFIO, USB, vhost-user, and physical/native passthrough are initially
      build-time unsupported in these conforming profiles.
    - Authority/deadline: `B+D/R`.
    - Manifest: `A:` logical device requirements and projected policy changes.
      `F:` exact device inventory by profile and VMM build.
    - Defaults/evidence: suppress `FC,CH`; require `EG,EN`.

54. **`artifact.security.rootFilesystem`**
    - Both use the same physical realization as
      `artifact.filesystem.writableRoot`: immutable built store/root and an
      explicit private bounded overlay only when requested.
    - Authority/deadline: `B+D/R`.
    - Manifest: `A:` resolved root alternative and bound resource. `F:`
      read-only/overlay implementation.
    - Defaults/evidence: suppress `μ,G`; require `EB,EN`.

### Secret slots

55. **`artifact.secretSlots.identity`**
    - Both preserve value-free declarations only.
    - Authority/deadline: `B`.
    - Manifest: `A:` secret-slot identities and cardinality. `F:` supported
      binding/delivery protocol identities, never a value or provider.
    - Defaults/evidence: suppress `H`; require `EM`.

56. **`artifact.secretSlots.delivery`**
    - Both use an authenticated guest-runtime/vsock path to deliver a tmpfs
      file, exec-time environment value, or typed credential channel.
    - Image/store delivery, Firecracker MMDS delivery, and Cloud Hypervisor OEM
      string delivery are forbidden. Unsupported alternatives fail at `B`.
    - Authority/deadline: `B+C/D/R`.
    - Manifest: `A:` permitted ephemeral alternatives and constraints. `F:`
      exact delivery capability.
    - Defaults/evidence: suppress `μ,H,G`; require `EX,EN`.

57. **`artifact.secretSlots.destination`**
    - Both preserve the typed destination only. Create revalidates conflicts
      and the guest runtime materializes it ephemerally.
    - Authority/deadline: `B+C+D`.
    - Manifest: `A:` destination contract without a secret reference. `F:`
      destination-kind support.
    - Defaults/evidence: suppress `H,G`; require `EN,EX`.

58. **`artifact.secretSlots.audienceLifetime`**
    - Both resolve a secret handle at Create, enforce UID/mode/audience through
      the guest runtime, remove delivery on expiry/process end, and bound
      lifetime under the supervisor.
    - Authority/deadline: `C/O/D/R`.
    - Manifest: `A:` audience, ownership/mode, and maximum delivery lifetime.
      `F:` lifecycle and scrub support.
    - Defaults/evidence: suppress `H`; require `EX,EL,EN`.

59. **`artifact.secretSlots.snapshotTreatment`**
    - Both VMMs snapshot guest RAM, so file, environment, and tmpfs secrets can
      be captured.
    - A slot that forbids capture requires either rejection of snapshot while
      the secret is resident or a proven quiesce/scrub protocol.
    - A Cloud Hypervisor live virtiofs path being external does not prove
      absence from guest RAM or cache.
    - Authority/deadline: `B` validates class compatibility; `D/operation`
      gates each snapshot.
    - Manifest: `A:` secret-slot by snapshot-class compatibility matrix. `F:`
      proven capture/scrub class.
    - Defaults/evidence: suppress `S`; require `ES,EN`.

### Requirements

60. **`artifact.requirements.capabilities`**
    - Both preserve only mandatory/optional version constraints and dependency
      closure.
    - The builder emits separately signed support and conformance facts. Any
      mandatory unsatisfied dependency fails at `B`; `ML` verifies facts.
    - Authority/deadline: `B+ML`; every mandatory dependency must resolve
      before the Artifact is admitted.
    - Manifest: `A:` normalized requirements. `F:` exact support/conformance
      statements and evidence identities.
    - Defaults/evidence: suppress target-name inference; require `EM`.

61. **`artifact.requirements.protocols`**
    - Both embed exact guest-runtime, target, driver, VMM API, and evidence
      protocol versions.
    - Manifest load verifies current driver compatibility. Artifact source
      never carries a live endpoint or socket.
    - Authority/deadline: `B+ML/P`.
    - Manifest: `A:` required protocol ranges. `F:` built and verified
      protocol versions.
    - Defaults/evidence: suppress `H`; require `EM,ER`.

62. **`artifact.requirements.workspace`**
    - Firecracker intersects requirements with `{copy, block}`.
    - Cloud Hypervisor intersects requirements with
      `{copy, block, qualified-virtiofs}`.
    - An empty intersection fails at `B`.
    - Authority/deadline: `B`; a nonempty supported intersection is required
      before member construction.
    - Manifest: `A:` derived hard workspace requirements. `F:` exact
      per-profile supported subset.
    - Defaults/evidence: suppress target fallback; require `EM,EX`.

63. **`artifact.requirements.enforcement`**
    - Both map every hard requirement to an explicit mechanism and evidence
      class. No result is advisory or best effort.
    - A missing mechanism fails at `B`; a necessarily observed property
      withholds readiness at `R`.
    - Authority/deadline: `B+D/R`; static support is required at build and
      runtime-observed enforcement is required before ready.
    - Manifest: `A:` required enforcement/evidence contracts. `F:` mechanism
      identities and evidence results.
    - Defaults/evidence: suppress warnings/downgrades; require `EM,EN,EQ`.

### Lifecycle requirements

64. **`artifact.lifecycleRequirements.maximumLifetime`**
    - Both carry the immutable ceiling in the manifest. Create/operator policy
      may narrow it.
    - The owned supervisor enforces a monotonic deadline independently of VMM
      defaults.
    - Authority/deadline: `B+C/O+D/R`.
    - Manifest: `A:` ceiling or explicit absence. `F:` supervisor capability.
    - Defaults/evidence: suppress target lifetime defaults; require `EL`.

65. **`artifact.lifecycleRequirements.maximumLifetimeEnforcement`**
    - Both compute the effective deadline at Create, arm termination/cleanup
      before start, and make Process operations inherit the ceiling.
    - Authority/deadline: `C+D`; live proof at `R`.
    - Manifest: `A:` immutable ceiling relation. `F:` termination and cleanup
      conformance.
    - Defaults/evidence: require `EL`.

66. **`artifact.lifecycleRequirements.snapshot`**
    - Both builders advertise only exact, proven capture classes.
    - Firecracker snapshots contain guest memory and VMM state; disk files are
      user-managed.
    - Cloud Hypervisor snapshot output contains configuration, memory, and VMM
      state, not a storage snapshot.
    - A filesystem-inclusive, secret-excluding, portable-host, or clone-safe
      requirement is build-time unsupported unless owned orchestration closes
      every additional obligation.
    - Authority/deadline: `B` for capability class; `P/D/operation` for current
      compatibility and capture.
    - Manifest: `A:` complete required snapshot class. `F:` VMM/build,
      CPU/kernel, storage, secret, and identity compatibility envelope.
    - Defaults/evidence: suppress `S`; require `ES`. Sources:
      [Firecracker snapshot documentation](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md),
      [Cloud Hypervisor snapshot documentation](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/snapshot_restore.md).

67. **`artifact.lifecycleRequirements.optionalOperations`**
    - Resolve support per operation, never as one lifecycle boolean.
    - Firecracker upstream offers pause/resume, snapshot/restore, and memory
      hotplug, but the initial profile advertises only operations with
      owned-driver conformance; it must not infer CPU-resize support.
    - Cloud Hypervisor can qualify pause/resume, snapshot/restore, CPU/memory
      resize, and device hotplug only after operation-specific tests.
    - PTY is a guest-runtime capability, not a VMM feature.
    - Any required unproven operation fails at `B`.
    - Authority/deadline: `B+ML` for advertised support; `C/D/R` for each
      requested operation before reporting its success.
    - Manifest: `A:` operation identities and version requirements. `F:`
      granular supported operations and evidence.
    - Defaults/evidence: suppress target-name inference; require `EL,ES,ER`.

### Outputs

68. **`artifact.outputs.declarations`**
    - Both preserve output eligibility only. Declaration does not select or
      export an output.
    - Authority/deadline: `B`.
    - Manifest: `A:` output identity, path, and kind. `F:` guest-runtime
      collection protocol support.
    - Defaults/evidence: require `EM`.

69. **`artifact.outputs.filesystemCompatibility`**
    - Both validate writable reachability and absence of protected/secret
      overlap at build, then recheck the effective runtime topology before
      ready.
    - Authority/deadline: `B+D/R`.
    - Manifest: `A:` output-to-filesystem relationship and protection
      constraints. `F:` topology proof.
    - Defaults/evidence: suppress implicit mount precedence; require `EN,EX`.

70. **`artifact.outputs.runtimeCollection`**
    - Both select outputs at Create/operation time and use the guest runtime to
      stream or copy them through the registered control channel.
    - Cloud Hypervisor live mounting may optimize transport but cannot change
      eligibility, timing, selection, or retention semantics.
    - Authority/deadline: `C+D/operation`.
    - Manifest: `A:` eligible output conventions only. `F:` supported
      archive/patch/stream protocols.
    - Defaults/evidence: suppress provider/host destination defaults; require
      `EX,EL`.

### Provenance

71. **`artifact.provenance.requirements`**
    - Both preserve requested provenance scheme and minimum claim classes.
    - The builder emits verified facts. An unsupported mandatory scheme fails
      at `B`.
    - Authority/deadline: `B+ML`; provenance facts must verify before member
      admission.
    - Manifest: `A:` requested scheme and claim classes. `F:` builder identity,
      inputs, outputs, and verification classification.
    - Defaults/evidence: require `EM,EB`.

72. **`artifact.provenance.profile`**
    - Both record the pinned profile, microvm.nix revision, VMM build, guest
      adapter, driver, guest runtime, and conformance suite.
    - Selection origin remains non-hashed explanation metadata.
    - Authority/deadline: `B`.
    - Manifest: `A:` semantic profile identity and explanation origin. `F:`
      exact realized pins and evidence.
    - Defaults/evidence: require `EM`.

73. **`artifact.provenance.native`**
    - Conforming v1 accepts no raw runner or VMM arguments.
    - A registered byte-changing construction handle must identify the affected
      member and lost/retested guarantees. Otherwise `B` rejects it.
    - Authority/deadline: `B+ML`; the handle and its conformance classification
      must verify before member admission.
    - Manifest: `A:` safe handle identity only. `F:` byte effect and granular
      conformance classification.
    - Defaults/evidence: suppress `μ,FC,CH`; require `EM,EB`.

74. **`artifact.provenance.semanticIdentity`**
    - Both compute one digest from fully expanded common semantics before
      physical target realization.
    - Firecracker and Cloud Hypervisor members share this semantic digest.
    - Authority/deadline: `B`.
    - Manifest: `A/F:` typed portable semantic digest.
    - Defaults/evidence: require `EM`.

75. **`artifact.provenance.builtIdentities`**
    - Both hash kernel, initrd, store/root images, guest configuration, guest
      runtime, member manifest, and Artifact Set graph independently from the
      portable semantic identity.
    - Authority/deadline: `B+ML`.
    - Manifest: `F:` typed content, member, Set, and relationship identities.
    - Defaults/evidence: require `EB,EM`.

### Targets

76. **`artifact.targets.enabled`**
    - Both require an explicit microVM target selection. No current host or
      provider inference is allowed.
    - Authority/deadline: `B`.
    - Manifest: `A:` target identity and construction-contract version. `F:`
      built member presence.
    - Defaults/evidence: suppress `H`; require `EM`.

77. **`artifact.targets.runtimeProfiles`**
    - Artifact source requests Firecracker and/or Cloud Hypervisor profile
      constraints.
    - The builder alone emits support and conformance facts. A requested target
      with no usable profile fails at `B`.
    - Authority/deadline: `B+ML`; each requested profile and its facts must
      verify before the Artifact Set is admitted.
    - Manifest: `A:` requested target/profile matrix and constraints. `F:`
      exact satisfied profile, build, and evidence.
    - Defaults/evidence: suppress fallback and target-name inference; require
      `EM,ER`.

78. **`artifact.targets.commonContract`**
    - Both members reference the same portable semantic digest.
    - Physical capability differences are explicit profile facts, never common
      field overrides.
    - Authority/deadline: `B`.
    - Manifest: `A:` exact common projection. `F:` per-member conformance
      relationship.
    - Defaults/evidence: require `EM,EN`.

79. **`artifact.targets.nativeConstruction`**
    - Both permit only registered, versioned Artifact-construction handles.
    - microvm.nix `preStart`, `extraArgsScript`, Firecracker
      `extraConfig/extraArgs`, Cloud Hypervisor
      `extraArgs/platformOEMStrings`, host paths, and runtime scripts are
      forbidden in conforming v1.
    - Authority/deadline: `B`.
    - Manifest: `A:` registered handle and version. `F:` affected bytes/member
      and conformance loss/retest result.
    - Defaults/evidence: suppress `μ,FC,CH,H`; require `EB,EM`.

80. **`artifact.targets.memberConstruction`**
    - Firecracker and Cloud Hypervisor should normally be separate members
      because hard runtime requirements, device baseline, process/helper
      confinement, workspace support, and snapshot envelope differ.
    - Kernel/initrd/store blobs may deduplicate when byte-identical, but member
      identity must not collapse.
    - Authority/deadline: `B`.
    - Manifest: `F:` exact content, protocol, requirement, and common-projection
      graph.
    - Defaults/evidence: suppress silent disappearance and downgrade; require
      `EM,EB`.

81. **`artifact.targets.artifactSet`**
    - Both profiles are included only after every requested member builds and
      verifies.
    - One unsupported requested profile fails the complete Artifact Set. No
      member may silently disappear or fall back.
    - Authority/deadline: `B+ML`.
    - Manifest: `F:` complete member graph, shared semantic identity, and Set
      identity.
    - Defaults/evidence: require `EM`.

## Artifact requirements versus builder-emitted facts

The manifest needs two non-interchangeable namespaces.

### Artifact-authored requirements

Artifact source may state:

- selected target and runtime-profile constraints;
- portable semantic fields;
- mandatory and optional capability requirements;
- protocol version requirements;
- enforcement requirements;
- workspace/materialization requirements;
- snapshot capability classes;
- optional-operation requirements;
- provenance scheme requirements;
- the common semantic value from which the semantic digest is derived.

Artifact source may not assert that a target supports those requirements or
that conformance passed.

### Builder/member facts

Only a trusted builder/member-manifest producer may emit:

- exact source and build pins;
- adapter, driver, and guest-runtime versions;
- content digests;
- profile support;
- supported materializations;
- supported optional operations;
- exact guest device baseline;
- enforcement mechanism identities and versions;
- conformance suite and result identities;
- architecture boot evidence;
- snapshot compatibility envelope;
- supported guest-runtime and control protocols;
- granular conformance loss caused by a registered native construction input.

Manifest load must reject:

- an author-supplied support/conformance fact;
- an unsigned builder fact;
- a fact for another member, profile, or source pin;
- expired, unknown, or unverifiable evidence;
- a requirement considered satisfied only because of a target name.

Even when kernel, initrd, and store-disk bytes are identical, Firecracker and
Cloud Hypervisor should have distinct member manifests. They differ at least in
live-workspace support, device baseline, process/helper confinement, snapshot
compatibility, and required VMM/driver protocols.

## Candidate genuinely new target invalid states

The assigned local-read scope excluded the current invariant registry, so exact
absence from that registry cannot be proven from this research alone. The
following states are new relative to the Packet B field ledger and Packet C
plan text. They should be exact-set diffed against the current registry before
assigning IDs:

1. A Firecracker high-assurance profile launched without jailer or an evidenced
   equal-or-stronger process jail. Reject at profile admission or preflight.
2. Firecracker jailer configured with `cgroup-version=2` but no cgroup
   parameters or valid existing parent, leaving the process outside a newly
   created per-VM cgroup. Reject at preflight.
3. Cloud Hypervisor inheriting `nested=true`, exposing nested virtualization
   despite the profile not declaring it. Reject driver configuration before
   start.
4. A Cloud Hypervisor member claiming an empty/minimal device set while
   unavoidable RTC/ACPI/RNG or a default console is present. Reject at
   build/profile validation.
5. Cloud Hypervisor claiming host-path sandboxing when Landlock is absent, too
   old, or applied only best-effort. Fail preflight; never warn and continue.
6. Cloud Hypervisor claiming AF_UNIX/socket confinement from Landlock alone.
   Its threat model explicitly says Landlock does not close that boundary.
   Reject the claim at build unless outer namespaces or another kernel control
   close it.
7. A Cloud Hypervisor live virtiofs workspace configured without
   `memory.shared=on`.
8. A Cloud Hypervisor virtiofsd helper running outside the VMM's outer process
   jail, cgroup, resource accounting, lifecycle supervision, or cleanup.
9. Cloud Hypervisor live workspace ownership, read-only, or protected-subpath
   semantics that cannot be represented by proven virtiofsd translation plus
   guest mounts. Reject at build or preflight, not after a workload write.
10. A snapshot capability advertised as filesystem-inclusive when only VMM
    memory, configuration, and device state are captured and disks are
    externally managed. Reject at build.
11. A snapshot requested while a `forbid capture` secret remains resident in
    guest RAM, tmpfs, or environment without proven scrub/quiesce. Reject the
    operation.
12. Reusing one Firecracker snapshot more than once without guest identity,
    entropy, token, and network refresh. Upstream calls this insecure. Reject
    clone/fork.
13. Firecracker restore attempted outside the proven CPU model, architecture,
    host-kernel, and VMM-version envelope. Reject preflight.
14. Cloud Hypervisor restore attempted under a different VMM build when profile
    evidence covers only exact-version restore. Reject preflight.
15. A directional per-resource storage I/O bound claimed from a combined token
    bucket or from host `io.max` on a shared backing device. Reject at build
    unless exact attribution is proven.
16. A Firecracker production profile enabling guest serial output without an
    explicit bounded sink and rate policy. Reject driver configuration.
17. Cloud Hypervisor opening a runtime path selected through unresolved
    symlinks or `/proc`. Its threat model assigns path-traversal protection to
    the trusted caller. Reject preflight.
18. Raw microvm.nix, Firecracker, or Cloud Hypervisor configuration enabling
    MMDS, OEM credential strings, passthrough, helper sockets, or undeclared
    devices while retaining built-in conformance claims. Reject at build.
19. A VMM memory size claimed as total-Sandbox or workload-memory enforcement
    without outer and guest cgroups respectively. Reject the support claim.
20. Snapshot restore retaining stale TAP, vsock, CID, API-socket, or host-path
    bindings instead of allocating and validating fresh runtime identities.
    Reject before resume.
21. Byte-identical Firecracker and Cloud Hypervisor blobs collapsed into one
    target member despite distinct hard requirements and support facts. Reject
    manifest construction.
22. Firecracker mandatory live-workspace semantics silently lowered to a copy
    or block volume. Reject at build.
23. A Cloud Hypervisor live-share requirement accepted when the helper's
    cache, xattr, ACL, UID/GID translation, or read-only semantics do not match
    the Artifact contract. Reject before start.
24. A snapshot operation treated as successful before externally managed disk
    state is quiesced and captured according to the required snapshot class.
25. A snapshot or restored clone advertised as network-continuous despite
    stale/lost network or vsock connections and missing reconfiguration
    evidence.

## Current documentation contradictions and capability drift

### Firecracker jailer resource-limit default contradiction

The current jailer document says the unspecified `no-file` limit defaults to
2048, while current production-host guidance says 4096. The product must set an
explicit value and test the effective rlimit rather than inheriting either
documented default.

Sources:

- [Jailer](https://github.com/firecracker-microvm/firecracker/blob/main/docs/jailer.md)
- [Production host setup](https://github.com/firecracker-microvm/firecracker/blob/main/docs/prod-host-setup.md)

### Cloud Hypervisor snapshot version contradiction

The current README says snapshot/restore is not supported across different
versions. The current release documentation narrows incompatibility to
different major versions. The initial profile should allow only an exact-build
restore envelope until executable conformance proves a wider one.

Sources:

- [README](https://github.com/cloud-hypervisor/cloud-hypervisor)
- [Release documentation](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/releases.md)

### Firecracker capability drift

Current Firecracker exposes entropy, pmem, memory hotplug, and
developer-preview PCI hotplug beyond the narrower device list in the locked
target strategy. These mechanisms must remain disabled and unadvertised until
separately profiled and proven. Upstream presence is not product-profile
support.

Source:

- [Current Firecracker API](https://github.com/firecracker-microvm/firecracker/blob/main/src/firecracker/swagger/firecracker.yaml)

### microvm.nix Firecracker runner is not a capability oracle

The current microvm.nix Firecracker runner:

- rejects shares;
- refuses configured user switching;
- rejects `credentialFiles`;
- rejects balloon and memory-hotplug settings;
- directly invokes Firecracker rather than jailer;
- always places `console=ttyS0` in boot arguments;
- warns rather than hard-fails some unsupported volume attributes.

These are runner properties, not current Firecracker capability facts. They
also confirm that the runner cannot realize the locked high-assurance profile.

Source:

- [microvm.nix Firecracker runner](https://github.com/microvm-nix/microvm.nix/blob/main/lib/runners/firecracker.nix)

### microvm.nix Cloud Hypervisor runner inherits hidden policy

The current microvm.nix Cloud Hypervisor runner:

- permits raw extra arguments;
- inherits Cloud Hypervisor defaults such as nested virtualization unless
  overridden;
- starts a watchdog;
- starts virtiofsd through microvm.nix's own helper supervision;
- accepts host share/socket paths as runner configuration;
- merges selected raw `--cpus`, `--platform`, and `--vsock` inputs.

This confirms the locked decision not to reuse its runtime contract.

Sources:

- [microvm.nix Cloud Hypervisor runner](https://github.com/microvm-nix/microvm.nix/blob/main/lib/runners/cloud-hypervisor.nix)
- [microvm.nix virtiofsd module](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/virtiofsd/default.nix)

### microvm.nix assertion coverage is incomplete for the product boundary

Current assertions cover duplicate volume images, interface identifiers,
bridge consistency, Linux interface-name length, duplicate share tags and
sockets, virtiofs ACL/translation conflict, port-forward restrictions, and a
small Cloud Hypervisor platform-string check. Several Firecracker restrictions
remain runner warnings or throws rather than final-config assertions.

The product adapter therefore needs its own exhaustive final-config validator.

Source:

- [microvm.nix assertions](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/asserts.nix)

### Snapshot wording overstates physical completeness

Cloud Hypervisor's snapshot guide says the restored VM is "identical", but its
snapshot directory contains `config.json`, `memory-ranges`, and `state.json`;
storage and external helper resources still require product orchestration.
Firecracker is more explicit that block-device files are user-managed. Packet C
must define identity and snapshot classes more narrowly than either convenient
phrase.

Sources:

- [Cloud Hypervisor snapshot documentation](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/snapshot_restore.md)
- [Firecracker snapshot documentation](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md)

## Profile recommendations

### `microvm-firecracker-linux-v1`

Define the initial Firecracker profile with:

- exact Firecracker and jailer build identities;
- x86_64 and/or aarch64 only when independently boot-tested;
- product-owned API calls, never the microvm.nix runner;
- required jailer or an evidenced equal/stronger outer jail;
- explicit cgroup v2 placement and controller availability;
- explicit UID/GID, PID namespace, mount namespace, netns, jail root, rlimits,
  API socket, and cleanup;
- production seccomp enabled;
- no MMDS;
- guest serial disabled, or a separately declared bounded/rate-limited channel;
- no live directory shares;
- copy and prepared block workspace materializations only;
- no unregistered passthrough, pmem, entropy, memory hotplug, or PCI hotplug;
- exact block, net, and vsock inventories;
- host-side network filtering;
- exact snapshot compatibility and capture-class facts;
- no snapshot support fact until clone identity, secret, storage, network, and
  restore compatibility tests pass.

### `microvm-cloud-hypervisor-linux-v1`

Define the initial Cloud Hypervisor profile with:

- exact Cloud Hypervisor and virtiofsd build identities;
- x86_64 and/or aarch64 only when independently boot-tested;
- product-owned REST API calls, never the microvm.nix runner;
- outer UID, PID/mount/net namespaces, cgroup v2, lifecycle supervisor, and
  bounded logs;
- seccomp in fail-stop/kill mode;
- Landlock enabled and fail-closed when it is a profile requirement, while
  explicitly not treating it as AF_UNIX confinement;
- `nested=false`;
- explicit CPU `boot=max`, core scheduling, and every memory option;
- explicit console, serial, and debug-console state;
- exact declaration of unavoidable RTC/ACPI/RNG baseline;
- no unregistered VFIO, vhost-user, passthrough, D-Bus, hotplug, or migration;
- host-side network filtering;
- copy and prepared block workspace materializations;
- live virtiofs only as an independently advertised capability with
  `shared=on`, confined helper process, exact cache/access/ownership semantics,
  and post-start negative probes;
- exact snapshot build compatibility and capture class.

### Target member identity

Firecracker and Cloud Hypervisor should normally have different target member
identities even when guest artifacts are byte-identical. They differ in:

- workspace materializations;
- baseline devices;
- helper process set;
- process jail;
- VMM API and protocol;
- snapshot compatibility;
- host preflight requirements;
- operation support;
- evidence obligations.

Blob storage may deduplicate identical kernel, initrd, store, and guest-runtime
content below the member layer.

## Conformance recommendations

1. Generate exact golden Firecracker API calls and Cloud Hypervisor API
   requests from the validated prepared state.
2. Read effective VMM configuration back where the API permits it.
3. Scan final microvm.nix evaluated configuration for every forbidden runtime
   field, not only raw arguments.
4. Independently rebuild and compare kernel, initrd, store/root image, guest
   runtime, and generated configuration.
5. Boot every supported profile/architecture pin to a versioned ready
   handshake.
6. Probe undeclared host paths, read-only paths, protected workspace paths,
   identity, groups, capabilities, NNP, kernel policies, ambient environment,
   network denial, DNS, and host channels.
7. Exhaust CPU, total memory, workload memory, swap, tasks, root capacity,
   volume capacity, tmpfs, and supported I/O dimensions.
8. Verify that the outer cgroup contains the VMM and all helper processes,
   including virtiofsd.
9. Exercise start failure, API failure, guest crash, VMM crash, timeout,
   cancellation, forced kill, and cleanup.
10. Test workspace copy/block/live access and ownership separately.
11. Test secret delivery, redaction, expiry, scrub, process end, crash, logs,
    immutable closure exclusion, and snapshot exclusion.
12. Test snapshots by exact VMM build, CPU model, architecture, host-kernel
    envelope, block image state, network rebind, vsock reset, CID allocation,
    guest identity refresh, secret state, full/diff or restore mode, repeated
    clone, and cleanup.
13. Do not convert upstream feature existence, successful build, or successful
    boot into a passing semantic conformance claim.

## Implementation recommendations

1. Give Artifact requirements and builder facts distinct closed schemas,
   signatures, and validation rules.
2. Make support facts granular: materialization, policy version, device class,
   operation, snapshot class, architecture, VMM build, and evidence set.
3. Make unsupported outcomes conditional and explicit. Examples include
   mandatory Firecracker live workspace, unproven Cloud Hypervisor ownership
   translation, unsupported policy version, directional I/O without exact
   attribution, and filesystem-inclusive snapshot without storage orchestration.
4. Model snapshot capability using component classes such as:
   - `memory+vmm-state`;
   - `external-disk-consistency`;
   - `filesystem-inclusive`;
   - `clone-identity-refresh`;
   - `network-rebind`;
   - `secret-exclusion`.
5. Never represent snapshot support as a generic `snapshot=true`.
6. Restrict initial I/O facts to dimensions exactly representable by the
   selected mechanism.
7. Require exact pin identities in all capability and conformance facts.
8. Re-run this source review on every dependency update.

## Primary sources

### microvm.nix

- [Repository](https://github.com/microvm-nix/microvm.nix)
- [Options](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/options.nix)
- [Assertions](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/asserts.nix)
- [Common runner](https://github.com/microvm-nix/microvm.nix/blob/main/lib/runner.nix)
- [Firecracker runner](https://github.com/microvm-nix/microvm.nix/blob/main/lib/runners/firecracker.nix)
- [Cloud Hypervisor runner](https://github.com/microvm-nix/microvm.nix/blob/main/lib/runners/cloud-hypervisor.nix)
- [Store-disk builder](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/store-disk.nix)
- [Boot-disk builder](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/boot-disk.nix)
- [Volume helper](https://github.com/microvm-nix/microvm.nix/blob/main/lib/volumes.nix)
- [Virtiofsd module](https://github.com/microvm-nix/microvm.nix/blob/main/nixos-modules/microvm/virtiofsd/default.nix)
- [Share documentation](https://github.com/microvm-nix/microvm.nix/blob/main/doc/src/shares.md)
- [Simple networking documentation](https://github.com/microvm-nix/microvm.nix/blob/main/doc/src/simple-network.md)

### Firecracker

- [Repository and capability summary](https://github.com/firecracker-microvm/firecracker)
- [Design](https://github.com/firecracker-microvm/firecracker/blob/main/docs/design.md)
- [OpenAPI](https://github.com/firecracker-microvm/firecracker/blob/main/src/firecracker/swagger/firecracker.yaml)
- [Device API](https://github.com/firecracker-microvm/firecracker/blob/main/docs/device-api.md)
- [Getting started and KVM prerequisites](https://github.com/firecracker-microvm/firecracker/blob/main/docs/getting-started.md)
- [Jailer](https://github.com/firecracker-microvm/firecracker/blob/main/docs/jailer.md)
- [Production host setup](https://github.com/firecracker-microvm/firecracker/blob/main/docs/prod-host-setup.md)
- [Network setup](https://github.com/firecracker-microvm/firecracker/blob/main/docs/network-setup.md)
- [Seccomp](https://github.com/firecracker-microvm/firecracker/blob/main/docs/seccomp.md)
- [Vsock](https://github.com/firecracker-microvm/firecracker/blob/main/docs/vsock.md)
- [Snapshot support](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md)
- [Snapshot versioning](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/versioning.md)
- [Snapshot clone networking](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/network-for-clones.md)
- [Memory hotplug](https://github.com/firecracker-microvm/firecracker/blob/main/docs/memory-hotplug.md)
- [Metrics](https://github.com/firecracker-microvm/firecracker/blob/main/docs/metrics.md)
- [Logger](https://github.com/firecracker-microvm/firecracker/blob/main/docs/logger.md)

### Cloud Hypervisor

- [Repository and status](https://github.com/cloud-hypervisor/cloud-hypervisor)
- [API](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/api.md)
- [OpenAPI](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/vmm/src/api/openapi/cloud-hypervisor.yaml)
- [Device model](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/device_model.md)
- [Virtiofs](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/fs.md)
- [Vsock](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/vsock.md)
- [I/O throttling](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/io_throttling.md)
- [Hotplug](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/hotplug.md)
- [Snapshot/restore](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/snapshot_restore.md)
- [Seccomp](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/seccomp.md)
- [Landlock](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/landlock.md)
- [Threat model](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/threat-model.md)
- [Security policy](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/SECURITY.md)
- [Release documentation](https://github.com/cloud-hypervisor/cloud-hypervisor/blob/main/docs/releases.md)

### virtiofsd

- [v1.14.0 release](https://gitlab.com/virtio-fs/virtiofsd/-/releases/v1.14.0)

### Linux/KVM

- [KVM API](https://docs.kernel.org/virt/kvm/api.html)
- [Control group v2](https://docs.kernel.org/admin-guide/cgroup-v2.html)
- [No New Privileges](https://docs.kernel.org/userspace-api/no_new_privs.html)
- [Seccomp BPF](https://docs.kernel.org/userspace-api/seccomp_filter.html)
- [Landlock](https://docs.kernel.org/userspace-api/landlock.html)
