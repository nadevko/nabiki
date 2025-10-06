# nabiki

> A small library named after a random anime character.

`nabiki` provides a set of composable helpers for loading modules and packages in Nix flakes and for building small, maintainable flake layouts. It aims to sit between heavy frameworks (e.g. `flake-parts`) and tiny one-function solutions (`mkflake`): simple enough for straightforward repos, but composable enough to avoid repetitive template code for larger projects.

## Motivation

Existing approaches to organising flakes each have trade-offs:

* `flake-parts` can be overly complicated for simple declarative manifests.
* Single-function solutions such as some `mkflake` flavours are easy to start with but require a lot of templating for anything beyond the simplest projects.
* `snowfall`-like approaches may be close to what I want, but they introduce extra abstractions and hardcoded behaviour that make customisation harder for advanced users.

`nabiki` tries to be pragmatic: a small toolkit of focused functions to read filesystem layouts, transform entries into Nix attribute sets, and help build flake outputs with minimal ceremony.

> **Warning.** Use only tagged `nabiki` releases. The project is under active refactoring: v1 → later versions include renames and deprecations. Backwards incompatibilities are likely between commits.

---

## Quick start — bootstrapping a NixOS dotfiles repo

Example steps to create a new dotfiles flake from the `nabiki` template:

```bash
dotfiles_repo=/path/to/dotfiles/repo
nix flake new --template github:nadevko/nabiki/v1#v1 "$dotfiles_repo"
cd "$dotfiles_repo"
git init .
rm ./nixos/configurations/default/.gitkeep
cp -r /etc/nixos/* ./nixos/default
mv ./nixos/configurations/default "./nixos/configurations/$HOSTNAME"
sudo nixos-rebuild switch --flake .#
```

---

## Upgrading packages

If every package in your flake exposes `passthru.updateScript` (for example, as a derivation), the `nabiki-update` helper can be used to collect and run update scripts across your packages. You can pass specific `nixpkgs` and `self` inputs, or rely on inputs from the flake.

---

## Reference — functions

Below are short, corrected descriptions of the functions provided by the library. Each entry states intent, typical parameters and what the function returns.

### File loading functions

#### `listModules`

Return a flat list of file values for all `.nix` files under a given path (recursively).
**Typical use:** enumerate all module files to import them or to inspect them.
**Parameters:** pipeline-style arguments (e.g. `path`).
**Returns:** a flat list of file values (paths or imported values depending on loader).

#### `readModulesFlatten`

Read files under `path` and produce an attribute set whose keys are flattened, concatenated names (separator configurable) and whose values are full file paths.
**Typical use:** build a flat attribute map of modules for easy access (`foo-bar = /.../foo/bar.nix`).
**Parameters:** `path` and optional `separator` (default `-`).
**Returns:** an attribute set mapping flattened names → file paths.

#### `readLib`

Import a `lib` directory as a tree of modules where non-underscored `.nix` files are imported.
**Behaviour:** `default.nix` files inside directories are treated as directory content (prepended) and every file is imported with the provided `inputs`.
**Returns:** a tree-like nested attribute set mirroring the filesystem layout.

#### `readLegacyPackages`

Read packages laid out in a legacy style: treat `package.nix` as the package for a directory; treat `default.nix` as plain code to be imported rather than called. Packages are placed into `pkgs` according to their relative path.
**Parameters:** `{ pkgs, overrides, path, ... }`.
**Returns:** a nested attribute set of packages, merged into `pkgs` using `pkgs.callPackage` when appropriate.

#### `readPackages`

Similar to `readLegacyPackages`, but uses flattened naming (via `readModulesFlatten`) and supports directories that export multiple packages (via `default.nix` that returns an attrset).
**Parameters:** `{ pkgs, overrides, path, ... }`.
**Returns:** a flat or semi-flattened attribute set of packages, suitable for inclusion in flake outputs.

---

### Core helpers (must-have)

#### `nestAttrs`

Convenience wrapper for building attribute sets from multiple roots. It takes an identity reader and a generator and produces a single merged attribute set.
**Typical use:** produce system-dependent outputs in flakes: `n [ "x86_64-linux" ] (system: {...})`.

#### `nestAttrs'`

Lower-level version of `nestAttrs` that accepts an explicit `reader`. It applies `reader` to each root and then uses `generator` to produce attribute sets which are zipped and merged.
**Parameters:** `reader: roots: generator:`.
**Returns:** merged attribute set.

#### `fpipe`

Functional `pipe` variant where the function list is the first argument. It is simply `flip pipe`. Use to build pipelines in a style where `fpipe [ f g h ] x` applies `f` then `g` then `h` to `x`.

#### `fpipeFlatten`

An `fpipe` variant that accepts nested lists of functions and flattens them before piping. Handy to assemble pipelines from lists-of-lists.

#### `fpipeFlattenWrap`

Wraps each function passed to `fpipeFlatten` with a `wrap` function, allowing you to inject additional context (for example, building closures around helper functions).

#### `fpipeFlattenMap`

A convenience that wraps each function with `builtins.map` (i.e. map the function over lists), combined with `fpipeFlattenWrap`. Useful when you want to apply a pipeline element to every item of a list.

#### `splitAt`

Split a list into `{ init = [...]; tail = [...] }` where `init` contains at most `n` elements and any remainder goes to `tail`. If `n` is negative it is interpreted relative to the list length. Returns the two parts as an attribute set.

---

### Path / string helpers (advanced but small)

#### `removeExtension`

Transformer that removes a file extension from an entry's `name` attribute. If no extension exists, the original name is kept.

#### `concatNodesSep`

Join `nodes ++ [ name ]` using a provided separator to create a flattened name. Useful when building flat keys from hierarchical paths.

---

### Traversal primitives (advanced)

#### `pipelineTraverse`

A generic, composable pipeline traverser. It composes small helper lists into a traversal pipeline that transforms filesystem-like entries into a final result list.
**Key lists (arguments):**

* `resolvers`: produce the initial node(s) from a `path` (e.g. `nodePathResolver`).
* `readers`: read directory contents (e.g. `itemiseDir`).
* `filters`: filter out unwanted entries (e.g. `isNotUnderscored`, `isNix`).
* `transformers`: mutate nodes before branching (e.g. `liftFile`, `removeExtension`).
* `switchers`: decide branch vs leaf (e.g. `switchDirFile`).
* `loaders`: load or materialise node values (imports, `pkgs.callPackage`, etc.).
* `mergers`: merge local results (e.g. `flatten`).
* `updaters`: final post-processing to produce the final value.
  **Returns:** a list (by default) of processed nodes; behaviour is controlled entirely by the passed lists and their order.

#### `treeishTraverse`

Wrapper around `pipelineTraverse` that configures loaders/mergers/updaters so that results are tree-like rather than a flat list. Use it when you want nested structures with `nodes` arrays and `value` fields suitable for building nested attrsets.

---

### Miscellaneous filesystem helpers

#### `isNix`

Filter predicate: true for `.nix` files or directories. Useful to select Nix source files during traversal.

#### `isNotUnderscored`

Filter predicate: excludes files whose names start with an underscore (`_`). Useful for ignoring helper or private files.

#### `itemiseDir`

Reads a directory and returns a list of node maps with `name`, `type`, `nodes` and `value` (full path). Intended to be used as a `reader` in traversal pipelines.

#### `itemiseFromContent`

Convert the result of importing a directory (an attrset of packages) into a list of package entries. Each produced entry contains `name`, `nodes`, `type="regular"`, `value` and `dir`.

#### `switchDirFile`

Simple switcher: if an entry is a directory call `onNode` (and append the directory name to `nodes`), otherwise call `onLeaf`. Use as the default branching strategy.

#### `liftFile`

Transformer that checks if a specific file (e.g. `default.nix` or `package.nix`) exists inside a directory and, if so, treat that file as the node content. Commonly used to prefer `package.nix` or `default.nix` over listing the directory.

#### `switchDirFileContent`

Enhanced switcher which, for directories, checks for a `liftedContentFile` (for example `"default.nix"`) and, if present, imports it and determines per-file handling (callable packages vs imported packages). For regular files it typically routes the entry through `callPackage` or `onLeaf`.

---

### Utilities / small helpers

#### `setNameToValue`

Take an entry `{ name, value, ... }` and return an attribute set where the key is the `name` and the value is `value`. Simple helper to convert one node into an attrset entry.

#### `nodePathResolver`

An initial resolver that converts an input `path` into the initial node structure accepted by `pipelineTraverse`. It initialises `{ nodes = []; value = path }` and then calls `onNode`.

---

## Examples

**Produce flake outputs per-system**

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    n = {
      url = "github:nadevko/nabiki";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { n, ... }: n [ "x86_64-linux" ] (system: {
    # some `system`-depend stuff...
  });
}
```

**Produce flake outputs per-system using pkgs**

```nix
{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    n = {
      url = "github:nadevko/nabiki";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs = { n, nixpkgs, ...}:
    n (system: nixpkgs.legacyPackages.${system}) [ "x86_64-linux" ]
    (pkgs: {
      # some `pkgs`-depend stuff...
    });
}
```

---

## Contributing & notes

* The library is intentionally minimal and composable. If you find a pattern repeated in your projects, please describe it in issues
* This readme mostly AI-written, so it can contain some mistakes.
* Remember to pin `nabiki` by tag in real projects. API changes between commits are expected during the project’s refactor cycle.
