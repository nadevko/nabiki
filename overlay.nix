final: prev:
let
  k-lib = import ./lib.nix { inherit (prev) lib; };
  callSet = k-lib.makeCallSet (k-lib.getOverride { } { }) (
    k-lib.intersectListsBy (x: x.stem) [ "package" ] (k-lib.listShallowNixes ./pkgs)
  );
in
k-lib.composeOverlayList [
  (k-lib.wrapLibOverlay (k-lib.toOverlay prev.lib))
  (k-lib.wrapFinal callSet)
  (k-lib.unscopeToOverlay "kasumi" (k-lib.fixCallSet callSet))
]
