{
  nixpkgs ? <nixpkgs>,
  pkgs ? import nixpkgs { },
  lib ? pkgs.lib,
  k ? import ./lib.nix { inherit lib; },
}:
pkgs.extend (
  lib.composeExtensions (k.wrapLibExtension (_: _: k)) (
    k.readPackagesOverlay ./pkgs [ "package.nix" ] (_: {
      inherit nixpkgs;
    })
  )
)
