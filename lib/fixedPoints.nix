self: lib:
let
  inherit (lib.fixedPoints) fix';
  inherit (lib.attrsets) recursiveUpdate;
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

  composeExtensionsWith =
    merger: gBase: gOverride: final: prev:
    let
      base = gBase final prev;
    in
    merger base (gOverride final (merger prev base));

  composeExtensionsListWith = flip foldr (final: prev: { });

  makeExtensibleWith =
    extender: extenderName: f:
    fix' (self: f self // { ${extenderName} = extender (makeExtensibleWith extender extenderName) f; });

  recExtends = extendsWith recursiveUpdate;
  composeRecExtensions = composeExtensionsWith recursiveUpdate;
  composeRecExtensionsList = composeExtensionsListWith composeRecExtensions;
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

  composePrivateWith =
    merger: gPrivate: gPublic: final: prev:
    let
      prev' = merger prev (gPrivate final' prev');
      final' = merger prev' final;
    in
    gPublic final' prev';

  composePrivate = composePrivateWith mergeAttrs;
  composeRecPrivate = composePrivateWith recursiveUpdate;
}
