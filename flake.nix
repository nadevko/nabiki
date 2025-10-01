{
  description = "yet another lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      lib = import ./. { inherit (nixpkgs) lib; };
    in
    {
      inherit lib;
      __functor = _: lib.attrsets.nestAttrs;
    }
    // lib.nestAttrs nixpkgs.lib.platforms.all (
      system:
      builtins.mapAttrs
        (
          _: fn:
          fn {
            path = ./pkgs;
            overrides = { inherit inputs; };
            pkgs = nixpkgs.legacyPackages.${system};
          }
        )
        {
          packages = lib.readPackages;
          legacyPackages = lib.readLegacyPackages;
        }
    );
}
