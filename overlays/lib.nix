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
      "transposeMapAttrs"
      "perRootIn"
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
      "makeScope"
    ];
    filesystem = [
      "flatMapDir"
      "flatMapVisible"
      "flatMapSubDirs"
      "listModules"
      "readModulesWithKeygen"
      "readModulesWith"
      "readModulesSep"
      "readModules"
      "loadNixTree"
      "readNixTreeOverlay"
      "readAliasedNixTreeOverlay"
      "readAliasedNixTreeOverlay'"
      "readConfigurationDir"
      "readNixosConfigurations"
      "readTemplates"
      "listNixDir'"
      "listNixDir"
    ];
    fixedPoints = [
      "rebase"
      "rebase'"
      "extendWith"
      "composeOverlaysWith"
      "composeOverlayListWith"
      "makeExtensibleWith"
      "safeExtendWith"
      "extends"
      "extendOverlays"
      "extendOverlayList"
      "makeExtensibleAs"
      "makeExtensible"
      "safeExtendAs"
      "safeExtend"
      "patches"
      "patchOverlays"
      "patchOverlayList"
      "makePatchableAs"
      "makePatchable"
      "safePatchAs"
      "safePatch"
      "augments"
      "augmentOverlays"
      "augmentOverlayList"
      "makeAugmentableAs"
      "makeAugmentable"
      "wrapLibOverlay"
      "wrapLibOverlay'"
      "safeAugmentAs"
      "safeAugment"
    ];
    lists = [
      "splitAt"
      "intersectListsBy"
    ];
    path = [
      "removeExtension"
      "removeNixExtension"
      "isDir"
      "isNix"
      "isHidden"
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
