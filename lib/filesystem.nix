final: prev:
let
  inherit (builtins) readDir pathExists mapAttrs;

  inherit (prev.attrsets) nameValuePair;
  inherit (prev.trivial) const;
  inherit (prev) nixosSystem;

  inherit (final.attrsets) bindAttrs mbindAttrs mergeMapAttrs;
  inherit (final.paths)
    stemOfNix
    stemOf
    isVisibleNix
    isNix
    isHidden
    isVisibleDir
    isDir
    ;
  inherit (final.di) callPackageWith callPinnedWith;
in
rec {
  makeReadDirWrapper =
    merger: fn: root:
    merger (name: fn (root + "/${name}") name) (readDir root);

  bindDir = makeReadDirWrapper bindAttrs;
  mbindDir = makeReadDirWrapper mbindAttrs;

  mapDir = makeReadDirWrapper mapAttrs;
  mergeMapDir = makeReadDirWrapper mergeMapAttrs;

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
    recurseInto = isVisibleDir;
    include = isVisibleNix;
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
      include = isVisibleNix;
      recurseInto = isVisibleDir;
      toRootPrefix = const;
      toRootName = name: _: stemOfNix name;
      concatPrefix =
        prefix: name: _:
        "${prefix}${sep}${name}";
      concatName =
        prefix: name: _:
        if name == "default.nix" then prefix else "${prefix}${sep}${stemOfNix name}";
    };

  collapseNixDir = collapseNixDirSep "-";

  readDirWithManifest =
    fn: root:
    let
      dir = readDir root;
    in
    mbindAttrs (
      name: type:
      let
        abs = root + "/${name}";
        config = if dir ? ${name + ".nix"} then import (abs + ".nix") else { };
      in
      if !isDir type || isHidden name then [ ] else [ (nameValuePair name (fn abs name config)) ]
    ) dir;

  readConfigurations =
    builder: base: getter:
    readDirWithManifest (
      abs: name: config:
      let
        overrides = getter name;
      in
      builder (
        base
        // config
        // overrides
        // {
          modules =
            (collectNixFiles abs)
            ++ (base.modules or [ ])
            ++ (config.modules or [ ])
            ++ (overrides.modules or [ ]);
        }
      )
    );

  readNixosConfigurations = readConfigurations nixosSystem;

  readTemplates =
    descriptions:
    readDirWithManifest (
      abs: name: config:
      config
      // {
        path = abs;
        ${if descriptions ? ${name} then "description" else null} = descriptions.${name};
      }
    );

  readLibOverlay =
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

  readShards = mergeMapDir (
    abs: _: type:
    mapAttrs (name: _: abs + "/${name}") (readDir abs)
  );

  readPackagesOverlay =
    root: final: prev:
    let
      callPackage = final.callPackage or callPackageWith final;
    in
    mapAttrs (_: abs: callPackage (abs + "/package.nix") { }) (readShards root);

  readPackagesWithPinsOverlay =
    root: final: prev:
    let
      callPackage = final.callPackage or callPackageWith final;
      callPinned = final.callPinned or callPinnedWith final;
    in
    mapAttrs (
      _: abs:
      let
        pins = abs + "/pins.nix";
      in
      (if pathExists pins then callPinned pins else callPackage) (abs + "/package.nix") { }
    ) (readShards root);
}
