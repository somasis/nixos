{ config
, pkgs
, lib
, ...
}:
let
  colorPick = pkgs.writeShellScript "color-pick" ''
    c=$(${pkgs.xcolor}/bin/xcolor "$@")

    printf '%s' "$c" | ${pkgs.xclip}/bin/xclip -in -selection clipboard
    ${pkgs.libnotify}/bin/notify-send \
        -a xcolor \
        -i gnome-color-chooser \
        "xcolor" \
        "Copied '$c' to clipboard."
  '';
in
{
  # XXX Don't use systemctl --user reload here; sxhkd is loaded on the fly in xsession for some reason
  home.activation."sxhkd" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    ${pkgs.procps}/bin/pgrep -u "$USER" sxhkd >/dev/null 2>&1 \
        && $DRY_RUN_CMD ${pkgs.procps}/bin/pkill -USR1 sxhkd \
        || :
  '';

  home.packages = [
    pkgs.screenshot
    pkgs.xinput-notify
    pkgs.xrandr-invert-colors
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
        "super + shift + o" = pkgs.writeShellScript "sxhkd-dragon" ''
          export PATH=${lib.makeBinPath [ config.xsession.windowManager.bspwm.package pkgs.coreutils pkgs.procps pkgs.xdragon pkgs.xdotool pkgs.xe pkgs.gnome.zenity ]}:"$PATH"
          window_pid=$(xdotool getactivewindow getwindowpid)
          window_pid_parent=$(pgrep -P "$window_pid" | tail -n1)
          window_cwd=$(readlink -f /proc/"$window_pid_parent"/cwd)
          cd "$window_cwd"

          title='Select a file (select none to create target)'

          bspc rule -a 'Zenity:*:'"$title" -o sticky=on
          f=$(zenity --title "$title" --file-selection --multiple --separator "$(printf '\n')") || exit 1

          bspc rule -a 'dragon' -o sticky=on
          if [ -n "$f" ]; then
              dragon -s 64 -T -A -x -I <<<"$f"
          else
              dragon -s 64 -T -A -x -t -k
          fi
        '';

        # Utility: color picker - super + g
        "super + g" = "${colorPick} -f hex";
        "super + alt + g" = "${colorPick} -f rgb";

        "super + i" = pkgs.writeShellScript "xrandr-invert-colors" ''
          : "''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}"

          if [ -e "$XDG_RUNTIME_DIR/xrandr-invert-colors.lock" ]; then
              xrandr-invert-colors
              [ "$(<$XDG_RUNTIME_DIR/xrandr-invert-colors.lock)" = "active" ] \
                   && ${pkgs.systemd}/bin/systemctl --user start sctd.service
              exec rm -f "$XDG_RUNTIME_DIR/xrandr-invert-colors.lock"
          else
              ${pkgs.systemd}/bin/systemctl --user is-active sctd.service \
                  > "$XDG_RUNTIME_DIR/xrandr-invert-colors.lock"
              ${pkgs.systemd}/bin/systemctl --user stop sctd.service
              exec xrandr-invert-colors
          fi
        '';

        # Take screenshot of window/selection
        "Print" = "SCREENSHOT_MAIM=-u screenshot -b 6 -p -6 -l -c .6,.4,.98,.5 -r hippie";

        # Take screenshot of window/selection (and scan its text)
        "shift + Print" = "SCREENSHOT_MAIM=-u SCREENSHOT_OCR=true screenshot -b 6 -p -6 -l -c .6,.4,.98,.5 -r hippie";

        # Take screenshot of current monitor
        "super + Print" = "SCREENSHOT_GEOMETRY=$(${getMonitorDimensions}) screenshot";

        # Take screenshot of all monitors
        "alt + Print" = "SCREENSHOT_GEOMETRY=desktop screenshot";

        # Hardware: toggle touchpad
        "super + F2" = "xinput-notify touchpad";
      };
  };

  xdg.configFile = {
    "slop/hippie.vert".source = "${pkgs.slop.src}/shaderexamples/hippie.vert";
    "slop/hippie.frag".source = "${pkgs.slop.src}/shaderexamples/hippie.frag";
  };
}
