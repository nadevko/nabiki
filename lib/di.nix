final: prev:
let
  inherit (builtins)
    attrNames
    functionArgs
    intersectAttrs
    filter
    head
    length
    concatStringsSep
    concatMap
    ;
  inherit (prev.lists)
    take
    sortOn
    init
    last
    findFirst
    ;
  inherit (prev.strings) levenshteinAtMost levenshtein;
  inherit (prev.customisation) makeOverridable;

  inherit (final.trivial) invoke compose;
  inherit (final.overlays) lay foldLay;
  inherit (final.debug) attrPos;
in
rec {
  callWith =
    context: f: overrides:
    let
      callee = invoke f;
      calleeArgs = functionArgs callee;
      callAttrs = intersectAttrs calleeArgs context // overrides;
      missing = findFirst (n: !(callAttrs ? ${n} || calleeArgs.${n})) null <| attrNames calleeArgs;
    in
    if missing == null then
      callee callAttrs
    else
      let
        suggestions =
          [
            overrides
            context
          ]
          |> concatMap attrNames
          |> filter (levenshteinAtMost 2 missing)
          |> sortOn (levenshtein missing)
          |> take 3;

        didYouMean =
          if suggestions == [ ] then
            ""
          else if length suggestions == 1 then
            ", did you mean '${head suggestions}'?"
          else
            ", did you mean '${concatStringsSep "', '" <| init suggestions}' or '${last suggestions}'?";

        pos = attrPos missing calleeArgs;
      in
      abort "kasumi.lib.di.callWith: Function called without required argument '${missing}' at ${pos}${didYouMean}";

  callPackageBy = call: f: invoke f |> call |> makeOverridable;
  callPackageWith = compose callPackageBy callWith;

  makeScopeWith =
    prev: rattrs:
    let
      pkgs = prev // self;
      extension = rattrs pkgs;
      self = extension // {
        inherit pkgs extension;
        __unfix__ = rattrs;

        makeScope = makeScopeWith pkgs;
        # conflict with pkgs.fuse -_-
        # I want to rename it: pkgs.fuse   ->  pkgs.libfuse
        #                      pkgs.fuse3  ->  pkgs.libfuse3
        # fuse = g: self.makeScope (lay g rattrs);
        fuses = g: self.makeScope <| lay g rattrs;
        fold = gs: self.makeScope <| lay (foldLay gs) rattrs;
        rebase = g: self.makeScope (self: g self pkgs);

        call = callWith pkgs;
        callPackage = callPackageBy self.call;
      };
    in
    self;
}
