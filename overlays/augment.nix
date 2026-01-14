final: prev:
let
  kasumi-lib = import ../lib.nix { inherit (prev) lib; };
in
kasumi-lib.wrapLibOverlay' "kasumi-lib" (_: _: kasumi-lib) final prev
