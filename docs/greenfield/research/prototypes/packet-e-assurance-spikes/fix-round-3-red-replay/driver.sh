#!/usr/bin/env bash
set -euo pipefail

spike="$1"
temporary="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-round-3-driver.XXXXXX")"
trap 'find "$temporary" -depth -delete' EXIT

expect_failure() {
  local label="$1"
  local expected="$2"
  shift 2
  local output="$temporary/${label//\//-}.txt"
  if "$@" >"$output" 2>&1; then
    echo "RED driver expected failure but command passed: $label" >&2
    return 1
  fi
  if ! grep -F "$expected" "$output" >/dev/null; then
    echo "RED driver failure mismatch: $label" >&2
    sed -n '1,40p' "$output" >&2
    return 1
  fi
  echo "RED $label: $expected"
}

expect_success() {
  local label="$1"
  shift
  local output="$temporary/${label//\//-}.txt"
  if ! "$@" >"$output" 2>&1; then
    echo "RED driver control failed: $label" >&2
    sed -n '1,40p' "$output" >&2
    return 1
  fi
  echo "CONTROL $label: accepted"
}

formal="$spike/formal/audit.mjs"
normalization="$spike/normalization/dependency-audit.mjs"
replay_tests="$spike/fix-round-1-red-replay/replay-tests.sh"

expect_failure formal/forged-match \
  "negative fixture was accepted: proposition premise" \
  node "$formal" --case expr-forged-match-prop
expect_failure formal/forged-rec \
  "negative fixture was accepted: proposition premise" \
  node "$formal" --case expr-forged-rec-prop
expect_failure formal/forged-cases-on \
  "negative fixture was accepted: nested Type parameter" \
  node "$formal" --case expr-forged-cases-on-higher-type
expect_failure formal/forged-no-confusion \
  "negative fixture was accepted: nested Type parameter" \
  node "$formal" --case expr-forged-no-confusion-nested-type
expect_success formal/actual-recursor \
  node "$formal" --case expr-actual-recursor-metadata

expect_failure normalization/capability-array \
  "dependency mutation survived: capability-array-concat-multihop" \
  node --expose-internals "$normalization" \
    --case dependency-capability-array-concat-multihop
expect_failure normalization/capability-object \
  "dependency mutation survived: capability-object-destructure" \
  node --expose-internals "$normalization" \
    --case dependency-capability-object-destructure
expect_failure normalization/capability-sequence \
  "dependency mutation survived: capability-sequence" \
  node --expose-internals "$normalization" --case dependency-capability-sequence

expect_failure replay/tmpdir-confinement \
  "replay observation missing: normal" \
  bash "$replay_tests" --case tmpdir-confinement

echo "RED round 3 summary: vulnerabilities=8 controls=1"
