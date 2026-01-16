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
    isFunction
    elem
    ;

  inherit (prev.attrsets) nameValuePair genAttrs mapAttrsToList;
  inherit (prev.strings) hasPrefix;

  inherit (final.trivial) compose id snd;
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
    base: override:
    base
    // mapAttrs (
      n: v: if isAttrs v && isAttrs (base.${n} or null) then v // base.${n} else base.${n} or v
    ) override;

  pointwiser =
    base: override:
    base
    // mapAttrs (n: v: if isAttrs v && isAttrs (base.${n} or null) then base.${n} // v else v) override;

  transposeAttrs =
    attrs:
    zipAttrsWith (_: listToAttrs) (mapAttrsToList (root: mapAttrs (_: nameValuePair root)) attrs);

  genAttrsBy =
    adapter: roots: generator:
    genAttrs roots (compose generator adapter);

  genTransposedAttrsBy =
    adapter: roots: generator:
    transposeAttrs (genAttrsBy adapter roots generator);

  perRootIn = genTransposedAttrsBy id;

  perSystemIn =
    systems: source: config:
    genTransposedAttrsBy (
      system:
      if config == null then
        source.legacyPackages.${system}
      else if isFunction config then
        import source (config system)
      else
        import source (config // { inherit system; })
    ) systems;

  perSystem = flake: perSystemIn (attrNames flake.legacyPackages) flake;

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

  flattenAttrs =
    {
      include ?
        _: _: _:
        true,
      recurseInto ? _: _: isAttrs,
      rootDepth ? 0,

      getRootPrefix ? getRootKey,
      getRootKey ? id,
      mergePrefix ? mergeKey,
      mergeKey ? prev: name: "${prev}-${name}",
    }:
    let
      recurse =
        depth: prefix:
        bindAttrs (
          name: value:
          (if include depth name value then [ (nameValuePair (mergeKey prefix name) value) ] else [ ])
          ++ (
            if recurseInto depth name value then recurse (depth + 1) (mergePrefix prefix name) value else [ ]
          )
        );
    in
    mbindAttrs (
      name: value:
      (if include rootDepth name value then [ (nameValuePair (getRootKey name) value) ] else [ ])
      ++ (
        if recurseInto rootDepth name value then recurse (rootDepth + 1) (getRootPrefix name) value else [ ]
      )
    );

  genLibAliasesWith =
    {
      blacklist ? [
        "systems"
        "licenses"
        "fetchers"
        "generators"
        "cli"
        "network"
        "kernel"
        "types"
        "maintainers"
        "teams"
      ],
    }@config:
    flattenAttrs (
      {
        include =
          depth: name: value:
          depth == 1 && !hasPrefix "_" name && !isAttrs value;
        recurseInto =
          depth: name: value:
          depth == 0 && !elem name blacklist && isAttrs value;
        getRootKey = id;
        mergeKey = snd;
      }
      // removeAttrs config [ "blacklist" ]
    );

  genLibAliases = genLibAliasesWith { };
}
