self: lib:
let
  inherit (lib.trivial) pipe flip;
  inherit (lib.lists) foldr;
in
rec {
  compose =
    f: g: x:
    f (g x);

  fpipe' = flip pipe;

  fpipe = flip (foldr compose);
}
