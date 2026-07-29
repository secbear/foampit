#!/usr/bin/env bash
set -euo pipefail

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
repository="$(git -C "$here" rev-parse --show-toplevel)"
base_commit="6462aa751470cdd08d49f1792432871a17d35fb3"
patch_sha256="12113c290d212c74b10ca0c8f20a3475837e8fbff631b62c572566b533fee107"
patch="$here/test-only.patch"
expected="$here/raw-output.txt"
temporary="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-red-replay.XXXXXX")"
checkout="$temporary/base"
observed="$temporary/raw-output.txt"
worktree_added=0

cleanup() {
  if (( worktree_added == 1 )); then
    git -C "$repository" worktree remove --force "$checkout" >/dev/null 2>&1 || true
  fi
  if [[ -d "$temporary" ]]; then
    find "$temporary" -depth -delete
  fi
}
trap cleanup EXIT

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
nix develop "$spike" --command bash \
  "$spike/fix-round-1-red-replay/driver.sh" >"$observed"

if ! cmp -s "$expected" "$observed"; then
  echo "RED replay raw output mismatch" >&2
  diff -u "$expected" "$observed" >&2 || true
  exit 1
fi

echo "RED replay bundle: PASS base=$base_commit patchSha256=$patch_sha256"
