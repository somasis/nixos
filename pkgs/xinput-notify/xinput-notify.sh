# shellcheck shell=bash

usage() {
    cat >&2 <<EOF
usage: ${0##*/} [-de] DEVICE...
       ${0##*/} [-de] CLASS
EOF
    exit 69
}

xinput() {
    LC_ALL=C command xinput "$@"
}

mode_enable() {
    xinput enable "$1" \
        && notify-send \
            -a xinput-notify \
            -i "${icon}" \
            -e \
            "${class@u}" \
            "Device '${1%" ${class}"}' enabled."
}

mode_disable() {
    xinput disable "$1" \
        && notify-send \
            -a xinput-notify \
            -i "${icon}" \
            -e \
            "${class@u}" \
            "Device '${1%" ${class}"}' disabled."
}

device_names() {
    xinput list --name-only | sed -e 's/^∼ //'
}

mode=toggle

while getopts :de arg >/dev/null 2>&1; do
    case "${arg}" in
        d) mode=disable ;;
        e) mode=enable ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

[[ $# -gt 0 ]] || usage

for device in "$@"; do
    case "${device}" in
        touchpad | pen | tablet | finger | keyboard | mouse | pointer)
            # shellcheck disable=SC2046
            device=$(device_names | grep -Fi "${device}" | head -n1)
            ;;
    esac

    [[ "$(device_names | grep -Fic "${device}")" -eq 0 ]] \
        && printf 'error: no device named "%s"\n' "${device}" >&2 \
        && exit 2

    case "${device,,}" in
        *touchpad*)
            icon=input-touchpad
            class=Touchpad
            ;;
        *pen*)
            icon=input-tablet
            class=Tablet
            ;;
        *tablet*)
            icon=input-tablet
            class=Tablet
            ;;
        *finger*)
            icon=tablet
            class=tablet
            ;;
        *keyboard*)
            icon=input-keyboard
            class=Keyboard
            ;;
        *mouse*)
            icon=input-mouse
            class=Mouse
            ;;
        *pointer*)
            icon=preferences-desktop-cursors
            class=Mouse
            ;;
    esac

    case "${mode}" in
        toggle)
            if [[ "$(xinput list-props "${device}" | sed '/Device Enabled/!d; s/.*:[\t ]*//')" -eq 1 ]]; then
                mode_disable "${device}"
            else
                mode_enable "${device}"
            fi
            ;;
        enable | disable) mode_"${mode}" "${device}" ;;
    esac
done
