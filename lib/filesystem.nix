self: lib:
let
  inherit (builtins)
    readDir
    mapAttrs
    attrValues
    catAttrs
    concatMap
    ;
  inherit (lib.lists) filter reverseList;
  inherit (lib.fixedPoints) composeExtensions;

  inherit (self.trivial) fpipe;
  inherit (self.lists) filterOut;
  inherit (self.path) isHidden isDirectory isImportableNix;
in
rec {
  readDirectory =
    path:
    mapAttrs (name: type: {
      inherit name type;
      path = /${path}/${name};
    }) (readDir path);

  listDirectory = path: attrValues (readDirectory path);

  readOverlaysDirectory =
    reader:
    fpipe [
      listDirectory
      (filterOut isHidden)
      (filter isDirectory)
      (catAttrs "path")
      (map reader)
      composeExtensions
    ];

  listNixFiles =
    let
      onDirectory =
        nodes:
        fpipe [
          listDirectory
          (filterOut isHidden)
          (concatMap (
            { name, path, ... }@value:
            if isImportableNix value then
              [ (value // { nodes = reverseList nodes; }) ]
            else if isDirectory value then
              onDirectory ([ name ] ++ nodes) path
            else
              [ ]
          ))
        ];
    in
    onDirectory [ ];
}
