{ config
, osConfig
, lib
, pkgs
, ...
}:
# TODO Utilize <https://git.sr.ht/~whynothugo/systemd-lock-handler> in some way,
# it looks a lot more purpose-built to actually do what I'm trying to do here
let
  inherit (config.lib.somasis) camelCaseToScreamingSnakeCase;

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

        Environment = lib.mapAttrsToList (n: v: "\"XSECURELOCK_${camelCaseToScreamingSnakeCase n}=${lib.escape [ "\"" ] (builtins.toString v)}\"") {
          backgroundColor = "#000000";

          authBackgroundColor = "#000000";
          authForegroundColor = "#ffffff";

          font = "monospace:style=bold:size=11";

          datetimeFormat = "%%a, %%b %%d, %%i:%%m %%p";
          passwordPrompt = "time";

          showDatetime = 0;
          showHostname = 0;
          showUsername = 0;
          showKeyboardLayout = 0;

          # noPamRhost = 1; # necessary to make fprintd work.

          authTimeout = 30;
          blankTimeout = 15;
        }
          # ++ lib.mapAttrsToList (key: command: "XSECURELOCK_KEY_${key}_COMMAND=${builtins.toString command}") {

          # }
        ;

        # Implement GNOME's lockscreen USBGuard integration stuff
        ExecStartPre =
          [ "${pkgs.xorg.setxkbmap}/bin/setxkbmap -option srvrkeys:none" ]
          ++ lib.optionals osConfig.services.usbguard.enable [
            "${pkgs.usbguard}/bin/usbguard set-parameter InsertedDevicePolicy block"
            "${pkgs.systemd}/bin/systemctl --user stop usbguard-notifier.service"
          ];

        ExecStart = [ "${xsecurelock}/bin/xsecurelock" ];

        ExecStopPost =
          [ "${pkgs.systemd}/bin/systemctl --user start setxkbmap.service" ]
          ++ lib.optionals osConfig.services.usbguard.enable [
            "${pkgs.systemd}/bin/systemctl --user start usbguard-notifier.service"
            "${pkgs.usbguard}/bin/usbguard set-parameter InsertedDevicePolicy ${osConfig.services.usbguard.insertedDevicePolicy}"
          ];

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

  home.packages = [
    (pkgs.writeShellApplication {
      name = "toggle-xsecurelock";

      runtimeInputs = [
        pkgs.libnotify
        pkgs.systemd
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
      name = "toggle-dpms";

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

  services.sxhkd.keybindings = {
    "super + l" = "${pkgs.systemd}/bin/loginctl lock-session";

    "super + shift + l" = "toggle-xsecurelock";
    "super + ctrl + l" = "toggle-dpms";
  };

}
