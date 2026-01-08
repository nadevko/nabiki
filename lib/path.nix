self: lib:
let
  inherit (builtins) match head;

  inherit (lib.strings) hasPrefix hasSuffix;
in
rec {
  removeExtension =
    name:
    let
      m = match "(.*)\\.[^.]+$" name;
    in
    if m == null then name else head m;

  isHidden = hasPrefix ".";
  isNixFile = hasSuffix ".nix";
  isValidNix = name: !isHidden name && isNixFile name;
}
