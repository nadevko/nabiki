{
  pkgs ? import <nixpkgs> { },
  kasumi-lib ? import ./lib.nix { inherit (pkgs) lib; },
}:
(kasumi-lib.makeLegacyPackages (_: pkgs)).extend (
  kasumi-lib.composeOverlays (kasumi-lib.wrapLibOverlay (import ./overlays/lib.nix)) (
    import ./overlay.nix
  )
)
