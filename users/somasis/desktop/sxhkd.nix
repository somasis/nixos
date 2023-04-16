{ config
, pkgs
, lib
, ...
}:
let
  screenshots = "${config.home.homeDirectory}/mess/current/screenshots";

  colorPick = pkgs.writeShellScript "color-pick" ''
    c=$(${pkgs.xcolor}/bin/xcolor "$@")

    printf '%s' "$c" | ${pkgs.xclip}/bin/xclip -in -selection clipboard
    ${pkgs.libnotify}/bin/notify-send \
        -a xcolor \
        -i gnome-color-chooser \
        "xcolor" \
        "Copied '$c' to clipboard."
  '';

  screenshot = pkgs.writeShellApplication {
    name = "screenshot";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.fq
      pkgs.libnotify
      pkgs.maim
      pkgs.moreutils
      pkgs.slop
      pkgs.tesseract
      pkgs.xclip
      pkgs.xdotool
      pkgs.zbar
    ];

    text = ''
      : "''${SCREENSHOT_DIR:=${screenshots}}"
      : "''${SCREENSHOT_BARCODE:=true}"
      : "''${SCREENSHOT_OCR:=false}"
      : "''${SCREENSHOT_MAIM:=}"

      maim() {
          # shellcheck disable=SC2086
          command maim $SCREENSHOT_MAIM "$@"
      }

      mkdir -p "$SCREENSHOT_DIR"
      b="$SCREENSHOT_DIR/$(TZ=UTC date +"%Y-%m-%dT%H:%M:%SZ")"

      case "''${SCREENSHOT_GEOMETRY:=selection}" in
          selection)
              slop=$(slop "$@" -f '%g %i') || exit 1

              read -r geometry window <<< "$slop"
              window=$(
                  # make sure it's actually a window ID
                  if [ "''${#window}" -eq 7 ]; then
                      xdotool getwindowclassname "$window" 2>/dev/null
                  else
                      xdotool getmouselocation getwindowclassname 2>/dev/null
                  fi
              )

              b="$b''${window:+ $window}"
              maim -g "$geometry" "$b".png
              ;;
          *)
              maim "$b".png
              ;;
      esac

      if [ "$SCREENSHOT_OCR" = true ] \
          && ocr=$(tesseract "$b".png stdout | ifne tee "$b".txt) \
          && [ -n "$ocr" ]; then
          xclip -i \
              -selection clipboard \
              -target UTF8_STRING \
              -rmlastnl \
              "$b".txt \
              >&- 2>&-

          notify-send \
              -a screenshot \
              -i scanner \
              "screenshot" \
              "Scanned ''${#ocr} characters: \"$ocr\""

      # Barcode data is not saved since it may contain sensitive information.
      elif [ "$SCREENSHOT_BARCODE" = true ] \
          && barcode=$(zbarimg -1q --xml -- "$b".png) \
          && [ -n "$barcode" ] \
          && barcode_type=$(fq -d xml -r '.barcodes.source.index.symbol."@type"' <<<"$barcode") \
          && barcode_data=$(fq -d xml -r '.barcodes.source.index.symbol.data' <<<"$barcode"); then

          xclip -i \
              -selection clipboard \
              -target UTF8_STRING \
              -rmlastnl \
              <<<"$barcode_data" \
              >&- 2>&-

          notify-send \
              -a screenshot \
              -i view-barcode-qr \
              "screenshot" \
              "Scanned barcode ($barcode_type): \"$barcode_data\""
      else
          xclip -i \
              -selection clipboard \
              -target UTF8_STRING \
              -rmlastnl \
              <<<"$b.png" \
              >&- 2>&-

          xclip -i \
              -selection clipboard \
              -target image/png \
              "$b".png \
              >&- 2>&-

          notify-send \
              -a screenshot \
              -i accessories-screenshot \
              "screenshot" \
              "Took screenshot: \"$b.png\""
      fi
    '';
  };

  xinput-notify = pkgs.writeShellApplication {
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
  };
in
{
  # XXX Don't use systemctl --user reload here; sxhkd is loaded on the fly in xsession for some reason
  home.activation."sxhkd" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.procps}/bin/pgrep -u "$USER" sxhkd >/dev/null 2>&1 \
        && $DRY_RUN_CMD ${pkgs.procps}/bin/pkill -USR1 sxhkd \
        || :
  '';

  home.packages = [
    pkgs.xrandr-invert-colors

    screenshot
    xinput-notify
  ];

  services.sxhkd = {
    enable = true;
    keybindings =
      let
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
      in
      {
        # Utility: drag files - super + shift + o
        "super + shift + o" = builtins.toString (pkgs.writeShellScript "sxhkd-dragon" ''
          export PATH=${lib.makeBinPath [ config.xsession.windowManager.bspwm.package pkgs.coreutils pkgs.procps pkgs.xdragon pkgs.xdotool pkgs.xe pkgs.gnome.zenity ]}:"$PATH"
          window_pid=$(xdotool getactivewindow getwindowpid)
          window_pid_parent=$(pgrep -P "$window_pid" | tail -n1)
          window_cwd=$(readlink -f /proc/"$window_pid_parent"/cwd)
          cd "$window_cwd"

          title='dragon: select a file (select none to create target)'

          bspc rule -a 'Zenity:*:'"$title" -o sticky=on
          f=$(zenity --title "$title" --file-selection --multiple --separator "$(printf '\n')") || exit 1

          bspc rule -a 'dragon' -o sticky=on
          if [ -n "$f" ]; then
              dragon -s 64 -T -A -x -I <<<"$f"
          else
              dragon -s 64 -T -A -x -t -k
          fi
        '');

        # Utility: color picker - super + g
        "super + g" = "${colorPick} -f hex";
        "super + alt + g" = "${colorPick} -f rgb";

        "super + i" = "xrandr-invert-colors";

        # Take screenshot of window/selection
        "Print" = ''
          SCREENSHOT_MAIM=-u screenshot -b 6 -p -6 -l -c 0.7686,0.9137,0.4705,.5
        '';

        # Take screenshot of window/selection (and scan its text)
        "shift + Print" = ''
          SCREENSHOT_MAIM=-u SCREENSHOT_OCR=true screenshot -b 6 -p -6 -l -c 0.7686,0.9137,0.4705,.5
        '';

        # Take screenshot of current monitor
        "super + Print" = ''
          SCREENSHOT_GEOMETRY=$(${getMonitorDimensions}) screenshot
        '';

        # Take screenshot of all monitors
        "alt + Print" = ''
          SCREENSHOT_GEOMETRY=desktop screenshot
        '';

        # Hardware: {mute, lower, raise} output volume - fn + {f1,f2,f3}
        "XF86AudioMute" = "ponymix -t sink toggle";
        "super + XF86AudioMute" = "ponymix -t source toggle";
        "XF86AudioRaiseVolume" = "ponymix-snap -t sink increase 5";
        "XF86AudioLowerVolume" = "ponymix-snap -t sink decrease 5";
        "super + XF86AudioRaiseVolume" = "ponymix-snap -t source increase 5";
        "super + XF86AudioLowerVolume" = "ponymix-snap -t source decrease 5";

        # Hardware: toggle touchpad - super + f1
        "super + F2" = "xinput-notify touchpad";
      };
  };
}
