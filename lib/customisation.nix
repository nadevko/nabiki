self: lib:
let
  inherit (builtins) attrNames isFunction mapAttrs;
  inherit (lib.fixedPoints) fix';
  inherit (lib.trivial) flip;
  inherit (lib.customisation) makeScope;

  inherit (self.attrsets) genTransposedAs;
  inherit (self.fixedPoints) recExtends;
in
rec {
  genFromPkgsFor =
    pkgs: config:
    genTransposedAs (
      system:
      if config == null then
        pkgs.legacyPackages.${system}
      else if isFunction config then
        import pkgs (config system)
      else
        import pkgs (config // { inherit system; })
    );

  genFromPkgs = pkgs: config: genFromPkgsFor pkgs config (attrNames pkgs.legacyPackages);

  wrapLibOverlay = g: final: prev: { lib = fix' (recExtends (_: _: prev.lib) (flip g prev.lib)); };

  getOverride =
    baseOverride: overrides: name:
    baseOverride // overrides.${name} or { };

  mapCallPackage =
    getOverride: callPackage: set:
    mapAttrs (name: flip callPackage (getOverride name)) set;

  mapFinalCallPackage = getOverride: final: mapCallPackage getOverride final.callPackage;

  makeUnscope = flip makeScope;

  rebaseScope = scope: scope.packages scope;
  rebaseUnscope = unscope: pkgs: rebaseScope (unscope pkgs.newScope);

  unscopeToOverlay =
    unscope: final: prev:
    let
      scope = unscope prev.newScope;
    in
    rebaseScope scope;

  unscopeToOverlay' =
    name: unscope: final: prev:
    let
      scope = unscope prev.newScope;
    in
    { ${name} = scope; } // rebaseScope scope;
}
