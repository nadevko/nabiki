final: prev:
let
  inherit (builtins) isFunction length elemAt;

  inherit (prev.fixedPoints) fix fix';
  inherit (prev.lists) foldr;
  inherit (prev.trivial) flip mergeAttrs;

  inherit (final.attrsets) pointwisel pointwiser;
in
rec {
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
    merger: gBase: gOverride: final: prev:
    let
      base = gBase final prev;
    in
    merger base (gOverride final (merger prev base));

  makeFold = flip foldr (final: prev: { });

  makeTemplate =
    extends: name: f:
    fix' (self: f self // { ${name} = g: makeTemplate extends name (extends g f); });

  forceMix =
    makeExtensible: name: extensible:
    extensible.${name} or (makeExtensible (_: extensible)).${name};

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

  augmentLib = fn: final: prev: {
    lib = forceAugment prev.lib (if isFunction fn then fn else import fn);
  };

  augmentLibAs =
    libName: fn: final: prev:
    let
      overlay = if isFunction fn then fn else import fn;
    in
    {
      lib = forceAugment prev.lib overlay;
      ${libName} =
        if prev ? ${libName} then
          forceAugment prev.${libName} overlay
        else
          makeAugmentable (patches overlay (_: prev.${libName} or prev.lib));
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
