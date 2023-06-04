# shellcheck shell=bash

: "${DMENU_EMOJI_LIST:?}"
: "${DMENU_EMOJI_HISTORY:=${XDG_CACHE_HOME:=~/.cache}/dmenu/dmenu-emoji.cache}"

usage() {
    cat >&2 <<EOF
usage: dmenu-emoji [-clt] [-- dmenu options]
EOF
    exit 69
}

list() {
    {
        cat "${DMENU_EMOJI_HISTORY}" 2>/dev/null
        sed -E \
            -e '/; fully-qualified/!d' \
            -e 's/.* # //' \
            -e 's/E[0-9]+\.[0-9]+ //' \
            -e 's/&/\&amp;/' \
            "${DMENU_EMOJI_LIST}" \
            | sort
    } | uq
}

clip=false
list=false
type=false

while getopts :clt arg >/dev/null 2>&1; do
    case "${arg}" in
        c) clip=true ;;
        l) list=true ;;
        t) type=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

mkdir -p "${DMENU_EMOJI_HISTORY%/*}"

if "${list}"; then
    list
    exit
fi

list \
    | ${DMENU:-dmenu -fn "sans 20px" -l 8 -g 8} -S -i -p "emoji" "$@" \
    | while read -r emoji line; do
        "${clip}" \
            && xclip -i -selection clipboard -rmlastnl <<<"${emoji}" \
            && xclip -o -selection clipboard

        "${type}" \
            && xdotool key "$(printf '%s ' "${emoji}")"

        {
            "${clip}" || "${type}"
        } || printf '%s\n' "${emoji}"

        printf '%s %s\n' "${emoji}" "${line}" >>"${DMENU_EMOJI_HISTORY}"
    done

head -n 64 "${DMENU_EMOJI_HISTORY}" \
    | grep -v '^$' \
    | uq \
    | ifne sponge "${DMENU_EMOJI_HISTORY}"
