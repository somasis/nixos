# shellcheck shell=bash disable=SC3000-SC3999
# Display the current volume, with the current sink's name, if it is not the built-in sink.
set -euo pipefail

: "${PANEL_COLOR_BACKGROUND:?}"
: "${PANEL_COLOR_BRIGHT_BLUE:?}"

get() {
    local sink sink_volume sink_muted
    local color

    sink=$(ponymix --short -t sink | cut -f4 | head -n1)
    sink_volume=$(ponymix --short -t sink get-volume)
    sink_muted=$(
        ponymix --short -t sink is-muted \
            && echo true \
            || echo false
    )

    color=$(printf '%.2d' "${sink_volume}")
    case "${color}" in
        100) color="${PANEL_COLOR_BRIGHT_BLUE}" ;;
        00) color="${PANEL_COLOR_BACKGROUND}" ;;
        *)
            color=$(
                pastel mix -f ."${color}" "${PANEL_COLOR_BRIGHT_BLUE}" "${PANEL_COLOR_BACKGROUND}" \
                    | pastel format hex
            )
            ;;
    esac

    case "${sink}" in
        Built-in*)
            sink="${sink_volume}%"
            ;;
        'Dummy Output')
            printf '\n'
            return
            ;;
        *)
            sink="${sink}: ${sink_volume}%"
            ;;
    esac

    sink="%{O12}${sink}%{O12}"

    case "${sink_muted}" in
        false) sink="%{+u}${sink}%{-u}" ;;
        true) : ;;
    esac

    o="%{U${color}}${sink}%{U-}"

    o="%{A1:pavucontrol &:}${o}%{A}"
    o="%{A2:ponymix-cycle-default sink:}${o}%{A}"
    o="%{A3:ponymix toggle >/dev/null:}${o}%{A}"
    o="%{A4:ponymix-snap increase 5 >/dev/null:}${o}%{A}"
    o="%{A5:ponymix-snap decrease 5 >/dev/null:}${o}%{A}"

    printf '%s\n' "${o}"
}

get
pactl subscribe \
    | while IFS= read -r line; do
        case "${line}" in
            *" on server #"* | *" on sink #"*) : ;;
            *) continue ;;
        esac
        get
    done
