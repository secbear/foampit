#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
wire_root="$(dirname "${prototype_root}")/wire-validator"
input_path="${1:?usage: migrate.sh INPUT.json}"
temporary_root="$(mktemp -d)"
trap 'rm -rf "${temporary_root}"' EXIT

# Validate the closed source-version envelope before interpreting its payload.
jq -e -f "${prototype_root}/validate-migration.jq" \
  "${input_path}" >"${temporary_root}/versioned-candidate.json"
jq -e '.artifact' "${input_path}" >"${temporary_root}/source-artifact.json"

# This prototype's v0-to-v1 migration changes only the versioned envelope. The
# semantic payload therefore has the same schema on both sides, allowing the
# same product validator to prove both the old input and the migrated result.
cargo run --quiet --manifest-path "${wire_root}/Cargo.toml" -- \
  check "${temporary_root}/source-artifact.json" \
  | jq -e '.artifact' >"${temporary_root}/validated-source-artifact.json"

jq -n \
  --slurpfile artifact "${temporary_root}/validated-source-artifact.json" \
  '{schemaVersion: 1, artifact: $artifact[0]}' \
  >"${temporary_root}/migrated.json"
jq -e '.artifact' "${temporary_root}/migrated.json" \
  >"${temporary_root}/migrated-artifact.json"
cargo run --quiet --manifest-path "${wire_root}/Cargo.toml" -- \
  check "${temporary_root}/migrated-artifact.json" >/dev/null

jq -S . "${temporary_root}/migrated.json"
