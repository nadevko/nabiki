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
    unsafeGetAttrPos
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

  inherit (self.fixedPoints) extends;
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

      attrPos = unsafeGetAttrPos arg requestedAttrs;
      loc = if attrPos != null then attrPos.file + ":" + toString attrPos.line else "<unknown location>";
    in
    ''Function called without required argument "${arg}" at ${loc}${prettySuggestions}'';

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
    makeScope newScope (final: newScope { inherit (final) newScope callPackage; } fn override);

  makeLegacyPackagesAs =
    extenderName: f:
    fix' (
      pkgs:
      f pkgs
      // {
        inherit pkgs;
        callPackage = pkgs.newScope { };
        newScope = extra: callPackageWith (pkgs // extra);
        ${extenderName} = g: makeLegacyPackagesAs extenderName (extends g f);
      }
    );

  makeLegacyPackages = makeLegacyPackagesAs "extend";

  makeScope =
    f: prevScope:
    fix' (
      self:
      f self
      // {
        newScope = scope: prevScope (self // scope);
        callPackage = self.newScope { };
        callScope = callScopeWith self;
        extendScope = g: makeScope prevScope (extends g f);
        rebaseScope = makeScope self.newScope;
        packagesWith = f;
        packages = f self;
      }
    );
}
