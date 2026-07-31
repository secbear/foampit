#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
corpus="${script_dir}/../CONFIGURATION-LANGUAGE-CORPUS.md"
registry="${script_dir}/invariants.json"
surface_coverage="${script_dir}/PACKET-A-SURFACE-COVERAGE.json"
artifact_field_review="${script_dir}/PACKET-B-ARTIFACT-FIELDS.json"
target_profiles="${script_dir}/PACKET-C-TARGET-PROFILES.json"
target_realization="${script_dir}/PACKET-C-TARGET-REALIZATION.json"
target_case_contracts="${script_dir}/PACKET-C-CASE-CONTRACTS.json"
provider_contracts="${script_dir}/PACKET-C-PROVIDER-CONTRACTS.json"
composition_paths="${script_dir}/PACKET-D-COMPOSITION-PATHS.json"
composition_coverage="${script_dir}/PACKET-D-COMPOSITION-COVERAGE.json"
composition_case_contracts="${script_dir}/PACKET-D-CASE-CONTRACTS.json"

for required_packet_d_file in \
  "${composition_paths}" \
  "${composition_case_contracts}" \
  "${composition_coverage}" \
  "${script_dir}/generate-composition-coverage.mjs" \
  "${script_dir}/validate-composition-coverage.jq" \
  "${script_dir}/test-composition-coverage.sh"; do
  if [[ ! -f "${required_packet_d_file}" ]]; then
    echo "Missing required Packet D inventory file: ${required_packet_d_file}" >&2
    exit 1
  fi
done

sha256_file() {
  local path="$1"
  if command -v sha256sum >/dev/null 2>&1; then
    sha256sum "${path}" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then
    shasum -a 256 "${path}" | awk '{print $1}'
  else
    echo "A SHA-256 implementation (sha256sum or shasum) is required." >&2
    return 127
  fi
}

target_profile_sha256="$(
  sha256_file "${target_profiles}"
)"
target_case_contracts_sha256="$(
  sha256_file "${target_case_contracts}"
)"
composition_paths_sha256="$(
  sha256_file "${composition_paths}"
)"
composition_case_contracts_sha256="$(
  sha256_file "${composition_case_contracts}"
)"
invariant_registry_sha256="$(
  sha256_file "${registry}"
)"

# These pins detect drift and force explicit review. Semantic validation below,
# not a coordinated digest rewrite, remains authoritative.
expected_composition_paths_sha256="488bf76167461b52766dd9fa8a9b1756d084f1ebc08c795315fd2baf2fbab6e0"
expected_composition_case_contracts_sha256="955c3dd8c03927be6876c58b2c3c67210f1fc0710ecf5f5ea2a4a2c59bc3f5b0"
expected_invariant_registry_sha256="05ee00cb46cf0533337640d6dc5b8eabbe0eb8e9affdc62b5da0b4c6502505f1"

if [[ "${composition_paths_sha256}" != "${expected_composition_paths_sha256}" ||
      "${composition_case_contracts_sha256}" != "${expected_composition_case_contracts_sha256}" ||
      "${invariant_registry_sha256}" != "${expected_invariant_registry_sha256}" ]]; then
  echo "Packet D digest pin mismatch; pins provide drift detection, not semantic authority" >&2
  exit 1
fi

"${script_dir}/test-registry.sh" inventory
"${script_dir}/validate-registry.sh" inventory "${registry}" "${corpus}"
"${script_dir}/test-surface-coverage.sh"
jq -e \
  --slurpfile registry "${registry}" \
  -f "${script_dir}/validate-surface-coverage.jq" \
  "${surface_coverage}" >/dev/null
"${script_dir}/test-artifact-field-review.sh"
jq -e \
  --slurpfile registry "${registry}" \
  --slurpfile packetA "${surface_coverage}" \
  -f "${script_dir}/validate-artifact-field-review.jq" \
  "${artifact_field_review}" >/dev/null
"${script_dir}/test-target-realization.sh"
node "${script_dir}/generate-target-realization.mjs" --check
jq -e \
  --arg profileRegistrySha256 "${target_profile_sha256}" \
  --arg caseContractsSha256 "${target_case_contracts_sha256}" \
  --slurpfile caseContracts "${target_case_contracts}" \
  --slurpfile profiles "${target_profiles}" \
  --slurpfile fields "${artifact_field_review}" \
  --slurpfile registry "${registry}" \
  -f "${script_dir}/validate-target-realization.jq" \
  "${target_realization}" >/dev/null
"${script_dir}/test-provider-contracts.sh"
jq -e \
  -f "${script_dir}/validate-provider-contracts.jq" \
  "${provider_contracts}" >/dev/null
jq -e \
  --slurpfile registry "${registry}" \
  '
    ([ $registry[0].invariants[].id ]) as $registry_ids |
    (
      (
        [.introducedInvariants[]] +
        [.contracts[].invariants[]]
      ) -
      $registry_ids
    ) |
    length == 0
  ' \
  "${provider_contracts}" >/dev/null
"${script_dir}/test-composition-coverage.sh"
node "${script_dir}/generate-composition-coverage.mjs" --check
jq -e \
  --arg validationScope full \
  --arg pathsRegistrySha256 "${composition_paths_sha256}" \
  --arg caseContractsSha256 "${composition_case_contracts_sha256}" \
  --arg invariantRegistrySha256 "${invariant_registry_sha256}" \
  --slurpfile paths "${composition_paths}" \
  --slurpfile caseContracts "${composition_case_contracts}" \
  --slurpfile registry "${registry}" \
  --slurpfile targetRealization "${target_realization}" \
  -f "${script_dir}/validate-composition-coverage.jq" \
  "${composition_coverage}" >/dev/null
jq -e \
  --slurpfile registry "${registry}" \
  --slurpfile paths "${composition_paths}" \
  --slurpfile contracts "${composition_case_contracts}" \
  '
    ($registry[0].invariants | length) == 140 and
    $paths[0].reviewedPathCount == 54 and
    ($paths[0].paths | length) == 54 and
    ($contracts[0].reviewedInvariantIds | length) == 140 and
    ($contracts[0].entries | length) == 54 and
    (.status == "candidate") and
    (.invariantIds == [$registry[0].invariants[].id]) and
    (.pathIds == [$paths[0].paths[].id]) and
    .expectedCellCount == 7560 and
    ([.rules[].selector.invariantIds[]] | length) == 7560 and
    .delegatedConcernTaxonomy == $contracts[0].delegatedConcernTaxonomy and
    .resolvedReentryReplay ==
      $contracts[0].serializedResolvedReentryReplaySets and
    .crossPathHandoffs == $contracts[0].crossPathHandoffs and
    .targetApplicabilityProjection ==
      $contracts[0].targetApplicabilityProjection
  ' \
  "${composition_coverage}" >/dev/null

invariant_count="$(jq '.invariants | length' "${registry}")"
surface_count="$(jq '.surfaces | length' "${surface_coverage}")"
artifact_field_count="$(jq '.fields | length' "${artifact_field_review}")"
packet_b_invariant_count="$(jq '.introducedInvariants | length' "${artifact_field_review}")"
target_profile_count="$(jq '.profiles | length' "${target_profiles}")"
target_cell_count="$(jq '.expectedCellCount' "${target_realization}")"
target_rule_count="$(jq '.rules | length' "${target_realization}")"
target_value_case_count="$(jq '[.rules[].cases[]] | length' "${target_realization}")"
target_outcome_counts="$(
  jq -r '
    [.rules[].cases[].outcome] |
    group_by(.) |
    map("\(.[0])=\(length)") |
    join(", ")
  ' "${target_realization}"
)"
provider_contract_count="$(jq '.contracts | length' "${provider_contracts}")"
packet_c_target_invariant_count="$(jq '.introducedInvariants | length' "${target_realization}")"
packet_c_provider_invariant_count="$(jq '.introducedInvariants | length' "${provider_contracts}")"
composition_path_count="$(jq '.paths | length' "${composition_paths}")"
composition_cell_count="$(jq '.expectedCellCount' "${composition_coverage}")"
composition_rule_count="$(jq '.rules | length' "${composition_coverage}")"
composition_frontend_mapping_count="$(
  jq '[.paths[].frontendMappings[]] | length' "${composition_paths}"
)"
composition_native_path_count="$(
  jq '
    [
      .paths[] |
      select(
        .category == "artifact-native" or
        .category == "lifecycle-native" or
        .category == "provider-native"
      )
    ] |
    length
  ' "${composition_paths}"
)"
composition_effect_counts="$(
  jq -r '
    .classificationCodeContract as $contracts |
    [.classificationVectorsByPath[] | split("")[]] |
    group_by(.) |
    map("\($contracts[.[0]])=\(length)") |
    join(", ")
  ' "${composition_case_contracts}"
)"
packet_d_invariant_count="$(
  jq '
    [
      .invariants[].id |
      select(
        . == "CMP-009" or
        . == "CMP-010" or
        . == "CMP-011" or
        . == "WIRE-005" or
        . == "WIRE-006" or
        . == "WIRE-007" or
        . == "MIG-001" or
        . == "NAT-003" or
        . == "OPS-003" or
        . == "OPS-004" or
        . == "OPS-005" or
        . == "SVC-003" or
        . == "SVC-004" or
        . == "SVC-005" or
        . == "DRV-002" or
        . == "DRV-003" or
        . == "DRV-004"
      )
    ] |
    length
  ' "${registry}"
)"
echo "Gate 2A registry structure: ${invariant_count} corpus invariants covered"
echo "Gate 2A Packet A: ${surface_count} public surface groups reviewed"
echo "Gate 2A Packet B: ${artifact_field_count} Artifact fields reviewed; ${packet_b_invariant_count} invariants introduced"
echo "Gate 2A Packet C: ${target_profile_count} target profiles; ${target_cell_count} field/profile cells; ${target_rule_count} selector rules; ${target_value_case_count} structurally complete ordered value cases"
echo "Gate 2A Packet C outcomes by value case: ${target_outcome_counts}"
echo "Gate 2A Packet C providers: ${provider_contract_count} transport contracts"
echo "Gate 2A Packet C invariants: $((packet_c_target_invariant_count + packet_c_provider_invariant_count)) introduced"
echo "Gate 2A Packet D: ${composition_path_count} paths × ${invariant_count} invariants = ${composition_cell_count} cells; ${composition_rule_count} identical-contract selector groups"
echo "Gate 2A Packet D effects: ${composition_effect_counts}"
echo "Gate 2A Packet D mappings/surfaces: ${composition_frontend_mapping_count} frontend/path mappings; ${composition_native_path_count} native paths"
echo "Gate 2A Packet D invariants: ${packet_d_invariant_count} introduced"
echo "Gate 2A remains open for Packets E-F"
