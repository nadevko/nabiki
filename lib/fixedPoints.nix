self: lib:
let
  inherit (builtins) isFunction;

  inherit (lib.fixedPoints) fix';
  inherit (lib.lists) foldr;
  inherit (lib.trivial) flip mergeAttrs;

  inherit (self.attrsets) pointwisel pointwiser;
in
rec {
  rebase =
    g: prev:
    let
      final = g (prev // final) prev;
    in
    final;

  rebase' = g: prev: rebase g prev // { __unfix__ = prev; };

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

  patches = extendBy pointwiser;
  patchOverlays = composeOverlaysBy pointwiser;
  patchOverlayList = composeOverlayListBy patchOverlays;
  makePatchableAs = makeExtensibleBy patches;
  makePatchable = makePatchableAs "patch";

  augments = extendBy pointwisel;
  augmentOverlays = composeOverlaysBy pointwisel;
  augmentOverlayList = composeOverlayListBy augmentOverlays;
  makeAugmentableAs = makeExtensibleBy augments;
  makeAugmentable = makeAugmentableAs "augment";

  augmentLib = lib: lib.augment or (makeAugmentable (_: lib)).augment;

  wrapLibOverlay = fn: final: prev: {
    lib = augmentLib prev.lib (if isFunction fn then fn else import fn);
  };

  wrapLibOverlay' =
    libName: fn: final: prev:
    let
      overlay = if isFunction fn then fn else import fn;
    in
    {
      lib = augmentLib prev.lib overlay;
      ${libName} = fix' (patches overlay (_: prev.${libName} or prev.lib));
    };
}
