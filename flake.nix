{
  description = "lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = import ./lib.nix { inherit (nixpkgs) lib; };

      callSet = nixpkgs.lib.pipe ./pkgs [
        lib.listShallowNixes
        (lib.intersectListsBy (x: x.stem) [ "package" ])
        builtins.listToAttrs
        (lib.makeCallSet (lib.getOverride { } { }))
      ];

      unscope = lib.makeUnscope callSet;
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
          self.overlays.default
          self.overlays.scope
        ]
      );
      packages = lib.rebaseScope (unscope pkgs);
    });
}
