final: prev:
let
  inherit (final.kasumi-lib.di) callWith;
  inherit (final.kasumi-lib.overlays) lay foldLay;

  rattrs = self: { };
in
{
  kasumi-lib = import ../lib { inherit (final) lib; };

  context = final;

  makeScope = final.kasumi-lib.makeScopeWith final;
  # conflict with pkgs.fuse -_-
  # I want to rename it: pkgs.fuse   ->  pkgs.libfuse
  #                      pkgs.fuse3  ->  pkgs.libfuse3
  # fuse = g: final.makeScope (lay g rattrs);
  fuze = g: final.makeScope (lay g rattrs);
  fold = gs: final.makeScope (lay (foldLay gs) rattrs);
  rebase = g: final.makeScope (final': g final' final);

  call = callWith final;
}
