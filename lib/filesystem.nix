final: prev:
let
  inherit (builtins) readDir pathExists;

  inherit (prev.attrsets) nameValuePair;
  inherit (prev.trivial) const;

  inherit (final.attrsets) bindAttrs mbindAttrs;
  inherit (final.paths)
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

  collectNixFiles = collectFiles {
    recurseInto = _: isVisibleDir;
    include = _: isVisibleNix;
  };

  collapseDir =
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

  collapseNixDirSep =
    sep:
    collapseDir {
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

  collapseNixDir = collapseNixDirSep "-";

  readDirWithConfig =
    pred: root:
    let
      dir = readDir root;
    in
    mbindAttrs (
      name: type:
      let
        abs = root + "/${name}";
        config = if dir ? ${name + ".nix"} then import (abs + ".nix") else { };
      in
      if !isDir type || isHidden name then [ ] else [ (nameValuePair name (pred abs name config)) ]
    ) dir;

  readNixosConfigurations =
    nixosSystem:
    readDirWithConfig (
      abs: _: config:
      nixosSystem (config // { modules = (collectNixFiles abs) ++ (config.modules or [ ]); })
    );

  readTemplates = readDirWithConfig (
    abs: _: config:
    config // { path = abs; }
  );

  readLibMixin =
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
