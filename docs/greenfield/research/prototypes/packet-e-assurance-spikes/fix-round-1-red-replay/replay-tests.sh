#!/usr/bin/env bash
set -euo pipefail

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repository="$(git -C "$here" rev-parse --show-toplevel)"
cases=(
  tmpdir-confinement
  failed-remove-fallback
  stale-registration-prune
  cleanup-failure-status
)

run_replay() {
  local case_root="$1"
  local scenario="$2"
  local child_status="${3:-0}"
  local observation="$case_root/observation-$scenario-$child_status.json"
  local temp_parent="$case_root/temp-parent"
  mkdir -p "$temp_parent"
  set +e
  TMPDIR="$temp_parent" \
    PACKET_E_REPLAY_TEST_FAST=1 \
    PACKET_E_REPLAY_TEST_SCENARIO="$scenario" \
    PACKET_E_REPLAY_TEST_CHILD_STATUS="$child_status" \
    PACKET_E_REPLAY_TEST_OBSERVATION="$observation" \
    bash "$here/replay.sh" >/dev/null 2>"$case_root/stderr-$scenario-$child_status.txt"
  replay_status=$?
  set -e
  [[ -f "$observation" ]] || {
    echo "replay observation missing: $scenario" >&2
    return 1
  }
}

assert_common_cleanup() {
  local observation="$1"
  jq -e '
    . as $observation |
    ($observation.temporary | type == "string" and length > 0) and
    ($observation.childTmp | startswith($observation.temporary + "/")) and
    ($observation.childProbe | startswith($observation.childTmp + "/")) and
    ($observation.checkout | startswith($observation.temporary + "/")) and
    ($observation.registeredAfter == false) and
    ($observation.temporaryAfter == false)
  ' "$observation" >/dev/null
}

with_case_root() {
  local case_name="$1"
  local case_root
  case_root="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-replay-test.$case_name.XXXXXX")"
  (
    trap 'find "$case_root" -depth -delete' EXIT
    "$2" "$case_root"
  )
}

test_tmpdir_confinement() {
  local case_root="$1"
  run_replay "$case_root" normal
  [[ "$replay_status" == 0 ]]
  assert_common_cleanup "$case_root/observation-normal-0.json"
  jq -e '.cleanupFailure == false' "$case_root/observation-normal-0.json" >/dev/null
}

test_failed_remove_fallback() {
  local case_root="$1"
  run_replay "$case_root" fail-remove-once
  [[ "$replay_status" == 0 ]]
  assert_common_cleanup "$case_root/observation-fail-remove-once-0.json"
  jq -e '.removeFallback == true and .cleanupFailure == false' \
    "$case_root/observation-fail-remove-once-0.json" >/dev/null
}

test_stale_registration_prune() {
  local case_root="$1"
  run_replay "$case_root" stale-registration
  [[ "$replay_status" == 0 ]]
  assert_common_cleanup "$case_root/observation-stale-registration-0.json"
  jq -e '.pruneUsed == true and .cleanupFailure == false' \
    "$case_root/observation-stale-registration-0.json" >/dev/null
}

test_cleanup_failure_status() {
  local case_root="$1"
  run_replay "$case_root" reported-cleanup-failure 0
  [[ "$replay_status" == 1 ]]
  assert_common_cleanup "$case_root/observation-reported-cleanup-failure-0.json"
  jq -e '.cleanupFailure == true and .childStatus == 0 and .finalStatus == 1' \
    "$case_root/observation-reported-cleanup-failure-0.json" >/dev/null

  run_replay "$case_root" reported-cleanup-failure 7
  [[ "$replay_status" == 7 ]]
  assert_common_cleanup "$case_root/observation-reported-cleanup-failure-7.json"
  jq -e '.cleanupFailure == true and .childStatus == 7 and .finalStatus == 7' \
    "$case_root/observation-reported-cleanup-failure-7.json" >/dev/null
}

run_case() {
  local name="$1"
  case "$name" in
    tmpdir-confinement)
      with_case_root "$name" test_tmpdir_confinement
      ;;
    failed-remove-fallback)
      with_case_root "$name" test_failed_remove_fallback
      ;;
    stale-registration-prune)
      with_case_root "$name" test_stale_registration_prune
      ;;
    cleanup-failure-status)
      with_case_root "$name" test_cleanup_failure_status
      ;;
    *)
      echo "unknown replay case: $name" >&2
      return 2
      ;;
  esac
  echo "PASS replay/$name"
}

if [[ "${1:-}" == "--case" ]]; then
  [[ -n "${2:-}" ]] || {
    echo "usage: replay-tests.sh --all | --case ${cases[*]}" >&2
    exit 2
  }
  run_case "$2"
elif [[ "${1:-}" == "--all" ]]; then
  for case_name in "${cases[@]}"; do
    run_case "$case_name"
  done
  echo "replay tests: ${#cases[@]} passed"
else
  echo "usage: replay-tests.sh --all | --case ${cases[*]}" >&2
  exit 2
fi
