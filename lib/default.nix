{
  lib ? import <nixpkgs/lib>,
}:
lib.fix' (self: import ../mixins/lib.nix self lib)
