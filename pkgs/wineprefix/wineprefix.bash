: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"

usage() {
    # shellcheck disable=SC2059
    [[ "$#" -eq 0 ]] || printf "$@" >&2

    cat >&2 <<EOF
Create, manage, or run commands under Wine prefixes.

usage: ${0##*/} [run [-i]] (<prefix> | all) <command>...
       ${0##*/} list-prefixes
       ${0##*/} list-applications (<prefix> | all))
       ${0##*/} start [-i] <prefix> <application>
       ${0##*/} print-aliases

commands:
    [run [-i]] (<prefix> | all) <command>...
        Run <command> in <prefix>.

        If <prefix> is an existing Wine prefix, and no options are applied
        to \`run\`, specifying \`run\` is not necessary.

        If 'all' is specified, run <command> in all existing Wine prefixes.

    list-prefixes
        Print a list of all known Wine prefixes.

    list-applications (<prefix> | all)
        Print a list of all start menu entries/applications under <prefix>.

    start [-i] <prefix> <application>
        Start the <application> that belongs to <prefix>
        (see \`list application <prefix>\` for valid applications).

    print-aliases
        Print sh(1) format alias declarations for each application
        in each prefix.

options:
    -i              do not run any initialization before running a command

See wine(1) for more details.
EOF
    [[ "$#" -eq 0 ]] || exit 1
    exit 69
}

list_prefixes() {
    local prefix
    for prefix in "${XDG_DATA_HOME}"/wineprefixes/*/system.reg; do
        prefix=${prefix%/system.reg}
        prefix=${prefix##*/}
        case "${prefix}" in .*) continue ;; esac
        prefix_exists "${prefix}" && printf '%s\n' "${prefix}"
    done
}

prefix_exists() {
    local prefix=${1:?no Wine prefix given}

    if ! [[ -e "${XDG_DATA_HOME}/wineprefixes/${prefix}/system.reg" ]]; then
        printf 'error: no Wine prefix named "%s" exists\n' "${prefix}" >&2
        return 1
    fi
}

run_in_prefix() (
    local opt
    while getopts :i opt >/dev/null 2>&1; do
        case "${opt}" in
            i) run_init=false ;;
            *) usage 'unknown option -- %s\n' "${OPTARG}" ;;
        esac
    done
    shift $((OPTIND - 1))
    unset opt

    local prefix="${1:?no Wine prefix given}"
    shift

    [[ "${prefix}" == "all" ]] && run_in_each_prefix "$@"

    [[ "$#" -gt 0 ]] || usage 'error: no command provided\n'

    prefix_exists "${prefix}" \
        && export WINEPREFIX="${XDG_DATA_HOME}/wineprefixes/${prefix}"

    if [[ "${run_init}" == true ]]; then
        if ! [[ -d "${WINEPREFIX}" ]]; then
            printf 'initializing wineprefix %q...\n' "${prefix}" >&2
            wineboot -i
        fi

        local init
        for init in "${XDG_CONFIG_HOME}"/wineprefixes/init "${XDG_CONFIG_HOME}"/wineprefixes/"${prefix}".init; do
            # shellcheck disable=SC1090
            if [[ -f "${init}" ]] && [[ -r "${init}" ]]; then . "${init}"; fi
        done
    fi

    exec -- "$@"
)

list_prefix_applications() (
    local prefix=${1:?no Wine prefix given}
    shift

    [[ "${prefix}" == "all" ]] && list_each_prefix_applications "$@"

    prefix_exists "${prefix}"

    prefix="${XDG_DATA_HOME}"/wineprefixes/"${prefix}"

    local directories=(
        "${prefix}/drive_c/users/${USER}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs"
        "${prefix}/ProgramData/Microsoft/Windows/Start Menu/Programs"
    )
    local d

    for d in "${directories[@]}"; do
        [[ -d "${d}" ]] && cd "${d}" || continue
        find .// -type f -iname '*.lnk'
    done \
        | sed 's|^\.//||; s|\.lnk$||' \
        | sort
)

start_prefix_application() {
    local opt
    while getopts :i opt >/dev/null 2>&1; do
        case "${opt}" in
            i) run_init=false ;;
            *) usage 'unknown option -- %s\n' "${OPTARG}" ;;
        esac
    done
    shift $((OPTIND - 1))
    unset opt

    local prefix=${1:?no Wine prefix given}
    prefix_exists "${prefix}"
    shift

    local application=${1:?no valid start menu entry given}
    shift

    application="C:/Users/${USER}/AppData/Roaming/Microsoft/Windows/Start Menu/Programs/${application}.lnk"
    application=${application//\//\\}

    run_in_prefix "${prefix}" wine start "${application}" "$@"
}

run_in_each_prefix() {
    local prefixes
    mapfile -t prefixes < <(list_prefixes)

    for prefix in "${prefixes[@]}"; do
        run_in_prefix "${prefix}" "$@" || exit $?
    done
    exit
}

list_each_prefix_applications() {
    local prefixes
    mapfile -t prefixes < <(list_prefixes)

    for prefix in "${prefixes[@]}"; do
        list_prefix_applications "${prefix}" \
            | while IFS= read -r application; do
                printf '%s\t%s\n' "${prefix}" "${application}"
            done
    done
    exit
}

print_aliases() {
    local prefixes
    local applications
    local alias_name alias_command

    format_alias_command() {
        local out
        out=$(printf '%q ' "$@")
        out=${out% }
        printf '%s' "${out}"
    }

    mapfile -t prefixes < <(list_prefixes)

    for prefix in "${prefixes[@]}"; do
        if [[ "${prefix}" == "default" ]]; then
            alias_name=wine
            alias_prefix=wine
        else
            alias_name=${prefix,,}
            alias_prefix=${alias_name}
            alias_name=${alias_name//[[:blank:]]/-}
        fi

        alias_command=$(format_alias_command "${0##*/}" run "${prefix}" wine)
        printf 'alias %q=%q\n' "${alias_prefix}" "${alias_command}"

        # entries ending in "..." are usually pointless shortcuts to websites
        mapfile -t applications < <(list_prefix_applications "${prefix}" | grep -v '\.\.\.$')
        for application in "${applications[@]}"; do
            alias_name=${application#*/}
            alias_name=${alias_name,,}
            alias_name=${alias_name//[[:blank:]]/-}
            alias_command=$(format_alias_command "${0##*/}" start "${prefix}" "${application}")

            printf 'alias %q=%q\n' \
                "${alias_prefix}-${alias_name}" "${alias_command}"
        done
    done
    exit
}

run_init=true

[[ "$#" -gt 0 ]] || usage

case "${1}" in
    run)
        shift
        run_in_prefix "$@"
        ;;

    run-for-each)
        shift
        run_in_each_prefix "$@"
        ;;

    start)
        shift
        start_prefix_application "$@"
        ;;

    list-prefixes)
        shift
        list_prefixes "$@"
        ;;

    list-applications)
        shift
        list_prefix_applications "$@"
        ;;

    print-aliases)
        shift
        print_aliases "$@"
        ;;

    help | --help) usage ;;

    *)
        if prefix_exists "${1}" 2>/dev/null && [[ "$#" -ge 2 ]]; then
            run_in_prefix "$@"
        else
            if [[ "$#" -gt 1 ]]; then
                usage 'error: no prefix named "%s" exists\n' "${1}"
            else
                usage 'error: unknown command -- "%s"\n' "$1"
            fi
        fi
        ;;
esac
