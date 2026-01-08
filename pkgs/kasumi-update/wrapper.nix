{ lib, writeShellApplication }:
let
  inherit (lib)
    isDerivation
    isAttrs
    isList
    getExe
    escapeShellArgs
    extendMkDerivation
    ;
in
extendMkDerivation {
  constructDrv = writeShellApplication;

  extendDrvArgs =
    _:
    {
      pkg,
      attrPath,
      name ? "update-${lib.replaceStrings [ "." ] [ "-" ] attrPath}",
      ...
    }:
    let
      rawScript = pkg.updateScript;
      scriptData =
        if isAttrs rawScript && !(isDerivation rawScript) then rawScript else { command = rawScript; };

      finalPath = scriptData.attrPath or attrPath;

      cmd =
        if isList scriptData.command then
          escapeShellArgs scriptData.command
        else if isDerivation scriptData.command then
          getExe scriptData.command
        else
          toString scriptData.command;
    in
    {
      inherit name;
      text = ''
        export UPDATE_NIX_NAME="${pkg.name or ""}"
        export UPDATE_NIX_PNAME="${pkg.pname or ""}"
        export UPDATE_NIX_OLD_VERSION="${pkg.version or ""}"
        export UPDATE_NIX_ATTR_PATH="${finalPath}"

        echo "=> Executing update for: ${finalPath}"
        ${cmd}
      '';
    };

  excludeDrvArgNames = [
    "pkg"
    "attrPath"
  ];
}
