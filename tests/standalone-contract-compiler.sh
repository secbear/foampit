#!/usr/bin/env bash
set -Eeuo pipefail

repository_root="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")/.." && pwd -P)"
source_project="${repository_root}/docs/greenfield/research/prototypes/packet-e-contract-compiler"
temporary_root="$(mktemp -d "${TMPDIR:-/tmp}/foampit-standalone-contract.XXXXXX")"

cleanup() {
  local status=$?
  trap - EXIT
  case "${temporary_root}" in
    "${TMPDIR:-/tmp}"/foampit-standalone-contract.*)
      rm -rf -- "${temporary_root}"
      ;;
    *)
      printf 'TEST_CLEANUP_REFUSED: %s\n' "${temporary_root}" >&2
      status=1
      ;;
  esac
  exit "${status}"
}
trap cleanup EXIT

standalone_project="${temporary_root}/repository/contract-compiler"
mkdir -p "${standalone_project}"
cp -R -- "${source_project}/." "${standalone_project}/"

run_preflight() {
  local output_file=$1
  (
    cd "${standalone_project}"
    ./test.sh --preflight
  ) >"${output_file}" 2>&1
}

baseline_output="${temporary_root}/baseline.txt"
daemon_output="${temporary_root}/daemon.txt"
changed_output="${temporary_root}/changed.txt"

if ! run_preflight "${baseline_output}"; then
  cat "${baseline_output}" >&2
  printf 'STANDALONE_PREFLIGHT_FAILED\n' >&2
  exit 1
fi

baseline_manifest="$(
  sed -n 's/^HARNESS_PREFLIGHT_SOURCE_MANIFEST: //p' "${baseline_output}"
)"
if [[ ! "${baseline_manifest}" =~ ^[0-9a-f]{64}$ ]]; then
  cat "${baseline_output}" >&2
  printf 'STANDALONE_PREFLIGHT_MANIFEST_INVALID: %s\n' \
    "${baseline_manifest}" >&2
  exit 1
fi
if ! grep -Fxq \
  'HARNESS_PREFLIGHT_OK: 21/21 product-owned stages' \
  "${baseline_output}"; then
  cat "${baseline_output}" >&2
  printf 'STANDALONE_PREFLIGHT_STAGE_COUNT_INVALID\n' >&2
  exit 1
fi

mkdir -p "${temporary_root}/repository/daemon"
printf 'unrelated legacy decoy\n' \
  >"${temporary_root}/repository/daemon/SHOULD_NOT_AFFECT_MANIFEST"
run_preflight "${daemon_output}"
daemon_manifest="$(
  sed -n 's/^HARNESS_PREFLIGHT_SOURCE_MANIFEST: //p' "${daemon_output}"
)"
if [[ "${daemon_manifest}" != "${baseline_manifest}" ]]; then
  diff -u "${baseline_output}" "${daemon_output}" >&2 || true
  printf 'STANDALONE_PREFLIGHT_READ_ANCESTOR_DAEMON\n' >&2
  exit 1
fi

printf '\n' >>"${standalone_project}/tspconfig.yaml"
run_preflight "${changed_output}"
changed_manifest="$(
  sed -n 's/^HARNESS_PREFLIGHT_SOURCE_MANIFEST: //p' "${changed_output}"
)"
if [[
  ! "${changed_manifest}" =~ ^[0-9a-f]{64}$ ||
  "${changed_manifest}" == "${baseline_manifest}"
]]; then
  cat "${changed_output}" >&2
  printf 'STANDALONE_PREFLIGHT_IGNORED_COMPILER_INPUT\n' >&2
  exit 1
fi

printf 'standalone contract-compiler preflight: ok\n'
