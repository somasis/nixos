# shellcheck shell=bash

: "${XDG_PICTURES_DIR:=$(xdg-user-dir PICTURES)}" || :
: "${SCREENSHOT_DIR:=${XDG_PICTURES_DIR:-$HOME/Pictures}/Screenshots}"

: "${SCREENSHOT_FREEZE:=false}"

: "${SCREENSHOT_MAIM:=}"

: "${SCREENSHOT_OCR:=false}"
: "${SCREENSHOT_BARCODE:=true}"

maim() {
    # shellcheck disable=SC2086
    command maim ${SCREENSHOT_MAIM} "$@"
}

clip() {
    xclip -in -selection clipboard "$@" >&- 2>&-
}

tilde() {
    : "${HOME:?\$HOME is unset}"

    local p="${1:?tilde(): no path given}"
    printf '%s' "${p/#${HOME}/\~}"
}

mkdir -p "${SCREENSHOT_DIR}"
b="${SCREENSHOT_DIR}/$(TZ=UTC date +"%Y-%m-%dT%H:%M:%SZ")"

case "${SCREENSHOT_GEOMETRY:=selection}" in
    selection)
        if [[ "${SCREENSHOT_FREEZE}" = true ]]; then
            temp=$(mktemp --suffix .png)
            maim -koqu >"${temp}"
            bspc rule -a Nsxiv:screenshot-preview -o \
                focus=off \
                border=off \
                locked=on \
                sticky=on \
                layer=above \
                state=fullscreen

            xdotool search --classname --sync --limit 1 screenshot-preview &
            xdotool_pid=$!

            nsxiv -N screenshot-preview -bfpq -s f -Z "${temp}" &
            nsxiv_pid=$!

            wait "${xdotool_pid}"

            nsxiv_window_id=$(xdotool search --classname --sync --limit 1 screenshot-preview)
        fi

        slop=$(slop "$@" -f '%g %i') || exit 1
        read -r geometry window_id <<<"${slop}"

        window_name=$(
            # make sure it's actually a window ID
            if [[ "${#window_id}" -eq 7 ]]; then
                xdotool getwindowclassname "${window_id}" 2>/dev/null || xdotool getwindowname "${window_id}" 2>/dev/null
            else
                if [[ "${SCREENSHOT_FREEZE}" = true ]]; then xdotool windowunmap --sync "${nsxiv_window_id}"; fi

                xdotool getmouselocation getwindowclassname 2>/dev/null || xdotool getwindowname "${window_id}" 2>/dev/null

                if [[ "${SCREENSHOT_FREEZE}" = true ]]; then xdotool windowmap "${nsxiv_window_id}"; fi
            fi
        )

        b="${b}${window_name:+ ${window_name}}"
        maim -g "${geometry}" "${b}".png

        if [[ "${SCREENSHOT_FREEZE}" = true ]]; then
            kill "${nsxiv_pid}"
        fi
        ;;
    *)
        maim "${b}".png
        ;;
esac

if [[ "${SCREENSHOT_OCR}" = true ]] \
    && ocr=$(tesseract "${b}".png stdout | ifne tee "${b}".txt) \
    && [[ -n "${ocr}" ]]; then
    clip \
        -target UTF8_STRING \
        -rmlastnl \
        "${b}".txt

    notify-send \
        -a screenshot \
        -i scanner \
        "Scanned ${#ocr} characters" \
        "\"${ocr}\""

# Barcode data is not saved since it may contain sensitive information.
elif [[ "${SCREENSHOT_BARCODE}" = true ]] \
    && barcode=$(zbarimg -1q --xml -- "${b}".png | ifne yq -p xml -o json) \
    && [[ -n "${barcode}" ]] \
    && eval "$(
        jq -r '
            "barcode_type=\(.barcodes.source.index.symbol."+@type" | @sh)",
            "barcode_data=\(.barcodes.source.index.symbol.data | @sh)"
        ' <<<"${barcode}"
    )"; then

    # shellcheck disable=SC2154
    clip \
        -target UTF8_STRING \
        -rmlastnl \
        <<<"${barcode_data}"

    # shellcheck disable=SC2154
    notify-send \
        -a screenshot \
        -i view-barcode-qr \
        "Scanned barcode (${barcode_type})" \
        "\"${barcode_data}\""
else
    clip \
        -target UTF8_STRING \
        -rmlastnl \
        <<<"${b}.png"

    clip \
        -target image/png \
        "${b}".png

    action=$(
        notify-send \
            -a screenshot \
            -i accessories-screenshot \
            -A "file=Open" \
            -A "directory=Open containing directory" \
            "Took screenshot" \
            "$(tilde "${b}".png)"
    )

    case "${action}" in
        file) xdg-open "${b}.png" & ;;
        directory) xdg-open "$(dirname "${b}.png")" & ;;
        *) : ;;
    esac
fi
