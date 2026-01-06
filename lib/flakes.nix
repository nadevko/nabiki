self: lib:
let
  inherit (builtins)
    attrNames
    readDir
    mapAttrs
    isFunction
    ;

  inherit (lib.attrsets) filterAttrs;
  inherit (lib.fileset) toList;
  inherit (lib.trivial) flip;
  inherit (lib.meta) getExe;
  inherit (lib.strings) hasPrefix;

  inherit (self.attrsets)
    addAliasesToAttrs
    genTransposed
    genTransposedAs
    mapAttrsIntersection
    ;
  inherit (self.fileset) toFlattenAttrsWith dirFilter toExtension;
  inherit (self.trivial) compose fpipe';
  inherit (self.customisation) genFromNixpkgsFor triComposeScope fixScope;
  inherit (self.fixedPoints) rebase;
in
rec {
  mkflake =
    {
      inputs ? { },

      self ? inputs.self,
      selfConfig ? null,
      perSelfPackages ? pkgs: { },

      nixpkgs ? inputs.nixpkgs,
      nixpkgsConfig ? null,
      perPackages ? pkgs: { },

      systems ? attrNames nixpkgs.legacyPackages,
      perSystem ? system: { },

      treefmt ? inputs.treefmt or null,
      treefmtConfig ? {
        programs.nixfmt = {
          enable = true;
          strict = true;
        };
      },
      ...
    }@flake:
    genFromNixpkgsFor self selfConfig systems perSelfPackages
    // genFromNixpkgsFor nixpkgs nixpkgsConfig systems perPackages
    // genTransposed systems perSystem
    // (
      if treefmt == null then
        { }
      else
        genTransposedAs (system: treefmt.lib.evalModule nixpkgs.legacyPackages.${system} treefmtConfig)
          [ "aarch64-darwin" "aarch64-linux" "i686-linux" "x86_64-darwin" "x86_64-linux" ]
          (treefmt: {
            formatter = treefmt.config.build.wrapper;
            checks.treefmt = treefmt.config.build.check self;
          })
    )
    // removeAttrs flake [
      "inputs"

      "treefmt"
      "treefmtConfig"

      "selfConfig"
      "perSelfPackages"

      "nixpkgs"
      "nixpkgsConfig"
      "perPackages"

      "systems"
      "perSystem"
    ];

  listModules = compose toList (dirFilter ({ isNixRec, ... }: isNixRec));

  flatifyModulesWith =
    args: compose (toFlattenAttrsWith args) (dirFilter ({ isNixRec, ... }: isNixRec));
  flatifyModulesSep = sep: flatifyModulesWith { inherit sep; };
  flatifyModules = flatifyModulesWith { };

  readLibExtension = compose toExtension (dirFilter ({ isNixRec, ... }: isNixRec));
  getLib = path: compose addAliasesToAttrs (rebase (readLibExtension path));

  makeConfigurationGetter =
    builder: configBase: perConfig:
    fpipe' [
      readDir
      (filterAttrs (name: type: !hasPrefix "." name && type == "directory"))
      (mapAttrs (name: _: builder (configBase // perConfig.${name} or { })))
    ];

  getConfigurations =
    builder:
    makeConfigurationGetter (
      args: { path, ... }: builder (args // { modules = listModules path ++ args.modules or [ ]; })
    );

  getTemplates = makeConfigurationGetter (args: { path, ... }: (args // { inherit path; }));

  readDirAsFlattenAttrsWith =
    args:
    compose (toFlattenAttrsWith ({ liftsOnly = true; } // args)) (
      dirFilter ({ isNixRec, ... }: isNixRec)
    );

  readPackagesExtensionWith =
    {
      packageBase ? { },
      perPackage ? { },
      callers ? final: prev: { },
      ...
    }@args:
    path: final: prev:
    mapAttrs (
      name:
      flip ((callers final prev).${name} or final.callPackage) (packageBase // perPackage.${name} or { })
    ) (readDirAsFlattenAttrsWith args path);

  readPackagesExtension = readPackagesExtensionWith { lifts = [ "package.nix" ]; };
  readDevShellExtension = readPackagesExtensionWith { lifts = [ "shell.nix" ]; };
  readCheckExtension = readPackagesExtensionWith { lifts = [ "check.nix" ]; };
  readHydraJobsExtension = readPackagesExtensionWith { lifts = [ "hydra.nix" ]; };
  readAppsExtension = readPackagesExtensionWith { lifts = [ "app.nix" ]; };

  getAppsFromExtension =
    {
      path,
      appBase ? {
        type = "app";
      },
      perApp ? { },
      packages ? fixScope scope,
      scope ? triComposeScope private extension overrides,
      private ? _: _: { },
      extension ? readAppsExtension args path,
      overrides ? _: _: { },
      ...
    }@args:
    let
      perApp' = mapAttrs (_: app: appBase // app) perApp;
      intersection = mapAttrsIntersection (
        name: package: app:
        app
        // {
          program =
            let
              program' = app.program or appBase.program or getExe package;
            in
            if isFunction program' then program' package else program';
        }
      ) packages perApp';
    in
    mapAttrs (_: package: appBase // { program = getExe package; }) packages // perApp' // intersection;
}
