{
  lib,
  pkgs,
}:
let
  inherit (lib)
    all
    concatMap
    elem
    filter
    foldl'
    hasPrefix
    intersectLists
    mapAttrs
    mkOption
    types
    unique
    ;

  ensure =
    condition: invariant: detail: value:
    if condition then
      value
    else
      throw "${invariant}: ${detail}";

  nonNegativeInt = types.addCheck types.int (value: value >= 0);

  maximumDefinitionType = types.mkOptionType {
    name = "maximum of non-negative integer definitions";
    description = "non-negative integer refined upward by every definition";
    check = nonNegativeInt.check;
    merge = _: definitions: foldl' lib.max 0 (map (definition: definition.value) definitions);
  };

  minimumDefinitionType = types.mkOptionType {
    name = "minimum of non-negative integer definitions";
    description = "non-negative integer refined downward by every definition";
    check = nonNegativeInt.check;
    merge =
      location: definitions:
      if definitions == [ ] then
        throw "artifact.resources.maximum_required: ${lib.showOption location}"
      else
        foldl' lib.min (builtins.head definitions).value (
          map (definition: definition.value) (builtins.tail definitions)
        );
  };

  policyDefinitionType = types.submodule {
    options = {
      role = mkOption {
        type = types.enum [
          "base"
          "refinement"
        ];
      };
      allowedDestinations = mkOption {
        type = types.listOf types.str;
      };
      source = mkOption {
        type = types.str;
      };
    };
  };

  secretSlotType = types.submodule {
    options = {
      name = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      delivery = mkOption {
        type = types.enum [
          "environment"
          "file"
        ];
      };
    };
  };

  packageEntryType = types.submodule {
    options = {
      value = mkOption {
        type = types.package;
        description = "Native Nix package value retained for construction.";
      };
      source = {
        kind = mkOption {
          type = types.enum [ "nixInput" ];
        };
        input = mkOption {
          type = types.str;
        };
        attribute = mkOption {
          type = types.str;
        };
      };
    };
  };

  artifactSchema =
    { ... }:
    {
      options = {
        profile.selected = mkOption {
          type = types.enum [
            "workspace-edit-offline"
            "workspace-live-development"
          ];
          default = "workspace-edit-offline";
          description = "Visible prototype profile selection.";
        };

        environment.packages = mkOption {
          type = types.listOf packageEntryType;
        };
        environment.variables = mkOption {
          type = types.attrsOf types.str;
          default = { };
        };
        environment.activation = mkOption {
          type = types.listOf types.str;
        };

        workspace.destination = mkOption {
          type = types.str;
          default = "/workspace";
        };
        workspace.materialization = mkOption {
          type = types.nullOr (
            types.enum [
              "copy"
              "live"
            ]
          );
          default = null;
          description = "Explicit author value; null inherits the selected visible profile.";
        };
        workspace.allowedMaterializations = mkOption {
          type = types.listOf (
            types.enum [
              "copy"
              "live"
            ]
          );
          default = [ ];
        };
        workspace.access = mkOption {
          type = types.nullOr (
            types.enum [
              "read-only"
              "read-write"
            ]
          );
          default = null;
        };

        network.mode = mkOption {
          type = types.nullOr (
            types.enum [
              "none"
              "egress"
            ]
          );
          default = null;
        };
        network.egressAllow = mkOption {
          type = types.listOf types.str;
          default = [ ];
        };
        network.policyDefinitions = mkOption {
          type = types.listOf policyDefinitionType;
        };

        secrets = mkOption {
          type = types.listOf secretSlotType;
          default = [ ];
        };

        resources.memory.minimumBytes = mkOption {
          type = maximumDefinitionType;
        };
        resources.memory.maximumBytes = mkOption {
          type = minimumDefinitionType;
        };

        targets = mkOption {
          type = types.listOf (
            types.enum [
              "bubblewrap"
              "firecracker"
            ]
          );
        };

        nativeGuestModules = mkOption {
          type = types.listOf types.raw;
          default = [ ];
          internal = true;
        };
      };

      config._module.check = true;
    };

  guestSchema =
    { ... }:
    {
      options = {
        guest.packages = mkOption {
          type = types.listOf types.package;
          default = [ ];
        };
        guest.services = mkOption {
          type = types.attrsOf types.raw;
          default = { };
        };
        host.shares = mkOption {
          type = types.listOf types.str;
          default = [ ];
          internal = true;
        };
        host.interfaces = mkOption {
          type = types.listOf types.str;
          default = [ ];
          internal = true;
        };
      };
      config._module.check = true;
    };

  profiles = {
    workspace-edit-offline = {
      workspace = {
        materialization = "copy";
        access = "read-write";
      };
      network.mode = "none";
    };
    workspace-live-development = {
      workspace = {
        materialization = "live";
        access = "read-write";
      };
      network.mode = "egress";
    };
  };

  targetCatalog = {
    bubblewrap.capabilities = [
      "workspace.copy"
      "workspace.live"
      "network.none"
      "network.egress"
    ];
    firecracker.capabilities = [
      "workspace.copy"
      "network.none"
      "network.egress"
    ];
  };

  runtimeProfileCatalog = {
    bubblewrap-copy = {
      target = "bubblewrap";
      materializations = [ "copy" ];
    };
    bubblewrap-live = {
      target = "bubblewrap";
      materializations = [ "live" ];
    };
    firecracker-copy = {
      target = "firecracker";
      materializations = [ "copy" ];
    };
  };

  evaluateGuest =
    modules:
    let
      evaluated = lib.evalModules {
        modules = [ guestSchema ] ++ modules;
        specialArgs = { inherit pkgs; };
      };
      config = evaluated.config;
      noHostClaims = config.host.shares == [ ] && config.host.interfaces == [ ];
    in
    ensure noHostClaims "artifact.native_guest.owner_boundary"
      "guest modules may not define host shares or interfaces"
      {
        packageCount = builtins.length config.guest.packages;
        serviceNames = builtins.attrNames config.guest.services;
      };

  evaluateArtifactWithSpecialArgs =
    extraSpecialArgs: modules:
    let
      evaluated = lib.evalModules {
        modules = [ artifactSchema ] ++ modules;
        specialArgs = { inherit pkgs; } // extraSpecialArgs;
      };
      config = evaluated.config;
      profile = profiles.${config.profile.selected};

      explicitMaterialization = config.workspace.materialization;
      explicitAccess = config.workspace.access;
      explicitNetworkMode = config.network.mode;

      materialization =
        if explicitMaterialization == null then
          profile.workspace.materialization
        else
          explicitMaterialization;
      access = if explicitAccess == null then profile.workspace.access else explicitAccess;
      networkMode =
        if explicitNetworkMode == null then profile.network.mode else explicitNetworkMode;

      materializationConflict =
        explicitMaterialization != null
        && explicitMaterialization != profile.workspace.materialization;
      accessConflict = explicitAccess != null && explicitAccess != profile.workspace.access;
      networkConflict = explicitNetworkMode != null && explicitNetworkMode != profile.network.mode;

      basePolicies = filter (definition: definition.role == "base") config.network.policyDefinitions;
      refinementPolicies =
        filter (definition: definition.role == "refinement") config.network.policyDefinitions;
      policyDefinitionPriority = evaluated.options.network.policyDefinitions.highestPrio;
      policyDefinitionPriorityIsSupported = policyDefinitionPriority >= 100;
      basePolicy =
        if builtins.length basePolicies == 1 then
          builtins.head basePolicies
        else
          throw "artifact.policy.single_base_required: exactly one hard-policy base is required";
      refinementIsNarrower =
        definition:
        all (destination: elem destination basePolicy.allowedDestinations)
          definition.allowedDestinations;
      policyIsMonotonic = all refinementIsNarrower refinementPolicies;
      effectiveEgress = foldl' (
        allowed: definition: intersectLists allowed definition.allowedDestinations
      ) basePolicy.allowedDestinations refinementPolicies;

      requiredCapabilities = [
        "network.${networkMode}"
        "workspace.${materialization}"
      ];
      targetSupportsRequirements =
        target:
        all (capability: elem capability targetCatalog.${target}.capabilities) requiredCapabilities;
      everyTargetSupportsRequirements = all targetSupportsRequirements config.targets;

      allowedMaterializations =
        unique (
          if config.workspace.allowedMaterializations == [ ] then
            [ materialization ]
          else
            config.workspace.allowedMaterializations
        );
      runtimeProfiles = lib.filterAttrs (
        _: runtimeProfile:
        elem runtimeProfile.target config.targets
        && all (candidate: elem candidate allowedMaterializations) runtimeProfile.materializations
      ) runtimeProfileCatalog;

      memoryMinimum = config.resources.memory.minimumBytes;
      memoryMaximum = config.resources.memory.maximumBytes;
      guest = evaluateGuest config.nativeGuestModules;
      packageReferenceResolves =
        entry:
        entry.source.kind == "nixInput"
        && entry.source.input == "nixpkgs"
        && entry.source.attribute == "hello"
        && entry.value.outPath == pkgs.hello.outPath;
      packageReferencesResolve = all packageReferenceResolves config.environment.packages;

      provenance = {
        "network.policyDefinitions" = {
          highestPriority = policyDefinitionPriority;
          contributors = map (definition: {
            file = definition.file;
            value = definition.value;
          }) evaluated.options.network.policyDefinitions.definitionsWithLocations;
        };
        "resources.memory.minimumBytes" = map (definition: {
          file = definition.file;
          value = definition.value;
        }) evaluated.options.resources.memory.minimumBytes.definitionsWithLocations;
        "resources.memory.maximumBytes" = map (definition: {
          file = definition.file;
          value = definition.value;
        }) evaluated.options.resources.memory.maximumBytes.definitionsWithLocations;
      };

      portableValue = {
        schemaVersion = {
          major = 0;
          minor = 1;
        };
        profile = {
          selected = config.profile.selected;
          selectionIsVisible = true;
        };
        environment = {
          packages = map (entry: { inherit (entry) source; }) config.environment.packages;
          variables = config.environment.variables;
          activation = [ config.environment.activation ];
        };
        workspace = {
          destination = config.workspace.destination;
          inherit
            allowedMaterializations
            materialization
            ;
          access = if access == "read-write" then "readWrite" else "readOnly";
        };
        network = {
          mode = if networkMode == "none" then "disabled" else networkMode;
          egressAllow = config.network.egressAllow;
          hardPolicy.allowedDestinations = effectiveEgress;
        };
        secrets = map (
          slot:
          {
            inherit (slot) name;
            delivery = [ slot.delivery ];
          }
        ) config.secrets;
        resources.memory = {
          minimumBytes = memoryMinimum;
          maximumBytes = memoryMaximum;
        };
        targets = config.targets;
        requiredCapabilities = map (
          capability:
          if capability == "network.none" then "network.disabled" else capability
        ) requiredCapabilities;
        inherit runtimeProfiles;
        extensions = { };
      };

      builderManifest = {
        portableArtifact = portableValue;
        packageStorePaths = map (entry: entry.value.outPath) config.environment.packages;
      };
      builder = pkgs.writeText "structured-prototype-artifact-manifest.json" (
        builtins.toJSON builderManifest
      );

      manifest = {
        schemaVersion = 1;
        builderDrvPath = builder.drvPath;
        inherit builderManifest;
        profile = {
          selected = config.profile.selected;
          selectionIsVisible = true;
        };
        environment = {
          packages = map (
            entry:
            {
              name = lib.getName entry.value;
              storePath = entry.value.outPath;
              inherit (entry) source;
            }
          ) config.environment.packages;
          variables = config.environment.variables;
          activation = config.environment.activation;
        };
        workspace = {
          inherit
            access
            allowedMaterializations
            materialization
            ;
          destination = config.workspace.destination;
        };
        network = {
          mode = networkMode;
          egressAllow = config.network.egressAllow;
          hardPolicy.allowedDestinations = effectiveEgress;
        };
        secrets = config.secrets;
        resources.memory = {
          minimumBytes = memoryMinimum;
          maximumBytes = memoryMaximum;
        };
        targets = config.targets;
        inherit requiredCapabilities;
        inherit
          guest
          portableValue
          provenance
          runtimeProfiles
          ;
      };
    in
    ensure (!materializationConflict && !accessConflict && !networkConflict)
      "artifact.profile.explicit_conflict"
      "an explicit value contradicts the selected visible profile"
      (
        ensure (hasPrefix "/" config.workspace.destination) "artifact.mount.destination_absolute"
          "workspace destination must be absolute"
          (
            ensure (config.environment.activation != [ ]) "artifact.environment.activation_nonempty"
              "activation argv must not be empty"
              (
                ensure (networkMode != "none" || config.network.egressAllow == [ ])
                  "artifact.network.none_has_no_egress"
                  "network mode none cannot have an egress allowlist"
                  (
                    ensure policyDefinitionPriorityIsSupported
                      "artifact.policy.override_priority_forbidden"
                      "hard-policy definitions cannot use a priority stronger than an ordinary definition"
                      (
                        ensure policyIsMonotonic "artifact.policy.monotonic_refinement"
                          "a refinement contains destinations not permitted by its base"
                          (
                            ensure everyTargetSupportsRequirements
                              "artifact.target.required_capability_supported"
                              "one or more targets do not satisfy mandatory Artifact capabilities"
                              (
                                ensure (config.targets != [ ]) "artifact.target.at_least_one"
                                  "at least one target must remain"
                                  (
                                    ensure (memoryMinimum <= memoryMaximum)
                                      "artifact.resources.bounds_nonempty"
                                      "minimum memory exceeds maximum memory"
                                      (
                                        ensure packageReferencesResolve
                                          "artifact.nix.package_reference_matches_value"
                                          "native package value does not match its portable pinned reference"
                                          manifest
                                      )
                                  )
                              )
                          )
                      )
                  )
              )
          )
      );

  evaluateArtifact = evaluateArtifactWithSpecialArgs { };

  resolveCreation =
    artifact: creation:
    let
      runtimeProfile =
        artifact.runtimeProfiles.${creation.runtimeProfile}
          or (throw "create.runtime_profile_known: selected runtime profile is not in the Artifact");
      materializationSupported =
        elem creation.workspace.materialization runtimeProfile.materializations;
      memoryWithinBounds =
        creation.allocation.memoryBytes >= artifact.resources.memory.minimumBytes
        && creation.allocation.memoryBytes <= artifact.resources.memory.maximumBytes;
      result = {
        runtimeProfile = creation.runtimeProfile;
        workspace = creation.workspace;
        allocation = creation.allocation;
      };
    in
    ensure materializationSupported "create.runtime_profile_supports_binding"
      "selected runtime profile does not support the requested workspace materialization"
      (
        ensure memoryWithinBounds "create.allocation.within_artifact_bounds"
          "requested memory is outside Artifact bounds"
          result
      );
in
{
  inherit
    evaluateArtifact
    evaluateArtifactWithSpecialArgs
    resolveCreation
    ;
}
