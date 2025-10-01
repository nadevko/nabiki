self: lib:
let
  inherit (lib.meta) availableOn;
  inherit (lib.attrsets) filterAttrs;

  inherit (self.fixedPoints) recExtends;
in
{
  wrapLibExtension = libOverlay: final: prev: {
    lib = recExtends libOverlay (_: prev.lib) final.lib;
  };

  wrapWithAvailabilityCheck =
    overlay: final: prev:
    filterAttrs (_: availableOn prev.system) (overlay final prev);
}
