#!/usr/bin/env bash
set -euo pipefail

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repository="$(git -C "$here" rev-parse --show-toplevel)"
base_commit="8389224046bd2c8c1c56f5e113bdae2aca2d68e9"
patch_sha256="61a1e213e7c9a192bcc3c58be07a3de101f3e0a7e858e99c50ac88f895926445"
patch="$here/test-only.patch"
expected="$here/raw-output.txt"
temporary="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-round-3-replay.XXXXXX")"
temporary="$(realpath "$temporary")"
checkout="$temporary/base"
child_tmp="$temporary/child-tmp"
observed="$temporary/raw-output.txt"
worktree_added=0
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

cleanup() {
  local child_status="$1"
  local cleanup_failure=0
  local final_status="$child_status"

  if (( worktree_added == 1 )) && worktree_registered; then
    if ! git -C "$repository" worktree remove --force "$checkout" >/dev/null 2>&1; then
      if [[ -d "$checkout" ]]; then
        find "$checkout" -depth -delete || cleanup_failure=1
      fi
      if only_target_is_prunable; then
        git -C "$repository" worktree prune --expire now >/dev/null 2>&1 ||
          cleanup_failure=1
      else
        cleanup_failure=1
      fi
    fi
  fi
  if worktree_registered; then
    echo "RED replay cleanup left worktree registration: $checkout" >&2
    cleanup_failure=1
  fi
  if [[ -d "$temporary" ]]; then
    find "$temporary" -depth -delete || cleanup_failure=1
  fi
  if [[ -e "$temporary" ]]; then
    echo "RED replay cleanup left temporary root: $temporary" >&2
    cleanup_failure=1
  fi

  if (( cleanup_failure != 0 )); then
    echo "RED replay cleanup failed" >&2
    if (( final_status == 0 )); then
      final_status=1
    fi
  fi
  return "$final_status"
}

on_exit() {
  local child_status="$?"
  local final_status
  trap - EXIT
  set +e
  cleanup "$child_status"
  final_status="$?"
  exit "$final_status"
}
trap on_exit EXIT

git -C "$repository" cat-file -e "$base_commit^{commit}"
if [[ "$(shasum -a 256 "$patch" | awk '{print $1}')" != "$patch_sha256" ]]; then
  echo "RED replay patch hash mismatch" >&2
  exit 1
fi

git -C "$repository" worktree add --detach "$checkout" "$base_commit" >/dev/null
worktree_added=1
git -C "$checkout" apply --check "$patch"
git -C "$checkout" apply "$patch"

spike="$checkout/docs/greenfield/research/prototypes/packet-e-assurance-spikes"
TMPDIR="$child_tmp" nix develop "$spike" --command env TMPDIR="$child_tmp" \
  bash "$here/driver.sh" "$spike" >"$observed"

if ! cmp -s "$expected" "$observed"; then
  echo "RED replay raw output mismatch" >&2
  diff -u "$expected" "$observed" >&2 || true
  exit 1
fi

trap - EXIT
if cleanup 0; then
  echo "RED replay bundle: PASS base=$base_commit patchSha256=$patch_sha256"
else
  exit $?
fi
