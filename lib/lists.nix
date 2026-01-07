self: lib:
let
  inherit (builtins)
    length
    filter
    partition
    head
    tail
    ;

  inherit (lib.lists) take drop;
in
rec {
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

  sortOnList =
    predList: list:
    let
      tail' = tail predList;
      check = partition (head predList) list;
    in
    if tail' == [ ] then check.right else check.right ++ (sortOnList tail' check.wrong);
}
