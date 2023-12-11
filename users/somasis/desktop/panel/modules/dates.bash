# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_COLOR_BACKGROUND:?}"
: "${PANEL_COLOR_BLACK:?}"
: "${PANEL_FONT_LIGHT:?}"

: "${TZ:=/etc/localtime}"

home_TZ=/etc/zoneinfo/America/New_York

TZ=$(readlink -f "${TZ}")
home_TZ=$(readlink -f "${home_TZ}")

background="${PANEL_COLOR_BLACK}"
home_background=$(pastel mix -f .5 "${background}" "${PANEL_COLOR_BACKGROUND}" | pastel format hex)
foreground=$(pastel textcolor "${background}" | pastel format hex)

if [[ "${TZ}" != "${home_TZ}" ]]; then
    tzdiff=' ('$(datediff --from-zone="${home_TZ}" -i "%H:%M" -f "%Hh%Mm" "$(TZ="${home_TZ}" date +%H:%M)" "$(date +%H:%M)" | sed 's/h0m$/h/')')'
fi

while :; do
    o=
    [[ "${TZ}" != "${home_TZ}" ]] && o="${o}%{F-}%{B-}%{B${home_background}}%{O12}"$(TZ="${home_TZ}" date +"%I:%M %p")"%{O12}"
    o="${o}%{F${foreground}}%{B${background}}%{O12}"$(date +"%I:%M %p${tzdiff}")"%{O12}%{F-}%{B-}"

    o="%{T${PANEL_FONT_LIGHT}}${o}%{T-}"

    # Scroll wheel brightness controls.
    o="%{A4:brillo -el -u 25000 -A 2:}%{A5:brillo -el -u 25000 -U 2:}${o}%{A}%{A}"

    # Launch big clock
    o="%{A1:systemctl --user -q is-active stw-dates.service && systemctl --user stop stw-dates.service || systemctl --user start stw-dates.service:}${o}%{A}"

    printf '%s\n' "${o}"

    snooze -H* -M*
done
