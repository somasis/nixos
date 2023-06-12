# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_COLOR_BLUE:?}"

trap 'trap - INT TERM QUIT EXIT; kill 0' INT TERM QUIT EXIT

export LC_ALL=C

monitor() {
    nmcli -t monitor &
    rfkill event &
    wait
}

parse() {
    o=$(
        nmcli -t -f type,uuid connection show --active \
            | sed \
                -e '/^loopback:/d' \
                -e 's/^[^:]*://' \
            | xe nmcli -g GENERAL.NAME connection show {}
    )

    o="%{A1:kitty -T nmctl --class nmctl nmctl &:}%{A3:kitty -T btcli --class btcli btcli &:}%{U${PANEL_COLOR_BLUE}}%{+u}%{O8}${o}%{O8}%{-u}%{U-}%{A}%{A}"

    printf '%s\n' "${o}"
}

parse
monitor | while read -r _; do parse; done
