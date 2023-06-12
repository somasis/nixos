# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail
set -m

colors=true

# this is insane. I hate `upower -m` so much
fifo=$(mktemp -u)
mkfifo "${fifo}"
trap 'rm -f "$fifo"; kill %%' EXIT
stdbuf -i0 -o0 -e0 upower -m >"${fifo}" &

usage() {
    cat >&2 <<EOF
usage: ${0##*/} [DEVICE]

DEVICE is either the DBus path to a UPower device
(/org/freedesktop/UPower/devices/*), the MAC address of a device known by the
Bluetooth daemon, or the "model" (name) of a device known by the Bluetooth
daemon. If no device is given as an argument, UPower's DisplayDevice is used.
EOF
    exit 69
}

up() {
    upower -d | jc --upower | jq -r "$@"
}

up_device() {
    local device
    device="$1"
    shift
    upower -i "${device}" | jc --upower | jq -r "$@"
}

# 1. when upower has activity,
wait_for_upower() {
    head -n 1 "${fifo}" >/dev/null
    return 0
}

flush_upower() {
    timeout 1 cat "${fifo}" >/dev/null || :
    return 0
}

# 2. fetch the current status
#     a. fill in missing values with defaults prescribed by UPower's documentation
#     b. put it into TSV format
get() {
    local device jq
    device="$1"

    jq='
        map(
            select((.type // "Device") == "Device")
                | (.detail.capacity // .detail.percentage // null) as $percentage
                | (
                    # Battery level calculation
                    (.detail.battery_level
                        | (
                            # Determine if the battery level is unset.
                            if
                                .detail.battery_level? == 0
                                or .detail.battery_level? == 1
                                or .detail.battery_level? == null
                                then
                                    # If unset, calculate a coarse level from the percentage.
                                    if
                                        $percentage >= 95 then 8
                                        elif $percentage > 75 then 7
                                        elif $percentage > 25 then 6
                                        elif $percentage > 15 then 4
                                        elif $percentage < 15 then 3
                                        else null
                                    end
                            else
                                # Otherwise, just use the one that is set
                                .
                            end
                        )
                    ) | (
                        # Parse the battery_level.
                        # <https://upower.freedesktop.org/docs/Device.html#Device:BatteryLevel>
                        if
                            . == 8 then "full"
                            elif . == 7 then "high"
                            elif . == 6 then "normal"
                            elif . == 4 then "critical"
                            elif . == 3 then "low"
                            else null
                        end)
                ) as $level
                | [
                    (.device_name  // "unknown"),
                    .detail.type,
                    .power_supply,
                    (.model // .native_path // "unknown"),
                    (.detail.state // "unknown"),
                    ($percentage // "unknown"),
                    $level,
                    (.detail.present // true)
                ]
                | @tsv
        )[]
    '

    # path, type, power_supply, name, state, percentage, battery_level, present
    up_device "${device}" -f <(printf '%s\n' "${jq}")
}

# 3. create formatted output (with colors, if requested)
process() {
    local path type power_supply name state percentage battery_level present
    local b f u o

    while IFS=$'\t' read -r path type power_supply name state percentage battery_level present; do
        # printf 'process: %s\t%s\t%s\t%s\t%s\t%s\t%s\t%s\n' "${path}" "${type}" "${power_supply}" "${name}" "${state}" "${percentage}" "${battery_level}" "${present}" >&2
        o=
        b=
        f=
        u=

        case "${battery_level}" in
            full | high) o= ;;
            *) o=${percentage} ;;
        esac

        if [[ -n "${colors}" ]]; then
            case "${battery_level}" in
                high) b="${xres_color2}" ;;
                *)
                    b=$(pastel mix "${xres_color2}" -f "0.$((percentage + 10))" "${xres_color9}" | pastel format hex)
                    ;;
            esac
        fi

        if [[ -n "${o}" ]]; then
            o="%{O12}${percentage}%%{O12}"

            if [[ "${state}" == "charging" ]]; then
                [[ -n "${colors}" ]] && u=$(pastel darken .25 "${b}" | pastel format hex)
                o="%{+u}${o}%{-u}"
            else
                u="${b}"
            fi

            if [[ -n "${colors}" ]]; then
                f=$(pastel textcolor "${b}" | pastel format hex)

                [[ -n "${u}" ]] && o="%{U${u}}${o}%{U-}"
                [[ -n "${f}" ]] && o="%{F${f}}${o}%{F-}"
                [[ -n "${b}" ]] && o="%{B${b}}${o}%{B-}"
            fi

            printf '%s\n' "${o}"
        else
            printf '\n'
        fi
    done
}

# trap "trap - TERM EXIT; kill 0" INT TERM QUIT EXIT

while getopts :C arg >/dev/null 2>&1; do
    case "${arg}" in
        C) colors=  ;;
        *) usage    ;;
    esac
done
shift $((OPTIND - 1))

[[ "$#" -le 1 ]] || usage

if ! upower -d >/dev/null 2>&1; then
    exit 127
fi

device="${1:-/org/freedesktop/UPower/devices/DisplayDevice}"

# Parse device referents belonging to Bluetooth devices on the Bluetooth daemon.
jq_resolve='
    map(
        select(.type == "Device"
            and (.native_path // false)
            and (.native_path | test("^/org/bluez/.*"))
        )
        | if (($ARGS.named | has("serial")) or ($ARGS.named | has("model"))) then
            select((.serial == $ARGS.named["serial"])
                or (.model == $ARGS.named["model"])
            )
        else
            .
        end
        | .device_name
    )[0]
'

case "${device}" in
    /org/freedesktop/UPower/devices/*)
        found=

        for d in $(upower -e); do
            [[ "${device}" = "${d}" ]] && found=true
        done

        if [[ -z "${found}" ]]; then
            printf 'error: device "%s" not found\n' "${device}" >&2
            exit 1
        fi

        unset found
        ;;

    [0123456789abcdefABCDEF][0123456789abcdefABCDEF]:[0123456789abcdefABCDEF][0123456789abcdefABCDEF]:[0123456789abcdefABCDEF][0123456789abcdefABCDEF]:[0123456789abcdefABCDEF][0123456789abcdefABCDEF]:[0123456789abcdefABCDEF][0123456789abcdefABCDEF]:[0123456789abcdefABCDEF][0123456789abcdefABCDEF]:)
        device=$(upower -d | jc --upower | jq -r --arg serial "${device}" "${jq_resolve}")
        ;;
    *)
        device=$(upower -d | jc --upower | jq -r --arg model "${device}" "${jq_resolve}")
        ;;
esac

unset jq_resolve

{
    get "${device}"
    flush_upower >/dev/null
    while wait_for_upower; do get "${device}"; done
} | process
