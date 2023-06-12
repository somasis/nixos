# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_MONITOR:?}"

: "${PANEL_FONT_BOLD:?}"

: "${PANEL_COLOR_BACKGROUND:?}"
: "${PANEL_COLOR_FOREGROUND:?}"
: "${PANEL_COLOR_ACCENT:?}"

report=()

bspc subscribe report \
    | while IFS=: read -r -a report; do
        # Lines from `bspc subscribe report` always begin with a "W".
        report[0]=${report[0]#?}

        skip_remaining_attributes=false

        monitors=()
        desktops=()

        focused_monitor=
        focused_desktop=

        # Run through report and...
        for attribute in "${report[@]}"; do
            k=${attribute:0:1}
            v=${attribute:1}

            case "${k}" in
                M)
                    focused_monitor="${v}"
                    monitors+=("${focused_monitor}")

                    skip_remaining_attributes=true

                    [[ "${v}" == "${PANEL_MONITOR}" ]] && skip_remaining_attributes=false
                    ;;

                m) monitors+=("${v}") ;;
            esac

            [[ "${skip_remaining_attributes}" == true ]] && continue

            case "${k}" in
                [OFU])
                    focused_desktop="${v}"
                    desktops+=("${focused_desktop}")
                    ;;
                [ofu]) [[ "${skip_remaining_attributes}" == true ]] || desktops+=("${v}") ;;
            esac
        done

        output=

        # Populate the desktop list
        desktop_number=0
        desktop_item=
        for desktop in "${desktops[@]}"; do
            desktop_number=$((desktop_number + 1))

            # Construct the list number item
            desktop_item=${desktop}

            # Add padding.
            desktop_item="%{O8}${desktop}%{O8}"

            # Underline and bold the number item if it is the focused desktop.
            if [[ "${desktop}" == "${focused_desktop}" ]]; then
                desktop_item="%{T${PANEL_FONT_BOLD}}${desktop_item}%{T-}"

                desktop_item="%{+u}${desktop_item}%{-u}"
            fi

            desktop_item="%{A1:bspc desktop -f 'focused\:^${desktop_number}':}${desktop_item}%{A}"

            output+="${desktop_item}"
        done

        # Highlight the desktop indicator on our desktop when our desktop is also the focused desktop
        if [[ "${focused_monitor}" = "${PANEL_MONITOR}" ]]; then
            output="%{B${PANEL_COLOR_ACCENT}}%{U${PANEL_COLOR_FOREGROUND}}${output}%{U-}%{B-}"
        else
            output="%{B${PANEL_COLOR_BACKGROUND}}%{U${PANEL_COLOR_ACCENT}}${output}%{U-}%{B-}"
        fi

        # Add scroll actions for scrolling through the desktop list.
        output="%{A4:bspc desktop -f \"\$(bspc query -D -m \"${PANEL_MONITOR}\" -d prev.local)\":}%{A5:bspc desktop -f \"\$(bspc query -D -m \"${PANEL_MONITOR}\" -d next.local)\":}${output}%{A}%{A}"

        printf '%s\n' "${output}"
    done
