#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
parent_root="$(dirname "${prototype_root}")"
wire_root="${parent_root}/wire-validator"
wire_manifest="${wire_root}/Cargo.toml"
valid_artifact="${wire_root}/fixtures/valid.json"
temporary_root="$(mktemp -d)"
trap 'rm -rf "${temporary_root}"' EXIT
expected_pass_count=40
pass_count=0

wire_check() {
  cargo run --quiet --manifest-path "${wire_manifest}" -- check "$1"
}

expect_failure() {
  local label="$1"
  local invariant="$2"
  shift 2
  local stderr_path="${temporary_root}/${label}.stderr"

  if "$@" >"${temporary_root}/${label}.stdout" 2>"${stderr_path}"; then
    echo "not ok - ${label}: unexpectedly succeeded" >&2
    exit 1
  fi
  if ! rg -F "${invariant}" "${stderr_path}" >/dev/null; then
    echo "not ok - ${label}: missing ${invariant}" >&2
    sed -n '1,20p' "${stderr_path}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
  echo "ok - ${label}"
}

expect_classified_failure() {
  local label="$1"
  local invariant="$2"
  local classification="$3"
  shift 3
  local stderr_path="${temporary_root}/${label}.stderr"

  if "$@" >"${temporary_root}/${label}.stdout" 2>"${stderr_path}"; then
    echo "not ok - ${label}: unexpectedly succeeded" >&2
    exit 1
  fi
  if ! rg -F "${invariant}" "${stderr_path}" >/dev/null ||
     ! rg -F "${classification}" "${stderr_path}" >/dev/null; then
    echo "not ok - ${label}: missing ${invariant}/${classification}" >&2
    sed -n '1,20p' "${stderr_path}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
  echo "ok - ${label}"
}

semantic_digest="$(wire_check "${valid_artifact}" | jq -er '.sha256')"
member_digest="$(printf 'member-v1' | shasum -a 256 | awk '{print $1}')"
evidence_digest="$(printf 'evidence-v1' | shasum -a 256 | awk '{print $1}')"
source_digest="$(printf 'retained-workspace-v1' | shasum -a 256 | awk '{print $1}')"
create_digest="$(printf 'create-request-v1' | shasum -a 256 | awk '{print $1}')"
prepared_digest="$(printf 'prepared-launch-v1' | shasum -a 256 | awk '{print $1}')"

jq -n \
  --slurpfile artifact "${valid_artifact}" \
  '{schemaVersion: 0, artifact: $artifact[0]}' \
  >"${temporary_root}/migration-v0.json"
"${prototype_root}/migrate.sh" "${temporary_root}/migration-v0.json" \
  >"${temporary_root}/migration-v1.json"
"${prototype_root}/migrate.sh" "${temporary_root}/migration-v1.json" \
  >"${temporary_root}/migration-v1-again.json"
cmp "${temporary_root}/migration-v1.json" "${temporary_root}/migration-v1-again.json"
jq -e '.schemaVersion == 1' "${temporary_root}/migration-v1.json" >/dev/null
jq -e '.artifact' "${temporary_root}/migration-v1.json" \
  >"${temporary_root}/migrated-artifact.json"
wire_check "${temporary_root}/migrated-artifact.json" >/dev/null
pass_count=$((pass_count + 1))
echo "ok - MIG-001 deterministic idempotent migration"

jq '.migrationPath = "fallback-via-legacy"' \
  "${temporary_root}/migration-v0.json" \
  >"${temporary_root}/migration-ambiguous.json"
expect_failure "MIG-001 ambiguous route" "MIG-001" \
  "${prototype_root}/migrate.sh" "${temporary_root}/migration-ambiguous.json"

jq '.legacyExtensions = {"unregistered.example/unsafe": {}}' \
  "${temporary_root}/migration-v0.json" \
  >"${temporary_root}/migration-extension-loss.json"
expect_failure "MIG-001 extension loss" "MIG-001" \
  "${prototype_root}/migrate.sh" "${temporary_root}/migration-extension-loss.json"

jq '.schemaVersion = 9' "${temporary_root}/migration-v0.json" \
  >"${temporary_root}/migration-unsupported.json"
expect_failure "MIG-001 unsupported source version" "MIG-001" \
  "${prototype_root}/migrate.sh" "${temporary_root}/migration-unsupported.json"

jq '.artifact.network.egressAllow = ["0.0.0.0/0"]' \
  "${temporary_root}/migration-v0.json" \
  >"${temporary_root}/migration-invalid-source.json"
expect_failure \
  "migration validates old semantics before transformation" \
  "artifact.network.disabled_has_no_egress" \
  "${prototype_root}/migrate.sh" "${temporary_root}/migration-invalid-source.json"

jq -n \
  --arg semantic "${semantic_digest}" \
  --arg member "${member_digest}" \
  --arg evidence "${evidence_digest}" \
  '{
    schemaVersion: 1,
    artifactSemanticDigest: $semantic,
    memberContentDigest: $member,
    portableProjectionDigest: $semantic,
    targetId: "bubblewrap",
    runtimeProfileIds: ["bubblewrap-linux-v1"],
    protocols: {
      targetManifest: "target-manifest-v1",
      driver: "bubblewrap-driver-v1",
      guest: "none-v1",
      evidence: "builder-evidence-v1"
    },
    builderEvidence: {
      artifactSemanticDigest: $semantic,
      memberContentDigest: $member,
      runtimeProfileId: "bubblewrap-linux-v1",
      protocolVersion: "builder-evidence-v1",
      evidenceDigest: $evidence
    }
  }' >"${temporary_root}/manifest-valid.json"

manifest_args=(
  --arg expectedArtifactSemanticDigest "${semantic_digest}"
  --arg expectedMemberContentDigest "${member_digest}"
  --arg expectedPortableProjectionDigest "${semantic_digest}"
  --arg expectedTargetId "bubblewrap"
  --arg expectedRuntimeProfileId "bubblewrap-linux-v1"
  --arg expectedBuilderEvidenceDigest "${evidence_digest}"
  -f "${prototype_root}/validate-built-manifest.jq"
)
jq -e "${manifest_args[@]}" "${temporary_root}/manifest-valid.json" >/dev/null
pass_count=$((pass_count + 1))
echo "ok - built manifest exact identity load"

jq '.artifactSemanticDigest = ("0" * 64)' \
  "${temporary_root}/manifest-valid.json" \
  >"${temporary_root}/manifest-identity.json"
expect_failure "MAN-001 corrupted semantic identity" "MAN-001" \
  jq -e "${manifest_args[@]}" "${temporary_root}/manifest-identity.json"

jq '.providerObjectId = "ambient-provider-object"' \
  "${temporary_root}/manifest-valid.json" \
  >"${temporary_root}/manifest-foreign-field.json"
expect_failure "MAN-003 provider field in manifest" "MAN-003" \
  jq -e "${manifest_args[@]}" "${temporary_root}/manifest-foreign-field.json"

jq 'del(.builderEvidence)' \
  "${temporary_root}/manifest-valid.json" \
  >"${temporary_root}/manifest-missing-evidence.json"
expect_failure "TGT-003 manifest missing builder evidence" "TGT-003" \
  jq -e "${manifest_args[@]}" "${temporary_root}/manifest-missing-evidence.json"

jq '.memberContentDigest = ("1" * 64)' \
  "${temporary_root}/manifest-valid.json" \
  >"${temporary_root}/manifest-member-substitution.json"
expect_failure "MAN-001 substituted member content" "MAN-001" \
  jq -e "${manifest_args[@]}" "${temporary_root}/manifest-member-substitution.json"

jq '.builderEvidence.evidenceDigest = ("2" * 64)' \
  "${temporary_root}/manifest-valid.json" \
  >"${temporary_root}/manifest-evidence-substitution.json"
expect_failure "TGT-003 substituted builder evidence" "TGT-003" \
  jq -e "${manifest_args[@]}" "${temporary_root}/manifest-evidence-substitution.json"

jq '.protocols.guest = "unknown-guest-v9"' \
  "${temporary_root}/manifest-valid.json" \
  >"${temporary_root}/manifest-unknown-protocol.json"
expect_failure "MAN-002 unregistered guest protocol" "MAN-002" \
  jq -e "${manifest_args[@]}" "${temporary_root}/manifest-unknown-protocol.json"

jq '.runtimeProfileIds += ["oci-linux-v1"]' \
  "${temporary_root}/manifest-valid.json" \
  >"${temporary_root}/manifest-profile-conflict.json"
expect_failure "MAN-006 incompatible member profile set" "MAN-006" \
  jq -e "${manifest_args[@]}" "${temporary_root}/manifest-profile-conflict.json"

jq -n \
  --arg semantic "${semantic_digest}" \
  --arg member "${member_digest}" \
  --arg source "${source_digest}" \
  --arg create "${create_digest}" \
  --arg prepared "${prepared_digest}" \
  '{
    resolvedVersion: 1,
    identity: {
      artifactSemanticDigest: $semantic,
      memberContentDigest: $member,
      createRequestDigest: $create,
      admissionDecisionId: "admission-v1",
      preparedSemanticIdentity: $prepared
    },
    profile: {
      id: "bubblewrap-linux-v1",
      targetId: "bubblewrap"
    },
    retainedSource: {
      workspaceDescriptorDigest: $source,
      acquisitionKind: "live-file-handle"
    },
    workspace: {
      destination: "/workspace",
      access: "readWrite",
      materialization: "retained"
    },
    network: {
      mode: "disabled",
      egressAllow: [],
      ports: []
    },
    resources: {
      cpuMillis: 1000,
      memoryBytes: 536870912,
      diskBytes: 2147483648
    },
    identitySecurity: {
      uid: 1000,
      gid: 1000,
      noNewPrivileges: true,
      capabilities: []
    },
    devices: {allowed: []},
    secrets: {bindings: []},
    snapshots: {mode: "disabled", source: null},
    output: {capture: "structured", maxBytes: 1048576},
    protocolVersions: {
      resolvedReentry: "resolved-reentry-v1",
      driver: "bubblewrap-driver-v1",
      generatedConfiguration: "generated-runtime-config-v1",
      guest: "none-v1"
    },
    backendDefaults: {
      rootFilesystem: "suppressed-explicit",
      networkNamespace: "suppressed-explicit",
      hostname: "suppressed-explicit",
      environment: "suppressed-explicit",
      workingDirectory: "suppressed-explicit",
      resourceLimits: "suppressed-explicit",
      security: "suppressed-explicit",
      devices: "suppressed-explicit",
      secrets: "suppressed-explicit",
      snapshots: "suppressed-explicit",
      output: "suppressed-explicit"
    }
  }' >"${temporary_root}/driver-valid.json"
driver_expected="${temporary_root}/driver-expected.json"
cp "${temporary_root}/driver-valid.json" "${driver_expected}"

driver_args=(
  --slurpfile expectedGeneratedConfiguration "${driver_expected}"
  --arg expectedArtifactSemanticDigest "${semantic_digest}"
  --arg expectedMemberContentDigest "${member_digest}"
  --arg expectedCreateRequestDigest "${create_digest}"
  --arg expectedAdmissionDecisionId "admission-v1"
  --arg expectedPreparedSemanticIdentity "${prepared_digest}"
  --arg expectedProfileId "bubblewrap-linux-v1"
  --arg expectedTargetId "bubblewrap"
  --arg expectedSourceDescriptorDigest "${source_digest}"
  --arg expectedDriverProtocolVersion "bubblewrap-driver-v1"
  --arg expectedGuestProtocolVersion "none-v1"
  -f "${prototype_root}/validate-resolved-driver.jq"
)
jq -e "${driver_args[@]}" "${temporary_root}/driver-valid.json" >/dev/null
pass_count=$((pass_count + 1))
echo "ok - resolved driver exact generated input"

jq '.retainedSource.workspaceDescriptorDigest = ("f" * 64)' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-source-swap.json"
expect_failure "DRV-001 resolved source identity corruption" "DRV-001" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-source-swap.json"

jq '.workspace.hostPath = "/tmp/ambient"' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-host-path.json"
expect_failure "DRV-004 raw host path" "DRV-004" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-host-path.json"

jq '.rawArgs = ["--bind", "/", "/host"]' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-raw-args.json"
expect_failure "DRV-004 raw driver arguments" "DRV-004" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-raw-args.json"

jq '.network = {mode: "egress", egressAllow: ["0.0.0.0/0"], ports: []}' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-network-widening.json"
expect_failure "DRV-001 resolved network widening" "DRV-001" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-network-widening.json"

for profile_case in \
  "bubblewrap-linux-v1|bubblewrap|bubblewrap-driver-v1|none-v1" \
  "microvm-firecracker-linux-v1|firecracker|firecracker-driver-v1|sandbox-agent-v1" \
  "microvm-cloud-hypervisor-linux-v1|cloud-hypervisor|cloud-hypervisor-driver-v1|sandbox-agent-v1" \
  "oci-linux-v1|oci|oci-driver-v1|oci-runtime-v1"
do
  IFS='|' read -r profile_id target_id driver_protocol guest_protocol \
    <<<"${profile_case}"
  jq \
    --arg profile "${profile_id}" \
    --arg target "${target_id}" \
    --arg driver "${driver_protocol}" \
    --arg guest "${guest_protocol}" \
    '.profile.id = $profile |
     .profile.targetId = $target |
     .protocolVersions.driver = $driver |
     .protocolVersions.guest = $guest' \
    "${temporary_root}/driver-valid.json" \
    >"${temporary_root}/driver-${profile_id}.json"
  profile_expected="${temporary_root}/driver-${profile_id}-expected.json"
  cp "${temporary_root}/driver-${profile_id}.json" "${profile_expected}"
  jq -e \
    --slurpfile expectedGeneratedConfiguration "${profile_expected}" \
    --arg expectedArtifactSemanticDigest "${semantic_digest}" \
    --arg expectedMemberContentDigest "${member_digest}" \
    --arg expectedCreateRequestDigest "${create_digest}" \
    --arg expectedAdmissionDecisionId "admission-v1" \
    --arg expectedPreparedSemanticIdentity "${prepared_digest}" \
    --arg expectedProfileId "${profile_id}" \
    --arg expectedTargetId "${target_id}" \
    --arg expectedSourceDescriptorDigest "${source_digest}" \
    --arg expectedDriverProtocolVersion "${driver_protocol}" \
    --arg expectedGuestProtocolVersion "${guest_protocol}" \
    -f "${prototype_root}/validate-resolved-driver.jq" \
    "${temporary_root}/driver-${profile_id}.json" >/dev/null
  pass_count=$((pass_count + 1))
  echo "ok - generated configuration profile binding ${profile_id}"
done

jq 'del(.devices)' "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-missing-category.json"
expect_failure "DRV-004 omitted generated category" "DRV-004" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-missing-category.json"

jq '.ambientBackend = {}' "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-unknown-root.json"
expect_failure "DRV-004 unknown generated root" "DRV-004" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-unknown-root.json"

jq '.resources.ambientLimit = 1' "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-unknown-nested.json"
expect_failure "DRV-004 unknown generated nested field" "DRV-004" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-unknown-nested.json"

jq 'del(.backendDefaults.networkNamespace)' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-default-omitted.json"
expect_failure "DRV-004 implicit backend default" "DRV-004" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-default-omitted.json"

jq '.profile.targetId = "oci"' "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-profile-corruption.json"
expect_failure "DRV-001 profile identity corruption" "DRV-001" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-profile-corruption.json"

jq '.protocolVersions.driver = "ambient-driver-v9"' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-protocol-corruption.json"
expect_failure "DRV-001 protocol corruption" "DRV-001" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-protocol-corruption.json"

jq '.snapshots.source = "ambient-snapshot"' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-absence-corruption.json"
expect_failure "DRV-001 explicit absence corruption" "DRV-001" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-absence-corruption.json"

jq '.resources.memoryBytes = 0' "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-post-generation-corruption.json"
expect_failure "DRV-001 post-generation corruption" "DRV-001" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-post-generation-corruption.json"

jq '.identity.preparedSemanticIdentity = ("9" * 64)' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-prepared-substitution.json"
expect_classified_failure \
  "DRV-001 prepared identity substitution" "DRV-001" \
  "DRV-003 private identity chain" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-prepared-substitution.json"

jq '.identity.preparedSemanticIdentity = "malformed-prepared-identity"' \
  "${temporary_root}/driver-valid.json" \
  >"${temporary_root}/driver-prepared-malformed.json"
expect_classified_failure \
  "DRV-001 malformed prepared identity" "DRV-001" \
  "DRV-003 private identity chain" \
  jq -e "${driver_args[@]}" "${temporary_root}/driver-prepared-malformed.json"

named_projection_mutations="${temporary_root}/named-projection-mutations.json"
jq -n '[
  {label: "workspace destination", path: ["workspace", "destination"], value: "/other-workspace"},
  {label: "cpuMillis", path: ["resources", "cpuMillis"], value: 2000},
  {label: "memoryBytes", path: ["resources", "memoryBytes"], value: 1073741824},
  {label: "diskBytes", path: ["resources", "diskBytes"], value: 4294967296},
  {label: "uid", path: ["identitySecurity", "uid"], value: 2000},
  {label: "gid", path: ["identitySecurity", "gid"], value: 2000},
  {label: "output maxBytes", path: ["output", "maxBytes"], value: 2097152}
]' >"${named_projection_mutations}"

named_projection_index=0
while IFS= read -r named_mutation; do
  named_projection_index=$((named_projection_index + 1))
  named_leaf_label="$(jq -r '.label' <<<"${named_mutation}")"
  named_leaf_path="$(jq -c '.path' <<<"${named_mutation}")"
  named_leaf_value="$(jq -c '.value' <<<"${named_mutation}")"
  named_mutated="${temporary_root}/driver-named-${named_projection_index}.json"
  jq \
    --argjson leafPath "${named_leaf_path}" \
    --argjson leafValue "${named_leaf_value}" \
    'setpath($leafPath; $leafValue)' \
    "${driver_expected}" >"${named_mutated}"
  expect_failure \
    "DRV-001 valid-shaped ${named_leaf_label} substitution" "DRV-001" \
    jq -e "${driver_args[@]}" "${named_mutated}"
done < <(jq -c '.[]' "${named_projection_mutations}")

retained_source_dir="${temporary_root}/retained-source"
mkdir "${retained_source_dir}"
printf '%s\n' "original-workspace-object" >"${retained_source_dir}/workspace"
exec {retained_source_fd}<"${retained_source_dir}/workspace"
mv "${retained_source_dir}/workspace" "${retained_source_dir}/original-moved"
printf '%s\n' "replacement-path-object" >"${retained_source_dir}/workspace"
IFS= read -r retained_source_value <&"${retained_source_fd}"
exec {retained_source_fd}<&-
if [[ "${retained_source_value}" != "original-workspace-object" ]] ||
   [[ "$(<"${retained_source_dir}/workspace")" != "replacement-path-object" ]]; then
  echo "not ok - HOST-005 retained source handle followed a replaced path" >&2
  exit 1
fi
pass_count=$((pass_count + 1))
echo "ok - HOST-005 retained source handle survives path replacement"

if ((pass_count != expected_pass_count)); then
  echo "expected ${expected_pass_count} downstream cases, observed ${pass_count}" >&2
  exit 1
fi

echo "downstream boundary prototypes: ${pass_count} cases passed"
