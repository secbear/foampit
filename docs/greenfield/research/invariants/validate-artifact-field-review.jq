def required_families:
  [
    "profile",
    "metadata",
    "platform",
    "environment",
    "process",
    "workspace",
    "filesystem",
    "network",
    "resources",
    "identity",
    "security",
    "secretSlots",
    "requirements",
    "lifecycleRequirements",
    "outputs",
    "provenance",
    "targets"
  ];

def field_kinds:
  ["scalar", "object", "map", "list", "sum-type", "reference", "derived"];

def outcomes:
  ["covered", "delegated", "no-new-rule"];

def destination_packets:
  ["C", "D", "E", "F"];

def nonempty_string:
  type == "string" and (gsub("^\\s+|\\s+$"; "") | length > 0);

def string_array:
  type == "array" and all(.[]; nonempty_string);

def placeholder_strings:
  [
    .. |
    strings |
    select(test("^(TBD|TODO|FIXME)(:|\\b|$)|^UNKNOWN$"; "i"))
  ];

def registry_ids:
  [$registry[0].invariants[].id];

def packet_a_artifact_surface_ids:
  [
    $packetA[0].surfaces[] |
    select(.resource == "artifact" or .resource == "manifest") |
    .id
  ];

def field_error($field; $message):
  "\($field.id // "<missing-id>"): \($message)";

def field_errors($field):
  [
    if $field.id | nonempty_string
    then empty
    else field_error($field; "id must be non-empty")
    end,

    if required_families | index($field.family)
    then empty
    else field_error($field; "unknown family: \($field.family // "<missing>")")
    end,

    if $field.owner == "artifact"
    then empty
    else field_error($field; "unknown owner: \($field.owner // "<missing>")")
    end,

    if field_kinds | index($field.kind)
    then empty
    else field_error($field; "unknown field kind: \($field.kind // "<missing>")")
    end,

    if outcomes | index($field.outcome)
    then empty
    else field_error($field; "unknown outcome: \($field.outcome // "<missing>")")
    end,

    if $field.invariants | string_array
    then empty
    else field_error($field; "invariants must be an array of identifiers")
    end,

    (
      ($field.invariants // []) |
      sort |
      group_by(.)[] |
      select(length > 1) |
      field_error($field; "duplicate invariant reference: \(.[0])")
    ),

    if $field.outcome == "covered" and
       ($field.invariants | length == 0)
    then field_error($field; "covered field requires an invariant")
    else empty
    end,

    if $field.delegatedPackets | string_array
    then empty
    else field_error($field; "delegatedPackets must be an array of packet identifiers")
    end,

    (
      ($field.delegatedPackets // []) |
      sort |
      group_by(.)[] |
      select(length > 1) |
      field_error($field; "duplicate delegated packet: \(.[0])")
    ),

    if $field.outcome == "delegated" and
       (
         ($field.delegatedPackets | length == 0) or
         any($field.delegatedPackets[]; destination_packets | index(.) | not)
       )
    then field_error($field; "delegated field requires packet C-F")
    else empty
    end,

    if $field.outcome != "delegated" and
       ($field.delegatedPackets | length > 0)
    then field_error($field; "only delegated fields name delegatedPackets")
    else empty
    end,

    if $field.refinesPacketASurfaces | string_array
    then empty
    else field_error($field; "refinesPacketASurfaces must be an array of surface identifiers")
    end,

    (
      ($field.refinesPacketASurfaces // []) |
      sort |
      group_by(.)[] |
      select(length > 1) |
      field_error($field; "duplicate Packet A surface reference: \(.[0])")
    ),

    (
      $field.invariants[]? as $invariant |
      if registry_ids | index($invariant)
      then empty
      else field_error($field; "unknown invariant reference: \($invariant)")
      end
    ),

    (
      $field.refinesPacketASurfaces[]? as $surface |
      if packet_a_artifact_surface_ids | index($surface)
      then empty
      else field_error($field; "unknown Packet A Artifact surface: \($surface)")
      end
    ),

    if $field.portableMeaning | nonempty_string
    then empty
    else field_error($field; "portableMeaning must be non-empty")
    end,

    if $field.valueShape | nonempty_string
    then empty
    else field_error($field; "valueShape must be non-empty")
    end,

    if $field.omissionSemantics | nonempty_string
    then empty
    else field_error($field; "omissionSemantics must be non-empty")
    end,

    if $field.forbiddenInputs | string_array
    then empty
    else field_error($field; "forbiddenInputs must be an array of descriptions")
    end,

    if $field.manifestProjection | nonempty_string
    then empty
    else field_error($field; "manifestProjection must be non-empty")
    end,

    if $field.rationale | nonempty_string
    then empty
    else field_error($field; "rationale must be non-empty")
    end,

    if ($field | placeholder_strings | length) == 0
    then empty
    else field_error($field; "contains placeholder content")
    end
  ];

. as $review |
(
  [
    if $review.reviewVersion == 1
    then empty
    else "reviewVersion must equal 1"
    end,

    if $review.packet == "B"
    then empty
    else "packet must equal B"
    end,

    if $review.status == "reviewed"
    then empty
    else "status must equal reviewed"
    end,

    if ($review.requiredFamilies | string_array) and
       ($review.requiredFamilies | length > 0)
    then empty
    else "requiredFamilies must be non-empty"
    end,

    (
      ($review.requiredFamilies // []) |
      sort |
      group_by(.)[] |
      select(length > 1) |
      "duplicate required family: \(.[0])"
    ),

    (
      required_families[] as $family |
      if $review.requiredFamilies | index($family)
      then empty
      else "requiredFamilies omits mandatory family: \($family)"
      end
    ),

    (
      $review.requiredFamilies[]? as $family |
      if required_families | index($family)
      then empty
      else "unknown required family: \($family)"
      end
    ),

    if $review.introducedInvariants | string_array
    then empty
    else "introducedInvariants must be an array of invariant identifiers"
    end,

    (
      ($review.introducedInvariants // []) |
      sort |
      group_by(.)[] |
      select(length > 1) |
      "duplicate introduced invariant: \(.[0])"
    ),

    if ($review.fields | type) == "array" and
       ($review.fields | length > 0)
    then empty
    else "fields must be non-empty"
    end,

    (
      ($review.fields // []) |
      sort_by(.id) |
      group_by(.id)[] |
      select(length > 1) |
      "duplicate field id: \(.[0].id // "<missing-id>")"
    ),

    (
      $review.requiredFamilies[]? as $family |
      if any($review.fields[]?; .family == $family)
      then empty
      else "required family has no field entry: \($family)"
      end
    ),

    (
      $review.introducedInvariants[]? as $invariant |
      if registry_ids | index($invariant)
      then empty
      else "unknown introduced invariant: \($invariant)"
      end
    ),

    (
      $review.introducedInvariants[]? as $invariant |
      if any($review.fields[]?; .invariants | index($invariant))
      then empty
      else "introduced invariant is not referenced by a field: \($invariant)"
      end
    ),

    (
      packet_a_artifact_surface_ids[] as $surface |
      if any($review.fields[]?; .refinesPacketASurfaces | index($surface))
      then empty
      else "Packet A Artifact surface is not refined: \($surface)"
      end
    ),

    (
      $review.fields[]? as $field |
      field_errors($field)[]
    ),

    if ($review | placeholder_strings | length) == 0
    then empty
    else "Artifact field review contains placeholder content"
    end
  ]
) as $errors |
if $errors | length == 0
then $review
else error($errors | join("\n"))
end
