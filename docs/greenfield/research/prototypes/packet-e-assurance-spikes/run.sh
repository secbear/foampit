#!/usr/bin/env bash
set -uo pipefail

here="$(CDPATH= cd -- "$(dirname -- "$0")" && pwd)"
failures=0

audit_toolchain() {
  local manifest="${1:-$here/toolchain.json}"
  local expected actual tool_name command_name output_path drv_path
  local lean_output archived_nixpkgs library_path

  if ! jq -e '
    .format == "packet-e-assurance-spike-toolchain-v1" and
    .system == "aarch64-darwin" and
    (.tools | keys == ["check-jsonschema","cue","jq","lean","node","python","sqlite"]) and
    (.tools.lean.libraries | map(.name) == ["Init", "Std"]) and
    (.tools.lean.libraries | all(
      (.storePath | type == "string" and length > 0) and
      (.sha256 | type == "string" and test("^[0-9a-f]{64}$"))
    ))
  ' "$manifest" >/dev/null; then
    echo "toolchain/library-provenance-mismatch" >&2
    return 1
  fi

  expected="$(jq -r '.nix.version' "$manifest")"
  actual="$(nix --version)"
  [[ "$actual" == "nix (Nix) $expected" ]] || return 1
  [[ "$(jq -r '.nodes.nixpkgs.locked.rev' "$here/flake.lock")" == \
    "$(jq -r '.nix.nixpkgs.rev' "$manifest")" ]] || return 1
  [[ "$(jq -r '.nodes.nixpkgs.locked.narHash' "$here/flake.lock")" == \
    "$(jq -r '.nix.nixpkgs.narHash' "$manifest")" ]] || return 1
  archived_nixpkgs="$(nix flake archive --json "$here" | jq -r '.inputs.nixpkgs.path')"
  [[ "$(realpath "$archived_nixpkgs")" == \
    "$(realpath "$(jq -r '.nix.nixpkgs.storePath' "$manifest")")" ]] || return 1
  [[ "$(nix eval --raw "$here#devShells.aarch64-darwin.default.inputDerivation")" == \
    "$(jq -r '.nix.devShellDrvPath' "$manifest")" ]] || return 1

  while IFS='|' read -r tool_name command_name; do
    output_path="$(jq -r --arg name "$tool_name" '.tools[$name].outPath' "$manifest")"
    [[ "$(command -v "$command_name")" == "$output_path/bin/$command_name" ]] || return 1
    drv_path="$(jq -r --arg name "$tool_name" '.tools[$name].drvPath' "$manifest")"
    [[ "$(nix-store -q --deriver "$output_path")" == "$drv_path" ]] || return 1
  done <<'TOOLS'
node|node
jq|jq
cue|cue
lean|lean
check-jsonschema|check-jsonschema
python|python3
sqlite|sqlite3
TOOLS

  [[ "$(node --version)" == "$(jq -r '.tools.node.commandVersion' "$manifest")" ]] || return 1
  [[ "$(jq --version)" == "$(jq -r '.tools.jq.commandVersion' "$manifest")" ]] || return 1
  [[ "$(cue version | sed -n '1p')" == "$(jq -r '.tools.cue.commandVersion' "$manifest")" ]] || return 1
  [[ "$(lean --version)" == "$(jq -r '.tools.lean.commandVersion' "$manifest")" ]] || return 1
  lean_output="$(jq -r '.tools.lean.outPath' "$manifest")"
  [[ "$(command -v lake)" == "$lean_output/bin/lake" ]] || return 1
  [[ "$(lake --version)" == "$(jq -r '.tools.lean.lakeVersion' "$manifest")" ]] || return 1
  [[ "$(check-jsonschema --version)" == \
    "$(jq -r '.tools["check-jsonschema"].commandVersion' "$manifest")" ]] || return 1
  [[ "$(python3 --version)" == "$(jq -r '.tools.python.commandVersion' "$manifest")" ]] || return 1
  [[ "$(python3 -c 'import sqlite3; print(sqlite3.sqlite_version)')" == \
    "$(jq -r '.tools.python.sqliteModuleVersion' "$manifest")" ]] || return 1
  [[ "$(sqlite3 --version)" == "$(jq -r '.tools.sqlite.commandVersionPrefix' "$manifest")"* ]] || return 1
  while IFS='|' read -r tool_name library_path expected; do
    [[ -f "$library_path" ]] || return 1
    [[ "$(realpath "$library_path")" == \
      "$lean_output/lib/lean/$tool_name.olean" ]] || return 1
    [[ "$(nix hash file --type sha256 --base16 "$library_path")" == "$expected" ]] ||
      return 1
  done < <(
    jq -r '.tools.lean.libraries[] | [.name, .storePath, .sha256] | join("|")' \
      "$manifest"
  )

  echo "toolchain audit: PASS tools=7 system=aarch64-darwin"
}

audit_toolchain_mutation() {
  local mutation="$1"
  local temporary manifest fake_bin
  temporary="$(mktemp -d "${TMPDIR:-/tmp}/packet-e-toolchain.XXXXXX")"
  manifest="$temporary/toolchain.json"
  fake_bin="$temporary/bin"
  mkdir "$fake_bin"
  case "$mutation" in
    wrong-deriver)
      jq '.tools.node.drvPath = .tools.lean.drvPath' \
        "$here/toolchain.json" >"$manifest"
      ;;
    lake-outside-lean)
      cp "$here/toolchain.json" "$manifest"
      ln -s "$(command -v lake)" "$fake_bin/lake"
      ;;
    library-outside-lean)
      jq '.tools.lean.libraries[0].storePath = .tools.node.outPath' \
        "$here/toolchain.json" >"$manifest"
      ;;
    missing-library-list)
      jq '.tools.lean.libraries = []' "$here/toolchain.json" >"$manifest"
      ;;
    missing-library-entry)
      jq 'del(.tools.lean.libraries[1])' "$here/toolchain.json" >"$manifest"
      ;;
    wrong-nixpkgs-source)
      jq '.nix.nixpkgs.storePath = .tools.node.outPath' \
        "$here/toolchain.json" >"$manifest"
      ;;
    *)
      echo "unknown toolchain mutation: $mutation" >&2
      return 2
      ;;
  esac
  if [[ "$mutation" == "lake-outside-lean" ]]; then
    if PATH="$fake_bin:$PATH" audit_toolchain "$manifest"; then
      echo "mutation survived: $mutation" >&2
      return 1
    fi
  elif audit_toolchain "$manifest"; then
    echo "mutation survived: $mutation" >&2
    return 1
  fi
  echo "toolchain mutation: KILLED $mutation"
}

audit_toolchain_suite() {
  local mutation
  audit_toolchain || return 1
  for mutation in \
    wrong-deriver \
    lake-outside-lean \
    library-outside-lean \
    missing-library-list \
    missing-library-entry \
    wrong-nixpkgs-source; do
    audit_toolchain_mutation "$mutation" || return 1
  done
  echo "toolchain tests: 6 mutations killed"
}

clear_generated_spike_artifacts() {
  local generated_directory
  for generated_directory in \
    "$here/durability/__pycache__" \
    "$here/formal/.lake"; do
    if [[ -d "$generated_directory" ]]; then
      find "$generated_directory" -depth -delete
    fi
  done
  if [[ -f "$here/formal/lake-manifest.json" ]]; then
    unlink "$here/formal/lake-manifest.json"
  fi
}

artifact_hygiene_case() {
  local artifact failure=0
  clear_generated_spike_artifacts
  node "$here/formal/audit.mjs" --case required-theorems-proof-bound || return 1
  env -u PYTHONDONTWRITEBYTECODE \
    bash "$here/durability/test.sh" --case pure-model-transitions || return 1
  for artifact in \
    "$here/durability/__pycache__" \
    "$here/formal/.lake" \
    "$here/formal/lake-manifest.json"; do
    if [[ -e "$artifact" ]]; then
      echo "generated artifact survived: ${artifact#"$here/"}" >&2
      failure=1
    fi
  done
  clear_generated_spike_artifacts
  return "$failure"
}

run_group() {
  local name="$1"
  shift
  echo "== $name =="
  if "$@"; then
    echo "PASS group/$name"
  else
    echo "FAIL group/$name" >&2
    failures=$((failures + 1))
  fi
}

if [[ "${1:-}" == "--toolchain-case" ]]; then
  audit_toolchain_mutation "$2"
  exit
fi
if [[ "${1:-}" == "--artifact-hygiene-case" ]]; then
  artifact_hygiene_case
  exit
fi

run_group toolchain audit_toolchain_suite
run_group normalization node --expose-internals "$here/normalization/dependency-audit.mjs" --all
run_group formal node "$here/formal/audit.mjs" --all
run_group durability bash "$here/durability/test.sh"
run_group artifact-hygiene artifact_hygiene_case

if (( failures != 0 )); then
  echo "packet-e assurance spikes: $failures group(s) failed" >&2
  exit 1
fi

echo "packet-e assurance spikes: PASS"
