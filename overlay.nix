final: _: {
  kasumi-update = final.callPackage ./pkgs/kasumi-update/package.nix { };
  kasumi-fmt = final.callPackage ./pkgs/kasumi-fmt/package.nix { };
}
