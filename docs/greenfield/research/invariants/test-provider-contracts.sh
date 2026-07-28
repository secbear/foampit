#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
validator="${script_dir}/validate-provider-contracts.jq"
fixture="${script_dir}/PACKET-C-PROVIDER-CONTRACTS.json"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT
pass_count=0

run_validator() {
  jq -e -f "${validator}" "$1" >/dev/null
}

expect_pass() {
  local name="$1"
  local input="$2"
  if ! provider_output="$(run_validator "${input}" 2>&1)"; then
    echo "FAIL ${name}: expected success" >&2
    echo "${provider_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_failure() {
  local name="$1"
  local mutation="$2"
  local expected="$3"
  local mutated="${tmp_dir}/${name}.json"
  jq "${mutation}" "${fixture}" >"${mutated}"
  if provider_output="$(run_validator "${mutated}" 2>&1)"; then
    echo "FAIL ${name}: expected failure" >&2
    exit 1
  fi
  if [[ "${provider_output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${provider_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_mutation_pass() {
  local name="$1"
  local mutation="$2"
  local mutated="${tmp_dir}/${name}.json"
  jq "${mutation}" "${fixture}" >"${mutated}"
  if ! provider_output="$(run_validator "${mutated}" 2>&1)"; then
    echo "FAIL ${name}: expected success" >&2
    echo "${provider_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_pass "real-provider-contracts" "${fixture}"
expect_mutation_pass \
  "explanations-are-non-normative" \
  '.identityExplanation = "A reader-facing identity summary." |
   .unsupportedExplanation = "A reader-facing unsupported summary." |
   .contracts[0].cacheExplanation = "A reader-facing cache summary." |
   .contracts[0].input.required[0].explanation =
     "A reader-facing description of the required input." |
   .contracts[0].providerExampleExplanations =
     ["A reader-facing provider example."]'
expect_failure \
  "transport-is-target" \
  '.transportIsNotTarget = false' \
  'transportIsNotTarget must equal true'
expect_failure \
  "transport-changes-identity" \
  '.identityContract.transportChangesPortableIdentity = true' \
  'identityContract must equal the closed provider identity contract'
expect_failure \
  "implicit-provider-rebuild" \
  '.unsupportedContract.implicitRebuild = "allowed"' \
  'unsupportedContract must equal the closed provider unsupported contract'
expect_failure \
  "missing-introduced-invariants" \
  '.introducedInvariants = []' \
  'introducedInvariants must be non-empty'
expect_failure \
  "duplicate-contract" \
  '.contracts += [.contracts[0]]' \
  'duplicate contract id: prebuilt-member-transfer'
expect_failure \
  "missing-required-contract" \
  '.contracts |= map(select(.id != "oci-descriptor-transfer"))' \
  'missing required provider contract: oci-descriptor-transfer'
expect_failure \
  "unknown-class" \
  '.contracts[0].conformanceClass = "opaque-provider"' \
  'unknown conformance class: opaque-provider'
expect_failure \
  "late-admission" \
  '.contracts[0].admission.firstSoundPhase = "H0" |
   .contracts[0].admission.deadline = "O0"' \
  'admission firstSoundPhase occurs after deadline'
expect_failure \
  "authority-outside-admission-window" \
  '.contracts[0].admission.deadline = "O0" |
   .contracts[0].admission.authority.phase = "H0"' \
  'admission authority phase must fall between firstSoundPhase and deadline'
expect_failure \
  "missing-admission-authority" \
  '.contracts[0].admission.authority.component = ""' \
  'admission authority component must be non-empty'
expect_failure \
  "wrong-contract-authority" \
  '.contracts[0].admission.authority.component = "artifact-author"' \
  'admission window and authority must equal the contract-specific contract'
expect_failure \
  "missing-verification" \
  '.contracts[0].identityVerification = []' \
  'identityVerification must be a non-empty structured obligation array'
expect_failure \
  "missing-contract-invariants" \
  '.contracts[0].invariants = []' \
  'invariants must be non-empty'
expect_failure \
  "missing-cache-semantics" \
  '.contracts[0].cacheExplanation = " "' \
  'cacheExplanation must be non-empty'
expect_failure \
  "mutated-provider-safety-policy" \
  '.contracts[0].safetyPolicy.cache.trust = "trusted"' \
  'safetyPolicy must equal the closed fail-closed provider policy'
expect_failure \
  "best-effort-provider-verification" \
  '.contracts[0].identityVerification = ["best effort"]' \
  'contains fail-open, default-inheriting, warning-only, or best-effort semantics'
expect_failure \
  "prose-cannot-replace-provider-verification" \
  '.contracts[0].identityVerification = [
     "If verification fails, proceed with a provider-selected substitute."
   ]' \
  'identityVerification must be a non-empty structured obligation array'
expect_failure \
  "mutated-provider-verification-id" \
  '.contracts[0].identityVerification[0].id = "another-obligation"' \
  'identityVerification IDs must equal the contract-specific obligation set'
expect_failure \
  "provider-verification-at-wrong-phase" \
  '.contracts[2].identityVerification[0].phase = "N0"' \
  'identityVerification obligation must use its contract-specific phase'
expect_failure \
  "provider-default-cache-trust" \
  '.contracts[0].safetyPolicy.cache.trust = "provider-default"' \
  'safetyPolicy must equal the closed fail-closed provider policy'
expect_failure \
  "warning-only-provider-unsupported" \
  '.contracts[0].unsupportedWhen = ["warn and continue"]' \
  'contains fail-open, default-inheriting, warning-only, or best-effort semantics'
expect_failure \
  "missing-secret-boundary" \
  '.contracts[0].secretExplanation = ""' \
  'secretExplanation must be non-empty'
expect_failure \
  "missing-runtime-evidence" \
  '.contracts[0].runtimeEvidence = []' \
  'runtimeEvidence must be a non-empty closed structured obligation array'
expect_failure \
  "missing-unsupported" \
  '.contracts[0].unsupportedWhen = []' \
  'unsupportedWhen must be a non-empty closed structured obligation array'
expect_failure \
  "missing-retention" \
  '.contracts[0].retentionExplanation = ""' \
  'retentionExplanation must be non-empty'
expect_failure \
  "placeholder" \
  '.contracts[0].cacheExplanation = "TBD"' \
  'contains placeholder content'
expect_failure \
  "unknown-registry-key" \
  '.implicitProviderFallback = true' \
  'unknown provider-contract registry key: implicitProviderFallback'
expect_failure \
  "mutated-provider-text-authority" \
  '.textAuthority = "Prose may override structured policy."' \
  'textAuthority must lock structured controls and mark explanations non-normative'
expect_failure \
  "unknown-contract-key" \
  '.contracts[0].warningOnly = true' \
  'unknown contract key: warningOnly'
expect_failure \
  "unknown-admission-key" \
  '.contracts[0].admission.bestEffort = true' \
  'unknown admission key: bestEffort'
expect_failure \
  "unknown-admission-authority-key" \
  '.contracts[0].admission.authority.warningOnly = true' \
  'unknown admission authority key: warningOnly'
expect_failure \
  "late-provider-side-construction" \
  '.contracts[2].admission.firstSoundPhase = "O0" |
   .contracts[2].admission.deadline = "H0" |
   .contracts[2].admission.authority.phase = "H0"' \
  'admission window and authority must equal the contract-specific contract'
expect_failure \
  "provider-obligation-contract-rewrite" \
  '.contracts[0].input.required = [{
     "id": "provider-chosen-input",
     "explanation": "provider chooses its own required input"
   }] |
   .contracts[0].input.forbidden = [{
     "id": "provider-chosen-prohibition",
     "explanation": "provider chooses its own prohibition"
   }] |
   .contracts[0].admission.requirements = [{
     "id": "provider-chosen-admission",
     "explanation": "provider chooses its own admission rule"
   }] |
   .contracts[0].runtimeEvidence = [{
     "id": "provider-chosen-evidence",
     "explanation": "provider chooses its own evidence"
   }] |
   .contracts[0].unsupportedWhen = [{
     "id": "provider-chosen-unsupported-case",
     "explanation": "provider chooses its own unsupported behavior"
   }]' \
  'input.required IDs must equal the contract-specific obligation set'

echo "provider contract validator: ${pass_count} cases passed"
