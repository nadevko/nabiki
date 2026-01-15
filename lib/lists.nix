self: lib:
let
  inherit (builtins) length filter elem;

  inherit (lib.trivial) max min;
  inherit (lib.lists) take drop;
in
{
  splitAt =
    n: list:
    let
      len = length list;
      n' = max 0 (min len (if n < 0 then len + n else n));
    in
    {
      left = take n' list;
      right = drop n' list;
    };

  subtractLists = minuend: subtrahend: filter (e: !elem e subtrahend) minuend;
}
