final: prev:
let
  inherit (builtins) unsafeGetAttrPos;
in
rec {
  attrPos' =
    default: n: set:
    let
      pos = unsafeGetAttrPos n set;
    in
    if pos == null then default else "${pos.file}:${toString pos.line}:${toString pos.column}";

  attrPos = attrPos' "<unknown location>";
}
