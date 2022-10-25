{ config
, pkgs
, lib
, ...
}:
let
  xinput-notify = (pkgs.writeShellApplication {
    name = "xinput-notify";
    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.libnotify
      pkgs.xe
      pkgs.xorg.xinput
    ];

    text = ''
      usage() {
          cat >&2 <<EOF
      usage: ''${0##*/} [-de] DEVICE...
             ''${0##*/} [-de] CLASS
      EOF
          exit 69
      }

      xinput() {
          LC_ALL=C command xinput "$@"
      }

      mode_enable() {
          xinput enable "$1" \
              && notify-send \
                  -a xinput \
                  -i "$icon" \
                  -u low \
                  "xinput" \
                  "$class '""''${name% "$class"}""' enabled."
      }

      mode_disable() {
          xinput disable "$1" \
              && notify-send \
                  -a xinput \
                  -i "$icon" \
                  -u low \
                  "xinput" \
                  "$class '""''${name% "$class"}""' disabled."
      }

      mode=toggle

      while getopts :de arg >/dev/null 2>&1; do
          case "$arg" in
              d) mode=disable ;;
              e) mode=enable ;;
              *) usage ;;
          esac
      done
      shift $((OPTIND - 1))

      [ $# -gt 0 ] || usage

      case "$1" in
          touchpad | pen | tablet | finger | keyboard | mouse | pointer)
              # shellcheck disable=SC2046
              eval "set -- $(printf '%s ' $(xinput list --name-only | grep -iF "$1" | xe s6-quote))"
              ;;
      esac

      while [ $# -gt 0 ]; do
          name="$1"

          [ "$(xinput list --name-only | grep -Fc "$name")" -eq 0 ] \
              && printf 'error: no device named "%s"\n' "$name" >&2 \
              && exit 2

          case "$(printf '%s\n' "$1" | tr '[:upper:]' '[:lower:]')" in
              *touchpad*)
                  icon=input-touchpad
                  class=Touchpad
                  ;;
              *pen*)
                  icon=input-tablet
                  class=Tablet
                  ;;
              *tablet*)
                  icon=input-tablet
                  class=Tablet
                  ;;
              *finger*)
                  icon=tablet
                  class=tablet
                  ;;
              *keyboard*)
                  icon=input-keyboard
                  class=Keyboard
                  ;;
              *mouse*)
                  icon=input-mouse
                  class=Mouse
                  ;;
              *pointer*)
                  icon=preferences-desktop-cursors
                  class=Mouse
                  ;;
          esac

          case "$mode" in
              toggle)
                  if [ "$(xinput list-props "$1" | sed '/Device Enabled/!d; s/.*:[\t ]*//')" -eq 1 ]; then
                      mode_disable "$1"
                  else
                      mode_enable "$1"
                  fi
                  ;;
              enable | disable) mode_"$mode" "$1" ;;
          esac
          shift
      done
    '';
  });
in
{
  # XXX Don't use systemctl --user reload here; sxhkd is loaded on the fly in xsession for some reason
  home.activation."sxhkd" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.procps}/bin/pgrep -u "$USER" sxhkd >/dev/null 2>&1 \
        && $DRY_RUN_CMD ${pkgs.procps}/bin/pkill -USR1 sxhkd \
        || :
  '';

  home.packages = [
    xinput-notify
  ];

  services.sxhkd = {
    enable = true;
    keybindings =
      let
        screenshots = "${config.home.homeDirectory}/mess/current/screenshots";
        screenshot = pkgs.writeShellScript "screenshot" ''
          set -eu
          set -o pipefail

          mkdir -p "${screenshots}"

          export TMPDIR=$(mktemp -d "${screenshots}"/.tmp.XXXXXX)
          d=$(TZ=UTC date +"%Y-%m-%dT%H:%M:%S.png")

          ${pkgs.maim}/bin/maim "$@" \
              | ${pkgs.moreutils}/bin/sponge "${screenshots}/$d"

          ${pkgs.xclip}/bin/xclip \
              -i \
              -selection clipboard \
              -t image/png \
              < "${screenshots}/$d"

          rm -r "$TMPDIR"
        '';
        getMonitorDimensions = pkgs.writeShellScript "get-monitor-dimensions" ''
          # TODO: This is an absolutely disgusting solution. I hate this. Isn't there a better way?
          #       Better yet, why doesn't maim(1) just handle displays in a way that makes sense???

          m=$(
              ${config.xsession.windowManager.bspwm.package}/bin/bspc \
                  query \
                      -M \
                      -m "''${1:-focused}" \
                      --names
          )

          eval $(
              ${pkgs.xdotool}/bin/xdotool \
                  search \
                      --screen "$m" \
                      --name "^$m$" \
                  getwindowgeometry \
                      --shell
          )
          printf '%sx%s+%s+%s\n' "$WIDTH" "$HEIGHT" "$X" "$Y"
        '';

        colorPick = pkgs.writeShellScript "color-pick" ''
          c=$(${pkgs.xcolor}/bin/xcolor "$@")

          printf '%s' "$c" | ${pkgs.xclip}/bin/xclip -in -selection clipboard
          ${pkgs.libnotify}/bin/notify-send \
              -a xcolor \
              -i color-picker \
              "xcolor" \
              "Copied '$c' to clipboard."
        '';
      in
      {
        # Utility: drag files -> open in launcher - super + o
        "super + shift + o" = ''
          ${pkgs.xdragon}/bin/dragon -s 32 -t -p -x \
              | ${pkgs.xe}/bin/xe -N1 xdg-open
        '';

        # Utility: color picker - super + g
        "super + g" = "${colorPick} -f hex";
        "super + alt + g" = "${colorPick} -f rgb";

        "super + i " = "${pkgs.xrandr-invert-colors}/bin/xrandr-invert-colors";

        # Music: {play/pause, stop, previous track, next track}
        # "XF86Audio{Play,Stop,Prev,Next}" = "{${bin}/mpc-toggle,${pkgs.mpc-cli}/bin/mpc stop,${pkgs.mpc-cli}/bin/mpc cdprev,${pkgs.mpc-cli}/bin/mpc next}";

        # Music: toggle {consume, random} mode
        # "super + XF86Audio{Prev,Play}" = "${pkgs.mpc-cli}/bin/mpc {consume,random}";

        # "ctrl + alt + {0,1,2,3,4,5}" = "${bin}/mpc-star {0,1,2,3,4,5}";

        # Take screenshot of window/selection
        "Print" = "${screenshot} -us -b 6 -p -6 -l -c 0.7686,0.9137,0.4705,.5";

        # Take screenshot of current monitor
        "super + Print" = "${screenshot} -g \"$(${getMonitorDimensions})\"";

        # Take screenshot of all monitors
        "alt + Print" = "${screenshot}";

        # Hardware: {mute, lower, raise} output volume - fn + {f1,f2,f3}
        "XF86AudioMute" = "ponymix -t sink toggle";
        "super + XF86AudioMute" = "ponymix -t source toggle";
        "XF86AudioRaiseVolume" = "ponymix-snap -t sink increase 5";
        "XF86AudioLowerVolume" = "ponymix-snap -t sink decrease 5";
        "super + XF86AudioRaiseVolume" = "ponymix-snap -t source increase 5";
        "super + XF86AudioLowerVolume" = "ponymix-snap -t source decrease 5";

        # Hardware: toggle touchpad - super + f1
        "super + F2" = ''
          ${xinput-notify}/bin/xinput-notify touchpad
        '';
      };
  };
}
