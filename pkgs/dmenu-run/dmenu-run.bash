# shellcheck shell=bash

: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${DMENU_RUN_HISTORY:=${XDG_CACHE_HOME}/dmenu/dmenu-run.cache}"
: "${DMENU_RUN_SCRIPT:=${XDG_DATA_HOME}/dmenu/dmenu-run.sh}"

: "${DMENU_RUN_HISTORY_LENGTH:=$((16 * 4))}"

mkdir -p "${DMENU_RUN_HISTORY%/*}"

# shellcheck source=/dev/null
[[ -e "${DMENU_RUN_SCRIPT}" ]] && . "${DMENU_RUN_SCRIPT}"

IFS=: read -r -a executable_paths <<<"${PATH}"

choice=$(
    {
        find -L \
            "${executable_paths[@]}" \
            ! -type d \
            -executable \
            -printf '%f\n' \
            2>/dev/null

        declare -F | cut -d ' ' -f3-
        alias | cut -c7- | cut -d= -f1
    } \
        | grep -v -e '^_' -e '^\.' \
        | sort "${DMENU_RUN_HISTORY}" - \
        | cat "${DMENU_RUN_HISTORY}" - 2>/dev/null \
        | uq \
        | ${DMENU:-dmenu -x -g 4 -l 16} -S -p "run" "$@"
)

[[ -n "${choice}" ]] || exit 0

{
    systemd-cat -t "dmenu-run" --level-prefix=false \
        "${SHELL:-/bin/sh}" -x -c "${choice}"
} &

touch "${DMENU_RUN_HISTORY}"

line_i=0
cat - "${DMENU_RUN_HISTORY}" <<<"${choice}" \
    | head -n "${DMENU_RUN_HISTORY_LENGTH}" \
    | grep -v \
        -e "^\s*$" \
        -e '^\..*' \
    | uq \
    | while read -r line; do
        base=${line%% *}
        if command -v "${base}" >/dev/null 2>&1; then
            printf "%s\n" "${line}"
        elif [[ "${line_i}" -eq 0 ]]; then
            # don't notify for every invalid command in the history;
            # only notify for the first line, the most recent command
            notify-send -a dmenu-run -i launch "dmenu-run" "${base}: command not found"
        fi

        line_i=$((line_i + 1))
    done \
    | ifne sponge "${DMENU_RUN_HISTORY}"
