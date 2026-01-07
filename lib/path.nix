self: lib:
let
  inherit (builtins) match head;

  inherit (lib.strings) hasPrefix hasSuffix;
in
rec {
  removeExtension =
    name:
    let
      name' = match "(.*)\\.[^.]+$" name;
    in
    if name' == null then name else head name';

  isHidden = hasPrefix ".";
  isNixFile = hasSuffix ".nix";
  isValidNix = name: !isHidden name && isNixFile name;
}
