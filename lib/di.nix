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
  inherit (prev.customisation) makeOverridable;

  inherit (final.trivial) invoke compose;
  inherit (final.overlays) lay foldLay;
  inherit (final.debug) attrPos;
in
rec {
  callWith =
    context: callee: overrides:
    let
      calleeArgs = functionArgs callee;
      callAttrs = intersectAttrs calleeArgs context // overrides;
      missing = findFirst (n: !(callAttrs ? ${n} || calleeArgs.${n})) null (attrNames calleeArgs);
    in
    if missing == null then
      invoke callee callAttrs
    else
      let
        suggestions =
          pipe
            [ overrides context ]
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
      abort "kasumi.lib.di.callWith: Function called without required argument '${missing}' at ${pos}${didYouMean}";

  callPackageBy = call: compose makeOverridable call;
  callPackageWith = compose callPackageBy callWith;

  callPinnedByCallPackage =
    callPackage: pin: fn: overrides:
    callPackage fn (callPackage pin { } // overrides);
  callPinnedBy = compose callPinnedByCallPackage callPackageBy;
  callPinnedWith = compose callPinnedBy callWith;

  makeScopeWith =
    prev: rattrs:
    let
      pkgs = prev // self;
      extension = rattrs pkgs;
      self = extension // {
        inherit pkgs extension;
        __unfix__ = rattrs;

        makeScope = makeScopeWith pkgs;
        fuse = g: self.makeScope (lay g rattrs);
        fold = gs: self.makeScope (lay (foldLay gs) rattrs);
        rebase = g: self.makeScope (final: g final pkgs);

        call = callWith pkgs;
        callPackage = callPackageBy self.call;
        callPinned = callPinnedByCallPackage self.callPackage;
      };
    in
    self;
}
