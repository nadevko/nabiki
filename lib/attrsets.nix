self: lib:
let
  inherit (builtins)
    mapAttrs
    isAttrs
    hasAttr
    length
    elemAt
    attrNames
    concatLists
    intersectAttrs
    zipAttrsWith
    ;
  inherit (lib.attrsets) foldAttrs mapAttrsToList mergeAttrsList;
  inherit (lib.trivial) flip;

  inherit (self.trivial) fpipe;
in
rec {
  nestAttrs' =
    reader: roots: generator:
    zipAttrsWith (_: mergeAttrsList) (
      map (root: mapAttrs (_: value: { ${root} = value; }) (generator (reader root))) roots
    );
  nestAttrs = nestAttrs' (x: x);
  mapAttrsNested = set: nestAttrs' (attr: set.${attr}) (attrNames set);

  nearestAttrByPath =
    nodesPath: pattern: default: attrset:
    let
      len = length nodesPath;
      iterator =
        set: idx: deepest:
        let
          key = elemAt nodesPath idx;
          nextSet = if idx < len && hasAttr key set then set.${key} else null;
          newDeepest = if hasAttr pattern set then set.${pattern} else deepest;
        in
        if isAttrs set then iterator nextSet (idx + 1) newDeepest else deepest;
    in
    iterator attrset 0 default;

  transposeStringMatrix = fpipe [
    (mapAttrsToList (name: map (flip nameValuePair' name)))
    concatLists
    (foldAttrs (name: acc: [ name ] ++ acc) [ ])
  ];

  mapIntersectedAttrs =
    pred: left: right:
    mapAttrs (name: pred name left.${name}) (intersectAttrs left right);

  nameValuePair' = name: value: { ${name} = value; };
}
