{ self, lib, ... }:
let
  inherit (builtins)
    listToAttrs
    mapAttrs
    filter
    foldl'
    zipAttrsWith
    ;

  inherit (self.trivial) flatPipe flatPipeWith mapPipe;
  inherit (self.filesystem) itemiseDir switchDirFile;

  inherit (lib.lists) init head last;
in
rec {
  pipelineTraverse =
    {
      path,
      resolvers ? nodePathResolver,
      readers ? itemiseDir,
      filters ? [ ],
      transformers ? [ ],
      switchers ? switchDirFile,
      loaders ? [ ],
      mergers ? [ ],
      updaters ? [ ],
      ...
    }@args:
    let
      builder = rec {
        onNode = flatPipe [
          readers
          filters
          perNode
          mergers
        ];
        perNode = mapPipe [
          transformers
          onSwitch
        ];
        onSwitch = flatPipe' [ switchers ];
        onLeaf = flatPipe [ loaders ];
      };
      flatPipe' = flatPipeWith (map (fn: fn (args // builder)));
    in
    flatPipe [
      (flatPipe' [ resolvers ])
      updaters
    ] path;

  treeishTraverse =
    {
      loaders ? [ ],
      mergers ? [ ],
      updaters ? [ ],
      ...
    }@args:
    pipelineTraverse (
      args
      // {
        loaders = [
          ({ nodes, ... }@entry: entry // { nodes = [ "" ] ++ nodes; })
          loaders
        ];
        mergers = [
          (filter (x: x != [ ]))
          (leaf: {
            name = last (head leaf).nodes;
            nodes = init (head leaf).nodes;
            value = listToAttrs leaf;
          })
          mergers
        ];
        updaters = [
          (x: x.value)
          updaters
        ];
      }
    );

  nestAttrs' =
    reader: roots: generator:
    zipAttrsWith (_: foldl' (a: b: a // b) { }) (
      map (root: mapAttrs (_: value: { ${root} = value; }) (generator (reader root))) roots
    );

  nestAttrs = nestAttrs' (x: x);

  setNameToValue =
    { name, value, ... }:
    {
      ${name} = value;
    };

  nodePathResolver =
    { onNode, ... }:
    path:
    onNode {
      nodes = [ ];
      value = path;
    };
}
