{
  nixpkgs,
  writeShellApplication,
  stdenvNoCC,
}:
writeShellApplication {
  name = "kasumi-update";
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
          (x: x.outputs.''${target}.${stdenvNoCC.hostPlatform.system})
          builtins.attrValues
          (builtins.catAttrs \"passthru\")
          (builtins.catAttrs \"updateScript\")
          pkgs.lib.lists.unique
        ];
      in
      pkgs.symlinkJoin {
        name = \"kasumi-update\";
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
