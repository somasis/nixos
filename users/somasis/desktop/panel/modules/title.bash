# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_MONITOR:?}"
: "${PANEL_RUNTIME:?}"

: "${PANEL_COLOR_BACKGROUND:?}"
: "${PANEL_COLOR_FOREGROUND:?}"
: "${PANEL_COLOR_BLACK:?}"
: "${PANEL_COLOR_RED:?}"
: "${PANEL_COLOR_GREEN:?}"
: "${PANEL_COLOR_YELLOW:?}"
: "${PANEL_COLOR_BLUE:?}"
: "${PANEL_COLOR_MAGENTA:?}"
: "${PANEL_COLOR_CYAN:?}"
: "${PANEL_COLOR_WHITE:?}"
: "${PANEL_COLOR_BRIGHT_BLACK:?}"
: "${PANEL_COLOR_BRIGHT_RED:?}"
: "${PANEL_COLOR_BRIGHT_GREEN:?}"
: "${PANEL_COLOR_BRIGHT_YELLOW:?}"
: "${PANEL_COLOR_BRIGHT_BLUE:?}"
: "${PANEL_COLOR_BRIGHT_MAGENTA:?}"
: "${PANEL_COLOR_BRIGHT_CYAN:?}"
: "${PANEL_COLOR_BRIGHT_WHITE:?}"

: "${PANEL_FONT_BOLD:?}"

runtime="${PANEL_RUNTIME}/title"
mkdir -p "${runtime}"
cd "${runtime}"

while :; do xtitle -is -f $'%u\t%s\n'; done \
    | while IFS=$'\t' read -r node node_title; do
        node_monitor=$(bspc query -M -n "${node}" --names)

        if [[ "${node}" -eq 0 ]] || [[ "${PANEL_MONITOR}" != "${node_monitor}" ]]; then
            printf '\n'
            continue
        fi

        node_name=$(
            xprop \
                -notype \
                -id "${node}" \
                WM_CLASS WM_ICON_NAME WM_TITLE 2>/dev/null \
                | sed -E '/ = /!d; s/^[^ ]* = "//; s/.*", "//; s/"$//; 1q' \
                | tr '/' .
        )

        if [[ -e "${node_name}.name" ]]; then
            node_pretty_name=$(<"${node_name}.name")
        else
            node_pretty_name=$(awk -F'[^[:alnum:]]' '{ print tolower($1) }' <<<"${node_name}")
        fi

        module_background=
        module_foreground=

        case "${node_pretty_name}" in
            alacritty)
                # module_background=${PANEL_COLOR_BLACK}

                node_name="${node_title%%:*}"
                node_name="${node_name%% *}"
                case "${node_title}" in
                    [Aa]'lacritty' | '')
                        node_title="alacritty"
                        ;;
                    *": "*" - Kakoune")
                        node_title="${node_title%%: *}: kakoune${node_title:+: }${node_title% - Kakoune}"
                        node_name="kakoune"
                        ;;
                    "Kakoune" | *" - Kakoune")
                        node_title="kakoune${node_title:+: }${node_title% - Kakoune}"
                        node_name="kakoune"
                        ;;
                    "tmux" | "tmux: "*)
                        node_name=${node_title#tmux: }
                        node_name=${node_name%%:*}
                        node_name=${node_name%% *}
                        ;;
                        # "alacritty: bash: /"*)
                        #     child=$(pgrep -P "$(xdotool getwindowpid "${node}")" | tail -n1)
                        #     node_title=$(<"/proc/${child}/comm")
                        #     ;;
                esac
                ;;
            discord)
                module_background=${PANEL_COLOR_BLUE}

                case "${node_title}" in
                    *' | '*' - Discord')
                        node_title="${node_title% - Discord}"
                        node_title="discord${node_title:+: ${node_title##* | }: ${node_title% | *}}"
                        ;;
                    *' - Discord')
                        node_title="${node_title% - Discord}"
                        node_title="discord${node_title:+: ${node_title}}"
                        ;;
                    'Discord' | ' - Discord' | '')
                        node_title="discord"
                        ;;
                esac
                ;;
            cantata)
                module_background=${PANEL_COLOR_BLUE}

                node_title=${node_title#Cantata }
                case "${node_title}" in
                    *' — Cantata')
                        node_title=": ${node_title% — Cantata}"
                        ;;
                    *)
                        node_title="${node_title:+: ${node_title}}"
                        ;;
                esac
                case "${node_title}" in
                    ': [default]') node_title=${node_title%: \[default\]} ;;
                    '[default]') node_title=${node_title#\[default\]} ;;
                esac
                node_title="${node_pretty_name}${node_title}"
                ;;
            prismlauncher)
                module_background=${PANEL_COLOR_BLACK}

                case "${node_title}" in
                    *' — Prism Launcher '*'.'*'.'*)
                        node_title="${node_pretty_name}: ${node_title% — Prism Launcher *.*.*}"
                        ;;
                    'Prism Launcher '*'.'*'.'*)
                        node_title="${node_pretty_name}"
                        ;;
                    *)
                        node_title="${node_pretty_name}${node_title:+: ${node_title}}"
                        ;;
                esac
                ;;
            minecraft)
                module_background=${PANEL_COLOR_BLACK}
                node_title="${node_pretty_name}"
                ;;
            qutebrowser)
                module_background=${PANEL_COLOR_BRIGHT_BLUE}
                module_foreground=${PANEL_COLOR_BACKGROUND}

                case "${node_title}" in
                    'qutebrowser - '*)
                        node_title="${node_title#qutebrowser - }"
                        node_title="${node_pretty_name}${node_title:+: ${node_title}}"
                        ;;
                    *)
                        node_title="${node_pretty_name}"
                        ;;
                esac
                ;;
            libreoffice | libreoffice-* | soffice)
                node_pretty_name="libreoffice"
                node_title="${node_title% - LibreOffice *}"
                node_title="${node_pretty_name}${node_title:+: ${node_title}}"
                ;;
            fl.exe | fl64.exe | fl | fl64)
                module_background=${PANEL_COLOR_YELLOW}

                node_pretty_name="fl"

                case "${node_title}" in
                    *' - FL Studio '[0-9]*)
                        node_title="${node_title% - FL Studio [0-9]*}"
                        ;;
                    'FL Studio '[0-9]*)
                        node_title=
                        ;;
                esac

                node_title="${node_pretty_name}${node_title:+: ${node_title}}"
                ;;
            io.github.quodlibet.ExFalso)
                node_pretty_name="exfalso"

                case "${node_title}" in
                    *' - Ex Falso')
                        node_title="${node_title% - Ex Falso}"
                        ;;
                    'Ex Falso')
                        node_title=
                        ;;
                esac

                node_title="${node_pretty_name}${node_title:+: ${node_title}}"
                ;;
            '.zoom ')
                node_pretty_name="zoom"
                module_background=${PANEL_COLOR_BLUE}

                case "${node_title}" in
                    "Zoom Cloud Meetings")
                        node_title=
                        ;;
                esac

                node_title="${node_pretty_name}${node_title:+: ${node_title}}"
                ;;
            zenity)
                node_pretty_name="${node_title}"
                node_title="${node_pretty_name}${node_title:+: ${node_title}}"
                ;;
            zotero)
                node_pretty_name=zotero
                module_background=${PANEL_COLOR_RED}

                node_title="${node_pretty_name}${node_title:+: ${node_title% - Zotero}}"
                ;;
            *)
                case "${node_title}" in
                    .*)
                        node_title=${node_title#.}
                        ;;
                esac

                case "${node_title}" in
                    *-wrapped)
                        node_title=${node_title%-wrapped}
                        ;;
                esac

                case "${node_title}" in
                    "${node_name} - "*)
                        node_title="${node_pretty_name}${node_title:+: }${node_title#"${node_name} - "}"
                        ;;
                    *" - ${node_name}")
                        node_title="${node_pretty_name}${node_title:+: }${node_title%" - ${node_name}"}"
                        ;;
                    *)
                        node_title="${node_pretty_name}${node_title:+: }${node_title}"
                        ;;
                esac
                ;;
        esac

        if [[ -z "${module_background}" ]]; then
            if [[ -e "${runtime}"/"${node_name}".bg ]]; then
                module_background=$(<"${node_name}.bg")
            else
                set -- $(echo "${node_name}" | od -An -s)
                set -- $(printf '%i\n' "${1}")
                module_background=$(printf '%i\n' "$(($1 % 15))" | tee "${node_name}.bg")

            fi

            module_foreground=
            [[ "${module_background}" -gt 8 ]] && module_foreground="${PANEL_COLOR_BACKGROUND}"
            case "${module_background}" in
                0) module_background="${PANEL_COLOR_BLACK}" ;;
                1) module_background="${PANEL_COLOR_RED}" ;;
                2) module_background="${PANEL_COLOR_GREEN}" ;;
                3) module_background="${PANEL_COLOR_YELLOW}" ;;
                4) module_background="${PANEL_COLOR_BLUE}" ;;
                5) module_background="${PANEL_COLOR_MAGENTA}" ;;
                6) module_background="${PANEL_COLOR_CYAN}" ;;
                7) module_background="${PANEL_COLOR_WHITE}" ;;
                8) module_background="${PANEL_COLOR_BRIGHT_BLACK}" ;;
                9) module_background="${PANEL_COLOR_BRIGHT_RED}" ;;
                10) module_background="${PANEL_COLOR_BRIGHT_GREEN}" ;;
                11) module_background="${PANEL_COLOR_BRIGHT_YELLOW}" ;;
                12) module_background="${PANEL_COLOR_BRIGHT_BLUE}" ;;
                13) module_background="${PANEL_COLOR_BRIGHT_MAGENTA}" ;;
                14) module_background="${PANEL_COLOR_BRIGHT_CYAN}" ;;
                15) module_background="${PANEL_COLOR_BRIGHT_WHITE}" ;;
            esac
        fi

        [[ -n "${module_foreground}" ]] || module_foreground="${PANEL_COLOR_FOREGROUND}"

        title_trim=${node_title:0:87}
        [[ "${#node_title}" -eq "${#title_trim}" ]] || node_title="${title_trim}..."

        if [[ -n "${node_title}" ]]; then
            o="%{B${module_background}}%{F${module_foreground}}${node_title:+%{O12\}${node_title}%{O12\}}%{F-}%{B-}"

            # Right click close, scroll down for next window, up for previous
            o="%{A1:bspc desktop -l next:}${node_title}%{A}"
            o="%{A3:bspwm-hide-or-close:}${o}%{A}"
            o="%{A4:bspc node -f prev.local.!hidden.window:}${o}%{A}"
            o="%{A5:bspc node -f next.local.!hidden.window:}${o}%{A}"

            # Use the bold font.
            node_title="%{T${PANEL_FONT_BOLD}}${node_title}%{T-}"

            printf '%s\n' "${o}"
        fi

        [[ -e "${node_name}.name" ]] || printf '%s\n' "${node_pretty_name}" >"${node_name}.name"
        last_node_name="${node_name}"
    done
