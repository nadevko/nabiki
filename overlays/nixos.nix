final: prev: {
  nixos = import <nixpkgs/nixos/lib> { lib = final; };
  nixosSystem = args: import <nixpkgs/nixos/lib/eval-config.nix> ({ lib = final; } // args);
}
