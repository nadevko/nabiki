self: lib:
let
  inherit (builtins)
    mapAttrs
    readDir
    hasAttr
    isAttrs
    concatStringsSep
    listToAttrs
    elem
    any
    ;

  inherit (lib.trivial) flip pipe;
  inherit (lib.path) append;
  inherit (lib.lists) flatten;
  inherit (lib.strings) hasSuffix;
  inherit (lib.attrsets) filterAttrs nameValuePair mapAttrsToList;
  inherit (lib.fileset.internal) _coerce _create _currentVersion;

  inherit (self.path) removeExtension;
  inherit (self.attrsets) listToMergedAttrs;
  inherit (self.lists) filterOut;
  inherit (self.trivial) compose;
  inherit (self.fileset) _check toFlattenAttrsWith;
in
assert _currentVersion == 3;
{
  _excludeAlias = [ "_check" ];

  _check =
    predicate: nodes: name: type:
    predicate rec {
      inherit name type nodes;
      hasPrefix = flip lib.strings.hasPrefix name;
      hasSuffix = flip lib.strings.hasSuffix name;
      isHidden = hasPrefix ".";
      hasExt = ext: hasSuffix ".${ext}";
      isNix = !isHidden && hasExt "nix";
      isNixRec = !isHidden && type == "directory" || isNix;
    };

  dirFilter =
    predicate: root:
    let
      recurse =
        nodes: path:
        pipe path [
          readDir
          (filterAttrs (_check predicate nodes))
          (mapAttrs (
            name: type: if type == "directory" then recurse (nodes ++ [ name ]) (append path name) else type
          ))
        ];
    in
    _create root (recurse [ ] root);

  toExtension = compose (
    {
      _internalIsEmptyWithoutBase,
      _internalBase,
      _internalTree,
      ...
    }:
    final: prev:
    let
      recurse =
        path: node:
        if node == "regular" then
          import path final prev
        else if isAttrs node then
          pipe node [
            (flip removeAttrs [ "default.nix" ])
            (mapAttrsToList (name: sub: nameValuePair (removeExtension name) (recurse (append path name) sub)))
            listToMergedAttrs
          ]
          // (if hasAttr "default.nix" node then import (append path "default.nix") final prev else { })
        else
          { };
    in
    if _internalIsEmptyWithoutBase then { } else recurse _internalBase _internalTree
  ) (_coerce "kasumi.lib.fileset.toExtension: Argument");

  toFlattenAttrsWith =
    {
      sep ? "-",
      lifts ? [ ],
      liftsOnly ? false,
      ...
    }:
    compose (
      {
        _internalIsEmptyWithoutBase,
        _internalBase,
        _internalTree,
        ...
      }:
      let
        recurse =
          nodes: path: value:
          if isAttrs value then
            mapAttrsToList (name: recurse (nodes ++ [ name ]) (append path name)) value
          else
            pipe nodes [
              (filterOut (flip elem lifts))
              (concatStringsSep sep)
              removeExtension
              (flip nameValuePair path)
            ];
        result = listToAttrs (flatten (recurse [ ] _internalBase _internalTree));
      in
      if _internalIsEmptyWithoutBase then
        { }
      else if liftsOnly then
        filterAttrs (_: path: any (flip hasSuffix path) lifts) result
      else
        result
    ) (_coerce "kasumi.lib.fileset.toFlattenAttrsWith: Argument");

  toFlattenAttrs = toFlattenAttrsWith { };
}
