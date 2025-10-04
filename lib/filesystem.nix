{ self, lib, ... }:
let
  inherit (builtins) readDir concatStringsSep elem;

  inherit (self) isNotUnderscored isNix;
  inherit (self.path) removeExtension;
  inherit (self.trivial) fpipeFlatten fpipe;

  inherit (lib.attrsets) mergeAttrsList mapAttrsToList recursiveUpdate;
  inherit (lib.lists) flatten filter last;
in
rec {
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

  loadLib =
    {
      defaultNix ? "default.nix",
      inputs ? { },
      ...
    }@args:
    let
      self = listModules (
        rec {
          namers = [
            (nodes: filter (node: !elem node [ defaultNix ]) nodes)
            last
            removeExtension
          ];
          loaders = [
            (
              { path, nodes, ... }:
              let
                fragment = import path inputs';
              in
              fragment // (if nodes != [ defaultNix ] then { ${fpipe namers nodes} = fragment; } else { })
            )
          ];
          mergers = [ mergeAttrsList ];
        }
        // args
      );
      inputs' = inputs // {
        inherit self;
      };
    in
    self;
}
