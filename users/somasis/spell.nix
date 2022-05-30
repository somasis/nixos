{ pkgs, ... }: {
  home.packages = [
    pkgs.hunspell
    pkgs.hunspellDicts.en-us-large
    pkgs.hunspellDicts.en-gb-ise
    pkgs.hunspellDicts.es-any
    pkgs.hunspellDicts.es-es
    pkgs.hunspellDicts.es-mx

    # TODO: not in nixpkgs yet
    # pkgs.hunspellDicts.tok

    # aspell is still used by kakoune's spell.kak, unfortunately.
    pkgs.aspellDicts.en
    pkgs.aspellDicts.en-computers
    pkgs.aspellDicts.en-science
    pkgs.aspellDicts.es

    (pkgs.writeShellApplication {
      name = "spell";
      runtimeInputs = [
        pkgs.hunspell
        pkgs.diffutils
      ];

      text = ''
        hunspell() {
            command hunspell ''${d:+-d "$d"} "$@"
        }

        d=
        while getopts :d: arg >/dev/null 2>&1; do
            case "$arg" in
                d) d="$OPTARG"; ;;
                *) usage ;;
            esac
        done
        shift $(( OPTIND - 1 ))

        diff -u "$1" <(hunspell -U "$1")
      '';
    })
  ];
}

