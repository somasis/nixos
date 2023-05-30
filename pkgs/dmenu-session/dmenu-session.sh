# shellcheck shell=sh

: "${DMENU_SESSION_ENABLE_LOCKING:=false}"

usage() {
    cat >&2 <<EOF
usage: dmenu-session [dmenu options]
EOF
    exit 69
}

lock_screen_text=
screensaver_text=
monitor_text=

if [ "${DMENU_SESSION_ENABLE_LOCKING}" = 'true' ]; then
    lock_screen_text="Lock screen"
    screensaver_text="Toggle screensaver"
    monitor_text="Toggle monitor power saving"
    lock_screen_choices=$(printf '%s\n' "${lock_screen_text}" "${screensaver_text}" "${monitor_text}")
fi

choice=$(
    ${DMENU:-dmenu -i} -p "session" "$@" <<EOF
Sleep
Reboot
${lock_screen_choices}
Power off
Logout
EOF
)

case "${choice}" in
    "") exit 0 ;;
    "Sleep") systemctl suspend ;;
    "Power off") systemctl poweroff ;;
    "Reboot") systemctl reboot ;;
    "Logout")
        systemctl --user stop graphical-session.target
        bspc quit &
        ;;
    "${lock_screen_text}") systemctl --user start xsecurelock.service & ;;
    "${screensaver_text}") xsecurelock-toggle & ;;
    "${monitor_text}") dpms-toggle & ;;
    *) usage ;;
esac
