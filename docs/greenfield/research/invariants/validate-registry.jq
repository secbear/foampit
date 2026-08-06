def phase_order:
  [
    "P0", "P1", "OC0", "MS0", "A0", "A1", "W0", "N0", "N1",
    "F0", "S0", "RW0", "C0", "O0", "H0", "D0", "R0", "R1",
    "L0", "L1", "E0", "E1", "T0"
  ];

# The product-phase succession graph. This is the single authority for phase
# reachability and is duplicated verbatim in validate-composition-coverage.jq
# and generate-composition-coverage.mjs so that no validator depends on
# another's definition. check-model-coherence.sh compares all three copies.
#
# This replaced a hand-enumerated list of 24 linear phase paths, which admitted
# 231 ordered pairs against this graph's 233 and disagreed on four:
# P0 -> OC0, P0 -> MS0, and P0 -> S0 were wrongly rejected, and OC0 -> C0 was
# wrongly accepted. OC0 -> C0 contradicted the locked Operator Configuration
# branch P1 -> OC0/O0 (DESIGN.md:117): the enumeration routed ["P1","OC0"] into
# the launch phases, which begin at C0. No registry entry used any of the four.
def phase_edges:
  {
    "P0": ["P1"],
    "P1": ["A0", "OC0", "MS0"],
    "A0": ["A1"],
    "A1": ["W0"],
    "W0": ["N0"],
    "N0": ["N1"],
    "N1": ["C0"],
    "F0": ["C0", "L0", "E0", "T0"],
    "OC0": ["O0"],
    "MS0": ["S0"],
    "S0": ["C0", "L0", "E0", "T0"],
    "RW0": ["C0"],
    "C0": ["O0"],
    "O0": ["H0"],
    "H0": ["D0"],
    "D0": ["R0"],
    "R0": ["R1"],
    "R1": ["L0", "E0", "T0"],
    "L0": ["L1"],
    "L1": ["T0"],
    "E0": ["E1"],
    "E1": ["T0"]
  };

def owners:
  [
    "artifact",
    "create",
    "operator",
    "service",
    "live",
    "exec",
    "framework",
    "runtime",
    "core"
  ];

def scopes:
  ["v1", "future", "research"];

def statuses:
  ["specified", "fixture-complete", "prototype-enforced", "closed", "deferred"];

def dispositions:
  [
    "unrepresentable",
    "reject-at-boundary",
    "dynamic-preflight",
    "observed-conformance"
  ];

def hook_roles:
  ["authoritative", "defensive", "observational"];

def hook_statuses:
  ["planned", "prototype", "production"];

def test_kinds:
  [
    "source-rejection",
    "construction-exclusion",
    "positive-boundary",
    "composition-bypass",
    "wire-corruption",
    "target-conformance",
    "dynamic-preflight",
    "runtime-probe",
    "diagnostic"
  ];

def test_statuses:
  ["planned", "passing"];

def nonempty_string:
  type == "string" and length > 0;

def string_array:
  type == "array" and all(.[]; type == "string" and length > 0);

def nonempty_string_array:
  string_array and length > 0;

# A boundary at which a serialized, product-owned representation is decoded and
# revalidated. `wire-corruption` is defined as "a malformed/corrupted FRONTEND RESULT is
# rejected by the next trust boundary", so the obligation belongs to these boundaries and
# not to in-process Core boundaries such as core-api, live-operation-dispatch,
# process-launch, idempotency-store, or driver-preparation, which receive a private
# product-owned stage rather than a decoded representation.
def decoding_trust_boundaries:
  [
    "canonical-wire",
    "frontend-adaptation",
    "frontend-evaluation",
    "schema-migration",
    "raw-wire-input",
    "resolved-reentry-wire",
    "built-manifest",
    "artifact-manifest-load",
    "provider-build-result",
    "provider-transport",
    "provider-cache",
    "nix-construction",
    "generated-service-unit"
  ];

def decodes_a_representation($invariant):
  any($invariant.trustBoundaries[]?;
      . as $b | decoding_trust_boundaries | index($b) != null);

def placeholder_strings:
  [
    .. |
    strings |
    select(test("^(TBD|TODO|FIXME)(:|\\b|$)|^UNKNOWN$"; "i"))
  ];

def phase_index($phase):
  phase_order | index($phase);

# Visited-set-guarded transitive closure. The guard is not an optimization:
# unguarded recursion over a graph containing any cycle exhausts memory instead
# of reporting, which is how a cycle-detection check can become structurally
# incapable of diagnosing the failure it names. $seen grows monotonically and is
# bounded by the node count, so this is total on any graph, cyclic or not.
def phase_closure($frontier; $seen):
  if ($frontier | length) == 0
  then $seen
  else
    ($frontier[0]) as $node |
    ($frontier[1:]) as $rest |
    if ($seen | index($node)) != null
    then phase_closure($rest; $seen)
    else phase_closure(($rest + (phase_edges[$node] // [])); ($seen + [$node]))
    end
  end;

def phase_descendants($phase):
  phase_closure((phase_edges[$phase] // []); []) | unique;

def phase_reachable($from; $to):
  (phase_order | index($from)) != null and
  (phase_order | index($to)) != null and
  (
    $from == $to or
    (phase_descendants($from) | index($to)) != null
  );

def inv_error($invariant; $message):
  "\($invariant.id // "<missing-id>"): \($message)";

def has_test($invariant; $kind):
  any($invariant.tests[]?; .kind == $kind);

def planned_test_covers($invariant; $value):
  any($invariant.tests[]?;
      any(.covers[]?; . == $value));

def planned_test_targets($invariant; $value):
  any($invariant.tests[]?;
      any(.targets[]?; . == $value));

def common_invariant_errors($invariant):
  [
    if ($invariant.id | nonempty_string) and
       ($invariant.id | test("^[A-Z][A-Z0-9]*-[0-9]{3}$"))
    then empty
    else inv_error($invariant; "id must match ^[A-Z][A-Z0-9]*-[0-9]{3}$")
    end,

    if $invariant.title | nonempty_string
    then empty
    else inv_error($invariant; "title must be non-empty")
    end,

    if $invariant.statement | nonempty_string
    then empty
    else inv_error($invariant; "statement must be non-empty")
    end,

    if owners | index($invariant.owner)
    then empty
    else inv_error($invariant; "unknown owner: \($invariant.owner // "<missing>")")
    end,

    if scopes | index($invariant.scope)
    then empty
    else inv_error($invariant; "unknown scope: \($invariant.scope // "<missing>")")
    end,

    if statuses | index($invariant.status)
    then empty
    else inv_error($invariant; "unknown status: \($invariant.status // "<missing>")")
    end,

    if phase_order | index($invariant.firstSoundPhase)
    then empty
    else inv_error($invariant; "unknown firstSoundPhase: \($invariant.firstSoundPhase // "<missing>")")
    end,

    if phase_order | index($invariant.rejectionDeadline)
    then empty
    else inv_error($invariant; "unknown rejectionDeadline: \($invariant.rejectionDeadline // "<missing>")")
    end,

    if (phase_index($invariant.firstSoundPhase) != null) and
       (phase_index($invariant.rejectionDeadline) != null) and
       (phase_reachable($invariant.firstSoundPhase;
                        $invariant.rejectionDeadline) | not)
    then inv_error($invariant; "rejectionDeadline is not reachable from firstSoundPhase")
    else empty
    end,

    if dispositions | index($invariant.disposition)
    then empty
    else inv_error($invariant; "unknown disposition: \($invariant.disposition // "<missing>")")
    end,

    if $invariant.rationale | nonempty_string
    then empty
    else inv_error($invariant; "rationale must be non-empty")
    end,

    if $invariant.invalidWitnesses | nonempty_string_array
    then empty
    else inv_error($invariant; "invalidWitnesses must be non-empty")
    end,

    if $invariant.validWitnesses | nonempty_string_array
    then empty
    else inv_error($invariant; "validWitnesses must be non-empty")
    end,

    if $invariant.targets | nonempty_string_array
    then empty
    else inv_error($invariant; "targets must be non-empty")
    end,

    if $invariant.trustBoundaries | nonempty_string_array
    then empty
    else inv_error($invariant; "trustBoundaries must be non-empty")
    end,

    if $invariant.compositionPaths | nonempty_string_array
    then empty
    else inv_error($invariant; "compositionPaths must be non-empty")
    end,

    if ($invariant.enforcementHooks | type == "array") and
       ($invariant.enforcementHooks | length > 0)
    then empty
    else inv_error($invariant; "enforcementHooks must be non-empty")
    end,

    if ($invariant.tests | type == "array") and ($invariant.tests | length > 0)
    then empty
    else inv_error($invariant; "tests must be non-empty")
    end,

    if ([ $invariant.enforcementHooks[]? |
          select(.role == "authoritative") ] | length) == 1
    then empty
    else inv_error($invariant; "inventory requires exactly one planned authoritative hook")
    end,

    if has_test($invariant; "positive-boundary")
    then empty
    else inv_error($invariant; "inventory requires planned positive-boundary evidence")
    end,

    if has_test($invariant; "diagnostic")
    then empty
    else inv_error($invariant; "inventory requires planned diagnostic evidence")
    end,

    if ($invariant.disposition == "reject-at-boundary") and
       (has_test($invariant; "source-rejection") | not)
    then inv_error($invariant; "inventory requires planned source-rejection evidence")
    else empty
    end,

    # `unrepresentable` accepts either kind. A value the schema cannot express has no
    # source text to reject, so `construction-exclusion` -- a compile- or schema-level
    # test that the supported API cannot name the value -- is the honest evidence.
    if ($invariant.disposition == "unrepresentable") and
       (has_test($invariant; "source-rejection") | not) and
       (has_test($invariant; "construction-exclusion") | not)
    then inv_error($invariant; "inventory requires planned source-rejection or construction-exclusion evidence")
    else empty
    end,

    if ($invariant.disposition == "dynamic-preflight") and
       (has_test($invariant; "dynamic-preflight") | not)
    then inv_error($invariant; "inventory requires planned dynamic-preflight evidence")
    else empty
    end,

    if ($invariant.disposition == "observed-conformance") and
       (has_test($invariant; "runtime-probe") | not)
    then inv_error($invariant; "inventory requires planned runtime-probe evidence")
    else empty
    end,

    if decodes_a_representation($invariant) and
       (has_test($invariant; "wire-corruption") | not)
    then inv_error($invariant; "inventory requires planned wire-corruption evidence")
    else empty
    end,

    (
      $invariant.compositionPaths[]? as $path |
      if planned_test_covers($invariant; $path)
      then empty
      else inv_error($invariant; "composition path lacks planned evidence: \($path)")
      end
    ),

    (
      $invariant.targets[]? as $target |
      if planned_test_targets($invariant; $target)
      then empty
      else inv_error($invariant; "target lacks planned evidence: \($target)")
      end
    ),

    if $invariant.diagnostic.identity | nonempty_string
    then empty
    else inv_error($invariant; "diagnostic.identity must be non-empty")
    end,

    if ($invariant.diagnostic.identity // "") == ($invariant.id // null)
    then empty
    else inv_error($invariant; "diagnostic.identity must equal invariant id")
    end,

    if $invariant.diagnostic.primaryPaths | nonempty_string_array
    then empty
    else inv_error($invariant; "diagnostic.primaryPaths must be non-empty")
    end,

    if $invariant.diagnostic.relatedPaths | string_array
    then empty
    else inv_error($invariant; "diagnostic.relatedPaths must be an array of strings")
    end,

    if $invariant.diagnostic.remediation | nonempty_string
    then empty
    else inv_error($invariant; "diagnostic.remediation must be non-empty")
    end,

    if ($invariant.diagnostic.secretSafe | type) == "boolean"
    then empty
    else inv_error($invariant; "diagnostic.secretSafe must be boolean")
    end,

    (
      $invariant.enforcementHooks[]? |
      if .phase as $phase | phase_order | index($phase)
      then empty
      else inv_error($invariant; "unknown enforcement-hook phase: \(.phase // "<missing>")")
      end,
      if .component | nonempty_string
      then empty
      else inv_error($invariant; "enforcement hook component must be non-empty")
      end,
      if .path | nonempty_string
      then empty
      else inv_error($invariant; "enforcement hook path must be non-empty")
      end,
      if .symbol | nonempty_string
      then empty
      else inv_error($invariant; "enforcement hook symbol must be non-empty")
      end,
      if .role as $role | hook_roles | index($role)
      then empty
      else inv_error($invariant; "unknown hook role: \(.role // "<missing>")")
      end,
      if .status as $status | hook_statuses | index($status)
      then empty
      else inv_error($invariant; "unknown hook status: \(.status // "<missing>")")
      end,
      if (.role // null) == "authoritative" and
         (phase_index(.phase) != null) and
         (phase_index($invariant.rejectionDeadline) != null) and
         (
           (phase_reachable($invariant.firstSoundPhase; .phase) | not) or
           (phase_reachable(.phase; $invariant.rejectionDeadline) | not)
         )
      then inv_error($invariant; "authoritative hook is later than rejectionDeadline")
      else empty
      end
    ),

    (
      $invariant.tests[]? |
      if .kind as $kind | test_kinds | index($kind)
      then empty
      else inv_error($invariant; "unknown test kind: \(.kind // "<missing>")")
      end,
      if .path | nonempty_string
      then empty
      else inv_error($invariant; "test path must be non-empty")
      end,
      if .case | nonempty_string
      then empty
      else inv_error($invariant; "test case must be non-empty")
      end,
      if .status as $status | test_statuses | index($status)
      then empty
      else inv_error($invariant; "unknown test status: \(.status // "<missing>")")
      end,
      if .covers | nonempty_string_array
      then empty
      else inv_error($invariant; "test covers must be non-empty")
      end,
      if .targets | nonempty_string_array
      then empty
      else inv_error($invariant; "test targets must be non-empty")
      end
    ),

    if ($invariant | placeholder_strings | length) == 0
    then empty
    else inv_error($invariant; "contains placeholder content")
    end
  ];

def has_passing_test($invariant; $kind):
  any($invariant.tests[]?;
      .kind == $kind and .status == "passing");

def passing_test_covers($invariant; $value):
  any($invariant.tests[]?;
      .status == "passing" and any(.covers[]?; . == $value));

def passing_test_targets($invariant; $value):
  any($invariant.tests[]?;
      .status == "passing" and any(.targets[]?; . == $value));

def closure_errors($invariant):
  [
    if $invariant.scope == "future" and $invariant.status == "deferred"
    then empty
    elif $invariant.status == "closed"
    then empty
    else inv_error($invariant; "closure requires status closed")
    end,

    if any($invariant.enforcementHooks[]?; .status == "planned")
    then inv_error($invariant; "closure forbids planned enforcement hooks")
    else empty
    end,

    if any($invariant.tests[]?; .status != "passing")
    then inv_error($invariant; "closure requires passing tests")
    else empty
    end,

    if ([ $invariant.enforcementHooks[]? |
          select(.role == "authoritative") ] | length) == 1
    then empty
    else inv_error($invariant; "closure requires exactly one authoritative hook")
    end,

    if has_passing_test($invariant; "positive-boundary")
    then empty
    else inv_error($invariant; "closure requires positive-boundary evidence")
    end,

    if has_passing_test($invariant; "diagnostic")
    then empty
    else inv_error($invariant; "closure requires diagnostic evidence")
    end,

    if ($invariant.disposition == "reject-at-boundary") and
       (has_passing_test($invariant; "source-rejection") | not)
    then inv_error($invariant; "closure requires source-rejection evidence")
    else empty
    end,

    if ($invariant.disposition == "unrepresentable") and
       (has_passing_test($invariant; "source-rejection") | not) and
       (has_passing_test($invariant; "construction-exclusion") | not)
    then inv_error($invariant; "closure requires source-rejection or construction-exclusion evidence")
    else empty
    end,

    if ($invariant.disposition == "dynamic-preflight") and
       (has_passing_test($invariant; "dynamic-preflight") | not)
    then inv_error($invariant; "closure requires dynamic-preflight evidence")
    else empty
    end,

    if ($invariant.disposition == "observed-conformance") and
       (has_passing_test($invariant; "runtime-probe") | not)
    then inv_error($invariant; "closure requires runtime-probe evidence")
    else empty
    end,

    if decodes_a_representation($invariant) and
       (has_passing_test($invariant; "wire-corruption") | not)
    then inv_error($invariant; "closure requires wire-corruption evidence")
    else empty
    end,

    (
      $invariant.compositionPaths[]? as $path |
      if passing_test_covers($invariant; $path)
      then empty
      else inv_error($invariant; "composition path lacks passing evidence: \($path)")
      end
    ),

    (
      $invariant.targets[]? as $target |
      if passing_test_targets($invariant; $target)
      then empty
      else inv_error($invariant; "target lacks passing evidence: \($target)")
      end
    )
  ];

def duplicate_id_errors:
  [
    (.invariants // []) |
    sort_by(.id) |
    group_by(.id)[] |
    select(length > 1) |
    "duplicate invariant id: \(.[0].id // "<missing-id>")"
  ];

if $mode != "inventory" and $mode != "closure"
then error("mode must be inventory or closure")
else
  . as $registry |
  (
    [
      if $registry.registryVersion == 1
      then empty
      else "registryVersion must equal 1"
      end,
      if ($registry.invariants | type) == "array" and
         ($registry.invariants | length > 0)
      then empty
      else "invariants must be a non-empty array"
      end
    ]
    + duplicate_id_errors
    + [
        $registry.invariants[]? as $invariant |
        common_invariant_errors($invariant)[],
        if $mode == "closure"
        then closure_errors($invariant)[]
        else empty
        end
      ]
  ) as $errors |
  if $errors | length == 0
  then $registry
  else error($errors | join("\n"))
  end
end
