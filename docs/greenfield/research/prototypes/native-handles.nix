{ pkgs }:
{
  devShells.project = pkgs.mkShell {
    packages = [ pkgs.hello ];
  };

  guestModules = {
    "safe-service" = {
      _file = "native-handle:safe-service";
      config.guest.services.example = {
        command = "${pkgs.hello}/bin/hello";
      };
    };

    "unsafe-host-share" = {
      _file = "native-handle:unsafe-host-share";
      config.host.shares = [ "/host/workspace" ];
    };
  };
}
