final: prev: {
  attrsets = import ../lib/attrsets.nix final prev;
  debug = import ../lib/debug.nix final prev;
  di = import ../lib/di.nix final prev;
  filesystem = import ../lib/filesystem.nix final prev;
  flakes = import ../lib/flakes.nix final prev;
  lists = import ../lib/lists.nix final prev;
  maintainers = import ../lib/maintainers.nix final prev;
  overlays = import ../lib/overlays.nix final prev;
  paths = import ../lib/paths.nix final prev;
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

  inherit (final.di)
    callWith
    callPackageBy
    callPackageWith
    callPinnedByCallPackage
    callPinnedBy
    callPinnedWith
    makeScopeWith
    makeCompatScopeWith
    ;

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
    ;

  inherit (final.flakes)
    pkgsFrom
    eachPkgsIn
    eachPkgs
    forPkgsIn
    forPkgs
    eachSystemIn
    eachSystem
    forSystemIn
    forSystem
    ;

  inherit (final.lists)
    splitAt
    intersectStrings
    subtractStrings
    dfold
    ;

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
    nestOverlayWith
    nestOverlayr
    nestOverlayl
    forkLibAs
    forkLib
    augmentLibAs
    augmentLib
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

  inherit (final.trivial)
    snd
    apply
    eq
    neq
    compose
    fpipe
    invoke
    fix
    fix'
    annotateArgs
    mirrorArgsFrom
    ;
}
