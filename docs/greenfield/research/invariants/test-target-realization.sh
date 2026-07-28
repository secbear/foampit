#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
validator="${script_dir}/validate-target-realization.jq"
realization_fixture="${script_dir}/PACKET-C-TARGET-REALIZATION.json"
case_contracts="${script_dir}/PACKET-C-CASE-CONTRACTS.json"
profile_fixture="${script_dir}/PACKET-C-TARGET-PROFILES.json"
field_fixture="${script_dir}/PACKET-B-ARTIFACT-FIELDS.json"
registry_fixture="${script_dir}/invariants.json"

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

profile_fixture_sha256="$(
  sha256_file "${profile_fixture}"
)"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT
pass_count=0

run_validator() {
  local realization="$1"
  local profiles="$2"
  local case_contracts_fixture="${3:-${case_contracts}}"
  local profile_registry_sha256_override="${4:-}"
  local case_contracts_sha256_override="${5:-}"
  local profile_registry_sha256
  local case_contracts_sha256
  if [[ -n "${profile_registry_sha256_override}" ]]; then
    profile_registry_sha256="${profile_registry_sha256_override}"
  else
    profile_registry_sha256="$(sha256_file "${profiles}")"
  fi
  if [[ -n "${case_contracts_sha256_override}" ]]; then
    case_contracts_sha256="${case_contracts_sha256_override}"
  else
    case_contracts_sha256="$(sha256_file "${case_contracts_fixture}")"
  fi
  jq -e \
    --arg profileRegistrySha256 "${profile_registry_sha256}" \
    --arg caseContractsSha256 "${case_contracts_sha256}" \
    --slurpfile caseContracts "${case_contracts_fixture}" \
    --slurpfile profiles "${profiles}" \
    --slurpfile fields "${field_fixture}" \
    --slurpfile registry "${registry_fixture}" \
    -f "${validator}" \
    "${realization}" >/dev/null
}

expect_case_contract_failure() {
  local name="$1"
  local mutation="$2"
  local expected="$3"
  local mutated="${tmp_dir}/${name}-case-contracts.json"
  jq "${mutation}" "${case_contracts}" >"${mutated}"
  if target_output="$(
    run_validator "${realization_fixture}" "${profile_fixture}" "${mutated}" 2>&1
  )"; then
    echo "FAIL ${name}: expected failure" >&2
    exit 1
  fi
  if [[ "${target_output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${target_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_pass() {
  local name="$1"
  local realization="$2"
  local profiles="${3:-${profile_fixture}}"
  if ! target_output="$(run_validator "${realization}" "${profiles}" 2>&1)"; then
    echo "FAIL ${name}: expected success" >&2
    echo "${target_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_failure() {
  local name="$1"
  local mutation="$2"
  local expected="$3"
  local mutated="${tmp_dir}/${name}.json"
  jq "${mutation}" "${realization_fixture}" >"${mutated}"
  if target_output="$(run_validator "${mutated}" "${profile_fixture}" 2>&1)"; then
    echo "FAIL ${name}: expected failure" >&2
    exit 1
  fi
  if [[ "${target_output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${target_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_profile_failure() {
  local name="$1"
  local mutation="$2"
  local expected="$3"
  local mutated="${tmp_dir}/${name}-profiles.json"
  jq "${mutation}" "${profile_fixture}" >"${mutated}"
  if target_output="$(
    run_validator \
      "${realization_fixture}" \
      "${mutated}" \
      "${case_contracts}" \
      "${profile_fixture_sha256}" 2>&1
  )"; then
    echo "FAIL ${name}: expected failure" >&2
    exit 1
  fi
  if [[ "${target_output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${target_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_profile_pin_failure() {
  local name="$1"
  local mutation="$2"
  local expected="$3"
  local mutated="${tmp_dir}/${name}-profiles.json"
  jq "${mutation}" "${profile_fixture}" >"${mutated}"
  if target_output="$(
    run_validator "${realization_fixture}" "${mutated}" 2>&1
  )"; then
    echo "FAIL ${name}: expected failure" >&2
    exit 1
  fi
  if [[ "${target_output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${target_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_pass "real-target-realization" "${realization_fixture}"
expect_profile_failure \
  "duplicate-profile" \
  '.profiles += [.profiles[0]]' \
  'duplicate profile id: bubblewrap-linux-v1'
expect_profile_failure \
  "missing-implementation-bundle" \
  '.profiles[0].implementationBundleExplanations = []' \
  'implementationBundleExplanations must be non-empty'
expect_profile_failure \
  "missing-research-pin" \
  '.profiles[0].researchPins = []' \
  'researchPins must be non-empty'
expect_profile_failure \
  "invalid-research-pin" \
  '.profiles[0].researchPins[0].revision = ""' \
  'research pin revision must be non-empty'
expect_profile_failure \
  "missing-unsupported-set" \
  '.profiles[0].baselineUnsupportedExplanations = []' \
  'baselineUnsupportedExplanations must be non-empty'
expect_profile_failure \
  "missing-production-identity-rule" \
  '.productionIdentityContract.reviewCoordinateIsProductionIdentity = true' \
  'target profile productionIdentityContract must equal the closed production identity contract'
expect_profile_failure \
  "unknown-profile-key" \
  '.profiles[0].unreviewedEscapeHatch = true' \
  'unknown profile key: unreviewedEscapeHatch'
expect_profile_failure \
  "missing-initial-profile" \
  '.profiles |= map(select(.id != "oci-linux-v1"))' \
  'target profile IDs must equal the locked Packet C initial profile universe'
expect_profile_failure \
  "renamed-initial-profile" \
  '.profiles[0].id = "renamed-bubblewrap-v1"' \
  'target profile IDs must equal the locked Packet C initial profile universe'
expect_profile_failure \
  "extra-initial-profile" \
  '.profiles += [(.profiles[0] | .id = "extra-profile-v1")]' \
  'target profile IDs must equal the locked Packet C initial profile universe'
expect_profile_failure \
  "profile-family-mismatch" \
  '.profiles[0].targetFamily = "oci"' \
  'targetFamily must match the locked profile coordinate'
expect_profile_pin_failure \
  "profile-registry-tandem-rewrite" \
  '.profiles[0].memberKind = "provider-selected-member"' \
  'target profile registry SHA-256 must equal the independently reviewed validator pin'
expect_failure \
  "duplicate-rule" \
  '.rules += [.rules[0]]' \
  'duplicate rule id: TRL-001-COMMON-IDENTITY'
expect_failure \
  "uncovered-cell" \
  '.rules[0].profileIds = ["bubblewrap-linux-v1"]' \
  'uncovered realization cell: artifact.profile.selection × microvm-firecracker-linux-v1'
expect_failure \
  "overlapping-cell" \
  '.rules[1].fieldIds += ["artifact.profile.selection"] |
   .rules[1].fieldTraceability["artifact.profile.selection"] =
     .rules[0].fieldTraceability["artifact.profile.selection"]' \
  'overlapping realization cell: artifact.profile.selection × bubblewrap-linux-v1'
expect_failure \
  "unknown-field" \
  '.rules[0].fieldIds = ["artifact.unknown"]' \
  'unknown Artifact field: artifact.unknown'
expect_failure \
  "unknown-profile" \
  '.rules[0].profileIds = ["unknown-v1"]' \
  'unknown target profile: unknown-v1'
expect_failure \
  "unknown-invariant" \
  '.rules[0].cases[0].invariants = ["INV-999"]' \
  'unknown invariant reference: INV-999'
expect_failure \
  "empty-field-selector" \
  '.rules[0].fieldIds = []' \
  'fieldIds must be non-empty'
expect_failure \
  "empty-profile-selector" \
  '.rules[0].profileIds = []' \
  'profileIds must be non-empty'
expect_failure \
  "missing-field-traceability" \
  '.rules[0].fieldTraceability = {}' \
  'fieldTraceability keys must equal fieldIds'
expect_failure \
  "wrong-field-invariants" \
  '.rules[0].fieldTraceability["artifact.profile.selection"].invariants = []' \
  'fieldTraceability invariants must equal Packet B'
expect_failure \
  "wrong-field-delegation" \
  '.rules[0].fieldTraceability["artifact.provenance.builtIdentities"].delegatedPackets = []' \
  'fieldTraceability delegatedPackets must equal unresolved Packet B delegations'
expect_failure \
  "invalid-outcome" \
  '.rules[0].cases[0].outcome = "best-effort"' \
  'unknown outcome: best-effort'
expect_failure \
  "invalid-phase-order" \
  '.rules[0].cases[0].firstSoundPhase = "R1" |
   .rules[0].cases[0].deadline = "N1"' \
  'firstSoundPhase occurs after deadline'
expect_failure \
  "missing-authority" \
  '.rules[0].cases[0].authority.component = ""' \
  'authority component must be non-empty'
expect_failure \
  "authority-does-not-name-step" \
  '.rules[0].cases[0].authority.component = "another-component"' \
  'authority must identify an exact realization step'
expect_failure \
  "outcome-authority-mismatch" \
  '.rules[0].cases[0].authority.component = "alternate-builder" |
   .rules[0].cases[0].steps[0].component = "alternate-builder"' \
  'conforming-lowering must span N0 to N1 with target-member-builder authority at N1'
expect_failure \
  "step-outside-authority-window" \
  '.rules[0].cases[0].steps += [
     (.rules[0].cases[0].steps[0] | .phase = "R1")
   ]' \
  'every realization step must fall between firstSoundPhase and deadline'
expect_failure \
  "steps-out-of-phase-order" \
  '.rules[3].cases[0].steps |= reverse' \
  'realization steps must be ordered by phase'
expect_failure \
  "missing-manifest-explanation" \
  '.rules[0].cases[0].manifestProjection.explanation = "  "' \
  'manifestProjection explanation must be non-empty'
expect_failure \
  "missing-diagnostic" \
  '.rules[0].cases[0].diagnostic.remediation = ""' \
  'diagnostic remediation must be non-empty'
expect_failure \
  "diagnostic-path-mismatch" \
  '.rules[0].cases[0].diagnostic.primaryPaths = ["artifact.network.access"]' \
  'diagnostic primaryPaths must equal rule fieldIds'
expect_failure \
  "missing-evidence" \
  '.rules[0].cases[0].evidence = []' \
  'evidence must be a non-empty structured obligation array'
expect_failure \
  "placeholder-content" \
  '.rules[0].cases[0].rationale = "TBD"' \
  'contains placeholder content'
expect_failure \
  "target-default-inheritance" \
  '.rules[0].cases[0].fallbackPolicy = "target-default"' \
  'fallbackPolicy must equal forbidden'
expect_failure \
  "best-effort-approximation" \
  '.rules[0].cases[0].approximationPolicy = "warning"' \
  'approximationPolicy must equal forbidden'
expect_failure \
  "mutated-safety-policy" \
  '.rules[0].cases[0].safetyPolicy.failure = "fail-open"' \
  'safetyPolicy must equal the closed fail-closed realization policy'
expect_failure \
  "prose-cannot-replace-structured-step" \
  '.rules[0].cases[0].steps[0].behavior =
     "If exact lowering fails, continue with automatically selected runtime settings."' \
  'unknown step key: behavior'
expect_failure \
  "best-effort-hidden-in-evidence" \
  '.rules[0].cases[0].evidence = ["best effort"]' \
  'evidence must be a non-empty structured obligation array'
expect_failure \
  "late-unsupported" \
  '.rules[0].cases[0].outcome = "build-time-unsupported" |
   .rules[0].cases[0].firstSoundPhase = "N0" |
   .rules[0].cases[0].deadline = "D0" |
   .rules[0].cases[0].authority.phase = "D0" |
   .rules[0].cases[0].steps[0].mode = "build-rejection"' \
  'build-time-unsupported must reject no later than N1'
expect_failure \
  "missing-value-cases" \
  '.rules[0].cases = []' \
  'cases must be non-empty'
expect_failure \
  "single-case-not-all-values" \
  '.rules[0].cases[0].condition.kind = "otherwise"' \
  'single value case must use all-values'
expect_failure \
  "duplicate-value-case" \
  '.rules[0].cases += [.rules[0].cases[0]]' \
  'duplicate value case id: all-values'
expect_failure \
  "partition-without-otherwise" \
  '.rules[0].cases[0].id = "present" |
   .rules[0].cases[0].condition = {
     "kind": "field-present",
     "path": "artifact.profile.selection"
   } |
   .rules[0].cases += [
     (.rules[0].cases[0] |
       .id = "omitted" |
       .condition.kind = "field-omitted")
   ]' \
  'partitioned value cases require exactly one otherwise case'
expect_failure \
  "overlapping-partition-shape" \
  '.rules[0].cases[0].id = "present" |
   .rules[0].cases[0].condition = {
     "kind": "field-present",
     "path": "artifact.environment"
   } |
   .rules[0].cases += [
     (.rules[0].cases[0] |
       .id = "alternative" |
       .condition = {
         "kind": "alternative",
         "path": "artifact.profile.selection",
         "values": ["closed"]
       }),
     (.rules[0].cases[0] |
       .id = "otherwise" |
       .condition = {"kind": "otherwise"})
  ]' \
  'unsupported value-partition shape'
expect_failure \
  "missing-constraint-predicate-id" \
  '.rules[0].cases[0].condition = {
     "kind": "constraint-satisfied",
     "requirement": "A named implementation predicate must decide this case."
  }' \
  'constraint predicateId must equal rule/case identity'
expect_failure \
  "irrelevant-condition-property" \
  '.rules[0].cases[0].condition.requirement = "This must not be ignored."' \
  'unknown condition key: requirement'
expect_failure \
  "condition-path-outside-rule" \
  '.rules[0].cases[0].condition = {
     "kind": "field-omitted",
     "path": "artifact.network.access"
  }' \
  'value condition path must select a field in its rule'
expect_failure \
  "mutated-obligation-id" \
  '.rules[0].cases[0].steps[0].obligationId = "another-obligation"' \
  'step obligationId must equal its rule/case/index/phase/mode identity'
expect_failure \
  "removed-dynamic-operator-step" \
  '(.rules[] |
     select(.id == "TRL-016-BUBBLEWRAP-SCRATCH") |
     .cases[0].steps) |= map(select(.mode != "operator-binding"))' \
  'dynamic observed-conformance steps must equal the locked ownership chain'
expect_failure \
  "dynamic-mode-at-wrong-phase" \
  '(.rules[] |
     select(.id == "TRL-016-BUBBLEWRAP-SCRATCH") |
     .cases[0].steps[2]) |=
       (.phase = "C0" |
        .obligationId =
          "TRL-016-BUBBLEWRAP-SCRATCH/all-values/step-3/C0/operator-binding")' \
  'realization mode must use its canonical phase'
expect_failure \
  "construction-unsupported-too-early" \
  '(.rules[] |
     select(.id == "TRL-045-CONDITIONAL-CONSTRUCTION-CLAIMS") |
     .cases[] |
     select(.outcome == "build-time-unsupported") |
     .firstSoundPhase) = "N0"' \
  'build-time-unsupported authority must be artifact-final-validator at A1 or target-member-builder at N1'
expect_failure \
  "mutated-text-authority" \
  '.textAuthority = "Prose may override structured policy."' \
  'textAuthority must lock structured controls and mark explanations non-normative'
expect_failure \
  "dynamic-component-relabel" \
  '(.rules[] |
     select(.id == "TRL-016-BUBBLEWRAP-SCRATCH") |
     .cases[0].steps[2].component) = "artifact-final-validator"' \
  'realization mode and phase must use their canonical component'
expect_failure \
  "dynamic-first-sound-relabel" \
  '(.rules[] |
     select(.id == "TRL-016-BUBBLEWRAP-SCRATCH") |
     .cases[0].firstSoundPhase) = "P0"' \
  'observed-conformance firstSoundPhase must equal its locked rule phase'
expect_failure \
  "conforming-deadline-relabel" \
  '.rules[0].cases[0].deadline = "R1"' \
  'conforming-lowering must span N0 to N1 with target-member-builder authority at N1'
expect_failure \
  "evidence-class-relabel" \
  '.rules[0].cases[0].evidence[0].class = "process-alive"' \
  'evidence obligation must have a stable class and rule/case/index identity'
expect_failure \
  "evidence-contract-rewrite" \
  '.rules[0].cases[0].evidence = [{
     "obligationId": "TRL-001-COMMON-IDENTITY/all-values/evidence-1/process-alive",
     "class": "process-alive"
   }]' \
  'structured controls must equal the generator-owned case contract'
expect_failure \
  "delegation-contract-rewrite" \
  '.rules[0].cases[0].delegatedPackets = ["F"]' \
  'structured controls must equal the generator-owned case contract'
expect_failure \
  "outcome-contract-rewrite" \
  '.rules[0].cases[0].outcome = "observed-conformance"' \
  'structured controls must equal the generator-owned case contract'
expect_failure \
  "unknown-realization-key" \
  '.implicitFallback = true' \
  'unknown target realization key: implicitFallback'
expect_failure \
  "shrunken-cell-universe" \
  '.expectedCellCount = 243' \
  'expectedCellCount and realized profile universe must equal the locked 324 cells'
expect_failure \
  "unknown-case-key" \
  '.rules[0].cases[0].warningOnly = true' \
  'unknown case key: warningOnly'
expect_case_contract_failure \
  "tandem-case-contract-rewrite" \
  '(.entries[] |
     select(.identity == "TRL-016-BUBBLEWRAP-SCRATCH/all-values")) |=
     (.outcome = "conforming-lowering" |
      .firstSoundPhase = "N0" |
      .deadline = "N1" |
      .authority = {
        "phase": "N1",
        "component": "target-member-builder"
      } |
      .steps = [{
        "phase": "N1",
        "mode": "manifest-only",
        "component": "target-member-builder"
      }] |
      .evidenceClasses = ["target-member-manifest"])' \
  'case-contract catalog SHA-256 must equal the independently reviewed validator pin'

echo "target realization validator: ${pass_count} cases passed"
