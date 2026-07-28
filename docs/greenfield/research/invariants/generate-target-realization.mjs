#!/usr/bin/env node

import fs from "node:fs";
import path from "node:path";
import { fileURLToPath } from "node:url";

const directory = path.dirname(fileURLToPath(import.meta.url));
const fieldsDocument = JSON.parse(
  fs.readFileSync(path.join(directory, "PACKET-B-ARTIFACT-FIELDS.json"), "utf8"),
);
const profilesDocument = JSON.parse(
  fs.readFileSync(path.join(directory, "PACKET-C-TARGET-PROFILES.json"), "utf8"),
);

const fieldById = new Map(fieldsDocument.fields.map((field) => [field.id, field]));
const profileIds = profilesDocument.profiles.map((profile) => profile.id);

const BUBBLEWRAP = ["bubblewrap-linux-v1"];
const FIRECRACKER = ["microvm-firecracker-linux-v1"];
const CLOUD_HYPERVISOR = ["microvm-cloud-hypervisor-linux-v1"];
const MICROVMS = [...FIRECRACKER, ...CLOUD_HYPERVISOR];
const OCI = ["oci-linux-v1"];
const ALL = [...BUBBLEWRAP, ...MICROVMS, ...OCI];
const TARGET_INTRODUCED_INVARIANTS = [
  "MAN-005",
  "MAN-006",
  "HOST-004",
  "HOST-005",
  "SNP-002",
];

const RULE_INVARIANTS = new Map([
  ["TRL-001-COMMON-IDENTITY", ["MAN-006"]],
  ["TRL-045-CONDITIONAL-CONSTRUCTION-CLAIMS", ["TGT-003", "MAN-006"]],
  ["TRL-039-REQUIREMENT-CLOSURE", ["TGT-003", "HOST-004"]],
  ["TRL-008-BUBBLEWRAP-WORKSPACE", ["HOST-005"]],
  ["TRL-009-FIRECRACKER-WORKSPACE", ["HOST-005"]],
  ["TRL-010-CLOUD-HYPERVISOR-WORKSPACE", ["HOST-005"]],
  ["TRL-011-OCI-WORKSPACE", ["HOST-005"]],
  ["TRL-012-BUBBLEWRAP-BINDING-FILESYSTEM", ["HOST-005"]],
  ["TRL-013-MICROVM-BINDING-FILESYSTEM", ["HOST-005"]],
  ["TRL-014-OCI-BINDING-FILESYSTEM", ["HOST-005"]],
  ["TRL-042-MICROVM-SNAPSHOT", ["SNP-002"]],
]);

const commonFacts = [
  "artifact.profile.selection",
  "artifact.profile.expansion",
  "artifact.profile.compositionPaths",
  "artifact.metadata.descriptive",
  "artifact.workspace.runtimeTransferExclusion",
  "artifact.provenance.profile",
  "artifact.provenance.semanticIdentity",
  "artifact.provenance.builtIdentities",
  "artifact.targets.enabled",
  "artifact.targets.commonContract",
  "artifact.targets.artifactSet",
];

const conditionalConstructionFacts = [
  "artifact.provenance.requirements",
  "artifact.provenance.native",
  "artifact.targets.runtimeProfiles",
  "artifact.targets.nativeConstruction",
  "artifact.targets.memberConstruction",
];

const softwareContent = [
  "artifact.platform.workload",
  "artifact.environment.packages",
  "artifact.environment.devShell",
  "artifact.filesystem.immutableInputs",
];

const closedEnvironment = [
  "artifact.environment.variables",
  "artifact.environment.searchPath",
  "artifact.environment.ambientExclusion",
  "artifact.process.environment",
];

const defaultProcess = [
  "artifact.process.argv",
  "artifact.process.cwd",
  "artifact.process.omission",
];

const identityFields = [
  "artifact.process.identity",
  "artifact.identity.user",
  "artifact.identity.groups",
  "artifact.identity.hostMappingExclusion",
];

const workspaceFields = [
  "artifact.workspace.slot",
  "artifact.workspace.destination",
  "artifact.workspace.access",
  "artifact.workspace.materializations",
  "artifact.workspace.ownership",
  "artifact.workspace.required",
  "artifact.requirements.workspace",
];

const bindingFilesystemFields = [
  "artifact.filesystem.mountSlots",
  "artifact.filesystem.volumeSlots",
  "artifact.resources.volumeCapacity",
];

const topologyFields = [
  "artifact.workspace.protectedPaths",
  "artifact.filesystem.topology",
];

const scratchFields = [
  "artifact.filesystem.scratch",
  "artifact.resources.tmpfsCapacity",
];

const writableRootFields = [
  "artifact.filesystem.writableRoot",
  "artifact.resources.writableRootCapacity",
  "artifact.security.rootFilesystem",
];

const networkFields = [
  "artifact.network.access",
  "artifact.network.egress",
  "artifact.network.dns",
  "artifact.network.ingressPorts",
  "artifact.network.credentialSlots",
  "artifact.network.hostChannels",
];

const commonResourceFields = [
  "artifact.resources.cpuConcurrency",
  "artifact.resources.cpuRate",
  "artifact.resources.memoryTotal",
  "artifact.resources.swap",
  "artifact.resources.tasks",
];

const securityPolicyFields = [
  "artifact.security.noNewPrivileges",
  "artifact.security.capabilities",
  "artifact.security.kernelPolicies",
];

const secretFields = [
  "artifact.secretSlots.identity",
  "artifact.secretSlots.delivery",
  "artifact.secretSlots.destination",
  "artifact.secretSlots.audienceLifetime",
  "artifact.secretSlots.snapshotTreatment",
];

const requirementFields = [
  "artifact.requirements.capabilities",
  "artifact.requirements.protocols",
  "artifact.requirements.enforcement",
];

const lifetimeFields = [
  "artifact.lifecycleRequirements.maximumLifetime",
  "artifact.lifecycleRequirements.maximumLifetimeEnforcement",
];

const outputFields = [
  "artifact.outputs.declarations",
  "artifact.outputs.filesystemCompatibility",
  "artifact.outputs.runtimeCollection",
];

const STORAGE_RUNTIME_STEPS = {
  create:
    "Resolve each per-Sandbox storage or scratch allocation within the Artifact's declared kind, access, ownership, cardinality, and hard-capacity contract.",
  operator:
    "Apply operator placement, quota, backing-store, retention, and cleanup ceilings without changing Artifact semantics.",
  preflight:
    "Allocate or retain stable handles to the concrete storage objects and prove capacity, ownership, isolation, and cleanup support before driver preparation.",
};

const NETWORK_RUNTIME_STEPS = {
  create:
    "Resolve every logical ingress, credential, DNS, egress, and host-channel binding requested for this Sandbox within the Artifact contract.",
  operator:
    "Select registered network-policy, proxy, broker, placement, and endpoint implementations under operator ceilings.",
  preflight:
    "Create and verify the concrete network namespace, TAP/interface, firewall, proxy, resolver, ingress, credential, and channel resources before driver preparation.",
};

const RESOURCE_RUNTIME_STEPS = {
  create:
    "Resolve requested per-Sandbox allocations within every Artifact minimum, maximum, dimension, unit, and scope.",
  operator:
    "Apply operator quota, placement, controller, overcommit, and accounting ceilings without weakening Artifact hard bounds.",
  preflight:
    "Reserve capacity, create the complete process-tree controller boundary, and verify required host controllers and accounting scopes before driver preparation.",
};

const SECURITY_RUNTIME_STEPS = {
  operator:
    "Bind the profile to registered architecture-specific policy compilers, kernel mechanisms, and outer-confinement implementations.",
  preflight:
    "Verify the concrete host kernel, policy, privilege, namespace, and outer-confinement capabilities fail closed before driver preparation.",
};

const DEVICE_RUNTIME_STEPS = {
  create:
    "Resolve each logical device request, count, and access mode to a per-Sandbox allocation request without embedding host device identity in the Artifact.",
  operator:
    "Select the registered device allocator and apply operator isolation, placement, and authority ceilings.",
  preflight:
    "Allocate and retain stable device handles, then verify identity, isolation, count, access, and every projected mount, group, capability, policy, and channel effect.",
};

const SECRET_RUNTIME_STEPS = {
  create:
    "Resolve each value-free secret slot to an authorized sealed value handle with the declared audience and lifetime.",
  operator:
    "Select a registered delivery broker and apply operator source, audience, rotation, redaction, and retention policy.",
  preflight:
    "Verify delivery paths, destinations, ownership, modes, helper availability, expiry, cleanup, and snapshot treatment without disclosing values.",
};

const LIFETIME_RUNTIME_STEPS = {
  create:
    "Resolve the requested per-Sandbox expiration no later than the Artifact maximum and propagate the remaining monotonic lifetime to all operations.",
  operator:
    "Apply any stricter operator lifetime ceiling and select the registered complete-tree termination and cleanup controller.",
  preflight:
    "Arm and verify the concrete monotonic deadline, termination path, provider timeout, and cleanup reservation before start.",
};

function condition(kind, extra = {}) {
  return { kind, ...extra };
}

function step(phase, mode, component, explanation) {
  return { phase, mode, component, explanation };
}

function preserved({
  id = "all-values",
  when = condition("all-values"),
  mechanism,
  manifest,
  evidence,
  rationale,
  remediation = "Use a value supported by the selected target profile.",
}) {
  return {
    id,
    condition: when,
    outcome: "conforming-lowering",
    firstSoundPhase: "N0",
    deadline: "N1",
    authority: { phase: "N1", component: "target-member-builder" },
    steps: [
      step(
        "N1",
        "preserved-no-emission",
        "target-member-builder",
        mechanism,
      ),
    ],
    manifestBehavior: manifest,
    fallbackPolicy: "forbidden",
    approximationPolicy: "forbidden",
    remediation,
    evidence,
    rationale,
  };
}

function built({
  id = "all-values",
  when = condition("all-values"),
  mechanism,
  manifest,
  evidence,
  rationale,
  remediation = "Use content constructible for the selected workload platform and profile.",
}) {
  return {
    id,
    condition: when,
    outcome: "conforming-lowering",
    firstSoundPhase: "N0",
    deadline: "N1",
    authority: { phase: "N1", component: "target-member-builder" },
    steps: [
      step("N1", "built-content", "target-member-builder", mechanism),
    ],
    manifestBehavior: manifest,
    fallbackPolicy: "forbidden",
    approximationPolicy: "forbidden",
    remediation,
    evidence,
    rationale,
  };
}

function observedRuntimeBinding({
  id,
  when,
  create,
  preflight,
  prepare,
  manifest,
  evidence,
  rationale,
  remediation,
}) {
  return {
    id,
    condition: when,
    outcome: "observed-conformance",
    firstSoundPhase: "C0",
    deadline: "R1",
    authority: { phase: "R1", component: "target-conformance-probe" },
    steps: [
      step("C0", "create-binding", "creation-resolver", create),
      step(
        "O0",
        "operator-binding",
        "operator-resolver",
        "Apply operator source, placement, allocation, quota, and host-policy ceilings to the selected binding without widening the Artifact contract.",
      ),
      step("H0", "host-preflight", "operator-preflight", preflight),
      step("D0", "driver-preparation", "target-driver", prepare),
      step(
        "R1",
        "post-start-probe",
        "target-conformance-probe",
        "Verify the effective binding identity, cardinality, destination, access, ownership, capacity, and required lifecycle behavior before readiness.",
      ),
    ],
    manifestBehavior: manifest,
    fallbackPolicy: "forbidden",
    approximationPolicy: "forbidden",
    remediation,
    evidence,
    rationale,
  };
}

function observed({
  id = "all-values",
  when = condition("all-values"),
  build,
  create,
  operator,
  preflight,
  prepare,
  probe,
  manifest,
  evidence,
  rationale,
  remediation = "Select a profile and host whose required conformance probe succeeds.",
}) {
  return {
    id,
    condition: when,
    outcome: "observed-conformance",
    firstSoundPhase: "N0",
    deadline: "R1",
    authority: { phase: "R1", component: "target-conformance-probe" },
    steps: [
      step("N1", "manifest-only", "target-member-builder", build),
      ...(create
        ? [step("C0", "create-binding", "creation-resolver", create)]
        : []),
      ...(operator
        ? [step("O0", "operator-binding", "operator-resolver", operator)]
        : []),
      ...(preflight
        ? [step("H0", "host-preflight", "operator-preflight", preflight)]
        : []),
      step("D0", "driver-preparation", "target-driver", prepare),
      step("R1", "post-start-probe", "target-conformance-probe", probe),
    ],
    manifestBehavior: manifest,
    fallbackPolicy: "forbidden",
    approximationPolicy: "forbidden",
    remediation,
    evidence,
    rationale,
  };
}

function unsupported({
  id = "unsupported",
  when = condition("otherwise"),
  phase = "A1",
  reason,
  manifest,
  evidence = ["target-build-rejection", "secret-safe-target-diagnostic"],
  remediation,
}) {
  const component =
    phase === "A1" ? "artifact-final-validator" : "target-member-builder";
  return {
    id,
    condition: when,
    outcome: "build-time-unsupported",
    firstSoundPhase: phase,
    deadline: phase,
    authority: { phase, component },
    steps: [
      step(
        phase,
        "build-rejection",
        component,
        reason,
      ),
    ],
    manifestBehavior: manifest,
    fallbackPolicy: "forbidden",
    approximationPolicy: "forbidden",
    remediation,
    evidence,
    rationale: reason,
  };
}

const specs = [];

function addRule(id, fieldIds, selectedProfiles, cases) {
  specs.push({ id, fieldIds, profileIds: selectedProfiles, cases });
}

addRule("TRL-001-COMMON-IDENTITY", commonFacts, ALL, [
  built({
    mechanism:
      "Preserve normalized common semantics, construct requested members, and emit typed semantic, member, content, profile, evidence, and Artifact Set relations without target inference.",
    manifest:
      "Record the common semantic digest, complete member graph, exact target/profile requirements, builder-produced support facts, construction pins, and explanation provenance in their distinct identity domains.",
    evidence: [
      "canonical-artifact-wire",
      "target-member-content-digests",
      "artifact-set-graph-validation",
      "builder-conformance-evidence-linkage",
    ],
    rationale:
      "These fields define or describe the common contract and construction result; they never lower to backend defaults.",
  }),
]);

addRule(
  "TRL-045-CONDITIONAL-CONSTRUCTION-CLAIMS",
  conditionalConstructionFacts,
  ALL,
  [
    built({
      id: "registered-and-constructible",
      when: condition("constraint-satisfied", {
        requirement:
          "Every requested runtime profile, provenance claim, native-construction contract, and member-construction contract is registered, exactly pinned, mutually compatible, and constructible with member-bound support evidence.",
      }),
      mechanism:
        "Resolve the complete registered construction closure and emit only builder-produced profile, native, member, provenance, support, and evidence facts bound to the exact constructed member.",
      manifest:
        "Record exact component and protocol identities, construction pins, compatibility results, member relations, provenance, and conformance-evidence references in their distinct identity domains.",
      evidence: [
        "registered-construction-closure",
        "exact-component-and-protocol-pins",
        "member-bound-builder-support-facts",
        "construction-conformance-evidence",
      ],
      rationale:
        "Construction and provenance claims are true only for a complete registered implementation closure, not merely because the common schema accepted their shape.",
    }),
    unsupported({
      phase: "N1",
      reason:
        "Reject any requested profile, mandatory provenance claim, native-construction contract, or member-construction contract whose implementation, exact identity, compatibility, construction path, or member-bound evidence is missing.",
      manifest:
        "Publish no target member, profile association, native handle, provenance claim, or support claim for the unresolved construction contract.",
      remediation:
        "Select a fully registered construction profile and satisfy every exact component, protocol, provenance, compatibility, and conformance-evidence requirement.",
    }),
  ],
);

addRule("TRL-002-SOFTWARE-CONTENT", softwareContent, ALL, [
  built({
    id: "constructible-platform-content",
    when: condition("constraint-satisfied", {
      requirement:
        "Every referenced input resolves reproducibly for the declared Linux workload platform and architecture, and the selected member builder can represent it.",
    }),
    mechanism:
      "Resolve pinned Nix inputs for the declared workload platform and place their exact closures or filesystem content into the target member.",
    manifest:
      "Record the workload platform, importer versions, source identities, closure/content digests, and target-member projection.",
    evidence: [
      "pinned-nix-input-resolution",
      "cross-platform-closure-build",
      "member-content-digest",
    ],
    rationale:
      "Target construction can preserve only content built for the explicitly declared workload platform.",
  }),
  unsupported({
    phase: "N1",
    reason:
      "Reject a non-Linux workload, an unregistered architecture/emulation requirement, an unresolved input, a current-host path, or content the selected target member cannot represent.",
    manifest:
      "Publish no member or support claim for the rejected target/profile.",
    remediation:
      "Select a supported Linux workload platform and replace every unresolved or host-dependent input with a pinned constructible reference.",
  }),
]);

addRule("TRL-003-CLOSED-ENVIRONMENT", closedEnvironment, ALL, [
  observed({
    build:
      "Record the exact closed non-secret environment and ordered search path, including explicit absence.",
    prepare:
      "Clear ambient driver, image, guest, provider, and host environment, then install only the validated map and explicit search path.",
    probe:
      "Inspect the launched process environment and prove that omitted, reserved, secret, and ambient values are absent.",
    manifest:
      "Reproduce the normalized environment map and search path exactly; record the closed-environment requirement and reserved-name policy version.",
    evidence: [
      "manifest-environment-projection",
      "effective-process-environment",
      "ambient-environment-negative-probe",
    ],
    rationale:
      "Built metadata cannot prove that a driver, image, guest, or provider did not reintroduce ambient environment.",
  }),
]);

addRule("TRL-004-ACTIVATION", ["artifact.environment.activation"], ALL, [
  observed({
    id: "registered-activation-semantics",
    when: condition("constraint-satisfied", {
      requirement:
        "Every activation executable is present in built content, has an exact identity, and the selected launcher or guest runtime implements the ordered direct-argv, final-isolation, fail-closed activation protocol.",
    }),
    build:
      "Identify every activation executable and preserve the ordered argv sequence without a shell.",
    prepare:
      "Run activation under final isolation through the product launcher or guest runtime before the main Process, failing closed on the first error.",
    probe:
      "Verify activation order, executable identity, environment, isolation, and failure behavior.",
    manifest:
      "Record ordered argv arrays and executable identities; never record or synthesize a shell hook.",
    evidence: [
      "activation-executable-identities",
      "activation-order-probe",
      "activation-failure-probe",
    ],
    rationale:
      "Activation is deterministic Artifact process semantics but executes only at runtime under target isolation.",
  }),
  unsupported({
    phase: "N1",
    reason:
      "Reject activation when any executable identity, ordered direct-argv semantic, final-isolation guarantee, or fail-closed behavior is not implemented by the selected profile.",
    manifest:
      "Publish no member/profile support claim for unsupported activation semantics and never translate activation into a shell hook.",
    remediation:
      "Use built activation executables and a registered profile whose launcher or guest runtime implements the exact activation protocol.",
  }),
]);

addRule("TRL-005-DEFAULT-PROCESS", defaultProcess, ALL, [
  observed({
    build:
      "Preserve the complete default-Process presence bitmap, argv, cwd, and explicit absence in the member manifest.",
    prepare:
      "Use direct argv execution and an explicit permitted cwd; suppress image entrypoints, provider commands, guest defaults, shells, and inherited cwd.",
    probe:
      "Verify argv, executable, cwd, and absence semantics for any instantiated default Process.",
    manifest:
      "Record explicit values or explicit absence exactly as normalized; omission never requests target inheritance or automatic start.",
    evidence: [
      "manifest-default-process-projection",
      "effective-argv-and-cwd",
      "backend-default-negative-probe",
    ],
    rationale:
      "A target can silently change workload behavior through entrypoint or cwd defaults unless absence is emitted and tested.",
  }),
]);

addRule("TRL-006-BUBBLEWRAP-IDENTITY", identityFields, BUBBLEWRAP, [
  observed({
    id: "representable-user-namespace-identity",
    when: condition("constraint-satisfied", {
      requirement:
        "The workload identity resolves from built content and the exact UID, GID, supplementary groups, and host mapping can be installed by the registered user-namespace launcher.",
    }),
    build:
      "Record only workload-visible identity and the required mapping capability; never record host accounts or mappings.",
    prepare:
      "Create a strict mapped user namespace, clear ambient groups, and install the exact UID, GID, and supplementary-group contract before exec.",
    probe:
      "Inspect uid_map, gid_map, setgroups state, real/effective IDs, and the complete supplementary-group set.",
    manifest:
      "Record the workload identity plus the registered mapping protocol requirement; host mapping remains effective runtime evidence.",
    evidence: [
      "built-identity-resolution",
      "user-namespace-map-evidence",
      "effective-identity-probe",
    ],
    rationale:
      "Bubblewrap flags alone do not represent arbitrary multi-user or supplementary-group contracts.",
  }),
  unsupported({
    phase: "N1",
    reason:
      "Reject an identity relationship that the registered non-setuid Bubblewrap user-namespace launcher cannot install exactly.",
    manifest:
      "Publish no Bubblewrap profile support claim for the unrepresentable identity contract.",
    remediation:
      "Use a representable numeric workload identity and group set or select a target profile with a proven identity mechanism.",
  }),
]);

addRule("TRL-007-GUEST-AND-OCI-IDENTITY", identityFields, [...MICROVMS, ...OCI], [
  observed({
    id: "representable-runtime-identity",
    when: condition("constraint-satisfied", {
      requirement:
        "Names resolve from constructed content and the guest runtime or OCI runtime can install the exact UID, GID, and supplementary-group set.",
    }),
    build:
      "Resolve names inside built content and record only workload-visible identity plus the required runtime protocol.",
    prepare:
      "Install the exact process identity inside the guest or OCI process configuration while keeping host and VMM identity separate.",
    probe:
      "Inspect the workload process IDs and complete group set and prove no host mapping or ambient group entered portable semantics.",
    manifest:
      "Record resolved workload identity and protocol requirements; runtime host mappings remain redacted evidence only.",
    evidence: [
      "built-identity-resolution",
      "runtime-identity-configuration",
      "effective-identity-probe",
    ],
    rationale:
      "Guest/VMM and container-host identities are separate authority layers from the workload identity.",
  }),
  unsupported({
    phase: "N1",
    reason:
      "Reject an identity or group relationship that the selected guest runtime or OCI runtime profile cannot install exactly.",
    manifest:
      "Publish no runtime-profile support claim for the unrepresentable identity contract.",
    remediation:
      "Use an identity representable by the selected runtime protocol or select another conformed profile.",
  }),
]);

addRule("TRL-008-BUBBLEWRAP-WORKSPACE", workspaceFields, BUBBLEWRAP, [
  observedRuntimeBinding({
    id: "supported-workspace-materialization",
    when: condition("constraint-satisfied", {
      requirement:
        "The workspace contract permits an owned copy-in tree, an FD-pinned bind, or another registered Bubblewrap materialization with exact access and ownership semantics.",
    }),
    create:
      "Select one permitted materialization and bind exactly one required logical workspace slot.",
    preflight:
      "Resolve and retain dynamic sources by safe file descriptor, verify ownership and access, and prepare copy-in content when selected.",
    prepare:
      "Mount the workspace at the declared destination using FD-safe read-only or read-write operations and apply protected subpaths afterward.",
    manifest:
      "Record the value-free workspace slot, destination, access ceiling, ownership expectations, permitted materializations, and required capability identities.",
    evidence: [
      "workspace-binding-cardinality",
      "fd-safe-source-resolution",
      "effective-workspace-mount",
      "workspace-access-probe",
    ],
    rationale:
      "The Artifact defines the workspace contract while Create and the selected host supply the concrete source.",
    remediation:
      "Choose a permitted Bubblewrap workspace materialization and a binding whose ownership and access satisfy the declared contract.",
  }),
  unsupported({
    reason:
      "Reject a mandatory workspace materialization, ownership mapping, or access contract not implemented by the Bubblewrap profile.",
    manifest:
      "Publish no Bubblewrap support claim for the unsupported workspace contract.",
    remediation:
      "Permit copy-in or FD-safe bind semantics that preserve the declared workspace contract, or select another profile.",
  }),
]);

addRule("TRL-009-FIRECRACKER-WORKSPACE", workspaceFields, FIRECRACKER, [
  observedRuntimeBinding({
    id: "copy-or-prepared-block-workspace",
    when: condition("constraint-satisfied", {
      requirement:
        "The required workspace can use copy-in or a prepared block image with exact ownership and access; live host-directory sharing is not mandatory.",
    }),
    create:
      "Select copy-in or prepared-block materialization and bind the logical workspace slot without embedding a host path in the member.",
    preflight:
      "Construct or identify the content-addressed workspace payload or bounded block image and verify capacity, ownership, and read-only/read-write semantics.",
    prepare:
      "Attach only the prepared workspace device or transfer content through the guest runtime before workload start.",
    manifest:
      "Record the workspace contract and Firecracker-supported materialization subset; runtime source and block identity remain effective configuration.",
    evidence: [
      "workspace-materialization-intersection",
      "prepared-block-identity",
      "guest-workspace-mount-probe",
    ],
    rationale:
      "Firecracker has no conforming live host-directory share in the initial profile.",
    remediation:
      "Permit copy-in or prepared-block workspace materialization, or select the qualified Cloud Hypervisor profile for live sharing.",
  }),
  unsupported({
    reason:
      "Reject a mandatory live host-filesystem workspace, an unrepresentable ownership translation, or an unsupported workspace device contract.",
    manifest:
      "Publish no Firecracker support claim and do not substitute copy-in for a mandatory live workspace.",
    remediation:
      "Change the Artifact's permitted materializations explicitly or select a profile with proven live sharing.",
  }),
]);

addRule("TRL-010-CLOUD-HYPERVISOR-WORKSPACE", workspaceFields, CLOUD_HYPERVISOR, [
  observedRuntimeBinding({
    id: "supported-cloud-hypervisor-workspace",
    when: condition("constraint-satisfied", {
      requirement:
        "The workspace uses copy-in, prepared block, or qualified virtiofs with shared memory, confined helper, exact ownership translation, and proven read-only/read-write semantics.",
    }),
    create:
      "Select one permitted workspace materialization and bind exactly one logical slot.",
    preflight:
      "For live virtiofs, resolve the source safely, verify translation and access, and place virtiofsd inside the VMM jail and resource-accounting boundary.",
    prepare:
      "Configure the explicit workspace device/share and guest mount; no implicit microvm.nix share is inherited.",
    manifest:
      "Record the workspace contract and exact supported materialization subset, including the required virtiofs/helper protocol when applicable.",
    evidence: [
      "workspace-materialization-intersection",
      "virtiofs-helper-confinement",
      "guest-workspace-access-probe",
    ],
    rationale:
      "Cloud Hypervisor live sharing is conforming only as a qualified multi-component profile.",
    remediation:
      "Use copy-in, prepared block, or a virtiofs binding satisfying every helper, memory, ownership, and access precondition.",
  }),
  unsupported({
    reason:
      "Reject live sharing without shared memory, helper confinement/accounting, exact ownership translation, or access conformance.",
    manifest:
      "Publish no Cloud Hypervisor support claim for the unsupported workspace relation.",
    remediation:
      "Satisfy the qualified virtiofs profile or select copy/block materialization explicitly.",
  }),
]);

addRule("TRL-011-OCI-WORKSPACE", workspaceFields, OCI, [
  observedRuntimeBinding({
    id: "supported-oci-workspace",
    when: condition("constraint-satisfied", {
      requirement:
        "The registered OCI driver can realize one permitted copy, bind, or independent-volume materialization with exact access, ownership, propagation, and path-safety semantics.",
    }),
    create:
      "Select one permitted materialization and bind the logical workspace slot.",
    preflight:
      "Resolve the source safely and verify ownership, capacity, propagation, and runtime support.",
    prepare:
      "Generate an explicit OCI mount and user mapping without inheriting image volumes or runtime mount defaults.",
    manifest:
      "Record the value-free workspace contract and required mount/mapping protocol; runtime source is effective configuration only.",
    evidence: [
      "workspace-binding-cardinality",
      "oci-mount-generation",
      "effective-workspace-access-probe",
    ],
    rationale:
      "OCI images describe content while concrete workspace sources belong to creation and runtime configuration.",
    remediation:
      "Use a registered OCI materialization whose mount and ownership semantics preserve the Artifact contract.",
  }),
  unsupported({
    reason:
      "Reject a workspace source, mapping, propagation, or access contract the registered OCI runtime profile cannot enforce.",
    manifest:
      "Publish no OCI profile support claim for the unsupported workspace contract.",
    remediation:
      "Use a supported copy, bind, or volume materialization or select another target profile.",
  }),
]);

for (const [id, selectedProfiles, mechanism] of [
  [
    "TRL-012-BUBBLEWRAP-BINDING-FILESYSTEM",
    BUBBLEWRAP,
    "FD-safe bind, owned copy-in tree, or quota-backed/preallocated storage registered by the Bubblewrap profile",
  ],
  [
    "TRL-013-MICROVM-BINDING-FILESYSTEM",
    MICROVMS,
    "prepared block device, guest-runtime copy, or profile-qualified Cloud Hypervisor virtiofs share",
  ],
  [
    "TRL-014-OCI-BINDING-FILESYSTEM",
    OCI,
    "explicit OCI bind, tmpfs, or independent managed-volume mount with registered quota and mapping support",
  ],
]) {
  addRule(id, bindingFilesystemFields, selectedProfiles, [
    observedRuntimeBinding({
      id: "supported-binding-class",
      when: condition("constraint-satisfied", {
        requirement:
          "Every required mount or volume source kind, capacity range, access mode, cardinality, ownership relation, and destination is implemented by the selected profile.",
      }),
      create:
        "Resolve every required logical slot exactly once and select only a permitted source kind.",
      preflight:
        `Allocate or validate the concrete source using ${mechanism}; prove capacity and ownership before launch.`,
      prepare:
        "Attach or mount the source at the exact destination with access no wider than the Artifact ceiling.",
      manifest:
        "Record only value-free slot contracts, capacity ranges, destinations, access, cardinality, and required realization protocols.",
      evidence: [
        "slot-binding-cardinality",
        "source-identity-and-capacity-preflight",
        "effective-mount-and-access-probe",
      ],
      rationale:
        "Concrete mount and volume identity is runtime state, while the Artifact fixes its complete admissible contract.",
      remediation:
        "Supply a binding within the declared contract and supported source/capacity classes.",
    }),
    unsupported({
      reason:
        `Reject any mandatory binding or hard capacity semantic not exactly representable by ${mechanism}.`,
      manifest:
        "Publish no target-profile support claim for the unsupported binding contract.",
      remediation:
        "Use a supported source kind and enforceable capacity contract or select another profile.",
    }),
  ]);
}

addRule("TRL-015-FILESYSTEM-TOPOLOGY", topologyFields, ALL, [
  observed({
    build:
      "Compile one conflict-free ordered path graph with every immutable, writable, protected, masked, secret, and output relation explicit.",
    prepare:
      "Apply target-specific mounts and protections in the sealed graph order without raw arguments, hooks, or later shadowing.",
    probe:
      "Inspect effective mounts and test positive and negative path access, protection, ownership, and non-shadowing.",
    manifest:
      "Record the canonical topology digest, ordered typed relations, and required filesystem conformance class.",
    evidence: [
      "filesystem-topology-digest",
      "effective-mount-graph",
      "protected-path-negative-probe",
    ],
    rationale:
      "A correct static graph can still be weakened by target mount ordering or runtime defaults.",
  }),
]);

for (const [id, selectedProfiles, mechanism] of [
  [
    "TRL-016-BUBBLEWRAP-SCRATCH",
    BUBBLEWRAP,
    "explicit sized tmpfs mounts, with each size bound attached to the intended mount",
  ],
  [
    "TRL-017-MICROVM-SCRATCH",
    MICROVMS,
    "guest tmpfs or an explicitly bounded private block-backed scratch device plus guest and outer accounting",
  ],
  [
    "TRL-018-OCI-SCRATCH",
    OCI,
    "explicit OCI tmpfs mounts and registered runtime resource accounting",
  ],
]) {
  addRule(id, scratchFields, selectedProfiles, [
    observed({
      build:
        "Record every scratch identity, destination, medium class, hard capacity, and required accounting scope.",
      ...STORAGE_RUNTIME_STEPS,
      prepare:
        `Realize scratch with ${mechanism}; never import a backend tmpfs or writable-layer default.`,
      probe:
        "Inspect filesystem type, destination, access, maximum capacity, accounting scope, and per-Sandbox disposal.",
      manifest:
        "Record scratch semantics and enforcement requirements without a host path or live storage identity.",
      evidence: [
        "scratch-manifest-projection",
        "effective-scratch-mount",
        "capacity-and-disposal-probe",
      ],
      rationale:
        "Scratch privacy and a hard maximum require both explicit target configuration and runtime evidence.",
    }),
  ]);
}

addRule("TRL-019-BUBBLEWRAP-AND-OCI-ROOT", writableRootFields, [...BUBBLEWRAP, ...OCI], [
  observed({
    id: "immutable-root",
    when: condition("alternative", {
      path: "artifact.filesystem.writableRoot",
      values: ["immutable"],
    }),
    build:
      "Construct immutable root content and record every explicitly writable subordinate resource.",
    prepare:
      "Mount the root read-only and suppress Bubblewrap root tmpfs, OCI writable-layer, image volume, and overlay defaults.",
    probe:
      "Verify the root is immutable while each declared writable subordinate mount retains only its declared access.",
    manifest:
      "Record the immutable-root alternative, root content identity, subordinate writable graph, and profile requirements.",
    evidence: [
      "root-content-identity",
      "effective-root-mount",
      "root-write-negative-probe",
    ],
    rationale:
      "Bubblewrap and generic OCI provide no profile-independent hard capacity for a private writable root.",
  }),
  unsupported({
    reason:
      "Reject a bounded private writable root because the baseline Bubblewrap and generic OCI profiles cannot prove a hard root-layer capacity without a separately registered quota-backed extension.",
    manifest:
      "Publish no profile support claim and never silently supply an unbounded tmpfs, overlay, or OCI writable layer.",
    remediation:
      "Use an immutable root plus explicitly bounded writable resources, or select a profile with a proven bounded-root mechanism.",
  }),
]);

addRule("TRL-020-MICROVM-ROOT", writableRootFields, MICROVMS, [
  observed({
    id: "representable-root-alternative",
    when: condition("constraint-satisfied", {
      requirement:
        "The root is immutable or its private writable layer is backed by an explicitly sized image/device with guest mount semantics and complete outer accounting.",
    }),
    build:
      "Build immutable root content and, when requested, a typed private writable-layer construction plan with a hard capacity.",
    ...STORAGE_RUNTIME_STEPS,
    prepare:
      "Attach only the declared root devices and configure the guest mount graph without VMM or microvm.nix disk defaults.",
    probe:
      "Verify effective root immutability or bounded private writability, subordinate mounts, device size, and cleanup.",
    manifest:
      "Record the root alternative, content/device identities, capacity, guest mount protocol, and applicable profile requirements.",
    evidence: [
      "microvm-root-content-and-device-identity",
      "guest-root-mount-probe",
      "root-capacity-and-cleanup-probe",
    ],
    rationale:
      "A fixed private disk can represent a bounded microVM root only when guest and host accounting agree.",
  }),
  unsupported({
    reason:
      "Reject a writable-root shape whose capacity, guest filesystem behavior, external state, or cleanup cannot be proven by the selected microVM profile.",
    manifest:
      "Publish no microVM support claim for the unsupported root alternative.",
    remediation:
      "Use an immutable root or a registered fixed-capacity private root implementation.",
  }),
]);

for (const [id, selectedProfiles, mechanism] of [
  [
    "TRL-021-BUBBLEWRAP-NETWORK",
    BUBBLEWRAP,
    "a strict isolated network namespace prepared before Bubblewrap, product-owned firewall/proxy/DNS/ingress brokers, and explicit typed host-channel brokers",
  ],
  [
    "TRL-022-MICROVM-NETWORK",
    MICROVMS,
    "explicit TAP/network namespace placement, host firewall/proxy/DNS/ingress enforcement, guest interface configuration, and registered vsock/channel brokers",
  ],
  [
    "TRL-023-OCI-NETWORK",
    OCI,
    "explicit OCI network namespace configuration plus product-owned firewall/proxy/DNS/ingress and typed channel brokers",
  ],
]) {
  addRule(id, networkFields, selectedProfiles, [
    observed({
      id: "supported-network-contract",
      when: condition("constraint-satisfied", {
        requirement:
          "Every requested access mode, egress rule, DNS alternative, ingress slot, credential dependency, and host-channel class has an exact registered enforcement mechanism.",
      }),
      build:
        "Record the complete closed network and channel contract plus required enforcement and evidence identities.",
      ...NETWORK_RUNTIME_STEPS,
      prepare:
        `Install ${mechanism}; synthesize resolver state and never inherit host networking, resolver files, ports, sockets, buses, or descriptors.`,
      probe:
        "Prove namespace identity and run positive and negative egress, DNS, ingress, credential, and undeclared-channel tests before readiness.",
      manifest:
        "Record only network policy, logical slots, host-channel contracts, and required protocol/evidence identities; endpoints and host objects remain runtime evidence.",
      evidence: [
        "effective-network-configuration",
        "network-positive-and-negative-probes",
        "undeclared-host-channel-negative-probe",
      ],
      rationale:
        "VMMs, Bubblewrap, and OCI configuration provide mechanisms, not complete high-level network policy semantics.",
    }),
    unsupported({
      reason:
        "Reject a network rule, DNS guarantee, ingress behavior, credential delivery, or host-channel class without an exact registered enforcement and evidence path.",
      manifest:
        "Publish no profile support claim for the unsupported network or channel contract.",
      remediation:
        "Use supported typed network/channel rules or select a profile with a proven broker and conformance suite.",
    }),
  ]);
}

addRule("TRL-024-COMMON-RESOURCE-BOUNDS", commonResourceFields, ALL, [
  observed({
    id: "representable-resource-bounds",
    when: condition("constraint-satisfied", {
      requirement:
        "Every declared minimum and hard maximum maps to an exact target and operator mechanism with the declared sandbox/workload scope.",
    }),
    build:
      "Record normalized dimensions, units, scopes, minimums, maxima, and required controller or VMM/guest protocol identities.",
    ...RESOURCE_RUNTIME_STEPS,
    prepare:
      "Place the complete target process tree in explicit cgroups and configure target/guest resource mechanisms before workload execution.",
    probe:
      "Read effective CPU, memory, swap, and task settings, prove complete process containment, and exercise the hard bounds.",
    manifest:
      "Record portable bounds and mechanism requirements; host allocations, cgroup paths, and provider resources remain redacted effective configuration.",
    evidence: [
      "resource-bound-manifest-projection",
      "effective-controller-and-vmm-readback",
      "resource-exhaustion-probe",
    ],
    rationale:
      "A VMM size, OCI field, cgroup namespace, relative weight, or successful start does not alone prove the declared scoped hard bound.",
  }),
  unsupported({
    reason:
      "Reject a resource dimension, scope, minimum, or hard maximum that the selected profile cannot represent and prove exactly.",
    manifest:
      "Publish no support claim for an approximate, relative, unbounded, or wrongly scoped resource mechanism.",
    remediation:
      "Use a representable resource contract or select a profile with exact enforcement for the required scope.",
  }),
]);

addRule("TRL-025-BUBBLEWRAP-WORKLOAD-MEMORY", ["artifact.resources.memoryWorkload"], BUBBLEWRAP, [
  preserved({
    id: "omitted",
    when: condition("field-omitted", {
      path: "artifact.resources.memoryWorkload",
    }),
    mechanism:
      "Preserve absence and make no workload-only memory support claim.",
    manifest:
      "Record explicit absence; total Sandbox memory remains a distinct field.",
    evidence: ["manifest-absence", "no-workload-memory-support-claim"],
    rationale:
      "The baseline Bubblewrap profile has only an outer complete-Sandbox cgroup.",
  }),
  unsupported({
    reason:
      "Reject a workload-only memory bound because the baseline Bubblewrap profile lacks a race-free nested workload cgroup that excludes launcher and supervisor overhead.",
    manifest:
      "Publish no workload-memory support claim and never relabel total Sandbox memory as workload memory.",
    remediation:
      "Use total Sandbox memory, or select a profile with a proven separate workload-memory boundary.",
  }),
]);

addRule("TRL-026-MICROVM-AND-OCI-WORKLOAD-MEMORY", ["artifact.resources.memoryWorkload"], [...MICROVMS, ...OCI], [
  preserved({
    id: "omitted",
    when: condition("field-omitted", {
      path: "artifact.resources.memoryWorkload",
    }),
    mechanism:
      "Preserve absence and make no workload-only memory guarantee.",
    manifest:
      "Record explicit absence without importing a guest, OCI, VMM, or provider memory default.",
    evidence: ["manifest-absence", "no-workload-memory-support-claim"],
    rationale:
      "Omission does not constrain valid narrower operator policy.",
  }),
  observed({
    id: "present-and-representable",
    when: condition("constraint-satisfied", {
      requiresFieldPresence: true,
      requirement:
        "The selected guest runtime or OCI runtime can place only workload processes in a distinct cgroup, keep VMM, launcher, driver, and supervisor overhead outside it, and enforce and prove the exact memory and swap bounds.",
    }),
    build:
      "Record the workload-only memory scope and required guest-runtime or container-cgroup enforcement protocol.",
    ...RESOURCE_RUNTIME_STEPS,
    prepare:
      "Place only workload processes in the workload cgroup while retaining separate outer VMM/runtime accounting.",
    probe:
      "Prove membership, effective memory and swap limits, exclusion of VMM/driver overhead, and workload exhaustion behavior.",
    manifest:
      "Record the workload-scoped range and exact enforcement/evidence requirement separately from total Sandbox memory.",
    evidence: [
      "workload-cgroup-membership",
      "effective-workload-memory-readback",
      "workload-memory-exhaustion-probe",
    ],
    rationale:
      "Workload and total Sandbox memory are distinct scopes and require distinct containment evidence.",
  }),
  unsupported({
    reason:
      "Reject a present workload-only memory requirement when the selected profile cannot create, populate, enforce, and prove a distinct workload cgroup without including runtime or VMM overhead.",
    manifest:
      "Publish no workload-memory support claim and never relabel total Sandbox or VM memory as workload-only memory.",
    remediation:
      "Select a profile with a proven distinct workload-memory boundary or omit the workload-only bound while retaining any total Sandbox bound.",
  }),
]);

addRule("TRL-027-BUBBLEWRAP-IO", ["artifact.resources.io"], BUBBLEWRAP, [
  preserved({
    id: "omitted",
    when: condition("field-omitted", { path: "artifact.resources.io" }),
    mechanism:
      "Preserve absence and make no logical-resource I/O performance guarantee.",
    manifest:
      "Record explicit absence without importing host-device throttling defaults.",
    evidence: ["manifest-absence", "no-io-support-claim"],
    rationale:
      "The baseline profile cannot attribute arbitrary logical paths independently to block devices.",
  }),
  unsupported({
    reason:
      "Reject a logical-resource I/O bound because cgroup io.max is block-device keyed and the baseline Bubblewrap profile does not require a dedicated provable backing device.",
    manifest:
      "Publish no path-scoped or directional I/O support claim.",
    remediation:
      "Use a profile extension with a dedicated verified backing device or omit the I/O performance requirement.",
  }),
]);

addRule("TRL-028-MICROVM-AND-OCI-IO", ["artifact.resources.io"], [...MICROVMS, ...OCI], [
  preserved({
    id: "omitted",
    when: condition("field-omitted", { path: "artifact.resources.io" }),
    mechanism:
      "Preserve absence and make no target or provider I/O performance guarantee.",
    manifest:
      "Record explicit absence without importing device throttle defaults.",
    evidence: ["manifest-absence", "no-io-support-claim"],
    rationale:
      "Omission leaves operator placement policy independent of Artifact semantics.",
  }),
  observed({
    id: "dedicated-representable-device",
    when: condition("constraint-satisfied", {
      requiresFieldPresence: true,
      requirement:
        "Each logical resource maps exclusively to a dedicated verified block device and every requested direction and dimension is exactly representable.",
    }),
    build:
      "Record each logical resource, direction, dimension, scope, bound, and required device-attribution/throttling capability.",
    ...RESOURCE_RUNTIME_STEPS,
    prepare:
      "Attach or resolve the dedicated device and configure exact host/VMM/runtime directional limits before workload start.",
    probe:
      "Verify logical-to-device attribution, effective read/write limits, complete containment, and directional exhaustion behavior.",
    manifest:
      "Record logical I/O requirements and mechanism versions; live device identities remain effective configuration.",
    evidence: [
      "logical-to-device-attribution",
      "effective-directional-io-readback",
      "io-throttle-conformance-probe",
    ],
    rationale:
      "Combined token buckets or a shared host device cannot prove independent logical-resource bounds.",
  }),
  unsupported({
    reason:
      "Reject I/O bounds on shared or unattributable backing storage, or dimensions/directions the selected VMM/runtime mechanism cannot express exactly.",
    manifest:
      "Publish no approximate or combined I/O support claim.",
    remediation:
      "Use dedicated attributable storage with representable limits or remove the unsupported I/O requirement.",
  }),
]);

for (const [id, selectedProfiles, mechanism] of [
  [
    "TRL-029-BUBBLEWRAP-SECURITY-POLICY",
    BUBBLEWRAP,
    "the non-setuid Bubblewrap profile plus an owned fail-closed identity/capability launcher and architecture-specific registered policy compiler",
  ],
  [
    "TRL-030-MICROVM-SECURITY-POLICY",
    MICROVMS,
    "the guest kernel/runtime for workload policy plus a separately confined VMM/helper process boundary",
  ],
  [
    "TRL-031-OCI-SECURITY-POLICY",
    OCI,
    "explicit OCI process capabilities, no-new-privileges, seccomp, LSM, namespace, and product-owned policy compilation",
  ],
]) {
  addRule(id, securityPolicyFields, selectedProfiles, [
    observed({
      id: "registered-representable-security-contract",
      when: condition("constraint-satisfied", {
        requirement:
          "Every capability-set relationship and kernel-policy identity/version/architecture/strength is exactly implemented by the registered profile.",
      }),
      build:
        "Validate capability relations and compile every registered policy for the workload architecture without target inference.",
      ...SECURITY_RUNTIME_STEPS,
      prepare:
        `Install the exact workload privilege ceiling using ${mechanism}; fail every kernel operation instead of warning or weakening.`,
      probe:
        "Inspect no-new-privileges, all capability sets, namespaces, seccomp/LSM/policy state, and run required positive and negative policy probes.",
      manifest:
        "Record canonical privilege and policy contracts, compiled-policy identities, architecture, mechanism versions, and evidence obligations.",
      evidence: [
        "compiled-security-policy-identity",
        "effective-privilege-and-policy-readback",
        "security-negative-probe",
      ],
      rationale:
        "A target mechanism name, process jail, or successful launch cannot substitute for the complete workload security contract.",
    }),
    unsupported({
      phase: "N1",
      reason:
        "Reject an unknown, uncompiled, wrongly scoped, weaker, or unrepresentable privilege or kernel-policy contract.",
      manifest:
        "Publish no support claim for the unsupported security semantics.",
      remediation:
        "Use registered policy/capability semantics supported by the selected profile or select another conformed profile.",
    }),
  ]);
}

for (const [id, selectedProfiles, mechanism] of [
  [
    "TRL-032-BUBBLEWRAP-DEVICES",
    BUBBLEWRAP,
    "an enumerated minimal pseudo-device tree plus explicit safely resolved dev-bind operations and projected capability/policy edits",
  ],
  [
    "TRL-033-FIRECRACKER-DEVICES",
    FIRECRACKER,
    "the explicit Firecracker device baseline and only registered block, network, vsock, and entropy devices; MMDS, serial, pmem, and passthrough remain disabled unless separately profiled",
  ],
  [
    "TRL-034-CLOUD-HYPERVISOR-DEVICES",
    CLOUD_HYPERVISOR,
    "the explicit unavoidable Cloud Hypervisor device baseline plus only registered block, network, vsock, and filesystem devices; nested virtualization and passthrough remain disabled",
  ],
  [
    "TRL-035-OCI-DEVICES",
    OCI,
    "an explicit minimal OCI device and cgroup-access baseline plus registered allocation and every projected mount, group, capability, hook replacement, and host-channel effect",
  ],
]) {
  addRule(id, ["artifact.security.devices"], selectedProfiles, [
    observed({
      id: "registered-device-contract",
      when: condition("constraint-satisfied", {
        requirement:
          "Every logical device class, count, access, isolation, allocation, and projected authority effect is implemented and evidenced by the selected profile.",
      }),
      build:
        "Record the logical device contract, exact profile baseline, projected authority edits, and required allocation/evidence protocols.",
      ...DEVICE_RUNTIME_STEPS,
      prepare:
        `Allocate and configure ${mechanism}; suppress all undeclared target, VMM, OCI, and host devices.`,
      probe:
        "Inventory effective devices and test required access, isolation, count, denial of undeclared devices, and every projected authority effect.",
      manifest:
        "Record logical classes and the complete target baseline without live host paths, provider IDs, or allocation choices.",
      evidence: [
        "device-baseline-manifest",
        "effective-device-inventory",
        "undeclared-device-negative-probe",
      ],
      rationale:
        "Device names are not sufficient because devices can inject mounts, groups, capabilities, hooks, and host channels.",
    }),
    unsupported({
      reason:
        "Reject a device class, passthrough mechanism, isolation level, or projected authority effect not exactly implemented by the selected profile.",
      manifest:
        "Publish no support claim and never add a runtime/VMM default device to satisfy the request approximately.",
      remediation:
        "Use a registered logical device contract or select a profile with proven allocation and isolation.",
    }),
  ]);
}

for (const [id, selectedProfiles, mechanism] of [
  [
    "TRL-036-BUBBLEWRAP-SECRETS",
    BUBBLEWRAP,
    "sealed descriptors and product-owned file, environment, credential, or broker delivery inside ephemeral namespace storage",
  ],
  [
    "TRL-037-MICROVM-SECRETS",
    MICROVMS,
    "authenticated guest-runtime/vsock delivery to guest tmpfs or exec-time channels, never image, store, MMDS, OEM strings, or VMM configuration",
  ],
  [
    "TRL-038-OCI-SECRETS",
    OCI,
    "sealed descriptors and product-owned ephemeral file, environment, credential, or broker delivery outside image layers and image configuration",
  ],
]) {
  addRule(id, secretFields, selectedProfiles, [
    observed({
      id: "supported-secret-contract",
      when: condition("constraint-satisfied", {
        requirement:
          "Every delivery alternative, destination, audience, ownership/mode, lifetime, and snapshot treatment is enforceable by the selected profile.",
      }),
      build:
        "Record value-free secret-slot contracts and required delivery/snapshot protocol identities only.",
      ...SECRET_RUNTIME_STEPS,
      prepare:
        `Resolve values only at Create and deliver them with ${mechanism}; install explicit modes, audiences, expiry, cleanup, redaction, and snapshot gates.`,
      probe:
        "Verify destination, audience, permissions, absence from immutable content and evidence, expiry cleanup, and applicable snapshot behavior without disclosing values.",
      manifest:
        "Record slot identity and contract only; no secret/provider reference, value, value hash, endpoint, or provider credential enters Artifact identity.",
      evidence: [
        "secret-free-member-scan",
        "redacted-secret-delivery-evidence",
        "secret-expiry-and-cleanup-probe",
        "snapshot-secret-treatment-probe",
      ],
      rationale:
        "Secret safety depends on delivery, process audience, lifetime, cleanup, diagnostics, and snapshot surfaces together.",
    }),
    unsupported({
      reason:
        "Reject a secret delivery, audience, lifetime, mode, destination, or snapshot treatment the selected target cannot enforce exactly.",
      manifest:
        "Publish no secret capability claim and never place the value in built content or an opaque provider mechanism.",
      remediation:
        "Use a registered ephemeral delivery alternative compatible with the target and requested snapshot class.",
    }),
  ]);
}

addRule("TRL-039-REQUIREMENT-CLOSURE", requirementFields, ALL, [
  observed({
    id: "satisfied-versioned-requirements",
    when: condition("constraint-satisfied", {
      requirement:
        "Every mandatory capability, protocol, dependency edge, enforcement class, and version constraint is implemented and covered by builder-linked conformance evidence.",
    }),
    build:
      "Resolve the complete mandatory requirement closure against the exact member, profile, implementation pins, and applicable versioned conformance suites.",
    prepare:
      "Load only a registered driver/guest/helper stack matching the proven profile and defensively revalidate the generated resolved contract.",
    probe:
      "Complete every required post-start evidence obligation before advertising readiness or model-facing capability.",
    manifest:
      "Keep Artifact-authored requirements separate from signed builder-produced support, implementation, result, and evidence facts.",
    evidence: [
      "requirement-dependency-closure",
      "builder-support-fact-verification",
      "versioned-conformance-results",
    ],
    rationale:
      "A target name, builder success, or author-authored support flag cannot satisfy a mandatory requirement.",
  }),
  unsupported({
    phase: "N1",
    reason:
      "Reject the target member when any mandatory capability, protocol, enforcement class, dependency, or evidence requirement is unsatisfied.",
    manifest:
      "Publish no member/profile association and do not drop the target or downgrade a requirement.",
    remediation:
      "Select a compatible target/profile or remove only a genuinely optional requirement explicitly.",
  }),
]);

addRule("TRL-040-MAXIMUM-LIFETIME", lifetimeFields, ALL, [
  observed({
    build:
      "Record the immutable Artifact lifetime ceiling or its explicit absence and the required enforcement protocol.",
    ...LIFETIME_RUNTIME_STEPS,
    prepare:
      "Resolve a no-later-than monotonic expiration, arm complete-tree termination and cleanup before launch, and propagate remaining lifetime to operations.",
    probe:
      "Verify deadline enforcement, signal/kill escalation, child cleanup, resource cleanup, and secret-safe termination evidence.",
    manifest:
      "Record the Artifact ceiling only; narrower Create/operator deadlines are effective runtime configuration and never change Artifact identity.",
    evidence: [
      "resolved-monotonic-deadline",
      "complete-process-tree-termination",
      "lifetime-cleanup-probe",
    ],
    rationale:
      "Target parent-death flags, provider timeouts, or VMM defaults do not independently prove a hard complete-Sandbox lifetime.",
  }),
]);

addRule("TRL-041-NONSNAPSHOT-TARGETS", ["artifact.lifecycleRequirements.snapshot"], [...BUBBLEWRAP, ...OCI], [
  preserved({
    id: "omitted",
    when: condition("field-omitted", {
      path: "artifact.lifecycleRequirements.snapshot",
    }),
    mechanism:
      "Preserve absence and advertise no snapshot capability for the baseline profile.",
    manifest:
      "Record explicit absence and retain secret snapshot-treatment metadata for future profile compatibility.",
    evidence: ["manifest-absence", "no-snapshot-support-claim"],
    rationale:
      "Bubblewrap and OCI Runtime v1 define no product-complete process/memory/device/storage snapshot protocol.",
  }),
  unsupported({
    reason:
      "Reject a required snapshot class because the baseline Bubblewrap and OCI profiles have no proven complete snapshot and restore contract.",
    manifest:
      "Publish no snapshot support claim and never reinterpret filesystem export or provider snapshot as the required class.",
    remediation:
      "Select a microVM profile with a compatible exact snapshot class or remove the mandatory snapshot requirement.",
  }),
]);

addRule("TRL-042-MICROVM-SNAPSHOT", ["artifact.lifecycleRequirements.snapshot"], MICROVMS, [
  preserved({
    id: "omitted",
    when: condition("field-omitted", {
      path: "artifact.lifecycleRequirements.snapshot",
    }),
    mechanism:
      "Preserve absence and do not infer a snapshot requirement from VMM capability.",
    manifest:
      "Record explicit absence while retaining profile snapshot capability facts separately.",
    evidence: ["manifest-absence", "separate-snapshot-capability-facts"],
    rationale:
      "Available VMM APIs do not change portable Artifact requirements.",
  }),
  observed({
    id: "supported-exact-snapshot-class",
    when: condition("constraint-satisfied", {
      requiresFieldPresence: true,
      requirement:
        "The requested component set, external storage, device state, secret treatment, quiescing, clone identity refresh, and compatibility domain exactly match a proven profile class.",
    }),
    build:
      "Record the exact snapshot class and compatibility envelope for the pinned VMM, guest, kernel, CPU architecture/model, devices, storage, secrets, and identity refresh protocol.",
    prepare:
      "Quiesce and scrub as required, capture every declared component through owned orchestration, and rebind runtime TAP/vsock/path identities on restore.",
    probe:
      "Verify capture completeness, secret treatment, storage consistency, exact restore compatibility, identity/entropy refresh, and resumed policy enforcement.",
    manifest:
      "Record granular snapshot component and compatibility classes; VMM memory/state APIs alone never imply filesystem-inclusive or clone-safe support.",
    evidence: [
      "snapshot-component-inventory",
      "snapshot-compatibility-envelope",
      "restore-and-identity-refresh-probe",
    ],
    rationale:
      "Firecracker and Cloud Hypervisor snapshot VMM state and memory while storage and security semantics require separate owned orchestration.",
  }),
  unsupported({
    phase: "N1",
    reason:
      "Reject filesystem-inclusive, secret-excluding, clone-safe, portable-host, unquiesced, or otherwise unmatched snapshot semantics without complete conformance evidence.",
    manifest:
      "Publish no approximate snapshot class or profile support claim.",
    remediation:
      "Request only an exact proven snapshot component/compatibility class or select another profile.",
  }),
]);

addRule("TRL-043-OPTIONAL-OPERATIONS", ["artifact.lifecycleRequirements.optionalOperations"], ALL, [
  preserved({
    id: "omitted",
    when: condition("field-omitted", {
      path: "artifact.lifecycleRequirements.optionalOperations",
    }),
    mechanism:
      "Preserve absence; no operation is inferred from target or provider capabilities.",
    manifest:
      "Record no mandatory optional-operation requirement while keeping builder capability facts separate.",
    evidence: ["manifest-absence", "separate-operation-capability-facts"],
    rationale:
      "Target capability does not create an Artifact requirement.",
  }),
  observed({
    id: "supported-granular-operations",
    when: condition("constraint-satisfied", {
      requiresFieldPresence: true,
      requirement:
        "Every required operation and semantic version is individually implemented and covered by the selected profile's state-specific conformance suite.",
    }),
    build:
      "Resolve each operation requirement independently against exact driver, guest, VMM/runtime, and evidence protocol versions.",
    prepare:
      "Expose only supported typed Core API operations; do not translate a generic lifecycle boolean or raw backend operation.",
    probe:
      "Exercise operation success, forbidden states, failure atomicity, authority preservation, cleanup, and evidence behavior.",
    manifest:
      "Record granular operation requirements and separate builder support facts with applicable states and protocol versions.",
    evidence: [
      "operation-capability-closure",
      "state-machine-conformance",
      "operation-authority-negative-probe",
    ],
    rationale:
      "Pause, resume, resize, PTY, snapshot, restore, and fork have independent semantics and support envelopes.",
  }),
  unsupported({
    reason:
      "Reject any mandatory operation without exact state-machine, authority, cleanup, and evidence conformance for the selected profile.",
    manifest:
      "Publish no generic lifecycle support claim and do not silently omit an operation.",
    remediation:
      "Require only individually proven operations or select a compatible profile.",
  }),
]);

addRule("TRL-044-OUTPUTS", outputFields, ALL, [
  observed({
    build:
      "Validate output identities and exact paths against the filesystem graph and record eligibility without selection, capture, destination, timing, retention, or existence semantics.",
    prepare:
      "Preserve writable output paths and expose collection only through a later typed operation under Artifact and operator bounds.",
    probe:
      "Verify output paths remain reachable, cannot overlap immutable/protected/secret surfaces, and collection does not escape the declared graph.",
    manifest:
      "Record output declarations and filesystem compatibility only; runtime selection and export destinations remain later operation inputs.",
    evidence: [
      "output-filesystem-graph-validation",
      "effective-output-path-probe",
      "collection-boundary-probe",
    ],
    rationale:
      "An output declaration is an eligible path convention, not implicit persistence, capture, export, or retention.",
  }),
]);

const seen = new Map();
for (const spec of specs) {
  for (const fieldId of spec.fieldIds) {
    if (!fieldById.has(fieldId)) {
      throw new Error(`${spec.id}: unknown field ${fieldId}`);
    }
    for (const profileId of spec.profileIds) {
      if (!profileIds.includes(profileId)) {
        throw new Error(`${spec.id}: unknown profile ${profileId}`);
      }
      const key = `${fieldId} × ${profileId}`;
      if (seen.has(key)) {
        throw new Error(`${spec.id}: overlaps ${seen.get(key)} at ${key}`);
      }
      seen.set(key, spec.id);
    }
  }
}

const expectedCells = fieldsDocument.fields.length * profileIds.length;
if (seen.size !== expectedCells) {
  const missing = [];
  for (const field of fieldsDocument.fields) {
    for (const profileId of profileIds) {
      const key = `${field.id} × ${profileId}`;
      if (!seen.has(key)) missing.push(key);
    }
  }
  throw new Error(
    `realization coverage is ${seen.size}/${expectedCells}; missing:\n${missing.join("\n")}`,
  );
}

function unique(values) {
  return [...new Set(values)];
}

const rules = specs.map((spec) => {
  const fields = spec.fieldIds.map((fieldId) => fieldById.get(fieldId));
  const invariants = unique([
    ...fields.flatMap((field) => field.invariants),
    "MAN-005",
    ...(RULE_INVARIANTS.get(spec.id) ?? []),
  ]);
  const fieldTraceability = Object.fromEntries(
    fields.map((field) => [
      field.id,
      {
        invariants: field.invariants,
        delegatedPackets: field.delegatedPackets.filter(
          (packet) => packet !== "C",
        ),
      },
    ]),
  );

  const cases = spec.cases.map((caseSpec) => {
    const { remediation, ...rest } = caseSpec;
    const diagnosticIdentity = `${spec.id}/${caseSpec.id}`;
    const conditionWithPredicate =
      ["constraint-satisfied", "constraint-unsatisfied"].includes(
        rest.condition.kind,
      )
        ? { ...rest.condition, predicateId: diagnosticIdentity }
        : rest.condition;
    const {
      steps: sourceSteps,
      manifestBehavior,
      evidence: evidenceClasses,
      ...caseFields
    } = rest;
    return {
      ...caseFields,
      condition: conditionWithPredicate,
      steps: sourceSteps.map((sourceStep, index) => ({
        ...sourceStep,
        obligationId:
          `${diagnosticIdentity}/step-${index + 1}/` +
          `${sourceStep.phase}/${sourceStep.mode}`,
      })),
      manifestProjection: {
        obligationId: `${diagnosticIdentity}/manifest-projection`,
        explanation: manifestBehavior,
      },
      evidence: evidenceClasses.map((evidenceClass, index) => ({
        obligationId:
          `${diagnosticIdentity}/evidence-${index + 1}/${evidenceClass}`,
        class: evidenceClass,
      })),
      safetyPolicy: {
        failure: "fail-closed",
        defaults: "explicit-only",
        warnings: "never-sufficient",
        evidence: "required",
      },
      invariants,
      delegatedPackets: [],
      diagnostic: {
        identity: diagnosticIdentity,
        primaryPaths: spec.fieldIds,
        relatedPaths: [
          "artifact.targets.runtimeProfiles",
          "targetMember.manifest",
          "runtime.evidence",
        ],
        remediation,
        secretSafe: true,
      },
    };
  });

  return {
    id: spec.id,
    fieldIds: spec.fieldIds,
    profileIds: spec.profileIds,
    fieldTraceability,
    cases,
  };
});

const document = {
  reviewVersion: 1,
  packet: "C",
  status: "reviewed",
  textAuthority:
    "Only closed structured control fields and stable obligation identifiers are normative. Human-readable explanations, rationales, and remediation text are non-normative and cannot change failure, default, warning, verification, evidence, phase, authority, or lowering semantics.",
  expectedCellCount: expectedCells,
  introducedInvariants: TARGET_INTRODUCED_INVARIANTS,
  rules,
};

const caseContractsDocument = {
  reviewVersion: 1,
  packet: "C",
  status: "reviewed",
  authority:
    "Generator-owned exact condition, outcome, phase, authority, step, evidence, and delegation contracts keyed by target realization rule/case identity.",
  entries: rules.flatMap((rule) =>
    rule.cases.map((realizationCase) => ({
      identity: realizationCase.diagnostic.identity,
      condition: realizationCase.condition,
      outcome: realizationCase.outcome,
      firstSoundPhase: realizationCase.firstSoundPhase,
      deadline: realizationCase.deadline,
      authority: realizationCase.authority,
      steps: realizationCase.steps.map(({ phase, mode, component }) => ({
        phase,
        mode,
        component,
      })),
      evidenceClasses: realizationCase.evidence.map((entry) => entry.class),
      delegatedPackets: realizationCase.delegatedPackets,
    })),
  ),
};

const outputPath = path.join(directory, "PACKET-C-TARGET-REALIZATION.json");
const generated = `${JSON.stringify(document, null, 2)}\n`;
const caseContractsPath = path.join(
  directory,
  "PACKET-C-CASE-CONTRACTS.json",
);
const generatedCaseContracts =
  `${JSON.stringify(caseContractsDocument, null, 2)}\n`;

if (process.argv.includes("--check")) {
  const existing = fs.readFileSync(outputPath, "utf8");
  if (existing !== generated) {
    throw new Error(
      "PACKET-C-TARGET-REALIZATION.json is stale; regenerate it with generate-target-realization.mjs",
    );
  }
  const existingCaseContracts = fs.readFileSync(caseContractsPath, "utf8");
  if (existingCaseContracts !== generatedCaseContracts) {
    throw new Error(
      "PACKET-C-CASE-CONTRACTS.json is stale; regenerate it with generate-target-realization.mjs",
    );
  }
} else {
  fs.writeFileSync(outputPath, generated);
  fs.writeFileSync(caseContractsPath, generatedCaseContracts);
}
