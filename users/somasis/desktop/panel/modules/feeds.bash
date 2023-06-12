# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_COLOR_YELLOW:?}"

unread() {
    local unread

    pgrep newsboat >/dev/null 2>&1 && return

    unread=$(LC_ALL=C newsboat -x print-unread 2>&1)
    unread=${unread%% *}
    case "${unread}" in
        0) o= ;;
        'Error:'*) : ;;
        *) o="${unread}" ;;
    esac

    o="%{A1:jumpapp -t newsboat -c newsboat -f kitty -T newsboat --class newsboat -e newsboat:}%{U${PANEL_COLOR_YELLOW}}%{+u}%{O12}${o}%{O12}%{-u}%{U-}%{A}"
    printf '%s\n' "${o}"
}

unread
sleep 1
while rwc -e "${XDG_CACHE_HOME:=${HOME}/.cache}"/newsboat/cache.db >/dev/null; do
    unread
    sleep 1
done
