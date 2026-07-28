{
  description = "Pinned Foampit Packet E contract-compiler prototype";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/624af665418d3c65d544145b4d34ad696439570e";

  outputs = { self, nixpkgs }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
    in {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          pkgs.nodejs_22
          pkgs.pnpm_10
          pkgs.cue
          pkgs.quint
          pkgs.protobuf
          pkgs.rustc
          pkgs.cargo
          pkgs.go
          pkgs.python313
        ];
      };
    };
}
