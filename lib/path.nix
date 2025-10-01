self: lib:
let
  inherit (builtins)
    match
    head
    pathExists
    concatStringsSep
    ;

  inherit (lib) hasPrefix hasSuffix;
in
rec {
  removeExtension =
    name:
    let
      name' = match "(.*)\\.[^.]+$" name;
    in
    if name' == null then name else head name';

  concatNodesToNamesSep' =
    forceFileName: sep:
    { name, nodes, ... }@e:
    e
    // {
      fullName = concatStringsSep sep (
        nodes ++ (if forceFileName || nodes == [ ] then [ (removeExtension name) ] else [ ])
      );
    };

  concatNodesToNamesSep = concatNodesToNamesSep' false;

  concatNodesToNames = concatNodesToNames "-";

  isNix = { name, ... }: hasSuffix ".nix" name;
  isHidden = { name, ... }: hasPrefix "." name;
  isDirectory = { type, ... }: type == "directory";
  isImportableNix = { path, ... }@e: isNix e || isDirectory e && pathExists /${path}/default.nix;
}
