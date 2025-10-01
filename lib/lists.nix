{ ... }:
let
  inherit (builtins) head tail length;
in
{
  splitAt =
    n: list:
    let
      n' = if n < 0 then length list + n else n;
      split =
        i: list:
        if i >= n' then
          list
        else
          split (i + 1) {
            init = list.init ++ [ (head list.tail) ];
            tail = tail list.tail;
          };
    in
    if n' >= length list then
      {
        init = list;
        tail = [ ];
      }
    else
      split 0 {
        init = [ ];
        tail = list;
      };
}
