{
  lib,
  writeShellApplication,
  callPackage,
}:
let
  inherit (builtins) isAttrs concatLists;
  inherit (lib)
    isDerivation
    mapAttrsToList
    unique
    concatMapStringsSep
    getExe
    extendMkDerivation
    ;

  wrap = callPackage ./wrapper.nix { };

  collect =
    abs: attrs:
    if isDerivation attrs then
      if attrs ? updateScript then
        [
          (wrap {
            pkg = attrs;
            inherit abs;
          })
        ]
      else
        [ ]
    else if isAttrs attrs && !(attrs ? __functor) then
      concatLists (
        mapAttrsToList (
          n: v:
          let
            nextPath = if abs == "" then n else "${abs}.${n}";
          in
          collect nextPath v
        ) attrs
      )
    else
      [ ];

in
extendMkDerivation {
  constructDrv = writeShellApplication;

  extendDrvArgs =
    _:
    {
      targetPackages,
      name ? "kasumi-collector",
      ...
    }:
    let
      updaters = unique (collect "" targetPackages);
    in
    {
      inherit name;
      text =
        if updaters == [ ] then
          ''
            echo "Kasumi Collector: No update scripts found in the specified target."
            exit 0
          ''
        else
          ''
            echo "Kasumi Collector: Found ${toString (builtins.length updaters)} update scripts."
            ${concatMapStringsSep "\n" (u: "echo \"[Running] ${u.name}...\" && ${getExe u}") updaters}
            echo "Done. All scripts executed."
          '';

      passthru = { inherit updaters; };
    };

  excludeDrvArgNames = [ "targetPackages" ];
}
