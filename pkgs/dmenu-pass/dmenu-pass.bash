# shellcheck shell=bash

: "${PASSWORD_STORE_DIR:=${HOME}/.password-store}"
: "${PASSWORD_STORE_CLIP_TIME:=45}"
: "${XDG_CACHE_HOME:=${HOME}/.cache}"

: "${DMENU_PASS_HISTORY:=${XDG_CACHE_HOME}/dmenu/dmenu-pass.cache}"

me=${0##*/}

usage() {
    cat >&2 <<EOF
usage: ${me} [-cn] [-i query] -m print|username|password|otp [-- dmenu options]
       ${me} [-cn] [-i query] -m FIELD [-- dmenu options]
EOF
    exit 69
}

pass() {
    if [[ "${notify}" == true ]]; then
        stdbuf -o0 -e0 \
            "$(command -v pass)" "$@" \
            2> >(while IFS= read -r stderr; do notify-send -a "pass" -i "password-manager" pass "${stderr}"; done) \
            | tee \
                >(while IFS= read -r stdout; do notify-send -a "pass" -i "password-manager" -e pass "${stdout}"; done)
    else
        command pass "$@"
    fi
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
        m) mode="${OPTARG}" ;;
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
    password)
        if "${clip}"; then
            pass show -c "${choice}"
        else
            pass show "${choice}" | head -n1
        fi
        ;;
    otp)
        if "${clip}"; then
            pass otp -c "${choice}"
        else
            pass otp "${choice}"
        fi
        ;;
    print | '') printf '%s\n' "${choice}" ;;
    *)
        field=$(pass meta "${choice}" "${mode}")

        if "${clip}"; then
            xclip -in -selection clipboard -rmlastnl <<<"${field}"
        else
            printf '%s\n' "${field}"
        fi
        ;;
esac

cat - "${DMENU_PASS_HISTORY}" <<<"${choice}" \
    | head -n 24 \
    | grep -v "^\s*$" \
    | uq \
    | while read -r entry; do
        test -e "${PASSWORD_STORE_DIR}"/"${entry}".gpg && printf '%s\n' "${entry}"
    done \
    | ifne sponge "${DMENU_PASS_HISTORY}"
