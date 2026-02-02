_: prev:
let
  inherit (builtins) isFunction functionArgs;
in
rec {
  snd = _: y: y;
  apply = f: x: f x;
  eq = x: y: x == y;
  neq = x: y: x != y;

  compose =
    f: g: x:
    f <| g x;

  invoke = f: if isFunction f then f else import f;

  fix =
    rattrs:
    let
      self = rattrs self;
    in
    self;

  fix' =
    __rattrs:
    let
      self = __rattrs self // {
        inherit __rattrs;
      };
    in
    self;

  annotateArgs = args: f: {
    __functor = _: f;
    __functionArgs = args;
  };

  mirrorArgsFrom = compose annotateArgs functionArgs;
}
