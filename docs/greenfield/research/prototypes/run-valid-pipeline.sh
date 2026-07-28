#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
candidate="${1:?usage: run-valid-pipeline.sh nix|nix-one-eval|cue|nickel|pkl}"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

jq_bin="${JQ_BIN:-jq}"
wire_validator_bin="${WIRE_VALIDATOR_BIN:-}"
common_file="$tmp_root/common.json"
portable_file="$tmp_root/portable.json"
validation_file="$tmp_root/validation.json"
validated_file="$tmp_root/validated.json"
nix_result_file="$tmp_root/nix-result.json"
one_evaluation_nix_result=""

case "$candidate" in
  nix)
    nix eval \
      --json \
      --no-write-lock-file \
      "path:$prototype_root/nix-baseline#cases.validMinimal.portableValue" \
      >"$portable_file"
    ;;
  nix-one-eval)
    nix eval \
      --json \
      --no-write-lock-file \
      "path:$prototype_root/nix-baseline#cases.validMinimal" \
      >"$common_file"
    "$jq_bin" -c '.portableValue' "$common_file" >"$portable_file"
    one_evaluation_nix_result="$common_file"
    ;;
  cue)
    "${CUE_BIN:-cue}" export \
      "$prototype_root/cue/schema/schema.cue" \
      "$prototype_root/cue/cases/valid-minimal.cue" \
      --expression output >"$common_file"
    "$jq_bin" -c -f "$prototype_root/comparison-portable-value.jq" \
      "$common_file" >"$portable_file"
    ;;
  nickel)
    "${NICKEL_BIN:-nickel}" export --format json \
      "$prototype_root/nickel/cases/valid-minimal.ncl" >"$common_file"
    "$jq_bin" -c -f "$prototype_root/comparison-portable-value.jq" \
      "$common_file" >"$portable_file"
    ;;
  pkl)
    "${PKL_BIN:-pkl}" eval -f json \
      "$prototype_root/pkl/cases/valid-minimal.pkl" |
      "$jq_bin" -c '.result' >"$common_file"
    "$jq_bin" -c -f "$prototype_root/comparison-portable-value.jq" \
      "$common_file" >"$portable_file"
    ;;
  *)
    echo "unknown candidate: $candidate" >&2
    exit 64
    ;;
esac

if [[ -n "$wire_validator_bin" ]]; then
  "$wire_validator_bin" check "$portable_file" >"$validation_file"
else
  cargo run --quiet \
    --manifest-path "$prototype_root/wire-validator/Cargo.toml" \
    -- check "$portable_file" >"$validation_file"
fi

"$jq_bin" -c '.artifact' "$validation_file" >"$validated_file"

if [[ -n "$one_evaluation_nix_result" ]]; then
  "$jq_bin" -c '{
    builderDrvPath,
    builderManifest,
    packages: .environment.packages
  }' "$one_evaluation_nix_result" >"$nix_result_file"
else
  nix-instantiate --eval --strict --json \
    "$prototype_root/structured-nix-bridge.nix" \
    --argstr manifestJson "$(<"$validated_file")" >"$nix_result_file"
fi

"$jq_bin" -cn \
  --arg candidate "$candidate" \
  --slurpfile validation "$validation_file" \
  --slurpfile nixResult "$nix_result_file" \
  '{
    candidate: $candidate,
    semanticDigest: $validation[0].sha256,
    builderDrvPath: $nixResult[0].builderDrvPath,
    packageStorePaths: [$nixResult[0].packages[].storePath]
  }'
