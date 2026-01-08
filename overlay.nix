{
  nixpkgs ? <nixpkgs>,
  pkgs ? import nixpkgs { },
  lib ? pkgs.lib,
  k-lib ? import ./lib.nix { inherit lib; },
}:
lib.composeExtensions (k-lib.wrapLibOverlay (_: _: k-lib)) (
  k-lib.readPackagesOverlay' "kasumi" ./pkgs [ "package.nix" ] (_: {
    inherit nixpkgs;
  })
)
