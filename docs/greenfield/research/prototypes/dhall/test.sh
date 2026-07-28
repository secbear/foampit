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

  if ! dhall-to-json --file "$prototype_root/cases/$fixture.dhall" \
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
  local expected_text="$3"
  local stdout_file="$tmp_root/$case_name.stdout"
  local stderr_file="$tmp_root/$case_name.stderr"

  if dhall-to-json --file "$prototype_root/cases/$fixture.dhall" \
    >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "evaluation unexpectedly succeeded"
    return
  fi

  if ! grep -F "$expected_text" "$stderr_file" >/dev/null; then
    record_failure "$case_name" "missing error text $expected_text: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_normalized_equal() {
  local case_name="$1"
  local left_fixture="$2"
  local right_fixture="$3"
  local left_file="$tmp_root/$case_name.left"
  local right_file="$tmp_root/$case_name.right"
  local stderr_file="$tmp_root/$case_name.stderr"

  if ! dhall --file "$prototype_root/cases/$left_fixture.dhall" \
    >"$left_file" 2>"$stderr_file"; then
    record_failure "$case_name" "left normalization failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! dhall --file "$prototype_root/cases/$right_fixture.dhall" \
    >"$right_file" 2>"$stderr_file"; then
    record_failure "$case_name" "right normalization failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  if ! cmp -s "$left_file" "$right_file"; then
    record_failure "$case_name" "semantically equivalent expressions normalized differently"
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

  if ! dhall-to-json --file "$prototype_root/cases/$fixture.dhall" \
    >"$rendered_file" 2>"$stderr_file"; then
    record_failure "$case_name" "Dhall did not render the invalid candidate: $(tr '\n' ' ' <"$stderr_file")"
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

expect_semantic_freeze() {
  local case_name="Dhall semantic import freeze is stable"
  local first_file="$tmp_root/freeze-first"
  local second_file="$tmp_root/freeze-second"
  local stderr_file="$tmp_root/freeze.stderr"

  if ! (
    cd "$prototype_root/cases"
    printf './valid-minimal.dhall\n' | dhall freeze --all
  ) >"$first_file" 2>"$stderr_file"; then
    record_failure "$case_name" "first freeze failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  (
    cd "$prototype_root/cases"
    printf './valid-minimal.dhall\n' | dhall freeze --all
  ) >"$second_file" 2>"$stderr_file"

  if ! cmp -s "$first_file" "$second_file"; then
    record_failure "$case_name" "semantic freeze output changed"
    return
  fi
  if ! grep -F "sha256:" "$first_file" >/dev/null; then
    record_failure "$case_name" "freeze output did not contain a semantic hash"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_changed_frozen_import_failure() {
  local case_name="D-DHALL changed frozen import fails semantic integrity"
  local case_root="$tmp_root/changed-frozen-import"
  local source_file="$case_root/source.dhall"
  local frozen_file="$case_root/frozen.dhall"
  local stdout_file="$case_root/stdout"
  local stderr_file="$case_root/stderr"

  mkdir -p "$case_root"
  cp "$prototype_root/cases/normalization-value.dhall" "$source_file"
  if ! (
    cd "$case_root"
    printf './source.dhall\n' |
      XDG_CACHE_HOME="$case_root/freeze-cache" dhall freeze --all
  ) >"$frozen_file" 2>"$stderr_file"; then
    record_failure "$case_name" "freeze failed: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi
  printf '{ answer = 3, nested = { enabled = True } }\n' >"$source_file"

  if XDG_CACHE_HOME="$case_root/check-cache" \
    dhall --file "$frozen_file" >"$stdout_file" 2>"$stderr_file"; then
    record_failure "$case_name" "changed frozen import unexpectedly succeeded"
    return
  fi
  if ! grep -F "Import integrity check failed" "$stderr_file" >/dev/null; then
    record_failure "$case_name" "missing integrity diagnostic: $(tr '\n' ' ' <"$stderr_file")"
    return
  fi

  passes=$((passes + 1))
  printf 'ok - %s\n' "$case_name"
}

expect_success \
  "Dhall closed-union valid Artifact control" \
  "valid-minimal" \
  '.profile.selected == "workspace-edit-offline"
   and .workspace.materialization == "copy"
   and .network.mode == "none"'

expect_failure \
  "Dhall assertion rejects hard-policy weakening" \
  "invalid-hard-policy-weakening" \
  "Assertion failed"

expect_failure \
  "Dhall right-biased update cannot bypass final assertion" \
  "invalid-right-biased-weakening" \
  "Assertion failed"

expect_failure \
  "Dhall recursive record merge rejects collision" \
  "invalid-recursive-collision" \
  "Field collision"

expect_success \
  "D-DHALL explicit selection overrides a product-owned default" \
  "valid-default-selection" \
  '.defaulted == "workspace-edit-offline"
   and .selected == "workspace-live-development"'

expect_success \
  "D-DHALL imported value is explicitly selected by right-biased preference" \
  "valid-import-preference" \
  '.profile.selected == "workspace-live-development"
   and .workspace.materialization == "live"'

expect_failure \
  "D-DHALL closed input record rejects an undeclared field" \
  "invalid-extra-field" \
  "Wrong type of function argument"

expect_success \
  "D-DHALL lexical module values stay out of JSON rendering" \
  "valid-lexical-scope" \
  '.visible == "available-during-evaluation"
   and (. | has("rendererSecret") | not)'

expect_normalized_equal \
  "D-DHALL import expansion and normalization are deterministic" \
  "valid-normalization-import" \
  "valid-normalization-inline"

expect_semantic_freeze

expect_changed_frozen_import_failure

expect_rendered_product_failure \
  "D-DHALL normalized JSON corruption reaches and is rejected by W0" \
  "invalid-rendered-product" \
  "artifact.workspace.destination_absolute"

if ((failures > 0)); then
  printf '%d test(s) failed\n' "$failures" >&2
  exit 1
fi

printf 'all Dhall control tests passed (%d assertions)\n' "$passes"
