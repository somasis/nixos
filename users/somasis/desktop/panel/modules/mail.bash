# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_COLOR_ACCENT:?}"

count() {
    o=$(mdirs ~/mail/*/Inbox | mlist -s | wc -l)
    [[ "${o}" -gt 0 ]] && o="toki: ${o}" || o=""

    o="%{A1:jumpapp -c mrepl -t mrepl -- kitty --class mrepl -T mrepl mrepl:}%{U${PANEL_COLOR_ACCENT}}%{+u}%{O12}${o}%{O12}%{-u}%{U-}%{A}"
    printf "%s\n" "${o}"
}

count
while mdirs -a ~/mail/*/Inbox | sed 's|$|/cur|' | rwc -ced >/dev/null; do
    count
done
