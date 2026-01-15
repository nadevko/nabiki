self: lib:
let
  inherit (builtins) readDir listToAttrs elem;

  inherit (lib.path) append;
  inherit (lib.attrsets) nameValuePair;

  inherit (self.attrsets) addAliasesToAttrs' addAliasesToAttrs flatMapAttrs;
  inherit (self.path)
    removeNixExtension
    isHidden
    isDir
    isNix
    ;
  inherit (self.trivial) compose;
  inherit (self.fixedPoints) rebase;
in
rec {
  flatMapDir = pred: root: flatMapAttrs (name: pred (append root name) name) (readDir root);
  flatMapVisible =
    pred:
    flatMapDir (
      root: name: type:
      if isHidden name then [ ] else pred root name type
    );

  flatMapSubDirs =
    pred: root:
    flatMapVisible (
      root: _: type:
      if isDir type then pred root else [ ]
    ) root;

  listModules = flatMapVisible (
    root: name: type:
    if isDir type then
      listModules root
    else if isNix name then
      [ root ]
    else
      [ ]
  );

  readModulesWithKeygen =
    keygen:
    let
      recurse =
        prefix:
        flatMapVisible (
          root: name: type:
          let
            key = keygen prefix name type;
          in
          if isDir type then
            recurse key root
          else if isNix name then
            [ (nameValuePair key root) ]
          else
            [ ]
        );
    in
    compose listToAttrs (recurse "");

  readModulesWith =
    {
      sep ? "-",
      lifts ? [ "default.nix" ],
    }:
    readModulesWithKeygen (
      prefix: name: type:
      let
        name' = removeNixExtension name;
      in
      if prefix == "" then
        if isDir type then name else name'
      else if elem name lifts then
        prefix
      else
        "${prefix}${sep}${name'}"
    );

  readModulesSep = sep: readModulesWith { inherit sep; };
  readModules = readModulesWith { };

  readNixTree =
    pred: root:
    let
      recurse = compose listToAttrs (
        flatMapVisible (
          root: name: type:
          let
            key = removeNixExtension name;
          in
          if isDir type then
            [ (nameValuePair key (recurse root)) ]
          else if isNix name then
            [ (nameValuePair key (pred root)) ]
          else
            [ ]
        )
      );
    in
    recurse root;

  readNixTreeOverlay =
    root: final: prev:
    readNixTree (root: import root final prev) root;

  readAliasedNixTreeOverlay =
    aliases: root: final: prev:
    addAliasesToAttrs aliases (rebase (readNixTreeOverlay root) prev);

  readAliasedNixTreeOverlay' =
    root: final: prev:
    addAliasesToAttrs' (rebase (readNixTreeOverlay root) prev);

  readConfigurationDir =
    builder: getOverride:
    compose listToAttrs (
      flatMapVisible (
        root: name: type:
        if isDir type then [ (nameValuePair name (builder root (getOverride name))) ] else [ ]
      )
    );

  readNixosConfigurations =
    nixosSystem:
    readConfigurationDir (
      root: config: nixosSystem (config // { modules = (listModules root) ++ (config.modules or [ ]); })
    );

  readTemplates = readConfigurationDir (root: config: config // { path = root; });

  listNixDir' =
    stem:
    flatMapVisible (
      value: name: type:
      if isDir type then
        flatMapVisible (
          value: fileName: type:
          if isNix fileName then
            [
              {
                stem = removeNixExtension fileName;
                inherit name value;
              }
            ]
          else
            [ ]
        ) value
      else if isNix name then
        [
          {
            name = removeNixExtension name;
            inherit value stem;
          }
        ]
      else
        [ ]
    );

  listNixDir = listNixDir' "package";
}
