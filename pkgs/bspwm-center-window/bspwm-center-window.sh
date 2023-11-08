# shellcheck shell=bash

# cleaned up slightly from original version at
# <https://www.reddit.com/r/bspwm/comments/k3udby/help_recenter_focused_and_floating_window/ge5geuj/>

set -euo pipefail

calculate_center_with_constraints() {
    printf '%i\n' "$(((($2 - $3) / 2) + $1 - $4))"
}

window_id=$(printf "0x%x" "${1?no window ID given}")

bspc query -N -n "${window_id}.floating" >/dev/null || exit

border_density=$(bspc config border_width)

window_size=$(wattr wh "${window_id^^}")
window_width=${window_size%% *}
window_height=${window_size##* }

monitor_dimensions=$(mattr xywh "${window_id}")
monitor_x=${monitor_dimensions%% *}
monitor_y=${monitor_dimensions#* }
monitor_y=${monitor_y%% *}
monitor_width=${monitor_dimensions#"${monitor_x} ${monitor_y} "}
monitor_width=${monitor_width%% *}
monitor_height=${monitor_dimensions##* }

new_window_x=$(calculate_center_with_constraints "${monitor_x}" "${monitor_width}" "${window_width}" "${border_density}")
new_window_y=$(calculate_center_with_constraints "${monitor_y}" "${monitor_height}" "${window_height}" "${border_density}")

wtp "${new_window_x}" "${new_window_y}" "${window_width}" "${window_height}" "${window_id}"
