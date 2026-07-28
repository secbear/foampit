let OneOf = fun values =>
  std.contract.from_predicate (fun value => std.array.elem value values)
in
let PackageReference = {
  input | String,
  attribute | String,
}
in
let PolicyDefinition = {
  allowedDestinations | Array String,
  source | String,
}
in
let SecretSlot = {
  name | String,
  delivery | OneOf ["environment", "file"],
}
in
let ArtifactInput = {
  profile
    | OneOf ["workspace-edit-offline", "workspace-live-development"]
    | default
    = "workspace-edit-offline",
  environment
    | {
      packages | Array PackageReference,
      variables | { _ | String },
      activation | Array String,
    },
  workspace
    | {
      destination | String,
      materialization | OneOf ["inherit", "copy", "live"] | default = "inherit",
      allowedMaterializations | Array (OneOf ["copy", "live"]) | default = ["copy"],
      access | OneOf ["inherit", "read-only", "read-write"] | default = "inherit",
    },
  network
    | {
      mode | OneOf ["inherit", "none", "egress"] | default = "inherit",
      egressAllow | Array String | default = [],
      hardPolicy
        | {
          base | PolicyDefinition,
          refinements | Array PolicyDefinition | default = [],
        },
    },
  secrets | Array SecretSlot,
  resources
    | {
      memory
        | {
          minimumBytes | Number,
          maximumBytes | Number,
        },
    },
  targets | Array (OneOf ["bubblewrap", "firecracker"]),
}
in
let CreateInput = {
  runtimeProfile | String,
  workspace
    | {
      materialization | OneOf ["copy", "live"],
    },
  allocation
    | {
      memoryBytes | Number,
    },
}
in
let profiles = {
  "workspace-edit-offline" = {
    workspace = {
      materialization = "copy",
      access = "read-write",
    },
    network.mode = "none",
  },
  "workspace-live-development" = {
    workspace = {
      materialization = "live",
      access = "read-write",
    },
    network.mode = "egress",
  },
}
in
let target_capabilities = fun target =>
  if target == "bubblewrap" then
    [
      "workspace.copy",
      "workspace.live",
      "network.none",
      "network.egress",
    ]
  else
    [
      "workspace.copy",
      "network.none",
      "network.egress",
    ]
in
let ensure = fun condition message value =>
  if condition then value else (value | std.FailWith message)
in
let compileArtifact = fun raw =>
  let input = raw | ArtifactInput in
  let profile = std.record.get input.profile profiles in
  let resolved_materialization =
    if input.workspace.materialization == "inherit" then
      profile.workspace.materialization
    else
      input.workspace.materialization
  in
  let resolved_access =
    if input.workspace.access == "inherit" then
      profile.workspace.access
    else
      input.workspace.access
  in
  let network_mode =
    if input.network.mode == "inherit" then
      profile.network.mode
    else
      input.network.mode
  in
  let profile_consistent =
    (
      input.workspace.materialization == "inherit"
      || input.workspace.materialization == profile.workspace.materialization
    )
    && (
      input.workspace.access == "inherit"
      || input.workspace.access == profile.workspace.access
    )
    && (input.network.mode == "inherit" || input.network.mode == profile.network.mode)
  in
  let refinement_is_narrower = fun refinement =>
    std.array.all
      (fun destination =>
        std.array.elem destination input.network.hardPolicy.base.allowedDestinations
      )
      refinement.allowedDestinations
  in
  let policy_is_monotonic =
    std.array.all refinement_is_narrower input.network.hardPolicy.refinements
  in
  let required_capabilities = [
    "network.%{network_mode}",
    "workspace.%{resolved_materialization}",
  ]
  in
  let target_supports_requirements = fun target =>
    std.array.all
      (fun capability => std.array.elem capability (target_capabilities target))
      required_capabilities
  in
  let every_target_supports_requirements =
    std.array.all target_supports_requirements input.targets
  in
  let runtime_profiles =
    {}
    & (
      if std.array.elem "bubblewrap" input.targets
      && std.array.elem "copy" input.workspace.allowedMaterializations then
        {
          "bubblewrap-copy" = {
            target = "bubblewrap",
            materializations = ["copy"],
          },
        }
      else
        {}
    )
    & (
      if std.array.elem "bubblewrap" input.targets
      && std.array.elem "live" input.workspace.allowedMaterializations then
        {
          "bubblewrap-live" = {
            target = "bubblewrap",
            materializations = ["live"],
          },
        }
      else
        {}
    )
    & (
      if std.array.elem "firecracker" input.targets
      && std.array.elem "copy" input.workspace.allowedMaterializations then
        {
          "firecracker-copy" = {
            target = "firecracker",
            materializations = ["copy"],
          },
        }
      else
        {}
    )
  in
  let manifest = {
    schemaVersion = 1,
    profile = {
      selected = input.profile,
      selectionIsVisible = true,
    },
    environment = input.environment,
    workspace = {
      destination = input.workspace.destination,
      materialization = resolved_materialization,
      allowedMaterializations = input.workspace.allowedMaterializations,
      access = resolved_access,
    },
    network = {
      mode = network_mode,
      egressAllow = input.network.egressAllow,
      hardPolicy.allowedDestinations =
        input.network.hardPolicy.base.allowedDestinations,
    },
    secrets = input.secrets,
    resources = input.resources,
    targets = input.targets,
    requiredCapabilities = required_capabilities,
    runtimeProfiles = runtime_profiles,
  }
  in
  ensure
    profile_consistent
    "artifact.profile.explicit_conflict: explicit value contradicts selected profile"
    (
      ensure
        (std.string.is_match "^/" input.workspace.destination)
        "artifact.mount.destination_absolute: workspace destination must be absolute"
        (
          ensure
            (std.array.length input.environment.activation > 0)
            "artifact.environment.activation_nonempty: activation argv must not be empty"
            (
              ensure
                (network_mode != "none" || std.array.length input.network.egressAllow == 0)
                "artifact.network.none_has_no_egress: disabled network cannot have egress destinations"
                (
                  ensure
                    policy_is_monotonic
                    "artifact.policy.monotonic_refinement: refinement widens hard policy"
                    (
                      ensure
                        every_target_supports_requirements
                        "artifact.target.required_capability_supported: target lacks mandatory capability"
                        (
                          ensure
                            (std.array.length input.targets > 0)
                            "artifact.target.at_least_one: at least one target is required"
                            (
                              ensure
                                (
                                  input.resources.memory.minimumBytes <= input.resources.memory.maximumBytes
                                )
                                "artifact.resources.bounds_nonempty: minimum memory exceeds maximum"
                                manifest
                            )
                        )
                    )
                )
            )
        )
    )
in
let createSandbox = fun artifact raw =>
  let input = raw | CreateInput in
  let runtime_profile =
    std.record.get input.runtimeProfile artifact.runtimeProfiles
  in
  let result = {
    runtimeProfile = input.runtimeProfile,
    workspace = input.workspace,
    allocation = input.allocation,
  }
  in
  ensure
    (std.array.elem input.workspace.materialization runtime_profile.materializations)
    "create.runtime_profile_supports_binding: runtime profile does not support requested workspace materialization"
    (
      ensure
        (
          input.allocation.memoryBytes >= artifact.resources.memory.minimumBytes
          && input.allocation.memoryBytes <= artifact.resources.memory.maximumBytes
        )
        "create.allocation.within_artifact_bounds: requested memory outside Artifact bounds"
        result
    )
in
{
  compile = compileArtifact,
  create = createSandbox,
}
