{
  operator,
  operatorNativeSummaryMalformed,
  operatorNativeSummaryUnknownField,
  operatorNativeSummaryWrongType,
  service,
  serviceNativeSummaryMalformed,
  serviceNativeSummaryUnknownField,
  serviceNativeSummaryWrongType,
}:
let
  operatorValid =
    compositionId:
    {
      validForward = operator.evaluate {
        inherit compositionId;
      };
      validReverse = operator.evaluate {
        inherit compositionId;
        reverse = true;
      };
    };

  serviceValid =
    compositionId:
    {
      validForward = service.evaluate {
        inherit compositionId;
      };
      validReverse = service.evaluate {
        inherit compositionId;
        reverse = true;
      };
    };
in
{
  operatorOrdinaryAuthoring =
    operatorValid "ordinary"
    // {
      credentialValueRejected = operator.evaluate {
        compositionId = "credentialValue";
      };
      unregisteredSelectionRejected = operator.evaluate {
        compositionId = "unregisteredSelection";
      };
      delayedFinalValueRejected = operator.evaluate {
        compositionId = "delayed";
      };
      delayedWithoutFinalForce = operator.evaluateForceBoundaryProbe {
        compositionId = "delayed";
      };
    };

  operatorPinnedImport =
    operatorValid "ordinary"
    // {
      incompleteClosureRejected = operator.evaluate {
        compositionId = "dependencyIncomplete";
      };
      malformedSriRejected = operator.evaluate {
        compositionId = "dependencyMalformedSri";
      };
      fabricatedIdentityRejected = operator.evaluate {
        compositionId = "dependencyFabricated";
      };
    };

  operatorPrecedenceLedger =
    operatorValid "precedence"
    // {
      incompleteLedgerRejected = operator.evaluate {
        compositionId = "ledgerOmitted";
      };
      extraLedgerEntryRejected = operator.evaluate {
        compositionId = "ledgerExtra";
      };
      duplicateLedgerEntryRejected = operator.evaluate {
        compositionId = "ledgerDuplicate";
      };
      wrongRoleRejected = operator.evaluate {
        compositionId = "ledgerWrongRole";
      };
    };

  operatorSemanticNarrowing =
    operatorValid "narrowing"
    // {
      widenedCeilingRejected = operator.evaluate {
        compositionId = "widenedCeiling";
      };
    };

  operatorForceCeiling =
    operatorValid "narrowing"
    // {
      mkForceRejected = operator.evaluate {
        compositionId = "mkForce";
      };
      strongerOverrideRejected = operator.evaluate {
        compositionId = "strongestOverride";
      };
      mkForceIncompleteLedgerRejected = operator.evaluate {
        compositionId = "mkForceIncompleteLedger";
      };
    };

  operatorNativeEscape =
    operatorValid "ordinary"
    // {
      unknownOptionStructurallyRejected = operator.evaluate {
        compositionId = "unknownOption";
      };
      moduleArgsRejectedAtOc0 = operator.evaluate {
        compositionId = "moduleArgsEscape";
      };
      freeformRejectedAtOc0 = operator.evaluate {
        compositionId = "freeformEscape";
      };
      nativeSummaryMalformedRejected = operatorNativeSummaryMalformed.evaluate {
        compositionId = "ordinary";
      };
      nativeSummaryUnknownFieldRejected = operatorNativeSummaryUnknownField.evaluate {
        compositionId = "ordinary";
      };
      nativeSummaryTypeRejected = operatorNativeSummaryWrongType.evaluate {
        compositionId = "ordinary";
      };
    };

  operatorMutableDependency =
    operatorValid "ordinary"
    // {
      mutableDependencyRejected = operator.evaluate {
        compositionId = "dependencyMutable";
      };
    };

  serviceOrdinaryAuthoring =
    serviceValid "ordinary"
    // {
      driverCallRejected = service.evaluate {
        compositionId = "driverCall";
      };
      rawRuntimeArgumentsRejected = service.evaluate {
        compositionId = "rawRuntimeArguments";
      };
      artifactPolicyRejected = service.evaluate {
        compositionId = "artifactPolicy";
      };
      untypedOperationRejected = service.evaluate {
        compositionId = "untypedOperation";
      };
      delayedFinalValueRejected = service.evaluate {
        compositionId = "delayed";
      };
      delayedWithoutFinalForce = service.evaluateForceBoundaryProbe {
        compositionId = "delayed";
      };
    };

  servicePinnedImport =
    serviceValid "ordinary"
    // {
      incompleteClosureRejected = service.evaluate {
        compositionId = "dependencyIncomplete";
      };
      malformedSriRejected = service.evaluate {
        compositionId = "dependencyMalformedSri";
      };
      fabricatedIdentityRejected = service.evaluate {
        compositionId = "dependencyFabricated";
      };
    };

  servicePrecedenceLedger =
    serviceValid "precedence"
    // {
      incompleteLedgerRejected = service.evaluate {
        compositionId = "ledgerOmitted";
      };
      extraLedgerEntryRejected = service.evaluate {
        compositionId = "ledgerExtra";
      };
      duplicateLedgerEntryRejected = service.evaluate {
        compositionId = "ledgerDuplicate";
      };
      wrongRoleRejected = service.evaluate {
        compositionId = "ledgerWrongRole";
      };
    };

  serviceSemanticNarrowing = serviceValid "narrowing";

  serviceForceCoreApi =
    serviceValid "ordinary"
    // {
      mkForceRejected = service.evaluate {
        compositionId = "mkForce";
      };
      strongerOverrideRejected = service.evaluate {
        compositionId = "strongestOverride";
      };
      mkForceIncompleteLedgerRejected = service.evaluate {
        compositionId = "mkForceIncompleteLedger";
      };
    };

  serviceNativeEscape =
    serviceValid "ordinary"
    // {
      unknownOptionStructurallyRejected = service.evaluate {
        compositionId = "unknownOption";
      };
      moduleArgsRejectedAtMs0 = service.evaluate {
        compositionId = "moduleArgsEscape";
      };
      freeformRejectedAtMs0 = service.evaluate {
        compositionId = "freeformEscape";
      };
      nativeSummaryMalformedRejected = serviceNativeSummaryMalformed.evaluate {
        compositionId = "ordinary";
      };
      nativeSummaryUnknownFieldRejected = serviceNativeSummaryUnknownField.evaluate {
        compositionId = "ordinary";
      };
      nativeSummaryTypeRejected = serviceNativeSummaryWrongType.evaluate {
        compositionId = "ordinary";
      };
    };

  serviceMutableDependency =
    serviceValid "ordinary"
    // {
      mutableDependencyRejected = service.evaluate {
        compositionId = "dependencyMutable";
      };
    };
}
