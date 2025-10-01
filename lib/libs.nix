self: lib:
let
  inherit (builtins)
    concatMap
    listToAttrs
    isAttrs
    attrNames
    removeAttrs
    filter
    elem
    ;

  inherit (lib.attrsets) mergeAttrsList nameValuePair;
  inherit (lib.trivial) flip;

  inherit (self.attrsets) nameValuePair';
  inherit (self.filesystem) listDirectory;
  inherit (self.trivial) fpipe;
  inherit (self.lists) filterOut;
  inherit (self.path)
    isNix
    isDirectory
    isHidden
    removeExtension
    ;
in
rec {
  readLibOverlay' =
    postProcess: path: final: prev:
    let
      onDirectory = path: mergeAttrsList (map switch (listDirectory path));
      switch =
        { name, path, ... }@e:
        if isHidden e then
          { }
        else if isDirectory e then
          onDirectory path
        else if !isNix e then
          { }
        else if name == "default.nix" then
          import path final prev
        else
          nameValuePair' (removeExtension name) (import path final prev);
    in
    postProcess (onDirectory path);

  readLibOverlayWithShortcuts = readLibOverlay' (
    lib:
    fpipe [
      attrNames
      (filter (name: isAttrs lib.${name}))
      (concatMap (
        sectionName:
        fpipe [
          (filterOut (flip elem (lib.${sectionName}._excludeShortcuts or [ ])))
          (map (name: nameValuePair name lib.${sectionName}.${name}))
        ] (lib.${sectionName}._includeShortcuts or attrNames lib.${sectionName})
      ))
      listToAttrs
      (flip removeAttrs [
        "_includeShortcuts"
        "_excludeShortcuts"
      ])
    ] lib
    // lib
  );
  readLibOverlayWithoutShortcuts = readLibOverlay' (lib: lib);
  readLibOverlay = readLibOverlayWithShortcuts;
}
