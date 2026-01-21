final: prev:
let
  inherit (builtins) readDir pathExists;

  inherit (prev.attrsets) nameValuePair;
  inherit (prev.trivial) const;

  inherit (final.attrsets) bindAttrs mbindAttrs;
  inherit (final.path)
    stemOfNix
    stemOf
    isVisibleNix
    isNix
    isHidden
    isVisibleDir
    isDir
    ;
in
rec {
  bindDir = pred: root: bindAttrs (name: pred (root + "/${name}") name) (readDir root);
  mbindDir = pred: root: mbindAttrs (name: pred (root + "/${name}") name) (readDir root);

  collectFiles =
    {
      recurseInto ? name: type: isDir type,
      include ? name: type: true,
      mapAttr ?
        abs: name: type:
        abs,
    }:
    let
      recurse = bindDir (
        abs: name: type:
        (if include name type then [ (mapAttr abs name type) ] else [ ])
        ++ (if recurseInto name type then recurse abs else [ ])
      );
    in
    recurse;

  collectNixes = collectFiles {
    recurseInto = _: isVisibleDir;
    include = _: isVisibleNix;
  };

  flattenDir =
    {
      recurseInto ? name: type: isDir type,
      include ? name: type: !isDir type,

      concatPrefix ?
        prefix: name: type:
        "${prefix}-${name}",
      concatName ?
        prefix: name: type:
        "${prefix}-${stemOf name}",

      toRootPrefix ? name: type: name,
      toRootName ? name: type: stemOf name,
    }:
    let
      makeRecurse =
        toPrefix: toName: abs: name: type:
        let
          entry = nameValuePair (toName name type) abs;
          subtree = recurse (toPrefix name type) abs;
        in
        (if include name type then [ entry ] else [ ]) ++ (if recurseInto name type then subtree else [ ]);
      recurse = prefix: bindDir (makeRecurse (concatPrefix prefix) (concatName prefix));
    in
    mbindDir (makeRecurse toRootPrefix toRootName);

  flattenNixesSep =
    sep:
    flattenDir {
      include = name: _: isVisibleNix name;
      recurseInto = isVisibleDir;
      toRootPrefix = const;
      toRootName = name: _: stemOfNix name;
      concatPrefix =
        prefix: name: _:
        "${prefix}${sep}${name}";
      concatName =
        prefix: name: _:
        "${prefix}${sep}${stemOfNix name}";
    };

  flattenNixes = flattenNixesSep "-";

  configureDir =
    pred: getConfig: root:
    let
      dir = readDir root;
    in
    mbindAttrs (
      name: type:
      let
        abs = root + "/${name}";
        config = getConfig name (if dir ? ${name + ".nix"} then import (abs + ".nix") else { });
      in
      if !isDir type || isHidden name then [ ] else [ (nameValuePair name (pred abs config)) ]
    ) dir;

  readNixosConfigurations =
    nixosSystem:
    configureDir (
      abs: config: nixosSystem (config // { modules = (collectNixes abs) ++ (config.modules or [ ]); })
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

  readShards =
    {
      shardDepth ? 0,
      recurseInto ? name: type: true,
      include ? name: type: true,
      caller ? abs: name: type: [ (nameValuePair name abs) ],
    }:
    root:
    let
      enterShards =
        depth: abs: name: type:
        if depth < shardDepth && recurseInto name type then
          bindDir (enterShards (depth + 1)) abs
        else if include name type then
          caller abs name type
        else
          [ ];
    in
    mbindDir (enterShards 0) root;
}
