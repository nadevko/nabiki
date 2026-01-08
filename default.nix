{
  nixpkgs ? <nixpkgs>,
  pkgs ? import nixpkgs { },
  lib ? pkgs.lib,
  k-lib ? import ./lib.nix { inherit lib; },
}:
pkgs.extend (
  import ./overlay.nix {
    inherit
      nixpkgs
      pkgs
      lib
      k-lib
      ;
  }
)
