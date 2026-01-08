self: lib:
let
  inherit (builtins) length filter;

  inherit (lib.trivial) max min;
  inherit (lib.attrsets) genAttrs;
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

  intersectListsBy =
    pred: targets:
    let
      targetMap = genAttrs targets (_: true);
    in
    filter (x: targetMap ? ${pred x});
}
