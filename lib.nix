{
  lib ? import <nixpkgs/lib>,
  fileset-internal ? import <nixpkgs/lib/fileset/internal.nix> { inherit lib; },
}:
let
  inherit (builtins) readDir;
  inherit (lib.fixedPoints) fix;
  inherit (lib.attrsets) mapAttrs' nameValuePair;
  inherit (lib.strings) removeSuffix;
  prev = lib // {
    fileset = lib.fileset // {
      internal = fileset-internal;
    };
  };
  final = fix (
    self:
    mapAttrs' (name: _: nameValuePair (removeSuffix ".nix" name) (import ./lib/${name} self prev)) (
      readDir ./lib
    )
  );
in
final.attrsets.addAliasesToAttrs final
