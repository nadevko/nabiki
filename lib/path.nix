self: lib:
let
  inherit (builtins) match head;

  inherit (lib.strings) hasPrefix hasSuffix removeSuffix;
in
rec {
  removeExtension =
    name:
    let
      m = match "(.*)\\.[^.]+$" name;
    in
    if m == null then name else head m;

  removeNixExtension = removeSuffix ".nix";

  isRegular = type: type == "regular";
  isDir = type: type == "directory";

  isHidden = hasPrefix ".";

  isNixFile = name: type: isRegular type && hasSuffix ".nix" name;
  isVisibleNix = name: type: !isHidden name && isNixFile name type;
  isVisibleDir = name: type: !isHidden name && isDir type;
}
