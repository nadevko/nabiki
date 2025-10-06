{ ... }:
let
  inherit (builtins) head tail length;
in
{
  /**
    Split a list into `init` and `tail` parts.

    - `init` will be at most `n` elements long.
    - Any overflow is placed into `tail`.
    - If `n` is negative, it is interpreted relative to the list length
      (i.e. length + n).

    Returns an attribute set `{ init = [...]; tail = [...] }`.
  */
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
