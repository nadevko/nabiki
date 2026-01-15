self: lib:
let
  inherit (builtins)
    attrNames
    isFunction
    functionArgs
    intersectAttrs
    filter
    length
    elemAt
    concatStringsSep
    head
    ;
  inherit (lib.fixedPoints) fix';
  inherit (lib.trivial) pipe;
  inherit (lib.customisation) makeOverridable;
  inherit (lib.lists)
    take
    sortOn
    init
    last
    ;
  inherit (lib.strings) levenshteinAtMost levenshtein;

  inherit (self.fixedPoints) extends composeOverlayList;
  inherit (self.trivial) compose getAttrPosMessage;
in
rec {
  getOverride =
    baseOverride: overrides: name:
    baseOverride // overrides.${name} or { };

  getCallErrorMessage =
    allNames: requestedAttrs: arg:
    let
      suggestions = pipe allNames [
        (filter (levenshteinAtMost 2 arg))
        (sortOn (levenshtein arg))
        (take 3)
        (map (x: ''"${x}"''))
      ];

      prettySuggestions =
        if suggestions == [ ] then
          ""
        else if length suggestions == 1 then
          ", did you mean ${elemAt suggestions 0}?"
        else
          ", did you mean ${concatStringsSep ", " (init suggestions)} or ${last suggestions}?";

      pos = getAttrPosMessage arg requestedAttrs;
    in
    ''Function called without required argument "${arg}" at ${pos}${prettySuggestions}'';

  callPackageWith =
    autoAttrs: fn: attrsAsIs:
    let
      callee = if isFunction fn then fn else import fn;
      requestedAttrs = functionArgs callee;
      callArg = intersectAttrs requestedAttrs autoAttrs // attrsAsIs;
      missing = filter (n: !(requestedAttrs.${n} || callArg ? ${n})) (attrNames requestedAttrs);
    in
    if missing == [ ] then
      makeOverridable callee callArg
    else
      abort "kasumi.lib.customisation.callPackageWith: ${
        getCallErrorMessage (attrNames (autoAttrs // attrsAsIs)) requestedAttrs (head missing)
      }";

  callScopeWith =
    { newScope, ... }:
    fn: override:
    makeScope (self: newScope { inherit (self) newScope callPackage; } fn override) newScope;

  makeScope =
    f: prevScope:
    fix' (
      scope:
      f scope
      // {
        _type = "scope";
        recurseForDerivations = true;

        inherit f;
        packages = f scope;

        newScope = extra: prevScope (scope // extra);
        callPackage = scope.newScope { };
        callScope = callScopeWith scope;

        overrideScope = g: makeScope prevScope (extends g f);
        overrideScopeList = compose scope.overrideScope composeOverlayList;
        rebaseScope = makeScope scope.newScope;
      }
    );
}
