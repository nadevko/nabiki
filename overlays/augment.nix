final: prev:
let
  kasumi-lib = import ../lib { inherit (prev) lib; };
in
kasumi-lib.augmentLibAs "kasumi-lib" (_: _: kasumi-lib) final prev
