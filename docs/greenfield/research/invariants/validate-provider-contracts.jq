def phases:
  ["N0", "N1", "O0", "H0"];

def required_contracts:
  [
    "prebuilt-member-transfer",
    "oci-descriptor-transfer",
    "provider-side-construction"
  ];

def conformance_classes:
  [
    "content-preserving-transfer",
    "rebuild-requires-equivalence-proof"
  ];

def nonempty_string:
  type == "string" and (gsub("^\\s+|\\s+$"; "") | length > 0);

def nonempty_string_array:
  type == "array" and
  length > 0 and
  all(.[]; nonempty_string);

def obligation_array:
  type == "array" and
  length > 0 and
  all(.[];
    type == "object" and
    (keys | sort) == ["explanation", "id"] and
    (.id | nonempty_string) and
    (.id | test("^[a-z0-9]+(?:-[a-z0-9]+)*$")) and
    (.explanation | nonempty_string)
  );

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
        "best[ -]?effort|fail[ -]?open|warn(ing)?[ -]?only|warn and continue|inherit(s|ed|ing)? (backend|target|provider|runtime|image) defaults?|trust(s|ed|ing)? (the )?(backend|target|provider|runtime|image) defaults?|implicit fallback|silently (drop|ignore|weaken)";
        "i"
      )
    )
  ];

def text_authority:
  "Only closed structured control fields and stable obligation identifiers are normative. Human-readable explanations and examples are non-normative and cannot change failure, default, warning, verification, cache, secret, retention, phase, authority, identity, input, evidence, unsupported, or admission semantics.";

def expected_safety_policy:
  {
    "failure": "fail-closed",
    "defaults": "explicit-only",
    "warnings": "never-sufficient",
    "verification": "mandatory",
    "cache": {
      "trust": "untrusted-optimization",
      "verification": "mandatory"
    },
    "secrets": {
      "providerCredentials": "operator-configuration",
      "workloadValues": "create-binding",
      "artifactInclusion": "forbidden"
    },
    "retention": {
      "source": "explicit-operator-configuration",
      "artifactIdentityEffect": "none"
    }
  };

def expected_identity_contract:
  {
    "transportChangesPortableIdentity": false,
    "providerReferences": "runtime-metadata-only",
    "mutableReferencesAsIdentity": "forbidden"
  };

def expected_unsupported_contract:
  {
    "disposition": "explicit-error",
    "implicitRebuild": "forbidden",
    "substitution": "forbidden",
    "semanticWeakening": "forbidden"
  };

def expected_obligation_ids($contract_id; $group):
  if $contract_id == "prebuilt-member-transfer" and $group == "input.required"
  then [
    "artifact-set-identity",
    "target-member-content-identity",
    "target-member-manifest",
    "member-content-source",
    "builder-conformance-evidence"
  ]
  elif $contract_id == "prebuilt-member-transfer" and $group == "input.forbidden"
  then [
    "mutable-provider-alias-as-identity",
    "secret-value",
    "provider-credential",
    "live-placement",
    "implicit-member-kind-conversion"
  ]
  elif $contract_id == "prebuilt-member-transfer" and $group == "admission.requirements"
  then [
    "accept-exact-member-kind-and-platform",
    "report-enforceable-runtime-profile",
    "preserve-member-bytes",
    "require-explicit-retention"
  ]
  elif $contract_id == "prebuilt-member-transfer" and $group == "runtimeEvidence"
  then [
    "effective-member-identity",
    "runtime-profile-and-implementation-identity",
    "admission-capability-results",
    "post-start-profile-conformance"
  ]
  elif $contract_id == "prebuilt-member-transfer" and $group == "unsupportedWhen"
  then [
    "member-kind-unavailable",
    "unverifiable-byte-transformation",
    "runtime-capability-or-evidence-unavailable",
    "retention-policy-unsatisfied"
  ]
  elif $contract_id == "oci-descriptor-transfer" and $group == "input.required"
  then [
    "digest-addressed-oci-descriptor",
    "linked-product-artifact-manifest",
    "target-member-and-artifact-set-identities",
    "builder-conformance-evidence"
  ]
  elif $contract_id == "oci-descriptor-transfer" and $group == "input.forbidden"
  then [
    "tag-only-selection",
    "provider-image-id-as-member-identity",
    "unverified-registry-response",
    "provider-image-defaults-as-artifact-semantics",
    "secret-in-image-or-metadata"
  ]
  elif $contract_id == "oci-descriptor-transfer" and $group == "admission.requirements"
  then [
    "accept-exact-digest-and-platform",
    "verify-descriptor-graph",
    "preserve-product-manifest-link",
    "enforce-oci-profile"
  ]
  elif $contract_id == "oci-descriptor-transfer" and $group == "runtimeEvidence"
  then [
    "verified-oci-descriptor-graph",
    "runtime-implementation-and-features",
    "effective-runtime-configuration",
    "post-start-profile-conformance"
  ]
  elif $contract_id == "oci-descriptor-transfer" and $group == "unsupportedWhen"
  then [
    "mutable-reference-only",
    "runtime-defaults-not-neutralizable",
    "runtime-semantics-not-provable",
    "opaque-runtime-mutation"
  ]
  elif $contract_id == "provider-side-construction" and $group == "input.required"
  then [
    "artifact-semantic-identity",
    "pinned-construction-inputs",
    "requested-target-profile",
    "versioned-construction-protocol",
    "expected-output-evidence-schema"
  ]
  elif $contract_id == "provider-side-construction" and $group == "input.forbidden"
  then [
    "unlocked-source",
    "ambient-provider-base",
    "opaque-imperative-setup",
    "secret-in-build-input-or-cache-key",
    "unverified-reproducibility-claim"
  ]
  elif $contract_id == "provider-side-construction" and $group == "admission.requirements"
  then [
    "support-construction-protocol",
    "verify-all-construction-inputs",
    "replace-provider-defaults",
    "return-product-output-and-evidence"
  ]
  elif $contract_id == "provider-side-construction" and $group == "runtimeEvidence"
  then [
    "builder-and-protocol-versions",
    "pinned-input-identity-set",
    "output-member-identity",
    "build-provenance-and-conformance",
    "runtime-implementation-and-post-start"
  ]
  elif $contract_id == "provider-side-construction" and $group == "unsupportedWhen"
  then [
    "imperative-recipe-only",
    "output-identity-or-evidence-unavailable",
    "provider-defaults-not-suppressible",
    "runtime-profile-unsatisfied"
  ]
  else []
  end;

def obligation_ids($items):
  [
    $items[]? |
    select(type == "object") |
    .id
  ] | sort;

def expected_admission($id):
  if $id == "prebuilt-member-transfer"
  then {
    "firstSoundPhase": "O0",
    "deadline": "H0",
    "authority": {"phase": "H0", "component": "remote-provider-adapter"}
  }
  elif $id == "oci-descriptor-transfer"
  then {
    "firstSoundPhase": "O0",
    "deadline": "H0",
    "authority": {"phase": "H0", "component": "oci-provider-adapter"}
  }
  elif $id == "provider-side-construction"
  then {
    "firstSoundPhase": "N0",
    "deadline": "N1",
    "authority": {"phase": "N1", "component": "provider-build-adapter"}
  }
  else null
  end;

def expected_verification_ids($id):
  if $id == "prebuilt-member-transfer"
  then [
    "verify-source-artifact-set",
    "verify-transferred-content",
    "bind-provider-reference-as-metadata"
  ]
  elif $id == "oci-descriptor-transfer"
  then [
    "verify-oci-root-descriptor",
    "verify-oci-graph-and-product-manifest",
    "classify-provider-identifiers-as-metadata"
  ]
  elif $id == "provider-side-construction"
  then [
    "verify-provider-output-member",
    "verify-claimed-bit-reproducibility",
    "verify-semantic-equivalence-for-distinct-member"
  ]
  else []
  end;

def expected_verification_phase($id):
  if $id == "verify-source-artifact-set" or
     $id == "verify-oci-root-descriptor"
  then "O0"
  elif $id == "verify-transferred-content" or
       $id == "bind-provider-reference-as-metadata" or
       $id == "verify-oci-graph-and-product-manifest" or
       $id == "classify-provider-identifiers-as-metadata"
  then "H0"
  elif $id == "verify-provider-output-member" or
       $id == "verify-claimed-bit-reproducibility" or
       $id == "verify-semantic-equivalence-for-distinct-member"
  then "N1"
  else null
  end;

def contract_error($contract; $message):
  "\($contract.id // "<missing-contract-id>"): \($message)";

def obligation_group_errors($contract; $group; $items):
  [
    if $items | obligation_array
    then empty
    else contract_error($contract; "\($group) must be a non-empty closed structured obligation array")
    end,
    if obligation_ids($items) ==
         (expected_obligation_ids($contract.id; $group) | sort)
    then empty
    else contract_error($contract; "\($group) IDs must equal the contract-specific obligation set")
    end
  ];

def contract_errors($contract):
  [
    (
      unknown_keys(
        $contract;
        [
          "id",
          "invariants",
          "conformanceClass",
          "safetyPolicy",
          "input",
          "admission",
          "identityVerification",
          "cacheExplanation",
          "secretExplanation",
          "retentionExplanation",
          "runtimeEvidence",
          "unsupportedWhen",
          "providerExampleExplanations"
        ]
      )[] as $key |
      contract_error($contract; "unknown contract key: \($key)")
    ),

    (
      unknown_keys(
        $contract.safetyPolicy;
        ["failure", "defaults", "warnings", "verification", "cache", "secrets", "retention"]
      )[] as $key |
      contract_error($contract; "unknown safetyPolicy key: \($key)")
    ),

    if $contract.safetyPolicy == expected_safety_policy
    then empty
    else contract_error($contract; "safetyPolicy must equal the closed fail-closed provider policy")
    end,

    (
      unknown_keys($contract.input; ["required", "forbidden"])[] as $key |
      contract_error($contract; "unknown input key: \($key)")
    ),

    (
      unknown_keys(
        $contract.admission;
        ["firstSoundPhase", "deadline", "authority", "requirements"]
      )[] as $key |
      contract_error($contract; "unknown admission key: \($key)")
    ),

    (
      unknown_keys(
        $contract.admission.authority;
        ["phase", "component"]
      )[] as $key |
      contract_error($contract; "unknown admission authority key: \($key)")
    ),

    if $contract.id | nonempty_string
    then empty
    else contract_error($contract; "id must be non-empty")
    end,

    if conformance_classes | index($contract.conformanceClass)
    then empty
    else contract_error($contract; "unknown conformance class: \($contract.conformanceClass // "<missing>")")
    end,

    if $contract.invariants | nonempty_string_array
    then empty
    else contract_error($contract; "invariants must be non-empty")
    end,

    if $contract.id == "provider-side-construction" and
       $contract.conformanceClass != "rebuild-requires-equivalence-proof"
    then contract_error($contract; "provider-side construction requires rebuild-requires-equivalence-proof")
    elif (
      $contract.id == "prebuilt-member-transfer" or
      $contract.id == "oci-descriptor-transfer"
    ) and $contract.conformanceClass != "content-preserving-transfer"
    then contract_error($contract; "content-preserving transfer requires content-preserving-transfer")
    else empty
    end,

    obligation_group_errors(
      $contract;
      "input.required";
      $contract.input.required
    )[],

    obligation_group_errors(
      $contract;
      "input.forbidden";
      $contract.input.forbidden
    )[],

    if phase_rank($contract.admission.firstSoundPhase) != null
    then empty
    else contract_error($contract; "unknown admission firstSoundPhase: \($contract.admission.firstSoundPhase // "<missing>")")
    end,

    if phase_rank($contract.admission.deadline) != null
    then empty
    else contract_error($contract; "unknown admission deadline: \($contract.admission.deadline // "<missing>")")
    end,

    if phase_rank($contract.admission.firstSoundPhase) != null and
       phase_rank($contract.admission.deadline) != null and
       phase_rank($contract.admission.firstSoundPhase) > phase_rank($contract.admission.deadline)
    then contract_error($contract; "admission firstSoundPhase occurs after deadline")
    else empty
    end,

    if {
         firstSoundPhase: $contract.admission.firstSoundPhase,
         deadline: $contract.admission.deadline,
         authority: $contract.admission.authority
       } == expected_admission($contract.id)
    then empty
    else contract_error($contract; "admission window and authority must equal the contract-specific contract")
    end,

    if phase_rank($contract.admission.authority.phase) != null
    then empty
    else contract_error($contract; "unknown admission authority phase: \($contract.admission.authority.phase // "<missing>")")
    end,

    if $contract.admission.authority.component | nonempty_string
    then empty
    else contract_error($contract; "admission authority component must be non-empty")
    end,

    if phase_rank($contract.admission.firstSoundPhase) != null and
       phase_rank($contract.admission.deadline) != null and
       phase_rank($contract.admission.authority.phase) != null and
       (
         phase_rank($contract.admission.authority.phase) <
           phase_rank($contract.admission.firstSoundPhase) or
         phase_rank($contract.admission.authority.phase) >
           phase_rank($contract.admission.deadline)
       )
    then contract_error($contract; "admission authority phase must fall between firstSoundPhase and deadline")
    else empty
    end,

    obligation_group_errors(
      $contract;
      "admission.requirements";
      $contract.admission.requirements
    )[],

    if ($contract.identityVerification | type) == "array" and
       ($contract.identityVerification | length) > 0 and
       all($contract.identityVerification[]; type == "object")
    then empty
    else contract_error($contract; "identityVerification must be a non-empty structured obligation array")
    end,

    if ([
         $contract.identityVerification[]? |
         select(type == "object") |
         .id
       ] | sort) ==
         (expected_verification_ids($contract.id) | sort)
    then empty
    else contract_error($contract; "identityVerification IDs must equal the contract-specific obligation set")
    end,

    (
      $contract.identityVerification[]? |
      select(type == "object") as $verification |
      unknown_keys(
        $verification;
        ["id", "phase", "component", "explanation"]
      )[] as $key |
      contract_error($contract; "unknown identityVerification key: \($key)")
    ),

    (
      $contract.identityVerification[]? |
      select(type == "object") as $verification |
      if ($verification.id | nonempty_string) and
         (phase_rank($verification.phase) != null) and
         ($verification.component | nonempty_string) and
         ($verification.explanation | nonempty_string)
      then empty
      else contract_error($contract; "identityVerification obligations require id, phase, component, and explanation")
      end
    ),

    (
      $contract.identityVerification[]? |
      select(type == "object") as $verification |
      if phase_rank($verification.phase) >=
           phase_rank($contract.admission.firstSoundPhase) and
         phase_rank($verification.phase) <=
           phase_rank($contract.admission.deadline) and
         $verification.component ==
           $contract.admission.authority.component
      then empty
      else contract_error($contract; "identityVerification obligation must use the contract authority within its admission window")
      end
    ),

    (
      $contract.identityVerification[]? |
      select(type == "object") as $verification |
      if $verification.phase == expected_verification_phase($verification.id)
      then empty
      else contract_error($contract; "identityVerification obligation must use its contract-specific phase")
      end
    ),

    (
      $contract.identityVerification[]? |
      select(type == "object") as $verification |
      if $verification.id | test("^[a-z0-9]+(?:-[a-z0-9]+)*$")
      then empty
      else contract_error($contract; "identityVerification id must be a stable lowercase token")
      end
    ),

    if $contract.cacheExplanation | nonempty_string
    then empty
    else contract_error($contract; "cacheExplanation must be non-empty")
    end,

    if $contract.secretExplanation | nonempty_string
    then empty
    else contract_error($contract; "secretExplanation must be non-empty")
    end,

    if $contract.retentionExplanation | nonempty_string
    then empty
    else contract_error($contract; "retentionExplanation must be non-empty")
    end,

    obligation_group_errors(
      $contract;
      "runtimeEvidence";
      $contract.runtimeEvidence
    )[],

    obligation_group_errors(
      $contract;
      "unsupportedWhen";
      $contract.unsupportedWhen
    )[],

    if $contract.providerExampleExplanations | nonempty_string_array
    then empty
    else contract_error($contract; "providerExampleExplanations must be non-empty")
    end,

    if ($contract | placeholder_strings | length) == 0
    then empty
    else contract_error($contract; "contains placeholder content")
    end,

    if (
         {
           admission: $contract.admission,
           identityVerification: $contract.identityVerification,
           safetyPolicy: $contract.safetyPolicy,
           runtimeEvidence: $contract.runtimeEvidence,
           unsupportedWhen: $contract.unsupportedWhen
         } |
         unsafe_semantic_strings |
         length
       ) == 0
    then empty
    else contract_error($contract; "contains fail-open, default-inheriting, warning-only, or best-effort semantics")
    end
  ];

. as $document |
(
  [
    (
      unknown_keys(
        $document;
        [
          "reviewVersion",
          "packet",
          "status",
          "textAuthority",
          "transportIsNotTarget",
          "introducedInvariants",
          "identityContract",
          "unsupportedContract",
          "identityExplanation",
          "unsupportedExplanation",
          "contracts"
        ]
      )[] as $key |
      "unknown provider-contract registry key: \($key)"
    ),

    if $document.reviewVersion == 1
    then empty
    else "reviewVersion must equal 1"
    end,

    if $document.packet == "C"
    then empty
    else "packet must equal C"
    end,

    if $document.status == "specified" or $document.status == "reviewed"
    then empty
    else "status must equal specified or reviewed"
    end,

    if $document.textAuthority == text_authority
    then empty
    else "textAuthority must lock structured controls and mark explanations non-normative"
    end,

    if $document.transportIsNotTarget == true
    then empty
    else "transportIsNotTarget must equal true"
    end,

    if $document.introducedInvariants | nonempty_string_array
    then empty
    else "introducedInvariants must be non-empty"
    end,

    if $document.identityContract == expected_identity_contract
    then empty
    else "identityContract must equal the closed provider identity contract"
    end,

    if $document.unsupportedContract == expected_unsupported_contract
    then empty
    else "unsupportedContract must equal the closed provider unsupported contract"
    end,

    if $document.identityExplanation | nonempty_string
    then empty
    else "identityExplanation must be non-empty"
    end,

    if $document.unsupportedExplanation | nonempty_string
    then empty
    else "unsupportedExplanation must be non-empty"
    end,

    if ($document.contracts | type) == "array" and
       ($document.contracts | length > 0)
    then empty
    else "contracts must be non-empty"
    end,

    (
      ($document.contracts // []) |
      sort_by(.id) |
      group_by(.id)[] |
      select(length > 1) |
      "duplicate contract id: \(.[0].id // "<missing-contract-id>")"
    ),

    (
      required_contracts[] as $required |
      if any($document.contracts[]?; .id == $required)
      then empty
      else "missing required provider contract: \($required)"
      end
    ),

    (
      $document.contracts[]? as $contract |
      if required_contracts | index($contract.id)
      then empty
      else contract_error($contract; "unknown provider contract")
      end
    ),

    (
      $document.contracts[]? as $contract |
      contract_errors($contract)[]
    ),

    (
      $document.contracts[]?.invariants[]? as $invariant |
      if $document.introducedInvariants | index($invariant)
      then empty
      else "provider contract references undeclared invariant: \($invariant)"
      end
    ),

    if ($document | placeholder_strings | length) == 0
    then empty
    else "contains placeholder content"
    end
  ]
) as $errors |
if $errors | length == 0
then $document
else error($errors | join("\n"))
end
