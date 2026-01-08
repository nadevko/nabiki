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
    getAttrs
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

  bind' = name: value: { ${name} = value; };

  extractAliases =
    {
      include,
      exclude ? [ ],
    }:
    v: getAttrs (filter (n: !elem n exclude) include) v;

  addAliasesToAttrs =
    aliases: set:
    let
      getExtra =
        n: v:
        let
          conf = aliases.${n} or { };
          include = conf.include or conf._include or [ ];
          exclude = conf.exclude or conf._exclude or [ ];
        in
        if include == [ ] then { } else extractAliases { inherit include exclude; } v;
    in
    set // concatMapAttrs (n: v: if isAttrs v then getExtra n v else { }) set;

  addAliasesToAttrs' =
    set:
    let
      defaultExcludes = [
        "_include"
        "_exclude"
      ];
    in
    mapAttrs (_: v: if isAttrs v then removeAttrs v defaultExcludes else v) set
    // concatMapAttrs (
      _: v:
      if !isAttrs v then
        { }
      else
        extractAliases {
          include = v._include or (attrNames v);
          exclude = v._exclude or defaultExcludes;
        } v
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
