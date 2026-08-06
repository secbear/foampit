#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
invariant_root="${prototype_root}/../invariants"
nixpkgs_ref="github:NixOS/nixpkgs/62c8382960464ceb98ea593cb8321a2cf8f9e3e5"

nix shell "$nixpkgs_ref#jq" "$nixpkgs_ref#ripgrep" \
  --command bash "$invariant_root/check-inventory.sh"

bash "$prototype_root/nix-baseline/test.sh"

bash "$prototype_root/nix-resource-composition/test.sh"

nix shell "$nixpkgs_ref#cue" "$nixpkgs_ref#jq" \
  --command bash "$prototype_root/cue/test.sh"

nix shell "$nixpkgs_ref#nickel" "$nixpkgs_ref#jq" \
  --command bash "$prototype_root/nickel/test.sh"

nix shell "$nixpkgs_ref#pkl" "$nixpkgs_ref#jq" \
  --command bash "$prototype_root/pkl/test.sh"

nix shell "$nixpkgs_ref#dhall" "$nixpkgs_ref#dhall-json" "$nixpkgs_ref#jq" \
  --command bash "$prototype_root/dhall/test.sh"

bash "$prototype_root/native-handles-test.sh"

bash "$prototype_root/frontend-adaptation-test.sh"

bash "$prototype_root/wire-validator/test.sh"

bash "$prototype_root/resolved-reentry/test.sh"

bash "$prototype_root/downstream-boundaries/test.sh"

bash "$prototype_root/classification-lattice/test.sh"

nix shell \
  "$nixpkgs_ref#cue" \
  "$nixpkgs_ref#nickel" \
  "$nixpkgs_ref#pkl" \
  "$nixpkgs_ref#jq" \
  --command bash "$prototype_root/pipeline-equivalence-test.sh"
