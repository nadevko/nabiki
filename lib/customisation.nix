{ self, lib, ... }:
let
  inherit (builtins)
    getFlake
    toString
    attrValues
    catAttrs
    ;

  inherit (self.trivial) fpipe;

  inherit (lib.lists) unique;
in
{
  /**
    Obtain all `updateScript` attributes from packages.

    This assumes that every package exposes `passthru.updateScript` and that
    `updateScript` is a derivation (or present) for the packages of the given system.

    Returns a list of unique update scripts.
  */
  getUpdateScripts =
    system:
    fpipe [
      toString
      getFlake
      (x: x.outputs.packages.${system})
      attrValues
      (catAttrs "passthru")
      (catAttrs "updateScript")
      unique
    ];
}
