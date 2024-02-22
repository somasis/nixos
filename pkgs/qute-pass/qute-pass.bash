# shellcheck shell=bash disable=SC3000-SC3999

set -euo pipefail

me="${0##*/}"
[[ -n "${QUTE_FIFO}" ]] && me=:pass

usage() {
    usage=$(
        cat <<EOF
usage: ${me} [-HS] [-d DELIMITER] -m fields|username|email|password|otp [QUERY]
       ${me} [-HS] [-d DELIMITER] -m fields|username|email|password|otp -u URL
       ${me} [-HS] [-d DELIMITER] -m generate [\`pass generate\` arguments] ENTRY
       ${me} [-HS] [-d DELIMITER] -m generate -u [\`pass generate\` arguments] URL
       ${me} -m url-to-entry URL
EOF
    )

    info "${usage}"
    if [[ -n "$1" ]]; then
        error "$1"
        exit 69
    else
        exit 0
    fi
}

info() {
    if [[ -n "${QUTE_FIFO}" ]]; then
        cmd "message-info \"${1//\"/\"}\""
    else
        printf '%s\n' "$1"
    fi
}

error() {
    if [[ -n "${QUTE_FIFO}" ]]; then
        cmd "message-error \"${1//\"/\"}\""
    else
        printf '%s\n' "$1" >&2
    fi
}

cmd() { printf '%s\n' "$@" >"${QUTE_FIFO}";  }

key() {
    local keystring
    keystring=
    for k; do keystring+="${k//\"/\\\"}"; done
    cmd "fake-key \"${keystring}\""
}

text() {
    cmd "insert-text $*"
}

fill() {
    local mode with

    mode="$1"
    with=$(dmenu-pass -m "${mode}" -i "$2") || exit 0

    if "${hints}"; then
        # NOTE: would be preferrable to use "spawn", but
        #       :hint doesn't properly support that with
        #       <input> elements :(
        cmd "hint -f ${mode} normal"
        sleep 1
    fi

    key "<Ctrl-a>" "<Backspace>"
    text "${with}"
}

url-to-entry() {
    local host
    host=$(trurl -f - -g '{host}' <<<"${QUTE_URL}")

    case "${host}" in
        *'.'*'.'*)
            local host_top_level host_main

            host_top_level=${host##*.}

            host_main=${host%."${host_top_level}"}
            host_main=${host_main##*.}.${host_top_level}

            # host_extra=${host%"${host_main}"}

            # host="(${host_extra//\./\.\)?(})"
            # host="${host%()}${host_main}"

            host="${host_main}"
            ;;
    esac
    printf '%s' "${host}"
}

delimiter='<Tab>'
submit=false
mode=login
hints=false
query_is_url=false
while getopts :SHud:m: arg >/dev/null 2>&1; do
    case "${arg}" in
        S) submit=true ;;
        H) hints=true ;;

        d) delimiter="${OPTARG}" ;;

        m)
            mode="${OPTARG}"

            case "${mode}" in
                fields | login | username | password | generate | otp | url-to-entry | generate-for-url) : ;;
                *)
                    usage 'error: invalid mode\n'
                    ;;
            esac
            ;;

        u) query_is_url=true ;;

        *) usage ;;
    esac
done
shift $((OPTIND - 1))

if [[ "${mode}" == "url-to-entry" ]]; then
    url-to-entry "$@"
    exit $?
fi

if [[ "$#" -gt 0 ]] && [[ "${query_is_url}" == true ]]; then
    query=$(url-to-entry "$1")
elif [[ "$#" -gt 0 ]] && [[ "${query_is_url}" == false ]]; then
    query="$1"
elif [[ "$#" -eq 0 ]]; then
    query=$(url-to-entry "${QUTE_URL}")
else
    usage
fi

: "${QUTE_FIFO:?}"
: "${PASSWORD_STORE_DIR:=${HOME}/.password-store}"

case "${mode}" in
    fields)
        fill fields "${query}"
        ;;

    login)
        choice=$(dmenu-pass -m print -i "${query}") || exit 0

        fill username "${choice}"
        if [[ "${delimiter}" != '<Tab>' ]] || [[ "${hints}" != true ]]; then
            key "${delimiter}"
            sleep 1
        fi

        fill password "${choice}"
        ;;

    username | email | password | otp)
        fill "${mode}" "${query}"
        ;;

    generate)
        pass_generate_args=$(getopt -o ncqif -l no-symbols,qrcode,clip,in-place,force -n "${me}" -- "$@")
        pass_generate_getopt_err=$?

        [[ "${pass_generate_getopt_err}" -eq 0 ]] || usage

        eval set -- "${pass_generate_args}"
        while true; do
            case "$1" in
                -[ncif] | --no-symbols | --qrcode | --clip | --force | --in-place)
                    pass_generate_args+=("${pass_generate_arg}")
                    shift
                    ;;
                --)
                    shift
                    break
                    ;;
            esac
        done

        query="${1}"
        shift

        if [[ "${query_is_url}" == true ]]; then
            query=$(url-to-entry "${query}")
            cmd "cmd-set-text :pass -m generate ${pass_generate_args:+${pass_generate_args[*]} }${query}"
            exit 0
        fi

        pass generate "${pass_generate_args[@]}" "${query}" "$@"

        fill new-password "${query}"

        # info "pass: Generated password at '${query}'. Copied to clipboard and will be cleared in ''${PASSWORD_STORE_CLIP_TIME} seconds."
        # error "pass: \`pass generate -c $*\` failed for some reason..."
        ;;
esac

if [[ "${submit}" == true ]]; then
    if [[ "${hints}" == true ]]; then
        cmd "hint -f submit"
    else
        key "<Enter>"
    fi
fi
