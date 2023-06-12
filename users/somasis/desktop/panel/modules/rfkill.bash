# shellcheck shell=bash disable=SC3000-SC3999
set -euo pipefail

monitor() {
    rfkill event
}

get() {
    if rfkill -n --output soft,hard | grep -q -e '^blocked ' -e ' blocked$'; then
        o="✈️"
    else
        o=
    fi

    printf '%s\n' "${o}"
}

get
monitor | while read -r _; do get; done
