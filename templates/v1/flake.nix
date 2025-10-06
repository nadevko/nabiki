{
  inputs = {
    nixpkgs.url = "github:nixos/nixpkgs/nixpkgs-unstable";

    home-manager = {
      url = "github:nix-community/home-manager";
      inputs.nixpkgs.follows = "nixpkgs";
    };

    n = {
      url = "github:nadevko/n/v1";
      inputs.nixpkgs.follows = "nixpkgs";
    };
  };

  outputs =
    {
      n,
      self,
      nixpkgs,
      home-manager,
      ...
    }@inputs:
    {
      # some top-level statements

      nixosConfigurations = builtins.mapAttrs (
        name: _:
        nixpkgs.lib.nixosSystem {
          modules = n.lib.listModules { path = ./nixos/configurations/${name}; };
          specialArgs = { inherit inputs; };
        }
      ) (builtins.readDir ./nixos/configurations);

      homeConfigurations = builtins.mapAttrs (
        name: _:
        home-manager.lib.homeManagerConfiguration {
          modules = n.lib.listModules { path = ./home/configurations/${name}; };
          extraSpecialArgs = { inherit inputs; };
          pkgs = nixpkgs.legacyPackages.x86_64-linux;
        }
      ) (builtins.readDir ./home/configurations);

      nixosModules = n.lib.readModulesFlatten { path = ./nixos/modules; };
      homeModules = n.lib.readModulesFlatten { path = ./home/modules; };

      lib = n.lib.readLib {
        path = ./lib;
        inherit inputs;
      };
    }
    // n.lib.nestAttrs' (system: nixpkgs.legacyPackages.${system}) nixpkgs.lib.platforms.all (pkgs: {
      # some system-specific statements

      packages = n.lib.readPackages {
        path = ./pkgs;
        overrides.inputs = inputs;
        inherit pkgs;
      };
      legacyPackages = n.lib.readLegacyPackages {
        path = ./pkgs;
        overrides.inputs = inputs;
        inherit pkgs;
      };
      devShells.default = pkgs.mkShell {
        packages = [ (n.packages.${pkgs.system}.nabiki-update.override { inherit inputs; }) ];
      };
    });
}
