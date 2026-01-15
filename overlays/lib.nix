final: prev:
let
  attrsets = import ../lib/attrsets.nix final prev;
  set = {
    inherit attrsets;
    customisation = import ../lib/customisation.nix final prev;
    debug = import ../lib/debug.nix final prev;
    filesystem = import ../lib/filesystem.nix final prev;
    fixedPoints = import ../lib/fixedPoints.nix final prev;
    lists = import ../lib/lists.nix final prev;
    maintainers = import ../lib/maintainers.nix final prev;
    path = import ../lib/path.nix final prev;
    trivial = import ../lib/trivial.nix final prev;
  };
in
attrsets.addAttrsAliases {
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
    "makeAttrsAliases"
    "addAttrsAliases"
    "getAliasList"
    "addAttrsAliasesWith'"
    "addAttrsAliases'"
    "makeCallSetWith"
    "makeCallPackageSet"
    "makeCallScopeSet"
    "flatMapAttrs"
    "morphAttrs"
    "shouldRecurseForDerivations"
  ];
  customisation = [
    "getOverride"
    "callPackageWith"
    "callScopeWith"
    "makeScope"
  ];
  debug = [
    "genPosLibErrorMessage"
    "getAttrPos"
    "validateLibAliasesWith"
    "validateLibWith"
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
    "safeAugmentAs"
    "safeAugment"
    "wrapLibOverlay"
    "wrapLibOverlay'"
  ];
  lists = [
    "splitAt"
    "subtractLists"
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
  ];
} set
