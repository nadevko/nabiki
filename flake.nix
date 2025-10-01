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
    }@inputs:
    let
      lib = import ./. { inherit (nixpkgs) lib; };
      private = nixpkgs.lib.composeExtensions self.overlays.lib (final: prev: { inherit inputs; });

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
        default = lib.readPackagesOverlay { } private ./pkgs;
        lib = lib.wrapLibExtension (_: _: lib);
      };
    }
    // lib.mapAttrsNested nixpkgs.legacyPackages perPackages;
}
