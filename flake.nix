{
  description = "lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = import ./lib.nix { inherit (nixpkgs) lib; };

      callSet = lib.makeCallSet (lib.getOverride { } { }) (
        lib.intersectListsBy (x: x.stem) [ "package" ] (lib.listShallowNixes ./pkgs)
      );

      unscope = lib.fixCallSet callSet;
    in
    {
      inherit lib;
      overlays = {
        default = lib.wrapFinal callSet;
        lib = lib.wrapLibOverlay (lib.toOverlay lib);
        scope = lib.unscopeToOverlay "kasumi" unscope;
      };
      templates = lib.readTemplates (lib.getOverride { } {
        default.description = "Most common kasumi usage";
      }) ./templates;
    }
    // lib.genFromPkgs nixpkgs null (pkgs: {
      legacyPackages = pkgs.extend (
        lib.composeOverlayList [
          self.overlays.lib
          self.overlays.packages
          self.overlays.scope
        ]
      );
      packages = lib.rebaseScope (unscope pkgs);
    });
}
