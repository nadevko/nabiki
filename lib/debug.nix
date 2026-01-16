final: prev:
let
  inherit (builtins) unsafeGetAttrPos;
in
rec {
  attrPos' =
    default: s: set:
    let
      pos = unsafeGetAttrPos s set;
    in
    if pos == null then default else "${pos.file}:${toString pos.line}:${toString pos.column}";

  attrPos = attrPos' "<unknown location>";
}
