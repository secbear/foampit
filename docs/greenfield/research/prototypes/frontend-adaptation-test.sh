#!/usr/bin/env bash
set -euo pipefail

prototype_root="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
adapter="$prototype_root/comparison-portable-value.jq"
tmp_root="$(mktemp -d)"
trap 'rm -rf "$tmp_root"' EXIT

jq -n '{
  schemaVersion: 1,
  profile: {
    selected: "workspace-edit-offline",
    selectionIsVisible: true
  },
  environment: {
    packages: [{input: "nixpkgs", attribute: "hello"}],
    variables: {EDITOR: "vi"},
    activation: ["bash"]
  },
  workspace: {
    destination: "/workspace",
    materialization: "copy",
    allowedMaterializations: ["copy"],
    access: "read-write"
  },
  network: {
    mode: "none",
    egressAllow: [],
    hardPolicy: {allowedDestinations: []}
  },
  secrets: [{name: "agent-api-token", delivery: "environment"}],
  resources: {
    memory: {
      minimumBytes: 536870912,
      maximumBytes: 4294967296
    }
  },
  targets: ["bubblewrap", "firecracker"],
  requiredCapabilities: ["network.none", "workspace.copy"],
  runtimeProfiles: {
    "bubblewrap-copy": {
      target: "bubblewrap",
      materializations: ["copy"]
    },
    "firecracker-copy": {
      target: "firecracker",
      materializations: ["copy"]
    }
  }
}' >"$tmp_root/valid.json"

jq -e -f "$adapter" "$tmp_root/valid.json" >"$tmp_root/portable.json"
printf 'ok - total adapter accepts the exact frontend shape\n'

expect_invalid_mutation() {
  local mutation="$1"
  jq "$mutation" "$tmp_root/valid.json" >"$tmp_root/invalid.json"
  if jq -e -f "$adapter" "$tmp_root/invalid.json" >/dev/null 2>"$tmp_root/error"; then
    printf 'not ok - lossy frontend adaptation accepted mutation %s\n' "$mutation" >&2
    exit 1
  fi
  rg -F 'WIRE-005' "$tmp_root/error" >/dev/null
}

for mutation in \
  '.schemaVersion = 2' \
  '.semanticSurprise = true' \
  '.workspace.semanticSurprise = true' \
  '.environment.packages[0].semanticSurprise = true' \
  '.runtimeProfiles["bubblewrap-copy"].semanticSurprise = true' \
  'del(.profile.selected)' \
  'del(.environment.packages)' \
  'del(.runtimeProfiles["bubblewrap-copy"].target)' \
  '.profile.selectionIsVisible = "true"' \
  '.environment.packages[0].input = 1' \
  '.workspace.access = "owner"' \
  '.network.mode = "offline"' \
  '.secrets[0].delivery = "socket"' \
  '.resources.memory.minimumBytes = 1.5' \
  '.targets = "bubblewrap"' \
  '.runtimeProfiles["bubblewrap-copy"].materializations = "copy"'
do
  expect_invalid_mutation "$mutation"
done

jq '
  .workspace.materialization = "live"
  | .workspace.allowedMaterializations = ["live"]
  | .workspace.access = "read-only"
  | .network.mode = "egress"
  | .network.egressAllow = ["api.example.test"]
  | .network.hardPolicy.allowedDestinations = ["api.example.test"]
  | .targets = ["bubblewrap"]
  | .requiredCapabilities = ["network.egress", "workspace.live"]
  | .runtimeProfiles = {
      "bubblewrap-live": {
        target: "bubblewrap",
        materializations: ["live"]
      }
    }
' "$tmp_root/valid.json" >"$tmp_root/valid-alternates.json"
jq -e -f "$adapter" "$tmp_root/valid-alternates.json" >"$tmp_root/portable-alternates.json"
jq -e '
  .workspace.access == "readOnly"
  and .network.mode == "egress"
  and .requiredCapabilities == ["network.egress", "workspace.live"]
' "$tmp_root/portable-alternates.json" >/dev/null
printf 'ok - total adapter accepts every supported translated value\n'

printf 'frontend adaptation prototype: 18 cases passed\n'
