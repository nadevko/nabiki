final: prev:
let
  inherit (builtins) attrNames isFunction;

  inherit (prev.trivial) id;

  inherit (final.attrsets) genTransposedAttrsBy;
in
rec {
  perRootIn = genTransposedAttrsBy id;

  perSystemIn =
    systems: flake: config:
    let
      isDynamic = isFunction config;
    in
    genTransposedAttrsBy (
      system:
      if config == { } then
        flake.legacyPackages.${system}
      else
        import flake ((if isDynamic then config system else config) // { inherit system; })
    ) systems;

  perSystem = flake: perSystemIn (attrNames flake.legacyPackages) flake;
}
