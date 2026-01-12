self: lib:
let
  inherit (builtins)
    readDir
    concatLists
    listToAttrs
    elem
    ;

  inherit (lib.path) append;
  inherit (lib.attrsets) nameValuePair mapAttrsToList;

  inherit (self.attrsets) addAliasesToAttrs' addAliasesToAttrs;
  inherit (self.path)
    removeNixExtension
    isHidden
    isVisibleNix
    isDir
    isVisibleDir
    ;
  inherit (self.trivial) compose;
  inherit (self.fixedPoints) rebase;
in
rec {
  scanDirWith = pred: root: concatLists (mapAttrsToList pred (readDir root));

  scanDir =
    pred: root:
    scanDirWith (name: type: if isHidden name then [ ] else pred (append root name) name type) root;

  nestedScanDir =
    pred: root:
    scanDirWith (name: type: if isVisibleDir name type then pred (append root name) else [ ]) root;

  listModules = scanDir (
    root: name: type:
    if isDir type then
      listModules root
    else if isVisibleNix name type then
      [ root ]
    else
      [ ]
  );

  flatifyModulesWithKeyMerger =
    keymerge:
    let
      recurse =
        prefix:
        scanDir (
          root: name: type:
          let
            key = keymerge prefix name type;
          in
          if isDir type then
            recurse key root
          else if isVisibleNix name type then
            [ (nameValuePair key root) ]
          else
            [ ]
        );
    in
    compose listToAttrs (recurse "");

  flatifyModulesWith =
    {
      sep ? "-",
      lifts ? [ "default.nix" ],
    }:
    flatifyModulesWithKeyMerger (
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

  flatifyModulesSep = sep: flatifyModulesWith { inherit sep; };
  flatifyModules = flatifyModulesWith { };

  loadNixTree =
    pred: root:
    let
      recurse = compose listToAttrs (
        scanDir (
          root: name: type:
          let
            key = removeNixExtension name;
          in
          if isDir type then
            [ (nameValuePair key (recurse root)) ]
          else if isVisibleNix name type then
            [ (nameValuePair key (pred root)) ]
          else
            [ ]
        )
      );
    in
    recurse root;

  importNixTreeOverlay =
    root: final: prev:
    loadNixTree (root: import root final prev) root;

  importAliasedNixTreeOverlay =
    aliases: root: final: prev:
    addAliasesToAttrs aliases (rebase (importNixTreeOverlay root) prev);

  importAliasedNixTreeOverlay' =
    root: final: prev:
    addAliasesToAttrs' (rebase (importNixTreeOverlay root) prev);

  readConfigurationDir =
    builder: getOverride:
    compose listToAttrs (
      scanDir (
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

  listShallowNixes = scanDir (
    value: name: type:
    if isDir type then
      scanDir (
        value: fileName: type:
        if isVisibleNix fileName type then
          [
            {
              stem = removeNixExtension fileName;
              inherit name value;
            }
          ]
        else
          [ ]
      ) value
    else if isVisibleNix name type then
      [
        {
          stem = "";
          name = removeNixExtension name;
          inherit value;
        }
      ]
    else
      [ ]
  );

  nestedListShallowNixes = nestedScanDir listShallowNixes;
}
