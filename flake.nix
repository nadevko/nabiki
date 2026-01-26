{
  description = "Nixpkgs Deconstruction Initiative";

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
      overlays = {
        default = import ./overlay.nix;
        lib = import ./overlays/lib.nix;
        augment = import ./overlays/augment.nix;
      };
      templates = lib.filesystem.readTemplates ./templates;
    }
    // lib.flakes.perScope nixpkgs { } [ self.overlays.default ] (scope: {
      inherit (scope) packages legacyPackages;
    });
}
