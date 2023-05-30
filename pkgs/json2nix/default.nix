{ lib
, writeShellApplication
, nix
, coreutils
, nixfmt
}:
(writeShellApplication {
  name = "json2nix";

  runtimeInputs = [
    coreutils
    nix
    nixfmt
  ];

  text = ''
    usage() {
        cat <<EOF
    usage: json2nix [FILE]
           ... | json2nix
    EOF
        exit 69
    }

    format() {
        if [[ -t 1 ]]; then
            nixfmt -w 120
        else
            cat
        fi
    }

    [[ "$#" -le 1 ]] || usage

    path=''${1:-}

    case "$path" in
        /*)   : ;;
        -|"") path=/dev/stdin ;;

        # builtins.readFile only wants absolute paths
        *)    path=$(readlink -f "$path") ;;
    esac

    nix-instantiate --eval \
        --readonly-mode \
        --argstr path "$path" \
        --expr '{ path }: builtins.fromJSON (builtins.readFile path)' \
        | format
  '';
}) // {
  meta = with lib; {
    description = "Convert JSON to Nix expressions";
    license = licenses.unlicense;
    maintainers = with maintainers; [ somasis ];
  };
}
