# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_COLOR_BACKGROUND:?}"
: "${PANEL_COLOR_GREEN:?}"

iftrue() {
    [[ "$1" == "on" ]] && return
    return 1
}

get() {
    local IFS
    local current status s o
    IFS=$'\t'

    # ${status[1]}  %length%
    # ${status[2]}  %totaltime%
    # ${status[3]}  %currenttime%
    # ${status[4]}  %state%
    # ${status[5]}  %repeat%
    # ${status[6]}  %single%
    # ${status[7]}  %random%
    # ${status[8]}  %consume%
    # ${status[9]}  %volume%
    # ${current[1]} %position%
    # ${current[2]} %artist%
    # ${current[3]} %title%

    mapfile -d $'\t' status < <(mpc status '%length%\t%totaltime%\t%currenttime%\t%state%\t%repeat%\t%single%\t%random%\t%consume%\t%volume%')
    mapfile -d $'\t' current < <(mpc current -f '%position%\t%artist%\t%title%')

    mixer_color=${status[9]%"%"}
    mixer_color=${mixer_color##* }
    case "${mixer_color}" in
        -1 | 0) mixer_color="${PANEL_COLOR_BACKGROUND}" ;;
        100) mixer_color="${PANEL_COLOR_GREEN}" ;;
        *)
            mixer_color=$(
                pastel mix -f ."$(printf '%.2d' "${mixer_color}")" "${PANEL_COLOR_GREEN}" "${PANEL_COLOR_BACKGROUND}" \
                    | pastel format hex
            )
            ;;
    esac

    # is mpd stopped?
    [[ "${status[2]} ${status[3]} ${status[4]}" = "0:00 0:00 paused" ]] \
        && printf '\n' \
        && return

    a=${current[2]}
    if [[ "${#a}" -gt 24 ]]; then
        a=${a%% & *}
        a=${a%%,*}
        a=${a%%/*}
        a=${a%% - *}
        a=${a%% feat. *}
    fi
    a=$(ellipsis 24 <<<"${a}")

    t=${current[3]}
    if [[ "${#t}" -gt 24 ]]; then
        t=${t%%/*}
        t=${t%% - *}
        t=${t%%: *}
    fi
    t=${t% / *}
    t=$(ellipsis 24 <<<"${t}")
    case "${t}" in *' ') t=${t% *} ;; esac

    o="${a:+${a} - }${t}"

    # "Transliterate" common punctuation to their ASCII equivalents,
    # useful for if lemonbar's font does not support all of Unicode.
    # o=$(<<<"${p}" teip -d $"\t" -f 1 -og '[´‘’“”]' -- iconv -f utf-8 -t ascii//translit)

    if [[ "${status[4]}" == "playing" ]]; then
        s=
        iftrue "${status[5]}" && s="${s}%{+o}%{A1:mpc -q repeat:}%{O8}↻%{O8}%{A}%{-o}"  || s="${s}%{A1:mpc -q repeat:}%{O8}↻%{O8}%{A}" # repeat
        iftrue "${status[6]}" && s="${s}%{+o}%{A1:mpc -q single:}%{O8}❶%{O8}%{A}%{-o}"  || s="${s}%{A1:mpc -q single:}%{O8}❶%{O8}%{A}" # single
        iftrue "${status[7]}" && s="${s}%{+o}%{A1:mpc -q random:}%{O8}⁑%{O8}%{A}%{-o}"  || s="${s}%{A1:mpc -q random:}%{O8}⁑%{O8}%{A}" # random
        iftrue "${status[8]}" && s="${s}%{+o}%{A1:mpc -q consume:}%{O8}␡%{O8}%{A}%{-o}" || s="${s}%{A1:mpc -q consume:}%{O8}␡%{O8}%{A}" # consume
        o="${s:+${s} }${o}"
        s=
    else
        o="%{O8}${o}"
    fi

    o="${o}%{O8}"

    o="%{A2:mpc -q cdprev:}${o}%{A}"
    o="%{A3:mpc -q next:}${o}%{A}"
    o="%{A4:mpc -q volume +5:}%{A5:mpc -q volume -5:}${o}%{A}%{A}"
    o="%{A1:mpc -q toggle:}${o}%{A}"

    [[ "${status[4]}" == "playing" ]] && o="%{+u}${o}%{-u}"

    o="%{U${PANEL_COLOR_GREEN}}${o}%{U-}"

    printf '%s\n' "${o}"
}

while systemd-wait --user -q "mpd.service" active; do
    get
    mpc idleloop player options | while read -r _; do get; done
done
