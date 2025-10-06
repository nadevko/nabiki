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
  /**
    Generic pipeline attribute-set traverser that returns a list of processed nodes.

    Arguments:
    - `path`       : the input data to traverse.
    - `resolvers`  : helpers that convert a generic `path` into the actual traverse root.
    - `readers`    : functions used to obtain node content.
    - `filters`    : predicates deciding which of the read nodes are included in the result.
    - `transformers`: functions that transform a node before branching/processing.
    - `switchers`  : functions that decide whether to treat a node as a branch or a leaf.
    - `loaders`    : functions that load or materialise a node's value.
    - `mergers`    : functions that merge loaded nodes into the pipeline result.
    - `updaters`   : post-processors applied to the pipeline result.

    The function is intentionally generic and composable: pass lists of small helpers
    which will be composed into a processing pipeline.
  */
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
    fpipeFlatten [ resolvers updaters ] path;

  /**
    `pipelineTraverse` wrapper that produces a tree-like structure instead of a flat list.

    It configures `pipelineTraverse` so that directory nodes contain `nodes` arrays
    and leaf nodes contain `value`s suitable for building nested attribute sets.
  */
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

  /**
    * Generate an attribute set from `roots`. `reader` is applied to each root and
    * `generator` is used to transform the reader results into attribute sets.
    *
    * Useful in flakes to produce system-dependent outputs when the `system` is not
    * needed directly.

    * ```nix
    * {
    *   inputs = {
    *     nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";
    *
    *     n = {
    *       url = "github:nadevko/nabiki";
    *       inputs.nixpkgs.follows = "nixpkgs";
    *     };
    *   };
    *
    *   outputs = { n, nixpkgs, ...}:
    *     n (system: nixpkgs.legacyPackages.${system}) [ "x86_64-linux" ]
    *     (pkgs: {
    *       # some `pkgs`-depend stuff...
    *     });
    * }
    * ```
  */
  nestAttrs' =
    reader: roots: generator:
    zipAttrsWith (_: foldl' (a: b: a // b) { }) (
      map (root: mapAttrs (_: value: { ${root} = value; }) (generator (reader root))) roots
    );

  /**
    * Convenience wrapper around `nestAttrs'` with identity `reader`.
    *
    * Can be used as a flake functor:

    *  ```nix
    *  {
    *    inputs = {
    *      nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    *     n = {
    *       url = "github:nadevko/nabiki";
    *       inputs.nixpkgs.follows = "nixpkgs";
    *     };
    *   };

    *    outputs = { n, ...}: n [ "x86_64-linux" ] (system: {
    *      # some `system`-depend stuff...
    *    });
    *  }
    *  ```
  */
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
