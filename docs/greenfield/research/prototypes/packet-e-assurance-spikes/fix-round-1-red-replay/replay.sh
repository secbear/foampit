#!/usr/bin/env bash
set -euo pipefail

if ! here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"; then
  echo "RED replay initialization could not resolve its wrapper directory" >&2
  exit 1
fi
shared_cleanup="$here/../replay-cleanup.sh"
if [[ ! -r "$shared_cleanup" ]]; then
  echo "RED replay shared cleanup implementation is absent" >&2
  exit 1
fi
# shellcheck source=../replay-cleanup.sh
if ! source "$shared_cleanup"; then
  echo "RED replay could not load shared cleanup implementation" >&2
  exit 1
fi
if ! packet_e_replay_initialize "$here" "packet-e-red-replay.XXXXXX"; then
  exit 1
fi

base_commit="6462aa751470cdd08d49f1792432871a17d35fb3"
patch_sha256="12113c290d212c74b10ca0c8f20a3475837e8fbff631b62c572566b533fee107"
patch="$here/test-only.patch"
expected="$here/raw-output.txt"
observed="$temporary/raw-output.txt"
trap packet_e_replay_on_exit EXIT

run_replay() {
  local actual_patch_sha spike
  git -C "$repository" cat-file -e "$base_commit^{commit}" || return
  if ! actual_patch_sha="$(shasum -a 256 "$patch" | awk '{print $1}')"; then
    echo "RED replay could not hash its test-only patch" >&2
    return 1
  fi
  if [[ "$actual_patch_sha" != "$patch_sha256" ]]; then
    echo "RED replay patch hash mismatch" >&2
    return 1
  fi

  git -C "$repository" worktree add --detach "$checkout" "$base_commit" >/dev/null ||
    return
  git -C "$checkout" apply --check "$patch" || return
  git -C "$checkout" apply "$patch" || return

  spike="$checkout/docs/greenfield/research/prototypes/packet-e-assurance-spikes"
  TMPDIR="$child_tmp" nix develop "$spike" --command env TMPDIR="$child_tmp" \
    bash "$spike/fix-round-1-red-replay/driver.sh" >"$observed" || return
  if ! cmp -s "$expected" "$observed"; then
    echo "RED replay raw output mismatch" >&2
    diff -u "$expected" "$observed" >&2 || true
    return 1
  fi
}

if run_replay; then
  child_status=0
else
  child_status=$?
fi
set +e
packet_e_replay_cleanup "$child_status"
final_status=$?
set -e
trap - EXIT

if (( final_status == 0 )); then
  echo "RED replay bundle: PASS base=$base_commit patchSha256=$patch_sha256"
fi
exit "$final_status"
