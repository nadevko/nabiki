self: lib:
let
  inherit (builtins)
    isAttrs
    zipAttrsWith
    listToAttrs
    attrValues
    mapAttrs
    attrNames
    intersectAttrs
    partition
    head
    tail
    isFunction
    concatLists
    filter
    ;

  inherit (lib.attrsets) nameValuePair genAttrs mapAttrsToList;
  inherit (lib.trivial) flip;
  inherit (lib.strings) hasPrefix;

  inherit (self.trivial) compose;
  inherit (self.lists) subtractLists;
in
rec {
  _internal = {
    getAliasExcludes =
      set: (set._aliasExcludes or [ ]) ++ (filter (e: hasPrefix "_" e) (attrNames set));
  };

  findClosestByPath =
    pattern:
    let
      find =
        nodesPath: deepest: set:
        let
          next = head nodesPath;
          nextDeepest = set.${pattern} or deepest;
          nextSet = set.${next} or null;
        in
        if !isAttrs set then
          deepest
        else if nodesPath == [ ] then
          nextDeepest
        else if nextSet == null then
          nextDeepest
        else
          find (tail nodesPath) nextDeepest nextSet;
    in
    find;

  mapAttrsIntersection =
    pred: left: right:
    mapAttrs (name: pred name left.${name}) (intersectAttrs left right);

  bind = name: value: { ${name} = value; };

  partitionAttrs =
    pred: set:
    let
      items = partition (n: pred n set.${n}) (attrNames set);
      build = flip genAttrs (n: set.${n});
    in
    {
      right = build items.right;
      wrong = build items.wrong;
    };

  pointwisel =
    base: extension:
    base
    // mapAttrs (
      n: v:
      if isAttrs v && isAttrs (base.${n} or null) then
        v // base.${n}
      else if base ? ${n} then
        base.${n}
      else
        v
    ) extension;

  pointwiser =
    base: extension:
    base
    // mapAttrs (
      n: v: if isAttrs v && isAttrs (base.${n} or null) then base.${n} // v else v
    ) extension;

  transposeAttrs =
    attrs:
    zipAttrsWith (_: listToAttrs) (
      attrValues (mapAttrs (root: mapAttrs (_: nameValuePair root)) attrs)
    );

  transposeMapAttrs =
    reader: roots: generator:
    transposeAttrs (genAttrs roots (compose generator reader));

  perRootIn = transposeMapAttrs (x: x);

  perSystemIn =
    systems: source: config:
    transposeMapAttrs (
      system:
      if config == null then
        source.legacyPackages.${system}
      else if isFunction config then
        config system
      else
        import source (config // { inherit system; })
    ) systems;

  perSystem = flake: perSystemIn (attrNames flake.legacyPackages) flake;

  makeAttrsAliases =
    aliases: set:
    listToAttrs (
      flatMapAttrs (
        category:
        map (name: {
          inherit name;
          value = (set.${category} or { }).${name};
        })
      ) aliases
    );

  addAttrsAliases = aliases: set: makeAttrsAliases aliases set // set;

  getAliasList =
    category: set:
    let
      includes = set._aliasIncludes or attrNames set;
      excludes = _internal.getAliasExcludes set;
      aliases = set._aliases or (subtractLists includes excludes);
    in
    map (name: {
      inherit name;
      inherit category;
      value = set.${name};
    }) aliases;

  addAttrsAliasesWith' =
    getAliasList:
    morphAttrs (
      category: set:
      if isAttrs set then
        getAliasList category set
        ++ [ (nameValuePair category (removeAttrs set _internal.getAliasExcludes set)) ]
      else
        [ (nameValuePair category set) ]
    );

  addAttrsAliases' = addAttrsAliasesWith' getAliasList;

  makeCallSetWith =
    caller: getOverride: set: final:
    mapAttrs (name: flip final.${caller} (getOverride final name)) set;

  makeCallPackageSet = makeCallSetWith "callPackage";
  makeCallScopeSet = makeCallSetWith "callScope";

  flatMapAttrs = pred: set: concatLists (mapAttrsToList pred set);
  morphAttrs = pred: set: listToAttrs (flatMapAttrs pred set);

  shouldRecurseForDerivations = x: isAttrs x && x.recurseForDerivations or false;
}
