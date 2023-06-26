# shellcheck shell=sh

: "${SCREENSHOT_DIR:=$(xdg-user-dir PICTURES)/Screenshots}"
: "${SCREENSHOT_BARCODE:=true}"
: "${SCREENSHOT_OCR:=false}"
: "${SCREENSHOT_MAIM:=}"

maim() {
    # shellcheck disable=SC2086
    command maim ${SCREENSHOT_MAIM} "$@"
}

mkdir -p "${SCREENSHOT_DIR}"
b="${SCREENSHOT_DIR}/$(TZ=UTC date +"%Y-%m-%dT%H:%M:%SZ")"

case "${SCREENSHOT_GEOMETRY:=selection}" in
    selection)
        slop=$(slop "$@" -f '%g %i') || exit 1

        read -r geometry window <<<"${slop}"

        window=$(
            # make sure it's actually a window ID
            if [ "${#window}" -eq 7 ]; then
                xdotool getwindowclassname "${window}" 2>/dev/null || xdotool getwindowname "${window}" 2>/dev/null
            else
                xdotool getmouselocation getwindowclassname 2>/dev/null || xdotool getwindowname "${window}" 2>/dev/null
            fi
        ) || :

        b="${b}${window:+ ${window}}"
        maim -g "${geometry}" "${b}".png
        ;;
    *)
        maim "${b}".png
        ;;
esac

if [ "${SCREENSHOT_OCR}" = true ] \
    && ocr=$(tesseract "${b}".png stdout | ifne tee "${b}".txt) \
    && [ -n "${ocr}" ]; then
    xclip -i \
        -selection clipboard \
        -target UTF8_STRING \
        -rmlastnl \
        "${b}".txt \
        >&- 2>&-

    notify-send \
        -a screenshot \
        -i scanner \
        "Scanned ${#ocr} characters" \
        "\"${ocr}\""

# Barcode data is not saved since it may contain sensitive information.
elif [ "${SCREENSHOT_BARCODE}" = true ] \
    && barcode=$(zbarimg -1q --xml -- "${b}".png | ifne yq -p xml -o json) \
    && [ -n "${barcode}" ] \
    && eval "$(
        printf '%s' "${barcode}" \
            | jq -r '
                "barcode_type=\(.barcodes.source.index.symbol."+@type" | @sh)",
                "barcode_data=\(.barcodes.source.index.symbol.data | @sh)"
            '
    )"; then

    # shellcheck disable=SC2154
    xclip -i \
        -selection clipboard \
        -target UTF8_STRING \
        -rmlastnl \
        <<<"${barcode_data}" \
        >&- 2>&-

    # shellcheck disable=SC2154
    notify-send \
        -a screenshot \
        -i view-barcode-qr \
        "Scanned barcode (${barcode_type})" \
        "\"${barcode_data}\""
else
    xclip -i \
        -selection clipboard \
        -target UTF8_STRING \
        -rmlastnl \
        <<<"${b}.png" \
        >&- 2>&-

    xclip -i \
        -selection clipboard \
        -target image/png \
        "${b}".png \
        >&- 2>&-

    action=$(
        notify-send \
            -a screenshot \
            -i accessories-screenshot \
            -A "file=Open" \
            -A "directory=Open containing directory" \
            "Took screenshot" \
            "\"${b}.png\""
    )

    case "${action}" in
        file) xdg-open "${b}.png" & ;;
        directory) xdg-open "$(dirname "${b}.png")" & ;;
        *) : ;;
    esac
fi
