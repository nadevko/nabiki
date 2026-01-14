self: lib:
let
  inherit (builtins) warn unsafeGetAttrPos;

  inherit (lib.trivial) flip pipe;
in
rec {
  compose =
    f: g: x:
    f (g x);

  fpipe = flip pipe;

  getAttrPosMessage =
    s: set:
    let
      attrPos = unsafeGetAttrPos s set;
    in
    if attrPos != null then attrPos.file + ":" + toString attrPos.line else "<unknown location>";

  libWarn =
    libName: lib: fnName: fn: message:
    warn "${libName}.${fnName} at ${getAttrPosMessage fn lib}: ${message}" fn;

  kasumiLibWarn = libWarn "kasumi.lib" self;
}
