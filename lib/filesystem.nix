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
  inherit (lib.customisation) makeScope;
  inherit (lib.trivial) pipe flip;

  inherit (self.attrsets) addAliasesToAttrs';
  inherit (self.customisation) unscopeToOverlay unscopeToOverlay';
  inherit (self.path)
    removeExtension
    isHidden
    isNixFile
    isValidNix
    ;
  inherit (self.trivial) compose;
  inherit (self.lists) intersectListsBy;
  inherit (self.fixedPoints) rebase;
in
rec {
  scanDir =
    root: f:
    concatLists (
      mapAttrsToList (name: type: if isHidden name then [ ] else f (append root name) name type) (
        readDir root
      )
    );

  listModules =
    root:
    scanDir root (
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
        prefix: root:
        scanDir root (
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
      if prefix == "" then
        if type == "directory" then name else removeExtension name
      else if elem name lifts then
        prefix
      else
        "${prefix}${sep}${removeExtension name}"
    );

  flatifyModulesSep = sep: flatifyModulesWith { inherit sep; };
  flatifyModules = flatifyModulesWith { };

  readLiblikeOverlay =
    root: final: prev:
    let
      recurse =
        root:
        listToAttrs (
          scanDir root (
            path: name: type:
            let
              key = removeExtension name;
            in
            if type == "directory" then
              [ (nameValuePair key (recurse path)) ]
            else if isNixFile name then
              [ (nameValuePair key (import path final prev)) ]
            else
              [ ]
          )
        );
    in
    recurse root;

  getLibOverlay =
    filePath: final: prev:
    addAliasesToAttrs' (rebase (readLiblikeOverlay filePath) prev);

  readConfigurationDir =
    builder: getOverride: root:
    listToAttrs (
      scanDir root (
        path: name: type:
        if type == "directory" then [ (nameValuePair name (builder path (getOverride name))) ] else [ ]
      )
    );

  readNixosConfigurations =
    nixosSystem:
    readConfigurationDir (
      filePath: config:
      nixosSystem (config // { modules = (listModules filePath) ++ (config.modules or [ ]); })
    );

  readTemplates = readConfigurationDir (filePath: config: config // { path = filePath; });

  listFlatDrvDirWithDefault =
    defaultTarget: root:
    scanDir root (
      path: name: type:
      if type == "directory" then
        scanDir path (
          subPath: subName: subType:
          if isValidNix subName && subType == "regular" then
            [
              {
                inherit name;
                target = subName;
                value = subPath;
              }
            ]
          else
            [ ]
        )
      else if type == "regular" && isValidNix name then
        [
          {
            name = removeExtension name;
            target = defaultTarget;
            value = path;
          }
        ]
      else
        [ ]
    );

  listFlatDrvDir = listFlatDrvDirWithDefault "package.nix";

  readPackagesFixedPoint =
    root: targets: getOverride: final:
    pipe root [
      listFlatDrvDir
      (intersectListsBy (x: x.target) targets)
      (map ({ name, value, ... }: nameValuePair name (final.callPackage value (getOverride name))))
      listToAttrs
    ];

  readPackagesScope =
    root: targets: getOverride:
    flip makeScope (readPackagesFixedPoint root targets getOverride);

  readPackagesOverlayWith =
    unscopeToOverlay: root: targets: getOverride:
    unscopeToOverlay (readPackagesScope root targets getOverride);

  readPackagesOverlay = readPackagesOverlayWith unscopeToOverlay;
  readPackagesOverlay' = compose readPackagesOverlayWith unscopeToOverlay';
}
