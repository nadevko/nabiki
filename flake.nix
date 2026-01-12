{
  description = "lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      getLib = lib: import ./lib.nix { inherit lib; };
      lib = getLib nixpkgs.lib;
    in
    {
      inherit lib;
      overlays = {
        default = import ./overlay.nix;
        lib = lib.wrapLibOverlay (_: prev: getLib prev.lib);
      };
      templates = lib.readTemplates (lib.getOverride { } {
        default.description = "Most common kasumi usage";
      }) ./templates;
    }
    // lib.perSystem nixpkgs null (pkgs: {
      legacyPackages = import ./. { inherit pkgs; };
      packages = self.overlays.default pkgs { };
    });
}
