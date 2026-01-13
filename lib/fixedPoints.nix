self: lib:
let
  inherit (builtins) isFunction;

  inherit (lib.fixedPoints) fix';
  inherit (lib.lists) foldr;
  inherit (lib.trivial) flip mergeAttrs;
  inherit (lib.attrsets) recursiveUpdate;
in
rec {
  extendBy =
    merger: g: f: final:
    let
      prev = f final;
    in
    merger prev (g final prev);

  composeOverlaysBy =
    merger: gBase: gOverride: final: prev:
    let
      base = gBase final prev;
    in
    merger base (gOverride final (merger prev base));

  composeOverlayListBy = flip foldr (final: prev: { });

  makeExtensibleBy =
    extends: extenderName: f:
    fix' (
      self: f self // { ${extenderName} = g: makeExtensibleBy extends extenderName (extends g f); }
    );

  extends = extendBy mergeAttrs;
  composeOverlays = composeOverlaysBy mergeAttrs;
  composeOverlayList = composeOverlayListBy composeOverlays;
  makeExtensibleAs = makeExtensibleBy extends;
  makeExtensible = makeExtensibleAs "extend";

  rebase =
    g: prev:
    let
      final = g (prev // final) prev;
    in
    final;

  rebase' = g: prev: rebase g prev // { __unfix__ = prev; };

  wrapLibOverlay = libName: fn: final: prev: {
    lib = prev.lib.extend (_: prev: recursiveUpdate final.${libName} prev);
    ${libName} = fix' (self: (if isFunction fn then fn else import fn) self prev.lib);
  };
}
