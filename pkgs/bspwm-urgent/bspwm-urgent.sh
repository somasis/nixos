# shellcheck shell=bash

set -euo pipefail

# exports $node_class and $node_hash
set_node_variables() {
    : "${node:?set_node_variables(): no node provided}"

    node_class=$(xdotool getwindowclassname "${node}")
    node_hash=$(printf '%s%s' "${node}" "${node_class}" | sha256sum)
    node_hash=${node_hash%% *}

    export node_class node_hash
}

# exports $notification_id
set_notification_variables() {
    : "${node_hash:?set_notification_variables(): no node hash provided}"

    local notification_id notification_file

    notification_id=
    notification_file="${runtime}/${node_hash}.notification"
    if [[ -e "${notification_file}" ]]; then
        notification_id=$(cat "${notification_file}")
    fi
    export notification_id notification_file
}

notify() {
    if [[ -n "${NOTIFY_SOCKET}" ]]; then
        systemd-notify "$@"
    fi
}

process() {
    local event="${1:?process(): no event given}"
    shift

    case "${event}" in
        node_flag)
            # local node_monitor node_desktop node node_flag node_flag_state
            # local node_monitor="$1"
            local node_desktop="$2"
            local node="$3"
            local node_flag="$4"
            local node_flag_state="$5"

            case "${node_flag}=${node_flag_state}" in
                urgent=on)
                    set_node_variables "${node}" # exports node_hash
                    set_notification_variables "${node_hash}"

                    # if current/focused desktop has urgent node then don't show notification
                    if [[ "${node_desktop}" != "$(bspc query -D -n focused || :)" ]]; then
                        {
                            got_id=false

                            notify-send \
                                --app-name="${node_class}" \
                                --icon="${node_class}" \
                                --action="Focus" \
                                --wait \
                                --print-id \
                                ${notification_id:+--replace-id="${notification_id}"} \
                                "${node_class}" \
                                "is marked urgent" \
                                | while IFS= read -r line; do
                                    if [[ "${got_id}" = 'false' ]]; then
                                        got_id=true
                                        printf '%s' "${line}" >"${notification_file}"
                                        continue
                                    fi

                                    bspc node -f "${node}"
                                    rm -f "${notification_file}"
                                    break
                                done
                        } &
                    fi
                    ;;
                urgent=off)
                    set_node_variables "${node}"
                    set_notification_variables "${node_hash}"

                    if [[ -e "${notification_file}" ]]; then
                        # dunstify -C "${notification_id}"
                        notify-send --replace-id="${notification_id}" -t 1 close

                        rm -f "${notification_file}"
                    fi
                    ;;
            esac
            ;;
    esac
}

: "${NOTIFY_SOCKET:=}"

runtime="${XDG_RUNTIME_DIR:=/run/user/$(id -u)}/bspwm-urgent"
mkdir -p "${runtime}"

notify --status="Waiting for bspwm..."
until bspc wm -g >/dev/null 2>&1; do
    sleep 1
done

notify --status="Subscribing to bspwm node_flag events..."
bspc subscribe node_flag \
    | {
        notify --ready
        while IFS=" " read -r line; do
            set -- "${line}"
            process "$@"
        done
    }
