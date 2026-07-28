{
  compositionRegistry,
  lib,
  productDependency,
  productNativeExtensionSummaries ? [ ],
}:
let
  inherit (lib)
    all
    attrByPath
    filter
    foldl'
    groupBy
    hasPrefix
    mkOption
    sort
    splitString
    types
    unique
    ;

  ensure =
    condition: invariant: detail: value:
    if condition then value else throw "${invariant}: ${detail}";

  nonNegativeInt = types.addCheck types.int (value: value >= 0);

  minimumDefinitionType = types.mkOptionType {
    name = "semantic minimum of non-negative integer definitions";
    description = "a desired-state limit narrowed by every surviving definition";
    check = nonNegativeInt.check;
    merge =
      location: definitions:
      if definitions == [ ] then
        throw "service.ms0.lifecycle_limit_required: ${lib.showOption location}"
      else
        foldl' lib.min (builtins.head definitions).value (
          map (definition: definition.value) (builtins.tail definitions)
        );
  };

  maximumDefinitionType = types.mkOptionType {
    name = "semantic maximum of non-negative integer definitions";
    description = "a reconciliation interval narrowed by every surviving definition";
    check = nonNegativeInt.check;
    merge =
      location: definitions:
      if definitions == [ ] then
        throw "service.ms0.reconcile_interval_required: ${lib.showOption location}"
      else
        foldl' lib.max (builtins.head definitions).value (
          map (definition: definition.value) (builtins.tail definitions)
        );
  };

  sourceIdentityType = types.submodule {
    options = {
      kind = mkOption {
        type = types.enum [ "flake" ];
      };
      locator = mkOption {
        type = types.str;
      };
      revision = mkOption {
        type = types.str;
      };
      narHash = mkOption {
        type = types.str;
      };
    };
    config._module.check = true;
  };

  dependencyType = types.submodule {
    options = {
      name = mkOption {
        type = types.str;
      };
      closurePath = mkOption {
        type = types.str;
      };
      sourceIdentity = mkOption {
        type = sourceIdentityType;
      };
    };
    config._module.check = true;
  };

  moduleIdentityType = types.submodule {
    options = {
      id = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      file = mkOption {
        type = types.str;
      };
      narHash = mkOption {
        type = types.str;
      };
    };
    config._module.check = true;
  };

  contributorType = types.submodule {
    options = {
      id = mkOption {
        type = types.strMatching "[A-Za-z][A-Za-z0-9_.-]*";
      };
      moduleIdentity = mkOption {
        type = moduleIdentityType;
      };
      definitionIndex = mkOption {
        type = nonNegativeInt;
      };
      optionPath = mkOption {
        type = types.str;
      };
      role = mkOption {
        type = types.enum [
          "contribution"
          "default"
          "selection"
          "refinement"
          "override"
          "import"
        ];
      };
      priority = mkOption {
        type = types.int;
      };
      definitionOrder = mkOption {
        type = types.int;
      };
      outcome = mkOption {
        type = types.enum [
          "effective"
          "superseded"
          "narrowed"
        ];
      };
      valueDigest = mkOption {
        type = types.str;
      };
      dependency = mkOption {
        type = types.nullOr dependencyType;
        default = null;
      };
    };
    config._module.check = true;
  };

  nativeExtensionSummaryType = types.submodule {
    options = {
      name = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      interfaceVersion = mkOption {
        type = nonNegativeInt;
      };
      sourceIdentity = mkOption {
        type = sourceIdentityType;
      };
    };
    config._module.check = true;
  };

  nativeExtensionSummarySchema =
    { ... }:
    {
      options.nativeExtensionSummaries = mkOption {
        type = types.listOf nativeExtensionSummaryType;
      };
      config._module.check = true;
    };

  canonicalNativeExtensionSummary =
    summary:
    {
      inherit (summary)
        interfaceVersion
        name
        ;
      sourceIdentity = {
        inherit (summary.sourceIdentity)
          kind
          locator
          narHash
          revision
          ;
      };
    };

  serviceOptionPaths = [
    [
      "artifactReference"
      "artifactId"
    ]
    [
      "artifactReference"
      "semanticDigest"
    ]
    [
      "artifactReference"
      "member"
    ]
    [
      "createRequest"
      "operation"
      "kind"
    ]
    [
      "createRequest"
      "operation"
      "api"
    ]
    [
      "createRequest"
      "operation"
      "schemaVersion"
    ]
    [
      "createRequest"
      "runtimeProfile"
    ]
    [
      "createRequest"
      "workspace"
      "materialization"
    ]
    [
      "createRequest"
      "allocation"
      "memoryBytes"
    ]
    [
      "desiredLifecycle"
      "state"
    ]
    [
      "desiredLifecycle"
      "restartPolicy"
    ]
    [
      "desiredLifecycle"
      "maxRestarts"
    ]
    [
      "desiredLifecycle"
      "reconcileIntervalSeconds"
    ]
    [
      "serviceMetadata"
      "name"
    ]
    [
      "serviceMetadata"
      "namespace"
    ]
    [
      "serviceMetadata"
      "owner"
    ]
    [
      "serviceMetadata"
      "description"
    ]
    [ "contributorLedger" ]
  ];

  pathIsPrefix =
    prefix: path:
    builtins.length prefix <= builtins.length path
    && lib.take (builtins.length prefix) path == prefix;

  allowedChildren =
    optionPaths: currentPath:
    unique (
      map (
        path: builtins.elemAt path (builtins.length currentPath)
      ) (
        filter (
          path:
          pathIsPrefix currentPath path
          && builtins.length path > builtins.length currentPath
        ) optionPaths
      )
    );

  configSurfaceValid =
    optionPaths: allowUnknownRoot: currentPath: config:
    if builtins.elem currentPath optionPaths then
      true
    else
      let
        keyNamesAttempt = builtins.tryEval (builtins.attrNames config);
      in
      keyNamesAttempt.success
      && all (
        key:
        if currentPath == [ ] && key == "_module" then
          true
        else
          let
            nextPath = currentPath ++ [ key ];
            childAllowed =
              builtins.elem key (allowedChildren optionPaths currentPath);
          in
          (allowUnknownRoot && currentPath == [ ] && !childAllowed)
          || (
            childAllowed
            && (
              builtins.elem nextPath optionPaths
              || configSurfaceValid optionPaths allowUnknownRoot nextPath (
                builtins.getAttr key config
              )
            )
          )
      ) keyNamesAttempt.value;

  moduleSurfaceValid =
    optionPaths: module:
    let
      loadedAttempt = builtins.tryEval (
        if builtins.isPath module then import module else module
      );
      instantiatedAttempt =
        if !loadedAttempt.success then
          {
            success = false;
            value = false;
          }
        else
          builtins.tryEval (
            if builtins.isFunction loadedAttempt.value then
              loadedAttempt.value (
                builtins.mapAttrs (
                  name: _:
                  if name == "lib" then
                    lib
                  else
                    throw "structural preflight module argument was forced"
                ) (builtins.functionArgs loadedAttempt.value)
              )
            else
              loadedAttempt.value
          );
    in
    instantiatedAttempt.success
    && builtins.isAttrs instantiatedAttempt.value
    && (
      let
        moduleValue = instantiatedAttempt.value;
        moduleKeysAttempt = builtins.tryEval (builtins.attrNames moduleValue);
        importsAttempt = builtins.tryEval (moduleValue.imports or [ ]);
        configAttempt = builtins.tryEval (moduleValue.config or { });
        allowedModuleKeys = [
          "_class"
          "_file"
          "config"
          "disabledModules"
          "imports"
          "key"
          "meta"
          "options"
        ];
        freeformSurfaceAttempt =
          if !configAttempt.success || !builtins.isAttrs configAttempt.value then
            {
              success = false;
              value = false;
            }
          else
            builtins.tryEval (
              builtins.elem "_module" (builtins.attrNames configAttempt.value)
              && builtins.isAttrs configAttempt.value._module
              && builtins.elem "freeformType" (
                builtins.attrNames configAttempt.value._module
              )
            );
        allowUnknownRoot =
          freeformSurfaceAttempt.success && freeformSurfaceAttempt.value;
      in
      moduleKeysAttempt.success
      && all (key: builtins.elem key allowedModuleKeys) moduleKeysAttempt.value
      && importsAttempt.success
      && builtins.isList importsAttempt.value
      && all (moduleSurfaceValid optionPaths) importsAttempt.value
      && configAttempt.success
      && builtins.isAttrs configAttempt.value
      && configSurfaceValid optionPaths allowUnknownRoot [ ] configAttempt.value
    );

  serviceSchema =
    { ... }:
    {
      options = {
        artifactReference.artifactId = mkOption {
          type = types.strMatching "[a-z][a-z0-9-]*";
        };
        artifactReference.semanticDigest = mkOption {
          type = types.str;
        };
        artifactReference.member = mkOption {
          type = types.strMatching "[a-z][a-z0-9-]*";
        };
        createRequest.operation.kind = mkOption {
          type = types.enum [
            "createSandbox"
            "driverCall"
            "rawRuntimeArguments"
            "artifactPolicyMutation"
          ];
        };
        createRequest.operation.api = mkOption {
          type = types.str;
        };
        createRequest.operation.schemaVersion = mkOption {
          type = nonNegativeInt;
        };
        createRequest.runtimeProfile = mkOption {
          type = types.strMatching "[a-z][a-z0-9-]*";
        };
        createRequest.workspace.materialization = mkOption {
          type = types.enum [
            "copy"
            "live"
          ];
        };
        createRequest.allocation.memoryBytes = mkOption {
          type = nonNegativeInt;
        };
        desiredLifecycle.state = mkOption {
          type = types.enum [
            "active"
            "suspended"
            "deleted"
          ];
        };
        desiredLifecycle.restartPolicy = mkOption {
          type = types.enum [
            "always"
            "on-failure"
            "never"
          ];
        };
        desiredLifecycle.maxRestarts = mkOption {
          type = minimumDefinitionType;
        };
        desiredLifecycle.reconcileIntervalSeconds = mkOption {
          type = maximumDefinitionType;
        };
        serviceMetadata.name = mkOption {
          type = types.strMatching "[a-z][a-z0-9-]*";
        };
        serviceMetadata.namespace = mkOption {
          type = types.strMatching "[a-z][a-z0-9-]*";
        };
        serviceMetadata.owner = mkOption {
          type = types.str;
        };
        serviceMetadata.description = mkOption {
          type = types.str;
        };
        contributorLedger = mkOption {
          type = types.listOf contributorType;
        };
      };
      config._module.check = true;
    };

  sriSha256IsWellFormed =
    hash:
    builtins.match "sha256-[A-Za-z0-9+/]{43}=" hash != null
    && builtins.convertHash {
      hashAlgo = "sha256";
      inherit hash;
      toHashFormat = "sri";
    } == hash;

  revisionIsWellFormed =
    revision:
    builtins.stringLength revision == 40
    && builtins.match "[0-9a-f]{40}" revision != null;

  valueDigest =
    value:
    builtins.convertHash {
      hashAlgo = "sha256";
      hash = builtins.hashString "sha256" (builtins.toJSON value);
      toHashFormat = "sri";
    };

  sortedStrings = values: sort builtins.lessThan values;

  build =
    {
      compositionId,
      reverse ? false,
    }:
    let
      descriptor =
        compositionRegistry.${compositionId}
          or (throw "service.ms0.unknown_product_composition: unregistered composition");
      orderedModules =
        if reverse then lib.reverseList descriptor.modules else descriptor.modules;
      structuralPreflightAttempt = builtins.tryEval (
        all (moduleSurfaceValid serviceOptionPaths) orderedModules
      );
      structuralPreflight =
        ensure (
          structuralPreflightAttempt.success && structuralPreflightAttempt.value
        )
          "SVC-005"
          "Managed-Service Definition source declares an unknown option path"
          true;
      expectedLedger = descriptor.contributionManifest;
      ledgerInjector = {
        _file = "product:service-contributor-ledger";
        config.contributorLedger = expectedLedger;
      };
      evaluated = builtins.seq structuralPreflight (
        lib.evalModules {
          modules = [ serviceSchema ] ++ orderedModules ++ [ ledgerInjector ];
        }
      );
      config = evaluated.config;

      nativeExtensionSummaryEvaluation = builtins.tryEval (
        let
          summaryEvaluation = lib.evalModules {
            modules = [
              nativeExtensionSummarySchema
              {
                _file = "product:service-native-extension-summaries";
                config.nativeExtensionSummaries = productNativeExtensionSummaries;
              }
            ];
          };
        in
        builtins.deepSeq summaryEvaluation.config.nativeExtensionSummaries (
          map canonicalNativeExtensionSummary summaryEvaluation.config.nativeExtensionSummaries
        )
      );
      validatedNativeExtensionSummaries =
        ensure nativeExtensionSummaryEvaluation.success
          "service.ms0.product_native_extension_summary_invalid"
          "product native-extension summaries must match the exact closed typed summary schema"
          nativeExtensionSummaryEvaluation.value;

      expectedIds = map (entry: entry.id) expectedLedger;
      expectedIndexes = builtins.genList (index: index) (builtins.length expectedLedger);
      manifestShapeValid =
        builtins.length expectedIds == builtins.length (unique expectedIds)
        && map (entry: entry.definitionIndex) expectedLedger == expectedIndexes
        && all (
          entry:
          sriSha256IsWellFormed entry.moduleIdentity.narHash
          && sriSha256IsWellFormed entry.valueDigest
        ) expectedLedger;
      ledgerComplete =
        config.contributorLedger == expectedLedger
        && builtins.length (map (entry: entry.id) config.contributorLedger)
        == builtins.length (unique (map (entry: entry.id) config.contributorLedger));

      checkedDefinitions = filter (entry: entry.checkDefinition) descriptor.definitionChecks;
      definitionGroups = groupBy (
        entry: entry.public.optionPath
      ) checkedDefinitions;
      definitionGroupValid =
        optionPath: entries:
        let
          option = attrByPath (splitString "." optionPath) null evaluated.options;
          minimumPriority = foldl' lib.min 1000000 (
            map (entry: entry.public.priority) entries
          );
          expectedSurvivors = filter (
            entry: entry.public.priority == minimumPriority
          ) entries;
          actualDefinitions =
            if option == null then [ ] else option.definitionsWithLocations;
          expectedFiles = sortedStrings (
            map (entry: entry.public.moduleIdentity.file) expectedSurvivors
          );
          actualFiles = sortedStrings (
            map (definition: definition.file) actualDefinitions
          );
          skipValueCheck = builtins.any (entry: entry.skipValueCheck) expectedSurvivors;
          expectedDigests = sortedStrings (
            map (entry: entry.public.valueDigest) expectedSurvivors
          );
          actualDigests =
            if skipValueCheck then
              [ ]
            else
              sortedStrings (map (definition: valueDigest definition.value) actualDefinitions);
        in
        option != null
        && option.highestPrio == minimumPriority
        && builtins.length actualDefinitions == builtins.length expectedSurvivors
        && actualFiles == expectedFiles
        && (skipValueCheck || actualDigests == expectedDigests);
      definitionsMatchManifest = all (
        optionPath: definitionGroupValid optionPath definitionGroups.${optionPath}
      ) (builtins.attrNames definitionGroups);

      ledgerDependencies = map (entry: entry.dependency) (
        filter (entry: entry.dependency != null) config.contributorLedger
      );
      dependencyHashesWellFormed =
        all (
          dependency: sriSha256IsWellFormed dependency.sourceIdentity.narHash
        ) ledgerDependencies;
      dependencyRecordsComplete =
        builtins.length ledgerDependencies == 1
        && all (
          dependency:
          dependency.name != ""
          && dependency.closurePath != ""
          && hasPrefix "/nix/store/" dependency.closurePath
          && dependency.sourceIdentity.kind == "flake"
          && hasPrefix "github:" dependency.sourceIdentity.locator
          && revisionIsWellFormed dependency.sourceIdentity.revision
        ) ledgerDependencies;
      dependenciesMatchProduct =
        dependencyRecordsComplete
        && builtins.head ledgerDependencies == productDependency;

      publicOptionNames = [
        "artifactReference"
        "contributorLedger"
        "createRequest"
        "desiredLifecycle"
        "serviceMetadata"
      ];
      configRootNames = builtins.attrNames config;
      operation = config.createRequest.operation;
      operationPrioritySupported =
        evaluated.options.createRequest.operation.kind.highestPrio >= 100
        && evaluated.options.createRequest.operation.api.highestPrio >= 100
        && evaluated.options.createRequest.operation.schemaVersion.highestPrio >= 100;
      isDriverCall = operation.kind == "driverCall";
      isRawRuntimeArguments = operation.kind == "rawRuntimeArguments";
      isArtifactPolicyMutation = operation.kind == "artifactPolicyMutation";
      isNativeEscape =
        hasPrefix "native://" operation.api
        || hasPrefix "freeform://" operation.api;
      isTypedCoreApi =
        operation.kind == "createSandbox"
        && operation.api == "core.sandbox"
        && operation.schemaVersion == 1;

      resource = {
        inherit (config)
          artifactReference
          contributorLedger
          createRequest
          desiredLifecycle
          serviceMetadata
          ;
      };
      normalized = {
        phase = "MS0";
        inherit resource;
        validationMetadata = {
          contributionManifest = expectedLedger;
          dependencyClosure = [ productDependency ];
          nativeExtensionSummaries = validatedNativeExtensionSummaries;
          offlineReproducible = true;
        };
      };

      ledgerValidation = builtins.deepSeq config.contributorLedger (
        ensure manifestShapeValid
          "service.ms0.product_contribution_manifest_invalid"
          "the product contribution manifest must have canonical unique identities, indexes, and SRI digests"
          (
            ensure ledgerComplete
              "service.ms0.contributor_ledger_incomplete"
              "the contributor ledger must exactly cover product-registered definitions"
              true
          )
      );

      validated = builtins.seq ledgerValidation (
        ensure definitionsMatchManifest
          "service.ms0.contributor_manifest_definition_mismatch"
          "registered definition values, priorities, order, or source identities do not match evaluation"
          (
            ensure (configRootNames == publicOptionNames)
              "service.ms0.native_escape_forbidden"
              "freeform configuration cannot add public Managed-Service Definition fields"
              (
                ensure (!isNativeEscape)
                  "service.ms0.native_escape_forbidden"
                  "native evaluator values cannot construct a validated Managed-Service Definition"
                  (
                    ensure operationPrioritySupported
                      "service.ms0.operation_priority_forbidden"
                      "typed Core API intent cannot use a force-class winning priority"
                      (
                        ensure (!isDriverCall)
                          "service.ms0.driver_call_forbidden"
                          "Managed-Service Definitions cannot call drivers"
                          (
                            ensure (!isRawRuntimeArguments)
                              "service.ms0.raw_runtime_arguments_forbidden"
                              "Managed-Service Definitions cannot provide raw runtime arguments"
                              (
                                ensure (!isArtifactPolicyMutation)
                                  "service.ms0.artifact_policy_forbidden"
                                  "Managed-Service Definitions cannot author Artifact policy"
                                  (
                                    ensure isTypedCoreApi
                                      "service.ms0.typed_core_api_required"
                                      "service intent must use the versioned typed Core Sandbox API"
                                      (
                                        ensure dependencyHashesWellFormed
                                          "service.ms0.dependency_identity_malformed"
                                          "dependency hashes must use a full SRI sha256 encoding"
                                          (
                                            ensure dependencyRecordsComplete
                                              "service.ms0.dependency_identity_incomplete"
                                              "every dependency must have a complete immutable source and closure identity"
                                              (
                                                ensure dependenciesMatchProduct
                                                  "service.ms0.dependency_identity_mismatch"
                                                  "dependency identity must match product-derived locked flake and closure evidence"
                                                  normalized
                                              )
                                          )
                                      )
                                  )
                              )
                          )
                      )
                  )
              )
          )
      );
    in
    {
      inherit
        normalized
        validated
        ;
    };
in
{
  publicOptionNames = [
    "artifactReference"
    "createRequest"
    "desiredLifecycle"
    "serviceMetadata"
    "contributorLedger"
  ];

  evaluate =
    arguments:
    let
      result = build arguments;
    in
    builtins.deepSeq result.validated result.validated;

  evaluateForceBoundaryProbe =
    arguments:
    let
      result = build arguments;
      shallow = builtins.tryEval result.normalized;
      forced = builtins.tryEval (builtins.deepSeq result.normalized true);
    in
    {
      phase = "MS0-candidate";
      shallowEvaluationSucceeded = shallow.success;
      explicitDeepForceSucceeded = forced.success;
    };
}
