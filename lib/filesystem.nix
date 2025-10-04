{ self, lib, ... }:
let
  inherit (builtins)
    readDir
    pathExists
    readFileType
    concatStringsSep
    elem
    ;

  inherit (self) isNotUnderscored isNix;
  inherit (self.path) removeExtension;
  inherit (self.attrsets) treeishTraverse;
  inherit (self.trivial) fpipeFlatten fpipe;

  inherit (lib.attrsets) mergeAttrsList mapAttrsToList recursiveUpdate;
  inherit (lib.lists) flatten filter last;
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
          mergers
        ] path;
      onFile = fpipe loaders;
    in
    onDirectory { inherit path; };

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

  loadPackages =
    {
      separator ? "-",
      defaultNix ? "default.nix",
      packageNix ? "package.nix",
      namers ? [
        (
          nodes:
          filter (
            node:
            !elem node [
              defaultNix
              packageNix
            ]
          ) nodes
        )
        (concatStringsSep separator)
        removeExtension
      ],
      importers ? [
        (
          { path, nodes, ... }:
          mapAttrsToList (name: drv: { ${fpipe namers (nodes ++ [ name ])} = drv; }) (import path pkgs)
        )
      ],
      callers ? [
        (
          { path, ... }@entry:
          {
            ${fpipe namers entry.nodes} = pkgs.callPackage path { };
          }
        )
      ],
      pkgs,
      ...
    }@args:
    listModules (
      {
        loaders = [
          ({ name, ... }@entry: fpipe (if name == defaultNix then importers else callers) entry)
        ];
        mergers = [
          flatten
          mergeAttrsList
        ];
      }
      // args
    );

  loadLegacyPackages =
    {
      defaultNix ? "default.nix",
      packageNix ? "package.nix",
      pkgs,
      ...
    }@args:
    recursiveUpdate pkgs (
      loadPackages (
        rec {
          namers = [
            (
              nodes:
              filter (
                node:
                !elem node [
                  defaultNix
                  packageNix
                ]
              ) nodes
            )
            last
            removeExtension
          ];
          importers = [
            (
              { path, nodes, ... }:
              {
                ${fpipe namers nodes} = import path pkgs;
              }
            )
          ];
          mergers = [ mergeAttrsList ];
        }
        // args
      )
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
}
