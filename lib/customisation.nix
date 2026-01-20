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

  inherit (final.trivial) invoke;
  inherit (final.debug) attrPos;
in
rec {
  call =
    autoAttrs: fn: attrsAsIs:
    let
      callee = invoke fn;
      requestedAttrs = functionArgs callee;
      callArg = intersectAttrs requestedAttrs autoAttrs // attrsAsIs;

      missing = findFirst (n: !(callArg ? ${n} || requestedAttrs.${n})) null (attrNames requestedAttrs);
    in
    if missing == null then
      callee callArg
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
      throw "kasumi.lib.customisation.call: Function called without required argument '${missing}' at ${pos}${didYouMean}";

  callPackageWith = ctx: fn: makeOverridable (call ctx fn);
}
