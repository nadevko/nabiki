{
  description = "lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    treefmt = {
      url = "github:numtide/treefmt-nix";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    { self, nixpkgs, ... }@inputs:
    let
      lib = import ./lib.nix {
        inherit (nixpkgs) lib;
        fileset-internal = import "${nixpkgs}/lib/fileset/internal.nix" { inherit (nixpkgs) lib; };
      };
    in
    lib.mkflake {
      inherit lib inputs;
      overlays = {
        default = lib.readPackagesExtension ./pkgs;
        lib = lib.wrapLibExtension (_: _: lib);
        _private = _: _: { inherit inputs; };
        _overrides = _: prev: { default = prev.kasumi-update; };
      };
      perPackages = pkgs: rec {
        packages = lib.fixScope scopes.default;
        defaultPackage = packages.default;
        scopes.default = with self.overlays; lib.triComposeScope pkgs.newScope _private default _overrides;
        defaultScope = scopes.default;
        legacyPackages = pkgs.extend (_: _: packages);
      };
      __functor = lib.mkflake;
    };
}
