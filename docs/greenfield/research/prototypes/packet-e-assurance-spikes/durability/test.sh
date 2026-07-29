#!/usr/bin/env bash
set -euo pipefail

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
driver="$here/crash_driver.py"
model="$here/model.py"
store="$here/sqlite_store.py"

cases=(
  pure-model-transitions
  sqlite-settings
  atomic-log-append
  attempt-state-cas
  slot-head-cas
  conflict-resolution-multi-cas
  partial-commit-mutation
  store-model-drift
  log-sequence-future
  log-sequence-stale
  log-sequence-duplicate
  observer-missing-database
  observer-extra-table
  observer-schema-shape
)

for required in "$driver" "$model" "$store"; do
  if [[ ! -f "$required" ]]; then
    echo "packet-e/durability-implementation-unimplemented: $(basename "$required")" >&2
    exit 1
  fi
done

if [[ "${1:-}" == "--case" ]]; then
  cases=("$2")
fi

for case_name in "${cases[@]}"; do
  python3 "$driver" --case "$case_name"
  echo "PASS durability/$case_name"
done

echo "durability tests: ${#cases[@]} passed"
