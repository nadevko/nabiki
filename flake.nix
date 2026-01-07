{
  description = "lib with some handy nix functions";

  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
  };

  outputs =
    { nixpkgs, ... }@inputs:
    let
      lib = import ./lib.nix { inherit (nixpkgs) lib; };
    in
    {
      inherit lib;
      overlays = {
        default = lib.readPackagesScope { } { } [ "package.nix" ];
        lib = lib.wrapLibExtension (_: _: lib);
        private = _: _: { inherit inputs; };
      };
      __functor = lib.mkflake;
    };
}
