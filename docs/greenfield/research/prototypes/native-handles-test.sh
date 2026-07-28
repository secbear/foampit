#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
registry_file="$prototype_root/native-handles.nix"
bridge_file="$prototype_root/structured-nix-bridge.nix"
wire_manifest="$prototype_root/wire-validator/Cargo.toml"
wire_fixture="$prototype_root/wire-validator/fixtures/valid.json"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

nixpkgs_revision="62c8382960464ceb98ea593cb8321a2cf8f9e3e5"
target_system="$(nix eval --raw --impure --expr builtins.currentSystem)"
registry_digest="$(shasum -a 256 "$registry_file" | awk '{print $1}')"
source_closure_digest="$(
  jq -cjS -n \
    --arg registry_digest "$registry_digest" \
    --arg nixpkgs_revision "$nixpkgs_revision" \
    --arg system "$target_system" \
    '{
      nativeInterfaceVersion: 1,
      nativeRegistryDigest: $registry_digest,
      nixpkgsRevision: $nixpkgs_revision,
      registry: "prototype-native",
      registryVersion: 1,
      system: $system
    }' |
    shasum -a 256 |
    awk '{print $1}'
)"

cargo run --quiet --manifest-path "$wire_manifest" \
  -- check "$wire_fixture" |
  jq -c '.artifact' >"$tmp_root/validated-artifact.json"
validated_artifact="$(<"$tmp_root/validated-artifact.json")"

base_handles() {
  local guest_module="$1"
  jq -cn \
    --arg registry_digest "$registry_digest" \
    --arg source_closure_digest "$source_closure_digest" \
    --arg system "$target_system" \
    --arg guest_module "$guest_module" \
    '{
      registry: "prototype-native",
      registryVersion: 1,
      registryDigest: $registry_digest,
      sourceClosureDigest: $source_closure_digest,
      nativeInterfaceVersion: 1,
      targetSystem: $system,
      affectedMember: "firecracker",
      expectedSemanticEffects: [
        "environment.devShell",
        "guest.services"
      ],
      devShell: {
        handle: "project",
        exportAttribute: "devShells.project"
      },
      guestModules: [{
        handle: $guest_module,
        exportAttribute: ("guestModules." + $guest_module),
        expectedSemanticEffect: "guest.services",
        affectedMember: "firecracker"
      }]
    }'
}

run_bridge() {
  local handles_json="$1"
  local stdout_file="$2"
  local stderr_file="$3"
  nix-instantiate --eval --strict --json "$bridge_file" \
    --argstr manifestJson "$validated_artifact" \
    --argstr nativeHandlesJson "$handles_json" \
    >"$stdout_file" 2>"$stderr_file"
}

run_bridge_without_native() {
  local stdout_file="$1"
  local stderr_file="$2"
  nix-instantiate --eval --strict --json "$bridge_file" \
    --argstr manifestJson "$validated_artifact" \
    >"$stdout_file" 2>"$stderr_file"
}

expect_invalid_handle() {
  local case_name="$1"
  local handles_json="$2"
  local invariant="$3"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if run_bridge "$handles_json" "$stdout_file" "$stderr_file"; then
    printf 'not ok - %s unexpectedly succeeded\n' "$case_name" >&2
    exit 1
  fi
  grep -F "$invariant" "$stderr_file" >/dev/null
  printf 'ok - %s\n' "$case_name"
}

valid_handles="$(base_handles safe-service)"
valid_stdout="$tmp_root/valid.stdout"
valid_repeat_stdout="$tmp_root/valid-repeat.stdout"
valid_stderr="$tmp_root/valid.stderr"
without_native_stdout="$tmp_root/without-native.stdout"
without_native_stderr="$tmp_root/without-native.stderr"
if ! run_bridge "$valid_handles" "$valid_stdout" "$valid_stderr"; then
  printf 'not ok - native handle resolution: %s\n' "$(tr '\n' ' ' <"$valid_stderr")" >&2
  exit 1
fi
if ! run_bridge "$valid_handles" "$valid_repeat_stdout" "$valid_stderr"; then
  printf 'not ok - repeated native handle resolution: %s\n' "$(tr '\n' ' ' <"$valid_stderr")" >&2
  exit 1
fi
if ! run_bridge_without_native "$without_native_stdout" "$without_native_stderr"; then
  printf 'not ok - bridge without native handles: %s\n' \
    "$(tr '\n' ' ' <"$without_native_stderr")" >&2
  exit 1
fi

jq -e \
  --arg system "$target_system" \
  '.native.registry == "prototype-native"
   and .native.registryVersion == 1
   and .native.nativeInterfaceVersion == 1
   and .native.targetSystem == $system
   and .native.affectedMember == "firecracker"
   and .native.expectedSemanticEffects == ["environment.devShell", "guest.services"]
   and .native.devShell.handle == "project"
   and .native.devShell.exportAttribute == "devShells.project"
   and (.native.devShell.drvPath | endswith(".drv"))
   and .native.guestModules == [{
     handle: "safe-service",
     exportAttribute: "guestModules.safe-service",
     expectedSemanticEffect: "guest.services",
     affectedMember: "firecracker"
   }]
   and .native.guest.serviceNames == ["example"]
   and (.native.registryDigest | length) == 64
   and (.native.sourceClosureDigest | length) == 64
   and .builderManifest.nativeIdentity == .native' \
  "$valid_stdout" >/dev/null
printf 'ok - complete native identity resolves after W0 validation\n'

if cmp -s "$valid_stdout" "$valid_repeat_stdout"; then
  printf 'ok - identical native handle is construction-identity deterministic\n'
else
  printf 'not ok - identical native handle changed construction identity\n' >&2
  exit 1
fi

if jq -e -s \
  '.[0].builderManifest != .[1].builderManifest
   and .[0].builderDrvPath != .[1].builderDrvPath' \
  "$without_native_stdout" "$valid_stdout" >/dev/null; then
  printf 'ok - valid native handle changes builder content and derivation identity\n'
else
  printf 'not ok - valid native handle did not change builder content and derivation identity\n' >&2
  exit 1
fi

expect_invalid_handle \
  "unsafe native guest ownership" \
  "$(base_handles unsafe-host-share)" \
  "artifact.native_guest.owner_boundary"

expect_invalid_handle \
  "native registry digest mismatch" \
  "$(base_handles safe-service | jq -c '.registryDigest = ("0" * 64)')" \
  "artifact.native_handle.registry_digest_matches"

expect_invalid_handle \
  "native source closure mismatch" \
  "$(base_handles safe-service | jq -c '.sourceClosureDigest = ("0" * 64)')" \
  "artifact.native_handle.source_closure_digest_matches"

expect_invalid_handle \
  "native target system mismatch" \
  "$(base_handles safe-service | jq -c '.targetSystem = "wrong-system"')" \
  "artifact.native_handle.target_system_matches"

expect_invalid_handle \
  "native export attribute mismatch" \
  "$(base_handles safe-service | jq -c '.devShell.exportAttribute = "devShells.other"')" \
  "artifact.native_handle.export_attribute_matches"

expect_invalid_handle \
  "native affected member mismatch" \
  "$(base_handles safe-service | jq -c '.guestModules[0].affectedMember = "bubblewrap"')" \
  "artifact.native_handle.affected_member_matches"

expect_invalid_handle \
  "unknown native guest member" \
  "$(base_handles missing-module)" \
  "artifact.native_handle.guest_module_known"

printf 'native handle prototype: 10 cases passed\n'
