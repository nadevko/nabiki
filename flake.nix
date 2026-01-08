{
  description = "lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = import ./lib.nix { inherit (nixpkgs) lib; };

      files = lib.intersectListsBy (x: x.stem) [ "package" ] (lib.listShallowNixes ./pkgs);
      set = builtins.listToAttrs files;
      f = lib.mapFinalCallPackage (lib.getOverride { } { }) set;
      unscope = lib.makeUnscope f;
    in
    {
      inherit lib;
      overlays = {
        lib = lib.wrapLibOverlay (_: _: lib);
        default = self.overlays.packages;
        packages = lib.unscopeToOverlay unscope;
        packages' = lib.unscopeToOverlay' "kasumi" unscope;
      };
      templates = lib.readTemplates (lib.getOverride { } {
        default.description = "Most common kasumi usage";
      }) ./templates;
    }
    // lib.genFromPkgs nixpkgs null (
      pkgs:
      let
        scope = unscope pkgs.newScope;
      in
      {
        legacyPackages = pkgs.extend self.overlays.packages';
        packages = lib.rebaseScope scope;
      }
    );
}
