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
  inherit (prev.customisation) makeOverridable;
  inherit (prev.trivial) pipe;
  inherit (prev.lists)
    take
    sortOn
    init
    last
    findFirst
    ;
  inherit (prev.strings) levenshteinAtMost levenshtein;

  inherit (final.fixedPoints) extends foldExtensions;
  inherit (final.attrsets) collapseScope;
  inherit (final.trivial) invoke;
  inherit (final.debug) attrPos;
in
rec {
  callWith =
    autoAttrs: callee: attrs:
    let
      calleeArgs = functionArgs callee;
      callAttrs = intersectAttrs calleeArgs autoAttrs // attrs;
      missing = findFirst (n: !(callAttrs ? ${n} || calleeArgs.${n})) null (attrNames calleeArgs);
    in
    if missing == null then
      callee callAttrs
    else
      let
        suggestions =
          pipe
            [ attrs autoAttrs ]
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

  callPackageWith = autoAttrs: fn: makeOverridable (callWith autoAttrs (invoke fn));

  makeScopeWith =
    pkgs: f:
    let
      self = f scope;
      legacyPackages = pkgs // self;
      scope = self // {
        inherit self legacyPackages;
        packages = collapseScope scope;
        __unfix__ = f;

        fuseScope = g: makeScopeWith pkgs (extends g f);
        foldScope = gs: makeScopeWith pkgs (extends (foldExtensions gs) f);
        rebaseScope = g: scope.makeScope (final: g final legacyPackages);
        makeScope = makeScopeWith legacyPackages;

        call = callWith legacyPackages;
        callPackage = fn: makeOverridable (scope.call (invoke fn));
        callPin = fn: scope.call (invoke fn) { };
      };
    in
    scope;
}
