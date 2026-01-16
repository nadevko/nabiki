final: prev:
let
  inherit (builtins)
    length
    filter
    elem
    listToAttrs
    ;

  inherit (prev.trivial) max min;
  inherit (prev.lists) take drop;
  inherit (prev.attrsets) nameValuePair;
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

  subtractLists =
    minuend: subtrahend: if subtrahend == [ ] then minuend else filter (e: !elem e subtrahend) minuend;

  subtractStrings =
    minuend: subtrahend:
    if subtrahend == [ ] then
      minuend
    else
      let
        index = listToAttrs (map (e: nameValuePair (toString e)) subtrahend);
      in
      filter (e: !index ? "${e}") minuend;
}
