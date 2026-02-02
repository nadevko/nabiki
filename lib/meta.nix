final: prev:
let
  inherit (builtins) elem;

  inherit (prev.attrsets) isDerivation;
in
{
  isSupportedDerivation =
    system: v:
    isDerivation v
    && !(v.meta.broken or false)
    && (v.meta ? badPlatforms -> !elem system v.meta.badPlatforms)
    && (v.meta ? platforms -> elem system v.meta.platforms);
}
