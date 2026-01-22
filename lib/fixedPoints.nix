final: prev:
let
  inherit (builtins) length elemAt isFunction;

  inherit (prev.fixedPoints) fix fix';
  inherit (prev.lists) foldr;
  inherit (prev.trivial) flip mergeAttrs;

  inherit (final.attrsets) pointwisel pointwiser;
  inherit (final.trivial) invoke;
in
rec {
  toMixin =
    f:
    if isFunction f then
      final: prev:
      let
        self = f final;
      in
      if isFunction self then self prev else self
    else
      final: prev: f;

  rebase = g: prev: fix (self: invoke g self prev);
  rebase' = g: prev: fix' (self: invoke g self prev);

  makeMixer =
    merger: g: f: final:
    let
      prev = f final;
    in
    merger prev (g final prev);

  makeRebase =
    merger: g: prev:
    fix (final: g (merger prev final) prev);

  makeRebase' =
    merger: g: prev:
    fix' (final: g (merger prev final) prev);

  makeFuse =
    merger: g: h: final: prev:
    let
      base = g final prev;
    in
    merger base (h final (merger prev base));

  makeFold = flip foldr (final: prev: { });

  makeTemplate =
    extends: name: f:
    fix' (self: f self // { ${name} = g: makeTemplate extends name (extends g f); });

  forceMix =
    makeTemplate: mix: template:
    template.${mix} or (makeTemplate (_: template)).${mix};

  extends = makeMixer mergeAttrs;
  rebaseExtension = makeRebase mergeAttrs;
  rebaseExtension' = makeRebase' mergeAttrs;
  fuseExtensions = makeFuse mergeAttrs;
  foldExtensions = makeFold fuseExtensions;
  makeExtensibleAs = makeTemplate extends;
  makeExtensible = makeExtensibleAs "extend";
  forceExtendAs = forceMix makeExtensible;
  forceExtend = forceExtendAs "extend";

  patches = makeMixer pointwiser;
  rebasePatch = makeRebase pointwiser;
  rebasePatch' = makeRebase' pointwiser;
  fusePatches = makeFuse pointwiser;
  foldPatches = makeFold fusePatches;
  makePatchableAs = makeTemplate patches;
  makePatchable = makePatchableAs "patch";
  forcePatchAs = forceMix makePatchable;
  forcePatch = forcePatchAs "patch";

  augments = makeMixer pointwisel;
  rebaseAugment = makeRebase pointwisel;
  rebaseAugment' = makeRebase' pointwisel;
  fuseAugments = makeFuse pointwisel;
  foldAugments = makeFold fuseAugments;
  makeAugmentableAs = makeTemplate augments;
  makeAugmentable = makeAugmentableAs "augment";
  forceAugmentAs = forceMix makeAugmentable;
  forceAugment = forceAugmentAs "augment";

  augmentLib = fn: final: prev: { lib = forceAugment prev.lib (invoke fn); };

  augmentLibAs =
    libName: fn: final: prev:
    let
      g = invoke fn;
    in
    {
      lib = forceAugment prev.lib g;
      ${libName} =
        if prev ? ${libName} then
          forceAugment prev.${libName} g
        else
          makeAugmentable (patches g (_: prev.${libName} or prev.lib));
    };

  dfold =
    transform: getInitial: getFinal: itemsList:
    let
      totalItems = length itemsList;
      linkStage =
        previousStage: index:
        if index == totalItems then
          getFinal previousStage
        else
          let
            thisStage = transform previousStage (elemAt itemsList index) nextStage;
            nextStage = linkStage thisStage (index + 1);
          in
          thisStage;
      initialStage = getInitial firstStage;
      firstStage = linkStage initialStage 0;
    in
    firstStage;
}
