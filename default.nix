{
  pkgs ? import <nixpkgs> args,
  ...
}@args:
pkgs.appendOverlays [
  (import ./overlays/compat.nix)
  (import ./overlay.nix)
]
