{ lib, ... }:
let
  inherit (lib.trivial) pipe flip;
  inherit (lib.lists) flatten;
in
rec {
  /**
    Like `pipe`, but functions are given as the first argument.
  */
  fpipe = flip pipe;

  /**
    `fpipe` that accepts nested lists of functions (it flattens them).
  */
  fpipeFlatten = fpipe [
    flatten
    fpipe
  ];

  /**
    `fpipeFlatten` that wraps passed functions with `wrap`.
  */
  fpipeFlattenWrap =
    wrap:
    fpipe [
      flatten
      wrap
      fpipe
    ];

  /**
    `fpipeFlatten` with every function wrapped in `builtins.map`.
  */
  fpipeFlattenMap = fpipeFlattenWrap (map map);
}
