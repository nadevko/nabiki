{
  flake_path,
  target,
  system,
  collector,
}:
let
  source =
    let
      maybeFlake = builtins.tryEval (builtins.getFlake flake_path);
    in
    if maybeFlake.success then maybeFlake.value else import flake_path { };

  targetContent =
    if source ? outputs then
      (source.outputs.${target}.${system} or source.outputs.legacyPackages.${system}.${target} or { })
    else
      (source.${target} or source);
in
collector {
  name = "kasumi-run-${target}";
  targetPackages = targetContent;
}
