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
if ! packet_e_replay_initialize "$here" "packet-e-round-4-replay.XXXXXX"; then
  exit 1
fi

base_commit="2eb96731e6d4ea4f143cd607fbaa2f92ad34da69"
patch_sha256="8e45e296292a5a47d3e541c49b6b6731a85c49aeb0248851ff172dbc2b0263b5"
driver_sha256="a1982971e30ac8679b1ab047bc06ab69bc9166096804d9bc70f68e20e10a6482"
raw_output_sha256="4229e0bc287e5293cc146a13cd00b7c0a3c4ba47b6e029c14ad70c650ea0b3b8"
statuses_sha256="66b8dd19af5f5f3465a70aaeb2aaac35e9b6971bebfc2a0c5f325bf219382f72"
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
