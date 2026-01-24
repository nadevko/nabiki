{
  description = "Nixpkgs Destructurisation Initiative";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = import ./lib { inherit (nixpkgs) lib; };
    in
    {
      inherit lib;
      overlays = self.mixins;
      mixins = {
        default = import ./mixin.nix;
        lib = import ./mixins/lib.nix;
        augment = import ./mixins/augment.nix;
      };
      templates = lib.filesystem.readTemplates ./templates;
    }
    // lib.flakes.perScope nixpkgs { } [ self.mixins.default ] (scope: {
      inherit (scope) packages legacyPackages;
    });
}
