# shellcheck shell=sh

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
            -a xinput \
            -i "${icon}" \
            -e \
            "xinput" \
            "${class} '${name%" ${class}"}' enabled."
}

mode_disable() {
    xinput disable "$1" \
        && notify-send \
            -a xinput \
            -i "${icon}" \
            -e \
            "xinput" \
            "${class} '${name%" ${class}"}' disabled."
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

[ $# -gt 0 ] || usage

case "$1" in
    touchpad | pen | tablet | finger | keyboard | mouse | pointer)
        # shellcheck disable=SC2046
        eval "set -- $(printf '%s ' $(xinput list --name-only | grep -iF "$1" | xe s6-quote))"
        ;;
esac

while [ $# -gt 0 ]; do
    name="$1"

    [ "$(xinput list --name-only | grep -Fc "${name}")" -eq 0 ] \
        && printf 'error: no device named "%s"\n' "${name}" >&2 \
        && exit 2

    case "$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')" in
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
            if [ "$(xinput list-props "$1" | sed '/Device Enabled/!d; s/.*:[\t ]*//')" -eq 1 ]; then
                mode_disable "$1"
            else
                mode_enable "$1"
            fi
            ;;
        enable | disable) mode_"${mode}" "$1" ;;
    esac
    shift
done
