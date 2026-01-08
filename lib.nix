{
  lib ? import <nixpkgs/lib>,
}:
let
  inherit (builtins) readDir;
  inherit (lib.fixedPoints) fix;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.strings) removeSuffix;
  final = fix (
    self:
    mapAttrs' (name: _: nameValuePair (removeSuffix ".nix" name) (import ./lib/${name} self lib)) (
      readDir ./lib
    )
  );
in
final.attrsets.addAliasesToAttrs' final
