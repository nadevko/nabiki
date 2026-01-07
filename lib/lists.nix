self: lib:
let
  inherit (builtins) length;

  inherit (lib.trivial) max min;
  inherit (lib.lists) take drop;
in
{
  splitAt = n: list:
    let
      len = length list;
      n' = max 0 (min len (if n < 0 then len + n else n));
    in
    { init = take n' list; tail = drop n' list; };
}
