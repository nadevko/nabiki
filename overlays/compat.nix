final: _:
let
  inherit (final.k.di) callWith;
in
{
  k = import ../lib { inherit (final) lib; };
  call = callWith final;
}
