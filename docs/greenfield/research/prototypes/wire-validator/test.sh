#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
manifest_path="$prototype_root/Cargo.toml"
fixtures="$prototype_root/fixtures"
generated_fixtures="$(mktemp -d)"
trap 'rm -rf "$generated_fixtures"' EXIT
pass_count=0

check_command() {
  cargo run --quiet --manifest-path "$manifest_path" -- check "$1"
}

expect_same_canonical_value() {
  local left="$1"
  local right="$2"
  local left_result
  local right_result

  left_result="$(check_command "$fixtures/$left")"
  right_result="$(check_command "$fixtures/$right")"

  if [[ "$left_result" != "$right_result" ]]; then
    echo "canonical output differed for $left and $right" >&2
    diff -u <(printf '%s\n' "$left_result") <(printf '%s\n' "$right_result") >&2 || true
    exit 1
  fi

  jq -e '
    .comparisonEncoding == "artifact-comparison-json-v0"
    and .sha256 == "db4d9e1c788df52ba6274dd09c68d554c8bc623046f65b7e2b38d145039e4f22"
    and .artifact.schemaVersion == {"major": 0, "minor": 1}
    and .artifact.workspace.allowedMaterializations == ["copy"]
    and .artifact.network.hardPolicy.allowedDestinations == []
    and .artifact.requiredCapabilities == ["network.disabled", "workspace.copy"]
    and (.artifact.runtimeProfiles | keys) == ["bubblewrap-copy", "firecracker-copy"]
  ' <<<"$left_result" >/dev/null

  pass_count=$((pass_count + 1))
}

expect_invalid() {
  local fixture="$1"
  local invariant="$2"
  local primary_path="$3"
  local related_path="${4:-}"
  local stdout_file
  local stderr_file
  local status
  local fixture_path="$fixture"

  if [[ "$fixture_path" != /* ]]; then
    fixture_path="$fixtures/$fixture_path"
  fi

  stdout_file="$(mktemp)"
  stderr_file="$(mktemp)"

  set +e
  check_command "$fixture_path" >"$stdout_file" 2>"$stderr_file"
  status=$?
  set -e

  if [[ "$status" -eq 0 ]]; then
    echo "expected $fixture to fail" >&2
    rm -f "$stdout_file" "$stderr_file"
    exit 1
  fi

  if [[ -s "$stdout_file" ]]; then
    echo "invalid fixture $fixture wrote to stdout" >&2
    rm -f "$stdout_file" "$stderr_file"
    exit 1
  fi

  if ! jq -e \
    --arg invariant "$invariant" \
    --arg path "$primary_path" \
    --arg related "$related_path" '
      .invariant == $invariant
      and .owner == "artifact"
      and .phase == "W0"
      and .severity == "error"
      and .primaryPath == $path
      and (.message | type == "string" and length > 0)
      and (.constraint | type == "string" and length > 0)
      and (.remediation | type == "string" and length > 0)
      and (.causeChain | type == "array")
      and (
        $related == ""
        or (.relatedPaths | index($related)) != null
      )
    ' "$stderr_file" >/dev/null; then
    echo "invalid fixture $fixture returned the wrong diagnostic" >&2
    cat "$stderr_file" >&2
    rm -f "$stdout_file" "$stderr_file"
    exit 1
  fi

  rm -f "$stdout_file" "$stderr_file"
  pass_count=$((pass_count + 1))
}

expect_same_canonical_value valid.json valid-reordered.json
expect_invalid invalid-duplicate-key.json wire.object_keys_unique '$.network.mode'
expect_invalid invalid-schema-major.json artifact.schema_version_supported '$.schemaVersion.major'
expect_invalid invalid-none-egress.json artifact.network.disabled_has_no_egress '$.network.egressAllow' '$.network.mode'
expect_invalid invalid-selected-materialization.json artifact.workspace.selected_materialization_allowed '$.workspace.materialization' '$.workspace.allowedMaterializations'
expect_invalid invalid-hard-policy-egress.json artifact.network.egress_refines_hard_policy '$.network.egressAllow' '$.network.hardPolicy.allowedDestinations'
expect_invalid invalid-required-capabilities.json artifact.required_capabilities.match_semantics '$.requiredCapabilities' '$.network.mode'
expect_invalid invalid-target-capability.json artifact.target.required_capability_supported '$.targets[0]' '$.requiredCapabilities'
expect_invalid invalid-runtime-profile-target.json artifact.runtime_profile.target_enabled '$.runtimeProfiles["firecracker-copy"].target' '$.targets'
expect_invalid invalid-runtime-profile-materialization.json artifact.runtime_profile.materializations_allowed '$.runtimeProfiles["bubblewrap-live"].materializations' '$.workspace.allowedMaterializations'
expect_invalid invalid-relative-destination.json artifact.workspace.destination_absolute '$.workspace.destination'
expect_invalid invalid-empty-targets.json artifact.targets.non_empty '$.targets'
expect_invalid invalid-unknown-field.json artifact.records.closed '$.workspace.destinaton' '$.workspace'
expect_invalid invalid-unregistered-extension.json artifact.extensions.registered '$.extensions["unregistered.example/unsafe"]' '$.extensions'
expect_invalid invalid-secret-value.json artifact.secrets.descriptors_only '$.secrets[0].value'
expect_invalid invalid-float-quantity.json artifact.resources.byte_quantity_integer '$.resources.memory.minimumBytes'

printf '{} {}\n' >"$generated_fixtures/invalid-trailing.json"
printf '{"value":"\xff"}\n' >"$generated_fixtures/invalid-utf8.json"
printf '9007199254740992\n' >"$generated_fixtures/invalid-unsafe-number.json"
printf '%s\n' '{"value":"\uD800"}' >"$generated_fixtures/invalid-lone-surrogate.json"
{
  for _ in $(seq 1 64); do printf '['; done
  printf 'null'
  for _ in $(seq 1 64); do printf ']'; done
  printf '\n'
} >"$generated_fixtures/valid-depth.json"
{
  for _ in $(seq 1 65); do printf '['; done
  printf 'null'
  for _ in $(seq 1 65); do printf ']'; done
  printf '\n'
} >"$generated_fixtures/invalid-depth.json"
head -c 1048577 /dev/zero | tr '\0' ' ' >"$generated_fixtures/invalid-oversize.json"
cp "$fixtures/valid.json" "$generated_fixtures/valid-exact-size.json"
valid_size="$(wc -c <"$generated_fixtures/valid-exact-size.json" | tr -d ' ')"
head -c "$((1048576 - valid_size))" /dev/zero |
  tr '\0' ' ' >>"$generated_fixtures/valid-exact-size.json"
jq --ascii-output \
  '.environment.variables.UNICODE = "😀"' \
  "$fixtures/valid.json" >"$generated_fixtures/valid-surrogate-pair.json"
jq \
  '.environment.variables.UNICODE = "é"' \
  "$fixtures/valid.json" >"$generated_fixtures/valid-unicode-composed.json"
jq \
  '.environment.variables.UNICODE = "é"' \
  "$fixtures/valid.json" >"$generated_fixtures/valid-unicode-decomposed.json"
depth_path='$'
for _ in $(seq 1 64); do depth_path+='[0]'; done

exact_size_result="$(check_command "$generated_fixtures/valid-exact-size.json")"
ordinary_size_result="$(check_command "$fixtures/valid.json")"
if [[ "$(wc -c <"$generated_fixtures/valid-exact-size.json" | tr -d ' ')" != "1048576" ]] ||
  [[ "$exact_size_result" != "$ordinary_size_result" ]]; then
  echo "exactly-at-limit input was not accepted as the same canonical value" >&2
  exit 1
fi
pass_count=$((pass_count + 1))

expect_invalid "$generated_fixtures/valid-depth.json" artifact.schema_shape '$.[0][0]'
expect_invalid "$generated_fixtures/invalid-trailing.json" wire.json_single_value '$'
expect_invalid "$generated_fixtures/invalid-utf8.json" wire.json_valid '$'
expect_invalid "$generated_fixtures/invalid-unsafe-number.json" wire.number_interoperable '$'
expect_invalid "$generated_fixtures/invalid-lone-surrogate.json" wire.json_valid '$'
expect_invalid "$generated_fixtures/invalid-depth.json" wire.nesting_depth_bounded "$depth_path"
expect_invalid "$generated_fixtures/invalid-oversize.json" wire.input_size_bounded '$'

surrogate_pair_result="$(check_command "$generated_fixtures/valid-surrogate-pair.json")"
if ! jq -e '.artifact.environment.variables.UNICODE == "😀"' \
  <<<"$surrogate_pair_result" >/dev/null; then
  echo "valid Unicode surrogate pair did not decode to its scalar value" >&2
  exit 1
fi
pass_count=$((pass_count + 1))

composed_result="$(check_command "$generated_fixtures/valid-unicode-composed.json")"
decomposed_result="$(check_command "$generated_fixtures/valid-unicode-decomposed.json")"
if jq -e -n \
  --argjson composed "$composed_result" \
  --argjson decomposed "$decomposed_result" \
  '$composed.sha256 == $decomposed.sha256
   or $composed.artifact.environment.variables.UNICODE != "é"
   or $decomposed.artifact.environment.variables.UNICODE != "é"' >/dev/null; then
  echo "Unicode normalization changed the locked accepted domain" >&2
  exit 1
fi
pass_count=$((pass_count + 1))

secret_marker="SUPER_SECRET_SHOULD_NOT_LEAK"
secret_stderr="$(mktemp)"
set +e
check_command "$fixtures/invalid-secret-value.json" >/dev/null 2>"$secret_stderr"
secret_status=$?
set -e

if [[ "$secret_status" -eq 0 ]] || rg -F "$secret_marker" "$secret_stderr" >/dev/null; then
  echo "secret-value diagnostic did not fail safely" >&2
  rm -f "$secret_stderr"
  exit 1
fi

rm -f "$secret_stderr"
pass_count=$((pass_count + 1))

echo "wire validator prototype: $pass_count cases passed"
