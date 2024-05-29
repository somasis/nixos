# shellcheck shell=bash

: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${XDG_CONFIG_HOME:=${HOME}/.config}"
: "${XDG_DATA_HOME:=${HOME}/.local/share}"

: "${DMENU:=dmenu -p 'run'}"

: "${DMENU_RUN_HISTORY:=${XDG_CACHE_HOME}/dmenu-run/history}"
: "${DMENU_RUN_HISTORY_LENGTH:=$((16 * 4))}"

: "${DMENU_RUN_SCRIPT:=${XDG_CONFIG_HOME}/dmenu-run/dmenu-run.sh}"

# Theory of operation:
# 1. Gather list of executables.
#     a. Get PATH value (or a default PATH value).
#     b. Split it by ':' and construct an array of paths from it.
#     c. Print all executable non-directories in the paths, as well as
#        any function names and alias names in the runtime.
#     d. Sort the list of executables.
#     e. Remove any matching '^_' or '^\.', as they are likely internal
#        commands of some sort, not meant to be ran by users, but rather
#        rather by other commands.
#     f. Gather list of command history, limiting the history prefix to
#        $DMENU_RUN_HISTORY_LENGTH.
#     g. Concatenate the command history and the executable list together,
#        ensuring the history remains at the beginning.
#     h. Print concatenated and deduplicated list of history and executables.
#
# 2. Pass list to dmenu(1) on standard input, displaying it and awaiting
#    user input.
#
# 3. Accept user input as <command>.
#     a. If <command> matches '^+', add it to the command history
#        and exit without executing it.
#     b. If <command> matches '^-', remove it from the command history
#        and exit without executing it.
#     c. If <command> matches '^[\s[:blank:]]', don't add it to command history.
# 3. Validate <command> as an existing command, add it to command history
#    (if applicable) and execute <command> with sh(1), if applicable.
# 4. Exit.

usage() {
    if [[ $# -gt 0 ]]; then
        # shellcheck disable=SC2059
        printf "$@" >&2
        exit 1
    fi

    cat >&2 <<EOF
usage: ${0##*/} [dmenu(1) option...]

Environment variables:
    PATH${PATH:+ (current value: "${PATH@Q}")}
        A colon-separated (:) list of directories to search for executable
        files in. See environ(1) for details.

    DMENU${DMENU:+ (current value: "${DMENU@Q}")}
        A dmenu(1)-like executable used for display the command list, that
        accepts a list on standard input, and outputs the user's desired
        command on standard output.
        If unset, default to \`dmenu -p 'run'\`. See dmenu(1) for a list
        of valid arguments.

    DMENU_RUN_HISTORY${DMENU_RUN_HISTORY:+ (current value: "${DMENU_RUN_HISTORY@Q}")}
        The file to write a new-line separated command history to.
        If set to "/dev/null" or an empty value, do not write history.

    DMENU_RUN_HISTORY_LENGTH${DMENU_RUN_HISTORY_LENGTH:+ (current value: "${DMENU_RUN_HISTORY_LENGTH@Q}")}
        An unsigned integer of how many commands to keep in command history.
        Defaults to 64 entries in history at a time.
        If set to 0 or set to an empty value, do not write history.

    DMENU_RUN_SCRIPT${DMENU_RUN_SCRIPT:+ (current value: "${DMENU_RUN_SCRIPT@Q}")}
        A sh(1) script. If the value is a file that exists, it will be sourced
        into the runtime environment before building the list of executables.
        If any aliases or functions are set in this script, they will appear in
        the list as valid commands.

Functions:
    _dmenu_run_before_execute()
        If defined, this function is ran before executing a command.
        It is passed the executed command as arguments.

    _dmenu_run_after_execute()
        If defined, this function is ran after executing a command.
        It is passed the executed command as arguments.

    _dmenu_run_command_not_found()
        If defined, this function is ran when the given command cannot
        be found. It is passed the executed command as arguments.

Handling of commands:
    - If the command starts with a '+', it will be added to the command
      history without being executed.
    - If the command starts with a '-', it will be removed from the command
      history without being executed.
    - If the command starts with leading whitespace, it will be executed
      without being added to the command history.

Invalid command handling:
    When a command cannot be found, dmenu-run will attempt to use a
    command-not-found handler, a form of integration sometimes provided by
    systems that adds integration for a system's package manager, to a user's
    interactive shell. See "COMMAND EXECUTION" in bash(1) for details.

    dmenu-run will try these handler functions, passing them the command as
    arguments (listed in order of priority):
        1. _dmenu_run_command_not_found
        2. command_not_found_handle
        3. command-not-found

EOF
    exit 69
}

notify() {
    notify-send -a dmenu-run -i launch "$@"
    printf '%s\n' "$@" >&2
}

quote() {
    local strings=()
    local string
    for string; do
        if [[ "'${string}'" == "${string@Q}" ]]; then
            strings+=("${string}")
        else
            strings+=("${string@Q}")
        fi
    done
    printf '%s' "${strings[*]}"
}

quote_as_one() {
    local string="$*"
    quote "${string}"
}

should_use_command_history() {
    [[ -n "${DMENU_RUN_HISTORY}" ]] \
        && [[ "${DMENU_RUN_HISTORY}" != '/dev/null' ]] \
        && [[ -n "${DMENU_RUN_HISTORY_LENGTH}" ]] \
        && [[ "${DMENU_RUN_HISTORY_LENGTH}" -ne 0 ]] \
        && return 0
    return 1
}

print_command_history() {
    if should_use_command_history; then
        head -n "${DMENU_RUN_HISTORY_LENGTH}" "${DMENU_RUN_HISTORY}"
    fi
}

add_to_command_history() {
    if should_use_command_history; then
        printf '%s\n' "$*"
        print_command_history
    fi
}

remove_hidden_commands() {
    sed -E \
        -e '/^\s/ d' \
        -e '/^-/  d' \
        -e '/^\./ d' \
        -e '/^_/  d' \
        "$@"
}

print_command_list() {
    # 1a. Get PATH value (or a default PATH value).
    local PATH="${PATH:-$(getconf PATH)}"
    local executable_paths=()

    # 1b. Split it by ':' and construct an array of paths from it.
    IFS=: read -r -a executable_paths <<<"${PATH}"

    {
        # 1c. Print all executable non-directories in the paths,
        find -L \
            "${executable_paths[@]}" \
            ! -type d \
            -executable \
            -printf '%f\n' \
            2>/dev/null

        # as well as any function names and alias names in the runtime.
        declare -F | cut -d ' ' -f3-
        alias | cut -c7- | cut -d= -f1
    } \
        |
        # 1d. Sort the list of executables.
        sort -d \
        |
        # 1e. Concatenate the command history and the executable list together,
        #     ensuring the history remains at the beginning.
        remove_hidden_commands \
            <(
                # 1f. Gather list of command history, limiting the history prefix to
                #     $DMENU_RUN_HISTORY_LENGTH.
                print_command_history
            ) \
            - \
        | uq # 1g. Print concatenated and deduplicated list of history and executables.
}

validate_command_history_with_notification() {
    local command_history_entry=()
    local command_history_entry_i=0

    while IFS=$' \t\n' read -r -a command_history_entry; do
        if type -t "${command_history_entry[0]}" >/dev/null 2>&1; then
            printf '%s\n' "$(quote "${command_history_entry[@]}")"
        elif [[ "${command_history_entry_i}" -eq 0 ]]; then
            #     a. If it is the first command in the list, show a 'command not found'
            #        notification for it.
            notify "${command_history_entry[0]}" "command not found"
        fi

        command_history_entry_i=$((command_history_entry_i + 1))
    done
}

write_command_history() {
    if should_use_command_history; then
        mkdir -p "$(dirname "${DMENU_RUN_HISTORY}")"
        touch "${DMENU_RUN_HISTORY}"
        uq | ifne sponge "${DMENU_RUN_HISTORY}"
    fi
}

case "${1:-}" in
    -h | --help) usage ;;
esac

dmenu_args=("$@")

for v in DMENU DMENU_RUN_HISTORY DMENU_RUN_HISTORY_LENGTH DMENU_RUN_SCRIPT; do
    [[ -v "${v}" ]] || usage 'error: %q must be set.\n' "${v}"
done
unset v

[[ "${DMENU_RUN_HISTORY_LENGTH:-}" =~ ^[0-9]+$ ]] || usage 'DMENU_RUN_HISTORY_LENGTH must be an unsigned integer.'

# shellcheck source=/dev/null
[[ -e "${DMENU_RUN_SCRIPT}" ]] && . "${DMENU_RUN_SCRIPT}"

command=$(
    # 1. Gather list of executables.
    print_command_list \
        | eval "${DMENU} ${dmenu_args[*]@Q}" # 2. Display list with dmenu(1).
)

unset IFS
read -r -a command <<<"${command}"
[[ -n "${command[*]}" ]] || exit 0

case "${command[0]}" in
    '+'*)
        add_to_command_history "${command[0]#+}${command[1]:+ ${command[*]:1}}" \
            | remove_hidden_commands \
            | write_command_history
        exit 0
        ;;

    '-'*)
        command_history_length_before=$(print_command_history | wc -l)

        print_command_history \
            | grep -Fv -- "${command[0]#'-'}${command[1]:+ ${command[*]:1}}" \
            | write_command_history

        command_history_length_after=$(print_command_history | wc -l)
        if [[ "${command_history_length_after}" -ne "${command_history_length_before}" ]]; then
            notification_text=$(
                printf \
                    "removed '%s' from history (%i commands in history -> %i commands in history)." \
                    "$(quote_as_one "${command[0]#'-'}${command[1]:+ ${command[*]:1}}")" \
                    "${command_history_length_before}" \
                    "${command_history_length_after}"
            )
            notify "${0##*/}" "${notification_text}"
            exit 0
        else
            notify "${0##*/}" "no command in history matching '$(quote_as_one "${command[0]#'-'}${command[1]:+ ${command[*]:1}}")'."
            exit 1
        fi
        ;;
esac

if type -t "${command[0]}" >/dev/null 2>&1; then
    type -t "_dmenu_run_before_execute" >/dev/null 2>&1 && _dmenu_run_before_execute "${command[@]}"

    command_error=0
    (
        command_base=
        for command_base in "${command[@]}"; do
            case "${command_base}" in
                # ignore `,`, which is provided by pkgs.comma
                ,) continue ;;
                *) break ;;
            esac
        done

        unset DMENU DMENU_RUN DMENU_RUN_HISTORY DMENU_RUN_HISTORY_LENGTH DMENU_RUN_SCRIPT
        printf '$ %s\n' "$(quote "${command[@]}")" >&2
        exec systemd-cat -t "dmenu-run-${command_base}" --level-prefix=false -- setsid -- "${command[@]}"
    ) &
    command_error=$?

    type -t "_dmenu_run_after_execute" >/dev/null 2>&1 && _dmenu_run_after_execute "${command[@]}"

    [[ "${command_error}" -eq 0 ]] || notify "${command[0]}" "command exited with ${command_error}."
else
    if type -t _dmenu_run_command_not_found >/dev/null 2>&1; then
        _dmenu_run_command_not_found "${command[@]}" || exit $?
    elif type -t command_not_found_handle >/dev/null 2>&1; then
        command_not_found_handle "${command[@]}" || exit $?
    elif type -t command-not-found >/dev/null 2>&1; then
        command-not-found "${command[@]}" || exit $?
    else
        notify "${command[0]}" "command not found."
        exit 1
    fi
fi

add_to_command_history "$(quote "${command[@]}")" \
    | remove_hidden_commands \
    | validate_command_history_with_notification \
    | write_command_history
