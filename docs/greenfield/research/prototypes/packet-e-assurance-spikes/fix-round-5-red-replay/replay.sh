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
if ! packet_e_replay_initialize "$here" "packet-e-round-5-replay.XXXXXX"; then
  exit 1
fi

base_commit="7373f4d97dcdb30992875743484de6f0d5b9e51e"
patch_sha256="a98cf9ff5985d653e706dfd7a568c5bfa992eb34467c259c9362a794362feb5e"
driver_sha256="f7b41d10a22c8242469b4b22d3e2e90081f7ca07dc922871c27f59da1958c7ea"
raw_output_sha256="3068cc6341f07739a89f031cbf9f2cdc3d80b540b1723fc03d52a15aae29c92b"
statuses_sha256="eccdbe8ed8838d5ba4fa08921da5419029d37ec6ed3f6e2f321ce1d7d391ed2c"
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
