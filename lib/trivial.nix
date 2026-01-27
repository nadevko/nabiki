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

  invoke = f: if isFunction f then f else import f;

  fix =
    rattrs:
    let
      self = rattrs self;
    in
    self;

  fix' =
    rattrs:
    let
      self = rattrs self // {
        __unfix__ = rattrs;
      };
    in
    self;

  annotateArgs = args: f: {
    __functor = self: f;
    __functionArgs = args;
  };

  mirrorArgsFrom = compose annotateArgs functionArgs;
}
