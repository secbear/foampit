#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

failures=0
passes=0

pkl_eval=(
  pkl eval
  --allowed-modules=file:
  --root-dir="$prototype_root"
  --no-project
  -f json
)

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

  if ! "${pkl_eval[@]}" "$prototype_root/cases/$fixture.pkl" \
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
  local fixture="$2"
  local invariant="$3"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if "${pkl_eval[@]}" "$prototype_root/cases/$fixture.pkl" \
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

expect_rendered_product_failure() {
  local case_name="$1"
  local fixture="$2"
  local invariant="$3"
  local rendered_file="$tmp_root/$case_name.rendered.json"
  local common_file="$tmp_root/$case_name.common.json"
  local portable_file="$tmp_root/$case_name.portable.json"
  local validation_file="$tmp_root/$case_name.validation.json"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! "${pkl_eval[@]}" "$prototype_root/cases/$fixture.pkl" \
    >"$rendered_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Pkl did not render the invalid candidate: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! jq -c '.result' "$rendered_file" >"$common_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Pkl result extraction failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! jq -c -f "$prototype_root/../comparison-portable-value.jq" \
    "$common_file" >"$portable_file" 2>"$stderr_file"; then
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
  local case_name="VAL-009 validated Pkl-to-W0-to-Nix package bridge"
  local rendered_file="$tmp_root/nix-bridge.rendered.json"
  local common_file="$tmp_root/nix-bridge.common.json"
  local portable_file="$tmp_root/nix-bridge.portable.json"
  local validation_file="$tmp_root/nix-bridge.validation.json"
  local manifest_file="$tmp_root/nix-bridge.validated.json"
  local stdout_file="$tmp_root/nix-bridge.stdout"
  local stderr_file="$tmp_root/nix-bridge.stderr"

  if ! "${pkl_eval[@]}" "$prototype_root/cases/valid-minimal.pkl" \
    >"$rendered_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Pkl evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  jq -c '.result' "$rendered_file" >"$common_file"

  if ! jq -c -f "$prototype_root/../comparison-portable-value.jq" \
    "$common_file" >"$portable_file" 2>"$stderr_file"; then
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
  '.result.profile.selected == "workspace-edit-offline"
   and .result.workspace.materialization == "copy"
   and .result.workspace.allowedMaterializations == ["copy"]
   and .result.workspace.access == "read-write"
   and .result.network.mode == "none"
   and .result.network.hardPolicy.allowedDestinations == []
   and .result.requiredCapabilities == ["network.none", "workspace.copy"]
   and (.result.runtimeProfiles | keys | sort) == ["bubblewrap-copy", "firecracker-copy"]
   and (.result.secrets | length) == 1
   and (.result.targets | sort) == ["bubblewrap", "firecracker"]'

expect_nix_bridge

expect_success \
  "D-PKL local import, defaults, hidden-and-local rendering, and typed Map" \
  "valid-default-hidden-local" \
  '.result.profile.selected == "workspace-edit-offline"
   and .result.workspace.materialization == "copy"
   and .result.network.mode == "none"
   and .result.environment.variables.PLUGIN__DYNAMIC_KEY == "accepted"
   and (has("rendererSecret") | not)
   and (has("input") | not)'

expect_success \
  "D-PKL module amends re-evaluates inherited output" \
  "valid-amends-output" \
  '.result.environment.variables.AMENDED == "yes"
   and .result.workspace.materialization == "copy"'

expect_success \
  "D-PKL module extends admits a new member and re-evaluates inherited output" \
  "valid-extends-output" \
  '.result.environment.variables.EXTENDED == "yes"
   and .result.workspace.materialization == "copy"
   and .extensionMetadata == "admitted-by-extends"'

expect_success \
  "D-PKL Dynamic accepts and renders an extension member" \
  "valid-dynamic-extra" \
  '.result.visible == "not-a-module-member"
   and .result.extensionField.accepted'

expect_success \
  "VAL-010 Firecracker copy creation" \
  "valid-firecracker-copy-creation" \
  '.result.runtimeProfile == "firecracker-copy"
   and .result.workspace.materialization == "copy"
   and .result.allocation.memoryBytes == 1073741824'

expect_failure \
  "STR-001 relative mount" \
  "invalid-relative-mount" \
  "artifact.mount.destination_absolute"

expect_failure \
  "STR-008 undeclared field" \
  "invalid-undeclared-field" \
  "Cannot find property"

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
  "CMP-008 amendment cannot bypass final validation" \
  "invalid-amendment-bypass" \
  "artifact.profile.explicit_conflict"

expect_failure \
  "D-PKL evaluator policy denies an external module reader" \
  "invalid-external-reader" \
  "Refusing to load module"

expect_rendered_product_failure \
  "D-PKL amended output corruption reaches and is rejected by W0" \
  "invalid-rendered-product" \
  "artifact.workspace.destination_absolute"

expect_rendered_product_failure \
  "D-PKL open-module extension corruption reaches and is rejected by W0" \
  "invalid-open-extends-product" \
  "artifact.workspace.destination_absolute"

if ((failures > 0)); then
  printf '%d test(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'all Pkl prototype tests passed (%d assertions)\n' "$passes"
