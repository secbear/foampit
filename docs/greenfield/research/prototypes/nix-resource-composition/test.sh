#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

expected_nixpkgs_rev="62c8382960464ceb98ea593cb8321a2cf8f9e3e5"
expected_nixpkgs_nar_hash="sha256-kKB3bqYJU5nzYeIROI82Ef9VtTbu4uA3YydSk/Bioa8="
expected_case_count=14
expected_internal_assertion_count=172
passes=0
failures=0
internal_assertions=0

record_failure() {
  local case_name="$1"
  local reason="$2"
  failures=$((failures + 1))
  printf 'not ok - %s: %s\n' "$case_name" "$reason"
}

eval_attribute() {
  local mode="$1"
  local attribute="$2"
  local stdout_file="$3"
  local stderr_file="$4"
  local -a mode_args=()

  case "$mode" in
    cold)
      mode_args=(--option eval-cache false)
      ;;
    warm)
      mode_args=()
      ;;
    offline)
      mode_args=(--offline --option eval-cache false)
      ;;
    *)
      printf 'unknown evaluation mode: %s\n' "$mode" >&2
      return 2
      ;;
  esac

  nix eval \
    --pure-eval \
    --json \
    --no-write-lock-file \
    "${mode_args[@]}" \
    "path:$prototype_root#$attribute" \
    >"$stdout_file" 2>"$stderr_file"
}

assert_valid_composition() {
  local case_name="$1"
  local case_id="$2"
  local jq_expression="$3"
  local mode order attribute stdout_file stderr_file

  for mode in cold warm offline; do
    for order in forward reverse; do
      attribute="cases.${case_id}.valid${order^}"
      stdout_file="$tmp_root/${case_id}.${mode}.${order}.stdout"
      stderr_file="$tmp_root/${case_id}.${mode}.${order}.stderr"

      if ! eval_attribute "$mode" "$attribute" "$stdout_file" "$stderr_file"; then
        record_failure "$case_name" \
          "$mode/$order valid evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
        return 1
      fi

      if ! jq -e \
        "($jq_expression)
         and (.validationMetadata.contributionManifest | length >= 2)
         and ([.validationMetadata.contributionManifest[].moduleIdentity.id] | unique | length >= 2)
         and ([.validationMetadata.contributionManifest[].definitionIndex]
           == ([.validationMetadata.contributionManifest[].definitionIndex] | sort))
         and (.validationMetadata.nativeExtensionSummaries | length == 1)
         and (.validationMetadata.nativeExtensionSummaries[0] | keys
           == [\"interfaceVersion\",\"name\",\"sourceIdentity\"])
         and (.validationMetadata.nativeExtensionSummaries[0].sourceIdentity | keys
           == [\"kind\",\"locator\",\"narHash\",\"revision\"])
         and .validationMetadata.nativeExtensionSummaries[0].name == \"firecracker\"
         and .validationMetadata.nativeExtensionSummaries[0].interfaceVersion == 1
         and (.validationMetadata.nativeExtensionSummaries[0].sourceIdentity
           == .validationMetadata.dependencyClosure[0].sourceIdentity)" \
        "$stdout_file" >/dev/null; then
        record_failure "$case_name" \
          "$mode/$order result did not satisfy: $jq_expression"
        return 1
      fi

      internal_assertions=$((internal_assertions + 1))
    done

    if ! cmp -s \
      "$tmp_root/${case_id}.${mode}.forward.stdout" \
      "$tmp_root/${case_id}.${mode}.reverse.stdout"; then
      record_failure "$case_name" "$mode result changed when import order was reversed"
      return 1
    fi
    internal_assertions=$((internal_assertions + 1))
  done
}

assert_success_probe() {
  local case_name="$1"
  local case_id="$2"
  local probe="$3"
  local jq_expression="$4"
  local stdout_file="$tmp_root/${case_id}.${probe}.stdout"
  local stderr_file="$tmp_root/${case_id}.${probe}.stderr"

  if ! eval_attribute offline "cases.${case_id}.${probe}" "$stdout_file" "$stderr_file"; then
    record_failure "$case_name" \
      "$probe evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
    return 1
  fi

  if ! jq -e "$jq_expression" "$stdout_file" >/dev/null; then
    record_failure "$case_name" "$probe did not satisfy: $jq_expression"
    return 1
  fi

  internal_assertions=$((internal_assertions + 1))
}

assert_failure_probe() {
  local case_name="$1"
  local case_id="$2"
  local probe="$3"
  local invariant="$4"
  local stdout_file="$tmp_root/${case_id}.${probe}.stdout"
  local stderr_file="$tmp_root/${case_id}.${probe}.stderr"

  if eval_attribute offline "cases.${case_id}.${probe}" "$stdout_file" "$stderr_file"; then
    record_failure "$case_name" "$probe unexpectedly evaluated successfully"
    return 1
  fi

  if ! grep -F "$invariant" "$stderr_file" >/dev/null; then
    record_failure "$case_name" \
      "$probe did not report $invariant: $(tr '\n' ' ' <"$stderr_file")"
    return 1
  fi

  internal_assertions=$((internal_assertions + 1))
}

assert_secret_safe_failure_probe() {
  local case_name="$1"
  local case_id="$2"
  local probe="$3"
  local invariant="$4"
  local secret_marker="$5"
  local stdout_file="$tmp_root/${case_id}.${probe}.stdout"
  local stderr_file="$tmp_root/${case_id}.${probe}.stderr"

  if eval_attribute offline "cases.${case_id}.${probe}" "$stdout_file" "$stderr_file"; then
    record_failure "$case_name" "$probe unexpectedly evaluated successfully"
    return 1
  fi

  if ! grep -F "$invariant" "$stderr_file" >/dev/null; then
    record_failure "$case_name" \
      "$probe did not report $invariant: $(tr '\n' ' ' <"$stderr_file")"
    return 1
  fi

  if grep -F "$secret_marker" "$stderr_file" >/dev/null; then
    record_failure "$case_name" "$probe rendered secret marker $secret_marker"
    return 1
  fi

  internal_assertions=$((internal_assertions + 1))
}

assert_pin() {
  local case_name="$1"
  local metadata_file="$tmp_root/flake-metadata.json"
  local stderr_file="$tmp_root/flake-metadata.stderr"

  if ! nix flake metadata \
    --json \
    --offline \
    --no-write-lock-file \
    "path:$prototype_root" \
    >"$metadata_file" 2>"$stderr_file"; then
    record_failure "$case_name" "offline flake metadata failed: $(tr '\n' ' ' <"$stderr_file")"
    return 1
  fi

  if ! jq -e \
    --arg rev "$expected_nixpkgs_rev" \
    --arg nar_hash "$expected_nixpkgs_nar_hash" \
    '.locks.nodes.nixpkgs.locked.rev == $rev
     and .locks.nodes.nixpkgs.locked.narHash == $nar_hash' \
    "$metadata_file" >/dev/null; then
    record_failure "$case_name" "nixpkgs dependency is not locked by revision and NAR hash"
    return 1
  fi

  internal_assertions=$((internal_assertions + 1))
}

run_case() {
  local case_name="$1"
  local case_id="$2"
  local jq_expression="$3"
  shift 3

  if ! assert_valid_composition "$case_name" "$case_id" "$jq_expression"; then
    return
  fi

  while (($# > 0)); do
    if ! assert_failure_probe "$case_name" "$case_id" "$1" "$2"; then
      return
    fi
    shift 2
  done

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

if [[ ! -f "$prototype_root/cases.nix" ]]; then
  printf 'resource-composition runner requires missing implementation: %s\n' \
    "$prototype_root/cases.nix" >&2
  exit 1
fi

run_case \
  "operator ordinary authoring" \
  "operatorOrdinaryAuthoring" \
  '.phase == "OC0"
   and (.resource | keys) == ["contributorLedger","credentialReferences","drivers","hardCeilings","placementClasses","providers"]
   and [.resource.drivers[].name] == ["firecracker","bubblewrap"]
   and .resource.credentialReferences[0].reference == "keychain://operator/firecracker"' \
  "credentialValueRejected" "operator.oc0.credential_values_forbidden" \
  "unregisteredSelectionRejected" "operator.oc0.unregistered_selection" \
  "delayedFinalValueRejected" "operator.oc0.final_value_deep_forced"
if ! assert_success_probe \
  "operator ordinary authoring" \
  "operatorOrdinaryAuthoring" \
  "delayedWithoutFinalForce" \
  '.phase == "OC0-candidate"
   and .shallowEvaluationSucceeded
   and (.explicitDeepForceSucceeded | not)'; then
  :
fi

run_case \
  "operator pinned import" \
  "operatorPinnedImport" \
  '.validationMetadata.dependencyClosure[0].sourceIdentity.revision
     == "62c8382960464ceb98ea593cb8321a2cf8f9e3e5"
   and (.validationMetadata.dependencyClosure[0].sourceIdentity.narHash
     == "sha256-kKB3bqYJU5nzYeIROI82Ef9VtTbu4uA3YydSk/Bioa8=")
   and (.validationMetadata.dependencyClosure[0].closurePath | startswith("/nix/store/"))
   and .validationMetadata.offlineReproducible' \
  "incompleteClosureRejected" "operator.oc0.dependency_identity_incomplete" \
  "malformedSriRejected" "operator.oc0.dependency_identity_malformed" \
  "fabricatedIdentityRejected" "operator.oc0.dependency_identity_mismatch"
assert_pin "operator pinned import"

run_case \
  "operator precedence and contributor ledger" \
  "operatorPrecedenceLedger" \
  '.resource.providers[0].region == "us-central-1"
   and [.resource.contributorLedger[]
     | select(.optionPath == "providers") | .outcome] == ["superseded","effective"]
   and [.resource.contributorLedger[]
     | select(.optionPath == "providers") | .priority] == [1000,100]' \
  "incompleteLedgerRejected" "operator.oc0.contributor_ledger_incomplete" \
  "extraLedgerEntryRejected" "operator.oc0.contributor_ledger_incomplete" \
  "duplicateLedgerEntryRejected" "operator.oc0.contributor_ledger_incomplete" \
  "wrongRoleRejected" "operator.oc0.contributor_ledger_incomplete"

run_case \
  "operator semantic narrowing" \
  "operatorSemanticNarrowing" \
  '.resource.hardCeilings.maxMemoryBytes == 4294967296
   and .resource.hardCeilings.maxSandboxes == 8
   and .validationMetadata.productAnchors.maxMemoryBytes == 8589934592
   and .validationMetadata.productAnchors.maxSandboxes == 32' \
  "widenedCeilingRejected" "operator.oc0.hard_ceiling_widening"

run_case \
  "operator mkForce cannot widen hard ceiling" \
  "operatorForceCeiling" \
  '.resource.hardCeilings.maxMemoryBytes == 4294967296' \
  "mkForceRejected" "operator.oc0.hard_ceiling_priority_forbidden" \
  "strongerOverrideRejected" "operator.oc0.hard_ceiling_priority_forbidden" \
  "mkForceIncompleteLedgerRejected" "operator.oc0.contributor_ledger_incomplete"

run_case \
  "operator freeform/native escape rejected at OC0" \
  "operatorNativeEscape" \
  '.phase == "OC0"
   and .validationMetadata.nativeExtensionSummaries[0].name == "firecracker"' \
  "moduleArgsRejectedAtOc0" "operator.oc0.native_escape_forbidden" \
  "freeformRejectedAtOc0" "operator.oc0.native_escape_forbidden" \
  "nativeSummaryMalformedRejected" "operator.oc0.product_native_extension_summary_invalid"
if ! assert_secret_safe_failure_probe \
  "operator freeform/native escape rejected at OC0" \
  "operatorNativeEscape" \
  "unknownOptionStructurallyRejected" \
  "OPS-005" \
  "TASK5_OPERATOR_STRUCTURAL_SECRET_7f3d"; then
  :
fi
if ! assert_secret_safe_failure_probe \
  "operator freeform/native escape rejected at OC0" \
  "operatorNativeEscape" \
  "nativeSummaryUnknownFieldRejected" \
  "operator.oc0.product_native_extension_summary_invalid" \
  "TASK5_OPERATOR_NATIVE_UNKNOWN_SECRET_8a4e"; then
  :
fi
if ! assert_secret_safe_failure_probe \
  "operator freeform/native escape rejected at OC0" \
  "operatorNativeEscape" \
  "nativeSummaryTypeRejected" \
  "operator.oc0.product_native_extension_summary_invalid" \
  "TASK5_OPERATOR_NATIVE_TYPE_SECRET_9b5f"; then
  :
fi

run_case \
  "operator mutable/unpinned dependency rejected" \
  "operatorMutableDependency" \
  '.validationMetadata.offlineReproducible
   and (.resource.contributorLedger[0].dependency.sourceIdentity.narHash
     == "sha256-kKB3bqYJU5nzYeIROI82Ef9VtTbu4uA3YydSk/Bioa8=")' \
  "mutableDependencyRejected" "operator.oc0.dependency_identity_incomplete"

run_case \
  "service ordinary authoring" \
  "serviceOrdinaryAuthoring" \
  '.phase == "MS0"
   and (.resource | keys) == ["artifactReference","contributorLedger","createRequest","desiredLifecycle","serviceMetadata"]
   and .resource.createRequest.operation.kind == "createSandbox"
   and .resource.desiredLifecycle.state == "active"' \
  "driverCallRejected" "service.ms0.driver_call_forbidden" \
  "rawRuntimeArgumentsRejected" "service.ms0.raw_runtime_arguments_forbidden" \
  "artifactPolicyRejected" "service.ms0.artifact_policy_forbidden" \
  "untypedOperationRejected" "service.ms0.typed_core_api_required" \
  "delayedFinalValueRejected" "service.ms0.final_value_deep_forced"
if ! assert_success_probe \
  "service ordinary authoring" \
  "serviceOrdinaryAuthoring" \
  "delayedWithoutFinalForce" \
  '.phase == "MS0-candidate"
   and .shallowEvaluationSucceeded
   and (.explicitDeepForceSucceeded | not)'; then
  :
fi

run_case \
  "service pinned import" \
  "servicePinnedImport" \
  '.validationMetadata.dependencyClosure[0].sourceIdentity.revision
     == "62c8382960464ceb98ea593cb8321a2cf8f9e3e5"
   and (.validationMetadata.dependencyClosure[0].sourceIdentity.narHash
     == "sha256-kKB3bqYJU5nzYeIROI82Ef9VtTbu4uA3YydSk/Bioa8=")
   and (.validationMetadata.dependencyClosure[0].closurePath | startswith("/nix/store/"))
   and .validationMetadata.offlineReproducible' \
  "incompleteClosureRejected" "service.ms0.dependency_identity_incomplete" \
  "malformedSriRejected" "service.ms0.dependency_identity_malformed" \
  "fabricatedIdentityRejected" "service.ms0.dependency_identity_mismatch"

run_case \
  "service precedence and contributor ledger" \
  "servicePrecedenceLedger" \
  '.resource.serviceMetadata.description == "production reconciler"
   and [.resource.contributorLedger[]
     | select(.optionPath == "serviceMetadata.description") | .outcome]
     == ["superseded","effective"]
   and [.resource.contributorLedger[]
     | select(.optionPath == "serviceMetadata.description") | .priority]
     == [1000,100]' \
  "incompleteLedgerRejected" "service.ms0.contributor_ledger_incomplete" \
  "extraLedgerEntryRejected" "service.ms0.contributor_ledger_incomplete" \
  "duplicateLedgerEntryRejected" "service.ms0.contributor_ledger_incomplete" \
  "wrongRoleRejected" "service.ms0.contributor_ledger_incomplete"

run_case \
  "service semantic narrowing" \
  "serviceSemanticNarrowing" \
  '.resource.desiredLifecycle.maxRestarts == 3
   and .resource.desiredLifecycle.reconcileIntervalSeconds == 60'

run_case \
  "service mkForce cannot bypass typed Core API" \
  "serviceForceCoreApi" \
  '.resource.createRequest.operation.kind == "createSandbox"' \
  "mkForceRejected" "service.ms0.operation_priority_forbidden" \
  "strongerOverrideRejected" "service.ms0.operation_priority_forbidden" \
  "mkForceIncompleteLedgerRejected" "service.ms0.contributor_ledger_incomplete"

run_case \
  "service freeform/native escape rejected at MS0" \
  "serviceNativeEscape" \
  '.phase == "MS0"
   and .validationMetadata.nativeExtensionSummaries[0].name == "firecracker"' \
  "moduleArgsRejectedAtMs0" "service.ms0.native_escape_forbidden" \
  "freeformRejectedAtMs0" "service.ms0.native_escape_forbidden" \
  "nativeSummaryMalformedRejected" "service.ms0.product_native_extension_summary_invalid"
if ! assert_secret_safe_failure_probe \
  "service freeform/native escape rejected at MS0" \
  "serviceNativeEscape" \
  "unknownOptionStructurallyRejected" \
  "SVC-005" \
  "TASK5_SERVICE_STRUCTURAL_SECRET_1c6a"; then
  :
fi
if ! assert_secret_safe_failure_probe \
  "service freeform/native escape rejected at MS0" \
  "serviceNativeEscape" \
  "nativeSummaryUnknownFieldRejected" \
  "service.ms0.product_native_extension_summary_invalid" \
  "TASK5_SERVICE_NATIVE_UNKNOWN_SECRET_2d7b"; then
  :
fi
if ! assert_secret_safe_failure_probe \
  "service freeform/native escape rejected at MS0" \
  "serviceNativeEscape" \
  "nativeSummaryTypeRejected" \
  "service.ms0.product_native_extension_summary_invalid" \
  "TASK5_SERVICE_NATIVE_TYPE_SECRET_3e8c"; then
  :
fi

run_case \
  "service mutable/unpinned dependency rejected" \
  "serviceMutableDependency" \
  '.validationMetadata.offlineReproducible
   and (.resource.contributorLedger[0].dependency.sourceIdentity.narHash
     == "sha256-kKB3bqYJU5nzYeIROI82Ef9VtTbu4uA3YydSk/Bioa8=")' \
  "mutableDependencyRejected" "service.ms0.dependency_identity_incomplete"

if ((failures > 0)); then
  printf '%d resource-composition test(s) failed\n' "$failures" >&2
  exit 1
fi

if ((passes != expected_case_count)); then
  printf 'expected %d reported cases, observed %d\n' "$expected_case_count" "$passes" >&2
  exit 1
fi

if ((internal_assertions != expected_internal_assertion_count)); then
  printf 'expected %d internal assertions, observed %d\n' \
    "$expected_internal_assertion_count" "$internal_assertions" >&2
  exit 1
fi

printf 'all nix-resource-composition prototype tests passed (%d cases, %d internal assertions)\n' \
  "$passes" "$internal_assertions"
