# shellcheck shell=bash

: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${DMENU_RUN_HISTORY:=${XDG_CACHE_HOME}/dmenu/dmenu-run.cache}"

mkdir -p "${DMENU_RUN_HISTORY%/*}"

choice=$(
    {
        IFS=:
        # We want the $PATH to be split here.
        # shellcheck disable=SC2086
        find ${PATH} \
            ! -name '.*' \
            ! -type d \
            -executable 2>/dev/null \
            | sed 's@.*/@@' \
            | sort "${DMENU_RUN_HISTORY}" - \
            | cat "${DMENU_RUN_HISTORY}" - 2>/dev/null
        unset IFS
    }   | uq \
        | ${DMENU:-dmenu -g 4 -l 16} -S -p "run" "$@"
)

[[ -n "${choice}" ]] || exit 0

touch "${DMENU_RUN_HISTORY}"

${SHELL:-sh} -x - <<<"${choice}" &

cat - "${DMENU_RUN_HISTORY}" <<<"${choice}" \
    | head -n 24 \
    | grep -v -e "^\s*$" -e '^\..*' \
    | uq \
    | while read -r line; do
        base=${line%% *}
        if command -v "${base}" >/dev/null 2>&1; then
            printf "%s\n" "${line}"
        else
            notify-send -a dmenu-run -i system-run "run" "'${base}' is not a valid command."
        fi
    done \
    | ifne sponge "${DMENU_RUN_HISTORY}"
