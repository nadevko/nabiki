{
  pkgs ? import <nixpkgs> { },
  lib ? import <nixpkgs/lib> { },
  fileset-internal ? import <nixpkgs/lib/fileset/internal.nix> { inherit lib; },
  k ? import ./lib.nix { inherit lib fileset-internal; },
  _private ? _: _: { nixpkgs = <nixpkgs>; },
  _overrides ? _: prev: { default = prev.kasumi-update; },
}:
pkgs.extend (
  k.fixScope' (k.triComposeScope pkgs.newScope _private (lib.readPackagesExtension ./pkgs) _overrides)
)
