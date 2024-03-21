# shellcheck shell=bash

usage() {
    # shellcheck disable=SC2059
    [[ "$#" -eq 0 ]] || printf "$@" >&2

    cat >&2 <<EOF
usage: ${0##*/} [-w width]
EOF
    exit 69
}

set -euo pipefail

wrap_width=80
while getopts :w: opt; do
    case "${opt}" in
        w)
            wrap_width="${OPTARG}"
            if [[ -z "${wrap_width##*[!0-9]*}" ]]; then
                usage 'error: wrap width must be an integer\n'
            fi
            ;;
        *) usage 'unknown option -- %s\n' "${OPTARG}" ;;
    esac
done
shift $((OPTIND - 1))

fortune=$(
    find -H \
        "${XDG_DATA_HOME:=${HOME}/.local/share}"/sonapona \
        -mindepth 2 \
        -type f \
        ! -executable \
        | shuf -n 1
)

fortune_content=$(sed '$ { /^—/ { d; q } }' "${fortune}")
fortune_attrib=$(sed -n '$ { /^—/ { p; q; } }' "${fortune}")

fortune_content_wrapped=$(fold -w "${wrap_width}" -s <<<"${fortune_content}" | sed 's/ *$//')

if [[ -n "${fortune_attrib}" ]]; then # fortune has an attribution
    fortune_content_max_line_width=$(wc -L <<<"${fortune_content_wrapped}")

    fortune_attrib_raligned=$(printf '%'$((fortune_content_max_line_width + 1))'s\n' "${fortune_attrib}")

    fortune_attrib_raligned_wrapped_prefix=$(sed -E '1 { s/^(\s+).*/\1/; !d }' <<<"${fortune_attrib_raligned}")
    fortune_attrib_raligned_wrapped_prefix_length=$(wc -m <<<"${fortune_attrib_raligned_wrapped_prefix}")

    fortune_attrib_raligned_wrapped=$(
        fmt \
            -w $((fortune_content_max_line_width + 2)) \
            ${fortune_attrib_raligned_wrapped_prefix:+-p "${fortune_attrib_raligned_wrapped_prefix}"} \
            <<<"${fortune_attrib_raligned}"
    )

    tab_width=8
    tab='        '
    if [[ -t 1 ]]; then
        # <https://unix.stackexchange.com/a/582746>
        printf ' \t \033[6n' >&2
        read -rs -d '[' _
        read -rs -dR tab_width
        tab_width=$((${tab_width#*;} - 2))
        printf "\r\e[0K" >&2
        tab=$(
            i=0
            while [[ "${tab_width}" -gt "${i}" ]]; do
                printf ' '
                i=$((i + 1))
            done
        )
    fi

    if [[ "${fortune_content_max_line_width}" -le "${fortune_attrib_raligned_wrapped_prefix_length}" ]]; then
        fortune="${fortune_content_wrapped}"$'\n'"${tab}${fortune_attrib_raligned_wrapped}"
    else
        fortune="${fortune_content_wrapped}"$'\n'" ${fortune_attrib_raligned_wrapped}"
    fi
else
    fortune="${fortune_content_wrapped}"
fi

printf '%s\n' "${fortune}"
