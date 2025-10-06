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
  inherit (self.trivial) fpipeFlattenMap fpipeFlatten;

  inherit (lib.attrsets) mergeAttrsList mapAttrsToList recursiveUpdate;
  inherit (lib.lists) flatten;
in
rec {
  /**
    Common file-path resolver: returns a list of files in a directory together
    with some metadata (name, type, nodes and full path).

    Input: an entry with { nodes, value, ... } where `value` is the directory path.
    Output: a list of maps suitable for further pipeline processing.
  */
  itemiseDir =
    { nodes, value, ... }:
    mapAttrsToList (name: type: {
      inherit nodes name type;
      value = /${value}/${name};
    }) (readDir value);

  /**
    Create list entries from package content.

    Each produced entry contains:
    - `name`  : package name,
    - `nodes` : the path nodes appended with the current `name`,
    - `type`  : "regular",
    - `value` : the package expression,
    - `dir`   : the directory that contained the package.
  */
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

  /**
    Switch helper: if the entry is a directory, call `onNode` (adding the dir to `nodes`);
    otherwise call `onLeaf`.
  */
  switchDirFile =
    { onLeaf, onNode, ... }:
    {
      name,
      type,
      nodes,
      ...
    }@entry:
    if type == "directory" then onNode (entry // { nodes = nodes ++ [ name ]; }) else onLeaf entry;

  /**
    Read `lib` functions as a tree. Non-underscored `.nix` files are imported.

    Behaviour:
    - Files are placed in the tree according to their relative filesystem path.
    - If a directory contains `default.nix`, that file is treated as directory content
      and is prepended to the node.
    - Each file import receives `inputs` as arguments.
  */
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

  /**
    Return a map whose keys are concatenated relative file paths (joined with `separator`)
    and whose values are the corresponding full file paths.
  */
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

  /**
    Return all `.nix` files under `path` recursively (flattened list of values).
  */
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

  /**
    Transformer that removes a file extension from the `name` attribute.

    If the name has no extension it is left unchanged.
  */
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

  /**
    Read legacy-style packages. Each file under `path` is treated as a package
    placed in `pkgs` according to its relative path. Behaviour:
    - `package.nix` inside a directory is considered as the package for that directory.
    - `default.nix` files are imported directly rather than treated as callables.

    The function returns a nested attribute set of packages where `pkgs` is used
    to call or import package expressions.
  */
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

  /**
    Enhanced switcher that chooses how to process a file depending on its content.

    The switcher supports:
    - `importers`: reading packages from a directory via `import`.
    - `callPackage`: calling a package file with `pkgs.callPackage`.
    - `liftedContentFile`: name of a file (e.g. "default.nix") that, when present,
      causes directory content to be treated as packages.
    - `contentReaders`: functions that convert imported content into entries.

    The switcher will:
    - For directories: check for `liftedContentFile`. If present, read its content
      and convert it to entries; otherwise treat the entry as a node.
    - For regular files: apply the `onLeaf` processing (calling packages etc.).
  */
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
      onContentRead = fpipeFlatten [
        importers
        contentReaders
        onContentLoad
      ];
      onContentLoad = fpipeFlattenMap [ loaders ];
    in
    if type == "directory" then
      if pathExists /${value}/${liftedContentFile} then
        fpipeFlatten [ onLeaf attrValues ] (entry // { value = onContentRead entry; })
      else
        onNode (entry // { nodes = nodes ++ [ name ]; })
    else
      onLeaf (fpipeFlatten [ callPackage ] entry)
  );

  /**
    Read packages similar to `readLegacyPackages`, but flatten names using
    the same naming mechanism as `readModulesFlatten`.
  */
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
