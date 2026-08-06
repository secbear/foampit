#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
temporary_root="$(mktemp -d)"
trap 'rm -rf "${temporary_root}"' EXIT
expected_pass_count=19

cd "${prototype_root}"
output="$(CARGO_TARGET_DIR="${temporary_root}/target" cargo run --quiet --offline)"
echo "${output}"

observed="$(printf '%s\n' "${output}" | sed -n 's/^post-launch enforcement slice: \([0-9]*\) checks passed$/\1/p')"
if [[ "${observed}" != "${expected_pass_count}" ]]; then
  echo "FAIL: expected ${expected_pass_count} checks, observed ${observed:-none}" >&2
  exit 1
fi

# The findings are the deliverable; a run that loses them is a failed run.
for finding in F1 F2 F3 F4 F5; do
  if ! grep -q "^## ${finding}\." "${prototype_root}/FINDINGS.md"; then
    echo "FAIL: FINDINGS.md is missing ${finding}" >&2
    exit 1
  fi
done

echo "post-launch enforcement slice: ${observed} checks, 5 findings recorded"
