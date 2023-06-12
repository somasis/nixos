# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

: "${PANEL_COLOR_BACKGROUND:?}"
: "${PANEL_COLOR_BLACK:?}"

color=$(
    pastel mix -f .25 "${PANEL_COLOR_BLACK}" "${PANEL_COLOR_BACKGROUND}" \
        | pastel format hex
)

get() {
    all_day=$(
        khal list \
            --day-format '' \
            --format $'{start-style}: {title}\n' \
            now \
            eod \
            "$@" \
            2>/dev/null \
            | sed -E \
                -e 's/^(↦|→): //' \
                -e 's/ \(.*\)$//' \
            | cut -d: -f1,2,3
    )

    timed=$(
        khal list \
            --day-format '' \
            --format $'{start-style}: {title}\n' \
            now \
            eod \
            "$@" \
            2>/dev/null \
            | sed -E \
                -e '/^(↦|→): /d' \
                -e 's/ \(.*\)$//' \
            | cut -d: -f1,2,3
    )

    if [[ "${timed}" = "No events" ]] || [[ "${all_day}" = "No events" ]]; then
        event_num=0
        event=
    elif [[ -n "${all_day}" ]] && [[ -n "${timed}" ]]; then
        event_num=$(wc -l <<<$"${all_day}\n${timed}")
        event_num=$((event_num - 1))
        event=$(head -n1 <<<"${timed}")
    else
        event_num=$(wc -l <<<"${timed}")
        event_num=$((event_num - 1))
        event=$(grep -v '^$' <<<$"${all_day}\n${timed}" | head -n1)
    fi

    [[ "${event_num}" -lt 1 ]] && event_num=
    { [[ -n "${event}" ]] && event=$(ellipsis 40 <<<"${event}"); } || return

    o="%{B${color}}%{O12}${event}${event_num:+ (+${event_num})}%{O12}%{B-}"
    o="%{A1:jumpapp -t khal -c khal -f kitty --class khal -T khal khal interactive:}${o}%{A}"
    printf '%s\n' "${o}"
}

while [[ "$#" -gt 0 ]]; do
    case "${1}" in
        --exclude=*)
            mapfile -t calendars < <(khal printcalendars | grep -Ev -- "${1#--exclude=}")
            ;;
    esac
    shift
done

khal_args=()
for c in "${calendars[@]}"; do
    khal_args+=(-a "${c}")
done

get "${khal_args[@]}" "$@"
snooze -H* -M*
while [[ $? -eq 0 ]]; do
    get "${khal_args[@]}" "$@"
    snooze -H* -M*
done
