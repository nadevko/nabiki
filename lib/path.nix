self: lib:
let
  inherit (builtins) match head;
in
{
  removeExtension =
    name:
    let
      name' = match "(.*)\\.[^.]+$" name;
    in
    if name' == null then name else head name';
}
