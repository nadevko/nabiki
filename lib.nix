{
  lib ? import <nixpkgs/lib>,
}:
lib.fix' (self: import ./overlays/lib.nix self lib)
