# shellcheck shell=bash
exit 0
: "${I_WANT_TO_FAIL_ALL_MY_CLASSES:=}"

usage() {
    cat >&2 <<EOF
usage: [I_WANT_TO_FAIL_ALL_MY_CLASSES=...] playtime [-iqw]
EOF
    exit 69
}

consider_any_work_during_day=false
invert=false
quiet=false
while getopts :iqw arg >/dev/null 2>&1; do
    case "${arg}" in
        i) invert=true ;;
        q) quiet=true ;;
        w) consider_any_work_during_day=true ;;
        *) usage ;;
    esac
done
shift $((OPTIND - 1))

work_remains() {
    # find if any class events ("XXX-0000: ...") remain
    cut <<<"${work_events}" -f3- \
        | cut -d: -f1 \
        | grep -qE '^[A-Z]+-'
}

if [[ "${invert}" == 'true' ]]; then
    is_playtime=1
    is_worktime=0
else
    is_playtime=0
    is_worktime=1
fi

today=$(date +'%Y-%m-%d')
time=$(date +'%I:%M %p')

work_events=$(
    khal list \
        --day-format "" \
        --format '{start-time}{tab}{end-time}{tab}{title}' \
        -a University \
        today \
        eod
)

if [[ "${consider_any_work_during_day}" == true ]]; then
    # if there's any work at all during the day,
    # then the whole day is a work day.
    working_start="${today} 07:00 AM"
    working_end="eod"
else
    # if it's just a regular work day, then the end of the work
    # day will be the last work event.
    working_start=$(head -n1 <<<"${work_events}"  | cut -f1)
    working_start="${today} ${working_start}"
    working_end="${today} 07:00 PM"

    if datetest -i '%Y-%m-%d %I:%M %p' "${today} ${time}" --ot "${working_start}" || datetest -i '%Y-%m-%d %I:%M %p' "${today} ${time}" --ot "${working_end}"; then
        exit "${is_playtime}"
    fi
fi

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

        exit "${is_playtime}"
    fi

    work_end_time=$(
        tail <<<"${work_events}" -n1 | cut -f2
    )

    [[ "${quiet}" == true ]] \
        && printf \
            'you should be working right now; play time begins at %s\n' \
            "${work_end_time}"
    exit "${is_worktime}"
else
    exit "${is_playtime}"
fi
