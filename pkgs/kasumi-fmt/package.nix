{
  writeShellApplication,
  git,
  nixfmt,
  deadnix,
}:
writeShellApplication {
  name = "kasumi-fmt";
  runtimeInputs = [
    git
    nixfmt
    deadnix
  ];
  text = ''
    format() {
      if (( $# == 0 )); then
        echo "There are no files to format"
        return 0
      fi
      echo "Formatting $# file(s)..."
      nixfmt --strict "$@"
      deadnix "$@"
      return 0
    }

    if (( $# != 0 )); then
      format "$@"
      exit $?
    fi

    files=()

    while IFS= read -r file; do
      if [[ -f "$file" ]]; then
        files+=("$file")
      fi
    done < <(git diff --cached --name-only --diff-filter=ACMR | grep '\.nix$' || true)

    format "''${files[@]}"
  '';
}
