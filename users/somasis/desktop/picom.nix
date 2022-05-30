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

    backend = "xr_glx_hybrid";
    vSync = true;

    shadow = false;
    shadowOffsets = [ (-16) (-16) ];
    shadowOpacity = .35;

    shadowExclude = [
      "bounding_shaped"
      "argb"
      "focused"
      "n:e:stw"
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
    };
  };

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
