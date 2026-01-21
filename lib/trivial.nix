final: prev:
let
  inherit (builtins) isFunction;

  inherit (prev.trivial) flip pipe;
in
{
  snd = x: y: y;
  apply = f: x: f x;
  eq = x: y: x == y;

  compose =
    f: g: x:
    f (g x);

  fpipe = flip pipe;

  invoke = fn: if isFunction fn then fn else import fn;
}
