final: prev:
let
  inherit (builtins)
    attrNames
    functionArgs
    intersectAttrs
    filter
    head
    length
    concatStringsSep
    concatMap
    ;
  inherit (prev.trivial) pipe;
  inherit (prev.lists)
    take
    sortOn
    init
    last
    findFirst
    ;
  inherit (prev.strings) levenshteinAtMost levenshtein;

  inherit (final.mixins)
    mix
    foldMix
    fix
    mixr
    mixl
    ;
  inherit (final.trivial) invoke;
  inherit (final.debug) attrPos;
in
rec {
  initLibAs = name: fn: final: prev: { ${name} = fix (final: invoke fn final { }); };
  initLib = initLibAs "lib";

  mergeLibWith = merger: base: name: fn: final: prev: {
    ${name} = fix (merger (invoke fn) (_: prev.${base}));
  };

  forkLibFrom = mergeLibWith mixr;
  forkLibAs = forkLibFrom "lib";
  forkLib = forkLibAs "lib";

  augmentLibFrom = mergeLibWith mixl;
  augmentLibAs = augmentLibFrom "lib";
  augmentLib = augmentLibAs "lib";

  callWith =
    context: callee: attrs:
    let
      calleeArgs = functionArgs callee;
      callAttrs = intersectAttrs calleeArgs context // attrs;
      missing = findFirst (n: !(callAttrs ? ${n} || calleeArgs.${n})) null (attrNames calleeArgs);
    in
    if missing == null then
      callee callAttrs
    else
      let
        suggestions =
          pipe
            [ attrs context ]
            [
              (concatMap attrNames)
              (filter (levenshteinAtMost 2 missing))
              (sortOn (levenshtein missing))
              (take 3)
            ];

        didYouMean =
          if suggestions == [ ] then
            ""
          else if length suggestions == 1 then
            ", did you mean '${head suggestions}'?"
          else
            ", did you mean '${concatStringsSep "', '" (init suggestions)}' or '${last suggestions}'?";

        pos = attrPos missing calleeArgs;
      in
      abort "kasumi.lib.customisation.call: Function called without required argument '${missing}' at ${pos}${didYouMean}";

  makeScopeWith =
    base: rattrs:
    let
      context = base // self;
      self = rattrs context;
      scope = self // {
        inherit self context;
        __unfix__ = rattrs;

        fuse = g: makeScopeWith context (mix g rattrs);
        fold = gs: makeScopeWith context (mix (foldMix gs) rattrs);
        rebase = g: scope.makeScope (final: g final context);
        makeScope = makeScopeWith context;

        call = callWith context;
      };
    in
    scope;
}
