final: prev:
let
  inherit (builtins) attrNames isFunction isAttrs;

  inherit (final.attrsets) genTransposedAttrs genTransposedAttrsBy;
  inherit (final.scopes) makeScopeWith;
in
rec {
  pkgsFrom =
    flake: config: system:
    if config == { } then
      flake.legacyPackages.${system}
    else
      import flake ({ inherit system; } // (if isFunction config then config system else config));

  perLegacyIn =
    systems: flake: config:
    genTransposedAttrsBy (pkgsFrom flake config) systems;

  perScopeIn =
    systems: flake: config: mixins:
    genTransposedAttrsBy (
      system: (makeScopeWith (pkgsFrom flake config system) (_: { })).fold mixins
    ) systems;

  forSystems =
    fn: flake:
    fn (if isAttrs (flake.legacyPackages or null) then attrNames flake.legacyPackages else flake) flake;

  perSystem = forSystems genTransposedAttrs;
  perLegacy = forSystems perLegacyIn;
  perScope = forSystems perScopeIn;
}
