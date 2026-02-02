final: prev:
let
  inherit (builtins) isFunction;

  inherit (final.attrsets) genAttrsBy;

  inherit (prev.systems) flakeExposed;
  inherit (prev.attrsets) genAttrs;
in
rec {
  flakeSystems = flakeExposed;

  importFlakePkgs =
    flake: config: system:
    if config == { } then
      flake.legacyPackages.${system}
    else
      import flake <| { inherit system; } // (if isFunction config then config system else config);

  forAllSystems = genAttrs flakeSystems;
  forSystems = genAttrs;

  forAllPkgs = forPkgs flakeSystems;
  forPkgs =
    systems: flake: config:
    genAttrsBy (importFlakePkgs flake config) systems;
}
