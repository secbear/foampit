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
    elem
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
    description = "a hard ceiling narrowed by every surviving definition";
    check = nonNegativeInt.check;
    merge =
      location: definitions:
      if definitions == [ ] then
        throw "operator.oc0.hard_ceiling_required: ${lib.showOption location}"
      else
        foldl' lib.min (builtins.head definitions).value (
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

  driverType = types.submodule {
    options = {
      name = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      runtimeProfile = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      implementationBundle = mkOption {
        type = types.str;
      };
      protocolVersion = mkOption {
        type = nonNegativeInt;
      };
    };
    config._module.check = true;
  };

  providerType = types.submodule {
    options = {
      name = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      driver = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      region = mkOption {
        type = types.str;
      };
    };
    config._module.check = true;
  };

  placementClassType = types.submodule {
    options = {
      name = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      driver = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      provider = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      maxMemoryBytes = mkOption {
        type = nonNegativeInt;
      };
    };
    config._module.check = true;
  };

  credentialReferenceType = types.submodule {
    options = {
      name = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      provider = mkOption {
        type = types.strMatching "[a-z][a-z0-9-]*";
      };
      kind = mkOption {
        type = types.enum [
          "keychainHandle"
          "environmentHandle"
        ];
      };
      reference = mkOption {
        type = types.str;
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

  operatorOptionPaths = [
    [ "drivers" ]
    [ "providers" ]
    [ "placementClasses" ]
    [
      "hardCeilings"
      "maxMemoryBytes"
    ]
    [
      "hardCeilings"
      "maxSandboxes"
    ]
    [ "credentialReferences" ]
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

  operatorSchema =
    { ... }:
    {
      options = {
        drivers = mkOption {
          type = types.listOf driverType;
        };
        providers = mkOption {
          type = types.listOf providerType;
        };
        placementClasses = mkOption {
          type = types.listOf placementClassType;
        };
        hardCeilings.maxMemoryBytes = mkOption {
          type = minimumDefinitionType;
        };
        hardCeilings.maxSandboxes = mkOption {
          type = minimumDefinitionType;
        };
        credentialReferences = mkOption {
          type = types.listOf credentialReferenceType;
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
          or (throw "operator.oc0.unknown_product_composition: unregistered composition");
      orderedModules =
        if reverse then lib.reverseList descriptor.modules else descriptor.modules;
      structuralPreflightAttempt = builtins.tryEval (
        all (moduleSurfaceValid operatorOptionPaths) orderedModules
      );
      structuralPreflight =
        ensure (
          structuralPreflightAttempt.success && structuralPreflightAttempt.value
        )
          "OPS-005"
          "Operator Configuration source declares an unknown option path"
          true;
      expectedLedger = descriptor.contributionManifest;
      ledgerInjector = {
        _file = "product:operator-contributor-ledger";
        config.contributorLedger = expectedLedger;
      };
      evaluated = builtins.seq structuralPreflight (
        lib.evalModules {
          modules = [ operatorSchema ] ++ orderedModules ++ [ ledgerInjector ];
        }
      );
      config = evaluated.config;

      nativeExtensionSummaryEvaluation = builtins.tryEval (
        let
          summaryEvaluation = lib.evalModules {
            modules = [
              nativeExtensionSummarySchema
              {
                _file = "product:operator-native-extension-summaries";
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
          "operator.oc0.product_native_extension_summary_invalid"
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
        "contributorLedger"
        "credentialReferences"
        "drivers"
        "hardCeilings"
        "placementClasses"
        "providers"
      ];
      configRootNames = builtins.attrNames config;
      driverNames = unique (map (driver: driver.name) config.drivers);
      providerNames = unique (map (provider: provider.name) config.providers);
      registeredSelections =
        all (provider: elem provider.driver driverNames) config.providers
        && all (
          placement:
          elem placement.driver driverNames
          && elem placement.provider providerNames
        ) config.placementClasses
        && all (
          credential: elem credential.provider providerNames
        ) config.credentialReferences;
      referencesAreOpaque =
        all (
          credential:
          hasPrefix "keychain://" credential.reference
          || hasPrefix "env-handle://" credential.reference
        ) config.credentialReferences;
      nativeEscapeReferencePresent =
        builtins.any (
          credential:
          hasPrefix "native://" credential.reference
          || hasPrefix "freeform://" credential.reference
        ) config.credentialReferences;

      productAnchors = {
        maxMemoryBytes = 8 * 1024 * 1024 * 1024;
        maxSandboxes = 32;
      };
      ceilingPrioritySupported =
        evaluated.options.hardCeilings.maxMemoryBytes.highestPrio >= 100
        && evaluated.options.hardCeilings.maxSandboxes.highestPrio >= 100;
      ceilingsNarrowAnchors =
        config.hardCeilings.maxMemoryBytes <= productAnchors.maxMemoryBytes
        && config.hardCeilings.maxSandboxes <= productAnchors.maxSandboxes;

      resource = {
        inherit (config)
          contributorLedger
          credentialReferences
          drivers
          hardCeilings
          placementClasses
          providers
          ;
      };
      normalized = {
        phase = "OC0";
        inherit resource;
        validationMetadata = {
          contributionManifest = expectedLedger;
          dependencyClosure = [ productDependency ];
          nativeExtensionSummaries = validatedNativeExtensionSummaries;
          offlineReproducible = true;
          inherit productAnchors;
        };
      };

      ledgerValidation = builtins.deepSeq config.contributorLedger (
        ensure manifestShapeValid
          "operator.oc0.product_contribution_manifest_invalid"
          "the product contribution manifest must have canonical unique identities, indexes, and SRI digests"
          (
            ensure ledgerComplete
              "operator.oc0.contributor_ledger_incomplete"
              "the contributor ledger must exactly cover product-registered definitions"
              true
          )
      );

      validated = builtins.seq ledgerValidation (
        ensure definitionsMatchManifest
          "operator.oc0.contributor_manifest_definition_mismatch"
          "registered definition values, priorities, order, or source identities do not match evaluation"
          (
            ensure (configRootNames == publicOptionNames)
              "operator.oc0.native_escape_forbidden"
              "freeform configuration cannot add public Operator Configuration fields"
              (
                ensure (!nativeEscapeReferencePresent)
                  "operator.oc0.native_escape_forbidden"
                  "native evaluator values cannot construct validated Operator Configuration"
                  (
                    ensure referencesAreOpaque
                      "operator.oc0.credential_values_forbidden"
                      "credentials must remain opaque references; values are never accepted"
                      (
                        ensure ceilingPrioritySupported
                          "operator.oc0.hard_ceiling_priority_forbidden"
                          "hard ceilings cannot use a force-class winning priority"
                          (
                            ensure ceilingsNarrowAnchors
                              "operator.oc0.hard_ceiling_widening"
                              "composed hard ceilings must narrow product-owned anchors"
                              (
                                ensure registeredSelections
                                  "operator.oc0.unregistered_selection"
                                  "drivers, providers, placements, and credentials must select registered identities"
                                  (
                                    ensure dependencyHashesWellFormed
                                      "operator.oc0.dependency_identity_malformed"
                                      "dependency hashes must use a full SRI sha256 encoding"
                                      (
                                        ensure dependencyRecordsComplete
                                          "operator.oc0.dependency_identity_incomplete"
                                          "every dependency must have a complete immutable source and closure identity"
                                          (
                                            ensure dependenciesMatchProduct
                                              "operator.oc0.dependency_identity_mismatch"
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
    "drivers"
    "providers"
    "placementClasses"
    "hardCeilings"
    "credentialReferences"
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
      phase = "OC0-candidate";
      shallowEvaluationSucceeded = shallow.success;
      explicitDeepForceSucceeded = forced.success;
    };
}
