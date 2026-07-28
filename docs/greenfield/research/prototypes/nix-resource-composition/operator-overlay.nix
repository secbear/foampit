{ lib, ... }:
{
  _file = "fixture:operator-product-overlay";
  config = {
    drivers = lib.mkAfter [
      {
        name = "bubblewrap";
        runtimeProfile = "bubblewrap-copy";
        implementationBundle = "operator-driver-bundle-v1";
        protocolVersion = 1;
      }
    ];
    hardCeilings = {
      maxMemoryBytes = 8 * 1024 * 1024 * 1024;
      maxSandboxes = 32;
    };
  };
}
