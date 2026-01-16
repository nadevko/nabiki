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
  inherit (lib.trivial) flip;

  inherit (self.fixedPoints) extends composeOverlayList;
  inherit (self.trivial) compose;
  inherit (self.attrsets) collapsePackagesSep collapsePackages;
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
    scope: newScope:
    let
      self = scope self // {
        inherit scope;

        newScope = scope: newScope (self // scope);
        callPackage = self.newScope { };
        callScope = callScopeWith self;

        overrideScope = g: makeScope (extends g scope) newScope;
        overrideScopeList = compose self.overrideScope composeOverlayList;
        rebaseScope = scope: makeScope scope self.newScope;
      };
    in
    self;
}
