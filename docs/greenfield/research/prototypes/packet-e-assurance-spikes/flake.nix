{
  description = "Pinned Packet E blocker-first assurance feasibility spikes";

  inputs.nixpkgs.url = "github:NixOS/nixpkgs/624af665418d3c65d544145b4d34ad696439570e";

  outputs =
    { nixpkgs, ... }:
    let
      system = "aarch64-darwin";
      pkgs = import nixpkgs { inherit system; };
      assurancePackages = {
        node = pkgs.nodejs_22;
        jq = pkgs.jq;
        cue = pkgs.cue;
        lean = pkgs.lean4;
        checkJsonschema = pkgs.check-jsonschema;
        python = pkgs.python313;
        sqlite = pkgs.sqlite;
      };
    in
    {
      devShells.${system}.default = pkgs.mkShell {
        packages = [
          assurancePackages.node
          assurancePackages.jq
          assurancePackages.cue
          assurancePackages.lean
          assurancePackages.checkJsonschema
          assurancePackages.python
          assurancePackages.sqlite
        ];
        shellHook = ''
          export PATH="${assurancePackages.python}/bin:$PATH"
        '';
      };
    };
}
