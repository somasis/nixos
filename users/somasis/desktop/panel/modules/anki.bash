# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_COLOR_BRIGHT_BLUE:?}"
: "${XDG_DATA_HOME:=~/.local/share}"

due() {
    local due o

    pgrep 'anki' >/dev/null 2>&1 && return

    due=$(apy info | grep '^Sum' | tr -s ' ' | cut -d ' ' -f4)
    case "${due}" in
        0)
            o=
            ;;
        *)
            o="anki: ${due}"
            ;;
    esac

    o="%{A1:jumpapp anki:}%{U${PANEL_COLOR_BRIGHT_BLUE}}%{+u}%{O12}${o}%{O12}%{-u}%{U-}%{A}"
    printf '%s\n' "${o}"
}

due
sleep 1
while rwc -e "${XDG_DATA_HOME}"/Anki2/*/collection.anki2 >/dev/null; do
    due
    sleep 1
done
