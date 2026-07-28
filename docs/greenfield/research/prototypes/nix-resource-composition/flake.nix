{
  description = "Disposable Operator and Managed-Service Nix composition witnesses";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/62c8382960464ceb98ea593cb8321a2cf8f9e3e5";

  outputs =
    { nixpkgs, ... }:
    let
      productDependency = {
        name = "nixpkgs";
        closurePath = toString nixpkgs.outPath;
        sourceIdentity = {
          kind = "flake";
          locator = "github:NixOS/nixpkgs";
          revision = nixpkgs.rev;
          narHash = nixpkgs.narHash;
        };
      };
      compositionRegistry = import ./composition-registry.nix {
        inherit
          productDependency
          ;
        lib = nixpkgs.lib;
      };
      validNativeExtensionSummaries = [
        {
          name = "firecracker";
          interfaceVersion = 1;
          sourceIdentity = productDependency.sourceIdentity;
        }
      ];
      malformedNativeExtensionSummaries = [
        {
          name = "firecracker";
          interfaceVersion = 1;
          sourceIdentity = builtins.removeAttrs productDependency.sourceIdentity [ "narHash" ];
        }
      ];
      unknownFieldNativeExtensionSummaries =
        marker:
        [
          {
            name = "firecracker";
            interfaceVersion = 1;
            sourceIdentity = productDependency.sourceIdentity;
            rawNativeHandle = throw marker;
          }
        ];
      wrongTypeNativeExtensionSummaries =
        marker:
        [
          {
            name = "firecracker";
            interfaceVersion = marker;
            sourceIdentity = productDependency.sourceIdentity;
          }
        ];
      mkOperator =
        productNativeExtensionSummaries:
        import ./operator-module.nix {
          inherit
            productDependency
            productNativeExtensionSummaries
            ;
          compositionRegistry = compositionRegistry.operator;
          lib = nixpkgs.lib;
        };
      mkService =
        productNativeExtensionSummaries:
        import ./service-module.nix {
          inherit
            productDependency
            productNativeExtensionSummaries
            ;
          compositionRegistry = compositionRegistry.service;
          lib = nixpkgs.lib;
        };
      operator = mkOperator validNativeExtensionSummaries;
      operatorNativeSummaryMalformed = mkOperator malformedNativeExtensionSummaries;
      operatorNativeSummaryUnknownField = mkOperator (
        unknownFieldNativeExtensionSummaries "TASK5_OPERATOR_NATIVE_UNKNOWN_SECRET_8a4e"
      );
      operatorNativeSummaryWrongType = mkOperator (
        wrongTypeNativeExtensionSummaries "TASK5_OPERATOR_NATIVE_TYPE_SECRET_9b5f"
      );
      service = mkService validNativeExtensionSummaries;
      serviceNativeSummaryMalformed = mkService malformedNativeExtensionSummaries;
      serviceNativeSummaryUnknownField = mkService (
        unknownFieldNativeExtensionSummaries "TASK5_SERVICE_NATIVE_UNKNOWN_SECRET_2d7b"
      );
      serviceNativeSummaryWrongType = mkService (
        wrongTypeNativeExtensionSummaries "TASK5_SERVICE_NATIVE_TYPE_SECRET_3e8c"
      );
    in
    {
      cases = import ./cases.nix {
        inherit
          operator
          operatorNativeSummaryMalformed
          operatorNativeSummaryUnknownField
          operatorNativeSummaryWrongType
          service
          serviceNativeSummaryMalformed
          serviceNativeSummaryUnknownField
          serviceNativeSummaryWrongType
          ;
      };
    };
}
