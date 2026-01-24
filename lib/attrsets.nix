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

  inherit (prev.attrsets)
    nameValuePair
    genAttrs
    mapAttrsToList
    isDerivation
    mergeAttrsList
    ;
  inherit (prev.strings) hasPrefix;
  inherit (prev.trivial) id;

  inherit (final.trivial) compose snd;
in
rec {
  singletonAttrs = name: value: { ${name} = value; };

  bindAttrs = fn: set: concatMap (name: fn name set.${name}) (attrNames set);
  mbindAttrs = fn: set: listToAttrs (bindAttrs fn set);

  mergeMapAttrs = fn: set: mergeAttrsList (map (name: fn name set.${name}) (attrNames set));

  intersectWith =
    fn: left: right:
    mapAttrs (name: fn name left.${name}) (intersectAttrs left right);

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

  genTransposedAttrs = genTransposedAttrsBy id;

  foldPathWith =
    fn: default: pattern:
    let
      recurse =
        deepest: nodesPath: set:
        if nodesPath == [ ] || !isAttrs set then
          deepest
        else
          let
            nextDeepest = if set ? ${pattern} then fn deepest set.${pattern} else deepest;
            nextSet = set.${head nodesPath} or null;
          in
          if nextSet == null then nextDeepest else recurse nextDeepest (tail nodesPath) nextSet;
    in
    recurse default;

  foldPath = foldPathWith snd;

  genLibAliasesPred =
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
    blacklist: genLibAliasesPred (name: _: elem name blacklist || hasPrefix "_" name);

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

  collapseScopeWith =
    {
      include ? isDerivation,
      sep ? "-",
    }:
    scope:
    let
      makeRecurse =
        concat: name: value:
        if include value then
          [ (nameValuePair (concat name) value) ]
        else if isAttrs value && value.recurseForDerivations or false then
          recurse (concat name) (value.self or value)
        else
          [ ];

      recurse = prefix: bindAttrs (makeRecurse (n: "${prefix}${sep}${n}"));
    in
    mbindAttrs (makeRecurse id) (scope.self or scope);

  collapseScopeSep = sep: collapseScopeWith { inherit sep; };
  collapseScope = collapseScopeSep "-";
}
