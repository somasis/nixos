# shellcheck shell=bash

set -euo pipefail

PATH="@coreutils@:@gawk@:${PATH}"

usage() {
    cat >&2 <<EOF
usage: pass meta ENTRY [FIELD]
EOF
    exit 69
}

meta() {
    cmd_show "$1" \
        | awk \
            -F ":" \
            -v entry="$1" \
            -v key="$2" '
                NR==1 { next }
                $1 ~ key {
                    if ($key ~ ".*://|:$") {
                        print $0
                    } else {
                        $1=""
                        print substr($0, 3)
                    }

                    if ($one) { exit }
                }
            '
            # -v one="${one}"
}

# one=0
while getopts : arg >/dev/null 2>&1; do
    case "${arg}" in
        # a) one=1 ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

[[ "$#" -ge 1 ]] || usage

check_sneaky_paths "$1"

case "${2:-}" in
    "")
        {
            printf '%s\n' password username
            cmd_show "$1" | tail -n +2 | cut -d: -f1
        } | uq
        ;;
    login | name | user | username)
        username=$(meta "$1" "login|name|user|username")
        [[ -z "${username}" ]] && exec basename "$1"
        printf '%s\n' "${username}"
        ;;

    pass | password) cmd_show "$@" ;;
    *) meta "$@" ;;
esac
