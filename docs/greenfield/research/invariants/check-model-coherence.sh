#!/usr/bin/env bash
#
# Semantic-coherence gate.
#
# This repository deliberately duplicates definitions across independent
# oracles, so that no component defines its own correctness. That duplication
# is load-bearing and must not be collapsed: it is what makes a coordinated
# mutation detectable rather than merely inconsistent.
#
# What was missing is comparison. A definition stated in five places with
# nothing comparing the copies drifts silently, and a *missing* copy is
# invisible to any check that only compares the copies that exist.
#
# This script compares every duplicated definition and fails loudly on
# divergence. It does not replace any validator; it establishes that the
# validators are all talking about the same product.
#
# Run it first. A drifted vocabulary makes every downstream result untrustworthy.

set -euo pipefail

script_dir="$(CDPATH= cd -- "$(dirname -- "${BASH_SOURCE[0]}")" && pwd)"
research_dir="$(CDPATH= cd -- "${script_dir}/.." && pwd)"
repo_root="$(CDPATH= cd -- "${research_dir}/../.." && pwd)"

corpus="${research_dir}/CONFIGURATION-LANGUAGE-CORPUS.md"
protocol="${research_dir}/INVARIANT-ENFORCEMENT.md"
registry="${script_dir}/invariants.json"
paths_doc="${script_dir}/PACKET-D-COMPOSITION-PATHS.json"
case_contracts="${script_dir}/PACKET-D-CASE-CONTRACTS.json"

work="$(mktemp -d)"
trap 'rm -rf -- "${work}"' EXIT

pass_count=0
fail_count=0

pass() { pass_count=$((pass_count + 1)); }

fail() {
  fail_count=$((fail_count + 1))
  echo "FAIL $1"
  if [[ $# -gt 1 ]]; then
    printf '%s\n' "${@:2}" | sed 's/^/    /'
  fi
}

# compare <check-name> <expected-label> <actual-label> <expected-file> <actual-file>
compare() {
  local name="$1" want_label="$2" got_label="$3" want="$4" got="$5"
  if diff -q "${want}" "${got}" >/dev/null 2>&1; then
    pass
  else
    fail "${name}: ${want_label} != ${got_label}" \
      "$(diff -u --label "${want_label}" --label "${got_label}" "${want}" "${got}" | tail -n +3)"
  fi
}

# ---------------------------------------------------------------------------
# Extractors.
#
# Each source kind is EVALUATED in its own language rather than pattern-matched,
# so that formatting differences (one value per line vs several, trailing
# commas, indentation) never masquerade as semantic drift. All extractors emit
# canonical compact JSON so the comparisons are pure text diffs.
# ---------------------------------------------------------------------------

# Print the body of a top-level `def <name>:` block from a .jq file, tracking
# bracket depth so nested structures terminate correctly.
jq_def_block() {
  local file="$1" name="$2"
  awk -v want="def ${name}:" '
    index($0, want) == 1 { collecting = 1 }
    collecting {
      print
      n = gsub(/[[{]/, "&"); depth += n
      n = gsub(/[]}]/, "&"); depth -= n
      if (depth <= 0 && /;[[:space:]]*$/) { exit }
    }
  ' "${file}"
}

# Evaluate a jq def and emit its value as canonical JSON.
jq_def_value() {
  local file="$1" name="$2"
  local block
  block="$(jq_def_block "${file}" "${name}")"
  if [[ -z "${block}" ]]; then
    echo "__MISSING__"
    return 0
  fi
  jq -cn "${block} ${name}" 2>/dev/null || echo "__UNPARSEABLE__"
}

# Evaluate a JS literal out of a .mjs file. `eval` rather than JSON.parse
# because these literals legitimately carry trailing commas and Map wrappers.
mjs_literal() {
  local file="$1" pattern="$2"
  node -e '
    const fs = require("fs");
    const source = fs.readFileSync(process.argv[1], "utf8");
    const match = source.match(new RegExp(process.argv[2]));
    if (!match) { console.log("__MISSING__"); process.exit(0); }
    let value = eval("(" + match[1] + ")");
    if (value instanceof Map) value = Object.fromEntries(value);
    const sortDeep = (v) =>
      Array.isArray(v) ? v.map(sortDeep)
      : (v && typeof v === "object")
        ? Object.fromEntries(Object.keys(v).sort().map((k) => [k, sortDeep(v[k])]))
        : v;
    console.log(JSON.stringify(sortDeep(value)));
  ' "${file}" "${pattern}"
}

# Emit "ID<TAB>Label" for each row of the markdown table whose header line
# contains the given marker.
md_table() {
  local file="$1" marker="$2"
  awk -v marker="${marker}" '
    index($0, marker) { collecting = 1; next }
    collecting && /^\|[[:space:]]*-+/ { next }
    collecting && /^\|/ {
      split($0, cell, "|")
      id = cell[2]; label = cell[3]
      gsub(/`/, "", id); gsub(/^[[:space:]]+|[[:space:]]+$/, "", id)
      gsub(/^[[:space:]]+|[[:space:]]+$/, "", label)
      print id "\t" label
      next
    }
    collecting { exit }
  ' "${file}"
}

# Emit "ID<TAB>Label" for each labelled mermaid node.
mermaid_nodes() {
  local file="$1"
  grep -oE '[A-Z][A-Z0-9]*\["[A-Z][A-Z0-9]* [^"]+"\]' "${file}" |
    sed -E 's/^([A-Z][A-Z0-9]*)\["[A-Z][A-Z0-9]* ([^"]+)"\]$/\1\t\2/' |
    sort -u
}

json_sorted_array() { jq -c 'sort' <<<"$1"; }

echo "checking model coherence"

# ---------------------------------------------------------------------------
# 1. The phase succession graph is identical across all three machine copies.
#
# This is the single authority for phase reachability. It is duplicated so that
# the registry validator, the coverage validator, and the coverage generator
# each carry their own statement of it and can disagree detectably.
# ---------------------------------------------------------------------------

jq -S . <<<"$(jq_def_value "${script_dir}/validate-registry.jq" phase_edges)" \
  >"${work}/edges-registry.json"
jq -S . <<<"$(jq_def_value "${script_dir}/validate-composition-coverage.jq" phase_edges)" \
  >"${work}/edges-coverage.json"
jq -S . <<<"$(mjs_literal "${script_dir}/generate-composition-coverage.mjs" \
  'const edges = (new Map\([\s\S]*?\n\));')" \
  >"${work}/edges-generator.json"

compare "phase-graph" \
  "validate-registry.jq phase_edges" \
  "validate-composition-coverage.jq phase_edges" \
  "${work}/edges-registry.json" "${work}/edges-coverage.json"

compare "phase-graph" \
  "validate-composition-coverage.jq phase_edges" \
  "generate-composition-coverage.mjs edges" \
  "${work}/edges-coverage.json" "${work}/edges-generator.json"

# ---------------------------------------------------------------------------
# 2. The phase universe agrees across all five copies, including the two that
#    no validator reads. The corpus table and the mermaid diagram are prose,
#    which is exactly why they rot: the corpus table sat at 20 rows against a
#    23-phase vocabulary while the corpus itself assigned the three missing
#    phases to invariants 15 times.
# ---------------------------------------------------------------------------

jq -r '.[]' <<<"$(jq_def_value "${script_dir}/validate-registry.jq" phase_order)" |
  sort >"${work}/phases-order.txt"
jq -r 'to_entries | map(.key, .value[]) | flatten | unique | .[]' \
  "${work}/edges-registry.json" | sort >"${work}/phases-graph.txt"
md_table "${corpus}" '| Phase | Label |' | cut -f1 | sort >"${work}/phases-corpus.txt"
mermaid_nodes "${protocol}" | cut -f1 | sort >"${work}/phases-mermaid.txt"

compare "phase-universe" \
  "validate-registry.jq phase_order" "phase_edges node set" \
  "${work}/phases-order.txt" "${work}/phases-graph.txt"

compare "phase-universe" \
  "validate-registry.jq phase_order" "CONFIGURATION-LANGUAGE-CORPUS.md phase table" \
  "${work}/phases-order.txt" "${work}/phases-corpus.txt"

compare "phase-universe" \
  "validate-registry.jq phase_order" "INVARIANT-ENFORCEMENT.md mermaid" \
  "${work}/phases-order.txt" "${work}/phases-mermaid.txt"

# ---------------------------------------------------------------------------
# 3. Phase labels agree between the corpus table and the mermaid diagram.
#    R0 read "Runtime launch" in one and "Sandbox launch" in the other. Under
#    the locked Packet E vocabulary those are different claims: the Sandbox
#    aggregate persists across epochs and the runtime does not.
# ---------------------------------------------------------------------------

md_table "${corpus}" '| Phase | Label |' | sort >"${work}/labels-corpus.txt"
mermaid_nodes "${protocol}" | sort >"${work}/labels-mermaid.txt"

compare "phase-labels" \
  "CONFIGURATION-LANGUAGE-CORPUS.md phase table" \
  "INVARIANT-ENFORCEMENT.md mermaid" \
  "${work}/labels-corpus.txt" "${work}/labels-mermaid.txt"

# ---------------------------------------------------------------------------
# 4. The closed owner set agrees across all four machine copies. Adding an
#    owner to fewer than four produces three different and unrelated-looking
#    failures, one of which throws before the generator writes anything.
# ---------------------------------------------------------------------------

json_sorted_array "$(jq_def_value "${script_dir}/validate-registry.jq" owners)" \
  >"${work}/owners-registry.json"
json_sorted_array "$(jq_def_value "${script_dir}/validate-surface-coverage.jq" owners)" \
  >"${work}/owners-surface.json"
json_sorted_array "$(jq_def_value "${script_dir}/validate-composition-coverage.jq" owners)" \
  >"${work}/owners-coverage.json"
json_sorted_array "$(mjs_literal "${script_dir}/generate-composition-coverage.mjs" \
  'const owners = (\[[\s\S]*?\]);')" >"${work}/owners-generator.json"

compare "owner-set" "validate-registry.jq owners" "validate-surface-coverage.jq owners" \
  "${work}/owners-registry.json" "${work}/owners-surface.json"
compare "owner-set" "validate-registry.jq owners" "validate-composition-coverage.jq owners" \
  "${work}/owners-registry.json" "${work}/owners-coverage.json"
compare "owner-set" "validate-registry.jq owners" "generate-composition-coverage.mjs owners" \
  "${work}/owners-registry.json" "${work}/owners-generator.json"

# The corpus owners table is the human-facing copy of the same closed set.
md_table "${corpus}" '| Owner ID | Owner |' | cut -f1 | sort >"${work}/owners-corpus.txt"
jq -r '.[]' "${work}/owners-registry.json" | sort >"${work}/owners-registry.txt"
if [[ -s "${work}/owners-corpus.txt" ]]; then
  compare "owner-set" "validate-registry.jq owners" \
    "CONFIGURATION-LANGUAGE-CORPUS.md owners table" \
    "${work}/owners-registry.txt" "${work}/owners-corpus.txt"
else
  fail "owner-set: CONFIGURATION-LANGUAGE-CORPUS.md owners table not extractable" \
    "expected a table whose header contains '| Owner | Resource'"
fi

# ---------------------------------------------------------------------------
# 5. Every ledger validator DEFINES the placeholder rule, and every definition
#    is byte-identical.
#
#    The identity half is an ordinary diff. The existence half is the point:
#    validate-composition-coverage.jq carries no placeholder rule at all, and
#    no check that only compares existing copies could ever notice.
# ---------------------------------------------------------------------------

ledger_validators=(
  validate-registry.jq
  validate-surface-coverage.jq
  validate-artifact-field-review.jq
  validate-target-realization.jq
  validate-provider-contracts.jq
  validate-composition-coverage.jq
)

reference_placeholder=""
for validator in "${ledger_validators[@]}"; do
  block="$(jq_def_block "${script_dir}/${validator}" placeholder_strings)"
  if [[ -z "${block}" ]]; then
    fail "placeholder-rule: ${validator} defines no placeholder_strings" \
      "every ledger validator must reject TBD/TODO/FIXME/UNKNOWN content;" \
      "a missing definition is invisible to a copy-versus-copy comparison"
    continue
  fi
  printf '%s\n' "${block}" >"${work}/placeholder-${validator}.txt"
  if [[ -z "${reference_placeholder}" ]]; then
    reference_placeholder="${validator}"
    pass
  else
    compare "placeholder-rule" "${reference_placeholder}" "${validator}" \
      "${work}/placeholder-${reference_placeholder}.txt" \
      "${work}/placeholder-${validator}.txt"
  fi
done

# ---------------------------------------------------------------------------
# 6. Each digest pin agrees between the validator's internal def and
#    check-inventory.sh. The duplication is intentional -- check-inventory.sh
#    aborts on a pin mismatch before any validator runs -- so the two copies
#    must move together or the early abort guards a stale value.
# ---------------------------------------------------------------------------

# Every validator that carries a pin, not just the first one found. A third copy of the
# registry pin lives in validate-operation-contracts.jq; missing it let a stale pin ship.
for pin in \
  "validate-composition-coverage.jq:expected_paths_registry_sha256:${paths_doc}" \
  "validate-composition-coverage.jq:expected_case_contracts_sha256:${case_contracts}" \
  "validate-composition-coverage.jq:expected_invariant_registry_sha256:${registry}" \
  "validate-operation-contracts.jq:expected_invariant_registry_sha256:${registry}" \
  "validate-operation-contracts.jq:expected_operation_registry_sha256:${script_dir}/PACKET-E-OPERATION-REGISTRY.json" \
  "validate-operation-contracts.jq:expected_case_contracts_sha256:${script_dir}/PACKET-E-CASE-CONTRACTS.json"; do
  validator_file="${pin%%:*}"
  rest="${pin#*:}"
  def_name="${rest%%:*}"
  target_file="${rest##*:}"
  in_validator="$(jq_def_value "${script_dir}/${validator_file}" "${def_name}" |
    jq -r '.' 2>/dev/null || echo "__MISSING__")"
  actual="$(shasum -a 256 "${target_file}" | awk '{print $1}')"
  if [[ "${in_validator}" == "__MISSING__" ]]; then
    fail "digest-pin ${validator_file}/${def_name}: not defined"
  elif [[ "${in_validator}" != "${actual}" ]]; then
    fail "digest-pin ${validator_file}/${def_name}: validator pin does not match the file it names" \
      "validator: ${in_validator}" "actual:    ${actual}"
  elif ! grep -q "${actual}" "${script_dir}/check-inventory.sh"; then
    fail "digest-pin ${validator_file}/${def_name}: check-inventory.sh does not carry the same pin" \
      "expected ${actual} to appear in check-inventory.sh"
  else
    pass
  fi
done

# ---------------------------------------------------------------------------
# 7. Orphaned valid corpus witnesses.
#
#    validate-registry.sh checks registry -> corpus. This is the missing
#    mirror: a VAL case defined in the corpus and referenced by nothing is
#    dead weight that reads as coverage.
# ---------------------------------------------------------------------------

rg -o --replace '$1' '^### `((?:VAL)-[0-9]{3})`' "${corpus}" | sort -u \
  >"${work}/val-corpus.txt"
jq -r '[.invariants[].validWitnesses[]] | unique | .[]' "${registry}" |
  grep -E '^VAL-[0-9]{3}$' | sort -u >"${work}/val-referenced.txt"

if orphans="$(comm -23 "${work}/val-corpus.txt" "${work}/val-referenced.txt")" &&
  [[ -z "${orphans}" ]]; then
  pass
else
  fail "orphan-valid-witness: defined in the corpus, referenced by no invariant" \
    "${orphans}"
fi

# ---------------------------------------------------------------------------
# 8. Every locked composition path is nameable from some registry alias.
#    A path no invariant can name is a path no invariant can carry evidence
#    for, so its column of the coverage matrix is unreachable from the registry.
# ---------------------------------------------------------------------------

jq -r '[.paths[].id] | sort | .[]' "${paths_doc}" >"${work}/paths-locked.txt"
jq -r '[.registryPathAliases[]] | unique | .[]' "${paths_doc}" >"${work}/paths-named.txt"

if unnameable="$(comm -23 "${work}/paths-locked.txt" "${work}/paths-named.txt")" &&
  [[ -z "${unnameable}" ]]; then
  pass
else
  fail "unnameable-path: locked Packet D path targeted by no registryPathAliases value" \
    "${unnameable}"
fi

# ---------------------------------------------------------------------------
# 9. Every active-effect classification cell has a declaring composition path.
#
#    Per-path evidence obligations are derived only from an invariant's
#    compositionPaths. A cell classified may-contribute / may-narrow /
#    may-select on a path the invariant never declares therefore asserts an
#    active effect that carries no test obligation at inventory or at closure.
# ---------------------------------------------------------------------------

jq -r --slurpfile registry "${registry}" --slurpfile paths "${paths_doc}" '
  ($paths[0].registryPathAliases) as $aliases |
  ($registry[0].invariants) as $invariants |
  (.reviewedInvariantIds) as $ids |
  [
    .classificationVectorsByPath | to_entries[] |
    .key as $path |
    (.value | split("")) as $codes |
    range(0; $ids | length) |
    select($codes[.] | test("[CNS]")) |
    {path: $path, id: $ids[.]}
  ] |
  map(
    . as $cell |
    ($invariants[] | select(.id == $cell.id)) as $invariant |
    ($invariant.compositionPaths | map($aliases[.]) | unique) as $declared |
    select($declared | index($cell.path) | not) |
    "\($cell.id) -> \($cell.path)"
  ) | sort | .[]
' "${case_contracts}" >"${work}/active-uncovered.txt" 2>/dev/null || true

if [[ ! -s "${work}/active-uncovered.txt" ]]; then
  pass
else
  fail "active-effect-uncovered: classified C/N/S on a path the invariant does not declare" \
    "$(wc -l <"${work}/active-uncovered.txt" | tr -d ' ') pairs; first 12:" \
    "$(head -12 "${work}/active-uncovered.txt")"
fi

# ---------------------------------------------------------------------------
# 10. Every declared trust boundary has covering test evidence. This mirrors
#     the per-element loop the registry validator already runs for
#     compositionPaths, which trustBoundaries never received.
# ---------------------------------------------------------------------------

jq -r '
  [
    .invariants[] |
    . as $invariant |
    ([$invariant.tests[]?.covers[]?] | unique) as $covered |
    $invariant.trustBoundaries[] |
    select([.] | inside($covered) | not) |
    "\($invariant.id) \(.)"
  ] | sort | .[]
' "${registry}" >"${work}/trust-unevidenced.txt"

if [[ ! -s "${work}/trust-unevidenced.txt" ]]; then
  pass
else
  fail "trust-boundary-unevidenced: declared boundary listed in no test's covers" \
    "$(cat "${work}/trust-unevidenced.txt")"
fi

# ---------------------------------------------------------------------------
# 11. The registry length and the Packet D universe agree with every literal
#     that pins them. These absolute counts are drift detection by design; the
#     failure mode is that the copies stop agreeing with each other.
# ---------------------------------------------------------------------------

registry_length="$(jq '.invariants | length' "${registry}")"
reviewed_length="$(jq '.reviewedInvariantIds | length' "${case_contracts}")"
path_count="$(jq '.paths | length' "${paths_doc}")"
expected_cells=$((path_count * registry_length))

if [[ "${registry_length}" != "${reviewed_length}" ]]; then
  fail "count-consistency: registry length != reviewedInvariantIds length" \
    "invariants.json: ${registry_length}" \
    "PACKET-D-CASE-CONTRACTS.json: ${reviewed_length}"
else
  pass
fi

vector_widths="$(jq -r '[.classificationVectorsByPath[] | length] | unique | @csv' \
  "${case_contracts}")"
if [[ "${vector_widths}" != "${registry_length}" ]]; then
  fail "count-consistency: classification vectors are not all the registry length" \
    "registry length: ${registry_length}" "vector widths present: ${vector_widths}"
else
  pass
fi

# The alias-vocabulary size is pinned in the validator and quoted in four prose
# documents. Until this check existed the literal sat outside every automated
# comparison, so the prose copies could drift silently.
alias_count="$(jq '.registryPathAliases | length' "${paths_doc}")"
if grep -q "== ${alias_count}" "${script_dir}/validate-composition-coverage.jq" &&
  grep -q "${alias_count}-alias" "${script_dir}/validate-composition-coverage.jq" &&
  grep -q "${alias_count}-alias" "${script_dir}/test-composition-coverage.sh"; then
  pass
else
  fail "count-consistency: alias vocabulary size ${alias_count} not pinned in validator and harness" \
    "expected '== ${alias_count}' and '${alias_count}-alias' in validate-composition-coverage.jq," \
    "and '${alias_count}-alias' in test-composition-coverage.sh"
fi

# Every alias target must be a real locked path, and every locked path must be
# nameable (check 8 above). Together these keep the vocabulary anchored.
if unknown_targets="$(jq -r --slurpfile p "${paths_doc}" '
  ([$p[0].paths[].id]) as $ids |
  [.registryPathAliases | to_entries[] | select(.value | IN($ids[]) | not) |
   "\(.key) -> \(.value)"] | .[]' "${paths_doc}")" &&
  [[ -z "${unknown_targets}" ]]; then
  pass
else
  fail "alias-target-unknown: alias points at something that is not a locked path" \
    "${unknown_targets}"
fi

for literal_site in \
  "check-inventory.sh:${registry_length}" \
  "check-inventory.sh:${expected_cells}" \
  "generate-composition-coverage.mjs:${registry_length}" \
  "generate-composition-coverage.mjs:${expected_cells}"; do
  site_file="${literal_site%%:*}"
  wanted="${literal_site##*:}"
  if grep -q "${wanted}" "${script_dir}/${site_file}"; then
    pass
  else
    fail "count-consistency: ${site_file} does not mention the current value ${wanted}" \
      "the pinned literals must be re-stated whenever the registry length changes"
  fi
done

echo "model coherence: ${pass_count} checks passed, ${fail_count} failed"
[[ "${fail_count}" -eq 0 ]]
