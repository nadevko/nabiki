{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixos-unstable";
  };

  outputs =
    { self, nixpkgs, ... }:
    let
      lib = import ./. { inherit (nixpkgs) lib; };
    in
    {
      inherit lib;
      __functor = _: self.lib.attrsets.nestAttrs;
    }
    // lib.nestAttrs nixpkgs.lib.platforms.unix (system: {
      packages = self.lib.readPackages {
        path = ./pkgs;
        overrides.lib = nixpkgs.lib // self.lib;
        pkgs = nixpkgs.legacyPackages.${system};
      };
    });
}
