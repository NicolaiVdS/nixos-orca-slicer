{
  description = "OrcaSlicer flake";

  inputs = {
    nixpkgs.url = "nixpkgs"; # We want to use packages from the binary cache
    flake-utils.url = "github:numtide/flake-utils";
  };

  outputs = inputs@{ self, nixpkgs, flake-utils, ... }:
  flake-utils.lib.eachSystem [ "x86_64-linux" ] (system: let
    pkgs = nixpkgs.legacyPackages.${system};
  in rec {
    packages.orca-slicer = pkgs.callPackage ./default.nix {
      inherit (pkgs.gst_all_1) gstreamer gst-plugins-base gst-plugins-bad;
    };

    legacyPackages = packages;

    defaultPackage = packages.orca-slicer;

    devShell = pkgs.mkShell {
      buildInputs = with pkgs; [ git ];
    };

  });
}
