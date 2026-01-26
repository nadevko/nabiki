final: prev:
let
  inherit (final.kasumi-lib.di) callWith;
  inherit (final.kasumi-lib.overlays) lay foldLay;

  rattrs = final: { };
in
{
  kasumi-lib = import ../lib { inherit (final) lib; };

  context = final;

  makeScope = final.kasumi-lib.makeScopeWith final;
  fuse = g: final.makeScope (lay g rattrs);
  fold = gs: final.makeScope (lay (foldLay gs) rattrs);
  rebase = g: final.makeScope (final': g final' final);

  call = callWith final;
}
