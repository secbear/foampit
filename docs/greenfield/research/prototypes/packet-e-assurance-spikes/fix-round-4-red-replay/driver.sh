#!/usr/bin/env bash
set -euo pipefail

spike="$1"
statuses="$2"
temporary="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-round-4-driver.XXXXXX")"
temporary="$(realpath "$temporary")"
trap 'find "$temporary" -depth -delete' EXIT
: >"$statuses"

expect_failure() {
  local label="$1"
  local expected="$2"
  shift 2
  local output="$temporary/${label//\//-}.txt"
  local child_status
  set +e
  "$@" >"$output" 2>&1
  child_status=$?
  set -e
  if [[ "$child_status" != 1 ]]; then
    echo "RED driver expected status 1 but observed $child_status: $label" >&2
    return 1
  fi
  if ! grep -F "$expected" "$output" >/dev/null; then
    echo "RED driver failure mismatch: $label" >&2
    sed -n '1,60p' "$output" >&2
    return 1
  fi
  printf '%s=%s\n' "$label" "$child_status" >>"$statuses"
  echo "RED $label: $expected"
}

expect_success() {
  local label="$1"
  shift
  local output="$temporary/${label//\//-}.txt"
  local child_status
  set +e
  "$@" >"$output" 2>&1
  child_status=$?
  set -e
  if [[ "$child_status" != 0 ]]; then
    echo "RED driver control failed with status $child_status: $label" >&2
    sed -n '1,60p' "$output" >&2
    return 1
  fi
  printf '%s=%s\n' "$label" "$child_status" >>"$statuses"
  echo "CONTROL $label: accepted"
}

normalization="$spike/normalization/dependency-audit.mjs"
replay_tests="$spike/fix-round-1-red-replay/replay-tests.sh"

expect_failure normalization/async-function-constructor \
  "dependency mutation survived: async-function-constructor" \
  node --expose-internals "$normalization" \
    --case dependency-async-function-constructor
expect_failure normalization/function-prototype-constructor \
  "dependency mutation survived: function-prototype-constructor" \
  node --expose-internals "$normalization" \
    --case dependency-function-prototype-constructor
expect_failure normalization/ambient-fetch \
  "dependency mutation survived: ambient-fetch" \
  node --expose-internals "$normalization" --case dependency-ambient-fetch
expect_failure normalization/ambient-websocket \
  "dependency mutation survived: ambient-websocket" \
  node --expose-internals "$normalization" --case dependency-ambient-websocket
expect_failure normalization/safe-global-member \
  "dependency mutation survived: safe-global-member" \
  node --expose-internals "$normalization" --case dependency-safe-global-member
expect_success normalization/lexical-shadowing \
  node --expose-internals "$normalization" \
    --case dependency-lexical-shadowing-control
expect_failure runtime/hardening-flags \
  "hardenedRuntimeArgs is not defined" \
  node --expose-internals "$normalization" --case runtime-hardening-flags

expect_success replay/normal bash "$replay_tests" --case normal
expect_failure replay/fail-first-remove \
  "invoked repository-wide worktree prune" \
  bash "$replay_tests" --case fail-first-remove
expect_failure replay/query-failure \
  "did not retain the exact recovery root" \
  bash "$replay_tests" --case query-failure
expect_failure replay/exact-remove-failure \
  "invoked repository-wide worktree prune" \
  bash "$replay_tests" --case exact-remove-failure
expect_success replay/status-preservation \
  bash "$replay_tests" --case status-preservation

echo "RED round 4 summary: vulnerabilities=9 controls=3"
