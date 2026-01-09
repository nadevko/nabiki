self: lib:
let
  inherit (builtins)
    attrNames
    isFunction
    mapAttrs
    listToAttrs
    ;
  inherit (lib.fixedPoints) fix';
  inherit (lib.trivial) flip;
  inherit (lib.customisation) makeScope;
  inherit (lib.attrsets) recursiveUpdate;

  inherit (self.attrsets) genTransposedAs;
  inherit (self.fixedPoints) wrapPrev;
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

  getOverride =
    baseOverride: overrides: name:
    baseOverride // overrides.${name} or { };

  mapCallPackage = getOverride: callPackage: mapAttrs (name: flip callPackage (getOverride name));

  makeCallSet =
    getOverride: list: final:
    mapCallPackage getOverride final.callPackage (listToAttrs list);

  fixCallSet = f: { newScope, ... }: makeScope newScope f;

  rebaseScope = scope: scope.packages scope;

  wrapLibOverlay =
    g:
    wrapPrev (prev: {
      lib = fix' (final: recursiveUpdate prev.lib (g final prev.lib));
    });
  unscopeToOverlay =
    name: unscope:
    wrapPrev (prev: {
      ${name} = unscope prev;
    });
}
