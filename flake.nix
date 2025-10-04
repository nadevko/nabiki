{
  description = "yet another lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    treefmt-nix = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      self,
      nixpkgs,
      treefmt-nix,
    }@inputs:
    let
      lib = import ./. { inherit (nixpkgs) lib; };
    in
    {
      inherit lib;
      __functor = _: lib.attrsets.nestAttrs;
    }
    // lib.nestAttrs nixpkgs.lib.platforms.all (
      system:
      let
        pkgs = nixpkgs.legacyPackages.${system};
        treefmt = treefmt-nix.lib.evalModule pkgs {
          programs.nixfmt = {
            enable = true;
            strict = true;
          };
        };
      in
      {
        formatter = treefmt.config.build.wrapper;
        checks.treefmt = treefmt.config.build.check self;
      }
    )
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
