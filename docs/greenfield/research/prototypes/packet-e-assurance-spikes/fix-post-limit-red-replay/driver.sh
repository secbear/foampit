#!/usr/bin/env bash
set -euo pipefail

spike="$1"
statuses="$2"
temporary="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-post-limit-driver.XXXXXX")"
temporary="$(realpath "$temporary")"
trap 'find "$temporary" -depth -delete' EXIT
: >"$statuses"

run_case() {
  local label="$1"
  local expected_status="$2"
  local expected_output="$3"
  shift 3
  local output="$temporary/${label//\//-}.txt"
  local child_status
  set +e
  "$@" >"$output" 2>&1
  child_status=$?
  set -e
  if [[ "$child_status" != "$expected_status" ]]; then
    echo "post-limit RED status mismatch: $label=$child_status expected=$expected_status" >&2
    sed -n '1,40p' "$output" >&2
    return 1
  fi
  if ! grep -F "$expected_output" "$output" >/dev/null; then
    echo "post-limit RED output mismatch: $label" >&2
    sed -n '1,40p' "$output" >&2
    return 1
  fi
  printf '%s=%s\n' "$label" "$child_status" >>"$statuses"
  if [[ "$expected_status" == 0 ]]; then
    echo "CONTROL $label: $expected_output"
  else
    echo "RED $label: $expected_output"
  fi
}

audit="$spike/normalization/dependency-audit.mjs"

run_case normalization/noncomputed-pattern-identifier-sensitive 1 \
  'dependency mutation survived: noncomputed-pattern-identifier-sensitive; prototypeEvidenceStatus=0 prototypeEvidenceStdout="MUTATED noncomputed-pattern-identifier-sensitive\n"' \
  node --expose-internals "$audit" --case dependency-noncomputed-pattern-identifier-sensitive
run_case normalization/noncomputed-pattern-string-sensitive 1 \
  'dependency mutation survived: noncomputed-pattern-string-sensitive; prototypeEvidenceStatus=0 prototypeEvidenceStdout="MUTATED noncomputed-pattern-string-sensitive\n"' \
  node --expose-internals "$audit" --case dependency-noncomputed-pattern-string-sensitive
run_case normalization/noncomputed-object-proto-sensitive 1 \
  'dependency mutation survived: noncomputed-object-proto-sensitive; prototypeEvidenceStatus=0 prototypeEvidenceStdout="MUTATED noncomputed-object-proto-sensitive\n"' \
  node --expose-internals "$audit" --case dependency-noncomputed-object-proto-sensitive
run_case normalization/noncomputed-property-controls 0 \
  'PASS normalization/dependency-noncomputed-property-controls' \
  node --expose-internals "$audit" --case dependency-noncomputed-property-controls
run_case normalization/noncomputed-unsupported-key 1 \
  'dependency mutation survived: noncomputed-unsupported-key' \
  node --expose-internals "$audit" --case dependency-noncomputed-unsupported-key

echo "RED post-limit summary: vulnerabilities=4 controls=1"
