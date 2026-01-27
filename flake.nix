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
        compat = import ./overlays/compat.nix;
      };
      templates = lib.filesystem.readTemplates { } ./templates;
      legacyPackages = lib.forSystem (
        system:
        import nixpkgs {
          inherit system;
          overlays = [
            self.overlays.compat
            self.overlays.default
          ];
        }
      );
      packages = lib.forSystem (
        system:
        nixpkgs.lib.pipe nixpkgs.legacyPackages.${system} [
          (pkgs: lib.makeScopeWith pkgs (final: self.overlays.default final pkgs))
          (s: s.self)
        ]
      );
    };
}
