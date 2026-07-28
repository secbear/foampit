{ lib, ... }:
{
  _file = "fixture:service-pinned-import";
  config = {
    artifactReference = {
      artifactId = "workspace-agent";
      semanticDigest = "sha256-aaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaaa=";
      member = "firecracker-copy";
    };
    createRequest = {
      operation = {
        kind = lib.mkDefault "createSandbox";
        api = lib.mkDefault "core.sandbox";
        schemaVersion = lib.mkDefault 1;
      };
      runtimeProfile = "firecracker-copy";
      workspace.materialization = "copy";
      allocation.memoryBytes = 1024 * 1024 * 1024;
    };
    desiredLifecycle = {
      state = "active";
      restartPolicy = "on-failure";
      maxRestarts = 10;
      reconcileIntervalSeconds = 30;
    };
    serviceMetadata = {
      name = "workspace-agent";
      namespace = "default";
      owner = "platform";
      description = lib.mkDefault "default reconciler";
    };
  };
}
