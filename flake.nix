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
        default = lib.readPackagesOverlay ./pkgs [ "package.nix" ] (self.overlays.private { });
        private = _: _: { inherit nixpkgs; };
        lib = lib.wrapLibExtension (_: _: lib);
      };
      templates = lib.readTemplates (lib.getOverride { } {
        default.description = "Most common kasumi usage";
      }) ./templates;
    }
    // lib.genFromNixpkgs nixpkgs null (pkgs: {
      packages =
        lib.rebase self.overlays.default
          nixpkgs.legacyPackages.${pkgs.stdenv.hostPlatform.system};
      legacyPackages = pkgs.extend self.overlays.default;
    });
}
