self: lib:
let
  inherit (lib.fixedPoints) fix';
  inherit (lib.lists) foldr;
  inherit (lib.trivial) flip mergeAttrs;

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

  composeOverlayListWith = flip foldr (final: prev: { });

  makeExtensibleWith =
    extender: extenderName: f:
    fix' (self: f self // { ${extenderName} = extender (makeExtensibleWith extender extenderName) f; });

  extends = extendsWith mergeAttrs;
  composeOverlays = composeOverlaysWith mergeAttrs;
  composeOverlayList = composeOverlayListWith composeOverlays;
  makeExtensibleAs = makeExtensibleWith (makeExtensible: f: compose makeExtensible (flip extends f));
  makeExtensible = makeExtensibleAs "extend";

  rebase =
    g: prev:
    let
      final = g (prev // final) prev;
    in
    final;

  rebase' = g: prev: rebase g prev // { __unfix__ = prev; };

  toOverlay =
    f: final: prev:
    f;
  wrapFinal =
    f: final: prev:
    f final;
  wrapPrev =
    f: final: prev:
    f prev;
}
