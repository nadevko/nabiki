# TODO

## v2

### v2-alpha

Alpha version should contain all core functions that works perfectly

- [x] lib
- [x] templates
- [x] modules
- [x] configurations
- [x] generic overlays
- [x] packages
- [x] legacyPackages
- [x] devShells
- [x] checks
- [x] hydraJobs
- [x] apps
- [x] update script

### v2-alpha-2

Maybe use scoping? Better packages

- [ ] packages is scope of callPackages+overlays
- [ ] builders is pkgs overlay of callPackage
- [ ] legacyPackages is overlay of callPackages+overlays+builders
- [ ] lib is pkgs overlay and lib overlay of overlays
- [ ] availableOn of packages
- [ ] better access logic using scopes?
- [ ] use newScope or overrideScope in packages?
- [ ] optimisations?
- [ ] recheck multiplatform support
- [ ] rewrite lib with readDirectory or even readDir?

pkgs structure:

\[meaningless-toplevel]/package-or-scope-name/

- if prev has scope-name.newScope
  - legacyPackages: overrideScope
  - packages: newScope
  - recursively
- if has package.nix
  - callPackage it with override.package-name
- if has overlay.nix
  - merge with root scope
- use readDirectory?
- re

### v2-beta

Beta adds some advanced tools

- [ ] formatters
- [ ] git hooks
- [ ] polyfills
- [ ] renaming?

### v2-rc

Release candidate are stays for QA

- [ ] flake module?
- [ ] split
- [ ] tests
- [ ] final refactoring
- [ ] webpage

### v2

For final version, stop changes and document all

- [ ] docs
