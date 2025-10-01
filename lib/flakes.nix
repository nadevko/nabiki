self: lib:
let
  inherit (builtins) listToAttrs filter catAttrs;

  inherit (lib.attrsets) nameValuePair;

  inherit (self.filesystem) listDirectory listNixFiles;
  inherit (self.trivial) fpipe;
  inherit (self.lists) filterOut;
  inherit (self.path) isDirectory isHidden concatNodesToNamesSep';
in
rec {
  listModulesFlatten = path: catAttrs "path" (listNixFiles path);

  getModulesFlattenSep =
    sep:
    fpipe [
      listNixFiles
      (map (concatNodesToNamesSep' true sep))
      (map ({ fullName, path, ... }: nameValuePair fullName path))
      listToAttrs
    ];

  readModulesFlatten = getModulesFlattenSep "-";

  getConfigurations' =
    builder: common: local:
    fpipe [
      listDirectory
      (filterOut isHidden)
      (filter isDirectory)
      (map ({ name, ... }@e: nameValuePair name (builder (common // local.${name} or { }) e)))
      listToAttrs
    ];

  getConfigurations =
    builder:
    getConfigurations' (
      args: { path, ... }: builder (args // { modules = listModulesFlatten path ++ args.modules or [ ]; })
    );

  getTemplates = getConfigurations' (args: { path, ... }: (args // { inherit path; }));
}
