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
    isAttrs
    ;
  inherit (prev.lists)
    take
    sortOn
    init
    last
    findFirst
    ;
  inherit (prev.strings) levenshteinAtMost levenshtein;
  inherit (prev.customisation) makeOverridable;
  inherit (prev.attrsets) nameValuePair isDerivation;
  inherit (prev.trivial) id;

  inherit (final.meta) isSupportedDerivation;
  inherit (final.trivial) invoke compose;
  inherit (final.overlays) lay foldLay;
  inherit (final.debug) attrPos;
  inherit (final.attrsets) mbindAttrs bindAttrs;
in
rec {
  callWith =
    context: f: overrides:
    let
      callee = invoke f;
      calleeArgs = functionArgs callee;
      callAttrs = intersectAttrs calleeArgs context // overrides;
      missing = findFirst (n: !(callAttrs ? ${n} || calleeArgs.${n})) null <| attrNames calleeArgs;
    in
    if missing == null then
      callee callAttrs
    else
      let
        suggestions =
          [
            overrides
            context
          ]
          |> concatMap attrNames
          |> filter (levenshteinAtMost 2 missing)
          |> sortOn (levenshtein missing)
          |> take 3;

        didYouMean =
          if suggestions == [ ] then
            ""
          else if length suggestions == 1 then
            ", did you mean '${head suggestions}'?"
          else
            ", did you mean '${concatStringsSep "', '" <| init suggestions}' or '${last suggestions}'?";

        pos = attrPos missing calleeArgs;
      in
      abort "kasumi.lib.di.callWith: Function called without required argument '${missing}' at ${pos}${didYouMean}";

  callPackageBy = call: f: invoke f |> call |> makeOverridable;
  callPackageWith = compose callPackageBy callWith;

  makeScopeWith =
    prev: __rattrs:
    let
      pkgs = prev // scope;
      extension = __rattrs pkgs;

      scope = extension // {
        inherit
          pkgs
          extension
          scope
          __rattrs
          ;

        call = callWith pkgs;
        callPackage = callPackageBy scope.call;
      };
    in
    scope;

  fuseScope = g: scope: makeScopeWith scope.pkgs <| lay g scope.__rattrs;
  foldScope = gs: scope: makeScopeWith scope.pkgs <| lay (foldLay gs) scope.__rattrs;
  rebaseScope = g: scope: makeScopeWith scope.pkgs (self: g self scope.pkgs);

  collapseScopeWith =
    {
      include ? isDerivation,
      sep ? "-",
    }:
    scope:
    let
      makeRecurse =
        concat: n: v:
        if include v then
          [ (nameValuePair (concat n) v) ]
        else if isAttrs v && v.recurseForDerivations or false then
          recurse (concat n) (v.extension or v)
        else
          [ ];

      recurse = prefix: bindAttrs <| makeRecurse (n: "${prefix}${sep}${n}");
    in
    mbindAttrs (makeRecurse id) (scope.extension or scope);

  collapseScopeSep = sep: collapseScopeWith { inherit sep; };
  collapseScope = collapseScopeSep "-";

  collapseSupportedSep =
    sep: system:
    collapseScopeWith {
      include = isSupportedDerivation system;
      inherit sep;
    };
  collapseSupportedBy = collapseSupportedSep "-";
}
