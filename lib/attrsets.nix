{ ... }:
let
  inherit (builtins)
    mapAttrs
    foldl'
    zipAttrsWith
    ;
in
rec {
  nestAttrs' =
    reader: roots: generator:
    zipAttrsWith (_: foldl' (a: b: a // b) { }) (
      map (root: mapAttrs (_: value: { ${root} = value; }) (generator (reader root))) roots
    );

  nestAttrs = nestAttrs' (x: x);
}
