#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
schema_file="$prototype_root/schema/schema.cue"
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
  local fixture="$2"
  local jq_expression="$3"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! cue export "$schema_file" "$prototype_root/cases/$fixture.cue" \
    --expression output >"$stdout_file" 2>"$stderr_file"; then
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
  local fixture="$2"
  local invariant="$3"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if cue export "$schema_file" "$prototype_root/cases/$fixture.cue" \
    --expression output >"$stdout_file" 2>"$stderr_file"; then
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

expect_equal_export_orders() {
  local case_name="$1"
  local base_fixture="$2"
  local refinement_fixture="$3"
  local jq_expression="$4"
  local forward_file="$tmp_root/$case_name.forward"
  local reverse_file="$tmp_root/$case_name.reverse"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! cue export "$schema_file" \
    "$prototype_root/cases/$base_fixture.cue" \
    "$prototype_root/cases/$refinement_fixture.cue" \
    --expression output >"$forward_file" 2>"$stderr_file"; then
    record_failure "$case_name" "forward export failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! cue export "$schema_file" \
    "$prototype_root/cases/$refinement_fixture.cue" \
    "$prototype_root/cases/$base_fixture.cue" \
    --expression output >"$reverse_file" 2>"$stderr_file"; then
    record_failure "$case_name" "reverse export failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! jq -e "$jq_expression" "$forward_file" >/dev/null; then
    record_failure "$case_name" "forward result did not satisfy $jq_expression"
    return
  fi
  if ! cmp -s "$forward_file" "$reverse_file"; then
    record_failure "$case_name" "reversing package file order changed normalized export"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_conflicting_package_files() {
  local case_name="$1"
  local base_fixture="$2"
  local conflict_fixture="$3"
  local invariant="$4"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if cue export "$schema_file" \
    "$prototype_root/cases/$base_fixture.cue" \
    "$prototype_root/cases/$conflict_fixture.cue" \
    --expression output >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "conflicting package files unexpectedly exported"
    return
  fi
  if ! grep -F "$invariant" "$stderr_file" >/dev/null; then
    record_failure "$case_name" "missing invariant $invariant: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_rendered_product_failure() {
  local case_name="$1"
  local fixture="$2"
  local invariant="$3"
  local rendered_file="$tmp_root/$case_name.rendered.json"
  local portable_file="$tmp_root/$case_name.portable.json"
  local validation_file="$tmp_root/$case_name.validation.json"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! cue export "$schema_file" "$prototype_root/cases/$fixture.cue" \
    --expression output >"$rendered_file" 2>"$stderr_file"; then
    record_failure "$case_name" "CUE did not render the invalid candidate: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! jq -c -f "$prototype_root/../comparison-portable-value.jq" \
    "$rendered_file" >"$portable_file" 2>"$stderr_file"; then
    record_failure "$case_name" "adapter rejected before W0: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if cargo run --quiet \
    --manifest-path "$prototype_root/../wire-validator/Cargo.toml" \
    -- check "$portable_file" >"$validation_file" 2>"$stderr_file"; then
    record_failure "$case_name" "W0 unexpectedly accepted the rendered invalid candidate"
    return
  fi
  if ! grep -F "$invariant" "$stderr_file" >/dev/null; then
    record_failure "$case_name" "W0 diagnostic omitted $invariant: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_nix_bridge() {
  local case_name="VAL-009 validated CUE-to-W0-to-Nix package bridge"
  local rendered_file="$tmp_root/nix-bridge.rendered.json"
  local portable_file="$tmp_root/nix-bridge.portable.json"
  local validation_file="$tmp_root/nix-bridge.validation.json"
  local manifest_file="$tmp_root/nix-bridge.validated.json"
  local stdout_file="$tmp_root/nix-bridge.stdout"
  local stderr_file="$tmp_root/nix-bridge.stderr"

  if ! cue export "$schema_file" "$prototype_root/cases/valid-minimal.cue" \
    --expression output >"$rendered_file" 2>"$stderr_file"; then
    record_failure "$case_name" "CUE evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! jq -c -f "$prototype_root/../comparison-portable-value.jq" \
    "$rendered_file" >"$portable_file" 2>"$stderr_file"; then
    record_failure "$case_name" "portable-value adaptation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! cargo run --quiet \
    --manifest-path "$prototype_root/../wire-validator/Cargo.toml" \
    -- check "$portable_file" >"$validation_file" 2>"$stderr_file"; then
    record_failure "$case_name" "W0 validation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  jq -c '.artifact' "$validation_file" >"$manifest_file"

  if ! nix-instantiate --eval --strict --json "$prototype_root/../structured-nix-bridge.nix" \
    --argstr manifestJson "$(cat "$manifest_file")" \
    >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Nix bridge failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  if ! jq -e \
    '(.packages[0].storePath | startswith("/nix/store/"))
     and .packages[0].name == "hello"
     and .builderManifest.portableArtifact.requiredCapabilities == ["network.disabled", "workspace.copy"]
     and (.builderManifest.portableArtifact.runtimeProfiles | keys | sort) == ["bubblewrap-copy", "firecracker-copy"]
     and .builderManifest.portableArtifact.network.hardPolicy.allowedDestinations == []
     and (.builderDrvPath | endswith(".drv"))' \
    "$stdout_file" >/dev/null; then
    record_failure "$case_name" "bridge did not resolve a real package and derivation"
    return
  fi

  if ! jq -e \
    '.sha256 == "db4d9e1c788df52ba6274dd09c68d554c8bc623046f65b7e2b38d145039e4f22"' \
    "$validation_file" >/dev/null; then
    record_failure "$case_name" "W0 semantic digest differed from the common oracle"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_success \
  "VAL-001 minimal visible profile" \
  "valid-minimal" \
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

expect_nix_bridge

expect_success \
  "D-CUE concrete defaults, pattern field, import, and hidden rendering" \
  "valid-default-open-hidden" \
  '.profile.selected == "workspace-edit-offline"
   and .workspace.materialization == "copy"
   and .network.mode == "none"
   and .environment.variables.PLUGIN__DYNAMIC_KEY == "accepted"
   and .environment.variables.EDITOR == "vi"
   and (has("_normalizedEditor") | not)'

expect_equal_export_orders \
  "D-CUE package file order unifies to one normalized export" \
  "valid-order-base" \
  "valid-order-refinement" \
  '.environment.variables.ORDER_CONTROL == "unified"
   and .network.hardPolicy.allowedDestinations == ["api.example.test"]'

expect_conflicting_package_files \
  "D-CUE conflicting package files produce bottom in either order" \
  "valid-order-base" \
  "invalid-order-conflict" \
  "conflicting values"

expect_success \
  "VAL-010 Firecracker copy creation" \
  "valid-firecracker-copy-creation" \
  '.runtimeProfile == "firecracker-copy"
   and .workspace.materialization == "copy"
   and .allocation.memoryBytes == 1073741824'

expect_failure \
  "STR-001 relative mount" \
  "invalid-relative-mount" \
  "artifact.mount.destination_absolute"

expect_failure \
  "STR-008 undeclared field" \
  "invalid-undeclared-field" \
  "field not allowed"

expect_failure \
  "SUM-004 disabled network with egress" \
  "invalid-none-with-egress" \
  "artifact.network.none_has_no_egress"

expect_failure \
  "TGT-001 Firecracker-only live workspace" \
  "invalid-firecracker-only-live" \
  "artifact.target.required_capability_supported"

expect_failure \
  "TGT-002 Firecracker live creation" \
  "invalid-firecracker-live-creation" \
  "create.runtime_profile_supports_binding"

expect_failure \
  "CMP-002 hard-policy weakening" \
  "invalid-hard-policy-weakening" \
  "artifact.policy.monotonic_refinement"

expect_failure \
  "CMP-003 profile conflict" \
  "invalid-profile-conflict" \
  "artifact.profile.explicit_conflict"

expect_failure \
  "CMP-008 embedded field cannot bypass closed Artifact schema" \
  "invalid-embedded-unknown" \
  "field not allowed"

expect_failure \
  "D-CUE conflicting defaults do not select by source order" \
  "invalid-conflicting-default" \
  "incomplete value"

expect_rendered_product_failure \
  "D-CUE rendered output corruption reaches and is rejected by W0" \
  "invalid-rendered-product" \
  "artifact.workspace.destination_absolute"

if ((failures > 0)); then
  printf '%d test(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'all CUE prototype tests passed (%d assertions)\n' "$passes"
