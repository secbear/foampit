#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
nixpkgs_ref="github:NixOS/nixpkgs/62c8382960464ceb98ea593cb8321a2cf8f9e3e5"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

resolve_package() {
  nix build --no-link --print-out-paths "$nixpkgs_ref#$1"
}

cue_root="$(resolve_package cue)"
nickel_root="$(resolve_package nickel)"
pkl_root="$(resolve_package pkl)"
dhall_root="$(resolve_package dhall)"
dhall_json_root="$(resolve_package dhall-json)"

cargo build --quiet --release \
  --manifest-path "$prototype_root/wire-validator/Cargo.toml"
wire_validator_bin="$prototype_root/wire-validator/target/release/wire-validator-prototype"

printf 'Pinned evaluator closures\n'
for entry in \
  "cue:$cue_root" \
  "nickel:$nickel_root" \
  "pkl:$pkl_root" \
  "dhall:$dhall_root" \
  "dhall-json:$dhall_json_root"; do
  name="${entry%%:*}"
  path="${entry#*:}"
  printf '%-12s ' "$name"
  nix path-info -Sh "$path"
done

printf '\nPrototype source lines (implementation then fixtures/tests)\n'
printf 'nix          '
wc -l \
  "$prototype_root/nix-baseline/prototype.nix" \
  "$prototype_root/nix-baseline/cases.nix" \
  "$prototype_root/nix-baseline/test.sh" | tail -1
printf 'cue          '
wc -l \
  "$prototype_root/cue/schema/schema.cue" \
  "$prototype_root/cue/cases/"*.cue \
  "$prototype_root/cue/test.sh" | tail -1
printf 'nickel       '
wc -l \
  "$prototype_root/nickel/prototype.ncl" \
  "$prototype_root/nickel/cases/"*.ncl \
  "$prototype_root/nickel/test.sh" | tail -1
printf 'pkl          '
wc -l \
  "$prototype_root/pkl/prototype.pkl" \
  "$prototype_root/pkl/cases/"*.pkl \
  "$prototype_root/pkl/test.sh" | tail -1
printf 'dhall-control '
wc -l \
  "$prototype_root/dhall/prototype.dhall" \
  "$prototype_root/dhall/cases/"*.dhall \
  "$prototype_root/dhall/test.sh" | tail -1
printf 'wire-validator '
wc -l \
  "$prototype_root/wire-validator/src/main.rs" \
  "$prototype_root/wire-validator/fixtures/"*.json \
  "$prototype_root/wire-validator/test.sh" | tail -1

printf '\nThree fresh-process valid-evaluation timings (seconds)\n'
for iteration in 1 2 3; do
  printf 'iteration %s\n' "$iteration"
  (
    cd "$prototype_root/nix-baseline"
    /usr/bin/time -p nix eval --json "path:$PWD#cases.validMinimal" >/dev/null
  )
  (
    cd "$prototype_root/cue"
    /usr/bin/time -p "$cue_root/bin/cue" export \
      schema/schema.cue cases/valid-minimal.cue --expression output >/dev/null
  )
  (
    cd "$prototype_root/nickel"
    /usr/bin/time -p "$nickel_root/bin/nickel" export --format json \
      cases/valid-minimal.ncl >/dev/null
  )
  (
    cd "$prototype_root/pkl"
    /usr/bin/time -p "$pkl_root/bin/pkl" eval -f json \
      cases/valid-minimal.pkl >/dev/null
  )
  (
    cd "$prototype_root/dhall"
    /usr/bin/time -p "$dhall_json_root/bin/dhall-to-json" --file \
      cases/valid-minimal.dhall >/dev/null
  )
done

printf '\nThree fresh-process frontend-plus-W0-plus-Nix timings (seconds)\n'
for iteration in 1 2 3; do
  printf 'iteration %s\n' "$iteration"
  for candidate in nix nix-one-eval cue nickel pkl; do
    printf '%s\n' "$candidate"
    CUE_BIN="$cue_root/bin/cue" \
      NICKEL_BIN="$nickel_root/bin/nickel" \
      PKL_BIN="$pkl_root/bin/pkl" \
      JQ_BIN="$(command -v jq)" \
      WIRE_VALIDATOR_BIN="$wire_validator_bin" \
      /usr/bin/time -p bash "$prototype_root/run-valid-pipeline.sh" "$candidate" \
      >/dev/null
  done
done
