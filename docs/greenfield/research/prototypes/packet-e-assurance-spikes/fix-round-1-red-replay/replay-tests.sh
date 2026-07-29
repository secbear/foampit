#!/usr/bin/env bash
set -euo pipefail

stub_git() {
  local command="${3:-}"
  local operation="${4:-}"
  local count
  if [[ "$command" == "worktree" && "$operation" == "add" ]]; then
    printf '%s\n' "$6" >"$PACKET_E_REPLAY_STUB_STATE/target"
  elif [[ "$command" == "worktree" && "$operation" == "list" ]]; then
    count=0
    if [[ -f "$PACKET_E_REPLAY_STUB_STATE/query-count" ]]; then
      count="$(<"$PACKET_E_REPLAY_STUB_STATE/query-count")"
    fi
    count=$((count + 1))
    printf '%s\n' "$count" >"$PACKET_E_REPLAY_STUB_STATE/query-count"
    if [[ (
      "$PACKET_E_REPLAY_STUB_SCENARIO" == "query-failure" ||
      "$PACKET_E_REPLAY_STUB_SCENARIO" == "status-preservation-query-failure"
    ) && "$count" == 1 ]]; then
      exit 71
    fi
  elif [[ "$command" == "worktree" && "$operation" == "remove" ]]; then
    count=0
    if [[ -f "$PACKET_E_REPLAY_STUB_STATE/remove-count" ]]; then
      count="$(<"$PACKET_E_REPLAY_STUB_STATE/remove-count")"
    fi
    count=$((count + 1))
    printf '%s\n' "$count" >"$PACKET_E_REPLAY_STUB_STATE/remove-count"
    if [[ "$PACKET_E_REPLAY_STUB_SCENARIO" == "fail-first-remove" && "$count" == 1 ]]; then
      exit 72
    fi
    if [[ "$PACKET_E_REPLAY_STUB_SCENARIO" == "exact-remove-failure" ]]; then
      exit 73
    fi
  elif [[ "$command" == "worktree" && "$operation" == "prune" ]]; then
    : >"$PACKET_E_REPLAY_STUB_STATE/prune"
  fi
  exec "$PACKET_E_REPLAY_REAL_GIT" "$@"
}

stub_nix() {
  printf '%s\n' "${TMPDIR:-}" >"$PACKET_E_REPLAY_STUB_STATE/child-tmp"
  if (( PACKET_E_REPLAY_STUB_CHILD_STATUS != 0 )); then
    exit "$PACKET_E_REPLAY_STUB_CHILD_STATUS"
  fi
  command cat "$PACKET_E_REPLAY_STUB_EXPECTED"
}

case "${0##*/}" in
  git)
    stub_git "$@"
    exit
    ;;
  nix)
    stub_nix "$@"
    exit
    ;;
esac

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repository="$(git -C "$here" rev-parse --show-toplevel)"
real_git="$(command -v git)"
cases=(
  normal
  fail-first-remove
  query-failure
  exact-remove-failure
  status-preservation
  status-preservation-query-failure
)
wrappers=(
  fix-round-1-red-replay/replay.sh
  fix-round-3-red-replay/replay.sh
)

fail() {
  echo "replay matrix assertion failed: $*" >&2
  return 1
}

capture_registration() {
  local clone="$1"
  local target="$2"
  local inventory
  if ! inventory="$("$real_git" -C "$clone" worktree list --porcelain)"; then
    fail "disposable inventory query failed"
  fi
  while IFS= read -r line; do
    if [[ "$line" == "worktree $target" ]]; then
      return 0
    fi
  done <<<"$inventory"
  return 1
}

prepare_disposable_clone() {
  local clone="$1"
  local wrapper_relative="$2"
  "$real_git" clone --quiet --no-hardlinks "$repository" "$clone"
  command cp "$repository/docs/greenfield/research/prototypes/packet-e-assurance-spikes/$wrapper_relative" \
    "$clone/docs/greenfield/research/prototypes/packet-e-assurance-spikes/$wrapper_relative"
  if [[ -f \
    "$repository/docs/greenfield/research/prototypes/packet-e-assurance-spikes/replay-cleanup.sh" ]]; then
    command cp \
      "$repository/docs/greenfield/research/prototypes/packet-e-assurance-spikes/replay-cleanup.sh" \
      "$clone/docs/greenfield/research/prototypes/packet-e-assurance-spikes/replay-cleanup.sh"
  fi
}

run_wrapper() {
  local case_root="$1"
  local scenario="$2"
  local wrapper_relative="$3"
  local child_status="$4"
  local wrapper_key clone state fake_bin temp_parent wrapper expected status
  local target root child_tmp remove_count expected_status expect_recovery

  wrapper_key="${wrapper_relative//\//-}"
  clone="$case_root/repository-$wrapper_key"
  state="$case_root/state-$wrapper_key"
  fake_bin="$case_root/bin-$wrapper_key"
  temp_parent="$case_root/temp-$wrapper_key"
  command mkdir -p "$state" "$fake_bin" "$temp_parent"
  prepare_disposable_clone "$clone" "$wrapper_relative"
  command ln -s "$here/replay-tests.sh" "$fake_bin/git"
  command ln -s "$here/replay-tests.sh" "$fake_bin/nix"

  wrapper="$clone/docs/greenfield/research/prototypes/packet-e-assurance-spikes/$wrapper_relative"
  expected="${wrapper%/*}/raw-output.txt"
  set +e
  PATH="$fake_bin:$PATH" \
    TMPDIR="$temp_parent" \
    PACKET_E_REPLAY_STUB_STATE="$state" \
    PACKET_E_REPLAY_STUB_SCENARIO="$scenario" \
    PACKET_E_REPLAY_STUB_CHILD_STATUS="$child_status" \
    PACKET_E_REPLAY_STUB_EXPECTED="$expected" \
    PACKET_E_REPLAY_REAL_GIT="$real_git" \
    bash "$wrapper" >"$state/stdout" 2>"$state/stderr"
  status=$?
  set -e

  [[ -s "$state/target" ]] || fail "$scenario/$wrapper_key did not record an exact target"
  target="$(<"$state/target")"
  root="${target%/base}"
  child_tmp="$(<"$state/child-tmp")"
  [[ "$target" == "$root/base" ]] ||
    fail "$scenario/$wrapper_key target is not the literal base child"
  [[ "$root" == "$(realpath "$temp_parent")/"* ]] ||
    fail "$scenario/$wrapper_key root escaped the canonical test TMPDIR"
  [[ "$child_tmp" == "$root/child-tmp" ]] ||
    fail "$scenario/$wrapper_key child TMPDIR was not confined"
  [[ ! -e "$state/prune" ]] ||
    fail "$scenario/$wrapper_key invoked repository-wide worktree prune"

  remove_count=0
  if [[ -f "$state/remove-count" ]]; then
    remove_count="$(<"$state/remove-count")"
  fi
  expected_status=0
  expect_recovery=0
  case "$scenario" in
    normal)
      [[ "$remove_count" == 1 ]] ||
        fail "$scenario/$wrapper_key did not remove the target exactly once"
      ;;
    fail-first-remove)
      [[ "$remove_count" == 2 ]] ||
        fail "$scenario/$wrapper_key did not retry the exact target once"
      ;;
    query-failure)
      expected_status=1
      expect_recovery=1
      [[ "$remove_count" == 0 ]] ||
        fail "$scenario/$wrapper_key removed after inventory query failure"
      ;;
    exact-remove-failure)
      expected_status=1
      expect_recovery=1
      [[ "$remove_count" == 2 ]] ||
        fail "$scenario/$wrapper_key did not stop after two exact attempts"
      ;;
    status-preservation)
      expected_status=7
      [[ "$remove_count" == 1 ]] ||
        fail "$scenario/$wrapper_key did not clean after child failure"
      ;;
    status-preservation-query-failure)
      expected_status=7
      expect_recovery=1
      [[ "$remove_count" == 0 ]] ||
        fail "$scenario/$wrapper_key removed after inventory query failure"
      ;;
    *)
      fail "unknown replay scenario: $scenario"
      ;;
  esac
  [[ "$status" == "$expected_status" ]] ||
    fail "$scenario/$wrapper_key status=$status expected=$expected_status"

  if (( expect_recovery == 1 )); then
    [[ -d "$root" && -d "$target" ]] ||
      fail "$scenario/$wrapper_key did not retain the exact recovery root"
    capture_registration "$clone" "$target" ||
      fail "$scenario/$wrapper_key did not retain the exact registration"
  else
    [[ ! -e "$root" ]] ||
      fail "$scenario/$wrapper_key left a successful cleanup root"
    if capture_registration "$clone" "$target"; then
      fail "$scenario/$wrapper_key left a successful cleanup registration"
    fi
  fi
}

run_case() {
  local scenario="$1"
  local case_root child_status=0 wrapper
  case_root="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-replay-matrix.$scenario.XXXXXX")"
  case_root="$(realpath "$case_root")"
  (
    trap 'find "$case_root" -depth -delete' EXIT
    if [[ "$scenario" == "status-preservation" ||
      "$scenario" == "status-preservation-query-failure" ]]; then
      child_status=7
    fi
    for wrapper in "${wrappers[@]}"; do
      run_wrapper "$case_root" "$scenario" "$wrapper" "$child_status"
    done
  )
  echo "PASS replay/$scenario wrappers=${#wrappers[@]}"
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
  echo "replay tests: ${#cases[@]} cases x ${#wrappers[@]} wrappers passed"
else
  echo "usage: replay-tests.sh --all | --case ${cases[*]}" >&2
  exit 2
fi
