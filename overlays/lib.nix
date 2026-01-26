final: prev: {
  attrsets = import ../lib/attrsets.nix final prev;
  debug = import ../lib/debug.nix final prev;
  filesystem = import ../lib/filesystem.nix final prev;
  flakes = import ../lib/flakes.nix final prev;
  lists = import ../lib/lists.nix final prev;
  maintainers = import ../lib/maintainers.nix final prev;
  overlays = import ../lib/overlays.nix final prev;
  paths = import ../lib/paths.nix final prev;
  scopes = import ../lib/scopes.nix final prev;
  trivial = import ../lib/trivial.nix final prev;

  inherit (final.attrsets)
    singletonAttrs
    bindAttrs
    mbindAttrs
    mergeMapAttrs
    intersectWith
    partitionAttrs
    pointwisel
    pointwiser
    transposeAttrs
    genAttrsBy
    genTransposedAttrsBy
    genTransposedAttrs
    foldPathWith
    foldPath
    genLibAliasesPred
    genLibAliasesWithout
    genLibAliases
    collapseScopeWith
    collapseScopeSep
    collapseScope
    ;

  inherit (final.debug) attrPos' attrPos;

  inherit (final.filesystem)
    makeReadDirWrapper
    bindDir
    mbindDir
    mapDir
    mergeMapDir
    collectFiles
    collectNixFiles
    collapseDir
    collapseNixDirSep
    collapseNixDir
    readDirWithManifest
    readConfigurations
    readTemplates
    readLibOverlay
    readShards
    readPackagesOverlay
    readPackagesWithPinsOverlay
    readRecursivePackagesOverlay
    ;

  inherit (final.flakes)
    pkgsFrom
    perSystemIn
    perLegacyIn
    perScopeIn
    forSystems
    perSystem
    perLegacy
    perScope
    ;

  inherit (final.lists) splitAt intersectStrings subtractStrings;

  inherit (final.overlays)
    makeLayMerge
    makeLayRebaseWith
    makeLayRebase
    makeLayRebase'
    makeLayFuse
    makeLayFold
    rebaseSelf
    rebaseSelf'
    lay
    rebaseLay
    rebaseLay'
    fuseLay
    foldLay
    layr
    rebaseLayr
    rebaseLayr'
    fuseLayr
    foldLayr
    layl
    rebaseLayl
    rebaseLayl'
    fuseLayl
    foldLayl
    overlayr
    overlayl
    ;

  inherit (final.paths)
    stemOf
    stemOfNix
    isDir
    isNix
    isHidden
    isVisible
    isVisibleNix
    isVisibleDir
    ;

  inherit (final.scopes)
    initLibAs
    initLib
    mergeLibWith
    forkLibFrom
    forkLibAs
    forkLib
    augmentLibFrom
    augmentLibAs
    augmentLib
    callWith
    makeScopeWith
    ;

  inherit (final.trivial)
    snd
    apply
    eq
    compose
    fpipe
    invoke
    fix
    fix'
    dfold
    annotateArgs
    mirrorArgsFrom
    ;
}
