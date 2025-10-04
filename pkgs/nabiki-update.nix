{
  inputs ? { },
  nixpkgs ? inputs.nixpkgs,
  self ? inputs.self,
  writeShellApplication,
  system,
}:
writeShellApplication {
  name = "nabiki-update";
  text = ''
    flake="$(realpath "''${1:-$PWD}")"

    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    cd "$tmp"

    nix build --impure --expr "
      let
        pkgs = import ${nixpkgs} { };
        self = import ${self} { nixpkgs = pkgs; };
        paths = self.getUpdateScripts \"${system}\" \"$flake\";
      in
      pkgs.symlinkJoin {
        name = \"update-scripts\";
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
