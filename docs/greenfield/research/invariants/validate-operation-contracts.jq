# Independent Packet E operation-contract validator.
#
# This is an ORACLE, not a second copy of the generator. It recomputes every structural
# identity from the registry and catalog rather than trusting what the generated document
# says about itself, so a coordinated rewrite of generator plus output still fails here.
#
# Invoked with:
#   --arg validationScope catalog|full
#   --arg operationRegistrySha256 <sha>
#   --arg caseContractsSha256 <sha>
#   --arg invariantRegistrySha256 <sha>
#   --slurpfile registry   PACKET-E-OPERATION-REGISTRY.json
#   --slurpfile catalog    PACKET-E-CASE-CONTRACTS.json
#   --slurpfile invariants invariants.json
#   --slurpfile concurrency PACKET-E-CONCURRENCY-MATRIX.json
# with PACKET-E-OPERATION-CONTRACTS.json as the input document.

# Byte-identical to the definition carried by every other ledger validator. A ledger
# validator that omits this rule is invisible to a copy-versus-copy comparison, which is
# how validate-composition-coverage.jq went without one.
def placeholder_strings:
  [
    .. |
    strings |
    select(test("^(TBD|TODO|FIXME)(:|\\b|$)|^UNKNOWN$"; "i"))
  ];

# Prose that quietly reopens what a closed control field forbids.
def unsafe_semantic_strings:
  [
    .. |
    strings |
    select(
      test("best[- ]effort"; "i") or
      test("fail[- ]open"; "i") or
      test("warning[- ]only"; "i") or
      test("inherits? (backend|target|provider|runtime|image) defaults"; "i") or
      test("fallback to .* defaults"; "i") or
      test("implicit fallback"; "i") or
      test("silently (drop|ignore|weaken)"; "i")
    )
  ];

def unknown_keys($object; $allowed):
  [$object | keys[] | select(. as $k | $allowed | index($k) | not)];

def same_set($left; $right):
  ($left | unique) == ($right | unique);

# `list | index(.field)` silently rebinds `.` to the list. This keeps the item in scope.
def lacks_member($list; $value):
  ($list | index($value)) == null;

def has_member($list; $value):
  ($list | index($value)) != null;

# --- pinned digests -----------------------------------------------------------------
# Duplicated on purpose: check-inventory.sh carries the same values and aborts before any
# validator runs, so the two copies must move together or the early abort guards a stale one.
def expected_operation_registry_sha256:
  "7612e8d346072e217b7a9107fea17d9ce79e60559d09db36f6de77ccad5a7ce5";

def expected_case_contracts_sha256:
  "e9dde541702c02370b37e6dc844a58fd79acca5edd4faa4966241e00885e0ba9";

def expected_invariant_registry_sha256:
  "7cd71ffdd40be3f61744704731b6de8acee30f91c060c51b9caa6f8f81c2b517";

# --- recomputed vocabularies ---------------------------------------------------------
def registry_doc: $registry[0];
def catalog_doc: $catalog[0];
def concurrency_doc: $concurrency[0];

def method_ids:
  [registry_doc.operations[] | select(.id | startswith("deferred.") | not) | .id] | sort;

def deferral_ids:
  [registry_doc.operations[] | select(.id | startswith("deferred.")) | .id] | sort;

def lifecycle_state_ids: [registry_doc.lifecycleStates[].id];
def request_error_ids: [registry_doc.requestErrorVariants[].id];
def terminal_outcome_ids: [registry_doc.terminalOutcomes[].id];
def cell_kinds: [catalog_doc.cellKindContract | keys[]];
def invariant_ids: [$invariants[0].invariants[].id];

def operation_by($id): (registry_doc.operations[] | select(.id == $id));

# --- header errors -------------------------------------------------------------------
def header_errors:
  [
    if $operationRegistrySha256 == expected_operation_registry_sha256 then empty
    else "operation registry SHA-256 must equal the independently reviewed validator pin"
    end,

    if $caseContractsSha256 == expected_case_contracts_sha256 then empty
    else "case-contract catalog SHA-256 must equal the independently reviewed validator pin"
    end,

    if $invariantRegistrySha256 == expected_invariant_registry_sha256 then empty
    else "invariant registry SHA-256 must equal the independently reviewed validator pin"
    end,

    # A packet that has not closed says candidate and must never say reviewed.
    if (registry_doc.status == "candidate") and
       (catalog_doc.status == "candidate") and
       (.status == "candidate")
    then empty
    else "Packet E ledgers must identify candidate-only version 1 authority"
    end,

    if (catalog_doc.authority | test("candidate"; "i")) and
       ((catalog_doc.authority | test("reviewed"; "i")) | not)
    then empty
    else "case-contract catalog authority must claim candidate and must not claim reviewed"
    end,

    if (registry_doc | placeholder_strings | length) == 0 then empty
    else "operation registry contains placeholder content"
    end,

    if (catalog_doc | placeholder_strings | length) == 0 then empty
    else "case-contract catalog contains placeholder content"
    end,

    if (. | placeholder_strings | length) == 0 then empty
    else "generated operation contracts contain placeholder content"
    end,

    if (registry_doc | unsafe_semantic_strings | length) == 0 then empty
    else "operation registry contains fail-open, default-inheriting, warning-only, or best-effort semantics"
    end,

    if (catalog_doc | unsafe_semantic_strings | length) == 0 then empty
    else "case-contract catalog contains fail-open, default-inheriting, warning-only, or best-effort semantics"
    end
  ];

# --- registry errors -----------------------------------------------------------------
def registry_errors:
  [
    # The 14 names rejected from portable Core v1, plus shell. Scoped to ids only --
    # `attach` legitimately appears in prose.
    (
      ["restart","wake","killsandbox","destroy","rollback","connect","attach","detach",
       "session","update","copy","ttl","archive","migration","shell"] as $rejected |
      registry_doc.operations[] |
      select(.id | ascii_downcase | . as $i | $rejected | index($i)) |
      "rejected v1 name used as an operation id: \(.id)"
    ),

    # Every conforming execution driver supports these six.
    (
      ["CreateSandbox","StartSandbox","StopSandbox","DeleteSandbox","Exec","TerminateProcess"][] |
      . as $required |
      select((method_ids | index($required)) == null) |
      "mandatory driver operation missing from the registry: \($required)"
    ),

    # RecoveryError is one of the five locked result branches and recoveryCoordinates
    # cannot substitute for it.
    (
      registry_doc.operations[] |
      select(.id | startswith("deferred.") | not) |
      select(has_member(["durable-operation-mutation","durable-process-mutation",
              "atomic-core-record-update","sequenced-process-control"]; .callClass)) |
      select((.allowedRecoveryErrors | length) == 0) |
      "\(.id): a durable or sequenced call class must declare allowedRecoveryErrors"
    ),

    # A deferral marker is not a method and must not be validatable as one.
    (
      registry_doc.operations[] |
      select(.id | startswith("deferred.")) |
      select(.coverageStatus != "not-yet-generated") |
      "\(.id): a deferral marker must carry coverageStatus not-yet-generated"
    ),

    # Only running may be accepting.
    (
      registry_doc.lifecycleStates[] |
      select(.executionAdmission == "accepting" and .sandboxStatus != "running") |
      "lifecycle state \(.id) publishes accepting against a non-running status"
    ),

    (
      registry_doc.operations[] |
      . as $operation |
      $operation.invariants[] |
      . as $cited |
      select(lacks_member(invariant_ids; $cited)) |
      "\($operation.id): cites an unregistered invariant \($cited)"
    ),

    # Every registered Packet E invariant is either governed by an operation or explicitly
    # assigned elsewhere. Silence is the defect this catches.
    (
      (
        [registry_doc.operations[].invariants[]] +
        [registry_doc.nonOperationCoverage.assignments[].invariants[]]
      ) as $accounted |
      invariant_ids[] |
      select(test("^(ADM|ADP|CNC|ERR|FEN|FRK|IDE|OPA|PIO|POL|PRC|PRF|RET|SBX|SIG|SOP)-")) |
      select(. as $id | $accounted | index($id) | not) |
      "registered Packet E invariant is governed by no operation and assigned to no ledger: \(.)"
    )
  ];

# --- catalog errors ------------------------------------------------------------------
def catalog_errors:
  [
    if same_set(catalog_doc.operationIds; method_ids) then empty
    else "catalog operationIds must equal the registry method set exactly"
    end,

    if catalog_doc.lifecycleStateIds == lifecycle_state_ids then empty
    else "catalog lifecycleStateIds must equal the registry lifecycle-state order exactly"
    end,

    (
      catalog_doc.transitionVectorsByOperation | to_entries[] |
      select((.value | length) != (lifecycle_state_ids | length)) |
      "\(.key): transition vector must classify every lifecycle state exactly once"
    ),

    (
      catalog_doc.transitionVectorsByOperation | to_entries[] as $vector |
      $vector.value | split("")[] |
      select(. as $k | cell_kinds | index($k) | not) |
      "\($vector.key): unknown cell kind \(.)"
    ),

    (
      catalog_doc.entries[] |
      select((.cells | length) != (lifecycle_state_ids | length)) |
      "\(.operationId): entry must carry one cell per lifecycle state"
    ),

    # The sentinel contract's iff-rules, recomputed rather than trusted.
    (
      catalog_doc.entries[] as $entry |
      $entry.cells[] |
      select((.cellKind == "T") != (.nextLifecycleStateId != "none")) |
      "\($entry.operationId) × \(.lifecycleStateId): nextLifecycleStateId is populated iff cellKind is T"
    ),

    (
      catalog_doc.entries[] as $entry |
      $entry.cells[] |
      select((.cellKind == "J") != (.requestErrorId != "none")) |
      "\($entry.operationId) × \(.lifecycleStateId): requestErrorId is populated iff cellKind is J"
    ),

    (
      catalog_doc.entries[] as $entry |
      $entry.cells[] |
      select(.requestErrorId != "none") |
      select(lacks_member(request_error_ids; .requestErrorId)) |
      "\($entry.operationId) × \(.lifecycleStateId): undeclared RequestError variant \(.requestErrorId)"
    ),

    (
      catalog_doc.entries[] as $entry |
      $entry.cells[] |
      select(.terminalOutcome != "none") |
      select(lacks_member(terminal_outcome_ids; .terminalOutcome)) |
      "\($entry.operationId) × \(.lifecycleStateId): undeclared terminal outcome \(.terminalOutcome)"
    ),

    # A terminal outcome asserts an Operation outcome, so only a durable-operation carrier
    # may hold one. Coercing the others would assert an outcome for calls minting no Operation.
    (
      catalog_doc.entries[] as $entry |
      (operation_by($entry.operationId)) as $operation |
      $entry.cells[] |
      select(.terminalOutcome != "none") |
      select($operation.resultCarrierKind != "durable-operation") |
      "\($entry.operationId) × \(.lifecycleStateId): terminalOutcome on a \($operation.resultCarrierKind) carrier"
    ),

    # A noop commits no effect, so it neither allocates, consumes, nor takes the epoch
    # as an effect-bearing precondition.
    (
      catalog_doc.entries[] as $entry |
      $entry.cells[] |
      select(.cellKind == "N" and .epochRule != "no-epoch") |
      "\($entry.operationId) × \(.lifecycleStateId): a noop must carry epochRule no-epoch"
    ),

    (
      catalog_doc.entries[] as $entry |
      $entry.cells[] as $cell |
      $cell.invariants[] |
      . as $cited |
      select(lacks_member(invariant_ids; $cited)) |
      "\($entry.operationId) × \($cell.lifecycleStateId): cites an unregistered invariant \($cited)"
    ),

    # Cell kind and transition vector are two statements of one fact; they must agree.
    (
      catalog_doc.entries[] as $entry |
      (catalog_doc.transitionVectorsByOperation[$entry.operationId] | split("")) as $vector |
      range(0; $entry.cells | length) as $index |
      select($entry.cells[$index].cellKind != $vector[$index]) |
      "\($entry.operationId) × \($entry.cells[$index].lifecycleStateId): cell kind disagrees with its transition vector position"
    )
  ];

# --- concurrency errors --------------------------------------------------------------
def concurrency_errors:
  [
    if (concurrency_doc.cells | length) == concurrency_doc.expectedCellCount then empty
    else "concurrency matrix cell count must equal expectedCellCount"
    end,

    if (concurrency_doc.rowOperationIds | length) *
       (concurrency_doc.columnOperationIds | length) == concurrency_doc.expectedCellCount
    then empty
    else "concurrency expectedCellCount must equal rows × columns"
    end,

    # Compatibility is a symmetric relation; an asymmetric pair is a specification error.
    (
      (concurrency_doc.cells | map({key: "\(.rowOperationId) \(.columnOperationId)", value: .compatibility}) | from_entries) as $lookup |
      concurrency_doc.cells[] |
      select($lookup["\(.columnOperationId) \(.rowOperationId)"] != .compatibility) |
      "concurrency pair \(.rowOperationId) × \(.columnOperationId) is not symmetric"
    ),

    (
      concurrency_doc.cells[] |
      . as $cell |
      select((concurrency_doc.compatibilityVocabulary | index($cell.compatibility)) == null) |
      "concurrency pair \($cell.rowOperationId) × \($cell.columnOperationId): undeclared compatibility \($cell.compatibility)"
    ),

    # An operation excluded from the matrix must be excluded for a declared reason.
    (
      concurrency_doc.rowOperationIds[] |
      . as $id |
      select((method_ids | index($id)) == null) |
      "concurrency matrix names an operation absent from the registry: \($id)"
    ),

    (
      (concurrency_doc.rowOperationIds + concurrency_doc.scopeRestriction.excluded) as $covered |
      method_ids[] |
      select(. as $id | $covered | index($id) | not) |
      "operation is neither a concurrency row nor a declared exclusion: \(.)"
    )
  ];

# --- generated-document errors --------------------------------------------------------
def generated_errors:
  [
    if .expectedCellCount == ((method_ids | length) * (lifecycle_state_ids | length))
    then empty
    else "expectedCellCount must equal methods × lifecycle states"
    end,

    if (.rules | length) == .expectedCellCount then empty
    else "generated rule count must equal expectedCellCount"
    end,

    if .operationIds == method_ids then empty
    else "generated operationIds must equal the exact registry method set in order"
    end,

    if .lifecycleStateIds == lifecycle_state_ids then empty
    else "generated lifecycleStateIds must equal the registry order exactly"
    end,

    # Total and disjoint, recomputed as a Cartesian product rather than counted.
    (
      ([.rules[] | "\(.selector.operationIds[0]) \(.selector.lifecycleStateIds[0])"]) as $present |
      method_ids[] as $operation |
      lifecycle_state_ids[] as $state |
      select(($present | index("\($operation) \($state)")) == null) |
      "uncovered operation contract cell: \($operation) × \($state)"
    ),

    (
      [.rules[] | "\(.selector.operationIds[0]) \(.selector.lifecycleStateIds[0])"] |
      group_by(.) | map(select(length > 1)) | .[] |
      "overlapping operation contract cell: \(.[0] | sub(" "; " × "))"
    ),

    (
      .rules[] |
      select((.selector.lifecycleStateIds | length) != 1) |
      "\(.id): a rule selector must name exactly one lifecycle state"
    ),

    # Each generated case must equal its catalog cell. This is what defeats a tandem
    # rewrite of generator and output.
    (
      .rules[] as $rule |
      $rule.valueCases[] as $case |
      ($rule.selector.operationIds[0]) as $operation |
      ($rule.selector.lifecycleStateIds[0]) as $state |
      (catalog_doc.entries[] | select(.operationId == $operation) | .cells[] | select(.lifecycleStateId == $state)) as $cell |
      select(
        $case.cellKind != $cell.cellKind or
        $case.nextLifecycleStateId != $cell.nextLifecycleStateId or
        $case.requestErrorId != $cell.requestErrorId or
        $case.terminalOutcome != $cell.terminalOutcome or
        $case.epochRule != $cell.epochRule
      ) |
      "\($rule.id): generated case diverges from its case-contract catalog cell"
    ),

    # The fixed fail-closed quad, recomputed.
    (
      .rules[] as $rule |
      $rule.valueCases[] |
      select(
        .safetyPolicy != {
          failure: "fail-closed",
          defaults: "explicit-only",
          warnings: "never-sufficient",
          evidence: "required"
        } or
        .fallbackPolicy != "forbidden" or
        .approximationPolicy != "forbidden"
      ) |
      "\($rule.id): value case must carry the exact fail-closed safety policy"
    ),

    # Obligation identity is structural, not free text.
    (
      .rules[] as $rule |
      $rule.valueCases[] |
      select(.diagnostic.identity != "\($rule.id)/\(.id)") |
      "\($rule.id): diagnostic identity must equal its rule/case identity"
    ),

    (
      .rules[] as $rule |
      $rule.valueCases[] |
      select(.implementationStatus != "planned") |
      "\($rule.id): Packet E value cases remain planned until Gate 4B"
    ),

    (
      .rules[] |
      unknown_keys(.; ["id","selector","operationTraceability","valueCases"])[] |
      "unknown rule key: \(.)"
    ),

    (
      .rules[] as $rule |
      $rule.valueCases[] |
      unknown_keys(.; ["id","condition","cellKind","nextLifecycleStateId","requestErrorId",
        "recoveryErrorId","terminalOutcome","epochRule","invariants","safetyPolicy",
        "fallbackPolicy","approximationPolicy","diagnostic","implementationStatus"])[] |
      "unknown value case key: \(.)"
    )
  ];

(
  if $validationScope == "catalog"
  then header_errors + registry_errors + catalog_errors
  else header_errors + registry_errors + catalog_errors + concurrency_errors + generated_errors
  end
) as $errors |
if ($errors | length) == 0
then true
else error($errors | unique | join("\n"))
end
