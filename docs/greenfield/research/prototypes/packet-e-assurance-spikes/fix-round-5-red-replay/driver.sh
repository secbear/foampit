#!/usr/bin/env bash
set -euo pipefail

spike="$1"
statuses="$2"
temporary="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-round-5-driver.XXXXXX")"
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
    echo "round-5 RED status mismatch: $label=$child_status expected=$expected_status" >&2
    sed -n '1,40p' "$output" >&2
    return 1
  fi
  if ! grep -F "$expected_output" "$output" >/dev/null; then
    echo "round-5 RED output mismatch: $label" >&2
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
replay_tests="$spike/fix-round-1-red-replay/replay-tests.sh"

run_case normalization/unresolved-let-computed-member 1 \
  'dependency mutation survived: unresolved-let-computed-member; prototypeEvidenceStatus=0 prototypeEvidenceStdout="MUTATED unresolved-let-computed-member\n"' \
  node --expose-internals "$audit" --case dependency-unresolved-let-computed-member
run_case normalization/unresolved-join-computed-member 1 \
  'dependency mutation survived: unresolved-join-computed-member; prototypeEvidenceStatus=0 prototypeEvidenceStdout="MUTATED unresolved-join-computed-member\n"' \
  node --expose-internals "$audit" --case dependency-unresolved-join-computed-member
run_case normalization/resolved-computed-members-control 0 \
  'PASS normalization/dependency-resolved-computed-members-control' \
  node --expose-internals "$audit" --case dependency-resolved-computed-members-control
run_case normalization/builtin-named-reexport-member 1 \
  'dependency mutation survived: builtin-named-reexport-member' \
  node --expose-internals "$audit" --case dependency-builtin-named-reexport-member
run_case normalization/builtin-export-all 1 \
  'dependency mutation survived: builtin-export-all' \
  node --expose-internals "$audit" --case dependency-builtin-export-all
run_case normalization/builtin-named-reexport-control 0 \
  'PASS normalization/dependency-builtin-named-reexport-control' \
  node --expose-internals "$audit" --case dependency-builtin-named-reexport-control

for flag in permission code-generation fetch websocket; do
  run_case "runtime/$flag" 23 \
    "RED runtime/$flag: childStatus=23 childStdout=\"EXPOSED $flag\\n\"" \
    node --expose-internals "$audit" --runtime-omission-red "$flag"
done

run_case replay/post-remove-query-failure 0 \
  'PASS replay/post-remove-query-failure wrappers=2' \
  bash "$replay_tests" --case post-remove-query-failure
run_case replay/status-preservation-post-remove-query-failure 0 \
  'PASS replay/status-preservation-post-remove-query-failure wrappers=2' \
  bash "$replay_tests" --case status-preservation-post-remove-query-failure

echo "RED round 5 summary: vulnerabilities=8 controls=4"
