self: lib:
let
  inherit (builtins) length filter;

  inherit (lib.lists) take drop;
in
{
  splitAt =
    n: list:
    let
      len = length list;
      n' = if n < 0 then len + n else n;
      n'' =
        if n' < 0 then
          0
        else if n' > len then
          len
        else
          n';
    in
    {
      init = take n'' list;
      tail = drop n'' list;
    };

  filterOut = pred: filter (e: !pred e);
}
