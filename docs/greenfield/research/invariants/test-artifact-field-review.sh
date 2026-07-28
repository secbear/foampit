#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
validator="${script_dir}/validate-artifact-field-review.jq"
review_fixture="${script_dir}/fixtures/minimal-artifact-field-review.json"
registry_fixture="${script_dir}/fixtures/minimal-inventory.json"
packet_a_fixture="${script_dir}/fixtures/minimal-artifact-surface-coverage.json"
tmp_dir="$(mktemp -d)"
trap 'rm -rf -- "${tmp_dir}"' EXIT
pass_count=0

run_validator() {
  local review="$1"
  local registry="$2"
  local packet_a="$3"
  jq -e \
    --slurpfile registry "${registry}" \
    --slurpfile packetA "${packet_a}" \
    -f "${validator}" \
    "${review}" >/dev/null
}

expect_pass() {
  local name="$1"
  local review="$2"
  if ! output="$(run_validator \
    "${review}" \
    "${registry_fixture}" \
    "${packet_a_fixture}" 2>&1)"; then
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
  jq "${mutation}" "${review_fixture}" >"${mutated}"
  if output="$(run_validator \
    "${mutated}" \
    "${registry_fixture}" \
    "${packet_a_fixture}" 2>&1)"; then
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

expect_pass "minimal-artifact-field-review" "${review_fixture}"
expect_failure \
  "duplicate-field" \
  '.fields += [.fields[0]]' \
  'duplicate field id: artifact.profile'
expect_failure \
  "missing-required-family" \
  '.fields |= map(select(.family != "targets"))' \
  'required family has no field entry: targets'
expect_failure \
  "unknown-owner" \
  '.fields[0].owner = "manifest"' \
  'unknown owner'
expect_failure \
  "unknown-kind" \
  '.fields[0].kind = "toggle"' \
  'unknown field kind'
expect_failure \
  "unknown-outcome" \
  '.fields[0].outcome = "pending"' \
  'unknown outcome'
expect_failure \
  "covered-without-invariant" \
  '.fields[0].invariants = []' \
  'covered field requires an invariant'
expect_failure \
  "unknown-invariant" \
  '.fields[0].invariants = ["INV-999"]' \
  'unknown invariant reference: INV-999'
expect_failure \
  "delegated-without-packet" \
  '.fields[13].delegatedPackets = []' \
  'delegated field requires packet C-F'
expect_failure \
  "nondelegated-with-packet" \
  '.fields[1].delegatedPackets = ["C"]' \
  'only delegated fields name delegatedPackets'
expect_failure \
  "missing-portable-meaning" \
  '.fields[0].portableMeaning = ""' \
  'portableMeaning must be non-empty'
expect_failure \
  "whitespace-portable-meaning" \
  '.fields[0].portableMeaning = "   "' \
  'portableMeaning must be non-empty'
expect_failure \
  "missing-omission-semantics" \
  '.fields[0].omissionSemantics = ""' \
  'omissionSemantics must be non-empty'
expect_failure \
  "placeholder-content" \
  '.fields[0].rationale = "TBD"' \
  'contains placeholder content'
expect_failure \
  "unknown-introduced-invariant" \
  '.introducedInvariants = ["INV-999"]' \
  'unknown introduced invariant: INV-999'
expect_failure \
  "duplicate-introduced-invariant" \
  '.introducedInvariants += [.introducedInvariants[0]]' \
  'duplicate introduced invariant: INV-001'
expect_failure \
  "unreferenced-introduced-invariant" \
  '.fields[0].outcome = "no-new-rule" |
   .fields[0].invariants = []' \
  'introduced invariant is not referenced by a field: INV-001'
expect_failure \
  "duplicate-field-invariant" \
  '.fields[0].invariants += [.fields[0].invariants[0]]' \
  'duplicate invariant reference: INV-001'
expect_failure \
  "duplicate-delegated-packet" \
  '.fields[13].delegatedPackets += [.fields[13].delegatedPackets[0]]' \
  'duplicate delegated packet: E'
expect_failure \
  "duplicate-refined-surface" \
  '.fields[0].refinesPacketASurfaces += [.fields[0].refinesPacketASurfaces[0]]' \
  'duplicate Packet A surface reference: artifact.example'
expect_failure \
  "unknown-packet-a-surface" \
  '.fields[0].refinesPacketASurfaces = ["artifact.unknown"]' \
  'unknown Packet A Artifact surface: artifact.unknown'
expect_failure \
  "unrefined-packet-a-surface" \
  '.fields[0].refinesPacketASurfaces = []' \
  'Packet A Artifact surface is not refined: artifact.example'

echo "artifact field review validator: ${pass_count} cases passed"
