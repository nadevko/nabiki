{
  pkgs ? import <nixpkgs> { },
  kasumi-lib ? import ./lib.nix { inherit (pkgs) lib; },
}:
pkgs.extend (
  kasumi-lib.composeOverlayList [
    (kasumi-lib.wrapLibOverlay (_: prev: import ./lib.nix { inherit (prev) lib; }))
    (import ./overlay.nix)
  ]
)
