{ lib, ... }:
let
  inherit (builtins) filter;

  inherit (lib) hasPrefix hasSuffix;
in
{
  /**
    Filter that selects all Nix source files (files with a .nix suffix) and directories.
  */
  isNix = filter ({ name, type, ... }: hasSuffix ".nix" name || type == "directory");
  /**
    Filter that excludes files whose names begin with an underscore.
  */
  isNotUnderscored = filter ({ name, ... }: !hasPrefix "_" name);
}
