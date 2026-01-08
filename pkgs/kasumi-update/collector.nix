{ lib, writeShellApplication, callPackage }:
let
  inherit (lib) 
    isDerivation isAttrs mapAttrsToList 
    concatLists unique concatMapStringsSep getExe extendMkDerivation;

  wrap = callPackage ./wrapper.nix { };

  collect = path: attrs:
    if isDerivation attrs then
      if attrs ? updateScript 
      then [ (wrap { pkg = attrs; inherit path; }) ] 
      else [ ]
    else if isAttrs attrs && !(attrs ? __functor) then
      concatLists (mapAttrsToList (n: v: 
        let nextPath = if path == "" then n else "${path}.${n}";
        in collect nextPath v
      ) attrs)
    else [ ];

in
extendMkDerivation {
  constructDrv = writeShellApplication;

  extendDrvArgs = _: { targetPackages, name ? "kasumi-collector", ... }:
    let
      updaters = unique (collect "" targetPackages);
      count = builtins.length updaters;
    in
    {
      inherit name;
      text = if count == 0 then ''
        echo "Kasumi Collector: No update scripts found in the specified target."
        exit 0
      '' else ''
        echo "Kasumi Collector: Found ${toString count} update scripts."
        ${concatMapStringsSep "\n" (u: "echo \"[Running] ${u.name}...\" && ${getExe u}") updaters}
        echo "Done. All scripts executed."
      '';

      passthru = { inherit updaters; };
    };

  excludeDrvArgNames = [ "targetPackages" ];
}
