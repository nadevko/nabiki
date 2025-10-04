{ self, lib, ... }:
let
  inherit (builtins)
    listToAttrs
    mapAttrs
    filter
    foldl'
    zipAttrsWith
    ;

  inherit (self.trivial) fpipeFlatten fpipeFlattenWrap fpipeFlattenMap;
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
        onNode = fpipeFlatten [
          readers
          filters
          perNode
          mergers
        ];
        perNode = fpipeFlattenMap [
          transformers
          onSwitch
        ];
        onSwitch = fpipeFlatten' [ switchers ];
        onLeaf = fpipeFlatten [ loaders ];
      };
      fpipeFlatten' = fpipeFlattenWrap (map (fn: fn (args // builder)));
    in
    fpipeFlatten [
      (fpipeFlatten' [ resolvers ])
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
