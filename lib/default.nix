{ lib, ... }:
let
  inherit (builtins) filter;

  inherit (lib) hasPrefix hasSuffix;
in
{
  isNix = filter ({ name, type, ... }: hasSuffix ".nix" name || type == "directory");
  isNotUnderscored = filter ({ name, ... }: !hasPrefix "_" name);
}
