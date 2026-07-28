#!/usr/bin/env bash
set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
corpus="${script_dir}/../CONFIGURATION-LANGUAGE-CORPUS.md"
registry="${script_dir}/invariants.json"

"${script_dir}/test-registry.sh" closure
"${script_dir}/validate-registry.sh" closure "${registry}" "${corpus}"

echo "Gate 4B enforcement closure: all registered invariants are closed"
