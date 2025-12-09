{
  pkgs ? import <nixpkgs> { },
  lib ? import <nixpkgs/lib>,
  fileset-internal ? import <nixpkgs/lib/fileset/internal.nix> { inherit lib; },
  k ? import ./lib.nix { inherit lib fileset-internal; },
  _private ? _: _: { nixpkgs = <nixpkgs>; },
  _overrides ? _: prev: { },
}:
pkgs.extend (
  _: _:
  k.fixScope (k.triComposeScope pkgs.newScope _private (k.readPackagesExtension ./pkgs) _overrides)
)
