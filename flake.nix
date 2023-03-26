{
  description = "site";
  inputs.nixpkgs.url = "github:nixos/nixpkgs";
  # inputs.hakyll-flakes.url = "github:Radvendii/hakyll-flakes";
  inputs.flake-utils.url = "github:numtide/flake-utils";

  outputs = { self, flake-utils, nixpkgs }:
    flake-utils.lib.eachDefaultSystem (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
      in
      {
        devShell = pkgs.mkShell {
          buildInputs = with pkgs; [ zlib pkg-config ];
          shellHook = ''
            PKG_CONFIG_PATH="${pkgs.zlib}:$PKG_CONFIG_PATH"
          '';
        };
      }
    );
}
