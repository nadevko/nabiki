self: lib:
let
  inherit (builtins)
    readDir
    concatMap
    listToAttrs
    concatStringsSep
    filter
    attrNames
    mapAttrs
    ;

  inherit (lib.path) append;
  inherit (lib.strings) hasPrefix hasSuffix;
  inherit (lib.attrsets) mapAttrsToList nameValuePair;
  inherit (lib.customisation) makeScope;
  inherit (lib.trivial) flip;

  inherit (self.attrsets) addAliasesToAttrs;
  inherit (self.customisation) derivationSetFromDir getOverride;
  inherit (self.path) removeExtension;
  inherit (self.trivial) compose rebase;
in
rec {
  listDir = compose (mapAttrsToList (name: type: { inherit name type; })) readDir;

  listModules =
    root:
    concatMap (
      { name, type }:
      let
        filePath = append root name;
      in
      if hasPrefix "." name then
        [ ]
      else if type == "directory" then
        listModules filePath
      else if hasSuffix ".nix" name then
        [ filePath ]
      else
        [ ]
    ) (listDir root);

  flatifyModulesSep =
    sep:
    let
      recurse =
        dirPath: root:
        concatMap (
          { name, type }:
          let
            filePath = append root name;
            name' = removeExtension name;
            dirPath' = dirPath ++ [ name' ];
            joinedName = concatStringsSep sep dirPath';
          in
          if hasPrefix "." name then
            [ ]
          else if type == "directory" then
            recurse dirPath' filePath
          else if hasSuffix ".nix" name then
            [ (nameValuePair joinedName filePath) ]
          else
            [ ]
        ) (listDir root);
    in
    compose listToAttrs (recurse [ ]);

  flatifyModules = flatifyModulesSep "-";

  readLiblikeOverlay =
    root: final: prev:
    let
      recurse =
        root:
        listToAttrs (
          concatMap (
            { name, type }:
            let
              name' = removeExtension name;
              filePath = append root name;
              dir = recurse filePath;
              overlay = import filePath final prev;
            in
            if hasPrefix "." name then
              [ ]
            else if type == "directory" then
              [ (nameValuePair name' dir) ]
            else if hasSuffix ".nix" name then
              [ (nameValuePair name' overlay) ]
            else
              [ ]
          ) (listDir root)
        );
    in
    recurse root;

  getLibOverlay =
    filePath: final: prev:
    addAliasesToAttrs (rebase (readLiblikeOverlay filePath) prev);

  getLib = filePath: rebase (getLibOverlay filePath);

  readConfigurationDir =
    builder: getOverride: root:
    concatMap (
      { name, type }:
      let
        filePath = append root name;
        configuration = builder filePath (getOverride name);
      in
      if !hasPrefix "." name && type == "directory" then nameValuePair name configuration else [ ]
    ) (listDir root);

  getNixosConfigurations =
    nixosSystem:
    readConfigurationDir (
      filePath: config:
      nixosSystem (config // { modules = listModules filePath ++ config.modules or [ ]; })
    );

  getTemplates = readConfigurationDir (filePath: config: config // { path = filePath; });

  listByNameDirWithDefaultType =
    defaultType: root:
    concatMap (
      { name, type }:
      let
        dirPath = append root name;
        dir = readDir dirPath;
        files = filter (name: !hasPrefix "." name && hasSuffix ".nix" name && dir.${name} == "regular") (
          attrNames dir
        );
      in
      if hasPrefix "." name then
        [ ]
      else if type == "directory" then
        map (type: {
          inherit name type;
          value = append dirPath type;
        }) files
      else if type == "regular" then
        [
          {
            name = removeExtension name;
            type = defaultType;
            value = dirPath;
          }
        ]
      else
        [ ]
    ) (listDir root);

  listByNameDir = listByNameDirWithDefaultType "package.nix";

  readPackagesFixedPoint =
    root: targets: getOverride: final:
    mapAttrs (compose (flip final.callPackage) getOverride) (
      derivationSetFromDir targets (listByNameDir root)
    );

  readPackagesScope =
    root: targets: getOverride:
    flip makeScope (readPackagesFixedPoint root targets getOverride);

  readPackagesOverlay =
    root: targets: baseOverride: overrides: final: prev:
    let
      scope = readPackagesScope root targets (getOverride baseOverride overrides) prev.newScope;
    in
    scope.packages scope;
}
