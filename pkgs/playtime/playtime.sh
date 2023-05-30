# shellcheck shell=bash

: "${I_WANT_TO_FAIL_ALL_MY_CLASSES:=}"

usage() {
    cat >&2 <<EOF
usage: [I_WANT_TO_FAIL_ALL_MY_CLASSES=...] playtime [-q]
EOF
    exit 69
}

quiet=false
while getopts :q arg >/dev/null 2>&1; do
    case "${arg}" in
        q) quiet=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

work_remains() {
    cut <<<"${work_remaining}" -f2- \
        | cut -d: -f1 \
        | grep -qE '^[A-Z]+-'
}

today=$(date +'%Y-%m-%d')
from=$(date '+%I:%M %p')

if datetest "$(date +'%I:%M %p')" --lt "07:00 AM"; then
    exit 0
fi

work_remaining=$(
    khal list \
        --day-format "" \
        --format '{end-time}{tab}{title}' \
        -a University \
        "${today} ${from}" \
        "$(dateadd "${today}" +1d)"
)

if work_remains; then
    if [[ "${I_WANT_TO_FAIL_ALL_MY_CLASSES}" == 'true' ]]; then
        trap 'echo "that will not work here!" >&2' INT TERM QUIT EXIT

        printf '%s\n' \
            "please don't give up. :(" \
            "sleeping for 60 seconds to make you reconsider" \
            >&2
        sleep 60

        # # listen to focus events
        # # <https://unix.stackexchange.com/a/480138>
        # printf '\e[?1004h' >&2
        # while :; do
        #     e=0
        #     IFS= read -t 60 -n 3 -s -r focus_event || e=$?

        #     if [[ "$e" -eq 128 ]]; then
        #         # timeout reached
        #         break
        #     else
        #         [[ "$focus_event" == '\e[O' ]] \
        #             && printf "restarting sleep--you can't just wait this out in some other window\n" >&2
        #     fi
        # done
        # printf '\e[?1004l' >&2
        trap - INT TERM QUIT EXIT

        exit 0
    fi

    work_end_time=$(
        tail <<<"${work_remaining}" -n1 | cut -f1
    )

    [[ "${quiet}" == true ]] \
        && printf \
            'error: you should be working right now; play time begins at %s\n' \
            "${work_end_time}"
    exit 1
else
    exit 0
fi
