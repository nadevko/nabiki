{
  pkgs ? import <nixpkgs> { },
  kasumi-lib ? import ./lib.nix { inherit (pkgs) lib; },
}:
(kasumi-lib.makeLegacyPackages (_: pkgs)).overrideList [
  (kasumi-lib.wrapLibOverlay "kasumi-lib" ./overlays/lib.nix)
  (import ./overlay.nix)
]
