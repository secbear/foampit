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
  local fixture="$2"
  local jq_expression="$3"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! nickel export --format json "$prototype_root/cases/$fixture.ncl" \
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

  if nickel export --format json "$prototype_root/cases/$fixture.ncl" \
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

expect_lazy_contract_boundary() {
  local case_name="$1"
  local fixture="$2"
  local invariant="$3"
  local visible_file="$tmp_root/$case_name.visible"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! nickel export --format json --field visible \
    "$prototype_root/cases/$fixture.ncl" >"$visible_file" 2>"$stderr_file"; then
    record_failure "$case_name" "unrelated field forced delayed contract: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! jq -e '. == true' "$visible_file" >/dev/null; then
    record_failure "$case_name" "visible control field did not serialize"
    return
  fi
  if nickel export --format json "$prototype_root/cases/$fixture.ncl" \
    >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "full export did not force delayed contract"
    return
  fi
  if ! grep -F "$invariant" "$stderr_file" >/dev/null; then
    record_failure "$case_name" "full export omitted $invariant: $(tr '\n' ' ' <"$stderr_file")"
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

  if ! nickel export --format json "$prototype_root/cases/$fixture.ncl" \
    >"$rendered_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Nickel did not render the invalid candidate: $(tr '\n' ' ' <"$stderr_file")"
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
  local case_name="VAL-009 validated Nickel-to-W0-to-Nix package bridge"
  local rendered_file="$tmp_root/nix-bridge.rendered.json"
  local portable_file="$tmp_root/nix-bridge.portable.json"
  local validation_file="$tmp_root/nix-bridge.validation.json"
  local manifest_file="$tmp_root/nix-bridge.validated.json"
  local stdout_file="$tmp_root/nix-bridge.stdout"
  local stderr_file="$tmp_root/nix-bridge.stderr"

  if ! nickel export --format json "$prototype_root/cases/valid-minimal.ncl" \
    >"$rendered_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Nickel evaluation failed: $(tr '\n' ' ' <"$stderr_file")"
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
  "D-NICKEL local import, defaults, and dynamic pattern field" \
  "valid-default-dynamic-import" \
  '.profile.selected == "workspace-edit-offline"
   and .workspace.materialization == "copy"
   and .network.mode == "none"
   and .environment.variables.PLUGIN__DYNAMIC_KEY == "accepted"'

expect_success \
  "D-NICKEL ordinary selection wins over a default" \
  "valid-priority-default" \
  '.profile.selected == "workspace-edit-offline"
   and .workspace.materialization == "copy"'

expect_success \
  "D-NICKEL recursive merge preserves declared nested values" \
  "valid-recursive-merge" \
  '.environment.variables.RECURSIVE_MERGE == "preserved"
   and .environment.variables.PLUGIN__DYNAMIC_KEY == "accepted"'

expect_success \
  "D-NICKEL lexical and not_exported fields stay out of serialization" \
  "valid-not-exported" \
  '.visible == "available-during-evaluation"
   and (. | has("hidden") | not)
   and .nested.kept
   and (.nested | has("hidden") | not)'

expect_lazy_contract_boundary \
  "D-NICKEL full export forces a delayed contract" \
  "invalid-delayed-contract" \
  "contract broken by the value"

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
  "extra field"

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
  "CMP-008 force cannot bypass final validation" \
  "invalid-force-bypass" \
  "artifact.policy.monotonic_refinement"

expect_failure \
  "D-NICKEL imported dynamic record cannot add a closed field" \
  "invalid-import-closed-field" \
  "extra field"

expect_failure \
  "D-NICKEL numeric priority wins merge but cannot bypass final validation" \
  "invalid-numeric-priority-bypass" \
  "artifact.policy.monotonic_refinement"

expect_rendered_product_failure \
  "D-NICKEL serialization corruption reaches and is rejected by W0" \
  "invalid-rendered-product" \
  "artifact.workspace.destination_absolute"

if ((failures > 0)); then
  printf '%d test(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'all Nickel prototype tests passed (%d assertions)\n' "$passes"
