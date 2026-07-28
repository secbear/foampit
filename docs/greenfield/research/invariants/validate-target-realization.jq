def phases:
  ["P0", "P1", "A0", "A1", "W0", "N0", "N1", "C0", "O0", "H0", "D0", "R0", "R1"];

def outcomes:
  [
    "conforming-lowering",
    "build-time-unsupported",
    "runtime-requirement",
    "observed-conformance"
  ];

def realization_modes:
  [
    "preserved-no-emission",
    "manifest-only",
    "built-content",
    "build-rejection",
    "create-binding",
    "operator-binding",
    "host-preflight",
    "driver-preparation",
    "post-start-probe"
  ];

def canonical_mode_phase($mode):
  if $mode == "preserved-no-emission" or
     $mode == "manifest-only" or
     $mode == "built-content"
  then "N1"
  elif $mode == "create-binding"
  then "C0"
  elif $mode == "operator-binding"
  then "O0"
  elif $mode == "host-preflight"
  then "H0"
  elif $mode == "driver-preparation"
  then "D0"
  elif $mode == "post-start-probe"
  then "R1"
  else null
  end;

def canonical_mode_component($mode; $phase):
  if $mode == "preserved-no-emission" or
     $mode == "manifest-only" or
     $mode == "built-content"
  then "target-member-builder"
  elif $mode == "build-rejection" and $phase == "A1"
  then "artifact-final-validator"
  elif $mode == "build-rejection" and $phase == "N1"
  then "target-member-builder"
  elif $mode == "create-binding"
  then "creation-resolver"
  elif $mode == "operator-binding"
  then "operator-resolver"
  elif $mode == "host-preflight"
  then "operator-preflight"
  elif $mode == "driver-preparation"
  then "target-driver"
  elif $mode == "post-start-probe"
  then "target-conformance-probe"
  else null
  end;

def target_families:
  ["bubblewrap", "microvm", "oci"];

def required_profile_ids:
  [
    "bubblewrap-linux-v1",
    "microvm-firecracker-linux-v1",
    "microvm-cloud-hypervisor-linux-v1",
    "oci-linux-v1"
  ];

def expected_target_family($id):
  if $id == "bubblewrap-linux-v1"
  then "bubblewrap"
  elif $id == "microvm-firecracker-linux-v1" or
       $id == "microvm-cloud-hypervisor-linux-v1"
  then "microvm"
  elif $id == "oci-linux-v1"
  then "oci"
  else null
  end;

def delegated_packets:
  ["D", "E", "F"];

def nonempty_string:
  type == "string" and (gsub("^\\s+|\\s+$"; "") | length > 0);

def string_array:
  type == "array" and all(.[]; nonempty_string);

def unknown_keys($object; $allowed):
  if ($object | type) == "object"
  then [
    ($object | keys[]) as $key |
    select(($allowed | index($key)) == null) |
    $key
  ]
  else ["<not-an-object>"]
  end;

def phase_rank($phase):
  phases | index($phase);

def duplicates($values):
  ($values // []) |
  sort |
  group_by(.)[] |
  select(length > 1) |
  .[0];

def placeholder_strings:
  [
    .. |
    strings |
    select(test("^(TBD|TODO|FIXME)(:|\\b|$)|^UNKNOWN$"; "i"))
  ];

def unsafe_semantic_strings:
  [
    .. |
    strings |
    select(
      test(
        "best[ -]?effort|fail[ -]?open|warn(ing)?[ -]?only|warn and continue|inherit(s|ed|ing)? (backend|target|provider|runtime|image) defaults?|fallback to (backend|target|provider|runtime|image) defaults?|trust(s|ed|ing)? (the )?(backend|target|provider|runtime|image) defaults?|implicit fallback|silently (drop|ignore|weaken)";
        "i"
      )
    )
  ];

def text_authority:
  "Only closed structured control fields and stable obligation identifiers are normative. Human-readable explanations, rationales, and remediation text are non-normative and cannot change failure, default, warning, verification, evidence, phase, authority, or lowering semantics.";

def profile_text_authority:
  "Only closed identity, member-sharing, claim-authority, profile-coordinate, ownership, and research-pin fields are normative. Fields named *Explanation or *Explanations are non-normative. Exact field/profile support, rejection, phase, evidence, and delegation semantics live in the independently pinned Packet C case-contract catalog.";

def expected_production_identity_contract:
  {
    "reviewCoordinateIsProductionIdentity": false,
    "binding": "complete-implementation-bundle-digest",
    "registryClosureBeforeAdvertisement": "required",
    "memberBoundConformanceBeforeAdvertisement": "required"
  };

def expected_member_sharing_contract:
  {
    "distinctHardRequirementsRequireDistinctMembers": true,
    "byteDeduplicationAcrossMembers": "allowed",
    "multiProfileAdvertisement": "independent-member-bound-evidence-required"
  };

def expected_claim_authority:
  {
    "artifactSource": "requirements-only",
    "builder": "construction-and-support-claims",
    "manifestLoader": "untrusted-claim-verifier",
    "create": "advertised-profile-selector",
    "operator": "implementation-and-placement-binder"
  };

def expected_profile_registry_sha256:
  "f674dcffbe506216218ddd2a1551b2d93c70d49017fb2bbbbfd7cd76112aee8d";

def expected_case_contracts_sha256:
  "baba66aa93502ea94044a2ccd967f37746fe28c4feab3062a6b10279aca00411";

def required_observed_modes($rule_id):
  if [
       "TRL-008-BUBBLEWRAP-WORKSPACE",
       "TRL-009-FIRECRACKER-WORKSPACE",
       "TRL-010-CLOUD-HYPERVISOR-WORKSPACE",
       "TRL-011-OCI-WORKSPACE",
       "TRL-012-BUBBLEWRAP-BINDING-FILESYSTEM",
       "TRL-013-MICROVM-BINDING-FILESYSTEM",
       "TRL-014-OCI-BINDING-FILESYSTEM"
     ] | index($rule_id)
  then [
    "create-binding",
    "operator-binding",
    "host-preflight",
    "driver-preparation",
    "post-start-probe"
  ]
  elif [
         "TRL-016-BUBBLEWRAP-SCRATCH",
         "TRL-017-MICROVM-SCRATCH",
         "TRL-018-OCI-SCRATCH",
         "TRL-020-MICROVM-ROOT",
         "TRL-021-BUBBLEWRAP-NETWORK",
         "TRL-022-MICROVM-NETWORK",
         "TRL-023-OCI-NETWORK",
         "TRL-024-COMMON-RESOURCE-BOUNDS",
         "TRL-026-MICROVM-AND-OCI-WORKLOAD-MEMORY",
         "TRL-028-MICROVM-AND-OCI-IO",
         "TRL-032-BUBBLEWRAP-DEVICES",
         "TRL-033-FIRECRACKER-DEVICES",
         "TRL-034-CLOUD-HYPERVISOR-DEVICES",
         "TRL-035-OCI-DEVICES",
         "TRL-036-BUBBLEWRAP-SECRETS",
         "TRL-037-MICROVM-SECRETS",
         "TRL-038-OCI-SECRETS",
         "TRL-040-MAXIMUM-LIFETIME"
       ] | index($rule_id)
  then [
    "manifest-only",
    "create-binding",
    "operator-binding",
    "host-preflight",
    "driver-preparation",
    "post-start-probe"
  ]
  elif [
         "TRL-029-BUBBLEWRAP-SECURITY-POLICY",
         "TRL-030-MICROVM-SECURITY-POLICY",
         "TRL-031-OCI-SECURITY-POLICY"
       ] | index($rule_id)
  then [
    "manifest-only",
    "operator-binding",
    "host-preflight",
    "driver-preparation",
    "post-start-probe"
  ]
  else null
  end;

def required_observed_first_sound($rule_id):
  if [
       "TRL-008-BUBBLEWRAP-WORKSPACE",
       "TRL-009-FIRECRACKER-WORKSPACE",
       "TRL-010-CLOUD-HYPERVISOR-WORKSPACE",
       "TRL-011-OCI-WORKSPACE",
       "TRL-012-BUBBLEWRAP-BINDING-FILESYSTEM",
       "TRL-013-MICROVM-BINDING-FILESYSTEM",
       "TRL-014-OCI-BINDING-FILESYSTEM"
     ] | index($rule_id)
  then "C0"
  else "N0"
  end;

def registry_ids:
  [$registry[0].invariants[].id];

def artifact_field_ids:
  [$fields[0].fields[].id];

def artifact_field($id):
  $fields[0].fields[] | select(.id == $id);

def profile_ids:
  [$profiles[0].profiles[].id];

def case_contract($identity):
  first(
    $caseContracts[0].entries[]? |
    select(.identity == $identity)
  ) // null;

def cell_key($field; $profile):
  "\($field) × \($profile)";

def rule_error($rule; $message):
  "\($rule.id // "<missing-rule-id>"): \($message)";

def profile_error($profile; $message):
  "\($profile.id // "<missing-profile-id>"): \($message)";

def profile_errors($profile):
  [
    if $profileRegistrySha256 == expected_profile_registry_sha256
    then empty
    else "target profile registry SHA-256 must equal the independently reviewed validator pin"
    end,

    if $caseContractsSha256 == expected_case_contracts_sha256
    then empty
    else "case-contract catalog SHA-256 must equal the independently reviewed validator pin"
    end,

    (
      unknown_keys(
        $profile;
        [
          "id",
          "targetFamily",
          "workloadPlatform",
          "memberKind",
          "artifactBuilder",
          "runtime",
          "implementationBundleExplanations",
          "researchPins",
          "requiredDefaultSuppressionExplanations",
          "baselineUnsupportedExplanations",
          "advertisementPreconditionExplanations"
        ]
      )[] as $key |
      profile_error($profile; "unknown profile key: \($key)")
    ),

    (
      unknown_keys($profile.workloadPlatform; ["os", "architecture"])[] as $key |
      profile_error($profile; "unknown workloadPlatform key: \($key)")
    ),

    (
      unknown_keys(
        $profile.artifactBuilder;
        ["owner", "componentClass", "reusedDependency", "forbiddenDependencyRoleExplanation"]
      )[] as $key |
      profile_error($profile; "unknown artifactBuilder key: \($key)")
    ),

    (
      unknown_keys(
        $profile.runtime;
        ["owner", "componentClass", "externalImplementation", "implementationPinOwner"]
      )[] as $key |
      profile_error($profile; "unknown runtime key: \($key)")
    ),

    if $profile.id | nonempty_string
    then empty
    else profile_error($profile; "id must be non-empty")
    end,

    if target_families | index($profile.targetFamily)
    then empty
    else profile_error($profile; "unknown target family: \($profile.targetFamily // "<missing>")")
    end,

    if $profile.targetFamily == expected_target_family($profile.id)
    then empty
    else profile_error($profile; "targetFamily must match the locked profile coordinate")
    end,

    if $profile.workloadPlatform.os | nonempty_string
    then empty
    else profile_error($profile; "workloadPlatform.os must be non-empty")
    end,

    if $profile.workloadPlatform.architecture | nonempty_string
    then empty
    else profile_error($profile; "workloadPlatform.architecture must be non-empty")
    end,

    if $profile.memberKind | nonempty_string
    then empty
    else profile_error($profile; "memberKind must be non-empty")
    end,

    if $profile.artifactBuilder.owner == "product"
    then empty
    else profile_error($profile; "artifactBuilder.owner must equal product")
    end,

    if $profile.artifactBuilder.componentClass | nonempty_string
    then empty
    else profile_error($profile; "artifactBuilder.componentClass must be non-empty")
    end,

    if $profile.artifactBuilder.reusedDependency | nonempty_string
    then empty
    else profile_error($profile; "artifactBuilder.reusedDependency must be non-empty")
    end,

    if $profile.artifactBuilder.forbiddenDependencyRoleExplanation | nonempty_string
    then empty
    else profile_error($profile; "artifactBuilder.forbiddenDependencyRoleExplanation must be non-empty")
    end,

    if $profile.runtime.owner == "product"
    then empty
    else profile_error($profile; "runtime.owner must equal product")
    end,

    if $profile.runtime.componentClass | nonempty_string
    then empty
    else profile_error($profile; "runtime.componentClass must be non-empty")
    end,

    if $profile.runtime.externalImplementation | nonempty_string
    then empty
    else profile_error($profile; "runtime.externalImplementation must be non-empty")
    end,

    if $profile.runtime.implementationPinOwner == "operator"
    then empty
    else profile_error($profile; "runtime.implementationPinOwner must equal operator")
    end,

    if ($profile.implementationBundleExplanations | string_array) and
       ($profile.implementationBundleExplanations | length > 0)
    then empty
    else profile_error($profile; "implementationBundleExplanations must be non-empty")
    end,

    if ($profile.researchPins | type) == "array" and
       ($profile.researchPins | length > 0)
    then empty
    else profile_error($profile; "researchPins must be non-empty")
    end,

    (
      duplicates([$profile.researchPins[]?.component]) as $component |
      profile_error($profile; "duplicate research pin component: \($component)")
    ),

    (
      $profile.researchPins[]? as $pin |
      unknown_keys($pin; ["component", "revision", "source"])[] as $key |
      profile_error($profile; "unknown research pin key: \($key)")
    ),

    (
      $profile.researchPins[]? as $pin |
      if $pin.component | nonempty_string
      then empty
      else profile_error($profile; "research pin component must be non-empty")
      end
    ),

    (
      $profile.researchPins[]? as $pin |
      if $pin.revision | nonempty_string
      then empty
      else profile_error($profile; "research pin revision must be non-empty")
      end
    ),

    (
      $profile.researchPins[]? as $pin |
      if $pin.source | nonempty_string
      then empty
      else profile_error($profile; "research pin source must be non-empty")
      end
    ),

    if ($profile.requiredDefaultSuppressionExplanations | string_array) and
       ($profile.requiredDefaultSuppressionExplanations | length > 0)
    then empty
    else profile_error($profile; "requiredDefaultSuppressionExplanations must be non-empty")
    end,

    if ($profile.baselineUnsupportedExplanations | string_array) and
       ($profile.baselineUnsupportedExplanations | length > 0)
    then empty
    else profile_error($profile; "baselineUnsupportedExplanations must be non-empty")
    end,

    if ($profile.advertisementPreconditionExplanations | string_array) and
       ($profile.advertisementPreconditionExplanations | length > 0)
    then empty
    else profile_error($profile; "advertisementPreconditionExplanations must be non-empty")
    end,

    if ($profile | placeholder_strings | length) == 0
    then empty
    else profile_error($profile; "contains placeholder content")
    end
  ];

def value_condition_kinds:
  [
    "all-values",
    "field-present",
    "field-omitted",
    "alternative",
    "constraint-satisfied",
    "constraint-unsatisfied",
    "otherwise"
  ];

def condition_keys($kind):
  if $kind == "all-values" or $kind == "otherwise"
  then ["kind"]
  elif $kind == "field-present" or $kind == "field-omitted"
  then ["kind", "path"]
  elif $kind == "alternative"
  then ["kind", "path", "values"]
  elif $kind == "constraint-satisfied" or $kind == "constraint-unsatisfied"
  then ["kind", "requirement", "requiresFieldPresence", "predicateId"]
  else ["kind"]
  end;

def case_error($rule; $case; $message):
  "\($rule.id // "<missing-rule-id>")/\($case.id // "<missing-case-id>"): \($message)";

def case_errors($rule; $case):
  [
    (
      unknown_keys(
        $case;
        [
          "id",
          "condition",
          "outcome",
          "firstSoundPhase",
          "deadline",
          "authority",
          "steps",
          "safetyPolicy",
          "manifestProjection",
          "fallbackPolicy",
          "approximationPolicy",
          "invariants",
          "delegatedPackets",
          "diagnostic",
          "evidence",
          "rationale"
        ]
      )[] as $key |
      case_error($rule; $case; "unknown case key: \($key)")
    ),

    (
      unknown_keys(
        $case.safetyPolicy;
        ["failure", "defaults", "warnings", "evidence"]
      )[] as $key |
      case_error($rule; $case; "unknown safetyPolicy key: \($key)")
    ),

    if $case.safetyPolicy == {
         "failure": "fail-closed",
         "defaults": "explicit-only",
         "warnings": "never-sufficient",
         "evidence": "required"
       }
    then empty
    else case_error($rule; $case; "safetyPolicy must equal the closed fail-closed realization policy")
    end,

    (
      unknown_keys(
        $case.condition;
        condition_keys($case.condition.kind)
      )[] as $key |
      case_error($rule; $case; "unknown condition key: \($key)")
    ),

    (
      unknown_keys($case.authority; ["phase", "component"])[] as $key |
      case_error($rule; $case; "unknown authority key: \($key)")
    ),

    (
      $case.steps[]? as $step |
      unknown_keys(
        $step;
        ["phase", "mode", "component", "obligationId", "explanation"]
      )[] as $key |
      case_error($rule; $case; "unknown step key: \($key)")
    ),

    (
      unknown_keys(
        $case.manifestProjection;
        ["obligationId", "explanation"]
      )[] as $key |
      case_error($rule; $case; "unknown manifestProjection key: \($key)")
    ),

    (
      unknown_keys(
        $case.diagnostic;
        ["identity", "primaryPaths", "relatedPaths", "remediation", "secretSafe"]
      )[] as $key |
      case_error($rule; $case; "unknown diagnostic key: \($key)")
    ),

    if $case.id | nonempty_string
    then empty
    else case_error($rule; $case; "id must be non-empty")
    end,

    if {
         condition: $case.condition,
         outcome: $case.outcome,
         firstSoundPhase: $case.firstSoundPhase,
         deadline: $case.deadline,
         authority: $case.authority,
         steps: [
           $case.steps[]? |
           {
             phase,
             mode,
             component
           }
         ],
         evidenceClasses: [
           $case.evidence[]? |
           select(type == "object") |
           .class
         ],
         delegatedPackets: $case.delegatedPackets
       } == (
         case_contract("\($rule.id)/\($case.id)") |
         del(.identity)
       )
    then empty
    else case_error($rule; $case; "structured controls must equal the generator-owned case contract")
    end,

    if value_condition_kinds | index($case.condition.kind)
    then empty
    else case_error($rule; $case; "unknown value condition: \($case.condition.kind // "<missing>")")
    end,

    if (
         $case.condition.kind == "field-present" or
         $case.condition.kind == "field-omitted" or
         $case.condition.kind == "alternative"
       ) and
       (($case.condition.path | nonempty_string) | not)
    then case_error($rule; $case; "value condition path must be non-empty")
    else empty
    end,

    if (
         $case.condition.kind == "field-present" or
         $case.condition.kind == "field-omitted" or
         $case.condition.kind == "alternative"
       ) and
       (($rule.fieldIds | index($case.condition.path)) == null)
    then case_error($rule; $case; "value condition path must select a field in its rule")
    else empty
    end,

    if $case.condition.kind == "alternative" and
       (
         (($case.condition.values | string_array) | not) or
         ($case.condition.values | length == 0)
       )
    then case_error($rule; $case; "alternative condition values must be non-empty")
    else empty
    end,

    if (
         $case.condition.kind == "constraint-satisfied" or
         $case.condition.kind == "constraint-unsatisfied"
       ) and
       (($case.condition.requirement | nonempty_string) | not)
    then case_error($rule; $case; "constraint condition requirement must be non-empty")
    else empty
    end,

    if $case.condition | has("requiresFieldPresence") and
       $case.condition.requiresFieldPresence != true
    then case_error($rule; $case; "requiresFieldPresence, when present, must equal true")
    else empty
    end,

    if (
         $case.condition.kind == "constraint-satisfied" or
         $case.condition.kind == "constraint-unsatisfied"
       ) and
       $case.condition.predicateId != "\($rule.id)/\($case.id)"
    then case_error($rule; $case; "constraint predicateId must equal rule/case identity")
    else empty
    end,

    if outcomes | index($case.outcome)
    then empty
    else rule_error($rule; "unknown outcome: \($case.outcome // "<missing>")")
    end,

    if phase_rank($case.firstSoundPhase) != null
    then empty
    else case_error($rule; $case; "unknown firstSoundPhase: \($case.firstSoundPhase // "<missing>")")
    end,

    if phase_rank($case.deadline) != null
    then empty
    else case_error($rule; $case; "unknown deadline: \($case.deadline // "<missing>")")
    end,

    if phase_rank($case.firstSoundPhase) != null and
       phase_rank($case.deadline) != null and
       phase_rank($case.firstSoundPhase) > phase_rank($case.deadline)
    then rule_error($rule; "firstSoundPhase occurs after deadline")
    else empty
    end,

    if any(
         $case.steps[]?;
         .phase == $case.authority.phase and
         .component == $case.authority.component
       )
    then empty
    else case_error($rule; $case; "authority must identify an exact realization step")
    end,

    if any(
         $case.steps[]?;
         phase_rank(.phase) < phase_rank($case.firstSoundPhase) or
         phase_rank(.phase) > phase_rank($case.deadline)
       )
    then case_error($rule; $case; "every realization step must fall between firstSoundPhase and deadline")
    else empty
    end,

    if any(
         range(1; $case.steps | length);
         phase_rank($case.steps[.].phase) <
           phase_rank($case.steps[. - 1].phase)
       )
    then case_error($rule; $case; "realization steps must be ordered by phase")
    else empty
    end,

    if phase_rank($case.authority.phase) != null
    then empty
    else case_error($rule; $case; "unknown authority phase: \($case.authority.phase // "<missing>")")
    end,

    if $case.authority.component | nonempty_string
    then empty
    else rule_error($rule; "authority component must be non-empty")
    end,

    if phase_rank($case.firstSoundPhase) != null and
       phase_rank($case.deadline) != null and
       phase_rank($case.authority.phase) != null and
       (
         phase_rank($case.authority.phase) < phase_rank($case.firstSoundPhase) or
         phase_rank($case.authority.phase) > phase_rank($case.deadline)
       )
    then case_error($rule; $case; "authority phase must fall between firstSoundPhase and deadline")
    else empty
    end,

    if ($case.steps | type) == "array" and ($case.steps | length > 0)
    then empty
    else case_error($rule; $case; "steps must be non-empty")
    end,

    (
      $case.steps[]? as $step |
      if phase_rank($step.phase) != null
      then empty
      else case_error($rule; $case; "unknown step phase: \($step.phase // "<missing>")")
      end
    ),

    (
      $case.steps[]? as $step |
      if realization_modes | index($step.mode)
      then empty
      else case_error($rule; $case; "unknown realization mode: \($step.mode // "<missing>")")
      end
    ),

    (
      $case.steps[]? as $step |
      if $step.mode == "build-rejection" or
         $step.phase == canonical_mode_phase($step.mode)
      then empty
      else case_error($rule; $case; "realization mode must use its canonical phase")
      end
    ),

    (
      $case.steps[]? as $step |
      if $step.component == canonical_mode_component($step.mode; $step.phase)
      then empty
      else case_error($rule; $case; "realization mode and phase must use their canonical component")
      end
    ),

    (
      $case.steps[]? as $step |
      if $step.component | nonempty_string
      then empty
      else case_error($rule; $case; "step component must be non-empty")
      end
    ),

    (
      $case.steps | to_entries[]? as $entry |
      if $entry.value.explanation | nonempty_string
      then empty
      else case_error($rule; $case; "step explanation must be non-empty")
      end
    ),

    (
      $case.steps | to_entries[]? as $entry |
      if $entry.value.obligationId ==
           "\($rule.id)/\($case.id)/step-\($entry.key + 1)/\($entry.value.phase)/\($entry.value.mode)"
      then empty
      else case_error($rule; $case; "step obligationId must equal its rule/case/index/phase/mode identity")
      end
    ),

    if $case.outcome == "build-time-unsupported" and
       (
         phase_rank($case.deadline) == null or
         phase_rank($case.deadline) > phase_rank("N1")
       )
    then rule_error($rule; "build-time-unsupported must reject no later than N1")
    else empty
    end,

    if $case.outcome == "build-time-unsupported" and
       (any($case.steps[]?; .mode == "build-rejection") | not)
    then case_error($rule; $case; "build-time-unsupported requires a build-rejection step")
    else empty
    end,

    if $case.outcome == "runtime-requirement" and
       (
         any(
           $case.steps[]?;
           .mode == "create-binding" or
           .mode == "operator-binding" or
           .mode == "host-preflight" or
           .mode == "driver-preparation"
         ) |
         not
       )
    then case_error($rule; $case; "runtime-requirement requires a pre-start realization step")
    else empty
    end,

    if $case.outcome == "observed-conformance" and
       (any($case.steps[]?; .mode == "post-start-probe") | not)
    then case_error($rule; $case; "observed-conformance requires a post-start-probe")
    else empty
    end,

    if $case.outcome == "observed-conformance" and $case.deadline != "R1"
    then case_error($rule; $case; "observed-conformance deadline must equal R1")
    else empty
    end,

    if $case.outcome == "observed-conformance" and
       $case.firstSoundPhase != required_observed_first_sound($rule.id)
    then case_error($rule; $case; "observed-conformance firstSoundPhase must equal its locked rule phase")
    else empty
    end,

    if $case.outcome == "observed-conformance" and
       required_observed_modes($rule.id) != null and
       [$case.steps[].mode] != required_observed_modes($rule.id)
    then case_error($rule; $case; "dynamic observed-conformance steps must equal the locked ownership chain")
    else empty
    end,

    if $case.outcome == "build-time-unsupported" and
       ((
         (
           $case.authority.phase == "A1" and
           $case.authority.component == "artifact-final-validator" and
           $case.firstSoundPhase == "A1" and
           $case.deadline == "A1"
         ) or
         (
           $case.authority.phase == "N1" and
           $case.authority.component == "target-member-builder" and
           $case.firstSoundPhase == "N1" and
           $case.deadline == "N1"
         )
       ) | not)
    then case_error($rule; $case; "build-time-unsupported authority must be artifact-final-validator at A1 or target-member-builder at N1")
    elif $case.outcome == "conforming-lowering" and
         (
           $case.authority.phase != "N1" or
           $case.authority.component != "target-member-builder" or
           $case.firstSoundPhase != "N0" or
           $case.deadline != "N1"
         )
    then case_error($rule; $case; "conforming-lowering must span N0 to N1 with target-member-builder authority at N1")
    elif $case.outcome == "observed-conformance" and
         (
           $case.authority.phase != "R1" or
           $case.authority.component != "target-conformance-probe"
         )
    then case_error($rule; $case; "observed-conformance authority must be target-conformance-probe at R1")
    else empty
    end,

    if $case.manifestProjection.explanation | nonempty_string
    then empty
    else rule_error($rule; "manifestProjection explanation must be non-empty")
    end,

    if $case.manifestProjection.obligationId ==
         "\($rule.id)/\($case.id)/manifest-projection"
    then empty
    else case_error($rule; $case; "manifestProjection obligationId must equal rule/case identity")
    end,

    if $case.fallbackPolicy == "forbidden"
    then empty
    else rule_error($rule; "fallbackPolicy must equal forbidden")
    end,

    if $case.approximationPolicy == "forbidden"
    then empty
    else rule_error($rule; "approximationPolicy must equal forbidden")
    end,

    if ($case.invariants | string_array) and ($case.invariants | length > 0)
    then empty
    else case_error($rule; $case; "invariants must be non-empty")
    end,

    (
      duplicates($case.invariants) as $invariant |
      case_error($rule; $case; "duplicate invariant reference: \($invariant)")
    ),

    (
      $case.invariants[]? as $invariant |
      if registry_ids | index($invariant)
      then empty
      else rule_error($rule; "unknown invariant reference: \($invariant)")
      end
    ),

    if $case.delegatedPackets | string_array
    then empty
    else case_error($rule; $case; "delegatedPackets must be an array")
    end,

    (
      $case.delegatedPackets[]? as $packet |
      if delegated_packets | index($packet)
      then empty
      else case_error($rule; $case; "unknown delegated packet: \($packet)")
      end
    ),

    if $case.diagnostic.identity == "\($rule.id)/\($case.id)"
    then empty
    else case_error($rule; $case; "diagnostic identity must equal rule/case identity")
    end,

    if ($case.diagnostic.primaryPaths | string_array) and
       (($case.diagnostic.primaryPaths | sort) == ($rule.fieldIds | sort))
    then empty
    else case_error($rule; $case; "diagnostic primaryPaths must equal rule fieldIds")
    end,

    if $case.diagnostic.relatedPaths | string_array
    then empty
    else case_error($rule; $case; "diagnostic relatedPaths must be an array")
    end,

    if $case.diagnostic.remediation | nonempty_string
    then empty
    else rule_error($rule; "diagnostic remediation must be non-empty")
    end,

    if $case.diagnostic.secretSafe == true
    then empty
    else case_error($rule; $case; "diagnostic must be secret-safe")
    end,

    if ($case.evidence | type) == "array" and
       ($case.evidence | length > 0) and
       all($case.evidence[]; type == "object")
    then empty
    else rule_error($rule; "evidence must be a non-empty structured obligation array")
    end,

    (
      $case.evidence[]? |
      select(type == "object") as $evidence |
      unknown_keys($evidence; ["obligationId", "class"])[] as $key |
      case_error($rule; $case; "unknown evidence key: \($key)")
    ),

    (
      $case.evidence | to_entries[]? as $entry |
      select($entry.value | type == "object") |
      if ($entry.value.class | test("^[a-z0-9]+(?:-[a-z0-9]+)*$")) and
         $entry.value.obligationId ==
           "\($rule.id)/\($case.id)/evidence-\($entry.key + 1)/\($entry.value.class)"
      then empty
      else case_error($rule; $case; "evidence obligation must have a stable class and rule/case/index identity")
      end
    ),

    if $case.rationale | nonempty_string
    then empty
    else case_error($rule; $case; "rationale must be non-empty")
    end,

    if ($case | placeholder_strings | length) == 0
    then empty
    else rule_error($rule; "contains placeholder content")
    end,

    if (
         {
           steps: $case.steps,
           manifestProjection: $case.manifestProjection,
           evidence: $case.evidence,
           rationale: $case.rationale
         } |
         unsafe_semantic_strings |
         length
       ) == 0
    then empty
    else case_error($rule; $case; "contains fail-open, default-inheriting, warning-only, or best-effort semantics")
    end
  ];

def rule_case_errors($rule):
  [
    (
      unknown_keys(
        $rule;
        ["id", "fieldIds", "profileIds", "fieldTraceability", "cases"]
      )[] as $key |
      rule_error($rule; "unknown rule key: \($key)")
    ),

    if $rule.id | nonempty_string
    then empty
    else rule_error($rule; "id must be non-empty")
    end,

    if ($rule.fieldIds | string_array) and ($rule.fieldIds | length > 0)
    then empty
    else rule_error($rule; "fieldIds must be non-empty")
    end,

    (
      duplicates($rule.fieldIds) as $field |
      rule_error($rule; "duplicate field selector: \($field)")
    ),

    (
      $rule.fieldIds[]? as $field |
      if artifact_field_ids | index($field)
      then empty
      else rule_error($rule; "unknown Artifact field: \($field)")
      end
    ),

    if ($rule.profileIds | string_array) and ($rule.profileIds | length > 0)
    then empty
    else rule_error($rule; "profileIds must be non-empty")
    end,

    (
      duplicates($rule.profileIds) as $profile |
      rule_error($rule; "duplicate profile selector: \($profile)")
    ),

    (
      $rule.profileIds[]? as $profile |
      if profile_ids | index($profile)
      then empty
      else rule_error($rule; "unknown target profile: \($profile)")
      end
    ),

    if (
         (($rule.fieldTraceability | type) == "object") and
         (($rule.fieldTraceability | keys | sort) == ($rule.fieldIds | sort))
       )
    then empty
    else rule_error($rule; "fieldTraceability keys must equal fieldIds")
    end,

    (
      $rule.fieldIds[]? as $field |
      (artifact_field($field)) as $ledger |
      unknown_keys(
        $rule.fieldTraceability[$field];
        ["invariants", "delegatedPackets"]
      )[] as $key |
      rule_error($rule; "\($field): unknown fieldTraceability key: \($key)")
    ),

    (
      $rule.fieldIds[]? as $field |
      (artifact_field($field)) as $ledger |
      if (
           (($rule.fieldTraceability[$field].invariants // []) | sort) ==
           (($ledger.invariants // []) | sort)
         )
      then empty
      else rule_error($rule; "\($field): fieldTraceability invariants must equal Packet B")
      end
    ),

    (
      $rule.fieldIds[]? as $field |
      (artifact_field($field)) as $ledger |
      if (
           (($rule.fieldTraceability[$field].delegatedPackets // []) | sort) ==
           ([$ledger.delegatedPackets[]? | select(. != "C")] | sort)
         )
      then empty
      else rule_error($rule; "\($field): fieldTraceability delegatedPackets must equal unresolved Packet B delegations")
      end
    ),

    (
      $rule.fieldIds[]? as $field |
      $rule.cases[]? as $case |
      $rule.fieldTraceability[$field].invariants[]? as $invariant |
      if $case.invariants | index($invariant)
      then empty
      else case_error($rule; $case; "case invariants omit field invariant \($invariant) for \($field)")
      end
    ),

    if ($rule.cases | type) == "array" and ($rule.cases | length > 0)
    then empty
    else rule_error($rule; "cases must be non-empty")
    end,

    (
      duplicates([$rule.cases[]?.id]) as $case_id |
      rule_error($rule; "duplicate value case id: \($case_id)")
    ),

    (
      duplicates([$rule.cases[]?.condition | tojson]) as $condition |
      rule_error($rule; "duplicate value condition: \($condition)")
    ),

    if ($rule.cases | length) == 1 and
       $rule.cases[0].condition.kind != "all-values"
    then rule_error($rule; "single value case must use all-values")
    else empty
    end,

    if ($rule.cases | length) > 1 and
       any($rule.cases[]?; .condition.kind == "all-values")
    then rule_error($rule; "partitioned value cases cannot use all-values")
    else empty
    end,

    if ($rule.cases | length) > 1 and
       ([ $rule.cases[]? | select(.condition.kind == "otherwise") ] | length) != 1
    then rule_error($rule; "partitioned value cases require exactly one otherwise case")
    else empty
    end,

    if ($rule.cases | length) > 1 and
       $rule.cases[-1].condition.kind != "otherwise"
    then rule_error($rule; "otherwise value case must be last")
    else empty
    end,

    if ($rule.cases | length) == 2
    then empty
    elif ($rule.cases | length) == 3 and
         $rule.cases[0].condition.kind == "field-omitted" and
         $rule.cases[1].condition.kind == "constraint-satisfied" and
         $rule.cases[1].condition.requiresFieldPresence == true and
         $rule.cases[2].condition.kind == "otherwise"
    then empty
    elif ($rule.cases | length) == 1
    then empty
    else rule_error($rule; "unsupported value-partition shape")
    end,

    (
      $rule.cases[]? as $case |
      case_errors($rule; $case)[]
    ),

    if ($rule | placeholder_strings | length) == 0
    then empty
    else rule_error($rule; "contains placeholder content")
    end
  ];

. as $realization |
(
  [
    (
      unknown_keys(
        $caseContracts[0];
        ["reviewVersion", "packet", "status", "authority", "entries"]
      )[] as $key |
      "unknown case-contract catalog key: \($key)"
    ),

    if $caseContracts[0].reviewVersion == 1 and
       $caseContracts[0].packet == "C" and
       $caseContracts[0].status == "reviewed" and
       ($caseContracts[0].authority | nonempty_string)
    then empty
    else "case-contract catalog identity and authority must be complete"
    end,

    if ($caseContracts[0].entries | type) == "array" and
       ($caseContracts[0].entries | length > 0)
    then empty
    else "case-contract catalog entries must be non-empty"
    end,

    (
      duplicates([$caseContracts[0].entries[]?.identity]) as $identity |
      "duplicate case-contract identity: \($identity)"
    ),

    (
      $caseContracts[0].entries[]? as $entry |
      unknown_keys(
        $entry;
        [
          "identity",
          "condition",
          "outcome",
          "firstSoundPhase",
          "deadline",
          "authority",
          "steps",
          "evidenceClasses",
          "delegatedPackets"
        ]
      )[] as $key |
      "unknown case-contract entry key: \($key)"
    ),

    (
      $caseContracts[0].entries[]? as $entry |
      if ($entry.identity | nonempty_string) and
         ($entry.evidenceClasses | string_array) and
         ($entry.evidenceClasses | length > 0) and
         ($entry.delegatedPackets | string_array)
      then empty
      else "case-contract entry requires identity, evidence classes, and delegation array"
      end
    ),

    (
      unknown_keys(
        $profiles[0];
        [
          "registryVersion",
          "packet",
          "status",
          "textAuthority",
          "identityStatusExplanation",
          "productionIdentityContract",
          "productionIdentityExplanation",
          "memberSharingContract",
          "memberSharingExplanation",
          "claimAuthority",
          "claimAuthorityExplanations",
          "profiles"
        ]
      )[] as $key |
      "unknown target profile registry key: \($key)"
    ),

    (
      unknown_keys(
        $profiles[0].claimAuthorityExplanations;
        ["artifactSource", "builder", "manifestLoader", "create", "operator"]
      )[] as $key |
      "unknown target profile claimAuthorityExplanations key: \($key)"
    ),

    if $profiles[0].registryVersion == 1
    then empty
    else "target profile registryVersion must equal 1"
    end,

    if $profiles[0].packet == "C"
    then empty
    else "target profile packet must equal C"
    end,

    if $profiles[0].status == "specified" or $profiles[0].status == "reviewed"
    then empty
    else "target profile status must equal specified or reviewed"
    end,

    if $profiles[0].textAuthority == profile_text_authority
    then empty
    else "target profile textAuthority must lock structured controls and mark explanations non-normative"
    end,

    if $profiles[0].productionIdentityContract ==
         expected_production_identity_contract
    then empty
    else "target profile productionIdentityContract must equal the closed production identity contract"
    end,

    if $profiles[0].memberSharingContract == expected_member_sharing_contract
    then empty
    else "target profile memberSharingContract must equal the closed member-sharing contract"
    end,

    if $profiles[0].claimAuthority == expected_claim_authority
    then empty
    else "target profile claimAuthority must equal the closed claim-authority contract"
    end,

    if ($profiles[0].identityStatusExplanation | nonempty_string) and
       ($profiles[0].productionIdentityExplanation | nonempty_string) and
       ($profiles[0].memberSharingExplanation | nonempty_string)
    then empty
    else "target profile identity and sharing explanations must be non-empty"
    end,

    (
      ["artifactSource", "builder", "manifestLoader", "create", "operator"][] as $owner |
      if $profiles[0].claimAuthorityExplanations[$owner] | nonempty_string
      then empty
      else "target profile claimAuthorityExplanations.\($owner) must be non-empty"
      end
    ),

    if ($profiles[0].profiles | type) == "array" and
       ($profiles[0].profiles | length > 0)
    then empty
    else "target profiles must be non-empty"
    end,

    if (profile_ids | sort) == (required_profile_ids | sort)
    then empty
    else "target profile IDs must equal the locked Packet C initial profile universe"
    end,

    (
      duplicates(profile_ids) as $profile |
      "duplicate profile id: \($profile)"
    ),

    (
      $profiles[0].profiles[]? as $profile |
      profile_errors($profile)[]
    ),

    (
      unknown_keys(
        $realization;
        [
          "reviewVersion",
          "packet",
          "status",
          "textAuthority",
          "expectedCellCount",
          "introducedInvariants",
          "rules"
        ]
      )[] as $key |
      "unknown target realization key: \($key)"
    ),

    if $realization.reviewVersion == 1
    then empty
    else "reviewVersion must equal 1"
    end,

    if (artifact_field_ids | length) == 81
    then empty
    else "Packet C requires the locked 81-field Packet B universe"
    end,

    if $realization.packet == "C"
    then empty
    else "packet must equal C"
    end,

    if $realization.status == "reviewed"
    then empty
    else "status must equal reviewed"
    end,

    if $realization.textAuthority == text_authority
    then empty
    else "textAuthority must lock structured controls and mark explanations non-normative"
    end,

    if $realization.introducedInvariants | string_array
    then empty
    else "introducedInvariants must be an array"
    end,

    (
      duplicates($realization.introducedInvariants) as $invariant |
      "duplicate introduced invariant: \($invariant)"
    ),

    (
      $realization.introducedInvariants[]? as $invariant |
      if registry_ids | index($invariant)
      then empty
      else "unknown introduced invariant: \($invariant)"
      end
    ),

    if ($realization.rules | type) == "array" and
       ($realization.rules | length > 0)
    then empty
    else "rules must be non-empty"
    end,

    (
      duplicates([$realization.rules[]?.id]) as $rule |
      "duplicate rule id: \($rule)"
    ),

    (
      $realization.rules[]? as $rule |
      rule_case_errors($rule)[]
    ),

    if (
         [$realization.rules[].cases[].diagnostic.identity] |
         sort
       ) == (
         [$caseContracts[0].entries[].identity] |
         sort
       )
    then empty
    else "case-contract identities must equal realization rule/case identities"
    end,

    (
      [
        artifact_field_ids[] as $field |
        profile_ids[] as $profile |
        {
          field: $field,
          profile: $profile,
          key: cell_key($field; $profile)
        }
      ]
    ) as $all_cells |

    (
      [
        $realization.rules[]? as $rule |
        $rule.fieldIds[]? as $field |
        $rule.profileIds[]? as $profile |
        {
          field: $field,
          profile: $profile,
          key: cell_key($field; $profile),
          rule: $rule.id
        }
      ]
    ) as $realized_cells |

    if $realization.expectedCellCount == 324 and
       ($all_cells | length) == 324
    then empty
    else "expectedCellCount and realized profile universe must equal the locked 324 cells"
    end,

    (
      $all_cells[] as $cell |
      if any($realized_cells[]; .key == $cell.key)
      then empty
      else "uncovered realization cell: \($cell.key)"
      end
    ),

    (
      $realized_cells |
      sort_by(.key) |
      group_by(.key)[] |
      select(length > 1) |
      "overlapping realization cell: \(.[0].key)"
    ),

    if ($realization | placeholder_strings | length) == 0
    then empty
    else "target realization contains placeholder content"
    end
  ]
) as $errors |
if $errors | length == 0
then $realization
else error($errors | join("\n"))
end
