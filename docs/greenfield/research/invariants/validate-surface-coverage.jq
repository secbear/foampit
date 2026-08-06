def owners:
  [
    "artifact", "create", "operator", "service",
    "live", "exec", "framework", "runtime",
    "core"
  ];

def resources:
  [
    "artifact", "manifest", "operator", "service",
    "create", "live", "exec", "framework", "runtime"
  ];

def kinds:
  [
    "resource",
    "field-group",
    "operation",
    "trust-boundary",
    "extension-boundary"
  ];

def outcomes:
  ["covered", "delegated", "no-new-rule"];

def string_array:
  type == "array" and all(.[]; type == "string" and length > 0);

def nonempty_string:
  type == "string" and length > 0;

def placeholder_strings:
  [
    .. |
    strings |
    select(test("^(TBD|TODO|FIXME)(:|\\b|$)|^UNKNOWN$"; "i"))
  ];

def surface_error($surface; $message):
  "\($surface.id // "<missing-id>"): \($message)";

def registry_ids:
  [$registry[0].invariants[].id];

def surface_errors($surface):
  [
    if $surface.id | nonempty_string
    then empty
    else surface_error($surface; "id must be non-empty")
    end,

    if resources | index($surface.resource)
    then empty
    else surface_error($surface; "unknown resource: \($surface.resource // "<missing>")")
    end,

    if owners | index($surface.owner)
    then empty
    else surface_error($surface; "unknown owner: \($surface.owner // "<missing>")")
    end,

    if kinds | index($surface.kind)
    then empty
    else surface_error($surface; "unknown kind: \($surface.kind // "<missing>")")
    end,

    if outcomes | index($surface.outcome)
    then empty
    else surface_error($surface; "unknown outcome: \($surface.outcome // "<missing>")")
    end,

    if $surface.invariants | string_array
    then empty
    else surface_error($surface; "invariants must be an array of identifiers")
    end,

    if $surface.outcome == "covered" and
       ($surface.invariants | length == 0)
    then surface_error($surface; "covered surface requires an invariant")
    else empty
    end,

    if $surface.outcome == "delegated" and
       (($surface.delegatedPacket | type) != "string" or
        (["B", "C", "D", "E", "F"] | index($surface.delegatedPacket) | not))
    then surface_error($surface; "delegated surface requires packet B-F")
    else empty
    end,

    if $surface.outcome != "delegated" and
       $surface.delegatedPacket != null
    then surface_error($surface; "only delegated surfaces name delegatedPacket")
    else empty
    end,

    (
      $surface.invariants[]? as $invariant |
      if registry_ids | index($invariant)
      then empty
      else surface_error($surface; "unknown invariant reference: \($invariant)")
      end
    ),

    if $surface.rationale | nonempty_string
    then empty
    else surface_error($surface; "rationale must be non-empty")
    end,

    if ($surface | placeholder_strings | length) == 0
    then empty
    else surface_error($surface; "contains placeholder content")
    end
  ];

. as $coverage |
(
  [
    if $coverage.reviewVersion == 1
    then empty
    else "reviewVersion must equal 1"
    end,
    if $coverage.packet == "A"
    then empty
    else "packet must equal A"
    end,
    if $coverage.status == "reviewed"
    then empty
    else "status must equal reviewed"
    end,
    if ($coverage.requiredResources | string_array) and
       ($coverage.requiredResources | length > 0)
    then empty
    else "requiredResources must be non-empty"
    end,
    if ($coverage.surfaces | type) == "array" and
       ($coverage.surfaces | length > 0)
    then empty
    else "surfaces must be non-empty"
    end,
    (
      ($coverage.surfaces // []) |
      sort_by(.id) |
      group_by(.id)[] |
      select(length > 1) |
      "duplicate surface id: \(.[0].id // "<missing-id>")"
    ),
    (
      $coverage.requiredResources[]? as $resource |
      if resources | index($resource)
      then empty
      else "unknown required resource: \($resource)"
      end
    ),
    (
      $coverage.requiredResources[]? as $resource |
      if any($coverage.surfaces[]?; .resource == $resource)
      then empty
      else "required resource has no surface entry: \($resource)"
      end
    ),
    (
      $coverage.surfaces[]? as $surface |
      surface_errors($surface)[]
    )
  ]
) as $errors |
if $errors | length == 0
then $coverage
else error($errors | join("\n"))
end
