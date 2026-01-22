final: prev:
let
  inherit (builtins) isFunction;

  inherit (prev.lists) foldr;
  inherit (prev.trivial) flip mergeAttrs;

  inherit (final.attrsets) pointwisel pointwiser;
  inherit (final.trivial) fix fix';
in
rec {
  makeMixMerge =
    merger: g: rattrs: final:
    let
      prev = rattrs final;
    in
    merger prev (g final prev);

  makeMixRebaseWith =
    fix: merger: g: prev:
    fix (final: g (merger prev final) prev);

  makeMixRebase = makeMixRebaseWith fix;
  makeMixRebase' = makeMixRebaseWith fix';

  makeMixFuse =
    merger: g: h: final: prev:
    let
      base = g final prev;
    in
    merger base (h final (merger prev base));

  makeMixFold = flip foldr (final: prev: { });

  rebaseSelf = g: prev: fix (self: g self prev);
  rebaseSelf' = g: prev: fix' (self: g self prev);

  mix = makeMixMerge mergeAttrs;
  rebaseMix = makeMixRebase mergeAttrs;
  rebaseMix' = makeMixRebase' mergeAttrs;
  fuseMix = makeMixFuse mergeAttrs;
  foldMix = makeMixFold fuseMix;

  mixr = makeMixMerge pointwiser;
  rebaseMixr = makeMixRebase pointwiser;
  rebaseMixr' = makeMixRebase' pointwiser;
  fuseMixr = makeMixFuse pointwiser;
  foldMixr = makeMixFold fuseMixr;

  mixl = makeMixMerge pointwisel;
  rebaseMixl = makeMixRebase pointwisel;
  rebaseMixl' = makeMixRebase' pointwisel;
  fuseMixl = makeMixFuse pointwisel;
  foldMixl = makeMixFold fuseMixl;

  toMixin =
    g:
    if isFunction g then
      final: prev:
      let
        prev' = g prev;
      in
      if isFunction prev' then g final prev else prev'
    else
      final: prev: g;
}
