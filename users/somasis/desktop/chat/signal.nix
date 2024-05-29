{ config
, pkgs
, lib
, osConfig
, ...
}:
let
  inherit (lib)
    concatStringsSep
    getExe
    mapAttrs'
    nameValuePair
    replaceStrings
    ;

  inherit (config.lib.somasis)
    camelCaseToKebabCase
    getExeName
    ;

  signal = pkgs.signal-desktop-beta;
  signalWindowClassName = "Signal Beta";
  signalDescription = signal.meta.description;

  signalExeName = getExeName signal;
  signalExe = getExe signal;
in
{
  home.packages = [ signal ];

  persist.directories = [ "etc/${signalWindowClassName}" ];

  xdg.configFile."${signalWindowClassName}/ephemeral.json".text = lib.generators.toJSON { }
    (mapAttrs' (n: v: nameValuePair (camelCaseToKebabCase n) v) {
      systemTraySetting = "MinimizeToSystemTray";
      shownTrayNotice = true;

      themeSetting = "system";

      window = mapAttrs' (n: v: nameValuePair (camelCaseToKebabCase n) v) {
        autoHideMenuBar = true;
      };

      spellCheck = true;
    });

  services.dunst.settings = {
    signal = {
      desktop_entry = lib.replaceStrings [ " " ] [ "" ] (lib.toLower signalWindowClassName);

      # Signal blue
      background = "#3a76f0";
      foreground = "#ffffff";
    };

    zz-signal-cassie = {
      desktop_entry = lib.replaceStrings [ " " ] [ "" ] (lib.toLower signalWindowClassName);

      summary = "Cassandra*";
      background = "#7596ff";
      foreground = "#ffffff";
    };
  };


  systemd.user = let secret = "${config.xdg.configHome}/${signalWindowClassName}/config.json"; in {
    services.signal = {
      Unit = {
        Description = signal.meta.description;
        PartOf = [ "graphical-session-autostart.target" ];
        Wants = [ "tray.target" ];

        Requires = [ "secret-signal.service" ];
        PropagatesStopTo = [ "secret-signal.service" ];

        StartLimitIntervalSec = 1;
        StartLimitBurst = 1;
        StartLimitAction = "none";

      };
      Install.WantedBy = [ "graphical-session-autostart.target" ];

      Service = {
        Type = "simple";
        ExecStart = "${signalExe} " + lib.cli.toGNUCommandLineShell { } {
          start-in-tray = true;
        };

        Restart = "on-abnormal";

        SyslogIdentifier = "signal";
      };
    };

    services.secret-signal = {
      Unit = {
        Description = "Provide a secret for Signal";
        Upholds = [ "signal.service" ];
        StopWhenUnneeded = true;
      };

      Service =
        let
          secret-signal = pkgs.writeShellScript "secret-signal" ''
            : "''${1?no secret entry given}"
            : "''${2?no secret file given}"

            PATH=${lib.makeBinPath [ pkgs.coreutils config.programs.password-store.package ]}

            # Check if the entry exists
            if pass show "$1" >/dev/null 2>&1; then
                # If it does, write it to the file.
                pass show "$1" > "$2"
            else
                # The entry doesn't exist, so just make the secret file;
                # we'll synchronize it back whenever we stop the service.
                touch "$2"
            fi
          '';

          secret-signal-sync = pkgs.writeShellScript "secret-signal-sync" ''
            : "''${1?no secret entry given}"
            : "''${2?no secret file given}"

            PATH=${lib.makeBinPath [ pkgs.diffutils config.programs.password-store.package ]}

            # Regardless of if the entry exists or not, sync the changes.
            # If it exists and they have changed, sync the changes to the entry,
            # otherwise create the entry.
            if ! cmp -s <(pass show "$1" 2>/dev/null || :) "$2"; then
                pass insert -m -f "$1" < "$2"
            fi
          '';
        in
        {
          Type = "oneshot";
          SyslogIdentifier = "secret-signal";

          # Create the secret file from the entry.
          ExecStart = ''${secret-signal} ''${ENTRY} %t/signal.secret'';

          # Only create the secret link after a successful start.
          ExecStartPost = ''${pkgs.coreutils}/bin/ln -sf %t/signal.secret ''${CONFIG}'';

          # Synchronize the file with the entry on changes.
          ExecStop = ''${secret-signal-sync} ''${ENTRY} %t/signal.secret'';
          RemainAfterExit = true;

          # Remove the secret file.
          ExecStopPost = ''${pkgs.coreutils}/bin/rm -f ''${CONFIG} %t/signal.secret'';

          Environment = [
            ''"CONFIG=%E/${signalWindowClassName}/config.json"''
            "ENTRY=${osConfig.networking.fqdnOrHostName}/signal-desktop"
          ];
        };
    };
  };

  services.sxhkd.keybindings."super + s" = pkgs.writeShellScript "signal" ''
    ${pkgs.jumpapp}/bin/jumpapp \
        -c ${lib.escapeShellArg signalWindowClassName} \
        -i ${lib.escapeShellArg signalExeName} \
        -f ${pkgs.writeShellScript "start-or-switch" ''
            if ! ${pkgs.systemd}/bin/systemctl --user is-active -q signal.service; then
                ${pkgs.systemd}/bin/systemctl --user start signal.service
                ${pkgs.systemd-wait}/bin/systemd-wait --user signal.service active
            fi
            ${config.systemd.user.services.signal.Service.ExecStart}
        ''}
  '';

  # services.xsuspender.rules.signal = {
  #   matchWmClassGroupContains = "signal-desktop";
  #   downclockOnBattery = 0;
  #   suspendDelay = 300;
  #   resumeEvery = 10;
  #   resumeFor = 5;

  #   suspendSubtreePattern = ".";

  #   # Only suspend if signal isn't currently open, and no applications
  #   # are playing on pulseaudio
  #   execSuspend = builtins.toString (pkgs.writeShellScript "suspend" ''
  #     ! ${pkgs.xdotool}/bin/xdotool search \
  #         --limit 1 \
  #         --onlyvisible \
  #         --classname \
  #         '^signal-desktop$' \
  #         >/dev/null \
  #         && test "$(
  #             ${pkgs.ponymix}/bin/ponymix \
  #                 --short \
  #                 --sink-input \
  #                 list \
  #                 | wc -l
  #             )" \
  #             -eq 0
  #     e=$?
  #     ${pkgs.libnotify}/bin/notify-send -a xsuspender xsuspender "suspending $WM_NAME ($PID, $WID)"
  #     exit $e
  #   '');
  # };
}
