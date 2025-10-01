{ self, lib, ... }:
let
  inherit (builtins)
    readDir
    pathExists
    readFileType
    concatStringsSep
    head
    elem
    ;

  inherit (self) isNotUnderscored isNix;
  inherit (self.path) removeExtension;
  inherit (self.attrsets) treeishTraverse;
  inherit (self.trivial) fpipeFlatten fpipe;
  inherit (self.lists) splitAt;

  inherit (lib.attrsets) mergeAttrsList mapAttrsToList recursiveUpdate;
  inherit (lib.lists) flatten filter;
in
rec {
  itemiseDir =
    { nodes, value, ... }:
    mapAttrsToList (name: type: {
      inherit nodes name type;
      value = /${value}/${name};
    }) (readDir value);

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

  readDirFlattenRecursive =
    {
      path,
      filters ? [ ],
      loaders ? [ ],
      mergers ? [ flatten ],
      ...
    }:
    let
      onDirectory =
        {
          path,
          nodes ? [ ],
          ...
        }:
        fpipeFlatten [
          readDir
          (mapAttrsToList (
            name: type: {
              path = /${path}/${name};
              nodes = nodes ++ [ name ];
              inherit
                name
                type
                onDirectory
                onFile
                ;
            }
          ))
          (map (fn: filter fn) filters)
          (map ({ type, ... }@entry: (if type == "directory" then onDirectory else onFile) entry))
        ] path;
      onFile = fpipe loaders;
    in
    fpipe mergers (onDirectory {
      inherit path;
    });

  listModules =
    args:
    readDirFlattenRecursive (
      {
        filters = [
          isNix
          isNotUnderscored
        ];
        loaders = [ ({ path, ... }: path) ];
      }
      // args
    );

  listPackages =
    {
      separator ? "-",
      namers ? [
        ({ nodes, ... }: nodes)
        (
          nodes:
          let
            split = splitAt (-1) nodes;
            last = head split.tail;
          in
          if
            elem last [
              "package.nix"
              "default.nix"
            ]
          then
            split.init
          else
            nodes
        )
        (concatStringsSep separator)
        removeExtension
      ],
      importers ? [
        ({ name, path, ... }: if name == "default.nix" then import path pkgs else pkgs.callPackage path { })
      ],
      pkgs,
      ...
    }@args:
    listModules (
      {
        loaders = [ (entry: { ${fpipe namers entry} = fpipe importers entry; }) ];
        mergers = [
          flatten
          mergeAttrsList
        ];
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
}
