#!/bin/sh

usage() {
    [ "$#" -gt 0 ] && printf '%s\n' "$@" >&2
    cat >&2 <<EOF
usage: ${0##*/} [-u] LENGTH
EOF
    exit 69
}

ellipsis="..."
while getopts :u arg >/dev/null 2>&1; do
    case "${arg}" in
        u) ellipsis=… ;;
        *) usage "error: unknown option -- ${arg}" ;;
    esac
done
shift $((OPTIND - 1))

ellipsis_width=${#ellipsis}

[ "$#" -eq 1 ] || usage

want_length="$1"
shift

IFS='
'
while read -r line; do
    t=$(printf '%s\n' "${line}" | cut -c -$((want_length - ellipsis_width)))

    if [ "${line}" != "${t}" ]; then
        # strip trailing space
        while :; do
            case "${t}" in
                *[[:blank:]]) t=${t% } ;;
                *) break ;;
            esac
        done

        printf "%s%s\n" "${t}" "${ellipsis}"
        continue
    fi

    printf '%s\n' "${line}"
done
