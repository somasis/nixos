# shellcheck shell=bash disable=SC2016

usage() {
    # shellcheck disable=SC2059
    [[ "$#" -eq 0 ]] || printf "$@" >&2

    cat >&2 <<'EOF'
Convert JSON input to Nix language declarations.

Conversion is done by calling directly to the `builtins.fromJSON` function
included with Nix.

Output will be formatted with `nixfmt` if standard output is a terminal.

usage: json2nix <file>...
       json2nix [-]
EOF

    [[ "$#" -eq 0 ]] || exit 1
    exit 69
}

format() {
    if [[ -t 1 ]]; then
        nixfmt -w 120
    else
        cat
    fi
}

while getopts : opt >/dev/null 2>&1; do
    case "${opt}" in
        ?) usage 'unknown option -- %s\n' "${OPTARG@Q}" ;;
    esac
done
shift $((OPTIND - 1))

[[ "$#" -gt 0 ]] || set -- -

for path; do
    case "${path}" in
        /*) : ;;

        -) path=/dev/stdin ;;

        # `builtins.readFile` only wants absolute paths
        *) path=$(readlink -f -- "${path}") ;;
    esac

    error=0

    output=$(
        nix-instantiate --eval \
            --readonly-mode \
            --argstr path "${path}" \
            --expr '{ path }: builtins.fromJSON (builtins.readFile path)'
    ) || error=$?

    if [[ "${error}" -ne 0 ]]; then
        # shellcheck disable=SC2016
        usage 'error: `nix-instantiate` failed while converting %s from JSON (error code: %i)\n' \
            "${path@Q}" \
            "${error}"
    fi

    format <<<"${output}"
done
