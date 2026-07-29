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
if ! packet_e_replay_initialize "$here" "packet-e-post-limit-replay.XXXXXX"; then
  exit 1
fi

base_commit="94aa7a0a2a1476f451b99bd167523361e435a774"
patch_sha256="322db8f641d273d33c32e30d67d2a984d90bec2598b300a8bb598dabc7026635"
driver_sha256="e44a48c217cc347ac23e7ad7748d80e2c1b6fa98448dd0a00c3af5abe1a504d5"
raw_output_sha256="19be40d285e1f59b6ac8e6bbed5758a5dbc08a8eb948336b193e53389ad590f1"
statuses_sha256="a3b7ea2eb2924bef64ba2784d19f0a1a14d6a844c940d8017a0744388ea66494"
patch="$here/test-only.patch"
driver="$here/driver.sh"
expected="$here/raw-output.txt"
expected_statuses="$here/statuses.txt"
observed="$temporary/raw-output.txt"
observed_statuses="$temporary/statuses.txt"
trap packet_e_replay_on_exit EXIT

run_replay() {
  local actual_sha spike
  git -C "$repository" cat-file -e "$base_commit^{commit}" || return
  while IFS='|' read -r artifact expected_sha label; do
    if ! actual_sha="$(shasum -a 256 "$artifact" | awk '{print $1}')"; then
      echo "RED replay could not hash its $label" >&2
      return 1
    fi
    if [[ "$actual_sha" != "$expected_sha" ]]; then
      echo "RED replay $label hash mismatch" >&2
      return 1
    fi
  done <<ARTIFACTS
$patch|$patch_sha256|test-only patch
$driver|$driver_sha256|driver
$expected|$raw_output_sha256|raw transcript
$expected_statuses|$statuses_sha256|status transcript
ARTIFACTS

  git -C "$repository" worktree add --detach "$checkout" "$base_commit" >/dev/null ||
    return
  git -C "$checkout" apply --unidiff-zero --check "$patch" || return
  git -C "$checkout" apply --unidiff-zero "$patch" || return

  spike="$checkout/docs/greenfield/research/prototypes/packet-e-assurance-spikes"
  TMPDIR="$child_tmp" nix develop "$spike" --command env TMPDIR="$child_tmp" \
    bash "$driver" "$spike" "$observed_statuses" >"$observed" || return
  if ! cmp -s "$expected" "$observed"; then
    echo "RED replay raw output mismatch" >&2
    diff -u "$expected" "$observed" >&2 || true
    return 1
  fi
  if ! cmp -s "$expected_statuses" "$observed_statuses"; then
    echo "RED replay status transcript mismatch" >&2
    diff -u "$expected_statuses" "$observed_statuses" >&2 || true
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
