{ config
, pkgs
, ...
}: {
  systemd.user.services.xssproxy = {
    Unit.Description = "Forward DBus calls relating to screensaver to Xss";
    Service.Type = "simple";
    Service.ExecStart = "${pkgs.xssproxy}/bin/xssproxy";
    Unit.PartOf = [ "graphical-session.target" ];
    Install.WantedBy = [ "graphical-session.target" ];
  };

  systemd.user.services.xsecurelock = {
    Unit.Description = "Run xsecurelock with specified configuration";
    Service.Type = "simple";

    Service.ProtectSystem = "strict";
    Service.UnsetEnvironment = [
      "HOME"
      "PATH"
      "XDG_RUNTIME_DIR"
      "TERM"
    ];
    Service.PassEnvironment = [
      "NOTIFY_SOCKET"
    ];

    Service.Environment = [
      ''"XSECURELOCK_BACKGROUND_COLOR=#000000"''
      ''"XSECURELOCK_AUTH_BACKGROUND_COLOR=#000000"''
      ''"XSECURELOCK_AUTH_FOREGROUND_COLOR=${config.xresources.properties."*darkForeground"}"''
      ''"XSECURELOCK_DATETIME_FORMAT=%%A, %%B %%d, %%I:%%M %%p"''
      ''"XSECURELOCK_FONT=monospace:style=bold:size=11"''
      ''"XSECURELOCK_PASSWORD_PROMPT=time"''
      ''"XSECURELOCK_SHOW_DATETIME=0"''
      ''"XSECURELOCK_SHOW_HOSTNAME=0"''
      ''"XSECURELOCK_SHOW_USERNAME=0"''

      # ''"XSECURELOCK_NO_PAM_RHOST=1"'' # Necessary to make fprintd work.

      ''"XSECURELOCK_AUTH_TIMEOUT=30"''
      ''"XSECURELOCK_BLANK_TIMEOUT=15"''
    ];

    Service.ExecStart = "${pkgs.xsecurelock}/bin/xsecurelock";
    Service.Restart = "on-failure";
    Service.RestartSec = 0;
    Unit.OnFailure = [ "xsecurelock-kill.service" ];

    Install.WantedBy = [ "sleep.target" ];
    Unit.Before = [ "sleep.target" ];
  };

  systemd.user.services.xsecurelock-failure = {
    Unit.Description = "Bring down the system when xsecurelock fails";
    Service.Type = "oneshot";
    Service.ExecStart = "${pkgs.systemd}/bin/systemctl poweroff";
  };

  # I only need this so I can react to logind's lock-session stuff and suspend events
  services.screen-locker = {
    enable = true;
    inactiveInterval = 15;
    lockCmd = "${pkgs.systemd}/bin/systemctl --user start xsecurelock.service";
    xautolock.enable = false; # Use xss-lock
  };

  services.xidlehook = {
    enable = true;

    not-when-audio = true;
    not-when-fullscreen = true;

    environment = {
      "XSECURELOCK_IDLE_TIMERS" = "";
      "XSECURELOCK_DIM_TIME_MS" = "2500";
      "XSECURELOCK_WAIT_TIME_MS" = "15000";
    };

    timers = [
      {
        delay = 1500;
        command = "${pkgs.xsecurelock}/libexec/xsecurelock/until_nonidle ${pkgs.xsecurelock}/libexec/xsecurelock/dimmer";
      }
      {
        delay = 1515;
        command = "${pkgs.systemd}/bin/systemctl --user start xsecurelock.service";
      }
    ];
  };

  services.sxhkd.keybindings = {
    # Session: lock screen - super + l
    "super + l" = "${pkgs.systemd}/bin/systemctl --user start xsecurelock.service";

    # Session: toggle screensaver on/off - super + shift + l
    "super + shift + l" = ''toggle-xsecurelock'';
  };

  home.packages = [
    (pkgs.writeShellApplication {
      name = "xsecurelock-toggle";

      runtimeInputs = [
        pkgs.gnugrep
        pkgs.libnotify
        pkgs.systemd
        pkgs.xorg.xset
      ];

      text = ''
        if systemctl --user -q is-active xidlehook.service xss-lock.service; then
            systemctl --user stop xidlehook.service xss-lock.service \
                && exec \
                    notify-send \
                        -a xsecurelock \
                        -i preferences-desktop-screensaver \
                        'xsecurelock' \
                        'Screensaver disabled, screen will not automatically lock.'
        else \
            systemctl --user start xidlehook.service xss-lock.service \
                && exec \
                    notify-send \
                        -a xsecurelock \
                        -i preferences-desktop-screensaver \
                        'xsecurelock' \
                        'Screensaver enabled, screen will automatically lock.'
        fi
      '';
    })

    (pkgs.writeShellApplication {
      name = "dpms-toggle";

      runtimeInputs = [
        pkgs.gnugrep
        pkgs.libnotify
        pkgs.xorg.xset
      ];

      text = ''
        if LC_ALL=C xset q | grep -q 'DPMS is Enabled'; then
            xset -dpms \
                && exec \
                    notify-send \
                        -a dpms-toggle \
                        -i preferences-desktop-display \
                        'dpms-toggle' \
                        'DPMS disabled, monitor will not go to sleep automatically.'
        else
            xset +dpms \
                && exec \
                    notify-send \
                        -a dpms-toggle \
                        -i preferences-desktop-display \
                        'dpms-toggle' \
                        'DPMS enabled, monitor will sleep automatically.'
        fi
      '';
    })
  ];
}
