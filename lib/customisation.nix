self: lib:
let
  inherit (builtins) attrNames isFunction foldl';
  inherit (lib.fixedPoints) fix';
  inherit (lib.trivial) flip;
  inherit (lib.customisation) makeScope;

  inherit (self.fixedPoints) recExtends;
  inherit (self.attrsets) genTransposedAs;
in
rec {
  genFromNixpkgsFor =
    nixpkgs: config:
    genTransposedAs (
      system:
      if config == null then
        nixpkgs.legacyPackages.${system}
      else if isFunction config then
        import nixpkgs (config system)
      else
        import nixpkgs (config // { inherit system; })
    );

  genFromNixpkgs =
    nixpkgs: config: genFromNixpkgsFor nixpkgs config (attrNames nixpkgs.legacyPackages);

  wrapLibExtension = g: final: prev: { lib = fix' (recExtends (_: _: prev.lib) (flip g prev.lib)); };

  makeScopeFromExtension = newScope: (makeScope newScope (_: { })).overrideScope;
  composeScopeFromExtensionList =
    newScope: foldl' ({ newScope, ... }: makeScopeFromExtension newScope) (makeScope newScope (_: { }));
  triComposeScope =
    newScope: private: public: overrides:
    (composeScopeFromExtensionList newScope [
      private
      public
    ]).overrideScope
      overrides;
  fixScope = scope: scope.packages scope;
}
