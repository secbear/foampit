#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

failures=0
passes=0

record_failure() {
  local case_name="$1"
  local reason="$2"
  failures=$((failures + 1))
  printf 'not ok - %s: %s\n' "$case_name" "$reason"
}

expect_success() {
  local case_name="$1"
  local attribute="$2"
  local jq_expression="$3"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! nix eval \
    --json \
    --no-write-lock-file \
    "path:$prototype_root#$attribute" \
    >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! jq -e "$jq_expression" "$stdout_file" >/dev/null; then
    record_failure "$case_name" "result did not satisfy $jq_expression"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_failure() {
  local case_name="$1"
  local attribute="$2"
  local invariant="$3"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if nix eval \
    --json \
    --no-write-lock-file \
    "path:$prototype_root#$attribute" \
    >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "evaluation unexpectedly succeeded"
    return
  fi

  if ! grep -F "$invariant" "$stderr_file" >/dev/null; then
    record_failure "$case_name" "missing invariant $invariant: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_equal_attributes() {
  local case_name="$1"
  local left_attribute="$2"
  local right_attribute="$3"
  local left_file="$tmp_root/$case_name.left"
  local right_file="$tmp_root/$case_name.right"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! nix eval --json --no-write-lock-file \
    "path:$prototype_root#$left_attribute" >"$left_file" 2>"$stderr_file"; then
    record_failure "$case_name" "left evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! nix eval --json --no-write-lock-file \
    "path:$prototype_root#$right_attribute" >"$right_file" 2>"$stderr_file"; then
    record_failure "$case_name" "right evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! cmp -s "$left_file" "$right_file"; then
    record_failure "$case_name" "reversing import order changed the evaluated value"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_pinned_nixpkgs_input() {
  local case_name="D-NIX frozen nixpkgs input identity"
  local stdout_file="$tmp_root/nixpkgs-input.stdout"
  local stderr_file="$tmp_root/nixpkgs-input.stderr"

  if ! nix flake metadata --json --no-write-lock-file "path:$prototype_root" \
    >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "flake metadata failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! jq -e \
    '.locks.nodes.nixpkgs.locked.rev == "62c8382960464ceb98ea593cb8321a2cf8f9e3e5"
     and (.locks.nodes.nixpkgs.locked.narHash | startswith("sha256-"))' \
    "$stdout_file" >/dev/null; then
    record_failure "$case_name" "nixpkgs import is not locked by revision and content hash"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_w0_nix_bridge() {
  local case_name="VAL-009 validated Nix-to-W0-to-Nix package bridge"
  local portable_file="$tmp_root/nix-w0.portable.json"
  local validation_file="$tmp_root/nix-w0.validation.json"
  local manifest_file="$tmp_root/nix-w0.validated.json"
  local stdout_file="$tmp_root/nix-w0.stdout"
  local stderr_file="$tmp_root/nix-w0.stderr"

  if ! nix eval \
    --json \
    --no-write-lock-file \
    "path:$prototype_root#cases.validMinimal.portableValue" \
    >"$portable_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Nix portable-value evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! cargo run --quiet \
    --manifest-path "$prototype_root/../wire-validator/Cargo.toml" \
    -- check "$portable_file" >"$validation_file" 2>"$stderr_file"; then
    record_failure "$case_name" "W0 validation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! jq -e \
    '.sha256 == "db4d9e1c788df52ba6274dd09c68d554c8bc623046f65b7e2b38d145039e4f22"' \
    "$validation_file" >/dev/null; then
    record_failure "$case_name" "W0 semantic digest differed from the common oracle"
    return
  fi

  jq -c '.artifact' "$validation_file" >"$manifest_file"
  if ! nix-instantiate --eval --strict --json \
    "$prototype_root/../structured-nix-bridge.nix" \
    --argstr manifestJson "$(cat "$manifest_file")" \
    >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Nix bridge failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! jq -e \
    '(.packages[0].storePath | startswith("/nix/store/"))
     and .packages[0].name == "hello"
     and (.builderDrvPath | endswith(".drv"))' \
    "$stdout_file" >/dev/null; then
    record_failure "$case_name" "bridge did not resolve the validated reference"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_success \
  "VAL-001 minimal visible profile" \
  "cases.validMinimal" \
  '.profile.selected == "workspace-edit-offline"
   and .workspace.materialization == "copy"
   and .workspace.allowedMaterializations == ["copy"]
   and .workspace.access == "read-write"
   and .network.mode == "none"
   and .network.hardPolicy.allowedDestinations == []
   and .requiredCapabilities == ["network.none", "workspace.copy"]
   and (.runtimeProfiles | keys | sort) == ["bubblewrap-copy", "firecracker-copy"]
   and (.secrets | length) == 1
   and (.targets | sort) == ["bubblewrap", "firecracker"]'

expect_success \
  "VAL-002 refinement and provenance" \
  "cases.validRefinement" \
  '.resources.memory.minimumBytes == 1073741824
   and .resources.memory.maximumBytes == 2147483648
   and (.provenance."resources.memory.minimumBytes" | length) == 2'

expect_success \
  "VAL-002 monotonic policy refinement provenance" \
  "cases.validPolicyRefinementForward" \
  '.network.hardPolicy.allowedDestinations == ["api.example.test"]
   and .provenance."network.policyDefinitions".highestPriority == 100
   and (.provenance."network.policyDefinitions".contributors | length) == 2'

expect_equal_attributes \
  "CMP-007 policy import order is semantic-neutral" \
  "cases.validPolicyRefinementForward.portableValue" \
  "cases.validPolicyRefinementReverse.portableValue"

expect_success \
  "D-NIX mkDefault loses to explicit visible selection" \
  "cases.validDefaultLosesToExplicitSelection" \
  '.profile.selected == "workspace-edit-offline"
   and .workspace.materialization == "copy"
   and .network.mode == "none"'

expect_success \
  "D-NIX mkOrder orders surviving list definitions" \
  "cases.validOrderedActivation" \
  '.environment.activation == ["prepare", "bash", "finish"]'

expect_success \
  "D-NIX attrsOf accepts a declared dynamic variable key" \
  "cases.validDynamicVariable" \
  '.environment.variables.PLUGIN__DYNAMIC_KEY == "accepted"'

expect_success \
  "D-NIX raw guest service data has no host authority" \
  "cases.validRawGuestDataHasNoHostAuthority" \
  '.guest.serviceNames == ["worker"]'

expect_success \
  "D-NIX _module.args contributes through declared options" \
  "cases.validModuleArgsContribution" \
  '.environment.variables.MODULE_ARG == "from-module-args"'

expect_success \
  "D-NIX specialArgs resolves a valid import before the fixed point" \
  "cases.validSpecialArgsImport" \
  '.network.hardPolicy.allowedDestinations == ["api.example.test"]
   and (.provenance."network.policyDefinitions".contributors | length) == 2'

expect_success \
  "D-NIX unused lazy module argument remains unforced" \
  "cases.validLazyUnusedModuleArgument" \
  '.profile.selected == "workspace-edit-offline"'

expect_success \
  "VAL-009 real Nix package reference" \
  "cases.validMinimal" \
  '(.environment.packages[0].storePath | startswith("/nix/store/"))
   and .environment.packages[0].name == "hello"'

expect_success \
  "D-NIX internal native values are absent from portable serialization" \
  "cases.validMinimal" \
  '(.portableValue.environment.packages[0] | keys) == ["source"]
   and (.portableValue | has("nativeGuestModules") | not)
   and (.environment.packages[0] | has("storePath"))'

expect_w0_nix_bridge
expect_pinned_nixpkgs_input

expect_success \
  "VAL-010 Firecracker copy creation" \
  "cases.validFirecrackerCopyCreation" \
  '.runtimeProfile == "firecracker-copy"
   and .workspace.materialization == "copy"
   and .allocation.memoryBytes == 1073741824'

expect_failure \
  "STR-001 relative mount" \
  "cases.invalidRelativeMount" \
  "artifact.mount.destination_absolute"

expect_failure \
  "SUM-004 disabled network with egress" \
  "cases.invalidNoneWithEgress" \
  "artifact.network.none_has_no_egress"

expect_failure \
  "TGT-001 Firecracker-only live workspace" \
  "cases.invalidFirecrackerOnlyLive" \
  "artifact.target.required_capability_supported"

expect_failure \
  "TGT-002 Firecracker live creation" \
  "cases.invalidFirecrackerLiveCreation" \
  "create.runtime_profile_supports_binding"

expect_failure \
  "CMP-002 hard-policy weakening" \
  "cases.invalidHardPolicyWeakening" \
  "artifact.policy.monotonic_refinement"

expect_failure \
  "NIX-001 native package matches portable reference" \
  "cases.invalidPackageReferenceMismatch" \
  "artifact.nix.package_reference_matches_value"

expect_failure \
  "CMP-003 profile conflict" \
  "cases.invalidProfileConflict" \
  "artifact.profile.explicit_conflict"

expect_failure \
  "CMP-005 guest claims host ownership" \
  "cases.invalidGuestHostShare" \
  "artifact.native_guest.owner_boundary"

expect_failure \
  "D-NIX closed module rejects an undeclared option" \
  "cases.invalidUndeclaredOption" \
  "workspace.materalization"

expect_failure \
  "D-NIX _module.args cannot widen hard policy" \
  "cases.invalidModuleArgsPolicyBypass" \
  "artifact.policy.monotonic_refinement"

expect_failure \
  "D-NIX specialArgs import cannot widen hard policy" \
  "cases.invalidSpecialArgsImportBypass" \
  "artifact.policy.monotonic_refinement"

expect_failure \
  "D-NIX required rendered value forces a delayed failure" \
  "cases.invalidLazyFinalValue" \
  "artifact.final_value_deep_forced"

expect_failure \
  "CMP-008 mkForce cannot bypass final validation" \
  "cases.invalidForcedProfileBypass" \
  "artifact.profile.explicit_conflict"

expect_failure \
  "CMP-002 priority stronger than mkForce cannot replace hard policy" \
  "cases.invalidStrongerThanForcePolicyBypass" \
  "artifact.policy.override_priority_forbidden"

expect_failure \
  "XRS-001 allocation below minimum" \
  "cases.invalidCreationBelowMinimum" \
  "create.allocation.within_artifact_bounds"

if ((failures > 0)); then
  printf '%d test(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'all nix-baseline prototype tests passed (%d assertions)\n' "$passes"
