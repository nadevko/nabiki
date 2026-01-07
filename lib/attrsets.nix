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
    ;
  inherit (lib.attrsets)
    nameValuePair
    genAttrs
    mergeAttrsList
    concatMapAttrs
    ;
  inherit (lib.trivial) flip;

  inherit (self.trivial) compose;
in
rec {
  nearestAttrByPath =
    nodesPath: pattern: set: deepest:
    let
      find =
        currentSet: path: currentDeepest:
        if path == [ ] then
          (if isAttrs currentSet && currentSet ? pattern then currentSet.${pattern} else currentDeepest)
        else
          let
            head = builtins.head path;
            tail = builtins.tail path;
            newDeepest =
              if isAttrs currentSet && currentSet ? pattern then currentSet.${pattern} else currentDeepest;
          in
          if isAttrs currentSet && currentSet ? head then
            find currentSet.${head} tail newDeepest
          else
            newDeepest;
    in
    find set nodesPath deepest;

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

  nameValuePair' = name: value: { ${name} = value; };

  addAliasesToAttrs =
    set:
    let
      defaultExcludes = [
        "_includeAlias"
        "_excludeAlias"
      ];
    in
    mapAttrs (_: v: if isAttrs v then removeAttrs v defaultExcludes else v) set
    // concatMapAttrs (
      _: v:
      if !isAttrs v then
        { }
      else
        lib.getAttrs (filter (n: !elem n (v._excludeAlias or defaultExcludes)) (
          v._includeAlias or (attrNames v)
        )) v
    ) set;

  partitionAttrs =
    pred: set:
    let
      names = attrNames set;
      items = partition (n: pred n set.${n}) names;
      build = compose listToAttrs (
        map (n: {
          name = n;
          value = set.${n};
        })
      );
    in
    {
      right = build items.right;
      wrong = build items.wrong;
    };

  listToMergedAttrs = zipAttrsWith (_: mergeAttrsList);
}
