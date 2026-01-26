final: prev:
let
  inherit (builtins) isFunction functionArgs;

  inherit (prev.trivial) flip pipe;
in
rec {
  snd = x: y: y;
  apply = f: x: f x;
  eq = x: y: x == y;
  neq = x: y: x != y;

  compose =
    f: g: x:
    f (g x);

  fpipe = flip pipe;

  invoke = fn: if isFunction fn then fn else import fn;

  fix =
    rattrs:
    let
      x = rattrs x;
    in
    x;

  fix' =
    rattrs:
    let
      x = rattrs x // {
        __unfix__ = rattrs;
      };
    in
    x;

  annotateArgs = args: f: {
    __functor = final: f;
    __functionArgs = args;
  };

  mirrorArgsFrom = compose annotateArgs functionArgs;
}
