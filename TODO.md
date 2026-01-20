# TODO

## v1.1

### ideas

- [ ] packages

- [ ] kasumi-shell
  - [ ] files
  - [ ] git hooks

- [ ] kasumi-test tool
  - [ ] lib
    - [ ] deepSeq
    - [ ] nixpkgs.lib collisions
    - [ ] aliases collisions
    - [ ] missing static aliases
  - [ ] nixpkgs-hammering
  - [ ] nixpkgs-vet
  - [ ] nixpkgs CI

- [ ] kasumi-update tool
  - [ ] updaters

- [ ] kasumi-format tool
- [ ] templates

- [ ] kasumi-docs
  - [ ] webpage
  - [ ] readme autoupdate
  - [ ] docs in code

- [ ] kasumi-pr

- [ ] flake module

- [ ] kasumi-release

- [ ] kasumi-commit

- [/] fs combinators

- by type
  - [ ] JIT
  - [ ] Nix-to-Nix IR
  - [ ] Json-to-Nix IR
  - [ ] AOT
- by usage
  - [ ] kasumi-lib.*
  - [ ] mkflake
  - [ ] flake-parts

- [ ] RFCs
  - [ ] 0140 by-name
  - [ ] 0192 pins.nix
  - [ ] 0075 declarative wrappers
  - [ ] draft feature parameter names

- nix cost of ownership top:
  - nix: derivation/stdenvNoCC
  - bash: stdenvNoCC
  - c/cpp: stdenv
  - zig: stdenvNoCC+zig
  - go: buildGoModule
  - c/cpp: static/musl/llvm stdenv
  - rust: $T_{build} \propto e^{S_{rust}}$
