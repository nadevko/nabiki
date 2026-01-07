self: lib:
let
  inherit (lib.fixedPoints) fix';
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.lists) foldr;
  inherit (lib.trivial) flip;

  inherit (self.trivial) compose;
in
rec {
  extendsWith =
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

  composeOverlaysListWith = flip foldr (final: prev: { });

  makeExtensibleWith =
    extender: extenderName: f:
    fix' (self: f self // { ${extenderName} = extender (makeExtensibleWith extender extenderName) f; });

  recExtends = extendsWith recursiveUpdate;
  composeRecOverlays = composeOverlaysWith recursiveUpdate;
  composeRecOverlaysList = composeOverlaysListWith composeRecOverlays;
  makeRecExtensibleWithCustomName = makeExtensibleWith (
    makeExtensible: f: compose makeExtensible (flip recExtends f)
  );
  makeRecExtensible = makeRecExtensibleWithCustomName "recExtend";

  rebase =
    g: prev:
    let
      final = g final prev;
    in
    final;

  rebase' = g: prev: rebase g prev // { __unfix__ = prev; };
}
