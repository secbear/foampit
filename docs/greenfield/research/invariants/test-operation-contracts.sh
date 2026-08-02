#!/usr/bin/env bash
#
# Packet E operation-contract mutation harness.
#
# Uses the REAL production ledgers as fixtures, per Packet C and Packet D convention, so a
# passing run is evidence about the shipped documents rather than about a synthetic minimum.
# Every case mutates one input and asserts the validator rejects it with a specific
# diagnostic -- matching on the message, never merely on a non-zero exit.

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
validator="${script_dir}/validate-operation-contracts.jq"
registry_fixture="${script_dir}/PACKET-E-OPERATION-REGISTRY.json"
catalog_fixture="${script_dir}/PACKET-E-CASE-CONTRACTS.json"
contracts_fixture="${script_dir}/PACKET-E-OPERATION-CONTRACTS.json"
concurrency_fixture="${script_dir}/PACKET-E-CONCURRENCY-MATRIX.json"
invariants_fixture="${script_dir}/invariants.json"
generator="${script_dir}/generate-operation-contracts.mjs"

tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT
pass_count=0

sha256_file() {
  if command -v sha256sum >/dev/null 2>&1; then sha256sum "$1" | awk '{print $1}'
  elif command -v shasum >/dev/null 2>&1; then shasum -a 256 "$1" | awk '{print $1}'
  else echo "A SHA-256 implementation is required." >&2; return 127
  fi
}

registry_sha256="$(sha256_file "${registry_fixture}")"
catalog_sha256="$(sha256_file "${catalog_fixture}")"
invariants_sha256="$(sha256_file "${invariants_fixture}")"

run_validator() {
  local scope="${1}" registry="${2}" catalog="${3}" contracts="${4}" concurrency="${5}"
  local registry_pin="${6:-${registry_sha256}}" catalog_pin="${7:-${catalog_sha256}}"

  jq -e \
    --arg validationScope "${scope}" \
    --arg operationRegistrySha256 "${registry_pin}" \
    --arg caseContractsSha256 "${catalog_pin}" \
    --arg invariantRegistrySha256 "${invariants_sha256}" \
    --slurpfile registry "${registry}" \
    --slurpfile catalog "${catalog}" \
    --slurpfile invariants "${invariants_fixture}" \
    --slurpfile concurrency "${concurrency}" \
    -f "${validator}" \
    "${contracts}" >/dev/null
}

fail() { echo "FAIL $1: $2" >&2; exit 1; }

# expect_failure <name> <target: registry|catalog|contracts|concurrency> <jq mutation> <expected substring>
expect_failure() {
  local name="$1" target="$2" mutation="$3" expected="$4"
  local mutated="${tmp_dir}/${name}.json" output
  local registry="${registry_fixture}" catalog="${catalog_fixture}"
  local contracts="${contracts_fixture}" concurrency="${concurrency_fixture}"
  local registry_pin="${registry_sha256}" catalog_pin="${catalog_sha256}"

  case "${target}" in
    registry)    jq "${mutation}" "${registry_fixture}"    >"${mutated}"; registry="${mutated}";    registry_pin="$(sha256_file "${mutated}")" ;;
    catalog)     jq "${mutation}" "${catalog_fixture}"     >"${mutated}"; catalog="${mutated}";     catalog_pin="$(sha256_file "${mutated}")" ;;
    contracts)   jq "${mutation}" "${contracts_fixture}"   >"${mutated}"; contracts="${mutated}" ;;
    concurrency) jq "${mutation}" "${concurrency_fixture}" >"${mutated}"; concurrency="${mutated}" ;;
    *) fail "${name}" "unknown mutation target ${target}" ;;
  esac

  if output="$(run_validator full "${registry}" "${catalog}" "${contracts}" "${concurrency}" "${registry_pin}" "${catalog_pin}" 2>&1)"; then
    fail "${name}" "expected semantic rejection, got a pass"
  fi
  if [[ "${output}" != *"${expected}"* ]]; then
    fail "${name}" "expected a diagnostic containing '${expected}'"$'\n'"${output}"
  fi
  pass_count=$((pass_count + 1))
}

# A digest mutation must be caught by the pin, not by luck.
expect_pin_failure() {
  local name="$1" pin_kind="$2" output
  local registry_pin="${registry_sha256}" catalog_pin="${catalog_sha256}"
  case "${pin_kind}" in
    registry) registry_pin="0000000000000000000000000000000000000000000000000000000000000000" ;;
    catalog)  catalog_pin="0000000000000000000000000000000000000000000000000000000000000000" ;;
  esac
  if output="$(run_validator full "${registry_fixture}" "${catalog_fixture}" "${contracts_fixture}" "${concurrency_fixture}" "${registry_pin}" "${catalog_pin}" 2>&1)"; then
    fail "${name}" "expected pin rejection"
  fi
  if [[ "${output}" != *"SHA-256 must equal the independently reviewed validator pin"* ]]; then
    fail "${name}" "expected a pin diagnostic"$'\n'"${output}"
  fi
  pass_count=$((pass_count + 1))
}

# Copy the generator and its inputs to a temp tree, mutate, regenerate, and assert the
# SEMANTIC validator still rejects. This is what defeats a tandem rewrite of generator and
# output -- the Packet D pattern.
expect_coordinated_regeneration_failure() {
  local name="$1" catalog_mutation="$2" expected="$3"
  local scenario="${tmp_dir}/${name}" output
  mkdir -p "${scenario}"
  cp "${generator}" "${scenario}/"
  cp "${registry_fixture}" "${scenario}/PACKET-E-OPERATION-REGISTRY.json"
  cp "${invariants_fixture}" "${scenario}/invariants.json"
  cp "${concurrency_fixture}" "${scenario}/PACKET-E-CONCURRENCY-MATRIX.json"
  jq "${catalog_mutation}" "${catalog_fixture}" >"${scenario}/PACKET-E-CASE-CONTRACTS.json"

  # The generator asserts before its single write, so many mutations are refused here.
  # Either outcome is a pass provided the message is the expected one.
  if ! output="$(node "${scenario}/generate-operation-contracts.mjs" 2>&1)"; then
    if [[ "${output}" != *"${expected}"* ]]; then
      fail "${name}" "generator rejected with an unexpected message"$'\n'"${output}"
    fi
    pass_count=$((pass_count + 1))
    return
  fi
  if output="$(run_validator full \
      "${scenario}/PACKET-E-OPERATION-REGISTRY.json" \
      "${scenario}/PACKET-E-CASE-CONTRACTS.json" \
      "${scenario}/PACKET-E-OPERATION-CONTRACTS.json" \
      "${scenario}/PACKET-E-CONCURRENCY-MATRIX.json" \
      "${registry_sha256}" "$(sha256_file "${scenario}/PACKET-E-CASE-CONTRACTS.json")" 2>&1)"; then
    fail "${name}" "coordinated regeneration passed semantic validation"
  fi
  if [[ "${output}" != *"${expected}"* ]]; then
    fail "${name}" "expected '${expected}'"$'\n'"${output}"
  fi
  pass_count=$((pass_count + 1))
}

# --- the real ledgers must pass, in both scopes -------------------------------------
run_validator full "${registry_fixture}" "${catalog_fixture}" "${contracts_fixture}" "${concurrency_fixture}" \
  || fail "production-ledger-full" "the shipped ledgers must validate"
pass_count=$((pass_count + 1))
run_validator catalog "${registry_fixture}" "${catalog_fixture}" "${contracts_fixture}" "${concurrency_fixture}" \
  || fail "production-ledger-catalog" "the shipped ledgers must validate in catalog scope"
pass_count=$((pass_count + 1))

# --- digest pins ---------------------------------------------------------------------
expect_pin_failure "registry-pin" registry
expect_pin_failure "catalog-pin" catalog

# --- status and authority ------------------------------------------------------------
expect_failure "registry-reviewed-too-early" registry '.status = "reviewed"' \
  'must identify candidate-only version 1 authority'
expect_failure "catalog-reviewed-too-early" catalog '.status = "reviewed"' \
  'must identify candidate-only version 1 authority'
expect_failure "contracts-reviewed-too-early" contracts '.status = "reviewed"' \
  'must identify candidate-only version 1 authority'
expect_failure "catalog-authority-claims-reviewed" catalog \
  '.authority = "This reviewed catalog is normative."' \
  'authority must claim candidate and must not claim reviewed'

# --- placeholder and softening prose --------------------------------------------------
expect_failure "registry-placeholder" registry '.probeNote = "TODO: unfinished"' \
  'operation registry contains placeholder content'
expect_failure "catalog-placeholder" catalog '.probeNote = "FIXME later"' \
  'case-contract catalog contains placeholder content'
expect_failure "contracts-placeholder" contracts '.probeNote = "TBD"' \
  'generated operation contracts contain placeholder content'
expect_failure "registry-bare-unknown" registry '.probeNote = "unknown"' \
  'operation registry contains placeholder content'
expect_failure "registry-best-effort" registry '.probeNote = "best-effort containment proof"' \
  'best-effort semantics'
expect_failure "catalog-fail-open" catalog '.probeNote = "the driver may fail-open here"' \
  'best-effort semantics'
expect_failure "registry-silently-weaken" registry \
  '.probeNote = "the adapter may silently weaken this bound"' \
  'best-effort semantics'

# --- registry rules -------------------------------------------------------------------
expect_failure "rejected-v1-name" registry \
  '.operations += [(.operations[0] | .id = "Restart")]' \
  'rejected v1 name used as an operation id'
expect_failure "mandatory-operation-missing" registry \
  '.operations |= map(select(.id != "TerminateProcess"))' \
  'mandatory driver operation missing from the registry'
expect_failure "recovery-errors-dropped" registry \
  '(.operations[] | select(.id == "StopSandbox") | .allowedRecoveryErrors) = []' \
  'must declare allowedRecoveryErrors'
expect_failure "deferral-marker-claims-coverage" registry \
  '(.operations[] | select(.id | startswith("deferred.")) | .coverageStatus) = "generated"' \
  'deferral marker must carry coverageStatus not-yet-generated'
expect_failure "accepting-without-running" registry \
  '(.lifecycleStates[] | select(.id == "suspended/closed") | .executionAdmission) = "accepting"' \
  'publishes accepting against a non-running status'
expect_failure "registry-unregistered-invariant" registry \
  '(.operations[0].invariants) += ["ZZZ-999"]' \
  'cites an unregistered invariant'
expect_failure "invariant-orphaned-from-every-ledger" registry \
  '(.operations |= map(.invariants |= map(select(. != "FEN-001")))) |
   (.nonOperationCoverage.assignments |= map(.invariants |= map(select(. != "FEN-001"))))' \
  'governed by no operation and assigned to no ledger'

# --- catalog rules ---------------------------------------------------------------------
expect_failure "catalog-operation-set-diverges" catalog \
  '.operationIds |= (.[1:])' \
  'catalog operationIds must equal the registry method set exactly'
expect_failure "catalog-state-order-diverges" catalog \
  '.lifecycleStateIds |= reverse' \
  'must equal the registry lifecycle-state order exactly'
expect_failure "vector-width" catalog \
  '(.transitionVectorsByOperation."StopSandbox") |= .[0:5]' \
  'must classify every lifecycle state exactly once'
expect_failure "vector-unknown-kind" catalog \
  '(.transitionVectorsByOperation."StopSandbox") = "ZZZZZZ"' \
  'unknown cell kind'
expect_failure "entry-cell-count" catalog \
  '(.entries[] | select(.operationId == "StopSandbox") | .cells) |= .[0:5]' \
  'must carry one cell per lifecycle state'
expect_failure "next-state-without-transition" catalog \
  '(.entries[] | select(.operationId == "GetSandbox") | .cells[0].nextLifecycleStateId) = "stopped/closed"' \
  'nextLifecycleStateId is populated iff cellKind is T'
expect_failure "transition-without-next-state" catalog \
  '(.entries[] | select(.operationId == "StopSandbox") | .cells[] | select(.cellKind == "T") | .nextLifecycleStateId) = "none"' \
  'nextLifecycleStateId is populated iff cellKind is T'
expect_failure "reject-without-error" catalog \
  '(.entries[] | select(.operationId == "DeleteSandbox") | .cells[] | select(.cellKind == "J") | .requestErrorId) = "none"' \
  'requestErrorId is populated iff cellKind is J'
expect_failure "error-without-reject" catalog \
  '(.entries[] | select(.operationId == "GetSandbox") | .cells[0].requestErrorId) = "InvalidState"' \
  'requestErrorId is populated iff cellKind is J'
expect_failure "undeclared-request-error" catalog \
  '(.entries[] | select(.operationId == "DeleteSandbox") | .cells[] | select(.cellKind == "J") | .requestErrorId) = "MadeUpError"' \
  'undeclared RequestError variant'
expect_failure "undeclared-terminal-outcome" catalog \
  '(.entries[0].cells[0].terminalOutcome) = "mostly-fine"' \
  'undeclared terminal outcome'
expect_failure "noop-claims-an-epoch" catalog \
  '(.entries[] | select(.operationId == "GetSandbox") | .cells[0].epochRule) = "retains-epoch"' \
  'a noop must carry epochRule no-epoch'
expect_failure "catalog-unregistered-invariant" catalog \
  '(.entries[0].cells[0].invariants) += ["ZZZ-999"]' \
  'cites an unregistered invariant'
expect_failure "kind-disagrees-with-vector" catalog \
  '(.entries[] | select(.operationId == "GetSandbox") | .cells[0].cellKind) = "R"' \
  'cell kind disagrees with its transition vector position'

# --- concurrency rules -------------------------------------------------------------------
expect_failure "concurrency-cell-count" concurrency '.cells |= .[1:]' \
  'cell count must equal expectedCellCount'
expect_failure "concurrency-asymmetric" concurrency \
  '(.cells[] | select(.rowOperationId == "StopSandbox" and .columnOperationId == "Exec") | .compatibility) = "permitted"' \
  'is not symmetric'
expect_failure "concurrency-undeclared-compatibility" concurrency \
  '(.cells[0].compatibility) = "probably-fine" | (.cells[] | select(.rowOperationId == .columnOperationId) | .compatibility) = "probably-fine"' \
  'undeclared compatibility'
expect_failure "concurrency-unknown-operation" concurrency \
  '.rowOperationIds += ["NotAnOperation"]' \
  'names an operation absent from the registry'
expect_failure "concurrency-silent-exclusion" concurrency \
  '.scopeRestriction.excluded |= .[1:]' \
  'neither a concurrency row nor a declared exclusion'

# --- generated-document rules ---------------------------------------------------------
expect_failure "generated-rule-count" contracts '.rules |= .[1:]' \
  'generated rule count must equal expectedCellCount'
expect_failure "generated-cell-uncovered" contracts \
  '.rules |= map(select(.selector.operationIds[0] != "StopSandbox" or .selector.lifecycleStateIds[0] != "running/accepting")) |
   .expectedCellCount = (.expectedCellCount - 1)' \
  'uncovered operation contract cell'
expect_failure "generated-cell-overlapping" contracts \
  '.rules += [.rules[0]] | .expectedCellCount = (.expectedCellCount + 1)' \
  'overlapping operation contract cell'
expect_failure "generated-operation-set" contracts '.operationIds |= .[1:]' \
  'generated operationIds must equal the exact registry method set in order'
expect_failure "generated-state-order" contracts '.lifecycleStateIds |= reverse' \
  'generated lifecycleStateIds must equal the registry order exactly'
expect_failure "generated-multi-state-selector" contracts \
  '(.rules[0].selector.lifecycleStateIds) += ["stopped/closed"]' \
  'must name exactly one lifecycle state'
expect_failure "generated-diverges-from-catalog" contracts \
  '(.rules[0].valueCases[0].epochRule) = "invented-rule"' \
  'generated case diverges from its case-contract catalog cell'
expect_failure "safety-quad-weakened" contracts \
  '(.rules[0].valueCases[0].safetyPolicy.failure) = "fail-open"' \
  'must carry the exact fail-closed safety policy'
expect_failure "fallback-permitted" contracts \
  '(.rules[0].valueCases[0].fallbackPolicy) = "permitted"' \
  'must carry the exact fail-closed safety policy'
expect_failure "approximation-permitted" contracts \
  '(.rules[0].valueCases[0].approximationPolicy) = "permitted"' \
  'must carry the exact fail-closed safety policy'
expect_failure "obligation-identity-free-text" contracts \
  '(.rules[0].valueCases[0].diagnostic.identity) = "some-label"' \
  'diagnostic identity must equal its rule/case identity'
expect_failure "implementation-status-claimed" contracts \
  '(.rules[0].valueCases[0].implementationStatus) = "production"' \
  'value cases remain planned until Gate 4B'
expect_failure "unknown-rule-key" contracts \
  '(.rules[0].escapeHatch) = "allowed"' \
  'unknown rule key'
expect_failure "unknown-value-case-key" contracts \
  '(.rules[0].valueCases[0].escapeHatch) = "allowed"' \
  'unknown value case key'
expect_failure "expected-cell-count-drift" contracts '.expectedCellCount = 999' \
  'expectedCellCount must equal methods × lifecycle states'

# --- coordinated regeneration ------------------------------------------------------------
expect_coordinated_regeneration_failure "coordinated-cell-drop" \
  '(.entries[] | select(.operationId == "StopSandbox") | .cells) |= .[0:5]' \
  'coverage is'
expect_coordinated_regeneration_failure "coordinated-kind-flip" \
  '(.entries[] | select(.operationId == "GetSandbox") | .cells[0].cellKind) = "T"' \
  'cell kind'
expect_coordinated_regeneration_failure "coordinated-noop-epoch" \
  '(.entries[] | select(.operationId == "GetSandbox") | .cells[0].epochRule) = "retains-epoch"' \
  'noop'
expect_coordinated_regeneration_failure "coordinated-undeclared-error" \
  '(.entries[] | select(.operationId == "DeleteSandbox") | .cells[] | select(.cellKind == "J") | .requestErrorId) = "MadeUpError"' \
  'undeclared RequestError variant'
expect_coordinated_regeneration_failure "coordinated-invariant-forgery" \
  '(.entries[0].cells[0].invariants) += ["ZZZ-999"]' \
  'unregistered invariant'

echo "operation contract validator: ${pass_count} cases passed"
