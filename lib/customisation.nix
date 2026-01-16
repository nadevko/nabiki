final: prev:
let
  inherit (builtins)
    attrNames
    isFunction
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

  inherit (final.fixedPoints) extends composeOverlayList;
  inherit (final.trivial) compose;
  inherit (final.debug) attrPos;
in
rec {
  callPackageWith =
    autoAttrs: fn: attrsAsIs:
    let
      callee = if isFunction fn then fn else import fn;
      requestedAttrs = functionArgs callee;
      callArg = intersectAttrs requestedAttrs autoAttrs // attrsAsIs;

      missing = findFirst (n: !(requestedAttrs.${n} || callArg ? ${n})) null (attrNames requestedAttrs);
    in
    if missing == null then
      makeOverridable callee callArg
    else
      let
        suggestions =
          pipe
            [ attrsAsIs autoAttrs ]
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

        pos = attrPos missing requestedAttrs;
      in
      throw "kasumi.lib.customisation.callPackageWith: Function called without required argument '${missing}' at ${pos}${didYouMean}";

  callScopeWith =
    { newScope, ... }:
    fn: override:
    makeScope newScope (self: newScope { inherit (self) newScope callPackage; } fn override);

  makeScope =
    newScope: scope:
    let
      packagesWith = scope self;
      self = packagesWith // {
        inherit scope packagesWith;

        newScope = scope: newScope (self // scope);
        callPackage = self.newScope { };
        callScope = callScopeWith self;

        overrideScope = g: makeScope newScope (extends g scope);
        overrideScopeList = compose self.overrideScope composeOverlayList;
        rebaseScope = makeScope self.newScope;
      };
    in
    self;
}
