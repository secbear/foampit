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
operation_registry="${script_dir}/PACKET-E-OPERATION-REGISTRY.json"
operation_case_contracts="${script_dir}/PACKET-E-CASE-CONTRACTS.json"
operation_contracts="${script_dir}/PACKET-E-OPERATION-CONTRACTS.json"
concurrency_matrix="${script_dir}/PACKET-E-CONCURRENCY-MATRIX.json"

for required_packet_d_file in \
  "${composition_paths}" \
  "${composition_case_contracts}" \
  "${composition_coverage}" \
  "${script_dir}/generate-composition-coverage.mjs" \
  "${script_dir}/validate-composition-coverage.jq" \
  "${script_dir}/test-composition-coverage.sh" \
  "${operation_registry}" \
  "${operation_case_contracts}" \
  "${operation_contracts}" \
  "${concurrency_matrix}" \
  "${script_dir}/generate-operation-contracts.mjs" \
  "${script_dir}/validate-operation-contracts.jq" \
  "${script_dir}/test-operation-contracts.sh"; do
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
operation_registry_sha256="$(
  sha256_file "${operation_registry}"
)"
operation_case_contracts_sha256="$(
  sha256_file "${operation_case_contracts}"
)"

# These pins detect drift and force explicit review. Semantic validation below,
# not a coordinated digest rewrite, remains authoritative.
expected_composition_paths_sha256="65322c7c30f4c75222a36793b8d1b877fa5813df4d1c83f236bb18884c364a65"
expected_composition_case_contracts_sha256="2d8ad1adb6588171a0b1f892d56641495e311b5b167a47473dc85522ee3767e2"
# Packet E pins. Second copies of the values inside validate-operation-contracts.jq, so a
# drifted pin aborts here before any validator runs -- the same discipline as Packet D.
expected_operation_registry_sha256="612d3c211c13af4629ebd7b48272d04198aad29a270ba9dc4b9938a2ac8359de"
expected_operation_case_contracts_sha256="ca608d2a82b962d077602cb89f0e15b9d622d34a45363ad0405602e5a653c223"
expected_invariant_registry_sha256="933697b9eb71411d37778660298789d9d077e5357ff1f2fb4651b7d89f921bdf"

if [[ "${operation_registry_sha256}" != "${expected_operation_registry_sha256}" ||
      "${operation_case_contracts_sha256}" != "${expected_operation_case_contracts_sha256}" ]]; then
  echo "Packet E digest pin mismatch; pins provide drift detection, not semantic authority" >&2
  exit 1
fi

if [[ "${composition_paths_sha256}" != "${expected_composition_paths_sha256}" ||
      "${composition_case_contracts_sha256}" != "${expected_composition_case_contracts_sha256}" ||
      "${invariant_registry_sha256}" != "${expected_invariant_registry_sha256}" ]]; then
  echo "Packet D digest pin mismatch; pins provide drift detection, not semantic authority" >&2
  exit 1
fi

# Runs first: several definitions are duplicated across independent oracles on
# purpose, and a drifted copy makes every downstream result untrustworthy.
"${script_dir}/check-model-coherence.sh"

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
    ($registry[0].invariants | length) == 355 and
    $paths[0].reviewedPathCount == 54 and
    ($paths[0].paths | length) == 54 and
    ($contracts[0].reviewedInvariantIds | length) == 355 and
    ($contracts[0].entries | length) == 54 and
    (.status == "candidate") and
    (.invariantIds == [$registry[0].invariants[].id]) and
    (.pathIds == [$paths[0].paths[].id]) and
    .expectedCellCount == 19170 and
    ([.rules[].selector.invariantIds[]] | length) == 19170 and
    .delegatedConcernTaxonomy == $contracts[0].delegatedConcernTaxonomy and
    .resolvedReentryReplay ==
      $contracts[0].serializedResolvedReentryReplaySets and
    .crossPathHandoffs == $contracts[0].crossPathHandoffs and
    .targetApplicabilityProjection ==
      $contracts[0].targetApplicabilityProjection
  ' \
  "${composition_coverage}" >/dev/null

"${script_dir}/test-operation-contracts.sh"
node "${script_dir}/generate-operation-contracts.mjs" --check
jq -e \
  --arg validationScope full \
  --arg operationRegistrySha256 "${operation_registry_sha256}" \
  --arg caseContractsSha256 "${operation_case_contracts_sha256}" \
  --arg invariantRegistrySha256 "${invariant_registry_sha256}" \
  --slurpfile registry "${operation_registry}" \
  --slurpfile catalog "${operation_case_contracts}" \
  --slurpfile invariants "${registry}" \
  --slurpfile concurrency "${concurrency_matrix}" \
  -f "${script_dir}/validate-operation-contracts.jq" \
  "${operation_contracts}" >/dev/null

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
operation_method_count="$(
  jq '[.operations[] | select(.id | startswith("deferred.") | not)] | length' "${operation_registry}"
)"
operation_deferral_count="$(
  jq '[.operations[] | select(.id | startswith("deferred."))] | length' "${operation_registry}"
)"
operation_state_count="$(jq '.lifecycleStates | length' "${operation_registry}")"
operation_cell_count="$(jq '.expectedCellCount' "${operation_contracts}")"
operation_rule_count="$(jq '.rules | length' "${operation_contracts}")"
operation_kind_counts="$(
  jq -r '
    [.rules[].valueCases[].cellKind] |
    group_by(.) |
    map("\(.[0])=\(length)") |
    join(", ")
  ' "${operation_contracts}"
)"
concurrency_cell_count="$(jq '.expectedCellCount' "${concurrency_matrix}")"
packet_e_operation_invariants="$(
  jq '[.operations[] | select(.coverageStatus == "generated") | .invariants[]] | unique | length' "${operation_registry}"
)"
packet_e_stated_absence_invariants="$(
  jq '
    ([.operations[] | select(.coverageStatus == "generated") | .invariants[]] | unique) as $generated |
    [.operations[] | select(.coverageStatus != "generated") | .invariants[]] |
    unique |
    map(select(. as $id | $generated | index($id) | not)) |
    length
  ' "${operation_registry}"
)"
packet_e_non_operation_invariants="$(
  jq '[.nonOperationCoverage.assignments[].invariants[]] | length' "${operation_registry}"
)"

echo "Gate 2A Packet E: ${operation_method_count} operations (+${operation_deferral_count} deferral markers) × ${operation_state_count} lifecycle states = ${operation_cell_count} cells; ${operation_rule_count} contract rules"
echo "Gate 2A Packet E cell kinds: ${operation_kind_counts}"
echo "Gate 2A Packet E concurrency: ${concurrency_cell_count} operation-pair cells"
echo "Gate 2A Packet E invariants: ${packet_e_operation_invariants} governed by a generated operation contract; ${packet_e_stated_absence_invariants} covered only by a stated absence; ${packet_e_non_operation_invariants} assigned to other ledgers"
echo "Gate 2A remains open for Packets E-F"
