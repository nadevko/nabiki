self: lib:
let
  inherit (lib.trivial) flip pipe;
  inherit (lib.lists) foldl;
in
{
  compose =
    f: g: x:
    f (g x);

  fpipe' = flip pipe;
  fpipe = flip (foldl (x: f: f x));
}
