#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
parent_root="$(dirname "${prototype_root}")"
repository_root="$(CDPATH= cd -- "${prototype_root}/../../../../.." && pwd)"
catalog="${repository_root}/docs/greenfield/research/invariants/PACKET-D-CASE-CONTRACTS.json"
downstream_validator="${parent_root}/downstream-boundaries/validate-resolved-driver.jq"
manifest="${prototype_root}/Cargo.toml"
temporary_root="$(mktemp -d)"
target_root="${temporary_root}/target"
trap 'rm -rf "${temporary_root}"' EXIT
expected_pass_count=13
expected_safe_diagnostic_probe_count=18
expected_prepared_identity_probe_count=8
expected_generated_projection_probe_count=44
expected_semantic_revalidation_probe_count=6
pass_count=0
safe_diagnostic_probe_count=0
prepared_identity_probe_count=0
generated_projection_probe_count=0
semantic_revalidation_probe_count=0
safe_probe_markers=()
leak_markers=(
  "serialized-secret-token"
  "LEAK-MARKER-UNKNOWN-ROOT"
  "LEAK-MARKER-UNKNOWN-NESTED"
  "LEAK-MARKER-DUPLICATE-ROOT"
  "LEAK-MARKER-DUPLICATE-NESTED"
  "LEAK-MARKER-VALUE"
  "LEAK-MARKER-DEEP"
  "LEAK-MARKER-WIRE-JSON"
  "LEAK-MARKER-BUILT-MISSING"
  "LEAK-MARKER-BUILT-EXTRA"
  "LEAK-MARKER-BUILT-DUPLICATE"
  "LEAK-MARKER-BUILT-REORDERED"
  "LEAK-MARKER-REPLAY-DUPLICATE"
  "LEAK-MARKER-REPLAY-OBJECT-KEY"
  "LEAK-MARKER-REPLAY-JSON"
  "LEAK-MARKER-RESOLVED-MISSING"
  "LEAK-MARKER-RESOLVED-EXTRA"
  "LEAK-MARKER-RESOLVED-DUPLICATE"
  "LEAK-MARKER-RESOLVED-REORDERED"
  "LEAK-MARKER-SEMANTIC-ARTIFACT"
  "LEAK-MARKER-SEMANTIC-MEMBER"
  "LEAK-MARKER-SEMANTIC-CREATE"
  "LEAK-MARKER-SEMANTIC-POLICY"
  "LEAK-MARKER-SEMANTIC-PROFILE"
  "LEAK-MARKER-SEMANTIC-SOURCE"
  "LEAK-MARKER-PREPARED-MALFORMED"
)

if [[ ! -f "${manifest}" ]]; then
  echo "resolved-reentry runner requires missing implementation: ${manifest}" >&2
  exit 1
fi

run_cli() {
  CARGO_TARGET_DIR="${target_root}" \
    cargo run --quiet --locked --offline --manifest-path "${manifest}" -- "$@"
}

expect_failure() {
  local label="$1"
  local invariant="$2"
  shift 2
  local stderr_path="${temporary_root}/failure-$RANDOM.stderr"
  if "$@" >"${temporary_root}/failure-$RANDOM.stdout" 2>"${stderr_path}"; then
    echo "not ok - ${label}: unexpectedly succeeded" >&2
    exit 1
  fi
  if ! rg -F "${invariant}" "${stderr_path}" >/dev/null; then
    echo "not ok - ${label}: missing ${invariant}" >&2
    sed -n '1,30p' "${stderr_path}" >&2
    exit 1
  fi
  assert_no_leak_markers "${label}" "${stderr_path}"
}

assert_no_leak_markers() {
  local label="$1"
  local stderr_path="$2"
  local marker
  for marker in "${leak_markers[@]}"; do
    if rg -F "${marker}" "${stderr_path}" >/dev/null; then
      echo "not ok - ${label}: diagnostic disclosed adversarial marker" >&2
      exit 1
    fi
  done
}

expect_safe_failure() {
  local label="$1"
  local invariant="$2"
  local category="$3"
  local marker="$4"
  shift 4
  local seen_marker command_arg marker_carried=false
  for seen_marker in "${safe_probe_markers[@]}"; do
    if [[ "${seen_marker}" == "${marker}" ]]; then
      echo "not ok - ${label}: reused nondisclosure marker ${marker}" >&2
      exit 1
    fi
  done
  for command_arg in "$@"; do
    if [[ -f "${command_arg}" ]] &&
       rg -F "${marker}" "${command_arg}" >/dev/null; then
      marker_carried=true
      break
    fi
  done
  if [[ "${marker_carried}" != true ]]; then
    echo "not ok - ${label}: fixture does not carry ${marker}" >&2
    exit 1
  fi
  local stderr_path="${temporary_root}/safe-failure-$RANDOM.stderr"
  if "$@" >"${temporary_root}/safe-failure-$RANDOM.stdout" 2>"${stderr_path}"; then
    echo "not ok - ${label}: unexpectedly succeeded" >&2
    exit 1
  fi
  if ! rg -F "${invariant}" "${stderr_path}" >/dev/null ||
     ! rg -F "\"category\":\"${category}\"" "${stderr_path}" >/dev/null; then
    echo "not ok - ${label}: missing stable ${invariant}/${category}" >&2
    sed -n '1,30p' "${stderr_path}" >&2
    exit 1
  fi
  assert_no_leak_markers "${label}" "${stderr_path}"
  safe_probe_markers+=("${marker}")
  safe_diagnostic_probe_count=$((safe_diagnostic_probe_count + 1))
}

expect_revalidation_rejection() {
  local label="$1"
  local candidate="$2"
  local marker="$3"
  local stdout_path="${temporary_root}/semantic-$RANDOM.stdout"
  local stderr_path="${temporary_root}/semantic-$RANDOM.stderr"
  if ! rg -F "${marker}" "${candidate}" >/dev/null; then
    echo "not ok - ${label}: fixture does not carry ${marker}" >&2
    exit 1
  fi
  if ! run_cli reject-no-mutation \
      "${candidate}" "${catalog}" "${retained_source}" \
      "${current_decision}" "bubblewrap-linux-v1" "DRV-001" \
      >"${stdout_path}" 2>"${stderr_path}"; then
    echo "not ok - ${label}: rejection did not preserve zero driver mutation" >&2
    sed -n '1,30p' "${stderr_path}" >&2
    exit 1
  fi
  if ! jq -e \
      '.invariant == "DRV-001" and .category == "driver.semantic-mismatch"' \
      "${stdout_path}" >/dev/null; then
    echo "not ok - ${label}: missing stable DRV-001/driver.semantic-mismatch" >&2
    sed -n '1,30p' "${stdout_path}" >&2
    exit 1
  fi
  assert_no_leak_markers "${label}" "${stdout_path}"
  assert_no_leak_markers "${label}" "${stderr_path}"
  semantic_revalidation_probe_count=$((semantic_revalidation_probe_count + 1))
}

expect_classified_failure() {
  local label="$1"
  local invariant="$2"
  local classification="$3"
  shift 3
  local stderr_path="${temporary_root}/classified-failure-$RANDOM.stderr"
  if "$@" >"${temporary_root}/classified-failure-$RANDOM.stdout" \
      2>"${stderr_path}"; then
    echo "not ok - ${label}: unexpectedly succeeded" >&2
    exit 1
  fi
  if ! rg -F "${invariant}" "${stderr_path}" >/dev/null ||
     ! rg -F "${classification}" "${stderr_path}" >/dev/null; then
    echo "not ok - ${label}: missing ${invariant}/${classification}" >&2
    sed -n '1,30p' "${stderr_path}" >&2
    exit 1
  fi
  assert_no_leak_markers "${label}" "${stderr_path}"
}

record_pass() {
  pass_count=$((pass_count + 1))
  echo "ok - $1"
}

semantic_digest="$(printf '%064d' 0 | tr '0' 'a')"
member_digest="$(printf '%064d' 0 | tr '0' 'b')"
create_digest="$(printf '%064d' 0 | tr '0' 'c')"
policy_digest="$(printf '%064d' 0 | tr '0' 'd')"
source_digest="$(printf '%064d' 0 | tr '0' 'e')"
auth_digest="$(printf '%064d' 0 | tr '0' 'f')"
current_decision="admission-v1"
retained_source="${temporary_root}/current-retained-source"
printf '%s\n' "current-live-source" >"${retained_source}"

write_envelope() {
  local profile="$1"
  local output="$2"
  jq -n \
    --arg semantic "${semantic_digest}" \
    --arg member "${member_digest}" \
    --arg create "${create_digest}" \
    --arg policy "${policy_digest}" \
    --arg source "${source_digest}" \
    --arg auth "${auth_digest}" \
    --arg profile "${profile}" \
    '{
      schemaVersion: 1,
      artifact: {
        semanticDigest: $semantic,
        memberContentDigest: $member,
        runtimeProfileId: $profile
      },
      create: {
        requestDigest: $create,
        idempotencyScope: "sandbox-create-v1",
        workspaceDestination: "/workspace",
        workspaceAccess: "readWrite",
        networkMode: "disabled",
        egressAllow: []
      },
      admissionContext: {
        decisionId: "admission-v1",
        policyDigest: $policy
      },
      retainedSourceReferences: {
        workspace: {
          descriptorDigest: $source,
          pathHint: "/serialized/path/must-not-be-opened",
          serializedToken: "serialized-secret-token"
        }
      },
      integrity: {
        principal: "authenticated-caller",
        authenticatedContextDigest: $auth
      }
    }' >"${output}"
}

valid_envelope="${temporary_root}/valid-envelope.json"
write_envelope "bubblewrap-linux-v1" "${valid_envelope}"

run_cli decode "${valid_envelope}" >/dev/null
bounded_envelope="${temporary_root}/bounded-envelope.json"
cp "${valid_envelope}" "${bounded_envelope}"
bounded_size="$(wc -c <"${bounded_envelope}" | tr -d ' ')"
dd if=/dev/zero bs=1 count="$((65536 - bounded_size))" 2>/dev/null |
  tr '\000' ' ' >>"${bounded_envelope}"
run_cli decode "${bounded_envelope}" >/dev/null
record_pass "closed bounded resolved envelope"

jq '.["LEAK-MARKER-UNKNOWN-ROOT"] = true' "${valid_envelope}" \
  >"${temporary_root}/unknown.json"
expect_safe_failure "unknown envelope" "WIRE-007" "wire.closed-schema" \
  "LEAK-MARKER-UNKNOWN-ROOT" \
  run_cli decode "${temporary_root}/unknown.json"

jq '.artifact["LEAK-MARKER-UNKNOWN-NESTED"] = true' "${valid_envelope}" \
  >"${temporary_root}/unknown-nested.json"
expect_safe_failure "unknown nested envelope" "WIRE-007" "wire.closed-schema" \
  "LEAK-MARKER-UNKNOWN-NESTED" \
  run_cli decode "${temporary_root}/unknown-nested.json"

perl -0pe 's/\A\{/{"schemaVersion":1,/' "${valid_envelope}" \
  >"${temporary_root}/duplicate.json"
expect_failure "duplicate envelope" "WIRE-007" \
  run_cli decode "${temporary_root}/duplicate.json"

jq -c . "${valid_envelope}" |
  perl -0pe \
    's/"artifact":\{/"artifact":{"runtimeProfileId":"bubblewrap-linux-v1",/' \
  >"${temporary_root}/duplicate-nested.json"
expect_failure "duplicate nested envelope" "WIRE-007" \
  run_cli decode "${temporary_root}/duplicate-nested.json"

printf '%s\n' \
  '{"LEAK-MARKER-DUPLICATE-ROOT":0,"LEAK-MARKER-DUPLICATE-ROOT":1}' \
  >"${temporary_root}/duplicate-secret-root.json"
expect_safe_failure \
  "secret duplicate root key" "WIRE-007" "wire.duplicate-key" \
  "LEAK-MARKER-DUPLICATE-ROOT" \
  run_cli decode "${temporary_root}/duplicate-secret-root.json"

printf '%s\n' \
  '{"outer":{"LEAK-MARKER-DUPLICATE-NESTED":0,"LEAK-MARKER-DUPLICATE-NESTED":1}}' \
  >"${temporary_root}/duplicate-secret-nested.json"
expect_safe_failure \
  "secret duplicate nested key" "WIRE-007" "wire.duplicate-key" \
  "LEAK-MARKER-DUPLICATE-NESTED" \
  run_cli decode "${temporary_root}/duplicate-secret-nested.json"

jq '.schemaVersion = "LEAK-MARKER-VALUE"' "${valid_envelope}" \
  >"${temporary_root}/secret-value.json"
expect_safe_failure "secret value type failure" "WIRE-007" "wire.closed-schema" \
  "LEAK-MARKER-VALUE" \
  run_cli decode "${temporary_root}/secret-value.json"

cp "${valid_envelope}" "${temporary_root}/oversize.json"
oversize_size="$(wc -c <"${temporary_root}/oversize.json" | tr -d ' ')"
dd if=/dev/zero bs=1 count="$((65537 - oversize_size))" 2>/dev/null |
  tr '\000' ' ' >>"${temporary_root}/oversize.json"
expect_failure "oversize envelope" "WIRE-007" \
  run_cli decode "${temporary_root}/oversize.json"

{
  printf '{"LEAK-MARKER-DEEP":'
  for _ in $(seq 1 33); do printf '['; done
  printf 'null'
  for _ in $(seq 1 33); do printf ']'; done
  printf '}\n'
} >"${temporary_root}/deep.json"
expect_safe_failure "deep envelope" "WIRE-007" "wire.depth-limit" \
  "LEAK-MARKER-DEEP" \
  run_cli decode "${temporary_root}/deep.json"

printf '%s\n' '{"LEAK-MARKER-WIRE-JSON":' \
  >"${temporary_root}/malformed-wire.json"
expect_safe_failure "malformed envelope JSON" "WIRE-007" "wire.invalid-json" \
  "LEAK-MARKER-WIRE-JSON" \
  run_cli decode "${temporary_root}/malformed-wire.json"

jq '.schemaVersion = 2' "${valid_envelope}" >"${temporary_root}/unsupported.json"
expect_failure "unsupported envelope" "WIRE-007" \
  run_cli decode "${temporary_root}/unsupported.json"
record_pass "unknown/duplicate/oversize/deep/unsupported envelope rejection"

jq -n '[
  {
    label: "artifact semantic identity",
    path: ["artifact", "semanticDigest"],
    value: ("9" * 64),
    marker: "LEAK-MARKER-SEMANTIC-ARTIFACT"
  },
  {
    label: "member content identity",
    path: ["artifact", "memberContentDigest"],
    value: ("8" * 64),
    marker: "LEAK-MARKER-SEMANTIC-MEMBER"
  },
  {
    label: "Create request identity",
    path: ["create", "requestDigest"],
    value: ("7" * 64),
    marker: "LEAK-MARKER-SEMANTIC-CREATE"
  },
  {
    label: "admission policy identity",
    path: ["admissionContext", "policyDigest"],
    value: ("6" * 64),
    marker: "LEAK-MARKER-SEMANTIC-POLICY"
  },
  {
    label: "runtime-profile identity",
    path: ["artifact", "runtimeProfileId"],
    value: "oci-linux-v1",
    marker: "LEAK-MARKER-SEMANTIC-PROFILE"
  },
  {
    label: "retained-source identity",
    path: ["retainedSourceReferences", "workspace", "descriptorDigest"],
    value: ("5" * 64),
    marker: "LEAK-MARKER-SEMANTIC-SOURCE"
  }
]' >"${temporary_root}/authenticated-semantic-mutations.json"
semantic_mutation_index=0
while IFS= read -r semantic_mutation; do
  semantic_mutation_index=$((semantic_mutation_index + 1))
  semantic_label="$(jq -r '.label' <<<"${semantic_mutation}")"
  semantic_path="$(jq -c '.path' <<<"${semantic_mutation}")"
  semantic_value="$(jq -c '.value' <<<"${semantic_mutation}")"
  semantic_marker="$(jq -r '.marker' <<<"${semantic_mutation}")"
  semantic_candidate="${temporary_root}/authenticated-stale-${semantic_mutation_index}.json"
  jq \
    --argjson semanticPath "${semantic_path}" \
    --argjson semanticValue "${semantic_value}" \
    --arg marker "${semantic_marker}" \
    'setpath($semanticPath; $semanticValue) |
     .retainedSourceReferences.workspace.serializedToken = $marker' \
    "${valid_envelope}" >"${semantic_candidate}"
  expect_revalidation_rejection \
    "stale ${semantic_label}" "${semantic_candidate}" "${semantic_marker}"
done < <(jq -c '.[]' "${temporary_root}/authenticated-semantic-mutations.json")
record_pass "authenticated envelope still revalidates semantics"

run_cli replay-check "${catalog}" built >/dev/null
for mutation in missing extra duplicate reordered; do
  mutated="${temporary_root}/built-${mutation}.json"
  case "${mutation}" in
    missing)
      replay_category="replay.set-membership"
      replay_marker="LEAK-MARKER-BUILT-MISSING"
      jq '(.serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds) |= .[1:]' \
        "${catalog}" >"${mutated}"
      ;;
    extra)
      replay_category="replay.set-membership"
      replay_marker="LEAK-MARKER-BUILT-EXTRA"
      jq '.serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds +=
          ["LEAK-MARKER-BUILT-EXTRA"]' \
        "${catalog}" >"${mutated}"
      ;;
    duplicate)
      replay_category="replay.duplicate-id"
      replay_marker="LEAK-MARKER-BUILT-DUPLICATE"
      jq '.serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds +=
          [.serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds[0]]' \
        "${catalog}" >"${mutated}"
      ;;
    reordered)
      replay_category="replay.order"
      replay_marker="LEAK-MARKER-BUILT-REORDERED"
      jq '(.serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds[0:2]) |= reverse' \
        "${catalog}" >"${mutated}"
      ;;
  esac
  marked="${temporary_root}/built-${mutation}-marked.json"
  jq --arg marker "${replay_marker}" \
    '.nondisclosureProbeMarker = $marker' "${mutated}" >"${marked}"
  mutated="${marked}"
  expect_safe_failure \
    "built replay ${mutation}" "DRV-001" "${replay_category}" \
    "${replay_marker}" \
    run_cli replay-check "${mutated}" built
done

jq '.serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds +=
    ["LEAK-MARKER-REPLAY-DUPLICATE", "LEAK-MARKER-REPLAY-DUPLICATE"]' \
  "${catalog}" >"${temporary_root}/built-secret-duplicate.json"
expect_safe_failure \
  "secret replay duplicate" "DRV-001" "replay.duplicate-id" \
  "LEAK-MARKER-REPLAY-DUPLICATE" \
  run_cli replay-check "${temporary_root}/built-secret-duplicate.json" built

jq '.serializedResolvedReentryReplaySets.builtMemberLoadInvariantIds +=
    [{"LEAK-MARKER-REPLAY-OBJECT-KEY": true}]' \
  "${catalog}" >"${temporary_root}/built-secret-object.json"
expect_safe_failure \
  "secret replay non-string" "DRV-001" "replay.invalid-id-type" \
  "LEAK-MARKER-REPLAY-OBJECT-KEY" \
  run_cli replay-check "${temporary_root}/built-secret-object.json" built

printf '%s\n' '{"LEAK-MARKER-REPLAY-JSON":' \
  >"${temporary_root}/built-secret-invalid-json.json"
expect_safe_failure \
  "secret replay malformed JSON" "DRV-001" "replay.invalid-json" \
  "LEAK-MARKER-REPLAY-JSON" \
  run_cli replay-check "${temporary_root}/built-secret-invalid-json.json" built
record_pass "89 built-load invariant replay set equality"

run_cli replay-check "${catalog}" resolved >/dev/null
for mutation in missing extra duplicate reordered; do
  mutated="${temporary_root}/resolved-${mutation}.json"
  case "${mutation}" in
    missing)
      replay_category="replay.set-membership"
      replay_marker="LEAK-MARKER-RESOLVED-MISSING"
      jq '(.serializedResolvedReentryReplaySets.resolvedStageInvariantIds) |= .[1:]' \
        "${catalog}" >"${mutated}"
      ;;
    extra)
      replay_category="replay.set-membership"
      replay_marker="LEAK-MARKER-RESOLVED-EXTRA"
      jq '.serializedResolvedReentryReplaySets.resolvedStageInvariantIds +=
          ["LEAK-MARKER-RESOLVED-EXTRA"]' \
        "${catalog}" >"${mutated}"
      ;;
    duplicate)
      replay_category="replay.duplicate-id"
      replay_marker="LEAK-MARKER-RESOLVED-DUPLICATE"
      jq '.serializedResolvedReentryReplaySets.resolvedStageInvariantIds +=
          [.serializedResolvedReentryReplaySets.resolvedStageInvariantIds[0]]' \
        "${catalog}" >"${mutated}"
      ;;
    reordered)
      replay_category="replay.order"
      replay_marker="LEAK-MARKER-RESOLVED-REORDERED"
      jq '(.serializedResolvedReentryReplaySets.resolvedStageInvariantIds[0:2]) |= reverse' \
        "${catalog}" >"${mutated}"
      ;;
  esac
  marked="${temporary_root}/resolved-${mutation}-marked.json"
  jq --arg marker "${replay_marker}" \
    '.nondisclosureProbeMarker = $marker' "${mutated}" >"${marked}"
  mutated="${marked}"
  expect_safe_failure \
    "resolved replay ${mutation}" "DRV-001" "${replay_category}" \
    "${replay_marker}" \
    run_cli replay-check "${mutated}" resolved
done
record_pass "30 resolved-stage invariant replay set equality"

run_cli reject-no-mutation \
  "${valid_envelope}" "${catalog}" "${retained_source}" \
  "admission-v2" "bubblewrap-linux-v1" "DRV-001" >/dev/null
record_pass "changed current admission invalidates cached candidate"

run_cli probe-retained \
  "${valid_envelope}" "${catalog}" "${retained_source}" \
  "${current_decision}" "bubblewrap-linux-v1" "current-live-source" >/dev/null
record_pass "serialized path/token cannot recreate retained handle"

run_cli probe-determinism \
  "${valid_envelope}" "${catalog}" "${retained_source}" \
  "${current_decision}" "bubblewrap-linux-v1" >/dev/null
record_pass "deterministic reconstruction creates a fresh PreparedLaunch"

consumer_root="${temporary_root}/external-consumer"
mkdir -p "${consumer_root}/src"
cat >"${consumer_root}/Cargo.toml" <<EOF
[package]
name = "resolved-reentry-external-consumer"
version = "0.0.0"
edition = "2021"
publish = false

[dependencies]
resolved-reentry = { path = "${prototype_root}" }
serde_json = "1.0"
EOF
cp "${prototype_root}/compile-probes/positive.rs" "${consumer_root}/src/main.rs"
cargo generate-lockfile --offline --manifest-path "${consumer_root}/Cargo.toml" \
  >/dev/null

run_consumer_probe() {
  local probe="$1"
  cp "${prototype_root}/compile-probes/${probe}.rs" "${consumer_root}/src/main.rs"
  CARGO_TARGET_DIR="${temporary_root}/consumer-target" \
    cargo check --quiet --locked --offline \
      --manifest-path "${consumer_root}/Cargo.toml"
}

expect_compile_failure() {
  local probe="$1"
  local error_code="$2"
  local stderr_path="${temporary_root}/${probe}.stderr"
  if run_consumer_probe "${probe}" >"${temporary_root}/${probe}.stdout" \
      2>"${stderr_path}"; then
    echo "not ok - ${probe}: unexpectedly compiled" >&2
    exit 1
  fi
  if ! rg -F "${error_code}" "${stderr_path}" >/dev/null; then
    echo "not ok - ${probe}: missing compiler category ${error_code}" >&2
    sed -n '1,40p' "${stderr_path}" >&2
    exit 1
  fi
}

run_consumer_probe positive
CARGO_TARGET_DIR="${temporary_root}/consumer-target" \
  cargo run --quiet --locked --offline \
    --manifest-path "${consumer_root}/Cargo.toml" -- \
    "${valid_envelope}" "${catalog}" "${retained_source}"
expect_compile_failure private_struct_literal "E0451"
expect_compile_failure prepared_deserialize "E0277"
expect_compile_failure prepared_clone "E0277"
record_pass "direct driver invocation rejected"

expect_compile_failure raw_json_driver "E0308"
expect_compile_failure raw_map_driver "E0308"
expect_compile_failure raw_arguments_driver "E0308"
record_pass "raw runtime map and raw argument input rejected"

write_expected_generated() {
  local profile="$1"
  local target="$2"
  local driver="$3"
  local guest="$4"
  local prepared="$5"
  local output_path="$6"
  jq -n \
    --arg semantic "${semantic_digest}" \
    --arg member "${member_digest}" \
    --arg create "${create_digest}" \
    --arg decision "${current_decision}" \
    --arg prepared "${prepared}" \
    --arg profile "${profile}" \
    --arg target "${target}" \
    --arg source "${source_digest}" \
    --arg driver "${driver}" \
    --arg guest "${guest}" \
    '{
      resolvedVersion: 1,
      identity: {
        artifactSemanticDigest: $semantic,
        memberContentDigest: $member,
        createRequestDigest: $create,
        admissionDecisionId: $decision,
        preparedSemanticIdentity: $prepared
      },
      profile: {
        id: $profile,
        targetId: $target
      },
      retainedSource: {
        workspaceDescriptorDigest: $source,
        acquisitionKind: "live-file-handle"
      },
      workspace: {
        destination: "/workspace",
        access: "readWrite",
        materialization: "retained"
      },
      network: {
        mode: "disabled",
        egressAllow: [],
        ports: []
      },
      resources: {
        cpuMillis: 1000,
        memoryBytes: 536870912,
        diskBytes: 2147483648
      },
      identitySecurity: {
        uid: 1000,
        gid: 1000,
        noNewPrivileges: true,
        capabilities: []
      },
      devices: {allowed: []},
      secrets: {bindings: []},
      snapshots: {mode: "disabled", source: null},
      output: {capture: "structured", maxBytes: 1048576},
      protocolVersions: {
        resolvedReentry: "resolved-reentry-v1",
        driver: $driver,
        generatedConfiguration: "generated-runtime-config-v1",
        guest: $guest
      },
      backendDefaults: {
        rootFilesystem: "suppressed-explicit",
        networkNamespace: "suppressed-explicit",
        hostname: "suppressed-explicit",
        environment: "suppressed-explicit",
        workingDirectory: "suppressed-explicit",
        resourceLimits: "suppressed-explicit",
        security: "suppressed-explicit",
        devices: "suppressed-explicit",
        secrets: "suppressed-explicit",
        snapshots: "suppressed-explicit",
        output: "suppressed-explicit"
      }
    }' >"${output_path}"
}

generated="${temporary_root}/generated.json"
run_cli revalidate \
  "${valid_envelope}" "${catalog}" "${retained_source}" \
  "${current_decision}" "bubblewrap-linux-v1" >"${generated}"
expected_generated="${temporary_root}/generated-expected.json"
prepared_identity="83dd67a46d952b262ad5b5afdd3196b74ce9e54c9aeff91a4b99638b8a5024e1"
write_expected_generated \
  "bubblewrap-linux-v1" "bubblewrap" "bubblewrap-driver-v1" "none-v1" \
  "${prepared_identity}" "${expected_generated}"

driver_args=(
  --slurpfile expectedGeneratedConfiguration "${expected_generated}"
  --arg expectedArtifactSemanticDigest "${semantic_digest}"
  --arg expectedMemberContentDigest "${member_digest}"
  --arg expectedCreateRequestDigest "${create_digest}"
  --arg expectedAdmissionDecisionId "${current_decision}"
  --arg expectedPreparedSemanticIdentity "${prepared_identity}"
  --arg expectedProfileId "bubblewrap-linux-v1"
  --arg expectedTargetId "bubblewrap"
  --arg expectedSourceDescriptorDigest "${source_digest}"
  --arg expectedDriverProtocolVersion "bubblewrap-driver-v1"
  --arg expectedGuestProtocolVersion "none-v1"
  -f "${downstream_validator}"
)
jq -e "${driver_args[@]}" "${generated}" >/dev/null

jq '.resources.cpuMillis = 1500' "${generated}" \
  >"${temporary_root}/generated-cpu-millis-substituted.json"
expect_failure "canonical oracle rejects cpuMillis substitution" "DRV-001" \
  jq -e "${driver_args[@]}" \
  "${temporary_root}/generated-cpu-millis-substituted.json"

profile_prepared_identities=()
while IFS='|' read -r profile target driver guest expected_prepared_identity; do
  profile_envelope="${temporary_root}/profile-${profile}.json"
  profile_generated="${temporary_root}/profile-${profile}-generated.json"
  write_envelope "${profile}" "${profile_envelope}"
  run_cli revalidate \
    "${profile_envelope}" "${catalog}" "${retained_source}" \
    "${current_decision}" "${profile}" >"${profile_generated}"
  profile_expected="${temporary_root}/profile-${profile}-expected.json"
  write_expected_generated \
    "${profile}" "${target}" "${driver}" "${guest}" \
    "${expected_prepared_identity}" "${profile_expected}"
  profile_prepared_identity="$(
    jq -r '.identity.preparedSemanticIdentity' "${profile_generated}"
  )"
  profile_prepared_identities+=("${profile_prepared_identity}")
  jq -e \
    --slurpfile expectedGeneratedConfiguration "${profile_expected}" \
    --arg expectedArtifactSemanticDigest "${semantic_digest}" \
    --arg expectedMemberContentDigest "${member_digest}" \
    --arg expectedCreateRequestDigest "${create_digest}" \
    --arg expectedAdmissionDecisionId "${current_decision}" \
    --arg expectedPreparedSemanticIdentity "${expected_prepared_identity}" \
    --arg expectedProfileId "${profile}" \
    --arg expectedTargetId "${target}" \
    --arg expectedSourceDescriptorDigest "${source_digest}" \
    --arg expectedDriverProtocolVersion "${driver}" \
    --arg expectedGuestProtocolVersion "${guest}" \
    -f "${downstream_validator}" "${profile_generated}" >/dev/null

  jq '.identity.preparedSemanticIdentity = ("0" * 64)' \
    "${profile_generated}" \
    >"${temporary_root}/profile-${profile}-prepared-substituted.json"
  expect_classified_failure \
    "prepared identity substitution ${profile}" "DRV-001" \
    "DRV-003 private identity chain" \
    jq -e \
      --slurpfile expectedGeneratedConfiguration "${profile_expected}" \
      --arg expectedArtifactSemanticDigest "${semantic_digest}" \
      --arg expectedMemberContentDigest "${member_digest}" \
      --arg expectedCreateRequestDigest "${create_digest}" \
      --arg expectedAdmissionDecisionId "${current_decision}" \
      --arg expectedPreparedSemanticIdentity "${expected_prepared_identity}" \
      --arg expectedProfileId "${profile}" \
      --arg expectedTargetId "${target}" \
      --arg expectedSourceDescriptorDigest "${source_digest}" \
      --arg expectedDriverProtocolVersion "${driver}" \
      --arg expectedGuestProtocolVersion "${guest}" \
      -f "${downstream_validator}" \
      "${temporary_root}/profile-${profile}-prepared-substituted.json"

  jq '.identity.preparedSemanticIdentity = "LEAK-MARKER-PREPARED-MALFORMED"' \
    "${profile_generated}" \
    >"${temporary_root}/profile-${profile}-prepared-malformed.json"
  expect_classified_failure \
    "malformed prepared identity ${profile}" "DRV-001" \
    "DRV-003 private identity chain" \
    jq -e \
      --slurpfile expectedGeneratedConfiguration "${profile_expected}" \
      --arg expectedArtifactSemanticDigest "${semantic_digest}" \
      --arg expectedMemberContentDigest "${member_digest}" \
      --arg expectedCreateRequestDigest "${create_digest}" \
      --arg expectedAdmissionDecisionId "${current_decision}" \
      --arg expectedPreparedSemanticIdentity "${expected_prepared_identity}" \
      --arg expectedProfileId "${profile}" \
      --arg expectedTargetId "${target}" \
      --arg expectedSourceDescriptorDigest "${source_digest}" \
      --arg expectedDriverProtocolVersion "${driver}" \
      --arg expectedGuestProtocolVersion "${guest}" \
      -f "${downstream_validator}" \
      "${temporary_root}/profile-${profile}-prepared-malformed.json"
  prepared_identity_probe_count=$((prepared_identity_probe_count + 2))
done <<'EOF'
bubblewrap-linux-v1|bubblewrap|bubblewrap-driver-v1|none-v1|83dd67a46d952b262ad5b5afdd3196b74ce9e54c9aeff91a4b99638b8a5024e1
microvm-firecracker-linux-v1|firecracker|firecracker-driver-v1|sandbox-agent-v1|ce34b98ebd242ae8dbb04b2a6919df819810d6ea0477adc557c180a0c83261a2
microvm-cloud-hypervisor-linux-v1|cloud-hypervisor|cloud-hypervisor-driver-v1|sandbox-agent-v1|6bf4467bead1a547f20c155f447d8896fa4bb44418cc58b913621daee303cbbb
oci-linux-v1|oci|oci-driver-v1|oci-runtime-v1|1398c4c42dbe86f0f396d672727250c1c97c03acf9d9ce0ce9e0925d93f283cb
EOF
if [[ "$(
  printf '%s\n' "${profile_prepared_identities[@]}" | sort -u | wc -l | tr -d ' '
)" != 4 ]]; then
  echo "not ok - prepared semantic identity is not profile-bound" >&2
  exit 1
fi

projection_mutations="${temporary_root}/generated-projection-mutations.json"
jq -n '[
  {path: ["resolvedVersion"], value: 2, invariant: "DRV-001"},
  {path: ["identity", "artifactSemanticDigest"], value: ("0" * 64), invariant: "DRV-001"},
  {path: ["identity", "memberContentDigest"], value: ("0" * 64), invariant: "DRV-001"},
  {path: ["identity", "createRequestDigest"], value: ("0" * 64), invariant: "DRV-001"},
  {path: ["identity", "admissionDecisionId"], value: "admission-v2", invariant: "DRV-001"},
  {path: ["identity", "preparedSemanticIdentity"], value: ("0" * 64), invariant: "DRV-001"},
  {path: ["profile", "id"], value: "oci-linux-v1", invariant: "DRV-001"},
  {path: ["profile", "targetId"], value: "oci", invariant: "DRV-001"},
  {path: ["retainedSource", "workspaceDescriptorDigest"], value: ("0" * 64), invariant: "DRV-001"},
  {path: ["retainedSource", "acquisitionKind"], value: "path-reference", invariant: "DRV-001"},
  {path: ["workspace", "destination"], value: "/other-workspace", invariant: "DRV-001"},
  {path: ["workspace", "access"], value: "readOnly", invariant: "DRV-001"},
  {path: ["workspace", "materialization"], value: "copy", invariant: "DRV-001"},
  {path: ["network", "mode"], value: "egress", invariant: "DRV-001"},
  {path: ["network", "egressAllow"], value: ["10.0.0.0/8"], invariant: "DRV-001"},
  {path: ["network", "ports"], value: ["8080/tcp"], invariant: "DRV-001"},
  {path: ["resources", "cpuMillis"], value: 2000, invariant: "DRV-001"},
  {path: ["resources", "memoryBytes"], value: 1073741824, invariant: "DRV-001"},
  {path: ["resources", "diskBytes"], value: 4294967296, invariant: "DRV-001"},
  {path: ["identitySecurity", "uid"], value: 2000, invariant: "DRV-001"},
  {path: ["identitySecurity", "gid"], value: 2000, invariant: "DRV-001"},
  {path: ["identitySecurity", "noNewPrivileges"], value: false, invariant: "DRV-001"},
  {path: ["identitySecurity", "capabilities"], value: ["CAP_NET_ADMIN"], invariant: "DRV-001"},
  {path: ["devices", "allowed"], value: ["device.example/test"], invariant: "DRV-001"},
  {path: ["secrets", "bindings"], value: ["secret-slot"], invariant: "DRV-001"},
  {path: ["snapshots", "mode"], value: "enabled", invariant: "DRV-001"},
  {path: ["snapshots", "source"], value: "snapshot-id", invariant: "DRV-001"},
  {path: ["output", "capture"], value: "raw", invariant: "DRV-001"},
  {path: ["output", "maxBytes"], value: 2097152, invariant: "DRV-001"},
  {path: ["protocolVersions", "resolvedReentry"], value: "resolved-reentry-v2", invariant: "DRV-001"},
  {path: ["protocolVersions", "driver"], value: "bubblewrap-driver-v2", invariant: "DRV-001"},
  {path: ["protocolVersions", "generatedConfiguration"], value: "generated-runtime-config-v2", invariant: "DRV-001"},
  {path: ["protocolVersions", "guest"], value: "guest-v2", invariant: "DRV-001"},
  {path: ["backendDefaults", "rootFilesystem"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "networkNamespace"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "hostname"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "environment"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "workingDirectory"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "resourceLimits"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "security"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "devices"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "secrets"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "snapshots"], value: "implicit", invariant: "DRV-004"},
  {path: ["backendDefaults", "output"], value: "implicit", invariant: "DRV-004"}
]' >"${projection_mutations}"

jq -en \
  --slurpfile expected "${expected_generated}" \
  --slurpfile mutations "${projection_mutations}" '
  def leaf_paths($value):
    [$value |
      path(..) as $leaf_path |
      select(($leaf_path | length) > 0) |
      select(($value | getpath($leaf_path) | type) != "object") |
      $leaf_path];
  (leaf_paths($expected[0])) as $expected_paths |
  ([$mutations[0][].path]) as $mutation_paths |
  ($expected_paths | length) == 44 and
  ($mutation_paths | length) == 44 and
  ($mutation_paths | unique | length) == 44 and
  ($expected_paths | sort) == ($mutation_paths | sort)
  ' >/dev/null

projection_index=0
while IFS= read -r projection_mutation; do
  projection_index=$((projection_index + 1))
  leaf_path_json="$(jq -c '.path' <<<"${projection_mutation}")"
  leaf_value_json="$(jq -c '.value' <<<"${projection_mutation}")"
  leaf_label="$(jq -r '.path | join(".")' <<<"${projection_mutation}")"
  leaf_invariant="$(jq -r '.invariant' <<<"${projection_mutation}")"
  mutated_projection="${temporary_root}/generated-leaf-${projection_index}.json"
  jq \
    --argjson leafPath "${leaf_path_json}" \
    --argjson leafValue "${leaf_value_json}" \
    'setpath($leafPath; $leafValue)' \
    "${expected_generated}" >"${mutated_projection}"
  expect_failure "generated projection leaf ${leaf_label}" "${leaf_invariant}" \
    jq -e "${driver_args[@]}" "${mutated_projection}"
  generated_projection_probe_count=$((generated_projection_probe_count + 1))
done < <(jq -c '.[]' "${projection_mutations}")

record_pass "generated configuration is total and closed"

jq 'del(.backendDefaults.networkNamespace)' "${generated}" \
  >"${temporary_root}/generated-default-omitted.json"
expect_failure "backend default omitted" "DRV-004" \
  jq -e "${driver_args[@]}" "${temporary_root}/generated-default-omitted.json"
record_pass "backend default omission rejected"

jq '.identity.artifactSemanticDigest = ("0" * 64)' "${generated}" \
  >"${temporary_root}/generated-corrupted.json"
expect_failure "post-generation identity corruption" "DRV-001" \
  jq -e "${driver_args[@]}" "${temporary_root}/generated-corrupted.json"
record_pass "post-generation corruption rejected"

if ((pass_count != expected_pass_count)); then
  echo "expected ${expected_pass_count} cases, observed ${pass_count}" >&2
  exit 1
fi
if ((safe_diagnostic_probe_count != expected_safe_diagnostic_probe_count)); then
  echo "expected ${expected_safe_diagnostic_probe_count} stable diagnostic probes, observed ${safe_diagnostic_probe_count}" >&2
  exit 1
fi
if ((prepared_identity_probe_count != expected_prepared_identity_probe_count)); then
  echo "expected ${expected_prepared_identity_probe_count} prepared-identity mutation probes, observed ${prepared_identity_probe_count}" >&2
  exit 1
fi
if ((generated_projection_probe_count != expected_generated_projection_probe_count)); then
  echo "expected ${expected_generated_projection_probe_count} generated-projection leaf probes, observed ${generated_projection_probe_count}" >&2
  exit 1
fi
if ((semantic_revalidation_probe_count != expected_semantic_revalidation_probe_count)); then
  echo "expected ${expected_semantic_revalidation_probe_count} semantic revalidation probes, observed ${semantic_revalidation_probe_count}" >&2
  exit 1
fi

echo "resolved reentry prototypes: ${pass_count} cases passed (${safe_diagnostic_probe_count} stable diagnostic probes, ${prepared_identity_probe_count} prepared-identity mutation probes, ${generated_projection_probe_count} generated-projection leaf probes)"
