# shellcheck shell=bash disable=SC3000-SC3999

set -euo pipefail
set -x

usage() {
    me=:pass
    [[ -n "${QUTE_FIFO}" ]] && me="${0##*/}"

    usage="usage: ${me} [-EH] [-d delimiter] [-m username|password|otp|domain-to-entry] [query]"

    if [[ -n "${QUTE_FIFO}" ]]; then
        cmd "message-info \"${usage//\"/\"}\""
        exit 0
    else
        printf '%s\n' "${usage}" >&2
        exit 69
    fi
}

cmd() { printf '%s\n' "$@" >"${QUTE_FIFO}";  }
# commands=
# cmd() { for c; do commands+="${c:+ ${c}}"; done; }
# trap 'printf "%s\n" "${commands[@]}" > "${QUTE_FIFO}"' EXIT

key() {
    local keystring
    keystring=
    for k; do keystring+="${k//\"/\\\"}"; done
    cmd "fake-key \"${keystring}\""
}

fill() {
    local mode with

    mode="$1"
    with=$(dmenu-pass -m "${mode}" -i "$2") || exit 0

    if "${hints}"; then cmd "hint -f ${mode} normal"; fi
    key "<Ctrl-a>" "<Backspace>" "${with}"
}

domain-to-entry() {
    local query
    query=$(trurl -f - -g '{host}' <<<"${QUTE_URL}")

    case "${query}" in
        *'.'*'.'*)
            local query_top_level query_main

            query_top_level=${query##*.}

            query_main=${query%."${query_top_level}"}
            query_main=${query_main##*.}.${query_top_level}

            # query_extra=${query%"${query_main}"}

            # query="(${query_extra//\./\.\)?(})"
            # query="${query%()}${query_main}"

            query="${query_main}"
            ;;
    esac
    printf '%s' "${query}"
}

# commands=()

delimiter='<Tab>'
enter=false
mode=login
hints=false
while getopts :EHd:m: arg >/dev/null 2>&1; do
    case "${arg}" in
        E) enter=true ;;
        H) hints=true ;;

        d) delimiter="${OPTARG}" ;;

        m)
            mode="${OPTARG}"

            case "${mode}" in
                login | username | password | otp | domain-to-entry) : ;;
                *)
                    printf 'error: invalid mode\n' >&2
                    usage
                    ;;
            esac
            ;;

        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [[ "${mode}" == "domain-to-entry" ]]; then
    domain-to-entry "$@"
    exit $?
fi

if [[ "$#" -eq 1 ]]; then
    query="$1"
elif [[ "$#" -eq 0 ]]; then
    query=$(domain-to-entry "${QUTE_URL}")
else
    usage
fi

: "${QUTE_FIFO:?}"
: "${PASSWORD_STORE_DIR:=${HOME}/.password-store}"

case "${mode}" in
    login)
        choice=$(dmenu-pass -m print -i "${query}") || exit 0

        fill username "${choice}"
        if [[ "${hints}" == true ]]; then
            key "${delimiter}"
        fi

        fill password "${choice}"
        ;;
    username | password | otp)
        fill "${mode}" "${query}"
        ;;
esac

if [[ "${enter}" == true ]]; then
    key "<Enter>"
fi
