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

      templates = lib.filesystem.readTemplates { default = "unstable"; } ./templates;

      overlays = {
        default = import ./overlay.nix;
        lib = import ./overlays/lib.nix;
        compat = import ./overlays/compat.nix;
      };

      legacyPackages = lib.forAllPkgs nixpkgs {
        overlays = [
          self.overlays.compat
          self.overlays.default
        ];
      } nixpkgs.lib.id;

      packages = lib.forAllPkgs nixpkgs { } (
        pkgs: lib.makeScopeWith pkgs (_: { }) |> lib.rebaseScope self.overlays.default |> lib.collapseScope
      );

      formatter = lib.forAllPkgs self { } (pkgs: pkgs.kasumi-fmt);
      devShells = lib.forAllPkgs self { } (pkgs: {
        default = pkgs.callPackage ./shell.nix { };
      });
    };

  nixConfig = {
    extra-experimental-features = [
      "pipe-operators"
      "no-url-literals"
    ];
    extra-substituters = [ "https://kasumi.cachix.org" ];
    extra-trusted-public-keys = [ "kasumi.cachix.org-1:ymQ5ardABxeR1WrQX+NAvohAh2GL8aAv5W6osujKbG8=" ];
  };
}
