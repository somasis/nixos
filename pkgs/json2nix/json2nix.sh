# shellcheck shell=sh

usage() {
    cat <<EOF
usage: json2nix [FILE]
       ... | json2nix
EOF
    exit 69
}

format() {
    if [ -t 1 ]; then
        nixfmt -w 120
    else
        cat
    fi
}

[ "$#" -le 1 ] || usage

path=${1:-}

case "${path}" in
    /*) : ;;
    - | '') path=/dev/stdin ;;

    # builtins.readFile only wants absolute paths
    *) path=$(readlink -f "${path}") ;;
esac

nix-instantiate --eval \
    --readonly-mode \
    --argstr path "${path}" \
    --expr '{ path }: builtins.fromJSON (builtins.readFile path)' \
    | format
