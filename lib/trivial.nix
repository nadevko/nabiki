final: prev:
let
  inherit (builtins)
    isFunction
    length
    elemAt
    functionArgs
    ;

  inherit (prev.trivial) flip pipe;
in
rec {
  snd = x: y: y;
  apply = f: x: f x;
  eq = x: y: x == y;

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

  dfold =
    transform: getInitial: getFinal: itemsList:
    let
      totalItems = length itemsList;
      linkStage =
        previousStage: index:
        if index == totalItems then
          getFinal previousStage
        else
          let
            thisStage = transform previousStage (elemAt itemsList index) nextStage;
            nextStage = linkStage thisStage (index + 1);
          in
          thisStage;
      initialStage = getInitial firstStage;
      firstStage = linkStage initialStage 0;
    in
    firstStage;

  annotateArgs = args: f: {
    __functor = self: f;
    __functionArgs = args;
  };

  mirrorArgsFrom = compose annotateArgs functionArgs;
}
