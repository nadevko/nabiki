{ lib, ... }:
let
  inherit (builtins) isList;

  inherit (lib.trivial) pipe flip;
  inherit (lib.lists) flatten;
in
rec {
  fpipe = flip pipe;

  fpipeFlatten = fpipe [
    flatten
    fpipe
  ];

  fpipeFlattenWrap =
    wrap:
    fpipe [
      flatten
      wrap
      fpipe
    ];

  fpipeFlattenMap = fpipeFlattenWrap (map map);

  deepPipe = fns: fpipe (map (fn: if isList fn then deepPipe fn else fn) fns);
}
