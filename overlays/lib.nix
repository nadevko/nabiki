final: prev: {
  attrsets = import ../lib/attrsets.nix final prev;
  debug = import ../lib/debug.nix final prev;
  di = import ../lib/di.nix final prev;
  filesystem = import ../lib/filesystem.nix final prev;
  lists = import ../lib/lists.nix final prev;
  maintainers = import ../lib/maintainers.nix final prev;
  nixos = import ../lib/nixos.nix final prev;
  overlays = import ../lib/overlays.nix final prev;
  paths = import ../lib/paths.nix final prev;
  systems = import ../lib/systems.nix final prev;
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
    ;

  inherit (final.debug) attrPos' attrPos;

  inherit (final.di)
    callWith
    callPackageBy
    callPackageWith
    makeScopeWith
    fuseScope
    foldScope
    rebaseScope
    collapseScopeWith
    collapseScopeSep
    collapseScope
    ;

  inherit (final.filesystem)
    readDirPaths
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
    readShards
    collapseShardsWith
    collapseShardsUntil
    readDirWithManifest
    readConfigurations
    readNixosConfigurations
    readTemplates
    readLibOverlay
    byNameOverlayWithName
    byNameOverlayFrom
    byNameOverlayWithPinsFrom
    byNameOverlayWithScopesFrom
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

  inherit (final.systems)
    flakeSystems
    importFlakePkgs
    forAllSystems
    forSystems
    forAllPkgs
    forPkgs
    ;

  inherit (final.trivial)
    snd
    apply
    eq
    neq
    compose
    invoke
    fix
    fix'
    annotateArgs
    mirrorArgsFrom
    ;
}
