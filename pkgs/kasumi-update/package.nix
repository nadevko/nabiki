{
  path,
  writeShellApplication,
  stdenvNoCC,
}:
let
  updater = ./updater.nix;
  collector = ./collector.nix;
in
writeShellApplication {
  name = "kasumi-update";

  text = ''
    target="''${1:-packages}"
    flake_path="$(realpath "''${2:-$PWD}")"
    system="${stdenvNoCC.hostPlatform.system}"

    updater_path=$(nix build --no-link --print-out-paths --impure --expr "
      let
        pkgs = import ${path} { };
        collector = pkgs.callPackage ${collector} { };
      in
      import ${updater} {
        inherit collector;
        flake_path = \"$flake_path\";
        target = \"$target\";
        system = \"$system\";
      }
    ")

    "$updater_path/bin/kasumi-run-$target"
  '';
}
