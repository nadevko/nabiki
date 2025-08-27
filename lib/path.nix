{ ... }:
let
  inherit (builtins) match head concatStringsSep;
in
{
  removeExtension =
    { name, ... }@entry:
    let
      name' = match "(.*)\\.[^.]+$" name;
    in
    entry // { name = if name' == null then name else head name'; };

  concatNodesSep =
    sep: { nodes, name, ... }@entry: entry // { name = concatStringsSep sep (nodes ++ [ name ]); };
}
