self: lib:
let
  inherit (builtins)
    warn
    unsafeGetAttrPos
    deepSeq
    isAttrs
    groupBy
    length
    concatStringsSep
    filter
    attrNames
    concatMap
    elemAt
    ;

  inherit (lib.trivial) pipe;

  inherit (self.attrsets) getAliasList;
  inherit (self.trivial) fpipe;

  inherit (lib.lists)
    take
    sortOn
    init
    last
    ;
  inherit (lib.strings) levenshteinAtMost levenshtein;
in
rec {
  _internal = {
    validateKasumi = validateLibWith { libPrefix = "kasumi.lib."; };

    getCallErrorMessage =
      allNames: requestedAttrs: arg:
      let
        suggestions = pipe allNames [
          (filter (levenshteinAtMost 2 arg))
          (sortOn (levenshtein arg))
          (take 3)
          (map (x: ''"${x}"''))
        ];

        prettySuggestions =
          if suggestions == [ ] then
            ""
          else if length suggestions == 1 then
            ", did you mean ${elemAt suggestions 0}?"
          else
            ", did you mean ${concatStringsSep ", " (init suggestions)} or ${last suggestions}?";

        pos = getAttrPos arg requestedAttrs;
      in
      ''Function called without required argument "${arg}" at ${pos}${prettySuggestions}'';
  };

  getAttrPos =
    s: set:
    let
      attrPos = unsafeGetAttrPos s set;
    in
    if attrPos != null then attrPos.file + ":" + toString attrPos.line else "<unknown location>";

  genPosLibErrorMessage =
    libPrefix: lib: category: name:
    "${libPrefix}${category}.${name} at ${getAttrPos name lib.${category}}";

  validateLibAliasesWith =
    {
      libPrefix ? "lib.",
      listAliases ? getAliasList,
      ...
    }:
    set:
    let
      attrs = filter (n: isAttrs set.${n}) (attrNames set);
      byName = groupBy (x: x.name) (concatMap (n: listAliases n set.${n}) attrs);
      genError = genPosLibErrorMessage libPrefix set;

      collisions = concatMap (
        name:
        let
          list = byName.${name};
        in
        if length list != 1 then
          [
            (warn ''kasumi.lib.debug.getLibCollisionWarns: Collision detected! ${toString (length list)} "${name}" dublicates: ${
              concatStringsSep ", " (map ({ category, ... }: genError category name) list)
            }'')
          ]
        else
          [ ]
      ) (attrNames byName);

      misses = pipe attrs [
        (concatMap (cat: listAliases cat set.${cat}))
        (filter (a: !(set ? ${a.name})))
        (map (
          { category, name, ... }:
          warn ''kasumi.lib.debug.getLibCollisionWarns: Alias missing ${genError category name}''
        ))
      ];
    in
    pipe set (collisions ++ misses);

  validateLibWith =
    {
      providers ? [
        (_: lib: deepSeq lib lib)
        (arg: validateLibAliasesWith arg)
      ],
      ...
    }@arg:
    fpipe (map (x: x arg) providers);
}
