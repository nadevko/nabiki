{ self, lib, ... }:
let
  inherit (builtins)
    readDir
    concatStringsSep
    elem
    attrValues
    mapAttrs
    ;

  inherit (self.path) removeExtension;
  inherit (self.lists) splitAt;
  inherit (self.trivial) fpipeFlatten fpipe;
  inherit (self.filesystem.filters) isNotUnderscored isNix;

  inherit (lib.attrsets)
    mergeAttrsList
    mapAttrsToList
    recursiveUpdate
    setAttrByPath
    filterAttrs
    ;
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
          (map ({ type, ... }@e: (if type == "directory" then onDirectory else onFile) e))
          mergers
        ] path;
      onFile = fpipe loaders;
    in
    onDirectory { inherit path; };

  readDirRecursive =
    args:
    readDirFlattenRecursive (
      {
        mergers = [
          (map (
            { parent, ... }@e:
            if parent == null then e else
            {
              ${pa} = e;
            }
          ))
          # mergeAttrsList
        ];
      }
      // args
    );

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
      pkgs,
      separator ? "-",
      defaultNix ? "default.nix",
      lifts ? [
        defaultNix
        "package.nix"
      ],

      importers ? [
        (
          { path, nodes, ... }:
          mapAttrsToList (name: drv: { ${fpipe namers (nodes ++ [ name ])} = drv; }) (import path pkgs)
        )
        mergeAttrsList
      ],
      callers ? [
        (
          { path, ... }@entry:
          {
            ${fpipe namers entry.nodes} = pkgs.callPackage path { };
          }
        )
      ],
      namers ? [
        (nodes: filter (node: !elem node lifts) nodes)
        (concatStringsSep separator)
        removeExtension
      ],
      ...
    }@args:
    listModules (
      {
        loaders = [
          attrValues
          ({ name, ... }@entry: fpipe (if name == defaultNix then importers else callers) entry)
        ];
        mergers = [ mergeAttrsList ];
      }
      // args
    );

  loadLegacyPackages =
    {
      pkgs,
      defaultNix ? "default.nix",
      lifts ? [
        defaultNix
        "package.nix"
      ],
      ...
    }@args:
    #  recursiveUpdate pkgs
    (loadPackages (
      rec {
        namers = [
          (nodes: filter (node: !elem node lifts) nodes)
          (map removeExtension)
        ];
        loaders = [
          (
            {
              name,
              path,
              nodes,
              ...
            }:
            setAttrByPath (fpipe namers nodes) (
              if name == defaultNix then import path pkgs else pkgs.callPackage path { }
            )
          )
        ];
        mergers = [ ];
        inherit pkgs defaultNix lifts;
      }
      // args
    ));

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
