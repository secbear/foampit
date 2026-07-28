#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
validator="${script_dir}/validate-surface-coverage.jq"
coverage_fixture="${script_dir}/fixtures/minimal-surface-coverage.json"
registry_fixture="${script_dir}/fixtures/minimal-inventory.json"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT
pass_count=0

run_validator() {
  local coverage="$1"
  local registry="$2"
  jq -e \
    --slurpfile registry "${registry}" \
    -f "${validator}" \
    "${coverage}" >/dev/null
}

expect_pass() {
  local name="$1"
  local coverage="$2"
  if ! output="$(run_validator "${coverage}" "${registry_fixture}" 2>&1)"; then
    echo "FAIL ${name}: expected success" >&2
    echo "${output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_failure() {
  local name="$1"
  local mutation="$2"
  local expected="$3"
  local mutated="${tmp_dir}/${name}.json"
  jq "${mutation}" "${coverage_fixture}" >"${mutated}"
  if output="$(run_validator "${mutated}" "${registry_fixture}" 2>&1)"; then
    echo "FAIL ${name}: expected failure" >&2
    exit 1
  fi
  if [[ "${output}" != *"${expected}"* ]]; then
    echo "FAIL ${name}: expected '${expected}'" >&2
    echo "${output}" >&2
    exit 1
  fi
  pass_count=$((pass_count + 1))
}

expect_pass "minimal-surface" "${coverage_fixture}"
expect_failure \
  "duplicate-surface" \
  '.surfaces += [.surfaces[0]]' \
  'duplicate surface id: create.bindings'
expect_failure \
  "unknown-owner" \
  '.surfaces[0].owner = "manifest"' \
  'unknown owner'
expect_failure \
  "covered-without-invariant" \
  '.surfaces[0].invariants = []' \
  'covered surface requires an invariant'
expect_failure \
  "unknown-invariant" \
  '.surfaces[0].invariants = ["INV-999"]' \
  'unknown invariant reference: INV-999'
expect_failure \
  "delegated-without-packet" \
  '.surfaces[0].outcome = "delegated" |
   .surfaces[0].invariants = []' \
  'delegated surface requires packet B-F'
expect_failure \
  "placeholder-rationale" \
  '.surfaces[0].rationale = "TBD"' \
  'contains placeholder content'

echo "surface coverage validator: ${pass_count} cases passed"
