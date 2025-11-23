{
  description = "lib with some handy nix functions";

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
    }:
    let
      lib = import ./. { inherit (nixpkgs) lib; };

      perPackages =
        pkgs:
        let
          treefmt = treefmt-nix.lib.evalModule pkgs {
            programs.nixfmt = {
              enable = true;
              strict = true;
            };
          };
        in
        {
          packages = lib.rebase self.overlays.default pkgs;
          legacyPackages = pkgs.extend self.overlays.default;
          formatter = treefmt.config.build.wrapper;
          checks.treefmt = treefmt.config.build.check self;
        };
    in
    {
      inherit lib;
      overlays = {
        default = lib.readPackagesOverlay ./pkgs;
        lib = lib.wrapLibExtension (_: _: lib);
      };
    }
    // lib.mapAttrsNested nixpkgs.legacyPackages perPackages;
}
