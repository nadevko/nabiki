{
  pkgs ? import <nixpkgs> args,
  ...
}@args:
pkgs.appendOverlays [
  (import ./overlays/nixos.nix)
  (import ./overlays/compat.nix)
  (import ./overlay.nix)
]
