{
  lib ? import <nixpkgs/lib>,
  ...
}:
let
  inherit (builtins) readDir attrValues;
  inherit (lib.fixedPoints) fix;
  inherit (lib.attrsets) mapAttrs' nameValuePair mergeAttrsList;
  inherit (lib.strings) removeSuffix;
  self = fix (
    final:
    mapAttrs' (
      name: _: nameValuePair (removeSuffix ".nix" name) (import ./lib/${name} final lib)
    ) (readDir ./lib)
  );
in
mergeAttrsList (attrValues self) // self
