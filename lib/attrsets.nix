final: prev:
let
  inherit (builtins)
    concatMap
    isAttrs
    zipAttrsWith
    listToAttrs
    mapAttrs
    attrNames
    intersectAttrs
    head
    tail
    elem
    ;

  inherit (prev.attrsets) nameValuePair genAttrs mapAttrsToList;
  inherit (prev.strings) hasPrefix;

  inherit (final.trivial) compose snd;
in
rec {
  singletonAttrs = name: value: { ${name} = value; };
  bindAttrs = pred: set: concatMap (name: pred name set.${name}) (attrNames set);
  mbindAttrs = pred: set: listToAttrs (bindAttrs pred set);

  mapAttrsIntersection =
    pred: left: right:
    mapAttrs (name: pred name left.${name}) (intersectAttrs left right);

  partitionAttrs = pred: set: {
    right = bindAttrs (
      name: value: if pred name value then [ (nameValuePair name value) ] else [ ]
    ) set;
    wrong = bindAttrs (
      name: value: if !pred name value then [ (nameValuePair name value) ] else [ ]
    ) set;
  };

  pointwisel =
    base: augment:
    base
    // mapAttrs (
      n: v: if isAttrs v && isAttrs (base.${n} or null) then v // base.${n} else base.${n} or v
    ) augment;

  pointwiser =
    base: override:
    base
    // mapAttrs (n: v: if isAttrs v && isAttrs (base.${n} or null) then base.${n} // v else v) override;

  transposeAttrs = compose (zipAttrsWith (_: listToAttrs)) (
    mapAttrsToList (root: mapAttrs (_: nameValuePair root))
  );

  genAttrsBy =
    adapter: roots: generator:
    genAttrs roots (compose generator adapter);

  genTransposedAttrsBy =
    adapter: roots: generator:
    transposeAttrs (genAttrsBy adapter roots generator);

  foldPathWith =
    pred: default: pattern:
    let
      recurse =
        deepest: nodesPath: set:
        if !isAttrs set then
          deepest
        else
          let
            nextDeepest = if set ? ${pattern} then pred deepest set.${pattern} else deepest;
            nextSet = set.${head nodesPath} or null;
          in
          if nodesPath == [ ] || nextSet == null then
            nextDeepest
          else
            recurse nextDeepest (tail nodesPath) nextSet;
    in
    recurse default;

  foldPath = foldPathWith snd;

  genLibAliasesWithoutPred =
    exclude:
    mbindAttrs (
      name: value:
      if !isAttrs value || exclude name value then
        [ ]
      else
        bindAttrs (
          name: value: if isAttrs value || hasPrefix "_" name then [ ] else [ (nameValuePair name value) ]
        ) value
    );

  genLibAliasesWithout =
    blacklist: genLibAliasesWithoutPred (name: _: elem name blacklist || hasPrefix "_" name);

  genLibAliases = genLibAliasesWithout [
    "systems"
    "licenses"
    "fetchers"
    "generators"
    "cli"
    "network"
    "kernel"
    "types"
    "maintainers"
    "features"
    "teams"
  ];
}
