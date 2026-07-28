{
  manifestJson,
  nativeHandlesJson ? null,
  system ? builtins.currentSystem,
}:
let
  nixpkgsRevision = "62c8382960464ceb98ea593cb8321a2cf8f9e3e5";
  nixpkgs = builtins.getFlake "github:NixOS/nixpkgs/${nixpkgsRevision}";
  pkgs = import nixpkgs { inherit system; };
  manifest = builtins.fromJSON manifestJson;
  lib = nixpkgs.lib;

  packageInputs = {
    nixpkgs = {
      hello = pkgs.hello;
    };
  };

  resolvePackage =
    reference:
    let
      source = reference.source or reference;
    in
    if !(builtins.hasAttr source.input packageInputs) then
      throw "artifact.nix.package_input_known: unknown pinned package input"
    else if !(builtins.hasAttr source.attribute packageInputs.${source.input}) then
      throw "artifact.nix.package_attribute_known: package attribute is not exported by the pinned input"
    else
      packageInputs.${source.input}.${source.attribute};

  resolvedPackages = map resolvePackage manifest.environment.packages;

  nativeRegistry = import ./native-handles.nix { inherit pkgs; };
  nativeRegistryDigest = builtins.hashFile "sha256" ./native-handles.nix;
  nativeSourceClosureDigest = builtins.hashString "sha256" (
    builtins.toJSON {
      registry = "prototype-native";
      registryVersion = 1;
      nativeInterfaceVersion = 1;
      inherit
        nativeRegistryDigest
        nixpkgsRevision
        system
        ;
    }
  );

  guestSchema =
    { ... }:
    {
      options = {
        guest.services = lib.mkOption {
          type = lib.types.attrsOf lib.types.raw;
          default = { };
        };
        host.shares = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          internal = true;
        };
        host.interfaces = lib.mkOption {
          type = lib.types.listOf lib.types.str;
          default = [ ];
          internal = true;
        };
      };
      config._module.check = true;
    };

  resolveNative =
    handles:
    let
      registryKnown = handles.registry == "prototype-native";
      registryVersionKnown = handles.registryVersion == 1;
      digestMatches = handles.registryDigest == nativeRegistryDigest;
      closureDigestMatches = handles.sourceClosureDigest == nativeSourceClosureDigest;
      interfaceKnown = handles.nativeInterfaceVersion == 1;
      systemMatches = handles.targetSystem == system;
      memberEnabled = builtins.elem handles.affectedMember manifest.targets;
      effectsKnown =
        handles.expectedSemanticEffects == [
          "environment.devShell"
          "guest.services"
        ];
      devShellHandle = handles.devShell.handle;
      devShellExportMatches = handles.devShell.exportAttribute == "devShells.${devShellHandle}";
      devShell =
        nativeRegistry.devShells.${devShellHandle}
          or (throw "artifact.native_handle.dev_shell_known: unknown native devShell handle");
      guestModules = map (
        handle:
        if handle.exportAttribute != "guestModules.${handle.handle}" then
          throw "artifact.native_handle.export_attribute_matches: native guest-module export attribute mismatch"
        else if handle.affectedMember != handles.affectedMember then
          throw "artifact.native_handle.affected_member_matches: native guest-module member mismatch"
        else if handle.expectedSemanticEffect != "guest.services" then
          throw "artifact.native_handle.semantic_effect_matches: native guest-module effect mismatch"
        else
          nativeRegistry.guestModules.${handle.handle}
          or (throw "artifact.native_handle.guest_module_known: unknown native guest-module handle")
      ) handles.guestModules;
      evaluatedGuest = lib.evalModules {
        modules = [ guestSchema ] ++ guestModules;
        specialArgs = { inherit pkgs; };
      };
      guestConfig = evaluatedGuest.config;
      guestRespectsBoundary =
        guestConfig.host.shares == [ ] && guestConfig.host.interfaces == [ ];
      value = {
        registry = handles.registry;
        registryVersion = handles.registryVersion;
        registryDigest = nativeRegistryDigest;
        sourceClosureDigest = nativeSourceClosureDigest;
        nativeInterfaceVersion = handles.nativeInterfaceVersion;
        targetSystem = system;
        affectedMember = handles.affectedMember;
        expectedSemanticEffects = handles.expectedSemanticEffects;
        devShell = {
          inherit (handles.devShell) handle exportAttribute;
          drvPath = builtins.unsafeDiscardStringContext devShell.drvPath;
        };
        guestModules = map (handle: {
          inherit (handle)
            affectedMember
            expectedSemanticEffect
            exportAttribute
            handle
            ;
        }) handles.guestModules;
        guest.serviceNames = builtins.attrNames guestConfig.guest.services;
      };
    in
    if !registryKnown then
      throw "artifact.native_handle.registry_known: unknown native-handle registry"
    else if !registryVersionKnown then
      throw "artifact.native_handle.registry_version_known: unknown native-handle registry version"
    else if !digestMatches then
      throw "artifact.native_handle.registry_digest_matches: native-handle registry digest mismatch"
    else if !closureDigestMatches then
      throw "artifact.native_handle.source_closure_digest_matches: native source-closure digest mismatch"
    else if !interfaceKnown then
      throw "artifact.native_handle.interface_version_known: unknown native interface version"
    else if !systemMatches then
      throw "artifact.native_handle.target_system_matches: native target-system mismatch"
    else if !memberEnabled then
      throw "artifact.native_handle.affected_member_enabled: native affected member is not enabled"
    else if !effectsKnown then
      throw "artifact.native_handle.semantic_effects_match: native semantic-effect declaration mismatch"
    else if !devShellExportMatches then
      throw "artifact.native_handle.export_attribute_matches: native devShell export attribute mismatch"
    else if !guestRespectsBoundary then
      throw "artifact.native_guest.owner_boundary: guest modules may not define host shares or interfaces"
    else
      value;

  native =
    if nativeHandlesJson != null then
      resolveNative (builtins.fromJSON nativeHandlesJson)
    else
      null;

  builderManifest =
    {
      portableArtifact = manifest;
      packageStorePaths = map (package: package.outPath) resolvedPackages;
    }
    // lib.optionalAttrs (native != null) {
      nativeIdentity = native;
    };
  builder = pkgs.writeText "structured-prototype-artifact-manifest.json" (
    builtins.toJSON builderManifest
  );
in
{
  packages = map (package: {
    name = pkgs.lib.getName package;
    storePath = package.outPath;
  }) resolvedPackages;
  builderDrvPath = builder.drvPath;
  inherit
    builderManifest
    native
    ;
}
