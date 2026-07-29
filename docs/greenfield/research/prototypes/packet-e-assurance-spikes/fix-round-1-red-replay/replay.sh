#!/usr/bin/env bash
set -uo pipefail

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repository="$(git -C "$here" rev-parse --show-toplevel)"
base_commit="6462aa751470cdd08d49f1792432871a17d35fb3"
patch_sha256="12113c290d212c74b10ca0c8f20a3475837e8fbff631b62c572566b533fee107"
patch="$here/test-only.patch"
expected="$here/raw-output.txt"
temporary="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-red-replay.XXXXXX")"
temporary="$(realpath "$temporary")"
checkout="$temporary/base"
child_tmp="$temporary/child-tmp"
observed="$temporary/raw-output.txt"
test_fast="${PACKET_E_REPLAY_TEST_FAST:-0}"
test_scenario="${PACKET_E_REPLAY_TEST_SCENARIO:-normal}"
test_child_status="${PACKET_E_REPLAY_TEST_CHILD_STATUS:-0}"
test_observation="${PACKET_E_REPLAY_TEST_OBSERVATION:-}"
child_probe=""
worktree_added=0
remove_fallback=0
prune_used=0
cleanup_done=0
mkdir -p "$child_tmp"

worktree_registered() {
  git -C "$repository" worktree list --porcelain |
    awk -v target="$checkout" '
      $1 == "worktree" && substr($0, 10) == target { found = 1 }
      END { exit(found ? 0 : 1) }
    '
}

only_target_is_prunable() {
  git -C "$repository" worktree list --porcelain |
    awk -v target="$checkout" '
      $1 == "worktree" {
        current = substr($0, 10)
      }
      $1 == "prunable" {
        count += 1
        if (current == target) {
          targetCount += 1
        }
      }
      END {
        exit(count == 1 && targetCount == 1 ? 0 : 1)
      }
    '
}

write_observation() {
  local child_status="$1"
  local final_status="$2"
  local cleanup_failure="$3"
  local registered_after="$4"
  local temporary_after="$5"
  [[ -n "$test_observation" ]] || return 0
  jq -n \
    --arg temporary "$temporary" \
    --arg childTmp "$child_tmp" \
    --arg childProbe "$child_probe" \
    --arg checkout "$checkout" \
    --argjson removeFallback "$remove_fallback" \
    --argjson pruneUsed "$prune_used" \
    --argjson registeredAfter "$registered_after" \
    --argjson temporaryAfter "$temporary_after" \
    --argjson cleanupFailure "$cleanup_failure" \
    --argjson childStatus "$child_status" \
    --argjson finalStatus "$final_status" \
    '{
      temporary: $temporary,
      childTmp: $childTmp,
      childProbe: $childProbe,
      checkout: $checkout,
      removeFallback: ($removeFallback == 1),
      pruneUsed: ($pruneUsed == 1),
      registeredAfter: $registeredAfter,
      temporaryAfter: $temporaryAfter,
      cleanupFailure: $cleanupFailure,
      childStatus: $childStatus,
      finalStatus: $finalStatus
    }' >"$test_observation"
}

cleanup() {
  local child_status="$1"
  local cleanup_failure=0
  local final_status="$child_status"
  local registered_after=false
  local temporary_after=false
  local initial_remove_failed=0

  if (( worktree_added == 1 )) && worktree_registered; then
    if [[ "$test_scenario" == "stale-registration" ]]; then
      if [[ -d "$checkout" ]]; then
        find "$checkout" -depth -delete || cleanup_failure=1
      fi
      initial_remove_failed=1
    elif [[ "$test_scenario" == "fail-remove-once" ]]; then
      initial_remove_failed=1
    elif ! git -C "$repository" worktree remove --force "$checkout" >/dev/null 2>&1; then
      initial_remove_failed=1
    fi

    if (( initial_remove_failed == 1 )); then
      remove_fallback=1
      if [[ "$test_scenario" != "stale-registration" ]] &&
          git -C "$repository" worktree remove --force "$checkout" >/dev/null 2>&1; then
        :
      else
        if [[ -d "$checkout" ]]; then
          find "$checkout" -depth -delete || cleanup_failure=1
        fi
        if only_target_is_prunable; then
          git -C "$repository" worktree prune --expire now >/dev/null 2>&1 ||
            cleanup_failure=1
          prune_used=1
        else
          cleanup_failure=1
        fi
      fi
    fi
  fi

  if worktree_registered; then
    echo "RED replay cleanup left worktree registration: $checkout" >&2
    registered_after=true
    cleanup_failure=1
  fi
  if [[ -d "$temporary" ]]; then
    find "$temporary" -depth -delete || cleanup_failure=1
  fi
  if [[ -e "$temporary" ]]; then
    echo "RED replay cleanup left temporary root: $temporary" >&2
    temporary_after=true
    cleanup_failure=1
  fi
  if [[ "$test_scenario" == "reported-cleanup-failure" ]]; then
    cleanup_failure=1
  fi

  if (( cleanup_failure != 0 )) && (( final_status == 0 )); then
    final_status=1
  fi
  write_observation \
    "$child_status" \
    "$final_status" \
    "$([[ "$cleanup_failure" == 0 ]] && echo false || echo true)" \
    "$registered_after" \
    "$temporary_after" || {
      echo "RED replay cleanup could not write observation" >&2
      cleanup_failure=1
      if (( final_status == 0 )); then
        final_status=1
      fi
    }
  if (( cleanup_failure != 0 )); then
    echo "RED replay cleanup failed" >&2
  fi
  cleanup_done=1
  return "$final_status"
}

on_exit() {
  local child_status="$?"
  local final_status
  if (( cleanup_done == 1 )); then
    return
  fi
  trap - EXIT
  set +e
  cleanup "$child_status"
  final_status="$?"
  exit "$final_status"
}
trap on_exit EXIT

run_replay() {
  git -C "$repository" cat-file -e "$base_commit^{commit}" || return
  if [[ "$(shasum -a 256 "$patch" | awk '{print $1}')" != "$patch_sha256" ]]; then
    echo "RED replay patch hash mismatch" >&2
    return 1
  fi

  git -C "$repository" worktree add --detach "$checkout" "$base_commit" >/dev/null ||
    return
  worktree_added=1
  git -C "$checkout" apply --check "$patch" || return
  git -C "$checkout" apply "$patch" || return

  if [[ "$test_fast" == 1 ]]; then
    if [[ ! "$test_child_status" =~ ^[0-9]+$ ]] || (( test_child_status > 255 )); then
      echo "invalid replay test child status" >&2
      return 2
    fi
    child_probe="$(TMPDIR="$child_tmp" mktemp "$child_tmp/child-probe.XXXXXX")" ||
      return
    return "$test_child_status"
  fi

  local spike="$checkout/docs/greenfield/research/prototypes/packet-e-assurance-spikes"
  TMPDIR="$child_tmp" nix develop "$spike" --command env TMPDIR="$child_tmp" \
    bash "$spike/fix-round-1-red-replay/driver.sh" >"$observed" || return

  if ! cmp -s "$expected" "$observed"; then
    echo "RED replay raw output mismatch" >&2
    diff -u "$expected" "$observed" >&2 || true
    return 1
  fi
}

run_replay
child_status="$?"
cleanup "$child_status"
final_status="$?"
trap - EXIT

if (( final_status == 0 )) && [[ "$test_fast" != 1 ]]; then
  echo "RED replay bundle: PASS base=$base_commit patchSha256=$patch_sha256"
fi
exit "$final_status"
