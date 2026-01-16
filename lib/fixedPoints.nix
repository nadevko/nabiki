self: lib:
let
  inherit (builtins) isFunction;

  inherit (lib.fixedPoints) fix fix';
  inherit (lib.lists) foldr;
  inherit (lib.trivial) flip mergeAttrs;

  inherit (self.attrsets) pointwisel pointwiser;
in
rec {
  rebase = g: prev: fix (final: g (prev // final) prev);
  rebase' = g: prev: fix' (final: g (prev // final) prev);

  extendWith =
    merger: g: f: final:
    let
      prev = f final;
    in
    merger prev (g final prev);

  composeOverlaysWith =
    merger: gBase: gOverride: final: prev:
    let
      base = gBase final prev;
    in
    merger base (gOverride final (merger prev base));

  composeOverlayListWith = flip foldr (final: prev: { });

  makeExtensibleWith =
    extends: extenderName: f:
    fix' (
      self: f self // { ${extenderName} = g: makeExtensibleWith extends extenderName (extends g f); }
    );

  safeExtendWith =
    makeExtensible: extenderName: extensible:
    extensible.${extenderName} or (makeExtensible (_: extensible)).${extenderName};

  extends = extendWith mergeAttrs;
  extendOverlays = composeOverlaysWith mergeAttrs;
  extendOverlayList = composeOverlayListWith extendOverlays;
  makeExtensibleAs = makeExtensibleWith extends;
  makeExtensible = makeExtensibleAs "extend";
  safeExtendAs = safeExtendWith makeExtensible;
  safeExtend = safeExtendAs "extend";

  patches = extendWith pointwiser;
  patchOverlays = composeOverlaysWith pointwiser;
  patchOverlayList = composeOverlayListWith patchOverlays;
  makePatchableAs = makeExtensibleWith patches;
  makePatchable = makePatchableAs "patch";
  safePatchAs = safeExtendWith makePatchable;
  safePatch = safePatchAs "patch";

  augments = extendWith pointwisel;
  augmentOverlays = composeOverlaysWith pointwisel;
  augmentOverlayList = composeOverlayListWith augmentOverlays;
  makeAugmentableAs = makeExtensibleWith augments;
  makeAugmentable = makeAugmentableAs "augment";
  safeAugmentAs = safeExtendWith makeAugmentable;
  safeAugment = safeAugmentAs "augment";

  wrapLibOverlay = fn: final: prev: {
    lib = safeAugment prev.lib (if isFunction fn then fn else import fn);
  };

  wrapLibOverlay' =
    libName: fn: final: prev:
    let
      overlay = if isFunction fn then fn else import fn;
    in
    {
      lib = safeAugment prev.lib overlay;
      ${libName} =
        if prev ? ${libName} then
          safeAugment prev.${libName} overlay
        else
          makeAugmentable (patches overlay (_: prev.${libName} or prev.lib));
    };
}
