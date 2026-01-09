self: lib:
let
  inherit (builtins) attrNames isFunction mapAttrs;
  inherit (lib.fixedPoints) fix';
  inherit (lib.trivial) flip;
  inherit (lib.attrsets) recursiveUpdate;
  inherit (lib.customisation) makeScope;

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

  makeCallSet =
    getOverride: set: final:
    mapAttrs (name: flip final.callPackage (getOverride name)) set;

  callScope =
    { newScope, ... }:
    path: override: makeScope newScope (final: newScope { inherit (final) callPackage; } path override);

  makeScopeSet =
    getOverride: set: final:
    mapAttrs (name: path: callScope final path (getOverride name)) set;

  makeUnscope = f: { newScope, ... }: makeScope newScope f;
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
