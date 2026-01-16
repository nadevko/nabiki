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
    head
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
    validateKasumiLib = validateLibWith { libPrefix = "kasumi.lib"; };
  };

  throwCallErrorMessage =
    fnName: autoNames: asIsNames: requestedAttrs: arg:
    let
      suggestions = pipe (autoNames ++ asIsNames) [
        (filter (levenshteinAtMost 2 arg))
        (sortOn (levenshtein arg))
        (take 3)
      ];

      prettySuggestions =
        if suggestions == [ ] then
          ""
        else if length suggestions == 1 then
          '', did you mean "${head suggestions}"?''
        else
          '', did you mean "${concatStringsSep ''", "'' (init suggestions)}" or "${last suggestions}"?'';

      filePos = getAtFilePos arg requestedAttrs;
    in
    throw ''${fnName}: Function called without required argument "${arg}" at ${filePos}${prettySuggestions}'';

  getAtFilePos =
    s: set:
    let
      pos = unsafeGetAttrPos s set;
    in
    if pos != null then
      "${pos.file}:${toString pos.line}:${toString pos.column}"
    else
      "<unknown location>";

  validateLibAliasesWith =
    {
      libPrefix ? "lib",
      listAliases ? getAliasList,
      ...
    }:
    set:
    let
      attrs = filter (n: isAttrs set.${n}) (attrNames set);
      byName = groupBy (x: x.name) (concatMap (n: listAliases n set.${n}) attrs);
      warnAbout = message: warn ("kasumi.lib.debug.validateLibAliasesWith: " + message);
      warnAboutCategory =
        category: name: warn "${libPrefix}.${category}.${name} at ${getAtFilePos name set.${category}}";

      collisions = concatMap (
        name:
        let
          list = byName.${name};
        in
        if length list != 1 then
          [
            (warnAbout (
              toString (length list)
              + ''"${name}" collisions: ''
              + concatStringsSep ", " (map ({ category, ... }: warnAboutCategory category name) list)
            ))
          ]
        else
          [ ]
      ) (attrNames byName);

      misses = pipe attrs [
        (concatMap (cat: listAliases cat set.${cat}))
        (filter (a: !(set ? ${a.name})))
        (map ({ category, name, ... }: warnAbout ''alias missing for ${warnAboutCategory category name}''))
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
