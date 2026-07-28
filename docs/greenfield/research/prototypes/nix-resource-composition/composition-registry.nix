{
  lib,
  productDependency,
}:
let
  inherit (lib)
    concatMap
    imap0
    mkAfter
    mkDefault
    mkForce
    mkOverride
    ;

  toSri =
    hex:
    builtins.convertHash {
      hashAlgo = "sha256";
      hash = hex;
      toHashFormat = "sri";
    };

  valueDigest =
    value: toSri (builtins.hashString "sha256" (builtins.toJSON value));

  registrySource = ./composition-registry.nix;
  operatorImportSource = ./operator-import.nix;
  operatorOverlaySource = ./operator-overlay.nix;
  serviceImportSource = ./service-import.nix;
  serviceOverlaySource = ./service-overlay.nix;

  mkModuleIdentity =
    {
      id,
      file,
      sourcePath ? registrySource,
    }:
    {
      inherit
        file
        id
        ;
      narHash = toSri (builtins.hashFile "sha256" sourcePath);
    };

  mkModuleRecord =
    {
      id,
      file,
      module,
      definitions,
      sourcePath ? registrySource,
    }:
    let
      moduleIdentity = mkModuleIdentity {
        inherit
          file
          id
          sourcePath
          ;
      };
    in
    {
      inherit
        definitions
        module
        moduleIdentity
        ;
    };

  enrichDefinition =
    moduleIdentity: definition:
    {
      inherit moduleIdentity;
      checkDefinition = definition.checkDefinition or true;
      skipValueCheck = definition.skipValueCheck or false;
      public = {
        dependency = definition.dependency or null;
        definitionOrder = definition.definitionOrder or 1000;
        id = definition.id or "${moduleIdentity.id}-${builtins.replaceStrings [ "." ] [ "-" ] definition.optionPath}";
        inherit moduleIdentity;
        optionPath = definition.optionPath;
        outcome = definition.outcome or "effective";
        priority = definition.priority or 100;
        role = definition.role or "contribution";
        valueDigest = valueDigest definition.value;
      };
    };

  mkDescriptor =
    records:
    let
      enriched = concatMap (
        record:
        map (enrichDefinition record.moduleIdentity) record.definitions
      ) records;
      indexed = imap0 (
        definitionIndex: entry:
        entry
        // {
          public = entry.public // { inherit definitionIndex; };
        }
      ) enriched;
    in
    {
      modules = map (record: record.module) records;
      contributionManifest = map (entry: entry.public) indexed;
      definitionChecks = indexed;
    };

  withLedgerMutation =
    {
      descriptor,
      id,
      file,
      mutate,
    }:
    let
      tamperedLedger = mutate descriptor.contributionManifest;
      tamperModule = {
        _file = file;
        config.contributorLedger = mkForce tamperedLedger;
      };
    in
    descriptor
    // {
      modules = descriptor.modules ++ [ tamperModule ];
    };

  repeatCharacter =
    character: count:
    builtins.concatStringsSep "" (builtins.genList (_: character) count);

  malformedSriDependency = productDependency // {
    sourceIdentity = productDependency.sourceIdentity // {
      narHash = "sha256-x";
    };
  };

  fabricatedDependency = productDependency // {
    sourceIdentity = productDependency.sourceIdentity // {
      revision = repeatCharacter "0" 40;
      narHash = "sha256-${repeatCharacter "A" 43}=";
    };
  };

  mutableDependency = productDependency // {
    sourceIdentity = productDependency.sourceIdentity // {
      revision = "main";
    };
  };

  operatorBaseDriver = {
    name = "firecracker";
    runtimeProfile = "firecracker-copy";
    implementationBundle = "operator-driver-bundle-v1";
    protocolVersion = 1;
  };

  operatorOverlayDriver = {
    name = "bubblewrap";
    runtimeProfile = "bubblewrap-copy";
    implementationBundle = "operator-driver-bundle-v1";
    protocolVersion = 1;
  };

  operatorProvider = {
    name = "local";
    driver = "firecracker";
    region = "local";
  };

  operatorPlacement = {
    name = "standard";
    driver = "firecracker";
    provider = "local";
    maxMemoryBytes = 4 * 1024 * 1024 * 1024;
  };

  operatorCredential = {
    name = "firecracker-operator";
    provider = "local";
    kind = "keychainHandle";
    reference = "keychain://operator/firecracker";
  };

  operatorImportModule = {
    _file = "fixture:operator-import-wrapper";
    imports = [ operatorImportSource ];
  };

  operatorBaseRecord =
    {
      dependency ? productDependency,
      providerOutcome ? "effective",
      operationId ? "operator-pinned-import",
    }:
    mkModuleRecord {
      id = operationId;
      file = "fixture:operator-pinned-import";
      sourcePath = operatorImportSource;
      module = operatorImportModule;
      definitions = [
        {
          id = "${operationId}-drivers";
          optionPath = "drivers";
          role = "import";
          value = [ operatorBaseDriver ];
          inherit dependency;
        }
        {
          id = "${operationId}-providers";
          optionPath = "providers";
          role = "default";
          priority = 1000;
          outcome = providerOutcome;
          value = [ operatorProvider ];
        }
        {
          id = "${operationId}-placement-classes";
          optionPath = "placementClasses";
          role = "import";
          value = [ operatorPlacement ];
        }
        {
          id = "${operationId}-maximum-memory";
          optionPath = "hardCeilings.maxMemoryBytes";
          role = "import";
          value = 8 * 1024 * 1024 * 1024;
        }
        {
          id = "${operationId}-maximum-sandboxes";
          optionPath = "hardCeilings.maxSandboxes";
          role = "import";
          value = 32;
        }
        {
          id = "${operationId}-credential-references";
          optionPath = "credentialReferences";
          role = "import";
          value = [ operatorCredential ];
        }
      ];
    };

  operatorOverlayRecord =
    id:
    mkModuleRecord {
      inherit id;
      file = "fixture:operator-product-overlay";
      sourcePath = operatorOverlaySource;
      module = {
        _file = "fixture:operator-overlay-wrapper";
        imports = [ operatorOverlaySource ];
      };
      definitions = [
        {
          id = "${id}-drivers";
          optionPath = "drivers";
          role = "contribution";
          definitionOrder = 1500;
          value = [ operatorOverlayDriver ];
        }
        {
          id = "${id}-maximum-memory";
          optionPath = "hardCeilings.maxMemoryBytes";
          role = "refinement";
          outcome = "narrowed";
          value = 8 * 1024 * 1024 * 1024;
        }
        {
          id = "${id}-maximum-sandboxes";
          optionPath = "hardCeilings.maxSandboxes";
          role = "refinement";
          outcome = "narrowed";
          value = 32;
        }
      ];
    };

  operatorOrdinaryDescriptor = mkDescriptor [
    (operatorBaseRecord { })
    (operatorOverlayRecord "operator-product-overlay")
  ];

  operatorSelection = [
    {
      name = "local";
      driver = "firecracker";
      region = "us-central-1";
    }
  ];

  operatorPrecedenceRecord = mkModuleRecord {
    id = "operator-provider-selection";
    file = "fixture:operator-provider-selection";
    module = {
      _file = "fixture:operator-provider-selection";
      config.providers = mkOverride 100 operatorSelection;
    };
    definitions = [
      {
        optionPath = "providers";
        role = "selection";
        priority = 100;
        outcome = "effective";
        value = operatorSelection;
      }
    ];
  };

  operatorPrecedenceDescriptor = mkDescriptor [
    (operatorBaseRecord { providerOutcome = "superseded"; })
    operatorPrecedenceRecord
  ];

  operatorNarrowingRecord = mkModuleRecord {
    id = "operator-ceiling-refinement";
    file = "fixture:operator-ceiling-refinement";
    module = {
      _file = "fixture:operator-ceiling-refinement";
      config.hardCeilings = {
        maxMemoryBytes = 4 * 1024 * 1024 * 1024;
        maxSandboxes = 8;
      };
    };
    definitions = [
      {
        optionPath = "hardCeilings.maxMemoryBytes";
        role = "refinement";
        outcome = "narrowed";
        value = 4 * 1024 * 1024 * 1024;
      }
      {
        optionPath = "hardCeilings.maxSandboxes";
        role = "refinement";
        outcome = "narrowed";
        value = 8;
      }
    ];
  };

  operatorNarrowingDescriptor = mkDescriptor [
    (operatorBaseRecord { })
    operatorNarrowingRecord
  ];

  operatorWideModule =
    let
      imported = import operatorImportSource { inherit lib; };
    in
    imported
    // {
      _file = "fixture:operator-wide-candidate";
      config = imported.config // {
        hardCeilings = {
          maxMemoryBytes = 16 * 1024 * 1024 * 1024;
          maxSandboxes = 64;
        };
      };
    };

  operatorWideRecord = mkModuleRecord {
    id = "operator-wide-candidate";
    file = "fixture:operator-wide-candidate";
    module = operatorWideModule;
    definitions = map (
      definition:
      if definition.optionPath == "hardCeilings.maxMemoryBytes" then
        definition // { value = 16 * 1024 * 1024 * 1024; }
      else if definition.optionPath == "hardCeilings.maxSandboxes" then
        definition // { value = 64; }
      else
        definition
    ) (operatorBaseRecord {
      operationId = "operator-wide-candidate-base";
      dependency = productDependency;
    }).definitions;
  };

  operatorCredentialValue = operatorCredential // {
    reference = "literal://credential-value";
  };

  operatorCredentialValueDescriptor = mkDescriptor [
    (operatorBaseRecord { })
    (mkModuleRecord {
      id = "operator-credential-value";
      file = "fixture:operator-credential-value";
      module = {
        _file = "fixture:operator-credential-value";
        config.credentialReferences = mkOverride 90 [ operatorCredentialValue ];
      };
      definitions = [
        {
          optionPath = "credentialReferences";
          role = "override";
          priority = 90;
          value = [ operatorCredentialValue ];
        }
      ];
    })
  ];

  operatorUnknownProvider = [
    {
      name = "local";
      driver = "unknown-driver";
      region = "local";
    }
  ];

  operatorUnregisteredDescriptor = mkDescriptor [
    (operatorBaseRecord { providerOutcome = "superseded"; })
    (mkModuleRecord {
      id = "operator-unregistered-driver";
      file = "fixture:operator-unregistered-driver";
      module = {
        _file = "fixture:operator-unregistered-driver";
        config.providers = operatorUnknownProvider;
      };
      definitions = [
        {
          optionPath = "providers";
          role = "selection";
          value = operatorUnknownProvider;
        }
      ];
    })
  ];

  operatorDelayedToken = "operator-delayed-implementation-bundle";

  operatorDelayedDescriptor = mkDescriptor [
    (operatorBaseRecord { })
    (mkModuleRecord {
      id = "operator-delayed-final-value";
      file = "fixture:operator-delayed-final-value";
      module = {
        _file = "fixture:operator-delayed-final-value";
        config.drivers = mkOverride 90 [
          (operatorBaseDriver // {
            implementationBundle =
              throw "operator.oc0.final_value_deep_forced: normalized Operator Configuration contains a delayed failure";
          })
        ];
      };
      definitions = [
        {
          optionPath = "drivers";
          role = "override";
          priority = 90;
          value = operatorDelayedToken;
          skipValueCheck = true;
        }
      ];
    })
  ];

  operatorForceDescriptor =
    priority: constructor: id:
    mkDescriptor [
      (operatorBaseRecord { })
      (mkModuleRecord {
        inherit id;
        file = "fixture:${id}";
        module = {
          _file = "fixture:${id}";
          config.hardCeilings.maxMemoryBytes =
            constructor (16 * 1024 * 1024 * 1024);
        };
        definitions = [
          {
            optionPath = "hardCeilings.maxMemoryBytes";
            role = "override";
            inherit priority;
            value = 16 * 1024 * 1024 * 1024;
          }
        ];
      })
    ];

  operatorMkForceDescriptor =
    operatorForceDescriptor 50 mkForce "operator-mk-force-ceiling";
  operatorStrongestDescriptor =
    operatorForceDescriptor (-1) (mkOverride (-1)) "operator-strongest-ceiling-override";

  operatorUnknownOptionDescriptor = mkDescriptor [
    (operatorBaseRecord { })
    (operatorOverlayRecord "operator-unknown-option-overlay")
    (mkModuleRecord {
      id = "operator-unknown-option";
      file = "fixture:operator-unknown-option";
      module = {
        _file = "fixture:operator-unknown-option";
        config.operatorRuntimeArguments =
          throw "TASK5_OPERATOR_STRUCTURAL_SECRET_7f3d";
      };
      definitions = [
        {
          optionPath = "operatorRuntimeArguments";
          role = "override";
          value = "non-forcing-structural-probe";
          checkDefinition = false;
        }
      ];
    })
  ];

  operatorNativeCredential = operatorCredential // {
    reference = "native://credential-object";
  };

  operatorModuleArgsDescriptor = mkDescriptor [
    (operatorBaseRecord { })
    (mkModuleRecord {
      id = "operator-module-args-provider";
      file = "fixture:operator-module-args-provider";
      module = {
        _file = "fixture:operator-module-args-provider";
        config._module.args.nativeCredentialReference = "native://credential-object";
      };
      definitions = [
        {
          optionPath = "_module.args.nativeCredentialReference";
          role = "override";
          value = "native://credential-object";
          checkDefinition = false;
        }
      ];
    })
    (mkModuleRecord {
      id = "operator-module-args-consumer";
      file = "fixture:operator-module-args-consumer";
      module =
        { nativeCredentialReference, ... }:
        {
          _file = "fixture:operator-module-args-consumer";
          config.credentialReferences = mkOverride 90 [
            (operatorCredential // { reference = nativeCredentialReference; })
          ];
        };
      definitions = [
        {
          optionPath = "credentialReferences";
          role = "override";
          priority = 90;
          value = [ operatorNativeCredential ];
        }
      ];
    })
  ];

  operatorFreeformDescriptor = mkDescriptor [
    (operatorBaseRecord { })
    (operatorOverlayRecord "operator-freeform-overlay")
    (mkModuleRecord {
      id = "operator-freeform-attempt";
      file = "fixture:operator-freeform-attempt";
      module = {
        _file = "fixture:operator-freeform-attempt";
        config = {
          _module.freeformType = lib.types.attrsOf lib.types.str;
          operatorFreeformEscape = "native driver object";
        };
      };
      definitions = [
        {
          optionPath = "operatorFreeformEscape";
          role = "override";
          value = "native driver object";
          checkDefinition = false;
        }
      ];
    })
  ];

  operatorDependencyDescriptor =
    id: dependency:
    mkDescriptor [
      (operatorBaseRecord {
        inherit dependency;
        operationId = id;
      })
      (operatorOverlayRecord "${id}-overlay")
    ];

  operatorIncompleteDependencyDescriptor =
    operatorDependencyDescriptor "operator-incomplete-dependency" null;
  operatorMalformedSriDescriptor =
    operatorDependencyDescriptor "operator-malformed-sri" malformedSriDependency;
  operatorFabricatedDependencyDescriptor =
    operatorDependencyDescriptor "operator-fabricated-dependency" fabricatedDependency;
  operatorMutableDependencyDescriptor =
    operatorDependencyDescriptor "operator-mutable-dependency" mutableDependency;

  ledgerExtraEntry =
    manifest:
    (builtins.head manifest)
    // {
      id = "operator-unexpected-contributor";
      definitionIndex = builtins.length manifest;
    };

  operatorOmittedLedgerDescriptor = withLedgerMutation {
    descriptor = operatorPrecedenceDescriptor;
    id = "operator-ledger-omission";
    file = "fixture:operator-ledger-omission";
    mutate = manifest: builtins.tail manifest;
  };
  operatorExtraLedgerDescriptor = withLedgerMutation {
    descriptor = operatorPrecedenceDescriptor;
    id = "operator-ledger-extra";
    file = "fixture:operator-ledger-extra";
    mutate = manifest: manifest ++ [ (ledgerExtraEntry manifest) ];
  };
  operatorDuplicateLedgerDescriptor = withLedgerMutation {
    descriptor = operatorPrecedenceDescriptor;
    id = "operator-ledger-duplicate";
    file = "fixture:operator-ledger-duplicate";
    mutate = manifest: manifest ++ [ (builtins.head manifest) ];
  };
  operatorWrongRoleDescriptor = withLedgerMutation {
    descriptor = operatorPrecedenceDescriptor;
    id = "operator-ledger-wrong-role";
    file = "fixture:operator-ledger-wrong-role";
    mutate =
      manifest:
      [
        ((builtins.head manifest) // { role = "override"; })
      ]
      ++ builtins.tail manifest;
  };
  operatorForceIncompleteLedgerDescriptor = withLedgerMutation {
    descriptor = operatorMkForceDescriptor;
    id = "operator-force-ledger-omission";
    file = "fixture:operator-force-ledger-omission";
    mutate =
      manifest:
      lib.take ((builtins.length manifest) - 1) manifest;
  };

  serviceArtifactReference = {
    artifactId = "workspace-agent";
    semanticDigest = "sha256-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=";
    member = "firecracker-copy";
  };

  serviceOperation = {
    kind = "createSandbox";
    api = "core.sandbox";
    schemaVersion = 1;
  };

  serviceLifecycle = {
    state = "active";
    restartPolicy = "on-failure";
    maxRestarts = 10;
    reconcileIntervalSeconds = 30;
  };

  serviceMetadata = {
    name = "workspace-agent";
    namespace = "default";
    owner = "platform";
    description = "default reconciler";
  };

  serviceImportModule = {
    _file = "fixture:service-import-wrapper";
    imports = [ serviceImportSource ];
  };

  serviceBaseRecord =
    {
      dependency ? productDependency,
      descriptionOutcome ? "effective",
      operationKindOutcome ? "effective",
      operationApiOutcome ? "effective",
      operationSchemaOutcome ? "effective",
      operationId ? "service-pinned-import",
    }:
    mkModuleRecord {
      id = operationId;
      file = "fixture:service-pinned-import";
      sourcePath = serviceImportSource;
      module = serviceImportModule;
      definitions = [
        {
          id = "${operationId}-artifact-id";
          optionPath = "artifactReference.artifactId";
          role = "import";
          value = serviceArtifactReference.artifactId;
          inherit dependency;
        }
        {
          id = "${operationId}-artifact-digest";
          optionPath = "artifactReference.semanticDigest";
          role = "import";
          value = serviceArtifactReference.semanticDigest;
        }
        {
          id = "${operationId}-artifact-member";
          optionPath = "artifactReference.member";
          role = "import";
          value = serviceArtifactReference.member;
        }
        {
          id = "${operationId}-operation-kind";
          optionPath = "createRequest.operation.kind";
          role = "default";
          priority = 1000;
          outcome = operationKindOutcome;
          value = serviceOperation.kind;
        }
        {
          id = "${operationId}-operation-api";
          optionPath = "createRequest.operation.api";
          role = "default";
          priority = 1000;
          outcome = operationApiOutcome;
          value = serviceOperation.api;
        }
        {
          id = "${operationId}-operation-schema";
          optionPath = "createRequest.operation.schemaVersion";
          role = "default";
          priority = 1000;
          outcome = operationSchemaOutcome;
          value = serviceOperation.schemaVersion;
        }
        {
          id = "${operationId}-runtime-profile";
          optionPath = "createRequest.runtimeProfile";
          role = "import";
          value = "firecracker-copy";
        }
        {
          id = "${operationId}-workspace-materialization";
          optionPath = "createRequest.workspace.materialization";
          role = "import";
          value = "copy";
        }
        {
          id = "${operationId}-allocation-memory";
          optionPath = "createRequest.allocation.memoryBytes";
          role = "import";
          value = 1024 * 1024 * 1024;
        }
        {
          id = "${operationId}-lifecycle-state";
          optionPath = "desiredLifecycle.state";
          role = "import";
          value = serviceLifecycle.state;
        }
        {
          id = "${operationId}-restart-policy";
          optionPath = "desiredLifecycle.restartPolicy";
          role = "import";
          value = serviceLifecycle.restartPolicy;
        }
        {
          id = "${operationId}-maximum-restarts";
          optionPath = "desiredLifecycle.maxRestarts";
          role = "import";
          value = serviceLifecycle.maxRestarts;
        }
        {
          id = "${operationId}-reconcile-interval";
          optionPath = "desiredLifecycle.reconcileIntervalSeconds";
          role = "import";
          value = serviceLifecycle.reconcileIntervalSeconds;
        }
        {
          id = "${operationId}-metadata-name";
          optionPath = "serviceMetadata.name";
          role = "import";
          value = serviceMetadata.name;
        }
        {
          id = "${operationId}-metadata-namespace";
          optionPath = "serviceMetadata.namespace";
          role = "import";
          value = serviceMetadata.namespace;
        }
        {
          id = "${operationId}-metadata-owner";
          optionPath = "serviceMetadata.owner";
          role = "import";
          value = serviceMetadata.owner;
        }
        {
          id = "${operationId}-metadata-description";
          optionPath = "serviceMetadata.description";
          role = "default";
          priority = 1000;
          outcome = descriptionOutcome;
          value = serviceMetadata.description;
        }
      ];
    };

  serviceOverlayRecord =
    id:
    mkModuleRecord {
      inherit id;
      file = "fixture:service-product-overlay";
      sourcePath = serviceOverlaySource;
      module = {
        _file = "fixture:service-overlay-wrapper";
        imports = [ serviceOverlaySource ];
      };
      definitions = [
        {
          id = "${id}-maximum-restarts";
          optionPath = "desiredLifecycle.maxRestarts";
          role = "refinement";
          outcome = "narrowed";
          value = 10;
        }
        {
          id = "${id}-reconcile-interval";
          optionPath = "desiredLifecycle.reconcileIntervalSeconds";
          role = "refinement";
          outcome = "narrowed";
          value = 30;
        }
      ];
    };

  serviceOrdinaryDescriptor = mkDescriptor [
    (serviceBaseRecord { })
    (serviceOverlayRecord "service-product-overlay")
  ];

  serviceDescriptionRecord = mkModuleRecord {
    id = "service-description-override";
    file = "fixture:service-description-override";
    module = {
      _file = "fixture:service-description-override";
      config.serviceMetadata.description = mkOverride 100 "production reconciler";
    };
    definitions = [
      {
        optionPath = "serviceMetadata.description";
        role = "override";
        priority = 100;
        value = "production reconciler";
      }
    ];
  };

  servicePrecedenceDescriptor = mkDescriptor [
    (serviceBaseRecord { descriptionOutcome = "superseded"; })
    serviceDescriptionRecord
  ];

  serviceNarrowingRecord = mkModuleRecord {
    id = "service-lifecycle-refinement";
    file = "fixture:service-lifecycle-refinement";
    module = {
      _file = "fixture:service-lifecycle-refinement";
      config.desiredLifecycle = {
        maxRestarts = 3;
        reconcileIntervalSeconds = 60;
      };
    };
    definitions = [
      {
        optionPath = "desiredLifecycle.maxRestarts";
        role = "refinement";
        outcome = "narrowed";
        value = 3;
      }
      {
        optionPath = "desiredLifecycle.reconcileIntervalSeconds";
        role = "refinement";
        outcome = "narrowed";
        value = 60;
      }
    ];
  };

  serviceNarrowingDescriptor = mkDescriptor [
    (serviceBaseRecord { })
    serviceNarrowingRecord
  ];

  serviceOperationDescriptor =
    {
      id,
      kind ? "createSandbox",
      api ? "core.sandbox",
      schemaVersion ? 1,
      kindPriority ? 100,
      apiPriority ? 100,
      schemaPriority ? 100,
      kindConstructor ? mkOverride kindPriority,
      apiConstructor ? mkOverride apiPriority,
      schemaConstructor ? mkOverride schemaPriority,
    }:
    mkDescriptor [
      (serviceBaseRecord {
        operationId = "${id}-base";
        operationKindOutcome = if kindPriority < 1000 then "superseded" else "effective";
        operationApiOutcome = if apiPriority < 1000 then "superseded" else "effective";
        operationSchemaOutcome = if schemaPriority < 1000 then "superseded" else "effective";
      })
      (mkModuleRecord {
        inherit id;
        file = "fixture:${id}";
        module = {
          _file = "fixture:${id}";
          config.createRequest.operation = {
            kind = kindConstructor kind;
            api = apiConstructor api;
            schemaVersion = schemaConstructor schemaVersion;
          };
        };
        definitions = [
          {
            id = "${id}-kind";
            optionPath = "createRequest.operation.kind";
            role = "override";
            priority = kindPriority;
            value = kind;
          }
          {
            id = "${id}-api";
            optionPath = "createRequest.operation.api";
            role = "override";
            priority = apiPriority;
            value = api;
          }
          {
            id = "${id}-schema";
            optionPath = "createRequest.operation.schemaVersion";
            role = "override";
            priority = schemaPriority;
            value = schemaVersion;
          }
        ];
      })
    ];

  serviceDriverCallDescriptor = serviceOperationDescriptor {
    id = "service-driver-call";
    kind = "driverCall";
  };
  serviceRawArgumentsDescriptor = serviceOperationDescriptor {
    id = "service-raw-runtime-arguments";
    kind = "rawRuntimeArguments";
  };
  serviceArtifactPolicyDescriptor = serviceOperationDescriptor {
    id = "service-artifact-policy";
    kind = "artifactPolicyMutation";
  };
  serviceUntypedDescriptor = serviceOperationDescriptor {
    id = "service-untyped-operation";
    api = "untyped";
    schemaVersion = 0;
  };

  serviceDelayedToken = "service-delayed-description";

  serviceDelayedDescriptor = mkDescriptor [
    (serviceBaseRecord { descriptionOutcome = "superseded"; })
    (mkModuleRecord {
      id = "service-delayed-final-value";
      file = "fixture:service-delayed-final-value";
      module = {
        _file = "fixture:service-delayed-final-value";
        config.serviceMetadata.description =
          throw "service.ms0.final_value_deep_forced: normalized Managed-Service Definition contains a delayed failure";
      };
      definitions = [
        {
          optionPath = "serviceMetadata.description";
          role = "override";
          priority = 100;
          value = serviceDelayedToken;
          skipValueCheck = true;
        }
      ];
    })
  ];

  serviceForceDescriptor =
    priority: constructor: id:
    serviceOperationDescriptor {
      inherit id;
      kind = "driverCall";
      kindPriority = priority;
      kindConstructor = constructor;
    };

  serviceMkForceDescriptor =
    serviceForceDescriptor 50 mkForce "service-mk-force-driver-call";
  serviceStrongestDescriptor =
    serviceForceDescriptor (-1) (mkOverride (-1)) "service-strongest-driver-call-override";

  serviceUnknownOptionDescriptor = mkDescriptor [
    (serviceBaseRecord { })
    (serviceOverlayRecord "service-unknown-option-overlay")
    (mkModuleRecord {
      id = "service-unknown-option";
      file = "fixture:service-unknown-option";
      module = {
        _file = "fixture:service-unknown-option";
        config.serviceDriverArguments =
          throw "TASK5_SERVICE_STRUCTURAL_SECRET_1c6a";
      };
      definitions = [
        {
          optionPath = "serviceDriverArguments";
          role = "override";
          value = "non-forcing-structural-probe";
          checkDefinition = false;
        }
      ];
    })
  ];

  serviceModuleArgsDescriptor = mkDescriptor [
    (serviceBaseRecord { })
    (mkModuleRecord {
      id = "service-module-args-provider";
      file = "fixture:service-module-args-provider";
      module = {
        _file = "fixture:service-module-args-provider";
        config._module.args.nativeServiceApi = "native://direct-driver";
      };
      definitions = [
        {
          optionPath = "_module.args.nativeServiceApi";
          role = "override";
          value = "native://direct-driver";
          checkDefinition = false;
        }
      ];
    })
    (mkModuleRecord {
      id = "service-module-args-consumer";
      file = "fixture:service-module-args-consumer";
      module =
        { nativeServiceApi, ... }:
        {
          _file = "fixture:service-module-args-consumer";
          config.createRequest.operation.api = nativeServiceApi;
        };
      definitions = [
        {
          optionPath = "createRequest.operation.api";
          role = "override";
          priority = 100;
          value = "native://direct-driver";
        }
      ];
    })
  ];

  serviceFreeformDescriptor = mkDescriptor [
    (serviceBaseRecord { })
    (serviceOverlayRecord "service-freeform-overlay")
    (mkModuleRecord {
      id = "service-freeform-attempt";
      file = "fixture:service-freeform-attempt";
      module = {
        _file = "fixture:service-freeform-attempt";
        config = {
          _module.freeformType = lib.types.attrsOf lib.types.str;
          serviceFreeformEscape = "direct driver object";
        };
      };
      definitions = [
        {
          optionPath = "serviceFreeformEscape";
          role = "override";
          value = "direct driver object";
          checkDefinition = false;
        }
      ];
    })
  ];

  serviceDependencyDescriptor =
    id: dependency:
    mkDescriptor [
      (serviceBaseRecord {
        inherit dependency;
        operationId = id;
      })
      (serviceOverlayRecord "${id}-overlay")
    ];

  serviceIncompleteDependencyDescriptor =
    serviceDependencyDescriptor "service-incomplete-dependency" null;
  serviceMalformedSriDescriptor =
    serviceDependencyDescriptor "service-malformed-sri" malformedSriDependency;
  serviceFabricatedDependencyDescriptor =
    serviceDependencyDescriptor "service-fabricated-dependency" fabricatedDependency;
  serviceMutableDependencyDescriptor =
    serviceDependencyDescriptor "service-mutable-dependency" mutableDependency;

  serviceExtraEntry =
    manifest:
    (builtins.head manifest)
    // {
      id = "service-unexpected-contributor";
      definitionIndex = builtins.length manifest;
    };

  serviceOmittedLedgerDescriptor = withLedgerMutation {
    descriptor = servicePrecedenceDescriptor;
    id = "service-ledger-omission";
    file = "fixture:service-ledger-omission";
    mutate = manifest: builtins.tail manifest;
  };
  serviceExtraLedgerDescriptor = withLedgerMutation {
    descriptor = servicePrecedenceDescriptor;
    id = "service-ledger-extra";
    file = "fixture:service-ledger-extra";
    mutate = manifest: manifest ++ [ (serviceExtraEntry manifest) ];
  };
  serviceDuplicateLedgerDescriptor = withLedgerMutation {
    descriptor = servicePrecedenceDescriptor;
    id = "service-ledger-duplicate";
    file = "fixture:service-ledger-duplicate";
    mutate = manifest: manifest ++ [ (builtins.head manifest) ];
  };
  serviceWrongRoleDescriptor = withLedgerMutation {
    descriptor = servicePrecedenceDescriptor;
    id = "service-ledger-wrong-role";
    file = "fixture:service-ledger-wrong-role";
    mutate =
      manifest:
      [
        ((builtins.head manifest) // { role = "override"; })
      ]
      ++ builtins.tail manifest;
  };
  serviceForceIncompleteLedgerDescriptor = withLedgerMutation {
    descriptor = serviceMkForceDescriptor;
    id = "service-force-ledger-omission";
    file = "fixture:service-force-ledger-omission";
    mutate =
      manifest:
      lib.take ((builtins.length manifest) - 1) manifest;
  };
in
{
  operator = {
    ordinary = operatorOrdinaryDescriptor;
    precedence = operatorPrecedenceDescriptor;
    narrowing = operatorNarrowingDescriptor;
    credentialValue = operatorCredentialValueDescriptor;
    unregisteredSelection = operatorUnregisteredDescriptor;
    delayed = operatorDelayedDescriptor;
    dependencyIncomplete = operatorIncompleteDependencyDescriptor;
    dependencyMalformedSri = operatorMalformedSriDescriptor;
    dependencyFabricated = operatorFabricatedDependencyDescriptor;
    dependencyMutable = operatorMutableDependencyDescriptor;
    ledgerOmitted = operatorOmittedLedgerDescriptor;
    ledgerExtra = operatorExtraLedgerDescriptor;
    ledgerDuplicate = operatorDuplicateLedgerDescriptor;
    ledgerWrongRole = operatorWrongRoleDescriptor;
    widenedCeiling = mkDescriptor [ operatorWideRecord ];
    mkForce = operatorMkForceDescriptor;
    strongestOverride = operatorStrongestDescriptor;
    mkForceIncompleteLedger = operatorForceIncompleteLedgerDescriptor;
    unknownOption = operatorUnknownOptionDescriptor;
    moduleArgsEscape = operatorModuleArgsDescriptor;
    freeformEscape = operatorFreeformDescriptor;
  };

  service = {
    ordinary = serviceOrdinaryDescriptor;
    precedence = servicePrecedenceDescriptor;
    narrowing = serviceNarrowingDescriptor;
    driverCall = serviceDriverCallDescriptor;
    rawRuntimeArguments = serviceRawArgumentsDescriptor;
    artifactPolicy = serviceArtifactPolicyDescriptor;
    untypedOperation = serviceUntypedDescriptor;
    delayed = serviceDelayedDescriptor;
    dependencyIncomplete = serviceIncompleteDependencyDescriptor;
    dependencyMalformedSri = serviceMalformedSriDescriptor;
    dependencyFabricated = serviceFabricatedDependencyDescriptor;
    dependencyMutable = serviceMutableDependencyDescriptor;
    ledgerOmitted = serviceOmittedLedgerDescriptor;
    ledgerExtra = serviceExtraLedgerDescriptor;
    ledgerDuplicate = serviceDuplicateLedgerDescriptor;
    ledgerWrongRole = serviceWrongRoleDescriptor;
    mkForce = serviceMkForceDescriptor;
    strongestOverride = serviceStrongestDescriptor;
    mkForceIncompleteLedger = serviceForceIncompleteLedgerDescriptor;
    unknownOption = serviceUnknownOptionDescriptor;
    moduleArgsEscape = serviceModuleArgsDescriptor;
    freeformEscape = serviceFreeformDescriptor;
  };
}
