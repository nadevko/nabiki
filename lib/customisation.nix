self: lib:
let
  inherit (builtins)
    attrNames
    isFunction
    functionArgs
    intersectAttrs
    filter
    head
    ;
  inherit (lib.fixedPoints) fix';
  inherit (lib.customisation) makeOverridable;

  inherit (self.fixedPoints) extends composeOverlayList;
  inherit (self.trivial) compose;
  inherit (self.debug._internal) getCallErrorMessage;
in
rec {
  getOverride =
    baseOverride: overrides: name:
    baseOverride // overrides.${name} or { };

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
      throw "kasumi.lib.customisation.callPackageWith: ${
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
