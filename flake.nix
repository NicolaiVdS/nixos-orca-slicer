{
  description = "OrcaSlicer flake";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs = { self, nixpkgs }:
  let
    forAllSystems = function:
      nixpkgs.lib.genAttrs [
        "x86_64-linux"
        "x86_64-darwin"
        "aarch64-linux"
      ] (system:
          function (import nixpkgs {
            inherit system;
      }));
  in 
  {
    packages = forAllSystems (pkgs: {
      default = pkgs.stdenv.mkDerivation {
        name = "OrcaSlicer";
        src = "./.";
        buildPhase = ''
          mkdir -p $out/bin 
          chmod +x orca-slicer
          cp orca-slicer $out/bin
        '';
      };
    });
  };
}
