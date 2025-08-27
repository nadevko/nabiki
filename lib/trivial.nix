{ lib, ... }:
let
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
}
