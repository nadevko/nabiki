self: lib:
let
  inherit (builtins) match head;

  inherit (lib.strings) hasPrefix hasSuffix removeSuffix;
in
{
  removeExtension =
    name:
    let
      m = match "(.*)\\.[^.]+$" name;
    in
    if m == null then name else head m;

  removeNixExtension = removeSuffix ".nix";

  isDir = type: type == "directory";
  isNix = name: hasSuffix ".nix" name;
  isHidden = hasPrefix ".";
}
