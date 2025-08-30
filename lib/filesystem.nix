{ self, lib, ... }:
let
  inherit (builtins)
    readDir
    attrValues
    pathExists
    readFileType
    ;

  inherit (self) isNotUnderscored isNix;
  inherit (self.path) removeExtension concatNodesSep;
  inherit (self.attrsets) setNameToValue pipelineTraverse treeishTraverse;
  inherit (self.trivial) mapPipe flatPipe;

  inherit (lib.attrsets) mergeAttrsList mapAttrsToList recursiveUpdate;
  inherit (lib.lists) flatten;
in
rec {
  itemiseDir =
    { nodes, value, ... }:
    mapAttrsToList (name: type: {
      inherit nodes name type;
      value = /${value}/${name};
    }) (readDir value);

  itemiseFromContent =
    {
      name,
      nodes,
      packages,
      value,
      ...
    }:
    mapAttrsToList (pname: package: {
      name = pname;
      nodes = nodes ++ [ name ];
      type = "regular";
      value = package;
      dir = value;
    }) packages;

  switchDirFile =
    { onLeaf, onNode, ... }:
    {
      name,
      type,
      nodes,
      ...
    }@entry:
    if type == "directory" then onNode (entry // { nodes = nodes ++ [ name ]; }) else onLeaf entry;

  readLib =
    { inputs, ... }@args:
    treeishTraverse (
      {
        filters = [
          isNotUnderscored
          isNix
        ];
        transformers = [
          (liftFile "default.nix")
          removeExtension
        ];
        loaders = entry: entry // { value = import entry.value inputs; };
      }
      // args
    );

  readModulesFlatten =
    {
      separator ? "-",
      ...
    }@args:
    pipelineTraverse (
      {
        filters = [
          isNotUnderscored
          isNix
        ];
        transformers = [
          (liftFile "default.nix")
          removeExtension
        ];
        loaders = [
          (concatNodesSep separator)
          setNameToValue
        ];
        mergers = flatten;
        updaters = mergeAttrsList;
      }
      // args
    );

  listModules =
    args:
    pipelineTraverse (
      {
        filters = [
          isNotUnderscored
          isNix
        ];
        loaders = { value, ... }: value;
        mergers = flatten;
      }
      // args
    );

  liftFile =
    file:
    {
      value,
      nodes,
      name,
      ...
    }@entry:
    let
      value' = /${value}/${file};
    in
    if pathExists value' then
      {
        inherit name nodes;
        type = readFileType value';
        dir = value;
        value = value';
        liftedAs = file;
      }
    else
      entry;

  readLegacyPackages =
    { pkgs, overrides, ... }@args:
    treeishTraverse (
      args
      // {
        filters = [
          isNotUnderscored
          isNix
        ];
        transformers = [
          (liftFile "package.nix")
          (liftFile "default.nix")
          removeExtension
        ];
        loaders =
          {
            value,
            liftedAs ? null,
            ...
          }@entry:
          entry
          // {
            value =
              if liftedAs == "default.nix" then
                import value (pkgs // overrides)
              else
                pkgs.callPackage value overrides;
          };
        updaters = recursiveUpdate pkgs;
      }
    );

  switchDirFileContent = (
    {
      importers,
      callPackage,
      liftedContentFile,
      loaders,
      onLeaf,
      onNode,
      contentReaders,
      ...
    }:
    {
      name,
      type,
      nodes,
      value,
      ...
    }@entry:
    let
      onContentRead = flatPipe [
        importers
        contentReaders
        onContentLoad
      ];
      onContentLoad = mapPipe [ loaders ];
    in
    if type == "directory" then
      if pathExists /${value}/${liftedContentFile} then
        flatPipe [ onLeaf attrValues ] (entry // { value = onContentRead entry; })
      else
        onNode (entry // { nodes = nodes ++ [ name ]; })
    else
      onLeaf (flatPipe [ callPackage ] entry)
  );

  readPackages =
    { pkgs, overrides, ... }@args:
    readModulesFlatten (
      {
        transformers = [
          (liftFile "package.nix")
          removeExtension
        ];
        callPackage = entry: entry // { value = pkgs.callPackage entry.value overrides; };
        importers = entry: entry // { packages = import entry.value (pkgs // overrides); };
        liftedContentFile = "default.nix";
        contentReaders = itemiseFromContent;
        switchers = switchDirFileContent;
      }
      // args
    );
}
