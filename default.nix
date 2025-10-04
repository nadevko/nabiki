{
  lib ? import <nixpkgs/lib>,
  ...
}:
let
  self = import ./lib inputs // {
    attrsets = import ./lib/attrsets.nix inputs;
    customisation = import ./lib/customisation.nix inputs;
    filesystem = import ./lib/filesystem.nix inputs;
    trivial = import ./lib/trivial.nix inputs;
    path = import ./lib/path.nix inputs;
    lists = import ./lib/lists.nix inputs;
  };
  inputs = { inherit lib self; };
in
self.attrsets
// self.customisation
// self.filesystem
// self.trivial
// self.path
// self.lists
// self
