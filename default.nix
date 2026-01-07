{
  lib ? import <nixpkgs/lib>,
  k ? import ./lib.nix { inherit lib; },
}:
{
  inherit lib k;
}
