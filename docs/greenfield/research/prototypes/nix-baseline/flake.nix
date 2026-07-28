{
  description = "Disposable strengthened-Nix configuration-language prototype";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/62c8382960464ceb98ea593cb8321a2cf8f9e3e5";

  outputs =
    { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      prototype = import ./prototype.nix {
        inherit pkgs;
        lib = nixpkgs.lib;
      };
    in
    {
      cases = import ./cases.nix {
        inherit pkgs prototype;
        lib = nixpkgs.lib;
      };
    };
}
