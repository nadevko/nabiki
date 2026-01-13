{
  description = "lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = import ./lib.nix { inherit (nixpkgs) lib; };
    in
    {
      inherit lib;
      overlays = {
        default = import ./overlay.nix;
        lib = import ./overlays/lib.nix;
      };
      templates = lib.filesystem.readTemplates (_: {
        description = "Most common kasumi usage";
      }) ./templates;
    }
    // lib.attrsets.perSystem nixpkgs null (pkgs: {
      legacyPackages = import ./. { inherit pkgs; };
      packages = self.overlays.default pkgs { };
    });
}
