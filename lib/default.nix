{ lib, ... }:
let
  inherit (lib) hasPrefix hasSuffix;
in
{
  isNix = { name, type, ... }: hasSuffix ".nix" name || type == "directory";
  isNotUnderscored = { name, ... }: !hasPrefix "_" name;
}
