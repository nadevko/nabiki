self: lib:
let
  inherit (builtins)
    listToAttrs
    attrNames
    removeAttrs
    groupBy
    mapAttrs
    attrValues
    head
    catAttrs
    isFunction
    ;

  inherit (lib.attrsets) mergeAttrsList nameValuePair;
  inherit (lib.fixedPoints) fix composeExtensions composeManyExtensions;
  inherit (lib.trivial) flip;
  inherit (lib.customisation) callPackageWith;

  inherit (self.attrsets) mapIntersectedAttrs;
  inherit (self.filesystem) listNixFiles;
  inherit (self.trivial) fpipe;
  inherit (self.path) concatNodesToNamesSep;
  inherit (self.customisation) wrapWithAvailabilityCheck;
in
rec {
  readPackagesOverlayBase =
    targets: sep: overrides: private: path:
    let
      overlay =
        final: prev:
        let
          pkgs = prev.extend (composeExtensions private overlay);
          final' = final // rec {
            callPackage = callPackageWith pkgs;
            callPackage' = name: flip callPackage (overrides.${name} or { });
          };
        in
        fpipe [
          listNixFiles
          (map (concatNodesToNamesSep sep))
          (groupBy ({ name, ... }: name))
          (mapIntersectedAttrs (_: targets: targets final' prev) targets)
          attrValues
          mergeAttrsList
        ] path;
    in
    overlay;

  readPackagesOverlaySep = readPackagesOverlayBase {
    "package.nix" = callFirstAsPackage;
    "overlay.nix" = loadAllAsOverlay;
    "builder.nix" = callFirstAsOverlay;
  };
  readPackagesOverlay = readPackagesOverlaySep "-";

  readCheckedPackagesOverlaySep = readPackagesOverlayBase {
    "package.nix" = wrapWithAvailabilityCheck callFirstAsPackage;
    "overlay.nix" = wrapWithAvailabilityCheck loadAllAsOverlay;
    "builder.nix" = callFirstAsOverlay;
  };
  readCheckedPackagesOverlay = readCheckedPackagesOverlaySep "-";

  callFirstAsPackage =
    final: prev:
    fpipe [
      (groupBy ({ fullName, ... }: fullName))
      (mapAttrs (_: head))
      (mapAttrs (name: { path, ... }: final.callPackage' name path))
    ];

  loadAllAsOverlay =
    final: prev:
    fpipe [
      (catAttrs "path")
      (map import)
      composeManyExtensions
      (overlay: overlay final prev)
    ];

  callFirstAsOverlay =
    final: prev:
    fpipe [
      (groupBy ({ fullName, ... }: fullName))
      (mapAttrs (_: head))
      (mapAttrs (name: { path, ... }: import path final prev))
    ];

  readDevShellsOverlaySep = readPackagesOverlayBase { "shell.nix" = callFirstAsPackage; };
  readDevShellsOverlay = readDevShellsOverlaySep "-";

  readCheckOverlaySep = readPackagesOverlayBase { "check.nix" = callFirstAsPackage; };
  readCheckOverlay = readCheckOverlaySep "-";

  readHydraJobsOverlaySep = readPackagesOverlayBase { "hydraJob.nix" = callFirstAsPackage; };
  readHydraJobsOverlay = readHydraJobsOverlaySep "-";

  readOverlaysSep =
    sep:
    fpipe [
      listNixFiles
      (map (concatNodesToNamesSep sep))
      (map ({ fullName, path, ... }: nameValuePair fullName path))
      listToAttrs
    ];
  readOverlays = readOverlaysSep "-";

  readAppsOverlaySep = readPackagesOverlayBase { "app.nix" = callFirstAsPackage; };
  readAppsOverlay = readAppsOverlaySep "-";
  getApps =
    common: locals: overrides: private: path: prev:
    let
      apps = fix (readAppsOverlay overrides private path) prev;
      getProgram = app: "${app.outPath}/bin/${app.meta.mainProgram}";
      intersection = mapIntersectedAttrs (
        name: app: manifest:
        manifest
        // {
          program =
            let
              program' = manifest.program or common.program or app;
            in
            if isFunction program' then program' app else program';
        }
      ) apps locals;
    in
    intersection
    // removeAttrs locals (attrNames intersection)
    // fpipe [
      (flip removeAttrs (attrNames intersection))
      (mapAttrs (_: app: common // { program = getProgram app; }))
    ] apps;
}
