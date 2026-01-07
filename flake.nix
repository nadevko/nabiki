{
  description = "lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = import ./lib.nix { inherit (nixpkgs) lib; };
      unscope = lib.readPackagesScope ./pkgs [ "package.nix" ] (self.overlays.private { });
    in
    {
      inherit lib;
      overlays = {
        default = self.overlays.packages;
        packages = lib.unscopeToOverlay unscope;
        packages' = lib.unscopeToOverlay' unscope;
        private = _: _: { inherit nixpkgs; };
        lib = lib.wrapLibOverlay (_: _: lib);
      };
      templates = lib.readTemplates (lib.getOverride { } {
        default.description = "Most common kasumi usage";
      }) ./templates;
    }
    // lib.genFromPkgs nixpkgs null (
      pkgs:
      let
        kasumi = unscope pkgs.newScope;
      in
      {
        packages = lib.rebaseScope kasumi;
        legacyPackages = pkgs.extend self.overlays.packages';
      }
    );
}
