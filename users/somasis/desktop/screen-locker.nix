{ config
, lib
, pkgs
, ...
}:
let
  xsecurelock = pkgs.xsecurelock.overrideAttrs (prev: {
    version = "unstable-2023-01-16";
    src = pkgs.fetchFromGitHub {
      owner = "google";
      repo = prev.pname;

      # TODO Remove once xsecurelock is updated in nixpkgs.
      rev = "15e9b01b02f64cc40f02184f001849971684ce15";
      hash = "sha256-k7xkM53hLJtjVDkv4eklvOntAR7n1jsxWHEHeRv5GJU=";
    };
  });
in
{
  systemd.user.services = {
    xssproxy = {
      Unit.Description = "Forward DBus calls relating to screensaver to Xss";
      Service.Type = "simple";
      Service.ExecStart = "${pkgs.xssproxy}/bin/xssproxy";
      Unit.PartOf = [ "graphical-session.target" ];
      Install.WantedBy = [ "graphical-session.target" ];
    };

    xsecurelock = {
      Unit = {
        Description = "Run xsecurelock with specified configuration";
        Before = [ "sleep.target" ];
        # OnFailure = [ "xsecurelock-failure.service" ];
      };

      Install.WantedBy = [ "sleep.target" ];

      Service = {
        Type = "simple";

        ProtectSystem = "strict";
        UnsetEnvironment = [
          "HOME"
          "PATH"
          "XDG_RUNTIME_DIR"
          "TERM"
        ];
        # PassEnvironment = [ "NOTIFY_SOCKET" ];
        # NotifyAccess = "all";

        Environment = [
          "XSECURELOCK_BACKGROUND_COLOR=#000000"

          "XSECURELOCK_AUTH_BACKGROUND_COLOR=#000000"
          "XSECURELOCK_AUTH_FOREGROUND_COLOR=#ffffff"

          "XSECURELOCK_FONT=monospace:style=bold:size=11"

          "XSECURELOCK_DATETIME_FORMAT=%%A, %%B %%d, %%I:%%M %%p"
          "XSECURELOCK_PASSWORD_PROMPT=cursor"

          "XSECURELOCK_SHOW_DATETIME=0"
          "XSECURELOCK_SHOW_HOSTNAME=0"
          "XSECURELOCK_SHOW_USERNAME=0"
          "XSECURELOCK_SHOW_KEYBOARD_LAYOUT=0"

          # "XSECURELOCK_NO_PAM_RHOST=1" # Necessary to make fprintd work.

          "XSECURELOCK_AUTH_TIMEOUT=30"
          "XSECURELOCK_BLANK_TIMEOUT=15"
        ];

        ExecStart = "${xsecurelock}/bin/xsecurelock";
        Restart = "on-failure";
        RestartSec = 0;
      };
    };

    xsecurelock-failure = {
      Unit.Description = "Bring down the system when xsecurelock fails";
      Service.Type = "oneshot";
      Service.ExecStart = "${pkgs.systemd}/bin/systemctl poweroff";
    };
  };

  # I only need this so I can react to logind's lock-session stuff and suspend events
  services.screen-locker = {
    enable = true;
    xautolock.enable = false; # Use xss-lock
    lockCmd = "${pkgs.systemd}/bin/systemctl --user start xsecurelock.service";

    inactiveInterval = 15; # minutes
    xss-lock = {
      extraOptions = [ "-l" ];
      screensaverCycle = 60 * 15;
    };
  };

  services.xidlehook = {
    enable = false;

    detect-sleep = true;
    not-when-audio = true;
    not-when-fullscreen = true;

    environment = { };

    timers = [
      {
        delay = 10;
        command = "${pkgs.systemd}/bin/systemctl start --user xsecurelock.service";
        canceller = "${pkgs.systemd}/bin/systemctl stop --user xsecurelock.service";
      }
    ];
  };

  services.sxhkd.keybindings = {
    # Session: lock screen - super + l
    "super + l" = "${pkgs.systemd}/bin/loginctl lock-session";

    # Session: toggle screensaver on/off - super + shift + l
    "super + shift + l" = "toggle-xsecurelock";
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
        if systemctl --user -q is-active xss-lock.service; then
            systemctl --user stop xss-lock.service \
                && exec \
                    notify-send \
                        -a xsecurelock \
                        -i preferences-desktop-screensaver \
                        'xsecurelock' \
                        'Screensaver disabled, screen will not automatically lock.'
        else \
            systemctl --user start xss-lock.service \
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
