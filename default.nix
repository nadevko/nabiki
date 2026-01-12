{
  pkgs ? import <nixpkgs> { },
  kasumi-lib ? import ./lib.nix { inherit (pkgs) lib; },
}:
pkgs.extend (
  kasumi-lib.fixedPoints.composeOverlayList [
    (kasumi-lib.fixedPoints.wrapLibOverlay (_: prev: import ./lib.nix { inherit (prev) lib; }))
    (import ./overlay.nix)
  ]
)
