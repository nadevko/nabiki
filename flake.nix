{
  description = "lib with some handy nix functions";

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
      templates = lib.filesystem.readTemplates (_: {
        description = "Most common kasumi usage";
      }) ./templates;
    }
    // lib.flakes.perSystem nixpkgs { overlays = [ self.overlays.augment ]; } (pkgs: {
      legacyPackages = import ./. { inherit pkgs; };
      packages = self.overlays.default pkgs { };
    });
}
