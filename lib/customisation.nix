self: lib:
let
  inherit (lib.fixedPoints) extends;

  inherit (self.fixedPoints) recExtends;
in
rec {
  wrapLibExtension = g: final: prev: {
    lib = recExtends g (_: prev.lib) final.lib // {
      __unfix__ = prev.lib;
    };
  };

  makeScope' =
    extraProtected: newScope: fPublic:
    let
      self = fPublic self // protected;
      protected = extraProtected {
        newScope = private: newScope (self // private);
        callPackage = self.newScope { };
        overrideScope' = extraProtected: g: makeScope' extraProtected newScope (extends g fPublic);
        overrideScope = self.overrideScope' { };
        packages = fPublic;
      };
    in
    self;

  makeScope = makeScope' { };
}
