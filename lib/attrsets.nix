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
  inherit (lib.strings) hasPrefix;

  inherit (self.trivial) compose;
  inherit (self.lists) subtractLists;
in
rec {
  _internal = {
    getAliasExcludes =
      set: (set._aliasExcludes or [ ]) ++ (filter (e: hasPrefix "_" e) (attrNames set));
  };

  flatMapAttrs = pred: set: concatLists (mapAttrsToList pred set);
  morphAttrs = pred: set: listToAttrs (flatMapAttrs pred set);

  mapAttrsIntersection =
    pred: left: right:
    mapAttrs (name: pred name left.${name}) (intersectAttrs left right);

  bind = name: value: { ${name} = value; };

  partitionAttrs =
    pred: set:
    let
      items = map (name: nameValuePair name set.${name}) (attrNames set);
      parts = partition ({ name, value }: pred name value) items;
    in
    {
      right = listToAttrs parts.right;
      wrong = listToAttrs parts.wrong;
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

  pivotAttrs =
    attrs:
    zipAttrsWith (_: listToAttrs) (
      attrValues (mapAttrs (root: mapAttrs (_: nameValuePair root)) attrs)
    );

  pivotMapAttrs =
    reader: roots: generator:
    pivotAttrs (genAttrs roots (compose generator reader));

  perRootIn = pivotMapAttrs (x: x);

  perSystemIn =
    systems: source: config:
    pivotMapAttrs (
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
    morphAttrs (
      category:
      map (name: {
        inherit name;
        value = (set.${category} or { }).${name};
      })
    ) aliases;

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
        ++ [ (nameValuePair category (removeAttrs set (_internal.getAliasExcludes set))) ]
      else
        [ (nameValuePair category set) ]
    );

  addAttrsAliases' = addAttrsAliasesWith' getAliasList;

  foldPathWith =
    pred: default: pattern:
    let
      find =
        deepest: nodesPath: set:
        let
          nextDeepest = if set ? ${pattern} then pred deepest set.${pattern} else deepest;
          nextSet = set.${head nodesPath} or null;
        in
        if !isAttrs set then
          deepest
        else if nodesPath == [ ] || nextSet == null then
          nextDeepest
        else
          find nextDeepest (tail nodesPath) nextSet;
    in
    find default;
}
