# Disposable adapter from the first common-slice prototype output to the
# provisional W0 comparison value. This is shape translation only: the shared
# validator owns semantic acceptance. It is not a public schema migration.
def adaptation_error($path; $detail):
  error("WIRE-005: \($path) \($detail)");

def exact_object($required; $path):
  if type != "object" then
    adaptation_error($path; "must be an object before frontend adaptation")
  else
    . as $object
    | (($object | keys_unsorted) - $required) as $unknown
    | ($required - ($object | keys_unsorted)) as $missing
    | if ($unknown | length) != 0 then
        adaptation_error(
          $path;
          "contains unknown fields that adaptation would discard: \($unknown | join(", "))"
        )
      elif ($missing | length) != 0 then
        adaptation_error(
          $path;
          "omits required fields: \($missing | join(", "))"
        )
      else
        $object
      end
  end;

def value_type($expected; $path):
  if type == $expected then
    .
  else
    adaptation_error($path; "must be \($expected), got \(type)")
  end;

def enum_value($allowed; $path):
  . as $value
  | if ($allowed | index($value)) != null then
      $value
    else
      adaptation_error($path; "has unsupported value \($value | tojson)")
    end;

def string_array($path; $allowed):
  value_type("array"; $path)
  | . as $values
  | if all($values[]; type == "string") then
      if $allowed == null or all($values[]; . as $value | ($allowed | index($value)) != null) then
        $values
      else
        adaptation_error($path; "contains an unsupported value")
      end
    else
      adaptation_error($path; "must contain only strings")
    end;

def safe_nonnegative_integer($path):
  if type == "number"
     and . >= 0
     and . <= 9007199254740991
     and floor == . then
    .
  else
    adaptation_error($path; "must be a non-negative interoperable integer")
  end;

def validate_frontend_shape:
  . as $root
  | ($root | exact_object([
      "schemaVersion",
      "profile",
      "environment",
      "workspace",
      "network",
      "secrets",
      "resources",
      "targets",
      "requiredCapabilities",
      "runtimeProfiles"
    ]; "$")) as $_root
  | if $root.schemaVersion == 1 then
      .
    else
      adaptation_error(
        "$.schemaVersion";
        "has unsupported value \($root.schemaVersion | tojson)"
      )
    end
  | ($root.profile
      | exact_object(["selected", "selectionIsVisible"]; "$.profile")
      | (.selected
          | value_type("string"; "$.profile.selected")
          | enum_value([
              "workspace-edit-offline",
              "workspace-live-development"
            ]; "$.profile.selected")) as $_selected
      | (.selectionIsVisible
          | value_type("boolean"; "$.profile.selectionIsVisible")) as $_selection_visible
      | .
    ) as $_profile
  | ($root.environment | exact_object([
      "packages",
      "variables",
      "activation"
    ]; "$.environment")) as $_environment
  | ($root.environment.packages
      | value_type("array"; "$.environment.packages")) as $_package_array
  | ([$root.environment.packages[] |
      exact_object(["input", "attribute"]; "$.environment.packages[]")
      | (.input | value_type("string"; "$.environment.packages[].input")) as $_input
      | (.attribute | value_type("string"; "$.environment.packages[].attribute")) as $_attribute
      | .
    ]) as $_packages
  | ($root.environment.variables
      | value_type("object"; "$.environment.variables")
      | if all(to_entries[]; .value | type == "string") then
          .
        else
          adaptation_error("$.environment.variables"; "must contain only string values")
        end) as $_variables
  | ($root.environment.activation
      | string_array("$.environment.activation"; null)) as $_activation
  | ($root.workspace | exact_object([
      "destination",
      "materialization",
      "allowedMaterializations",
      "access"
    ]; "$.workspace")
      | (.destination | value_type("string"; "$.workspace.destination")) as $_destination
      | (.materialization
          | value_type("string"; "$.workspace.materialization")
          | enum_value(["copy", "live"]; "$.workspace.materialization")) as $_materialization
      | (.allowedMaterializations
          | string_array("$.workspace.allowedMaterializations"; ["copy", "live"])) as $_allowed
      | (.access
          | value_type("string"; "$.workspace.access")
          | enum_value(["read-write", "read-only"]; "$.workspace.access")) as $_access
      | .
    ) as $_workspace
  | ($root.network | exact_object([
      "mode",
      "egressAllow",
      "hardPolicy"
    ]; "$.network")
      | (.mode
          | value_type("string"; "$.network.mode")
          | enum_value(["none", "egress"]; "$.network.mode")) as $_mode
      | (.egressAllow | string_array("$.network.egressAllow"; null)) as $_egress
      | .
    ) as $_network
  | ($root.network.hardPolicy |
      exact_object(["allowedDestinations"]; "$.network.hardPolicy")
      | (.allowedDestinations
          | string_array("$.network.hardPolicy.allowedDestinations"; null))
        as $_allowed_destinations
      | .) as $_hard_policy
  | ($root.secrets | value_type("array"; "$.secrets")) as $_secret_array
  | ([$root.secrets[] |
      exact_object(["name", "delivery"]; "$.secrets[]")
      | (.name | value_type("string"; "$.secrets[].name")) as $_name
      | (.delivery
          | value_type("string"; "$.secrets[].delivery")
          | enum_value(["environment", "file"]; "$.secrets[].delivery")) as $_delivery
      | .
    ]) as $_secrets
  | ($root.resources | exact_object(["memory"]; "$.resources")) as $_resources
  | ($root.resources.memory |
      exact_object(["minimumBytes", "maximumBytes"]; "$.resources.memory")
      | (.minimumBytes
          | safe_nonnegative_integer("$.resources.memory.minimumBytes")) as $_minimum
      | (.maximumBytes
          | safe_nonnegative_integer("$.resources.memory.maximumBytes")) as $_maximum
      | .
    ) as $_memory
  | ($root.targets
      | string_array("$.targets"; ["bubblewrap", "firecracker"])) as $_targets
  | ($root.requiredCapabilities
      | string_array("$.requiredCapabilities"; null)) as $_required_capabilities
  | ($root.runtimeProfiles
      | value_type("object"; "$.runtimeProfiles")) as $_runtime_profile_object
  | ([$root.runtimeProfiles | to_entries[] | .value |
      exact_object(["target", "materializations"]; "$.runtimeProfiles.*")
      | (.target
          | value_type("string"; "$.runtimeProfiles.*.target")
          | enum_value(["bubblewrap", "firecracker"]; "$.runtimeProfiles.*.target")) as $_target
      | (.materializations
          | string_array("$.runtimeProfiles.*.materializations"; ["copy", "live"]))
        as $_materializations
      | .
    ]) as $_runtime_profiles
  | $root;

validate_frontend_shape |
{
  schemaVersion: {
    major: 0,
    minor: 1
  },
  profile: .profile,
  environment: {
    packages: [
      .environment.packages[] |
      {
        source: {
          kind: "nixInput",
          input: .input,
          attribute: .attribute
        }
      }
    ],
    variables: .environment.variables,
    activation: [.environment.activation]
  },
  workspace: {
    destination: .workspace.destination,
    materialization: .workspace.materialization,
    allowedMaterializations: .workspace.allowedMaterializations,
    access: (
      if .workspace.access == "read-write" then
        "readWrite"
      elif .workspace.access == "read-only" then
        "readOnly"
      else
        .workspace.access
      end
    )
  },
  network: {
    mode: (
      if .network.mode == "none" then
        "disabled"
      else
        .network.mode
      end
    ),
    egressAllow: .network.egressAllow,
    hardPolicy: .network.hardPolicy
  },
  secrets: [
    .secrets[] |
    {
      name: .name,
      delivery: [.delivery]
    }
  ],
  resources: .resources,
  targets: .targets,
  requiredCapabilities: [
    .requiredCapabilities[] |
    if . == "network.none" then
      "network.disabled"
    else
      .
    end
  ],
  runtimeProfiles: .runtimeProfiles,
  extensions: {}
}
