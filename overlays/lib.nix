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
      "closestAttrByPath"
      "mapAttrsIntersection"
      "bind"
      "partitionAttrs"
      "zipMerge"
      "transposeAttrs"
      "perWith"
      "per"
      "perSystemIn"
      "perSystem"
      "extractAliases"
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
      "makeCallExtensibleAs"
      "makeCallExtensible"
      "makeScope"
    ];
    filesystem = [
      "scanDirWith"
      "scanDir"
      "nestedScanDir"
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
      "listShallowNixes"
      "nestedListShallowNixes"
    ];
    fixedPoints = [
      "extendBy"
      "composeOverlaysBy"
      "composeOverlayListBy"
      "makeExtensibleBy"
      "extends"
      "composeOverlays"
      "composeOverlayList"
      "makeExtensibleAs"
      "makeExtensible"
      "rebase"
      "rebase'"
      "wrapLibOverlay"
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
      "pipeF"
    ];
  };
in
attrsets.addAliasesToAttrs aliases set // set
