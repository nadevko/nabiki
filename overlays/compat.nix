final: _:
let
  inherit (final.kasumi-lib.di) callWith;
in
{
  kasumi-lib = import ../lib { inherit (final) lib; };
  call = callWith final;
}
