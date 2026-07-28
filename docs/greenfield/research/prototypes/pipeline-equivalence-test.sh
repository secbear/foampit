#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT
results_file="$tmp_root/results.jsonl"

for candidate in nix nix-one-eval cue nickel pkl; do
  bash "$prototype_root/run-valid-pipeline.sh" "$candidate" >>"$results_file"
done

jq -se '
  (map(.semanticDigest) | unique | length) == 1
  and (map(.builderDrvPath) | unique | length) == 1
  and (map(.packageStorePaths) | unique | length) == 1
  and (map(.candidate) | sort) == ["cue", "nickel", "nix", "nix-one-eval", "pkl"]
' "$results_file" >/dev/null

echo "pipeline equivalence: serialized/one-eval Nix, CUE, Nickel, and Pkl produced one W0 digest and Nix output"
