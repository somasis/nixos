: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"

usage() {
    # shellcheck disable=SC2059
    [[ "$#" -eq 0 ]] || printf "$@" >&2

    cat >&2 <<EOF
usage: ${0##*/} [-I] prefix command...
       ${0##*/} [-I] -E command...
       ${0##*/} -l prefix
       ${0##*/} -s prefix application
       ${0##*/} -L
EOF
    [[ "$#" -eq 0 ]] || exit 1
    exit 69
}

prefix=

run_init=true
mode=run
while getopts :EILls opt; do
    case "${opt}" in
        E) mode=for_each_prefix ;;
        I) run_init=false ;;
        L) mode=list_prefixes ;;

        l) mode=list_prefix_applications ;;
        s) mode=start_prefix_application ;;

        *) usage 'unknown option -- %s\n' "${OPTARG}" ;;
    esac
done
shift $((OPTIND - 1))
unset opt

case "${mode}" in
    list_prefix_applications)
        prefix=${1:-}
        shift

        [[ -n "${prefix}" ]] || usage 'error: no prefix given\n'
        [[ -e "${XDG_DATA_HOME}"/wineprefixes/"${prefix}" ]] || usage 'error: no prefix named %q exists\n' "${prefix}"
        prefix="${XDG_DATA_HOME}"/wineprefixes/"${prefix}"

        if [[ -d "${prefix}/drive_c/users/${USER}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs" ]]; then
            cd "${prefix}/drive_c/users/${USER}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs" || exit 1
            find .// -type f -iname '*.lnk' | sed 's|^\.//||; s|\.lnk$||' || :
        else
            exit 1
        fi
        ;;

    start_prefix_application)
        prefix=${1:-}
        shift

        [[ -n "${prefix}" ]] || usage 'error: no prefix given\n'
        [[ -e "${XDG_DATA_HOME}"/wineprefixes/"${prefix}" ]] || usage 'error: no prefix named %q exists\n' "${prefix}"

        application=${1:-}
        shift

        [[ -n "${application}" ]] || usage 'error: no application given\n'
        application="C:/Users/${USER}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/${application}.lnk"
        application=${application//\//\\}

        exec wineprefix "${prefix}" wine start "${application}" "$@"
        ;;

    list_prefixes)
        for prefix in "${XDG_DATA_HOME}"/wineprefixes/*/system.reg; do
            [[ -e "${prefix}" ]] || break
            prefix=${prefix%/system.reg}
            prefix=${prefix##*/}

            printf '%s\n' "${prefix}"
        done
        exit
        ;;
    for_each_prefix)
        for prefix in "${XDG_DATA_HOME}"/wineprefixes/*/system.reg; do
            [[ -e "${prefix}" ]] || break
            prefix=${prefix%/system.reg}
            prefix=${prefix##*/}

            "$0" "${prefix}" "$@" || exit $?
        done
        exit
        ;;
    run)
        [[ -n "${1:-}" ]] || usage 'error: no Wine prefix specified\n'
        prefix="$1"
        export WINEPREFIX="${XDG_DATA_HOME}/wineprefixes/${prefix}"
        shift

        [[ "$#" -gt 0 ]] || usage 'error: no command provided\n'

        if [[ "${run_init}" == true ]]; then
            if ! [[ -d "${WINEPREFIX}" ]]; then
                printf 'initializing wineprefix %q...\n' "${prefix}" >&2
                wineboot -i
            fi

            for init in "${XDG_CONFIG_HOME}"/wineprefixes/init "${XDG_CONFIG_HOME}"/wineprefixes/"${prefix}".init; do
                # shellcheck disable=SC1090
                if [[ -f "${init}" ]] && [[ -r "${init}" ]]; then . "${init}"; fi
            done
            unset init
        fi

        unset prefix
        exec -- "$@"
        ;;
esac
