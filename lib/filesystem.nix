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
    isNixFile
    isValidNix
    ;
  inherit (self.trivial) compose;
  inherit (self.fixedPoints) rebase;
in
rec {
  scanDir =
    f: root:
    concatLists (
      mapAttrsToList (name: type: if isHidden name then [ ] else f (append root name) name type) (
        readDir root
      )
    );

  listModules = scanDir (
    path: name: type:
    if type == "directory" then
      listModules path
    else if isNixFile name then
      [ path ]
    else
      [ ]
  );

  flatifyModulesWithKeyMerger =
    keymerge:
    let
      recurse =
        prefix:
        scanDir (
          path: name: type:
          let
            key = keymerge prefix name type;
          in
          if type == "directory" then
            recurse key path
          else if isNixFile name then
            [ (nameValuePair key path) ]
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
        if type == "directory" then name else name'
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
          path: name: type:
          let
            key = removeNixExtension name;
          in
          if type == "directory" then
            [ (nameValuePair key (recurse path)) ]
          else if isNixFile name then
            [ (nameValuePair key (pred path)) ]
          else
            [ ]
        )
      );
    in
    recurse root;

  importNixTreeOverlay =
    root: final: prev:
    loadNixTree (path: import path final prev) root;

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
        path: name: type:
        if type == "directory" then [ (nameValuePair name (builder path (getOverride name))) ] else [ ]
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
    if type == "directory" then
      scanDir (
        value: fileName: type:
        if type == "regular" && isValidNix fileName then
          [
            {
              stem = removeNixExtension fileName;
              inherit name value;
            }
          ]
        else
          [ ]
      ) value
    else if type == "regular" && isValidNix name then
      [
        {
          stem = null;
          name = removeNixExtension name;
          inherit value;
        }
      ]
    else
      [ ]
  );
}
