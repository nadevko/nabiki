self: lib:
let
  inherit (lib.trivial) pipe flip;
in
{
  fpipe = flip pipe;
}
