{
  lib,
  writeShellApplication,
  system,
  pkgsPath,
}:
let
  inherit (lib.customisation) getUpdateScripts;
in
writeShellApplication {
  name = "nabiki-update";
  text = ''
    tmp="$(mktemp -d)"
    trap 'rm -rf "$tmp"' EXIT
    pushd "$tmp"
    nix build ${lib.escapeShellArgs (getUpdateScripts system pkgsPath)}
    popd
    for i in "$tmp"/*/bin/*; do
      "$i"
    done
  '';
}
