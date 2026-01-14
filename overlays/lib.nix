final: prev:
let
  attrsets = import ../lib/attrsets.nix final prev;
  set = {
    inherit attrsets;
    customisation = import ../lib/customisation.nix final prev;
    filesystem = import ../lib/filesystem.nix final prev;
    fixedPoints = import ../lib/fixedPoints.nix final prev;
    lists = import ../lib/lists.nix final prev;
    maintainers = import ../lib/maintainers.nix final prev;
    path = import ../lib/path.nix final prev;
    trivial = import ../lib/trivial.nix final prev;
  };
  aliases = {
    attrsets = [
      "findClosestByPath"
      "mapAttrsIntersection"
      "bind"
      "partitionAttrs"
      "pointwisel"
      "pointwiser"
      "transposeAttrs"
      "perWith"
      "per"
      "perSystemIn"
      "perSystem"
      "addAliasesToAttrs"
      "addAliasesToAttrs'"
      "makeCallSetWith"
      "makeCallPackageSet"
      "makeCallScopeSet"
    ];
    customisation = [
      "getOverride"
      "getCallErrorMessage"
      "callPackageWith"
      "callScopeWith"
      "makeLegacyPackages"
      "makeScope"
    ];
    filesystem = [
      "scanDirWith"
      "scanDir"
      "scanSubDirs"
      "listModules"
      "flatifyModulesWithKeyMerger"
      "flatifyModulesWith"
      "flatifyModulesSep"
      "flatifyModules"
      "loadNixTree"
      "importNixTreeOverlay"
      "importAliasedNixTreeOverlay"
      "importAliasedNixTreeOverlay'"
      "readConfigurationDir"
      "readNixosConfigurations"
      "readTemplates"
      "listNixesWithDefaultStem"
      "listNixes"
    ];
    fixedPoints = [
      "rebase"
      "rebase'"
      "extendBy"
      "composeOverlaysBy"
      "composeOverlayListBy"
      "makeExtensibleBy"
      "extends"
      "extendOverlays"
      "extendOverlayList"
      "makeExtensibleAs"
      "makeExtensible"
      "patches"
      "patchOverlays"
      "patchOverlayList"
      "makePatchableAs"
      "makePatchable"
      "augments"
      "augmentOverlays"
      "augmentOverlayList"
      "makeAugmentableAs"
      "makeAugmentable"
      "wrapLibOverlay"
      "wrapLibOverlay'"
    ];
    lists = [
      "splitAt"
      "intersectListsBy"
    ];
    path = [
      "removeExtension"
      "removeNixExtension"
      "isRegular"
      "isDir"
      "isHidden"
      "isNixFile"
      "isVisibleNix"
      "isVisibleDir"
    ];
    trivial = [
      "compose"
      "fpipe"
      "getAttrPosMessage"
      "libWarn"
    ];
  };
in
attrsets.addAliasesToAttrs aliases set // set
