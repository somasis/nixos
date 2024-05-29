{ config
, osConfig
, lib
, pkgs
, ...
}:
assert osConfig.services.systemd-lock-handler.enable;
let
  inherit (config.lib.somasis) camelCaseToScreamingSnakeCase;

  usbguardCfg = osConfig.services.usbguard;
  usbguardPkg = usbguardCfg.package or pkgs.usbguard-nox;
in
{
  services = {
    xsecurelock = {
      enable = true;
      settings = {
        XSECURELOCK_BACKGROUND_COLOR = "#000000";
        XSECURELOCK_AUTH_BACKGROUND_COLOR = "#000000";
        XSECURELOCK_AUTH_FOREGROUND_COLOR = "#ffffff";
        XSECURELOCK_AUTH_WARNING_COLOR = "#ff0000";

        XSECURELOCK_FONT = "monospace:style=bold:size=11";

        XSECURELOCK_DATETIME_FORMAT = "%a, %b %d, %i:%m %p";
        XSECURELOCK_PASSWORD_PROMPT = "time";

        XSECURELOCK_SHOW_DATETIME = 0;
        XSECURELOCK_SHOW_HOSTNAME = 0;
        XSECURELOCK_SHOW_USERNAME = 0;
        XSECURELOCK_SHOW_KEYBOARD_LAYOUT = 0;

        XSECURELOCK_AUTH_TIMEOUT = 30;
        XSECURELOCK_BLANK_TIMEOUT = 15;

        # XSECURELOCK_DIM_TIME_MS = 15 * 1000;
        # XSECURELOCK_NO_PAM_RHOST = 1; # necessary to make fprintd work?
      };
    };

    xssproxy = {
      enable = true;
      verbose = true;
    };

    sxhkd.keybindings = {
      "super + l" = "${pkgs.systemd}/bin/loginctl lock-session";
      "super + shift + l" = "toggle-xsecurelock";
      "super + ctrl + l" = "toggle-dpms";
    };
  };

  systemd.user = {
    services.xsecurelock = {
      # Unit.OnFailure = [ "xsecurelock-failure.service" ];
      Unit.Conflicts = [ "usbguard-notifier.service" ];
      Unit.OnSuccess = [ "usbguard-notifier.service" ];

      Service = {
        ExecStartPre =
          # Disable the ability to switch between virtual terminals.
          [ "-${lib.getExe pkgs.xorg.setxkbmap} -option srvrkeys:none" ]
          # Implement something like GNOME's USBGuard integration
          ++ lib.optionals usbguardCfg.enable [
            "${usbguardPkg}/bin/usbguard set-parameter InsertedDevicePolicy block"
            "${usbguardPkg}/bin/usbguard set-parameter ImplicitPolicyTarget block"
            # "${pkgs.systemd}/bin/systemctl --user stop usbguard-notifier.service"
          ];

        ExecStopPost = lib.optionals osConfig.services.usbguard.enable [
          # "${pkgs.systemd}/bin/systemctl --user start usbguard-notifier.service"
          "${usbguardPkg}/bin/usbguard set-parameter InsertedDevicePolicy ${usbguardCfg.insertedDevicePolicy}"
          "${usbguardPkg}/bin/usbguard set-parameter ImplicitPolicyTarget ${usbguardCfg.implicitPolicyTarget}"
        ];
      };
    };

    # services.xsecurelock-failure = {
    #   Unit.Description = "Bring down the system when xsecurelock fails";
    #   Service.Type = "oneshot";
    #   Service.ExecStart = "${pkgs.systemd}/bin/systemctl poweroff";
    # };

    # Re-initialize keyboard settings when system is unlocked.
    services.setxkbmap = {
      Unit.PartOf = [ "unlock.target" ];
      Install.WantedBy = [ "unlock.target" ];
    };
  };

  # I only need this so I can react to logind's lock-session stuff and suspend events
  services.screen-locker = {
    enable = true;
    lockCmd = "${pkgs.systemd}/bin/loginctl lock-session";
    inactiveInterval = 15; # lock after x minutes of inactivity

    xautolock = {
      enable = false; # Use xss-lock
      # extraOptions =
      #   let
      #     xsecurelockNotifier = pkgs.writeShellScript "xsecurelock-notifier" ''
      #       ${lib.toShellVar "XSECURELOCK_DIM_TIME_MS" xsecurelockSettings.dimTimeMs}
      #       ${lib.toShellVar "XSECURELOCK_WAIT_TIME_MS" xsecurelockSettings.waitTimeMs}
      #       exec ${xsecurelockPkg}/lib/xsecurelock/until_nonidle ${xsecurelockPkg}/lib/xsecurelock/dimmer
      #     '';
      #   in
      #   [
      #     "-notify ${xsecurelockSettings.dimTimeMs / 1000}"
      #     "-notifier ${xsecurelockNotifier}"
      #   ];
    };

    xss-lock = {
      extraOptions =
        # let
        #   xsecurelockDimmer = pkgs.writeShellScript "xsecurelock-dimmer" ''
        #     ${lib.toShellVar "XSECURELOCK_DIM_TIME_MS" xsecurelockSettings.dimTimeMs}
        #     ${lib.toShellVar "XSECURELOCK_WAIT_TIME_MS" xsecurelockSettings.waitTimeMs}
        #     exec ${xsecurelockPkg}/lib/xsecurelock/dimmer
        #   '';
        # in
        [
          # "-n ${xsecurelockDimmer}"
          "-l"
        ];

      screensaverCycle = 60 * 15;
    };
  };

  # services.xidlehook = {
  #   enable = false;

  #   detect-sleep = true;
  #   not-when-audio = true;
  #   not-when-fullscreen = true;

  #   environment = { };

  #   timers = [
  #     {
  #       delay = 10;
  #       command = "${pkgs.systemd}/bin/systemctl start --user xsecurelock.service";
  #       canceller = "${pkgs.systemd}/bin/systemctl stop --user xsecurelock.service";
  #     }
  #   ];
  # };

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
}
