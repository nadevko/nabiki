self: lib:
let
  inherit (lib.fixedPoints) fix';
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) foldr;
  inherit (lib.trivial) flip;
in
rec {
  extendsWith =
    merger: overlay: fixedPoint: final:
    let
      prev = fixedPoint final;
    in
    merger prev (overlay final prev);

  composeExtensionsWith =
    merger: baseOverlay: overrideOverlay: final: prev:
    let
      base = baseOverlay final prev;
      overridePrev = merger prev base;
    in
    merger base (overrideOverlay final overridePrev);

  composeExtensionsListWith = flip foldr (final: prev: { });

  makeExtensibleWith =
    extender: extenderName: fixedPoint:
    fix' (
      self:
      fixedPoint self
      // {
        ${extenderName} = extender (makeExtensibleWith extender extenderName) fixedPoint;
      }
    );

  recExtends = extendsWith recursiveUpdate;
  composeRecExtensions = composeExtensionsWith recursiveUpdate;
  composeRecExtensionsList = composeExtensionsListWith composeRecExtensions;
  makeRecExtensibleWithCustomName = makeExtensibleWith (
    makeExtensible: fixedPoint: overlay:
    makeExtensible (recExtends overlay fixedPoint)
  );
  makeRecExtensible = makeRecExtensibleWithCustomName "recExtend";

  rebase =
    overlay: prev:
    let
      final = overlay final prev;
    in
    final;

  rebase' = overlay: prev: rebase overlay prev // { __unfix__ = prev; };
}
