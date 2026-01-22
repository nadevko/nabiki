final: prev: {
  lib =
    let
      inherit (final) kasumi-lib;
      inherit (kasumi-lib.trivial) fix mixr;
    in
    fix (mixr (_: _: kasumi-lib) (_: prev.lib));
  kasumi-lib = import ../lib { inherit (prev) lib; };
}
