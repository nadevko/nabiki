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
  inherit (lib.fixedPoints) fix composeManyExtensions;
  inherit (lib.trivial) flip;

  inherit (self.attrsets) mapIntersectedAttrs;
  inherit (self.filesystem) listNixFiles;
  inherit (self.trivial) fpipe';
  inherit (self.path) concatNodesToNamesSep;
in
rec {
  readPackagesOverlayBase =
    targets: sep: path:
    let
      g =
        final: prev:
        fpipe' [
          listNixFiles
          (map (concatNodesToNamesSep sep))
          (groupBy ({ name, ... }: name))
          (mapIntersectedAttrs (_: targets: targets final prev) targets)
          attrValues
          mergeAttrsList
        ] path;
    in
    g;

  readPackagesOverlaySep = readPackagesOverlayBase {
    "package.nix" = makePackageNixExtension;
    "overlay.nix" = makeOverlayNixExtension;
  };
  readPackagesOverlay = readPackagesOverlaySep "-";

  groupUniqueByFullName = fpipe' [
    (groupBy ({ fullName, ... }: fullName))
    (mapAttrs (_: head))
  ];

  makePackageNixExtension =
    final: prev:
    fpipe' [
      groupUniqueByFullName
      (mapAttrs (name: { path, ... }: final.callPackage' name path))
    ];

  makeOverlayNixExtension =
    final: prev:
    fpipe' [
      (catAttrs "path")
      (map import)
      composeManyExtensions
      (g: g final prev)
    ];

  readDevShellsOverlaySep = readPackagesOverlayBase { "shell.nix" = makePackageNixExtension; };
  readDevShellsOverlay = readDevShellsOverlaySep "-";

  readCheckOverlaySep = readPackagesOverlayBase { "check.nix" = makePackageNixExtension; };
  readCheckOverlay = readCheckOverlaySep "-";

  readHydraJobsOverlaySep = readPackagesOverlayBase { "hydraJob.nix" = makePackageNixExtension; };
  readHydraJobsOverlay = readHydraJobsOverlaySep "-";

  readOverlaysSep =
    sep:
    fpipe' [
      listNixFiles
      (map (concatNodesToNamesSep sep))
      (map ({ fullName, path, ... }: nameValuePair fullName path))
      listToAttrs
    ];
  readOverlays = readOverlaysSep "-";

  readAppsOverlaySep = readPackagesOverlayBase { "app.nix" = makePackageNixExtension; };
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
    // fpipe' [
      (flip removeAttrs (attrNames intersection))
      (mapAttrs (_: app: common // { program = getProgram app; }))
    ] apps;
}
