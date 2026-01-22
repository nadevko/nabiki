final: prev:
let
  inherit (builtins) match head;

  inherit (prev.strings) hasPrefix hasSuffix removeSuffix;

  inherit (final.trivial) eq;
in
rec {
  stemOf =
    name:
    let
      matches = match ''(.*)\.[^.]+$'' name;
    in
    if matches == null then name else head matches;

  stemOfNix = removeSuffix ".nix";

  isDir = eq "directory";
  isNix = hasSuffix ".nix";
  isHidden = hasPrefix ".";
  isVisible = name: !isHidden name;

  isVisibleNix = name: type: isVisible name && isNix name;
  isVisibleDir = name: type: isVisible name && isDir type;
}
