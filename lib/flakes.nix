final: prev:
let
  inherit (builtins) isFunction;

  inherit (prev.systems) flakeExposed;
  inherit (prev.attrsets) genAttrs;

  inherit (final.attrsets) genTransposedAttrsBy genTransposedAttrs genAttrsBy;
in
rec {
  flakeSystems = flakeExposed;

  pkgsFrom =
    flake: config: system:
    if config == { } then
      flake.legacyPackages.${system}
    else
      import flake ({ inherit system; } // (if isFunction config then config system else config));

  eachPkgsIn =
    systems: flake: config:
    genTransposedAttrsBy (pkgsFrom flake config) systems;
  eachPkgs = eachPkgsIn flakeSystems;

  forPkgsIn =
    systems: flake: config:
    genAttrsBy (pkgsFrom flake config) systems;
  forPkgs = forPkgsIn flakeSystems;

  eachSystemIn = genTransposedAttrs;
  eachSystem = eachSystemIn flakeSystems;

  forSystemsIn = genAttrs;
  forSystems = forSystemsIn flakeSystems;
}
