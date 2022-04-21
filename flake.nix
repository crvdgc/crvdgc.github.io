{
  description = "site";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  inputs.hakyll-flakes.url = "github:Radvendii/hakyll-flakes";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, hakyll-flakes, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (
      system:
      hakyll-flakes.lib.mkAllOutputs {
        inherit system;
        name = "site";
        src = ./.;
        websiteBuildInputs = with nixpkgs.legacyPackages.${system}; [
          # rubber
          # texlive.combined.scheme-full
          # poppler_utils
        ];
      }
    );
}
