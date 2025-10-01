{
  inputs ? { },
  nixpkgs ? inputs.nixpkgs,
  writeShellApplication,
  system,
}:
writeShellApplication {
  name = "nabiki-update";
  text = ''
    target="''${1:-packages}"
    flake="$(realpath "''${2:-$PWD}")"

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    nix build --extra-experimental-features 'nix-command flakes' --impure --expr "
      let
        pkgs = import ${nixpkgs} { };
        paths = pkgs.lib.trivial.pipe \"$flake\" [
          builtins.getFlake
          (x: x.outputs.''${target}.${system})
          builtins.attrValues
          (builtins.catAttrs \"passthru\")
          (builtins.catAttrs \"updateScript\")
          pkgs.lib.lists.unique
        ];
      in
      pkgs.symlinkJoin {
        name = \"nabiki-update\";
        inherit paths;
      }
    "

    cd "$flake"
    echo "Change root to $flake"
    for i in "$tmp"/result/bin/*; do
      echo "Run $i..."
      "$i"
    done
  '';
}
