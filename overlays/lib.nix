final: prev: {
  attrsets = import ../lib/attrsets.nix final prev;
  customisation = import ../lib/customisation.nix final prev;
  debug = import ../lib/debug.nix final prev;
  filesystem = import ../lib/filesystem.nix final prev;
  fixedPoints = import ../lib/fixedPoints.nix final prev;
  lists = import ../lib/lists.nix final prev;
  maintainers = import ../lib/maintainers.nix final prev;
  path = import ../lib/path.nix final prev;
  trivial = import ../lib/trivial.nix final prev;

  inherit (final.attrsets)
    bindAttrs
    mbindAttrs
    singletonAttrs
    mapAttrsIntersection
    partitionAttrs
    pointwisel
    pointwiser
    transposeAttrs
    genTransposedAttrsBy
    perRootIn
    perSystemIn
    perSystem
    foldPathWith
    ;
  inherit (final.customisation)
    getOverride
    shouldRecurseForDerivations
    callPackageWith
    callScopeWith
    makeScope
    ;
  inherit (final.debug) attrPos;
  inherit (final.filesystem) collectFiles listNixFiles;
  inherit (final.fixedPoints)
    rebase
    rebase'
    extendWith
    composeOverlaysWith
    composeOverlayListWith
    makeExtensibleWith
    safeExtendWith
    extends
    extendOverlays
    extendOverlayList
    makeExtensibleAs
    makeExtensible
    safeExtendAs
    safeExtend
    patches
    patchOverlays
    patchOverlayList
    makePatchableAs
    makePatchable
    safePatchAs
    safePatch
    augments
    augmentOverlays
    augmentOverlayList
    makeAugmentableAs
    makeAugmentable
    safeAugmentAs
    safeAugment
    wrapLibOverlay
    wrapLibOverlay'
    ;
  inherit (final.lists) splitAt subtractLists subtractStrings;
  inherit (final.path)
    stemOf
    stemOfNix
    isDir
    isNix
    isHidden
    ;
  inherit (final.trivial) compose fpipe;
}
