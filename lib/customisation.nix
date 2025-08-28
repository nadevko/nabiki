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
