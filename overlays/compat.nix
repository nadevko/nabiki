final: _:
let
  inherit (final.kasumi-lib.di) callWith;
in
{
  k = import ../lib { inherit (final) lib; };
  call = callWith final;
}
