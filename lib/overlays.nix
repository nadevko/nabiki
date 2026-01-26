final: prev:
let
  inherit (builtins) isFunction;

  inherit (prev.lists) foldr;
  inherit (prev.trivial) flip mergeAttrs;

  inherit (final.attrsets) pointwisel pointwiser;
  inherit (final.trivial) fix fix';
in
rec {
  makeLayMerge =
    merger: g: rattrs: final:
    let
      prev = rattrs final;
    in
    merger prev (g final prev);

  makeLayRebaseWith =
    fix: merger: g: prev:
    fix (final: g (merger prev final) prev);

  makeLayRebase = makeLayRebaseWith fix;
  makeLayRebase' = makeLayRebaseWith fix';

  makeLayFuse =
    merger: g: h: final: prev:
    let
      base = g final prev;
    in
    merger base (h final (merger prev base));

  makeLayFold = flip foldr (final: prev: { });

  rebaseSelf = g: prev: fix (self: g self prev);
  rebaseSelf' = g: prev: fix' (self: g self prev);

  lay = makeLayMerge mergeAttrs;
  rebaseLay = makeLayRebase mergeAttrs;
  rebaseLay' = makeLayRebase' mergeAttrs;
  fuseLay = makeLayFuse mergeAttrs;
  foldLay = makeLayFold fuseLay;

  layr = makeLayMerge pointwiser;
  rebaseLayr = makeLayRebase pointwiser;
  rebaseLayr' = makeLayRebase' pointwiser;
  fuseLayr = makeLayFuse pointwiser;
  foldLayr = makeLayFold fuseLayr;

  layl = makeLayMerge pointwisel;
  rebaseLayl = makeLayRebase pointwisel;
  rebaseLayl' = makeLayRebase' pointwisel;
  fuseLayl = makeLayFuse pointwisel;
  foldLayl = makeLayFold fuseLayl;

  overlayr =
    g:
    if isFunction g then
      final: prev:
      let
        prev' = g prev;
      in
      if isFunction prev' then g final prev else prev'
    else
      final: prev: g;

  overlayl =
    g:
    if isFunction g then
      final: prev:
      let
        final' = g final;
      in
      if isFunction final' then final' prev else final'
    else
      final: prev: g;
}
