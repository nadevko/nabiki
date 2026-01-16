final: prev:
let
  inherit (builtins)
    readDir
    pathExists
    fromJSON
    readFile
    ;

  inherit (prev.attrsets) nameValuePair;

  inherit (final.attrsets) bindAttrs mbindAttrs;
  inherit (final.path)
    stemOfNix
    stemOf
    isVisibleNix
    isNix
    isVisible
    isHidden
    isVisibleDir
    isDir
    ;
  inherit (final.trivial) id;
in
rec {
  bindDir = pred: root: bindAttrs (name: pred (root + "/${name}") name) (readDir root);
  mbindDir = pred: root: mbindAttrs (name: pred (root + "/${name}") name) (readDir root);

  importManifestAs =
    stem: dir: abs:
    if dir ? ${stem + ".nix"} then
      import (abs + ".nix")
    else if dir ? ${stem + ".json"} then
      fromJSON (readFile (abs + ".json"))
    else
      { };

  importManifest = importManifestAs "manifest";

  collectFiles =
    {
      include ?
        _: _: _:
        true,
      recurseInto ? _: _: isDir,
      rootDepth ? 0,
    }:
    let
      recurse =
        depth:
        bindDir (
          abs: name: type:
          (if include depth name type then [ abs ] else [ ])
          ++ (if recurseInto depth name type then recurse (depth + 1) abs else [ ])
        );
    in
    recurse rootDepth;

  collectNixFiles = collectFiles {
    include = _: isVisibleNix;
    recurseInto = _: isVisibleDir;
  };

  flattenDir =
    {
      include ?
        _: _: _:
        true,
      recurseInto ? _: _: isDir,
      rootDepth ? 0,

      getRootPrefix ? id,
      getRootKey ? stemOf,
      mergePrefix ? prev: name: "${prev}-${name}",
      mergeKey ? prefix: name: "${prefix}-${stemOf name}",
    }:
    let
      recurse =
        depth: prefix:
        bindDir (
          abs: name: type:
          (if include depth name type then [ (nameValuePair (mergeKey prefix name) abs) ] else [ ])
          ++ (if recurseInto depth name type then recurse (depth + 1) (mergePrefix prefix name) abs else [ ])
        );
    in
    mbindDir (
      abs: name: type:
      (if include rootDepth name type then [ (nameValuePair (getRootKey name) abs) ] else [ ])
      ++ (
        if recurseInto rootDepth name type then recurse (rootDepth + 1) (getRootPrefix name) abs else [ ]
      )
    );

  flattenNixDirSep =
    sep:
    flattenDir {
      include = isVisibleNix;
      recurseInto = _: isVisibleDir;
      getRootKey = stemOfNix;
      mergePrefix = prev: name: "${prev}${sep}${name}";
      mergeKey = prev: name: "${prev}${sep}${stemOfNix name}";
    };

  flattenNixDir = flattenNixDirSep "-";

  configureDir =
    pred: getConfig: root:
    let
      dir = readDir root;
    in
    mbindDir (
      abs: name: type:
      let
        config = getConfig name (importManifestAs name dir abs);
      in
      if isVisible name && isDir type then [ (nameValuePair name (pred abs config)) ] else [ ]
    ) dir;

  readNixosConfigurations =
    nixosSystem:
    configureDir (
      abs: config: nixosSystem (config // { modules = (collectNixFiles abs) ++ (config.modules or [ ]); })
    );

  readTemplates = configureDir (abs: config: config // { path = abs; });

  importLibOverlay =
    root: final: prev:
    mbindDir (
      abs: name: type:
      if isHidden name then
        [ ]
      else if isDir type then
        let
          default = abs + "/default.nix";
        in
        if pathExists default then [ (nameValuePair name (import default final prev)) ] else [ ]
      else if name != "default.nix" && isNix name then
        [ (nameValuePair (stemOfNix name) (import abs final prev)) ]
      else
        [ ]
    ) root;
}
