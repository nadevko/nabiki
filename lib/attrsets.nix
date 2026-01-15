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
    ;

  inherit (lib.attrsets) nameValuePair genAttrs mapAttrsToList;
  inherit (lib.trivial) flip;

  inherit (self.trivial) compose;
  inherit (self.lists) subtractLists;
in
rec {
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

  getAliasesWith =
    {
      includes,
      excludes,
      forceExcludes,
    }:
    name: v:
    map (fnName: nameValuePair fnName v.${fnName}) (
      v._aliasForce or (subtractLists includes (excludes ++ forceExcludes))
    );

  makeAttrsAliasesWith' =
    {
      includes ? v: v._aliasIncludes or attrNames v,
      excludes ? v: v._aliasExcludes or [ ],
      forceExcludes ? [
        "_aliasForce"
        "_aliasIncludes"
        "_aliasExcludes"
      ],
      getAliases ? getAliasesWith { inherit includes excludes forceExcludes; },
    }:
    morphAttrs (name: v: if isAttrs v then getAliases name v else [ ]);

  addAttrsAliasesWith' =
    {
      includes ? v: v._aliasIncludes or attrNames v,
      excludes ? v: v._aliasExcludes or [ ],
      forceExcludes ? [
        "_aliasForce"
        "_aliasIncludes"
        "_aliasExcludes"
      ],
      getAliases ? getAliasesWith { inherit includes excludes forceExcludes; },
    }:
    morphAttrs (
      name: v:
      if isAttrs v then
        getAliases name v ++ [ (nameValuePair name (removeAttrs v forceExcludes)) ]
      else
        [ (nameValuePair name v) ]
    );

  makeAttrsAliases' = makeAttrsAliasesWith' { };
  addAttrsAliases' = addAttrsAliasesWith' { };

  makeCallSetWith =
    caller: getOverride: set: final:
    mapAttrs (name: flip final.${caller} (getOverride final name)) set;

  makeCallPackageSet = makeCallSetWith "callPackage";
  makeCallScopeSet = makeCallSetWith "callScope";

  flatMapAttrs = pred: set: concatLists (mapAttrsToList pred set);
  morphAttrs = pred: set: listToAttrs (flatMapAttrs pred set);

  shouldRecurseForDerivations = x: isAttrs x && x.recurseForDerivations or false;
}
