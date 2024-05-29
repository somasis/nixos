# shellcheck shell=bash

: "${XDG_CACHE_HOME:=${HOME}/.cache}"
: "${DMENU:=dmenu}"
: "${DMENU_EMOJI_LIST:?}"
: "${DMENU_EMOJI_HISTORY:=${XDG_CACHE_HOME}/dmenu-emoji/history}"

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

dmenu_args=()
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

dmenu_args=("$@")

mkdir -p "${DMENU_EMOJI_HISTORY%/*}"

if "${list}"; then
    list
    exit
fi

dmenu_args=(-p "emoji")

list \
    | eval "${DMENU} ${dmenu_args[*]@Q}" \
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
