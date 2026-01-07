self: lib:
let
  inherit (builtins) attrNames isFunction listToAttrs;
  inherit (lib.fixedPoints) fix';
  inherit (lib.trivial) flip;

  inherit (self.attrsets) genTransposedAs;
  inherit (self.fixedPoints) recExtends;
  inherit (self.trivial) compose;
  inherit (self.lists) sortOnList;
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

  getOverride =
    baseOverride: overrides: name:
    baseOverride // overrides.${name} or { };

  ensureDerivationOrder = compose sortOnList (map (target: { type, ... }: type == target));

  derivationSetFromDir = files: compose listToAttrs (ensureDerivationOrder files);
}
