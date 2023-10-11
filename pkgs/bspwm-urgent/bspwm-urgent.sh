# shellcheck shell=sh

set_window_variables() {
    : "${id:?set_window_variables(): no \$id provided}"

    class=$(xdotool getwindowclassname "${id}")

    hash=$(printf '%s%s' "${id}" "${class}" | sha256sum)
    hash=${hash%% *}
}

set_notification_variables() {
    : "${hash:?set_notification_variables(): no \$hash provided}"

    notification_id=
    notification_file="${runtime}/${hash}.notification"
    if [ -e "${notification_file}" ]; then
        notification_id=$(cat "${notification_file}")
    fi
}

notify() {
    if [ -n "${NOTIFY_SOCKET}" ]; then
        systemd-notify "$@"
    fi
}

process() {
    while IFS=' ' read -r _ _ _ id flag state; do
        case "${flag}=${state}" in
            urgent=on)
                set_window_variables
                set_notification_variables

                {
                    got_id=false

                    notify-send \
                        --app-name="${class}" \
                        --icon="${class}" \
                        --action="Focus" \
                        --wait \
                        --print-id \
                        ${notification_id:+--replace-id="${notification_id}"} \
                        "${class}" \
                        "is marked urgent" \
                        | while IFS= read -r line; do
                            if [ "${got_id}" = 'false' ]; then
                                got_id=true
                                printf '%s' "${line}" >"${notification_file}"
                                continue
                            fi

                            bspc node -f "${id}"
                            rm -f "${notification_file}"
                            break
                        done
                } &
                ;;
            urgent=off)
                set_window_variables
                set_notification_variables

                if [ -e "${notification_file}" ]; then
                    # dunstify -C "${notification_id}"
                    notify-send --replace-id="${notification_id}" -t 1 close

                    rm -f "${notification_file}"
                fi
                ;;
        esac
    done
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
        process
    }
