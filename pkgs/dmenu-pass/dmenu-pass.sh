# shellcheck shell=bash

: "${PASSWORD_STORE_DIR:=${HOME}/.password-store}"
: "${PASSWORD_STORE_CLIP_TIME:=45}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"

: "${DMENU_PASS_HISTORY:=${XDG_CACHE_HOME}/dmenu/dmenu-pass.cache}"

usage() {
    cat >&2 <<EOF
usage: dmenu-pass [-cn] [-i query] [-m print|username|password|otp] [-- dmenu options]
EOF
    exit 69
}

clip=false
notify=false
initial=
mode=password

while getopts :cni:m: arg >/dev/null 2>&1; do
    case "${arg}" in
        c) clip=true ;;
        n) notify=true ;;
        i) initial="${OPTARG}" ;;
        m)
            case "${OPTARG}" in
                print) mode= ;;
                username | password | otp) mode="${OPTARG}" ;;
                *) usage ;;
            esac
            ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

mkdir -p "${DMENU_PASS_HISTORY%/*}"

choice=$(
    (   
        cd "${PASSWORD_STORE_DIR}" || exit
        find .// \
            -type f \
            ! -path '*/.*/*' \
            ! -name '.*' \
            -name '*.gpg' \
            -printf '%d %p\n' 2>/dev/null \
            | sort -n \
            | sed 's@^[0-9]* @@; s@^\.//@@; s@\.gpg$@@' \
            | cat "${DMENU_PASS_HISTORY}" - 2>/dev/null
    )   | uq \
        | ${DMENU:-dmenu} ${initial:+-n -it "${initial}"} -S -p "pass${mode:+ [${mode}]}" "$@"
)

[[ -n "${choice}" ]] || exit 0

touch "${DMENU_PASS_HISTORY}"

case "${mode}" in
    username)
        username=$(pass meta "${choice}" username)

        if "${clip}"; then
            xclip -in -selection clipboard -rmlastnl <<<"${username}"
        else
            printf '%s\n' "${username}"
        fi
        ;;
    password)
        if "${clip}"; then
            pass show -c "${choice}"
            if "${notify}"; then
                notify-send \
                    -a pass \
                    -i password \
                    "pass" \
                    "Copied ${choice} to clipboard. Will clear in ${PASSWORD_STORE_CLIP_TIME} seconds."
            fi
        else
            pass show "${choice}" | head -n1
        fi
        ;;
    otp)
        if "${clip}"; then
            pass otp -c "${choice}"
            if "${notify}"; then
                notify-send \
                    -a pass \
                    -i password \
                    "pass" \
                    "Copied OTP code for ${choice} to clipboard. Will clear in ${PASSWORD_STORE_CLIP_TIME} seconds."
            fi
        else
            pass otp "${choice}"
        fi
        ;;
    '') printf '%s\n' "${choice}" ;;
esac

cat - "${DMENU_PASS_HISTORY}" <<<"${choice}" \
    | head -n 24 \
    | grep -v "^\s*$" \
    | uq \
    | while read -r entry; do
        test -e "${PASSWORD_STORE_DIR}"/"${entry}".gpg && printf '%s\n' "${entry}"
    done \
    | ifne sponge "${DMENU_PASS_HISTORY}"
