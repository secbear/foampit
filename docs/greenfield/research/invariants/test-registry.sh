#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
validator="${script_dir}/validate-registry.sh"
inventory_fixture="${script_dir}/fixtures/minimal-inventory.json"
closed_fixture="${script_dir}/fixtures/minimal-closed.json"
corpus_fixture="${script_dir}/fixtures/minimal-corpus.md"
requested_mode="${1:-all}"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT

if [[ "${requested_mode}" != "inventory" &&
      "${requested_mode}" != "closure" &&
      "${requested_mode}" != "all" ]]; then
  echo "usage: $0 [inventory|closure|all]" >&2
  exit 2
fi

pass_count=0

run_validator() {
  local mode="$1"
  local input="$2"
  local corpus="${3:-}"
  if [[ -n "${corpus}" ]]; then
    "${validator}" "${mode}" "${input}" "${corpus}"
  else
    "${validator}" "${mode}" "${input}"
  fi
}

expect_pass() {
  local name="$1"
  local mode="$2"
  local input="$3"

  if ! output="$(run_validator "${mode}" "${input}" 2>&1)"; then
    echo "FAIL ${name}: expected success" >&2
    echo "${output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_mutation_failure() {
  local name="$1"
  local mode="$2"
  local base="$3"
  local mutation="$4"
  local expected="$5"
  local mutated="${tmp_dir}/${name}.json"

  jq "${mutation}" "${base}" >"${mutated}"
  if output="$(run_validator "${mode}" "${mutated}" 2>&1)"; then
    echo "FAIL ${name}: expected validation failure" >&2
    exit 1
  fi
  if [[ "${output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected diagnostic containing '${expected}'" >&2
    echo "${output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_mutation_pass() {
  local name="$1"
  local mode="$2"
  local base="$3"
  local mutation="$4"
  local mutated="${tmp_dir}/${name}.json"

  jq "${mutation}" "${base}" >"${mutated}"
  if ! output="$(run_validator "${mode}" "${mutated}" 2>&1)"; then
    echo "FAIL ${name}: expected validation success" >&2
    echo "${output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_coverage_pass() {
  local name="$1"
  local registry="$2"
  local corpus="$3"

  if ! output="$(run_validator "inventory" "${registry}" "${corpus}" 2>&1)"; then
    echo "FAIL ${name}: expected coverage success" >&2
    echo "${output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_coverage_failure() {
  local name="$1"
  local registry="$2"
  local corpus="$3"
  local expected="$4"

  if output="$(run_validator "inventory" "${registry}" "${corpus}" 2>&1)"; then
    echo "FAIL ${name}: expected coverage failure" >&2
    exit 1
  fi
  if [[ "${output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected diagnostic containing '${expected}'" >&2
    echo "${output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

run_inventory_cases() {
  expect_pass \
    "inventory-valid" \
    "inventory" \
    "${inventory_fixture}"

  expect_mutation_failure \
    "registry-version" \
    "inventory" \
    "${inventory_fixture}" \
    '.registryVersion = 2' \
    'registryVersion must equal 1'

  expect_mutation_failure \
    "duplicate-id" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants += [.invariants[0]]' \
    'duplicate invariant id: INV-001'

  expect_mutation_failure \
    "unknown-owner" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].owner = "frontend"' \
    'unknown owner'

  expect_mutation_pass \
    "live-owner" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].owner = "live"'

  expect_mutation_pass \
    "exec-owner" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].owner = "exec"'

  expect_mutation_pass \
    "runtime-owner" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].owner = "runtime"'

  expect_mutation_failure \
    "unknown-phase" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "BUILD"' \
    'unknown firstSoundPhase'

  expect_mutation_pass \
    "operator-configuration-validation-phase" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "P1" |
     .invariants[0].rejectionDeadline = "OC0" |
     .invariants[0].enforcementHooks[0].phase = "OC0"'

  expect_mutation_pass \
    "managed-service-definition-validation-phase" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "P1" |
     .invariants[0].rejectionDeadline = "MS0" |
     .invariants[0].enforcementHooks[0].phase = "MS0"'

  expect_mutation_pass \
    "resolved-reentry-wire-phase" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "RW0" |
     .invariants[0].rejectionDeadline = "RW0" |
     .invariants[0].enforcementHooks[0].phase = "RW0"'

  expect_mutation_failure \
    "phase-order" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "C0" | .invariants[0].rejectionDeadline = "A1"' \
    'rejectionDeadline is not reachable from firstSoundPhase'

  expect_mutation_pass \
    "live-phase-branch" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "L0" |
     .invariants[0].rejectionDeadline = "L1" |
     .invariants[0].enforcementHooks[0].phase = "L1"'

  expect_mutation_pass \
    "exec-phase-branch" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "E0" |
     .invariants[0].rejectionDeadline = "E1" |
     .invariants[0].enforcementHooks[0].phase = "E1"'

  expect_mutation_failure \
    "cross-operation-phase-order" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "L0" |
     .invariants[0].rejectionDeadline = "E0" |
     .invariants[0].enforcementHooks[0].phase = "E0"' \
    'rejectionDeadline is not reachable from firstSoundPhase'

  expect_mutation_pass \
    "framework-create-ingress" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "F0" |
     .invariants[0].rejectionDeadline = "C0" |
     .invariants[0].enforcementHooks[0].phase = "C0"'

  expect_mutation_pass \
    "service-live-ingress" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "S0" |
     .invariants[0].rejectionDeadline = "L0" |
     .invariants[0].enforcementHooks[0].phase = "L0"'

  expect_mutation_failure \
    "cross-ingress-phase-order" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].firstSoundPhase = "F0" |
     .invariants[0].rejectionDeadline = "S0" |
     .invariants[0].enforcementHooks[0].phase = "S0"' \
    'rejectionDeadline is not reachable from firstSoundPhase'

  expect_mutation_failure \
    "missing-invalid-witness" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].invalidWitnesses = []' \
    'invalidWitnesses must be non-empty'

  expect_mutation_failure \
    "missing-valid-witness" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].validWitnesses = []' \
    'validWitnesses must be non-empty'

  expect_mutation_failure \
    "missing-hook" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].enforcementHooks = []' \
    'enforcementHooks must be non-empty'

  expect_mutation_failure \
    "missing-test" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].tests = []' \
    'tests must be non-empty'

  expect_mutation_failure \
    "inventory-no-authority" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].enforcementHooks[0].role = "defensive"' \
    'inventory requires exactly one planned authoritative hook'

  expect_mutation_failure \
    "inventory-missing-positive" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].tests |= map(select(.kind != "positive-boundary"))' \
    'inventory requires planned positive-boundary evidence'

  expect_mutation_failure \
    "inventory-missing-corruption" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].tests |= map(select(.kind != "wire-corruption"))' \
    'inventory requires planned wire-corruption evidence'

  expect_mutation_failure \
    "inventory-uncovered-composition" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].compositionPaths += ["native-extension"]' \
    'composition path lacks planned evidence: native-extension'

  expect_mutation_failure \
    "inventory-uncovered-target" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].targets += ["bubblewrap"]' \
    'target lacks planned evidence: bubblewrap'

  expect_mutation_failure \
    "missing-diagnostic" \
    "inventory" \
    "${inventory_fixture}" \
    'del(.invariants[0].diagnostic.remediation)' \
    'diagnostic.remediation must be non-empty'

  expect_mutation_failure \
    "placeholder" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].rationale = "TBD"' \
    'contains placeholder content'

  expect_mutation_failure \
    "unknown-hook-role" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].enforcementHooks[0].role = "primary-ish"' \
    'unknown hook role'

  expect_mutation_failure \
    "unknown-test-kind" \
    "inventory" \
    "${inventory_fixture}" \
    '.invariants[0].tests[0].kind = "unit"' \
    'unknown test kind'

  expect_coverage_pass \
    "corpus-coverage-valid" \
    "${inventory_fixture}" \
    "${corpus_fixture}"

  local corpus_extra="${tmp_dir}/corpus-extra.md"
  {
    printf '%s\n' '# Corpus with unregistered invariant'
    printf '%s\n' '#### `INV-001` Existing invariant'
    printf '%s\n' '#### `INV-002` Missing registry invariant'
  } >"${corpus_extra}"
  expect_coverage_failure \
    "corpus-id-missing-from-registry" \
    "${inventory_fixture}" \
    "${corpus_extra}" \
    'corpus invariant missing from registry: INV-002'

  local registry_extra="${tmp_dir}/registry-extra.json"
  jq '.invariants += [
        (.invariants[0] |
         .id = "INV-002" |
         .diagnostic.identity = "INV-002")
      ]' "${inventory_fixture}" >"${registry_extra}"
  expect_coverage_failure \
    "registry-id-missing-from-corpus" \
    "${registry_extra}" \
    "${corpus_fixture}" \
    'registry invariant missing from corpus: INV-002'

  local invalid_witness_unknown="${tmp_dir}/invalid-witness-unknown.json"
  jq '.invariants[0].invalidWitnesses = ["INV-999"]' \
    "${inventory_fixture}" >"${invalid_witness_unknown}"
  expect_coverage_failure \
    "unknown-invalid-witness" \
    "${invalid_witness_unknown}" \
    "${corpus_fixture}" \
    'unknown invalid witness: INV-999'

  local valid_witness_unknown="${tmp_dir}/valid-witness-unknown.json"
  jq '.invariants[0].validWitnesses = ["VAL-999"]' \
    "${inventory_fixture}" >"${valid_witness_unknown}"
  expect_coverage_failure \
    "unknown-valid-witness" \
    "${valid_witness_unknown}" \
    "${corpus_fixture}" \
    'unknown valid witness: VAL-999'
}

assert_packet_d_correction_registration() {
  local registry="${script_dir}/invariants.json"
  local failures

  # Reports which assertion failed. This was previously a bare
  # `jq -e ... >/dev/null`, so a count mismatch aborted check-inventory.sh with
  # completely empty output and read as a harness crash rather than a failed
  # assertion.
  failures="$(
    jq -r '
      [.invariants[].id] as $ids |
      (.invariants | length) as $count |
      [
        ([
          "OPS-003","OPS-004","OPS-005",
          "SVC-003","SVC-004","SVC-005",
          "WIRE-007","DRV-002","DRV-003","DRV-004"
        ][] | select($ids | index(.) == null) |
          "Packet D correction invariant missing from the registry: \(.)"),

        ([
          "ADP-001","ERR-001","FRK-001","RET-001","SOP-001"
        ][] | select($ids | index(.) == null) |
          "Packet E batch 4 invariant missing from the registry: \(.)"),

        (if $count == 354 then empty
         else "registry length is \($count); Packet E batch 2 expects 354 (297 + 57)"
         end)
      ] | .[]
    ' "${registry}"
  )"

  if [[ -n "${failures}" ]]; then
    printf '%s\n' "${failures}" >&2
    return 1
  fi
}

run_closure_cases() {
  expect_pass \
    "closure-valid" \
    "closure" \
    "${closed_fixture}"

  expect_mutation_failure \
    "closure-status" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].status = "prototype-enforced"' \
    'closure requires status closed'

  expect_mutation_failure \
    "closure-planned-hook" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].enforcementHooks[0].status = "planned"' \
    'closure forbids planned enforcement hooks'

  expect_mutation_failure \
    "closure-planned-test" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].tests[0].status = "planned"' \
    'closure requires passing tests'

  expect_mutation_failure \
    "closure-no-authority" \
    "closure" \
    "${closed_fixture}" \
    '(.invariants[0].enforcementHooks[] | select(.role == "authoritative")).role = "defensive"' \
    'closure requires exactly one authoritative hook'

  expect_mutation_failure \
    "closure-missing-positive" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].tests |= map(select(.kind != "positive-boundary"))' \
    'closure requires positive-boundary evidence'

  expect_mutation_failure \
    "closure-missing-corruption" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].tests |= map(select(.kind != "wire-corruption"))' \
    'closure requires wire-corruption evidence'

  expect_mutation_failure \
    "closure-missing-diagnostic-test" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].tests |= map(select(.kind != "diagnostic"))' \
    'closure requires diagnostic evidence'

  expect_mutation_failure \
    "closure-uncovered-composition" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].compositionPaths += ["native-extension"]' \
    'composition path lacks passing evidence: native-extension'

  expect_mutation_failure \
    "closure-uncovered-target" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].targets += ["bubblewrap"]' \
    'target lacks passing evidence: bubblewrap'

  expect_mutation_failure \
    "closure-missing-hook-file" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].enforcementHooks[0].path = "fixtures/does-not-exist"' \
    'referenced hook path does not exist'

  expect_mutation_failure \
    "closure-missing-hook-reference" \
    "closure" \
    "${closed_fixture}" \
    '.invariants[0].enforcementHooks[0].path = "validate-registry.jq"' \
    'hook path does not reference invariant id'
}

case "${requested_mode}" in
  inventory)
    run_inventory_cases
    assert_packet_d_correction_registration
    ;;
  closure)
    run_closure_cases
    ;;
  all)
    run_inventory_cases
    assert_packet_d_correction_registration
    run_closure_cases
    ;;
esac

echo "registry validator: ${pass_count} cases passed (${requested_mode})"
