# shellcheck shell=bash

: "${XDG_CONFIG_HOME:=${HOME}/.config}"

show_local=true
table=false
right_align=false
format=
date_format=

usage() {
    cat >&2 <<EOF
usage: ${0##*/} [-Lr] [-f FORMAT] [+DATE_FORMAT] [NAMES...]
EOF
    exit 69
}

mkdir -p "${XDG_CONFIG_HOME}"/dates
cd "${XDG_CONFIG_HOME}"/dates || exit $?

while getopts :Lrf: arg >/dev/null 2>&1; do
    case "${arg}" in
        L) show_local=false ;;
        r) right_align=true ;;
        f) format="${OPTARG}" ;;
        ?) usage ;;
    esac
done
shift $((OPTIND - 1))

case "${1:-}" in
    +*)
        date_format="$1"
        shift
        ;;
esac

[[ "${right_align}" == "false" ]] && right_align=

[[ "$#" -gt 0 ]] || set -- *

if [[ -z "${format}" ]]; then
    longest=0
    for t; do
        if [[ "${t}" = _ ]] && [[ "${show_local}" = true ]]; then
            t=local
            continue
        fi

        [[ "${#t}" -gt "${longest}" ]] && longest=${#t}
    done
    format="%${right_align:+-}${longest}s %s\n"
fi

case "${format}${date_format}" in
    *$'\t'*) table=true ;;
esac

for t; do
    if [[ "${t}" = _ ]]; then
        if [[ "${show_local}" = true ]]; then
            t=local
        else
            continue
        fi
    elif [[ -f /etc/zoneinfo/"${t}" ]]; then
        export TZ="${t}"
    elif [[ -e "${t}" ]]; then
        TZ=$(readlink -f "${t}")
        export TZ=":${TZ}"
    else
        printf 'error: timezone "%s" does not exist\n' "${t}" >&2
        exit 1
    fi

    # Don't yell about us using $variables in printf's format, it's meant to be user-customized.
    # shellcheck disable=SC2059,SC2312
    printf "${format}" "${t}" "$(date ${date_format:+"${date_format}"})"
done \
    | if [[ "${table}" == "true" ]]; then
        table ${right_align:+-R 1} -o " "
    else
        cat
    fi
