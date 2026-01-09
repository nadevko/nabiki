self: lib:
let
  inherit (lib.trivial) flip pipe;
in
{
  compose =
    f: g: x:
    f (g x);

  pipeF = flip pipe;
}
