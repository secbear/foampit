{
  lib,
  pkgs,
  prototype,
}:
let
  mib = 1024 * 1024;

  mkBaseModule =
    {
      destination ? "/workspace",
      materialization ? null,
      allowedMaterializations ? [ ],
      networkMode ? null,
      egressAllow ? [ ],
      profileSelected ? "workspace-edit-offline",
      packageSourceAttribute ? "hello",
      targets ? [
        "bubblewrap"
        "firecracker"
      ],
      baseAllowedDestinations ? [ ],
      nativeGuestModules ? [ ],
    }:
    {
      _file = "fixture:base";
      config = {
        profile.selected = profileSelected;
        environment = {
          packages = [
            {
              value = pkgs.hello;
              source = {
                kind = "nixInput";
                input = "nixpkgs";
                attribute = packageSourceAttribute;
              };
            }
          ];
          variables.EDITOR = "vi";
          activation = [ "bash" ];
        };
        workspace = {
          inherit
            allowedMaterializations
            destination
            materialization
            ;
        };
        network = {
          mode = networkMode;
          inherit egressAllow;
          policyDefinitions = [
            {
              role = "base";
              allowedDestinations = baseAllowedDestinations;
              source = "fixture:base";
            }
          ];
        };
        secrets = [
          {
            name = "agent-api-token";
            delivery = "environment";
          }
        ];
        resources.memory = {
          minimumBytes = 512 * mib;
          maximumBytes = 4096 * mib;
        };
        inherit
          nativeGuestModules
          targets
          ;
      };
    };

  refinementModule = {
    _file = "fixture:refinement";
    config.resources.memory = {
      minimumBytes = 1024 * mib;
      maximumBytes = 2048 * mib;
    };
  };

  validMinimal = prototype.evaluateArtifact [
    (mkBaseModule { })
  ];

  validFlexibleWorkspace = prototype.evaluateArtifact [
    (mkBaseModule {
      allowedMaterializations = [
        "copy"
        "live"
      ];
    })
  ];

  policyBaseModule = mkBaseModule {
    profileSelected = "workspace-live-development";
    egressAllow = [ "api.example.test" ];
    targets = [ "bubblewrap" ];
    baseAllowedDestinations = [
      "api.example.test"
      "docs.example.test"
    ];
  };

  policyRefinementModule = {
    _file = "fixture:policy-refinement";
    config.network.policyDefinitions = [
      {
        role = "refinement";
        allowedDestinations = [ "api.example.test" ];
        source = "fixture:policy-refinement";
      }
    ];
  };

  specialArgImportModule =
    { importedPolicyModule, ... }:
    {
      _file = "fixture:special-arg-import";
      imports = [ importedPolicyModule ];
    };
in
{
  inherit validMinimal;

  validRefinement = prototype.evaluateArtifact [
    (mkBaseModule { })
    refinementModule
  ];

  validPolicyRefinementForward = prototype.evaluateArtifact [
    policyBaseModule
    policyRefinementModule
  ];

  validPolicyRefinementReverse = prototype.evaluateArtifact [
    policyRefinementModule
    policyBaseModule
  ];

  validDefaultLosesToExplicitSelection = prototype.evaluateArtifact [
    (mkBaseModule { })
    (
      { lib, ... }:
      {
        _file = "fixture:mk-default-selection";
        config.profile.selected = lib.mkDefault "workspace-live-development";
      }
    )
  ];

  validOrderedActivation = prototype.evaluateArtifact [
    (mkBaseModule { })
    (
      { lib, ... }:
      {
        _file = "fixture:activation-before";
        config.environment.activation = lib.mkBefore [ "prepare" ];
      }
    )
    (
      { lib, ... }:
      {
        _file = "fixture:activation-after";
        config.environment.activation = lib.mkAfter [ "finish" ];
      }
    )
  ];

  validDynamicVariable = prototype.evaluateArtifact [
    (mkBaseModule { })
    {
      _file = "fixture:dynamic-variable";
      config.environment.variables."PLUGIN__DYNAMIC_KEY" = "accepted";
    }
  ];

  validRawGuestDataHasNoHostAuthority = prototype.evaluateArtifact [
    (mkBaseModule {
      nativeGuestModules = [
        {
          _file = "fixture:guest-raw-service";
          config.guest.services.worker = {
            command = [ "worker" ];
            host.shares = [ "/not-a-host-claim" ];
          };
        }
      ];
    })
  ];

  validModuleArgsContribution = prototype.evaluateArtifact [
    (mkBaseModule { })
    {
      _file = "fixture:module-args-provider";
      config._module.args.fixtureVariable = "from-module-args";
    }
    (
      { fixtureVariable, ... }:
      {
        _file = "fixture:module-args-consumer";
        config.environment.variables.MODULE_ARG = fixtureVariable;
      }
    )
  ];

  validSpecialArgsImport = prototype.evaluateArtifactWithSpecialArgs
    {
      importedPolicyModule = policyRefinementModule;
    }
    [
      policyBaseModule
      specialArgImportModule
    ];

  validLazyUnusedModuleArgument = prototype.evaluateArtifact [
    (mkBaseModule { })
    {
      _file = "fixture:lazy-unused-module-argument";
      config._module.args.unusedFailure = throw "D-NIX-LAZY-UNUSED-MODULE-ARGUMENT";
    }
  ];

  validFirecrackerCopyCreation = prototype.resolveCreation validFlexibleWorkspace {
    runtimeProfile = "firecracker-copy";
    workspace.materialization = "copy";
    allocation.memoryBytes = 1024 * mib;
  };

  invalidRelativeMount = prototype.evaluateArtifact [
    (mkBaseModule { destination = "workspace"; })
  ];

  invalidNoneWithEgress = prototype.evaluateArtifact [
    (mkBaseModule { egressAllow = [ "api.example.test" ]; })
  ];

  invalidFirecrackerOnlyLive = prototype.evaluateArtifact [
    (mkBaseModule {
      profileSelected = "workspace-live-development";
      targets = [ "firecracker" ];
    })
  ];

  invalidFirecrackerLiveCreation = prototype.resolveCreation validFlexibleWorkspace {
    runtimeProfile = "firecracker-copy";
    workspace.materialization = "live";
    allocation.memoryBytes = 1024 * mib;
  };

  invalidHardPolicyWeakening = prototype.evaluateArtifact [
    (mkBaseModule { })
    {
      _file = "fixture:weakening";
      config.network.policyDefinitions = [
        {
          role = "refinement";
          allowedDestinations = [ "api.example.test" ];
          source = "fixture:weakening";
        }
      ];
    }
  ];

  invalidPackageReferenceMismatch = prototype.evaluateArtifact [
    (mkBaseModule { packageSourceAttribute = "bash"; })
  ];

  invalidProfileConflict = prototype.evaluateArtifact [
    (mkBaseModule { materialization = "live"; })
  ];

  invalidGuestHostShare = prototype.evaluateArtifact [
    (mkBaseModule {
      nativeGuestModules = [
        {
          _file = "fixture:guest-host-share";
          config.host.shares = [ "/host/workspace" ];
        }
      ];
    })
  ];

  invalidUndeclaredOption = prototype.evaluateArtifact [
    (mkBaseModule { })
    {
      _file = "fixture:undeclared-option";
      config.workspace.materalization = "copy";
    }
  ];

  invalidModuleArgsPolicyBypass = prototype.evaluateArtifact [
    (mkBaseModule { })
    {
      _file = "fixture:module-args-policy-provider";
      config._module.args.attemptedDestinations = [ "api.example.test" ];
    }
    (
      { attemptedDestinations, ... }:
      {
        _file = "fixture:module-args-policy-consumer";
        config.network.policyDefinitions = [
          {
            role = "refinement";
            allowedDestinations = attemptedDestinations;
            source = "fixture:module-args-policy-consumer";
          }
        ];
      }
    )
  ];

  invalidSpecialArgsImportBypass = prototype.evaluateArtifactWithSpecialArgs
    {
      importedPolicyModule = {
        _file = "fixture:special-args-weakening";
        config.network.policyDefinitions = [
          {
            role = "refinement";
            allowedDestinations = [ "api.example.test" ];
            source = "fixture:special-args-weakening";
          }
        ];
      };
    }
    [
      (mkBaseModule { })
      specialArgImportModule
    ];

  invalidLazyFinalValue = prototype.evaluateArtifact [
    (mkBaseModule { })
    {
      _file = "fixture:lazy-final-value";
      config.environment.variables.REQUIRED =
        throw "artifact.final_value_deep_forced: required rendered values cannot remain lazy";
    }
  ];

  invalidForcedProfileBypass = prototype.evaluateArtifact [
    (mkBaseModule { })
    (
      { lib, ... }:
      {
        _file = "fixture:mk-force-bypass";
        config.workspace.materialization = lib.mkForce "live";
      }
    )
  ];

  invalidStrongerThanForcePolicyBypass = prototype.evaluateArtifact [
    (mkBaseModule { })
    (
      { lib, ... }:
      {
        _file = "fixture:stronger-than-mk-force-policy-bypass";
        config.network.policyDefinitions = lib.mkOverride (-1) [
          {
            role = "base";
            allowedDestinations = [ "api.example.test" ];
            source = "fixture:forged-replacement-base";
          }
        ];
      }
    )
  ];

  invalidCreationBelowMinimum = prototype.resolveCreation validFlexibleWorkspace {
    runtimeProfile = "firecracker-copy";
    workspace.materialization = "copy";
    allocation.memoryBytes = 256 * mib;
  };
}
