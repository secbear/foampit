#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
mode="${1:-}"
registry="${2:-}"
corpus="${3:-}"

if [[ "${mode}" != "inventory" && "${mode}" != "closure" ]]; then
  echo "usage: $0 <inventory|closure> <registry.json> [corpus.md]" >&2
  exit 2
fi

if [[ -z "${registry}" || ! -f "${registry}" ]]; then
  echo "registry file does not exist: ${registry:-<missing>}" >&2
  exit 2
fi

jq -e --arg mode "${mode}" \
  -f "${script_dir}/validate-registry.jq" \
  "${registry}" >/dev/null

if [[ -n "${corpus}" ]]; then
  if [[ ! -f "${corpus}" ]]; then
    echo "corpus file does not exist: ${corpus}" >&2
    exit 2
  fi

  corpus_ids() {
    rg -o \
      --replace '$1' \
      '^#### `([A-Z][A-Z0-9]*-[0-9]{3})`' \
      "${corpus}"
  }

  registry_ids() {
    jq -r '.invariants[].id' "${registry}"
  }

  valid_corpus_ids() {
    rg -o \
      --replace '$1' \
      '^### `((?:VAL)-[0-9]{3})`' \
      "${corpus}"
  }

  registry_invalid_witnesses() {
    jq -r \
      '.invariants[].invalidWitnesses[] |
       select(test("^[A-Z][A-Z0-9]*-[0-9]{3}$"))' \
      "${registry}"
  }

  registry_valid_witnesses() {
    jq -r \
      '.invariants[].validWitnesses[] |
       select(test("^VAL-[0-9]{3}$"))' \
      "${registry}"
  }

  duplicate_corpus_ids="$(
    corpus_ids |
      LC_ALL=C sort |
      uniq -d
  )"
  if [[ -n "${duplicate_corpus_ids}" ]]; then
    while IFS= read -r invariant_id; do
      echo "duplicate corpus invariant id: ${invariant_id}" >&2
    done <<<"${duplicate_corpus_ids}"
    exit 1
  fi

  coverage_failed=false
  while IFS= read -r invariant_id; do
    [[ -z "${invariant_id}" ]] && continue
    echo "corpus invariant missing from registry: ${invariant_id}" >&2
    coverage_failed=true
  done < <(
    comm -23 \
      <(corpus_ids | LC_ALL=C sort -u) \
      <(registry_ids | LC_ALL=C sort -u)
  )

  while IFS= read -r invariant_id; do
    [[ -z "${invariant_id}" ]] && continue
    echo "registry invariant missing from corpus: ${invariant_id}" >&2
    coverage_failed=true
  done < <(
    comm -13 \
      <(corpus_ids | LC_ALL=C sort -u) \
      <(registry_ids | LC_ALL=C sort -u)
  )

  while IFS= read -r witness_id; do
    [[ -z "${witness_id}" ]] && continue
    echo "unknown invalid witness: ${witness_id}" >&2
    coverage_failed=true
  done < <(
    comm -23 \
      <(registry_invalid_witnesses | LC_ALL=C sort -u) \
      <(corpus_ids | LC_ALL=C sort -u)
  )

  while IFS= read -r witness_id; do
    [[ -z "${witness_id}" ]] && continue
    echo "unknown valid witness: ${witness_id}" >&2
    coverage_failed=true
  done < <(
    comm -23 \
      <(registry_valid_witnesses | LC_ALL=C sort -u) \
      <(valid_corpus_ids | LC_ALL=C sort -u)
  )

  if [[ "${coverage_failed}" == true ]]; then
    exit 1
  fi
fi

if [[ "${mode}" != "closure" ]]; then
  exit 0
fi

check_references() {
  local kind="$1"
  local query="$2"

  while IFS=$'\t' read -r invariant_id relative_path; do
    local resolved_path
    if [[ "${relative_path}" = /* ]]; then
      resolved_path="${relative_path}"
    else
      resolved_path="${script_dir}/${relative_path}"
    fi

    if [[ ! -f "${resolved_path}" ]]; then
      echo "${invariant_id}: referenced ${kind} path does not exist: ${relative_path}" >&2
      exit 1
    fi
    if ! rg -F -q -- "${invariant_id}" "${resolved_path}"; then
      echo "${invariant_id}: ${kind} path does not reference invariant id: ${relative_path}" >&2
      exit 1
    fi
  done < <(jq -r "${query}" "${registry}")
}

check_references \
  "hook" \
  '.invariants[] as $invariant |
   $invariant.enforcementHooks[] |
   select(.status != "planned") |
   [$invariant.id, .path] | @tsv'

check_references \
  "test" \
  '.invariants[] as $invariant |
   $invariant.tests[] |
   select(.status == "passing") |
   [$invariant.id, .path] | @tsv'
