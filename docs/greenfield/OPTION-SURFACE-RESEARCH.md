# Sandbox Option-Surface Research

Status: **Research synthesis — recommendations are not locked**

Date: 2026-07-23

This report informs the greenfield design in `DESIGN.md`. It surveys current
sandbox products, agent SDKs, Nix target technologies, and validation
mechanisms to determine:

- which concepts users already expect;
- which concepts have stable semantics across bubblewrap, microVM, and OCI
  targets;
- which options belong in the Nix definition, runtime creation API, live
  sandbox API, target-native configuration, or framework adapter;
- which conflicts can be rejected during Nix evaluation;
- how later failures must be represented and propagated.

The provider, backend, and validation surveys were performed independently and
then reconciled. Automated research claims that could not be verified against
primary specifications were discarded. In particular, OCI core lifecycle,
microvm.nix snapshot support, and agent-framework capabilities were frequently
overgeneralized by secondary syntheses.

## Executive conclusions

1. There is no convergent, portable `workspace.changes` or workspace-writeback
   toggle. That proposed field is rejected.
2. Workspace access, sandbox-state persistence, and result transfer are three
   separate concerns.
3. Not every option belongs in the Nix definition. The product needs distinct
   definition, create, live-operation, and adapter surfaces.
4. The common schema describes observable intent and required enforcement, not
   backend mechanisms.
5. Portable fields are hard requirements. Unsupported semantics fail; they do
   not degrade to backend defaults.
6. Static capability conflicts and contradictions visible in the final merged
   configuration fail during fully forced Nix evaluation.
7. Artifact, host, allocation, and live-state facts cannot honestly be called
   compile-time checks. They fail at artifact build, host preflight,
   create/start, or a gated post-create probe.
8. Diagnostics are a versioned data contract. Nix and provider prose is never
   parsed as the semantic error protocol.
9. OpenAI agent capabilities such as `Shell`, `Filesystem`, `Memory`, and
   `Compaction` belong to the OpenAI adapter. They are not sandbox isolation
   capabilities.
10. Arbitrary native configuration is trusted code. When it affects behavior
    that cannot be projected and validated, the affected guarantee must be
    rejected or explicitly marked unverified; there is no `bypassValidate`
    escape hatch.

## Research scope

### Provider and framework surfaces

- OpenAI Codex local permissions
- OpenAI Agents SDK Sandbox Agents
- E2B
- Modal Sandbox
- Daytona
- Cloudflare Sandbox SDK
- Vercel Sandbox
- CodeSandbox SDK
- Kubernetes SIG Agent Sandbox
- OpenSandbox and NVIDIA OpenShell as emerging interoperability references

### Initial and future execution targets

- bubblewrap through jail.nix
- microvm.nix and its supported hypervisors
- OCI Image and Runtime specifications
- container engines and runtimes where they extend OCI
- future policy/runtime candidates including Landlock, seccomp, syd, gVisor,
  and Kata

### Validation and API surfaces

- Nix module evaluation
- flake checks and derivation realization
- target-host preflight
- post-create conformance
- CLI diagnostics
- generic SDK errors
- OpenAI Agents adapter errors

## Provider vocabulary and behavior

### Convergent vocabulary

| Concept | Convergence |
|---|---|
| `Sandbox` | Overwhelmingly means a live isolated environment |
| `Workspace` | User-editable file tree presented inside a sandbox |
| `Command` or `Process` | One execution with argv, cwd, environment, streams, and status |
| `Snapshot` | Captured state reusable later, although captured components differ |
| `Volume`, `Drive`, or PVC | Storage with a lifecycle independent of one sandbox |
| `Image` or `Template` | Reusable starting environment; the terms are not interchangeable |
| `Session` | Ambiguous: client attachment, running incarnation, or stateful shell |

The live resource should be named `Sandbox`. `Snapshot`, `Volume`, `Image`,
`Template`, `Process`, and `Shell` remain distinct concepts. `Session` should
not be a foundational core resource because providers use it for materially
different things.

### Provider comparison

| Provider | Starting environment | Live resource | Persistence model | Important defaults or boundaries |
|---|---|---|---|---|
| Codex | Current host workspace plus a permission profile | No provisioned remote object | Directly edits allowed workspace roots | Workspace editing, network disabled, protected control paths |
| OpenAI Agents | `Manifest`, snapshot, or serialized session state | `SandboxSession` backed by a client | Fresh manifest, reconnect, or seed from snapshot are separate | Agent capabilities default to filesystem, shell, and compaction; mount `read_only` defaults true |
| E2B | `Template` | `Sandbox` | Pause/resume, filesystem or memory snapshot, volumes | Internet allowed by provider default; finite timeout |
| Modal | `Image` | `Sandbox` | Volumes plus filesystem, directory, or memory snapshots | Most resources and policy selected at create time |
| Daytona | `Snapshot` or image | `Sandbox` | Volumes, stop/pause/archive, cold or hot snapshot | Rich mutable lifecycle and provider-specific sandbox classes |
| Cloudflare | Deployment-time Docker image | Durable-Object-addressed `Sandbox` | Container sleep loses local state; backup or bucket mount preserves selected data | Default session and keepalive behavior are provider-specific |
| Vercel | Runtime/image/source/snapshot | Persistent named `Sandbox`; running `Session` | `persistent=true` auto-snapshots on stop and restores on resume | The `persistent` flag does not sync changes back to an originating checkout |
| CodeSandbox | `Template` | Firecracker-backed `Sandbox` | Git-backed workspace and hibernation snapshots | Workspace persistence is inherent, not a toggle |
| Kubernetes Agent Sandbox | `SandboxTemplate` or `SandboxClaim` | `Sandbox` CRD | PVCs, suspension, retention policy, warm pools | Full PodSpec remains Kubernetes-native |

The provider-specific facts and defaults above are documented in:

- [Codex permissions](https://developers.openai.com/codex/permissions)
- [OpenAI Sandbox Agents](https://developers.openai.com/api/docs/guides/agents/sandboxes)
- [OpenAI sandbox clients](https://openai.github.io/openai-agents-python/sandbox/clients)
- [E2B lifecycle](https://e2b.dev/docs/sandbox)
- [E2B persistence](https://e2b.dev/docs/sandbox/persistence)
- [E2B snapshots](https://e2b.dev/docs/sandbox/snapshots)
- [Modal Sandbox reference](https://modal.com/docs/reference/modal.Sandbox)
- [Modal snapshots](https://modal.com/docs/guide/sandbox-snapshots)
- [Daytona Sandbox API](https://www.daytona.io/docs/en/typescript-sdk/sandbox)
- [Daytona snapshots](https://www.daytona.io/docs/en/snapshots)
- [Cloudflare lifecycle](https://developers.cloudflare.com/sandbox/concepts/sandboxes/)
- [Vercel Sandbox SDK](https://vercel.com/docs/vercel-sandbox/sdk-reference)
- [CodeSandbox lifecycle](https://codesandbox.io/docs/sdk/lifecycle)
- [Kubernetes Agent Sandbox API](https://agent-sandbox.sigs.k8s.io/docs/api)

## Rejected `workspace.changes` abstraction

The proposed field was:

```nix
workspace.changes = "live" | "manual" | "discard";
```

This combines unrelated behavior:

1. **Access** — whether a presented path is read-only, directly writable, or
   copy-on-write.
2. **Sandbox retention** — whether filesystem, memory, and device state survive
   stop, suspension, or recreation.
3. **Result transfer** — whether selected files, an archive, a patch, a
   snapshot, or a mounted volume carries results elsewhere.

Providers do not expose one common control for these axes:

- Codex writes directly into allowed host workspace roots.
- OpenAI Manifest mounts have access modes, while snapshots and session state
  are separate.
- E2B has pause, snapshots, and volumes.
- Modal has volumes and several snapshot types.
- Daytona has volumes, snapshots, pause, and archive.
- Cloudflare has backups and bucket mounts.
- CodeSandbox persists a Git-backed workspace intrinsically.
- Kubernetes uses PVCs and operating modes.
- Vercel's exceptional `persistent` boolean means automatic snapshot/restore,
  not host writeback.

The common product model must therefore expose real underlying concepts rather
than a synthesized toggle.

## Separate public surfaces

The same option should not be repeated at every layer. Each concern has one
authoritative surface.

```text
Nix Sandbox Definition
        ↓ evaluate and build
Sandbox Artifact + fully expanded manifest
        ↓ create with runtime bindings
Sandbox
        ↓ live operations
Process / Shell / Snapshot / captured outputs
        ↓ optional translation
Framework adapter
```

### Nix definition surface

Owns reproducible and policy-bearing intent:

- visible profile selection;
- software environment and packages;
- default process environment and working directory;
- workspace contract and protected paths;
- logical filesystem inputs, scratch paths, and mount requirements;
- network policy requirements;
- resource requirements and hard policy bounds that every runtime must honor;
- workload identity and security requirements;
- declared secret slots and allowed delivery forms, never secret values or
  provider bindings;
- required runtime capabilities, such as whether a compatible driver must
  support PTY or checkpointing, without deciding when to use them;
- build provenance requirements;
- enabled artifact targets and target-native configuration.

### Runtime create surface

Owns values that are not reproducible build inputs:

- Sandbox Artifact reference;
- actual workspace source;
- actual external mount or volume bindings;
- secret references and provider bindings for declared secret slots;
- requested sandbox name and labels;
- actual CPU, memory, storage, and device allocation within artifact-declared
  requirements and bounds;
- create timeout;
- run timeout, idle timeout, and the selected supported idle/end behavior;
- requested output capture for this run;
- execution-evidence and retention policy;
- permitted runtime overrides within artifact-declared bounds;
- provider/driver selection;
- target-host or remote-provider connection;
- placement hints only when the selected driver supports them.

### Live Sandbox surface

Owns operations on an existing sandbox:

- inspect status and capabilities;
- execute a process;
- create or reconnect a stateful shell where supported;
- upload, download, list, stat, and remove files;
- expose or resolve declared ports;
- stop or terminate;
- optional pause/resume;
- optional snapshot/checkpoint;
- optional fork/clone;
- stream logs and runtime evidence;
- collect declared outputs.

### Exec surface

Owns per-process values:

- exact argv array;
- cwd;
- non-secret environment overrides;
- secret references when explicitly allowed;
- stdin;
- stdout/stderr streaming;
- timeout;
- background/detached behavior;
- PTY request and dimensions;
- signal and cancellation behavior;
- workload user when permitted by policy.

### Framework adapter surface

Owns framework-specific agent semantics:

- OpenAI `SandboxAgent` capabilities;
- translation between OpenAI `Manifest` and workspace inputs;
- framework-specific tool descriptions and prompts;
- framework-specific session state;
- framework-specific lifecycle defaults and choices translated into core
  create/live operations;
- conversion of core diagnostics into safe framework results.

Agent concepts such as skills, memory, compaction, guardrails, approval
reviewers, or prompt templates do not belong in the sandbox core.

## Corrected ownership boundary

The artifact definition and runtime API intentionally contain related but
different representations of some concepts:

| Concern | Nix definition / artifact manifest | Runtime or adapter |
|---|---|---|
| Workspace | Required destination, access bounds, protected paths | Actual source and mount/upload binding |
| Network | Maximum permitted connectivity and required enforcement | Selected driver mechanism and runtime endpoint rules within that bound |
| Resources | Minimum requirements and hard maximums | Actual allocation for this sandbox |
| Secrets | Named slots, delivery forms, permissions | Provider references and injected values |
| Lifecycle | Required optional capabilities only | TTL, idle action, pause/resume, snapshot timing, retention |
| Outputs | Optional conventional paths only when intrinsic to the artifact | Per-run capture/export selection |
| Evidence | Build provenance requirements | Execution, retention, and model-visibility policy |

The OpenAI or another framework adapter may expose its own lifecycle ergonomics.
It translates them into the core create and live-operation primitives. The
provider driver then maps those primitives onto E2B, Modal, microVM, OCI, or
another execution substrate. Provider lifecycle vocabulary does not become Nix
module vocabulary.

## Candidate Nix definition groups

Names below are research recommendations and remain subject to design approval.

| Group | Candidate concepts | Why common | Important limits |
|---|---|---|---|
| `profile` | Descriptive named profile | Makes the selected baseline visible and reproducible | Fully expands during evaluation; never delegates to backend defaults |
| `metadata` | Name, description, labels | Convergent and non-security-sensitive | IDs and timestamps are runtime-generated |
| `environment` | devShell importer, packages, variables, explicit activation | All targets can carry Nix closures and environment | devShell is not a root filesystem; reject host-specific paths and implicit behavior |
| `process` | Default cwd, default user, optional default argv, shell policy | Every target executes processes | Runtime argv belongs to `exec`; no hidden shell interpolation |
| `workspace` | Destination, access, protected paths, ownership contract | Coding sandboxes need one obvious project root | Actual source is supplied at create time; persistence is not a workspace flag |
| `filesystem` | Read-only inputs, writable scratch, mounts, independent volumes | All targets expose filesystems and mounts | Mount mechanisms remain target-specific |
| `network` | None, unrestricted egress, controlled egress requirement, ingress declarations, host channels | Connectivity intent is observable | Allowlist enforcement requires a named proxy/firewall capability |
| `requirements` | Platform, runtime capabilities, resource minimums and hard bounds | Allows artifacts to reject incompatible drivers before create | Actual allocation and lifecycle choices remain runtime inputs |
| `identity` | Workload-visible UID/GID/user, groups, privilege policy | All initial targets are Linux environments | Guest root, namespace root, and host root are distinct |
| `security` | No-new-privileges, Linux capabilities, seccomp policy, device requests | Important portable process properties | Enforcement location and strength differ across VM and shared-kernel targets |
| `secretSlots` | Names, permitted destinations, mode, audience constraints | Lets an artifact declare a secret interface without containing secret references or values | Runtime create options bind provider references |
| `provenance` | Required build provenance and artifact metadata | Intrinsic to artifact construction | Runtime evidence policy belongs to the caller |
| `targets` | Enabled targets and `native` configuration | Required to build multiple artifact types | Native configuration cannot weaken common policy |

### Environment

Portable:

- target-system packages and their closures;
- explicit non-secret variables;
- executable search path;
- explicit activation executed by the trusted runtime;
- a devShell importer that records exactly what it retained.

Not portable without normalization:

- interactive shell hooks;
- host paths;
- services assumed to exist outside the environment;
- architecture-specific tools unavailable for an enabled target;
- ambient environment inherited from the build or caller.

`nix develop` constructs a build-like shell environment rather than a deployable
root filesystem. See [Nix `develop`](https://nix.dev/manual/nix/stable/command-ref/new-cli/nix3-develop.html).

### Workspace and filesystem

The common contract should describe:

- destination;
- read-only or read-write access;
- protected subpaths;
- expected ownership;
- whether the source is required at create time;
- logical input, scratch, volume, and secret mounts.

Mechanisms are target-specific:

- bubblewrap bind, read-only bind, tmpfs, or overlay;
- microVM 9p/virtiofs share or block volume;
- OCI runtime bind, tmpfs, volume, or writable root layer;
- remote provider upload, volume, drive, bucket, or snapshot seed.

Bubblewrap overlays and jail.nix overlay combinators exist but have kernel,
mount-topology, and security constraints. microvm.nix share support varies by
hypervisor. OCI Image `Volumes` is metadata and does not perform runtime
mounting. See [jail.nix combinators](https://alexdav.id/projects/jail-nix/combinators/),
[microvm.nix shares](https://microvm-nix.github.io/microvm.nix/shares.html),
and [OCI Runtime Configuration](https://specs.opencontainers.org/runtime-spec/config/).

### Network and host channels

The portable intent should distinguish:

- no IP connectivity;
- unrestricted egress;
- controlled egress requiring a named enforcement implementation;
- inbound port declarations;
- DNS behavior;
- host communication channels such as Unix sockets, vsock, D-Bus, Wayland,
  PipeWire, or a broker.

`network = none` does not prove there is no host communication. A microVM may
still have vsock or shared files; bubblewrap or OCI may expose host sockets.

jail.nix grants general network access or omits it; destination allowlists need
another component. OCI defines network namespaces but delegates network setup
to engines/CNI. microVM filtering belongs at a host tap/router/proxy boundary.

### Resources

Do not expose one undifferentiated `memory`, `disk`, or `cpu` value without
semantic definitions. The Nix definition may declare minimum requirements and
hard bounds. Runtime create options request an actual allocation within those
bounds; the framework adapter may choose that allocation on the caller's
behalf.

Candidate distinctions:

- CPU concurrency versus CPU quota/weight;
- total sandbox memory ceiling versus guest workload memory ceiling;
- process/task ceiling;
- writable-root capacity;
- per-volume capacity;
- tmpfs capacity;
- I/O bandwidth or IOPS.

For a VM, assigned RAM includes the guest OS and devices. A host parent cgroup
can cap the whole VMM but cannot by itself express a guest process-count limit.
OCI cgroups expose richer workload controls. bubblewrap needs an outer cgroup
manager. See [OCI Linux resources](https://specs.opencontainers.org/runtime-spec/config-linux/?v=v1.3.0)
and [systemd resource control](https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html).

### Identity and security

The schema must not use a single `root = true|false` value. It must distinguish:

- workload-visible UID/GID;
- guest or container UID 0;
- host user-namespace mapping;
- privilege of the outer launcher;
- root-filesystem writability.

Portable security requirements can include:

- no new privileges;
- empty or explicit Linux capability sets;
- a versioned seccomp policy;
- explicit devices;
- explicit host channels.

These properties have different security meanings in a shared-host-kernel
sandbox and a microVM, so evidence must record where enforcement occurred.

### Secrets

A portable artifact secret slot may declare:

- destination as file, credential, or environment only when explicitly
  permitted;
- ownership and mode;
- audience;
- whether inclusion in a snapshot is forbidden or permitted.

The runtime create request binds a secret slot to a provider reference and
chooses a lifetime within the slot's constraints. The framework adapter may
collect or derive those bindings using framework-specific APIs.

Secret values never become Nix values, derivation inputs, image layers,
manifest environment values, argv, logs, or model-visible diagnostics.

### Lifecycle, snapshots, and persistence

These are core runtime operations and adapter choices, not Nix environment
options. A Nix definition may require that a compatible driver advertise one
of the optional capabilities, but it does not decide when an orchestrator uses
it.

Portable core lifecycle:

- create;
- inspect;
- execute;
- stop or terminate;
- delete retained state where one exists.

Capability-gated lifecycle:

- pause/resume;
- archive/restore;
- traffic-triggered wake;
- fork;
- dynamic resize;
- checkpoint/snapshot.

A checkpoint request describes captured components separately:

- filesystem;
- memory;
- emulated device state;
- mounted external storage;
- network connections;
- secret handling;
- compatibility domain;
- quiescing requirements.

There is no portable `snapshot = true`, `hibernate = true`, or
`persistent = true` boolean.

### Declared outputs

Result capture is owned by the core runtime API and its caller, and therefore
can be portable even when provider persistence is not. The Nix artifact may
publish conventional result paths, but it does not decide which results a
particular run captures or where the caller exports them.

Candidate forms:

- selected files or directories;
- archive;
- declared artifact;
- workspace patch produced by a trusted capture implementation;
- upper-layer export when the target supports it.

The common guarantee is that declared results are collected or the operation
fails. A direct writable workspace needs no export to preserve edits, but
direct mutation is not rollback, snapshotting, or atomic result capture.

## Capability-gated common-shaped options

These concepts may have a standard shape but must be advertised and validated
per artifact, driver, runtime variant, host, and provider:

- PTY and resize;
- background processes and stateful shells;
- exposed ports and previews;
- domain/CIDR egress policy;
- DNS enforcement;
- host channels and brokers;
- persistent volumes;
- GPU and other allocated devices;
- multiple users and groups;
- workload identity or OIDC;
- dynamic resource resizing;
- pause/resume;
- filesystem checkpoint;
- memory/device checkpoint;
- fork/clone;
- browser or desktop/computer-use;
- product-supervised services and readiness;
- warm pools;
- placement/region;
- dynamic policy replacement.

Capability support is not inferred from the target name alone. For example,
microvm.nix hypervisors differ substantially in share protocols and control
facilities, while OCI-compatible runtimes differ in kernel, device, filesystem,
and checkpoint behavior.

## Target-native configuration

Target-native configuration remains necessary:

### bubblewrap

- jail.nix combinators;
- explicit GUI/GPU/camera/audio permissions;
- bubblewrap-specific overlays;
- seccomp implementation details;
- raw runtime helpers only when they remain inspectable.

### microVM

- hypervisor selection;
- native NixOS modules;
- 9p/virtiofs choice;
- shares and block volumes;
- network interfaces and host forwarding;
- VMM packages, arguments, and device passthrough;
- arbitrary NixOS services.

### OCI

- OCI image configuration;
- OCI runtime configuration;
- runtime class;
- engine and CNI behavior;
- CDI device injection;
- hooks and annotations;
- engine-specific volumes, checkpointing, and inspection.

### Hosted providers

- provider template/image/snapshot IDs;
- cloud/region placement;
- provider volume, drive, bucket, or secret objects;
- warm pools;
- provider network transformations;
- billing- and retention-specific settings.

There is no `bypassValidate` flag. Raw arguments, hooks, pre-start scripts, or
arbitrary native modules may affect behavior that cannot be statically
understood. In strict policy mode they must either:

1. be projected into the final manifest and validated;
2. be disallowed; or
3. cause the specific affected guarantee to be explicitly marked unverified,
   preventing publication as a fully conformant artifact.

## Rejected common options

| Rejected option | Reason |
|---|---|
| `workspace.changes` or `workspace.writeback` | Combines access, retention, and result transfer |
| `persistent = bool` | Does not specify filesystem, memory, identity, TTL, mounted storage, or restore semantics |
| `snapshot = bool` | Does not specify captured components or restore guarantees |
| `network = host` | A VM cannot join the caller's network namespace with process-sandbox semantics |
| `disk = bytes` | Writable root, volume, tmpfs, and I/O constraints are different resources |
| `root = bool` | Guest root, namespace root, host mapping, launcher privilege, and rootfs writability differ |
| universal `image` | bwrap closure, microVM system, OCI image, and provider template are different artifacts |
| provider-selected defaults | Violates visible, reproducible configuration |
| `bypassValidate` | Converts a policy claim into an unchecked assertion |
| OpenAI `Shell`/`Filesystem`/`Memory`/`Compaction` in core | These are agent tool/harness capabilities, not isolation capabilities |
| unified secret values or credentials | Values must remain outside Nix and artifacts; provider mechanisms differ |
| generic `kill` | Providers use it for process termination, sandbox termination, or deletion |

## Target capability declaration

Each artifact and driver needs a versioned declaration keyed by:

- artifact target;
- target builder version;
- driver version;
- hypervisor or OCI runtime class;
- host platform;
- provider integration version.

Each capability records:

```text
semantic support
enforcement location
enforcement strength
static requirements
runtime requirements
conformance probe
known exclusions
native fields that invalidate the claim
```

Example shape:

```json
{
  "capability": "network.egress.controlled",
  "supported": true,
  "mechanism": "proxy",
  "enforcementLocation": "outer-host",
  "strength": "mandatory",
  "granularity": ["domain", "cidr", "port"],
  "requires": ["network-proxy/v1"],
  "probe": "network-policy/v1",
  "exclusions": ["unix-sockets", "vsock"],
  "invalidatedBy": ["targets.microvm.native.interfaces"]
}
```

Unknown optional capabilities are preserved or ignored. Unknown required
capabilities fail before create.

## Validation phases

“Compile time” means pure Nix evaluation of a fully forced, JSON-safe final
manifest. It does not include host or provider facts.

| Phase | What can fail here | What cannot be known yet |
|---|---|---|
| Evaluation | Unknown options, required fields, types, enums, ranges, duplicate logical IDs, deterministic cross-field conflicts, profile expansion, protected-option overrides, policy versus final-config conflicts, selected-target capability mismatch, package attributes and declared platform metadata, JSON projection | Successful package realization, builder behavior, host kernel/runtime/resources |
| Artifact build | Fetches, hashes, compilation, closure construction, OCI layout/config validation, VM image generation, artifact-local smoke tests, secret scanning | Actual target-host kernel features, KVM, user namespaces, cgroups, free ports, current quotas |
| Host preflight | Runtime version, architecture, kernel features, KVM, namespaces, cgroups, seccomp, mount source existence/ownership, storage, device/IOMMU allocation, port availability, secret provider, policy-enforcement component | Race-sensitive allocation and successful application by the runtime |
| Create/start | Provider/API acceptance, unique ID, actual port/device/tap allocation, hook failures, runtime application of requested configuration | Workload readiness and longer-term behavior |
| Post-create probe | Trusted control transport, exec, mounts, negative read-only writes, UID/GID, capabilities, no-new-privileges, cgroup state, devices, DNS/network probes, PTY, service readiness | Exhaustive proof of arbitrary program behavior |
| Runtime/teardown | Timeouts, peak resources, process exits, output capture, checkpoint result, secret revocation, cleanup, final evidence | Future behavior after termination |

No untrusted workload starts before preflight and the gated post-create probe
succeed.

### Nix evaluation architecture

Recommended structure:

1. Evaluate a typed module schema.
2. Pass portable policy outside the merge through read-only external arguments.
3. Protect policy-derived options with `readOnly`.
4. Evaluate generated and native configuration together.
5. Project every execution-affecting value into a JSON-safe manifest.
6. Run an outer validator over the final effective state.
7. Force the complete validation result with `deepSeq` and JSON serialization.
8. Return structured diagnostics as data.
9. Throw a rendered human message only when `nix build` or `nix flake check`
   requires failure behavior.

Module priority is not a security boundary. `mkForce` can itself be outranked,
and arbitrary modules can affect module-system behavior. See
[Nixpkgs modules](https://github.com/NixOS/nixpkgs/blob/master/lib/modules.nix).

`nix flake check` must expose and force a validation check for every enabled
target. A skipped host or conformance check reports `skipped`, never `passed`.

## Structured diagnostic contract

Diagnostic prose may improve over time; codes and data fields remain stable.

```json
{
  "protocolVersion": "1.0",
  "requestId": "req_...",
  "operation": "check",
  "ok": false,
  "diagnostics": [
    {
      "code": "SBX1101",
      "name": "POLICY_CONFLICT",
      "severity": "error",
      "phase": "evaluation",
      "summary": "Effective network mode violates portable policy",
      "detail": "Native configuration selected an unsupported mode.",
      "subject": {
        "sandbox": "api",
        "target": "microvm",
        "instancePath": "/network/mode",
        "optionPath": ["sandboxes", "api", "network", "mode"]
      },
      "sources": [
        {
          "role": "effective-definition",
          "uri": "workspace://native.nix",
          "line": 42,
          "column": 7,
          "precision": "exact"
        }
      ],
      "expected": {"allowed": ["none", "controlled"]},
      "actual": {"value": "host"},
      "fixes": [
        {"message": "Remove the override or select a supported network mode."}
      ],
      "retry": {"retryable": false, "transient": false},
      "origin": {"component": "sandbox-evaluator", "version": "1.0.0"},
      "fingerprint": "sha256:...",
      "documentation": "https://.../SBX1101",
      "extensions": {}
    }
  ]
}
```

Required fields:

- stable code and name;
- phase and severity;
- safe summary and detail;
- sandbox, target, and option/instance paths;
- source positions where available;
- expected and actual structured values;
- actionable fixes;
- retryability and transience;
- origin/version;
- deterministic fingerprint;
- documentation link;
- causal diagnostics;
- namespaced extensions.

Secret values, raw environment, unrestricted host paths, source excerpts with
credentials, stack traces, and complete Nix/provider logs never appear in
model-visible diagnostics.

Suggested initial codes:

| Code | Name |
|---|---|
| `SBX1001` | `UNKNOWN_OPTION` |
| `SBX1002` | `TYPE_MISMATCH` |
| `SBX1003` | `REQUIRED_FIELD_MISSING` |
| `SBX1004` | `MERGE_CONFLICT` |
| `SBX1101` | `POLICY_CONFLICT` |
| `SBX1102` | `PROTECTED_OPTION_OVERRIDE` |
| `SBX1201` | `TARGET_UNSUPPORTED` |
| `SBX1202` | `PACKAGE_METADATA_UNAVAILABLE` |
| `SBX1301` | `MANIFEST_NOT_SERIALIZABLE` |
| `SBX2001` | `ARTIFACT_BUILD_FAILED` |
| `SBX2002` | `ARTIFACT_INVALID` |
| `SBX3001` | `CAPABILITY_MISSING` |
| `SBX3002` | `HOST_RESOURCE_CONFLICT` |
| `SBX3003` | `RUNTIME_VERSION_UNSUPPORTED` |
| `SBX4001` | `CREATE_FAILED` |
| `SBX5001` | `POST_CREATE_PROBE_FAILED` |
| `SBX9001` | `NIX_EVALUATION_FAILED` |
| `SBX9002` | `PROTOCOL_ERROR` |
| `SBX9003` | `REQUIRED_EXTENSION_UNSUPPORTED` |

Recommended CLI exit classes:

- `0`: success;
- `2`: evaluation/validation;
- `3`: artifact build;
- `4`: host preflight;
- `5`: create/probe;
- `70`: internal/protocol.

### Nix subprocess boundary

Run Nix with structured logging and traces. Parse event structure and source
positions, never regex-match message prose into semantic codes. Nix documents
that log text may change.

If Nix fails before the evaluator emits the diagnostic envelope:

- return `SBX9001 NIX_EVALUATION_FAILED`;
- attach structured positions and trace frames as best-effort causes;
- keep the complete raw log behind a log reference.

### CLI

The CLI renders the same diagnostics:

```text
ERROR SBX1101 POLICY_CONFLICT [evaluation]
  api · microvm · /network/mode
  Effective value "host" violates portable policy.
  effective: native.nix:42
  fix: Remove the override or select a supported network mode.

1 error, 0 warnings; artifact build not started
```

Candidate commands:

- `sandbox check`;
- `sandbox explain`;
- `sandbox build`;
- `sandbox preflight`;
- `sandbox run`.

### Generic SDK

- `check()` returns a `ValidationResult`, including semantic errors.
- `build()` and `create()` raise `SandboxError` containing the same diagnostics
  when they cannot proceed.
- Every language preserves code, phase, paths, retryability, transience, causes,
  and safe remediation.
- No SDK exposes only an exception string.

### OpenAI Agents adapter

- Semantic validation failures become compact, safe structured tool results so
  an agent can repair a call.
- Unexpected infrastructure failures fail the run or invoke the framework's
  infrastructure-error handler.
- Model-visible data includes code, target, safe summary, and fix hints.
- Raw Nix logs, provider responses, host paths, secrets, and stack traces remain
  outside model context.
- Ordinary sandbox validation is not represented as a guardrail tripwire.

## Conformance and flake outputs

Recommended standard outputs:

```text
checks.<system>.sandbox-<name>-eval
checks.<system>.sandbox-<name>-manifest
checks.<system>.sandbox-<name>-artifact
checks.<system>.sandbox-<name>-conformance-offline

packages.<system>.sandbox-<name>-manifest
packages.<system>.sandbox-<name>-artifact

lib.evalSandbox
lib.validateSandbox
lib.diagnosticSchema

sandboxConfigurations.<name>.validation
sandboxConfigurations.<name>.manifest
```

Host preflight and live conformance are commands or CI jobs against declared
runner classes. They cannot be honestly represented as universally passing
Nix builds.

## Initial recommendations for design review

1. Lock the separation between Nix definition, create options, live operations,
   exec options, and framework adapters.
2. Permanently reject `workspace.changes` and generic writeback/persistence
   booleans.
3. Review the candidate common option groups before settling exact Nix names.
4. Define a capability descriptor before defining target-specific schemas.
5. Lock the six validation phases and structured diagnostic envelope.
6. Keep OpenAI capabilities exclusively in the adapter.
7. Do not add `bypassValidate`; unrestricted native configuration is trusted
   and may invalidate conformance.
8. Design artifact workspace constraints, runtime lifecycle
   retention/checkpointing, and runtime result capture in separate sections.

## Primary references

### Provider and framework

- [Codex permissions](https://developers.openai.com/codex/permissions)
- [OpenAI Sandbox Agents](https://developers.openai.com/api/docs/guides/agents/sandboxes)
- [OpenAI sandbox clients](https://openai.github.io/openai-agents-python/sandbox/clients)
- [E2B lifecycle](https://e2b.dev/docs/sandbox)
- [E2B persistence](https://e2b.dev/docs/sandbox/persistence)
- [E2B snapshots](https://e2b.dev/docs/sandbox/snapshots)
- [Modal Sandbox reference](https://modal.com/docs/reference/modal.Sandbox)
- [Modal snapshots](https://modal.com/docs/guide/sandbox-snapshots)
- [Daytona Sandbox API](https://www.daytona.io/docs/en/typescript-sdk/sandbox)
- [Daytona snapshots](https://www.daytona.io/docs/en/snapshots)
- [Daytona volumes](https://www.daytona.io/docs/en/volumes/)
- [Cloudflare Sandbox options](https://developers.cloudflare.com/sandbox/configuration/sandbox-options/)
- [Cloudflare lifecycle](https://developers.cloudflare.com/sandbox/concepts/sandboxes/)
- [Vercel Sandbox SDK](https://vercel.com/docs/vercel-sandbox/sdk-reference)
- [CodeSandbox lifecycle](https://codesandbox.io/docs/sdk/lifecycle)
- [Kubernetes Agent Sandbox API](https://agent-sandbox.sigs.k8s.io/docs/api)
- [OpenSandbox](https://github.com/opensandbox-group/OpenSandbox)
- [NVIDIA OpenShell](https://docs.nvidia.com/openshell/sandboxes/manage-sandboxes)

### Targets and standards

- [jail.nix combinators](https://alexdav.id/projects/jail-nix/combinators/)
- [jail.nix advanced configuration](https://alexdav.id/projects/jail-nix/advanced-configuration)
- [bubblewrap security model](https://github.com/containers/bubblewrap/blob/main/README.md)
- [bubblewrap manual](https://manpages.debian.org/experimental/bubblewrap/bwrap.1.en.html)
- [microvm.nix](https://github.com/microvm-nix/microvm.nix)
- [microvm.nix options](https://microvm-nix.github.io/microvm.nix/microvm-options.html)
- [microvm.nix shares](https://microvm-nix.github.io/microvm.nix/shares.html)
- [OCI Image Configuration](https://specs.opencontainers.org/image-spec/config/)
- [OCI Runtime Configuration](https://specs.opencontainers.org/runtime-spec/config/)
- [OCI Linux Configuration](https://specs.opencontainers.org/runtime-spec/config-linux/?v=v1.3.0)
- [OCI lifecycle](https://specs.opencontainers.org/runtime-spec/runtime/)
- [OCI runtime features](https://github.com/opencontainers/runtime-spec/blob/main/features.md)
- [runc operations](https://github.com/opencontainers/runc/blob/main/man/runc.8.md)
- [Firecracker snapshot support](https://github.com/firecracker-microvm/firecracker/blob/main/docs/snapshotting/snapshot-support.md)
- [Landlock](https://www.kernel.org/doc/html/latest/userspace-api/landlock.html)
- [systemd resource control](https://www.freedesktop.org/software/systemd/man/latest/systemd.resource-control.html)

### Nix and diagnostics

- [Nix module tutorial](https://nix.dev/tutorials/module-system/a-basic-module/index.html)
- [Nixpkgs module implementation](https://github.com/NixOS/nixpkgs/blob/master/lib/modules.nix)
- [Nix builtins](https://nix.dev/manual/nix/2.35/language/builtins.html)
- [nix flake check](https://nix.dev/manual/nix/2.24/command-ref/new-cli/nix3-flake-check)
- [flake-parts debug](https://flake.parts/debug)
- [Arion architecture](https://docs.hercules-ci.com/arion/)
- [RFC 8785 JSON Canonicalization Scheme](https://www.rfc-editor.org/rfc/rfc8785)
- [OpenAI Agents tools and failures](https://openai.github.io/openai-agents-python/tools/)

## Research artifacts

Independent research reports and extracted evidence are stored under `/tmp`.
The cross-provider deep-research continuation identifier is:

```text
trun_10e52f8986cf485f91f1cfe7f3776d14
```

The generated report is:

```text
/tmp/sandbox-option-surface-research.md
/tmp/sandbox-option-surface-research.json
```

The generated report is useful for source discovery but is not authoritative.
It contains several overgeneralizations corrected in this synthesis, including:

- treating OpenAI agent capabilities as sandbox isolation capabilities;
- overstating OCI lifecycle and persistence semantics;
- attributing generic snapshot/GPU/secure-boot options to microvm.nix;
- recommending validation bypasses;
- collapsing provider defaults into a portable schema.
