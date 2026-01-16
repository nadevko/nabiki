final: prev:
let
  inherit (prev.trivial) flip pipe;
in
{
  id = x: x;
  const = x: y: x;
  snd = x: y: y;
  apply = f: x: f x;
  eq = x: y: x == y;

  compose =
    f: g: x:
    f (g x);

  fpipe = flip pipe;
}
