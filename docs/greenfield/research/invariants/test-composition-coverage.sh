#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
validator="${script_dir}/validate-composition-coverage.jq"
paths_fixture="${script_dir}/PACKET-D-COMPOSITION-PATHS.json"
coverage_fixture="${script_dir}/PACKET-D-COMPOSITION-COVERAGE.json"
case_contracts_fixture="${script_dir}/PACKET-D-CASE-CONTRACTS.json"
registry_fixture="${script_dir}/invariants.json"
target_realization_fixture="${script_dir}/PACKET-C-TARGET-REALIZATION.json"
invalid_witnesses_fixture="${script_dir}/fixtures/composition-invalid-witnesses.json"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT
pass_count=0

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

paths_fixture_sha256="$(sha256_file "${paths_fixture}")"
case_contracts_fixture_sha256="$(sha256_file "${case_contracts_fixture}")"
registry_fixture_sha256="$(sha256_file "${registry_fixture}")"

run_validator() {
  local coverage="$1"
  local paths="${2:-${paths_fixture}}"
  local contracts="${3:-${case_contracts_fixture}}"
  local registry="${4:-${registry_fixture}}"
  local scope="${5:-full}"
  local paths_sha256="${6:-$(sha256_file "${paths}")}"
  local contracts_sha256="${7:-$(sha256_file "${contracts}")}"
  local registry_sha256="${8:-$(sha256_file "${registry}")}"

  jq -e \
    --arg validationScope "${scope}" \
    --arg pathsRegistrySha256 "${paths_sha256}" \
    --arg caseContractsSha256 "${contracts_sha256}" \
    --arg invariantRegistrySha256 "${registry_sha256}" \
    --slurpfile paths "${paths}" \
    --slurpfile caseContracts "${contracts}" \
    --slurpfile registry "${registry}" \
    --slurpfile targetRealization "${target_realization_fixture}" \
    -f "${validator}" \
    "${coverage}" >/dev/null
}

expect_catalog_failure() {
  local name="$1"
  local mutation="$2"
  local expected="$3"
  local mutated="${tmp_dir}/${name}-contracts.json"
  local validator_output

  jq "${mutation}" "${case_contracts_fixture}" >"${mutated}"
  if validator_output="$(
    run_validator \
      "${coverage_fixture}" \
      "${paths_fixture}" \
      "${mutated}" \
      "${registry_fixture}" \
      catalog \
      "${paths_fixture_sha256}" \
      "${case_contracts_fixture_sha256}" 2>&1
  )"; then
    echo "FAIL ${name}: expected semantic catalog failure" >&2
    exit 1
  fi
  if [[ "${validator_output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${validator_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_coverage_failure() {
  local name="$1"
  local mutation="$2"
  local expected="$3"
  local mutated="${tmp_dir}/${name}-coverage.json"
  local validator_output

  jq "${mutation}" "${coverage_fixture}" >"${mutated}"
  if validator_output="$(run_validator "${mutated}" 2>&1)"; then
    echo "FAIL ${name}: expected generated coverage failure" >&2
    exit 1
  fi
  if [[ "${validator_output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${validator_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_coordinated_regeneration_failure() {
  local name="$1"
  local paths_mutation="$2"
  local contracts_mutation="$3"
  local expected="$4"
  local scenario_dir="${tmp_dir}/${name}"
  local validator_output

  mkdir -p "${scenario_dir}"
  cp "${script_dir}/generate-composition-coverage.mjs" \
    "${scenario_dir}/generate-composition-coverage.mjs"
  cp "${registry_fixture}" "${scenario_dir}/invariants.json"
  cp "${target_realization_fixture}" \
    "${scenario_dir}/PACKET-C-TARGET-REALIZATION.json"
  jq "${paths_mutation}" "${paths_fixture}" \
    >"${scenario_dir}/PACKET-D-COMPOSITION-PATHS.json"
  jq "${contracts_mutation}" "${case_contracts_fixture}" \
    >"${scenario_dir}/PACKET-D-CASE-CONTRACTS.json"
  node "${scenario_dir}/generate-composition-coverage.mjs"

  if validator_output="$(
    run_validator \
      "${scenario_dir}/PACKET-D-COMPOSITION-COVERAGE.json" \
      "${scenario_dir}/PACKET-D-COMPOSITION-PATHS.json" \
      "${scenario_dir}/PACKET-D-CASE-CONTRACTS.json" \
      "${scenario_dir}/invariants.json" \
      full \
      "${paths_fixture_sha256}" \
      "${case_contracts_fixture_sha256}" \
      "${registry_fixture_sha256}" 2>&1
  )"; then
    echo "FAIL ${name}: coordinated regenerated mutation unexpectedly passed semantic validation" >&2
    exit 1
  fi
  if [[ "${validator_output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${validator_output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

if ! run_validator \
  "${coverage_fixture}" \
  "${paths_fixture}" \
  "${case_contracts_fixture}" \
  "${registry_fixture}" \
  catalog; then
  echo "FAIL direct-candidate-case-catalog: direct catalog validation failed" >&2
  exit 1
fi
pass_count=$((pass_count + 1))

expect_coordinated_regeneration_failure \
  "coordinated-direct-api-owner-crossover" \
  '(.paths[] | select(.id == "direct-api") | .sourceOwner) = "framework" |
   (.paths[] | select(.id == "direct-api") | .reachableOwners) = ["framework"]' \
  '(.entries[] | select(.pathId == "direct-api") | .sourceOwner) = "framework" |
   (.entries[] | select(.pathId == "direct-api") | .reachableOwners) = ["framework"]' \
  'path ownership and contract template must equal the exact validator-owned path contract'

expect_coordinated_regeneration_failure \
  "coordinated-provider-build-retroactive-rejection" \
  '.' \
  '.contractTemplates["provider-build"].rejectedForeignOwnerAt =
     "nix-construction"' \
  'contract templates must equal the exact validator-owned phase, boundary, and rejecting-boundary contracts'

expect_coordinated_regeneration_failure \
  "coordinated-direct-api-typed-request-divergence" \
  '.' \
  '(.reviewedInvariantIds | index("CRT-001")) as $index |
   .classificationVectorsByPath["direct-api"] =
     (.classificationVectorsByPath["direct-api"][0:$index] +
      "F" +
      .classificationVectorsByPath["direct-api"][$index + 1:])' \
  'direct API, framework, and CLI typed-request classifications must remain exact boundary-input peers'

expect_coordinated_regeneration_failure \
  "coordinated-framework-adapter-target-broadening" \
  '(.paths[] | select(.id == "framework-adapter") |
     .targetApplicability) = ["all-packet-c-profiles"]' \
  '.requiredProfileIds as $profiles |
   .targetApplicabilityProjection["framework-adapter"] = $profiles |
   (.entries[] | select(.pathId == "framework-adapter") |
     .targetProfileIds) = $profiles' \
  'path semantics and attached contract template must equal the exact validator-owned path contract'

expect_coordinated_regeneration_failure \
  "coordinated-authoring-identity-authority-minting" \
  '.' \
  '.contractTemplates.authoring.identityAuthority = "mint-everything"' \
  'contract templates must equal the exact validator-owned complete semantic contracts'

expect_coordinated_regeneration_failure \
  "coordinated-framework-ownership-exclusion-removal" \
  '.' \
  '.contractTemplates.framework.ownershipExclusions |= .[0:-1]' \
  'contract templates must equal the exact validator-owned complete semantic contracts'

expect_coordinated_regeneration_failure \
  "coordinated-create-structural-exclusion-drift" \
  '.' \
  '.contractTemplates.create.structuralExclusion += " Altered."' \
  'contract templates must equal the exact validator-owned complete semantic contracts'

expect_coordinated_regeneration_failure \
  "coordinated-manifest-load-full-revalidation-removal" \
  '.' \
  '.contractTemplates["manifest-load"].fullRevalidation = false' \
  'contract templates must equal the exact validator-owned complete semantic contracts'

expect_coordinated_regeneration_failure \
  "coordinated-alias-reassignment" \
  '.registryPathAliases["binding-resolution"] = "framework-adapter"' \
  '.' \
  'registryPathAliases must equal the exact validator-owned 76-alias mapping'

# The eight identity tokens minted in 2026-07-31 name paths that previously no
# invariant could reach. A wrong target for a NEW token would still satisfy the
# 76-entry count, so pin two of them against re-pointing specifically.
expect_coordinated_regeneration_failure \
  "coordinated-new-token-reassignment-create-native-extension" \
  '.registryPathAliases["create-native-extension"] = "direct-api"' \
  '.' \
  'registryPathAliases must equal the exact validator-owned 76-alias mapping'

expect_coordinated_regeneration_failure \
  "coordinated-new-token-reassignment-artifact-semantic-refinement" \
  '.registryPathAliases["artifact-semantic-refinement"] = "artifact-explicit-override"' \
  '.' \
  'registryPathAliases must equal the exact validator-owned 76-alias mapping'

expect_coordinated_regeneration_failure \
  "coordinated-frontend-candidate-reassignment" \
  '(.paths[] | select(.id == "direct-api") |
     .frontendMappings[0].candidate) = "framework-request"' \
  '.' \
  'frontend mappings must equal the exact validator-owned candidate, result, research-pin, and witness projection'

expect_coordinated_regeneration_failure \
  "coordinated-frontend-result-drift" \
  '(.paths[] | select(.id == "direct-api") |
     .frontendMappings[0].result) = "research-control-only"' \
  '.' \
  'frontend mappings must equal the exact validator-owned candidate, result, research-pin, and witness projection'

expect_coordinated_regeneration_failure \
  "coordinated-frontend-research-pin-drift" \
  '(.paths[] | select(.id == "direct-api") |
     .frontendMappings[0].researchPin) = "UNPINNED"' \
  '.' \
  'frontend mappings must equal the exact validator-owned candidate, result, research-pin, and witness projection'

expect_coordinated_regeneration_failure \
  "coordinated-frontend-witness-drift" \
  '(.paths[] | select(.id == "direct-api") |
     .frontendMappings[0].witness) = "planned/packet-d/direct-api/other"' \
  '.' \
  'frontend mappings must equal the exact validator-owned candidate, result, research-pin, and witness projection'

expect_coordinated_regeneration_failure \
  "coordinated-frontend-mapping-removal" \
  '(.paths[] | select(.id == "direct-api") |
     .frontendMappings) = []' \
  '.' \
  'frontend mappings must equal the exact validator-owned candidate, result, research-pin, and witness projection'

if ! jq -e '
  def code($path; $id):
    (.reviewedInvariantIds | index($id)) as $index |
    .classificationVectorsByPath[$path][$index:$index + 1];
  code("operator-configuration-authoring"; "XRS-008") == "C" and
  code("operator-configuration-imports"; "XRS-008") == "C" and
  code("managed-service-definition-authoring"; "SVC-002") == "L" and
  code("managed-service-definition-imports"; "SVC-002") == "L"
' "${case_contracts_fixture}" >/dev/null; then
  echo "FAIL corrected-resource-source-cells: Operator XRS-008 must contribute and Definition-source SVC-002 must remain no-authority" >&2
  exit 1
fi
pass_count=$((pass_count + 1))

if ! jq -e '
  .invalidWitnesses | length == 50 and
  all(.[];
    (.id | type == "string" and length > 0) and
    (.invalidState | type == "string" and length > 0) and
    (.nearbyValidWitness | type == "string" and length > 0)
  )
' "${invalid_witnesses_fixture}" >/dev/null; then
  echo "FAIL invalid-witness-catalog: expected exactly 50 closed invalid/nearby-valid records" >&2
  exit 1
fi
pass_count=$((pass_count + 1))

expect_catalog_failure \
  "catalog-reviewed-too-early" \
  '.status = "reviewed"' \
  'case-contract catalog must identify candidate-only Packet D version 1 authority'

expect_catalog_failure \
  "catalog-authority-claims-reviewed" \
  '.authority = "This reviewed catalog is normative."' \
  'case-contract catalog must identify candidate-only Packet D version 1 authority'

expect_catalog_failure \
  "registry-order-diverges" \
  '.reviewedInvariantIds[0:2] |= reverse' \
  'reviewedInvariantIds must equal the exact current registry in order'

# This validator was the only ledger validator carrying no placeholder rule.
# Its five siblings all reject TBD/TODO/FIXME/UNKNOWN content, so the gap was
# invisible to any check comparing the copies that existed.
expect_catalog_failure \
  "catalog-placeholder-content" \
  '. + {"probeNote": "TODO: unfinished"}' \
  'composition case contracts contain placeholder content'

expect_catalog_failure \
  "vector-width-253" \
  '.classificationVectorsByPath["artifact-imports"] |= .[0:253]' \
  'classification vector must classify every reviewed invariant exactly once'

expect_catalog_failure \
  "missing-path-entry" \
  '.entries |= map(select(.pathId != "managed-service-definition-refinement"))' \
  'case-contract path IDs must equal the exact ordered locked 54-path universe'

expect_catalog_failure \
  "path-entry-order-diverges" \
  '.entries[0:2] |= reverse' \
  'case-contract path IDs must equal the exact ordered locked 54-path universe'

expect_catalog_failure \
  "native-guest-profile-broadened" \
  '.targetApplicabilityProjection["native-guest-module"] += ["oci-linux-v1"]' \
  'target applicability must project semantically to the exact per-path Packet C profile IDs'

expect_catalog_failure \
  "portable-path-gains-profile" \
  '(.entries[] | select(.pathId == "artifact-ordinary-authoring") |
    .targetProfileIds) = ["bubblewrap-linux-v1"]' \
  'target applicability must project semantically to the exact per-path Packet C profile IDs'

expect_catalog_failure \
  "all-profiles-path-omits-profile" \
  '.targetApplicabilityProjection["target-native-extension"] |= .[1:]' \
  'target applicability must project semantically to the exact per-path Packet C profile IDs'

expect_catalog_failure \
  "remote-provider-alone-narrowed" \
  '.targetApplicabilityProjection["provider-native-adapter"] = ["oci-linux-v1"]' \
  'target applicability must project semantically to the exact per-path Packet C profile IDs'

expect_catalog_failure \
  "oci-provider-marker-broadens-explicit-profile" \
  '(.entries[] | select(.pathId == "oci-descriptor-transfer") | .targetProfileIds) =
     .requiredProfileIds' \
  'target applicability must project semantically to the exact per-path Packet C profile IDs'

expect_catalog_failure \
  "built-load-replay-omitted" \
  '.serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds |= .[1:]' \
  'serialized resolved reentry must preserve the exact independent 89 built/load and 30 resolved-stage replay sets'

expect_catalog_failure \
  "resolved-stage-replay-reordered" \
  '.serializedResolvedReentryReplaySets.resolvedStageInvariantIds[0:2] |= reverse' \
  'serialized resolved reentry must preserve the exact independent 89 built/load and 30 resolved-stage replay sets'

expect_catalog_failure \
  "serialized-vector-omits-replay-cell" \
  '(.reviewedInvariantIds | index("STR-001")) as $index |
   .classificationVectorsByPath["serialized-resolved-reentry"] =
     (.classificationVectorsByPath["serialized-resolved-reentry"][0:$index] +
      "L" +
      .classificationVectorsByPath["serialized-resolved-reentry"][$index + 1:])' \
  'serialized resolved reentry boundary-input vector must equal the exact unique 89 + 30 + 3 replay set'

expect_catalog_failure \
  "serialized-vector-adds-unrelated-cell" \
  '(.reviewedInvariantIds | index("DRV-004")) as $index |
   .classificationVectorsByPath["serialized-resolved-reentry"] =
     (.classificationVectorsByPath["serialized-resolved-reentry"][0:$index] +
      "B" +
      .classificationVectorsByPath["serialized-resolved-reentry"][$index + 1:])' \
  'serialized resolved reentry boundary-input vector must equal the exact unique 89 + 30 + 3 replay set'

expect_catalog_failure \
  "driver-trust-private-chain-changed" \
  '.driverTrustStateContracts["resolved-driver-handoff"].phaseSequence =
     ["C0","H0","D0"]' \
  'driverTrustStateContracts must equal the five exact private, replayed, generated, and forbidden trust states'

expect_catalog_failure \
  "operator-source-traverses-artifact" \
  '.contractTemplates["operator-source"].boundaryChain |=
     .[0:1] + [{"id":"artifact-final-validation","phase":"A1","component":"artifact-final-validator"}] + .[1:]' \
  'Operator and Managed-Service source templates must begin at P1 source semantics, end at their exact validator, and never traverse Artifact phases'

expect_catalog_failure \
  "operator-source-hollows-dependency-closure" \
  '.contractTemplates["operator-source"].boundaryChain[1] = {
     "id":"irrelevant-optional-step",
     "phase":"OC0",
     "component":"noop"
   }' \
  'source templates must equal the complete approved ordered boundary-step tuples'

expect_catalog_failure \
  "operator-source-identity-mutated" \
  '.contractTemplates["operator-source"].identityAuthority =
     "mint-operator-identity"' \
  'source templates must equal the complete approved structured contracts'

expect_catalog_failure \
  "operator-source-rejected-boundary-mutated" \
  '.contractTemplates["operator-source"].rejectedForeignOwnerAt =
     "operator-dependency-closure"' \
  'source templates must equal the complete approved structured contracts'

expect_catalog_failure \
  "managed-service-source-authority-changed" \
  '.contractTemplates["managed-service-source"].authority.component =
     "managed-service-compiler"' \
  'Operator and Managed-Service source templates must begin at P1 source semantics, end at their exact validator, and never traverse Artifact phases'

expect_catalog_failure \
  "managed-service-source-first-sound-mutated" \
  '.contractTemplates["managed-service-source"].firstSoundPhase = "MS0"' \
  'source templates must equal the complete approved structured contracts'

expect_catalog_failure \
  "managed-service-source-exclusion-mutated" \
  '.contractTemplates["managed-service-source"].structuralExclusion =
     "Service source may author runtime facts."' \
  'source templates must equal the complete approved structured contracts'

expect_catalog_failure \
  "managed-service-source-hollows-dependency-closure" \
  '.contractTemplates["managed-service-source"].boundaryChain[1] = {
     "id":"irrelevant-optional-step",
     "phase":"MS0",
     "component":"noop"
   }' \
  'source templates must equal the complete approved ordered boundary-step tuples'

expect_catalog_failure \
  "resolved-handoff-skips-o0" \
  '.contractTemplates["resolved-driver-handoff"].boundaryChain |=
     map(select(.phase != "O0"))' \
  'driver templates must equal the exact private handoff, full replay, total generator, and rejection-only chains'

expect_catalog_failure \
  "resolved-handoff-hollows-private-constructor" \
  '.contractTemplates["resolved-driver-handoff"].boundaryChain[0].component =
     "untrusted-deserializer"' \
  'driver templates must equal the complete approved ordered boundary-step tuples'

expect_catalog_failure \
  "resolved-handoff-authority-mutated" \
  '.contractTemplates["resolved-driver-handoff"].authority = {
     "phase":"C0",
     "component":"creation-resolver"
   }' \
  'driver templates must equal the complete approved structured contracts'

expect_catalog_failure \
  "resolved-handoff-deadline-mutated" \
  '.contractTemplates["resolved-driver-handoff"].rejectionDeadline = "H0"' \
  'driver templates must equal the complete approved structured contracts'

expect_catalog_failure \
  "serialized-reentry-not-full" \
  '.contractTemplates["serialized-resolved-reentry"].fullRevalidation = false' \
  'driver templates must equal the exact private handoff, full replay, total generator, and rejection-only chains'

expect_catalog_failure \
  "serialized-reentry-skips-rw0" \
  '.contractTemplates["serialized-resolved-reentry"].boundaryChain |= .[1:]' \
  'driver templates must equal the exact private handoff, full replay, total generator, and rejection-only chains'

expect_catalog_failure \
  "serialized-reentry-hollows-private-constructor" \
  '.contractTemplates["serialized-resolved-reentry"].boundaryChain[1] = {
     "id":"copy-foreign-record",
     "phase":"C0",
     "component":"untrusted-deserializer"
   }' \
  'driver templates must equal the complete approved ordered boundary-step tuples'

expect_catalog_failure \
  "serialized-reentry-ownership-exclusions-mutated" \
  '.contractTemplates["serialized-resolved-reentry"].ownershipExclusions |=
     .[1:]' \
  'driver templates must equal the complete approved structured contracts'

expect_catalog_failure \
  "generated-config-skips-total-generator" \
  '.contractTemplates["generated-runtime-configuration"].boundaryChain |= .[1:]' \
  'driver templates must equal the exact private handoff, full replay, total generator, and rejection-only chains'

expect_catalog_failure \
  "generated-config-hollows-validation" \
  '.contractTemplates["generated-runtime-configuration"].boundaryChain[1].id =
     "optional-validation" |
   .contractTemplates["generated-runtime-configuration"].rejectedForeignOwnerAt =
     "optional-validation"' \
  'driver templates must equal the complete approved ordered boundary-step tuples'

expect_catalog_failure \
  "direct-driver-admits-value" \
  '.driverTrustStateContracts["direct-driver-invocation"].admittedValue =
     "PreparedLaunch"' \
  'driverTrustStateContracts must equal the five exact private, replayed, generated, and forbidden trust states'

expect_catalog_failure \
  "direct-driver-hollows-rejection-step" \
  '.contractTemplates["direct-driver-invocation"].boundaryChain[0].id =
     "optional-driver-check" |
   .contractTemplates["direct-driver-invocation"].rejectedForeignOwnerAt =
     "optional-driver-check"' \
  'driver templates must equal the complete approved ordered boundary-step tuples'

expect_catalog_failure \
  "raw-runtime-rejection-gains-prestage" \
  '.contractTemplates["raw-runtime-config-input"].boundaryChain |=
     [{"id":"raw-decode","phase":"H0","component":"raw-runtime-decoder"}] + .' \
  'driver templates must equal the exact private handoff, full replay, total generator, and rejection-only chains'

expect_catalog_failure \
  "raw-runtime-hollows-rejection-step" \
  '.contractTemplates["raw-runtime-config-input"].boundaryChain[0].id =
     "optional-runtime-check" |
   .contractTemplates["raw-runtime-config-input"].rejectedForeignOwnerAt =
     "optional-runtime-check"' \
  'driver templates must equal the complete approved ordered boundary-step tuples'

expect_catalog_failure \
  "forbidden-driver-gains-authority" \
  '(.reviewedInvariantIds | index("DRV-004")) as $index |
   .classificationVectorsByPath["direct-driver-invocation"] =
     (.classificationVectorsByPath["direct-driver-invocation"][0:$index] +
      "C" +
      .classificationVectorsByPath["direct-driver-invocation"][$index + 1:])' \
  'classification effects must be allowed by the path and active effects require a reachable invariant owner'

expect_catalog_failure \
  "raw-runtime-input-gains-boundary-authority" \
  '(.reviewedInvariantIds | index("DRV-004")) as $index |
   .classificationVectorsByPath["raw-runtime-config-input"] =
     (.classificationVectorsByPath["raw-runtime-config-input"][0:$index] +
      "B" +
      .classificationVectorsByPath["raw-runtime-config-input"][$index + 1:])' \
  'classification effects must be allowed by the path and active effects require a reachable invariant owner'

expect_catalog_failure \
  "operator-source-gains-artifact-authority" \
  '(.reviewedInvariantIds | index("STR-001")) as $index |
   .classificationVectorsByPath["operator-configuration-authoring"] =
     (.classificationVectorsByPath["operator-configuration-authoring"][0:$index] +
      "C" +
      .classificationVectorsByPath["operator-configuration-authoring"][$index + 1:])' \
  'classification effects must be allowed by the path and active effects require a reachable invariant owner'

expect_catalog_failure \
  "operator-refinement-activates-host-state" \
  '(.reviewedInvariantIds | index("HOST-001")) as $index |
   .classificationVectorsByPath["operator-configuration-refinement"] =
     (.classificationVectorsByPath["operator-configuration-refinement"][0:$index] +
      "N" +
      .classificationVectorsByPath["operator-configuration-refinement"][$index + 1:])' \
  'resource source classifications must apply ownership before exact mechanism refinement'

expect_catalog_failure \
  "operator-authoring-underclassifies-xrs-008" \
  '(.reviewedInvariantIds | index("XRS-008")) as $index |
   .classificationVectorsByPath["operator-configuration-authoring"] =
     (.classificationVectorsByPath["operator-configuration-authoring"][0:$index] +
      "L" +
      .classificationVectorsByPath["operator-configuration-authoring"][$index + 1:])' \
  'resource source classifications must apply ownership before exact mechanism refinement'

expect_catalog_failure \
  "operator-imports-underclassifies-xrs-008" \
  '(.reviewedInvariantIds | index("XRS-008")) as $index |
   .classificationVectorsByPath["operator-configuration-imports"] =
     (.classificationVectorsByPath["operator-configuration-imports"][0:$index] +
      "L" +
      .classificationVectorsByPath["operator-configuration-imports"][$index + 1:])' \
  'resource source classifications must apply ownership before exact mechanism refinement'

expect_catalog_failure \
  "operator-authoring-overclassifies-host-state" \
  '(.reviewedInvariantIds | index("HOST-001")) as $index |
   .classificationVectorsByPath["operator-configuration-authoring"] =
     (.classificationVectorsByPath["operator-configuration-authoring"][0:$index] +
      "C" +
      .classificationVectorsByPath["operator-configuration-authoring"][$index + 1:])' \
  'resource source classifications must apply ownership before exact mechanism refinement'

expect_catalog_failure \
  "service-authoring-overclassifies-svc-002" \
  '(.reviewedInvariantIds | index("SVC-002")) as $index |
   .classificationVectorsByPath["managed-service-definition-authoring"] =
     (.classificationVectorsByPath["managed-service-definition-authoring"][0:$index] +
      "C" +
      .classificationVectorsByPath["managed-service-definition-authoring"][$index + 1:])' \
  'resource source classifications must apply ownership before exact mechanism refinement'

expect_catalog_failure \
  "service-imports-overclassifies-svc-002" \
  '(.reviewedInvariantIds | index("SVC-002")) as $index |
   .classificationVectorsByPath["managed-service-definition-imports"] =
     (.classificationVectorsByPath["managed-service-definition-imports"][0:$index] +
      "C" +
      .classificationVectorsByPath["managed-service-definition-imports"][$index + 1:])' \
  'resource source classifications must apply ownership before exact mechanism refinement'

expect_catalog_failure \
  "service-native-escape-gains-authority" \
  '(.reviewedInvariantIds | index("SVC-005")) as $index |
   .classificationVectorsByPath["managed-service-definition-native-escape"] =
     (.classificationVectorsByPath["managed-service-definition-native-escape"][0:$index] +
      "C" +
      .classificationVectorsByPath["managed-service-definition-native-escape"][$index + 1:])' \
  'resource source classifications must apply ownership before exact mechanism refinement'

expect_catalog_failure \
  "artifact-authoring-claims-framework-fact" \
  '(.reviewedInvariantIds | index("XRS-007")) as $index |
   .classificationVectorsByPath["artifact-ordinary-authoring"] =
     (.classificationVectorsByPath["artifact-ordinary-authoring"][0:$index] +
      "C" +
      .classificationVectorsByPath["artifact-ordinary-authoring"][$index + 1:])' \
  'artifact ordinary authoring must forbid XRS-007 and XRS-008 foreign-owner authority'

expect_catalog_failure \
  "cli-framework-typed-request-diverges" \
  '(.reviewedInvariantIds | index("CRT-001")) as $index |
   .classificationVectorsByPath["cli-adapter"] =
     (.classificationVectorsByPath["cli-adapter"][0:$index] +
      "F" +
      .classificationVectorsByPath["cli-adapter"][$index + 1:])' \
  'direct API, framework, and CLI typed-request classifications must remain exact boundary-input peers'

expect_catalog_failure \
  "conditional-native-tuple-incomplete" \
  'del(.conditionalNativeHandleContract.contract.registryDigest)' \
  'native handle contracts must preserve the canonical tuple and exact active-or-boundary conditional rule'

expect_catalog_failure \
  "native-target-loses-total-effect" \
  '(.entries[] | select(.pathId == "target-native-extension") |
    .evidenceObligationIds) |=
      map(select(. != "total-native-effect-projection"))' \
  'native guest and target contracts must carry canonical identity and total-effect obligations'

expect_catalog_failure \
  "delegated-taxonomy-relabel" \
  '.delegatedConcernTaxonomy.E[0] = "transition-ish"' \
  'delegatedConcernTaxonomy must equal the exact Packet E/F concern expansion'

expect_catalog_failure \
  "delegated-expansion-omitted" \
  '(.entries[] | select(.pathId == "resolved-driver-handoff") |
    .delegatedConcerns) |= .[1:]' \
  'delegatedPackets must expand to the exact ordered delegated concern taxonomy'

expect_catalog_failure \
  "cross-path-handoff-boundary-changed" \
  '.crossPathHandoffs[0].resumeBoundary.phase = "N1"' \
  'crossPathHandoffs must equal the six exact source/target path and boundary contracts'

if ! jq -e \
  --slurpfile contracts "${case_contracts_fixture}" \
  '
    .status == "candidate" and
    .delegatedConcernTaxonomy == $contracts[0].delegatedConcernTaxonomy and
    .resolvedReentryReplay ==
      $contracts[0].serializedResolvedReentryReplaySets and
    .crossPathHandoffs == $contracts[0].crossPathHandoffs and
    .targetApplicabilityProjection ==
      $contracts[0].targetApplicabilityProjection
  ' \
  "${coverage_fixture}" >/dev/null; then
  echo "focused composition catalog validator: ${pass_count} cases passed" >&2
  echo "FAIL task-4-generated-top-level-contracts: candidate coverage must copy the exact reviewed taxonomy, replay, handoff, and applicability contracts" >&2
  exit 1
fi
pass_count=$((pass_count + 1))

coverage_invariants="$(jq '.invariantIds | length' "${coverage_fixture}")"
coverage_paths="$(jq '.pathIds | length' "${coverage_fixture}")"
coverage_cells="$(jq '.expectedCellCount' "${coverage_fixture}")"

if [[ "${coverage_invariants}" != "254" ||
      "${coverage_paths}" != "54" ||
      "${coverage_cells}" != "13716" ]]; then
  echo "focused composition catalog validator: ${pass_count} cases passed" >&2
  echo "FAIL task-4-generated-matrix-boundary: PACKET-D-COMPOSITION-COVERAGE.json remains ${coverage_paths} paths × ${coverage_invariants} invariants = ${coverage_cells} cells; expected 54 × 254 = 13716" >&2
  exit 1
fi

if ! run_validator "${coverage_fixture}"; then
  echo "FAIL generated-composition-coverage: current 54 × 254 matrix failed full validation" >&2
  exit 1
fi
pass_count=$((pass_count + 1))

expect_coverage_failure \
  "coverage-claims-reviewed" \
  '.status = "reviewed"' \
  'composition coverage header must identify candidate-only Packet D version 1'

expect_coverage_failure \
  "coverage-registry-order-diverges" \
  '.invariantIds[0:2] |= reverse' \
  'coverage invariant IDs must equal the exact 254-ID registry order'

expect_coverage_failure \
  "coverage-delegated-taxonomy-diverges" \
  '.delegatedConcernTaxonomy.E[0] = "transition-ish"' \
  'coverage delegatedConcernTaxonomy must exactly copy the reviewed candidate catalog'

expect_coverage_failure \
  "coverage-replay-diverges" \
  '.resolvedReentryReplay.builtMemberLoadInvariantIds |= .[1:]' \
  'coverage resolvedReentryReplay must exactly copy the reviewed candidate catalog'

expect_coverage_failure \
  "coverage-handoff-diverges" \
  '.crossPathHandoffs[0].resumeBoundary.phase = "N1"' \
  'coverage crossPathHandoffs must exactly copy the reviewed candidate catalog'

expect_coverage_failure \
  "coverage-applicability-diverges" \
  '.targetApplicabilityProjection["native-guest-module"] += ["oci-linux-v1"]' \
  'coverage targetApplicabilityProjection must exactly copy the reviewed candidate catalog'

expect_coverage_failure \
  "conditional-native-condition-removed" \
  '(.rules[] |
    select(
      (.selector.invariantIds | index("NAT-002")) != null and
      .valueCases[0].condition.kind == "when-native-handle-present"
    ) |
    .valueCases[0].condition) = {"kind":"all-values"}' \
  'active or boundary NAT-002/NAT-003 requires the exact conditional native-handle condition'

expect_coverage_failure \
  "conditional-native-tuple-removed" \
  '(.rules[] |
    select(
      (.selector.invariantIds | index("NAT-002")) != null and
      .valueCases[0].condition.kind == "when-native-handle-present"
    ) |
    .valueCases[0].nativeHandleContract) = null' \
  'structured controls must equal the independently pinned invariant/path contract'

expect_coverage_failure \
  "native-path-unconditional-tuple-removed" \
  '(.rules[] |
    select(
      .selector.pathIds == ["typed-nix-handle"] and
      (.selector.invariantIds | index("NAT-002")) == null
    ) |
    .valueCases[0].nativeHandleContract) = null' \
  'native Nix value must require the complete pinned transitive source-closure digest'

expect_coverage_failure \
  "classification-code-only-grouping" \
  '(.rules[] |
    select(.id == "DCR_ARTIFACT_ORDINARY_AUTHORING_001") |
    .selector.invariantIds) += ["STR-004"]' \
  'structured controls must equal the independently pinned invariant/path contract'

expect_coverage_failure \
  "lexical-instead-of-reachable-chain" \
  '(.rules[] |
    select(.id == "DCR_ARTIFACT_ORDINARY_AUTHORING_001") |
    .valueCases[0].boundaryChain[1].phase) = "RW0"' \
  'boundaryChain must be ordered by authoritative graph reachability'

expect_coverage_failure \
  "uncovered-cell" \
  '.rules[0].selector.invariantIds |= .[1:]' \
  'uncovered composition cell'

expect_coverage_failure \
  "overlapping-selector" \
  '.rules[1].selector.invariantIds += [.rules[0].selector.invariantIds[0]]' \
  'overlapping composition cell'

expect_coverage_failure \
  "unknown-effect" \
  '.rules[0].valueCases[0].allowedEffect = "may-widen"' \
  'unknown allowedEffect: may-widen'

expect_coverage_failure \
  "unknown-case-key" \
  '.rules[0].valueCases[0].bestEffort = true' \
  'unknown composition case key: bestEffort'

echo "composition coverage validator: ${pass_count} cases passed"
