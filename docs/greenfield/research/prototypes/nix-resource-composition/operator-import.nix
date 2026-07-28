{ lib, ... }:
{
  _file = "fixture:operator-pinned-import";
  config = {
    drivers = [
      {
        name = "firecracker";
        runtimeProfile = "firecracker-copy";
        implementationBundle = "operator-driver-bundle-v1";
        protocolVersion = 1;
      }
    ];
    providers = lib.mkDefault [
      {
        name = "local";
        driver = "firecracker";
        region = "local";
      }
    ];
    placementClasses = [
      {
        name = "standard";
        driver = "firecracker";
        provider = "local";
        maxMemoryBytes = 4 * 1024 * 1024 * 1024;
      }
    ];
    hardCeilings = {
      maxMemoryBytes = 8 * 1024 * 1024 * 1024;
      maxSandboxes = 32;
    };
    credentialReferences = [
      {
        name = "firecracker-operator";
        provider = "local";
        kind = "keychainHandle";
        reference = "keychain://operator/firecracker";
      }
    ];
  };
}
