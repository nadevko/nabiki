self: lib:
let
  inherit (builtins)
    mapAttrs
    isAttrs
    hasAttr
    length
    elemAt
    attrNames
    intersectAttrs
    groupBy
    zipAttrsWith
    attrValues
    listToAttrs
    concatMap
    removeAttrs
    filter
    elem
    partition
    ;
  inherit (lib.attrsets)
    nameValuePair
    genAttrs
    mapAttrsToList
    mergeAttrsList
    ;
  inherit (lib.trivial) flip mergeAttrs pipe;

  inherit (self.trivial) compose;
  inherit (self.lists) filterOut;
in
rec {
  nearestAttrByPath =
    nodesPath: pattern:
    let
      len = length nodesPath;
      iterator =
        idx: set: deepest:
        let
          key = elemAt nodesPath idx;
          nextSet = if idx < len && hasAttr key set then set.${key} else null;
          newDeepest = if hasAttr pattern set then set.${pattern} else deepest;
        in
        if isAttrs set then iterator (idx + 1) nextSet newDeepest else deepest;
    in
    iterator 0;

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
    pipe set [
      attrValues
      (filter isAttrs)
      (concatMap (
        {
          _includeAlias ? attrNames sub,
          _excludeAlias ? defaultExcludes,
          ...
        }@sub:
        if isAttrs _excludeAlias then
          _includeAlias
        else
          map (name: nameValuePair name sub.${name}) (filterOut (flip elem _excludeAlias) _includeAlias)
      ))
      listToAttrs
      (flip mergeAttrs (
        mapAttrs (_: value: if isAttrs value then removeAttrs value defaultExcludes else value) set
      ))
    ];

  partitionAttrs =
    pred: set:
    mapAttrs (_: listToAttrs) (
      partition ({ name, value }: pred name value) (mapAttrsToList nameValuePair set)
    );

  listToMergedAttrs = compose (mapAttrs (_: compose mergeAttrsList (map ({ value, ... }: value)))) (
    groupBy ({ name, ... }: name)
  );
}
