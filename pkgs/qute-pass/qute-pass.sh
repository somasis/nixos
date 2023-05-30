# shellcheck shell=bash

set -euo pipefail
set -x

: "${QUTE_FIFO:?}"
: "${QUTE_URL:?}"

exec >>"${QUTE_FIFO}"

# HACK: I wish qutebrowser would just pass this to the scripts...
qute_wid=$(xdotool getwindowfocus)

delimiter=Tab
enter=false
mode=login
while getopts :Eupod: arg >/dev/null 2>&1; do
    case "${arg}" in
        E) enter=true ;;

        u) mode=username ;;
        p) mode=password ;;
        o) mode=otp ;;

        d) delimiter="${OPTARG}" ;;

        *) exit 127 ;;
    esac
done
shift $((OPTIND - 1))

query=$(
    sed \
        -e "s|^[^:]*://||" \
        -e "s|/.*||" \
        <<<"${QUTE_URL}" \
        | rev \
        | cut -d. -f1-2 \
        | rev
)

printf '%s\n' ":mode-enter passthrough"

# TODO: I'm really not a fan of the usage of `sleep` here, but there's
#       not any other good way to do this without better integration
#       via qutebrowser's fake-key commands; which, leak into its log.
case "${mode}" in
    login)
        choice=$(dmenu-pass -m print -i "${query}")

        # Wait a moment for the focus to return...
        sleep 1

        xdotool key --window "${qute_wid}" --clearmodifiers ctrl+a BackSpace

        dmenu-pass -m username -i "${choice}" \
            | xdotool type --window "${qute_wid}" --clearmodifiers --file -

        case "${delimiter}" in
            Tab)
                xdotool key --window "${qute_wid}" --clearmodifiers Tab
                ;;
            *)
                xdotool key --window "${qute_wid}" --clearmodifiers "${delimiter}"
                sleep 2
                ;;
        esac

        dmenu-pass -m password -i "${choice}" \
            | xdotool type --window "${qute_wid}" --clearmodifiers --file -
        ;;
    username | password | otp)
        {
            dmenu-pass -m "${mode}" -i "${query}"
            sleep 1
        } | xdotool type --window "${qute_wid}" --clearmodifiers --file -
        ;;
esac

[[ "${enter}" = "true" ]] && xdotool key --window "${qute_wid}" --clearmodifiers Enter

printf '%s\n' ":mode-enter normal"
