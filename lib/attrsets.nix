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
    filter
    elem
    partition
    head
    tail
    isFunction
    ;
  inherit (lib.attrsets)
    nameValuePair
    genAttrs
    mergeAttrsList
    concatMapAttrs
    getAttrs
    ;
  inherit (lib.trivial) flip;

  inherit (self.trivial) compose;
in
rec {
  closestAttrByPath =
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

  transposeAttrs =
    attrs:
    zipAttrsWith (_: listToAttrs) (
      attrValues (mapAttrs (root: mapAttrs (_: nameValuePair root)) attrs)
    );

  genTransposedAs =
    reader: roots: generator:
    transposeAttrs (genAttrs roots (compose generator reader));

  genTransposed = genTransposedAs (x: x);

  genTransposedFrom' = compose (flip genTransposedAs) attrNames;
  genTransposedFrom = set: genTransposedFrom' set (attr: set.${attr});

  mapAttrsIntersection =
    pred: left: right:
    mapAttrs (name: pred name left.${name}) (intersectAttrs left right);

  bind = name: value: { ${name} = value; };

  extractAliases = include: exclude: getAttrs (filter (n: !elem n exclude) include);

  addAliasesToAttrs =
    getInclude: set:
    let
      getExtra =
        n: v:
        let
          includes = getInclude n;
        in
        if includes == [ ] then { } else extractAliases includes [ "_includes" "_excludes" ] v;
    in
    set // concatMapAttrs (n: v: if isAttrs v then getExtra n v else { }) set;

  addAliasesToAttrs' =
    set:
    let
      defaultExcludes = [
        "_includes"
        "_excludes"
      ];
    in
    mapAttrs (_: v: if isAttrs v then removeAttrs v defaultExcludes else v) set
    // concatMapAttrs (
      _: v:
      if !isAttrs v then
        { }
      else
        extractAliases (v._includes or attrNames v) ((v._excludes or [ ]) ++ defaultExcludes) v
    ) set;

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

  zipMerge = zipAttrsWith (_: mergeAttrsList);

  perSystemIn =
    systems: flake: config:
    genTransposedAs (
      system:
      if config == null then
        flake.legacyPackages.${system}
      else if isFunction config then
        import flake (config system)
      else
        import flake (config // { inherit system; })
    ) systems;

  perSystem = flake: perSystemIn (attrNames flake.legacyPackages) flake;

  makeCallSetWith =
    caller: getOverride: set: final:
    mapAttrs (name: flip final.${caller} (getOverride name)) set;

  makeCallPackageSet = makeCallSetWith "callPackage";
  makeCallScopeSet = makeCallSetWith "callScope";
}
