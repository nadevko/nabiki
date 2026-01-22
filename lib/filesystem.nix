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

  libMixin =
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

  listShards =
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

  importScope =
    let
      loadIn =
        dir: abs: name: f:
        if dir ? ${name} then f (abs + "/${name}") else { };

      recurse =
        scope: abs:
        let
          package = abs + "/package.nix";
        in
        if pathExists package then
          let
            pins = abs + "/pins.nix";
          in
          if pathExists pins then scope.callScopeWith pins package else scope.callScope package
        else
          scope.fuse (
            final: prev:
            let
              dir = readDir abs;
              files = removeAttrs dir [
                "default.nix"
                "overlay.nix"
              ];

              content = mbindAttrs (
                name: type:
                let
                  child = abs + "/${name}";
                in
                if isHidden name then
                  [ ]
                else if isDir type then
                  [ (nameValuePair name (recurse final child)) ]
                else if isNix name then
                  [ (nameValuePair (stemOfNix name) (final.callPackage child)) ]
                else
                  [ ]
              ) files;

              load = loadIn dir abs;
              defaultNix = load "default.nix" (p: import p { pkgs = final.legacyPackages; });
              overlayNix = load "overlay.nix" (p: import p final.legacyPackages prev.legacyPackages);
            in
            defaultNix // content // overlayNix
          );
    in
    recurse;
}
