{ ... }:
let
  inherit (builtins) match head concatStringsSep;
in
{
  /**
    * Remove file extension from the `name` attribute.
    *
    * If `name` has no extension it is left unchanged.
  */
  removeExtension =
    { name, ... }@entry:
    let
      name' = match "(.*)\\.[^.]+$" name;
    in
    entry // { name = if name' == null then name else head name'; };

  /**
    Set a new node `name` which is the concatenation of `nodes ++ [ name ]`
    joined with the provided `sep`.

    Useful when producing flattened names from a node path.
  */
  concatNodesSep =
    sep: { nodes, name, ... }@entry: entry // { name = concatStringsSep sep (nodes ++ [ name ]); };
}
