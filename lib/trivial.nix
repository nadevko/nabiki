{ lib, ... }:
let
  inherit (builtins) isList;

  inherit (lib.trivial) pipe flip;
  inherit (lib.lists) flatten;
in
rec {
  fpipe = flip pipe;

  flatPipe = fpipe [
    flatten
    fpipe
  ];

  flatPipeWith =
    wrap:
    fpipe [
      flatten
      wrap
      fpipe
    ];

  mapPipe = flatPipeWith (map map);

  deepPipe = fns: fpipe (map (fn: if isList fn then deepPipe fn else fn) fns);
}
