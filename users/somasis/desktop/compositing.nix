{ lib
, pkgs
, ...
}: {
  home.activation."picom" = lib.hm.dag.entryAfter [ "writeBoundary" ] ''
    if ${pkgs.procps}/bin/pgrep -u "$USER" picom >/dev/null 2>&1; then
        $DRY_RUN_CMD ${pkgs.procps}/bin/pkill -USR1 picom
    fi
  '';

  services.picom = {
    enable = true;

    backend = "xrender";
    vSync = true;

    shadow = false;
    shadowOffsets = [ (-16) (-16) ];
    shadowOpacity = 1;

    shadowExclude = [
      "bounding_shaped"
      "argb"
      "focused"
      "n:e:stw"

      # Kvantum
      "(_NET_WM_WINDOW_TYPE@:a *= 'MENU' || _NET_WM_WINDOW_TYPE@:a *= 'COMBO')"
    ];

    settings = {
      shadow-radius = 16;

      detect-client-leader = false;
      detect-client-opacity = true;
      detect-rounded-corners = true;
      mark-ovredir-focused = true;
      mark-wmwin-focused = true;
      use-ewmh-active-win = false;
      xrender-sync-fence = true;

      xinerama-shadow-crop = true;

      detect-transient = true;
      unredir-if-possible = true;
      no-ewmh-fullscreen = true;

      wintypes = {
        notification = { redir-ignore = true; };
        dock = { clip-shadow-above = false; };
      };

      # Kvantum
      blur-background-exclude = [
        "(_NET_WM_WINDOW_TYPE@:a *= 'MENU' || _NET_WM_WINDOW_TYPE@:a *= 'COMBO')"
      ];

      # allow for inverting individual windows
      # <https://www.reddit.com/r/i3wm/comments/kbw3a5/shortcut_for_inverting_a_windows_colors/>
      invert-color-include = [ "KYLIE_INVERT@:8c = 1" ];
    };
  };

  services.sxhkd.keybindings."super + shift + i" = builtins.toString (pkgs.writeShellScript "toggle-invert" ''
    xprop -id "$(xdotool getwindowfocus)" -format KYLIE_INVERT 8c \
        -set KYLIE_INVERT "$(
            xprop -id "$(xdotool getwindowfocus)" 8c KYLIE_INVERT \
                | sed \
                    -e 's/.*= 1.*/0/' \
                    -e 's/.*= 0.*/1/' \
                    -e 's/.*not found.*/1/'
        )"
  '');

  programs.autorandr.hooks.postswitch.picom = ''
    ${pkgs.systemd}/bin/systemctl --user try-restart picom.service
  '';

  systemd.user.services.xsecurelock.Service.ExecStartPre = [
    "-${pkgs.systemd}/bin/systemctl --user stop picom.service"
  ];

  systemd.user.services.xsecurelock.Service.ExecStopPost = [
    "-${pkgs.systemd}/bin/systemctl --user start picom.service"
  ];
}
