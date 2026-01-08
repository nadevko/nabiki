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

  isHidden = hasPrefix ".";
  isNixFile = hasSuffix ".nix";
  isValidNix = name: !isHidden name && isNixFile name;
}
