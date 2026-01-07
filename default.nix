{
  nixpkgs ? <nixpkgs>,
  pkgs ? import nixpkgs { },
  lib ? pkgs.lib,
  k ? import ./lib.nix { inherit lib; },
}:
pkgs.extend (
  lib.composeExtensions (k.wrapLibOverlay (_: _: k)) (
    k.readPackagesOverlay ./pkgs [ "package.nix" ] (_: {
      inherit nixpkgs;
    })
  )
)
