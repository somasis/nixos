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

  signalPackage = pkgs.signal-desktop-beta;
  signalWindowClassName = "Signal Beta";
  signalDescription = signalPackage.meta.description;

  signal = pkgs.symlinkJoin {
    name = "signal-desktop-with-pass";
    paths = [
      (pkgs.writeShellScriptBin (getExeName signalPackage) ''
        set -eu
        set -o pipefail

        entry="${osConfig.networking.fqdnOrHostName}/signal-desktop"

        mkdir -m 700 -p "''${XDG_CONFIG_HOME:=$HOME/.config}/${signalWindowClassName}"
        rm -f "$XDG_CONFIG_HOME/${signalWindowClassName}"/config.json
        mkfifo "$XDG_CONFIG_HOME/${signalWindowClassName}"/config.json

        ${config.programs.password-store.package}/bin/pass "$entry" \
            | ${config.programs.jq.package}/bin/jq -R '{
                key: .,
                mediaPermissions: true,
                mediaCameraPermissions: true
            }' \
            > "$XDG_CONFIG_HOME/${signalWindowClassName}"/config.json &

        ${pkgs.rwc}/bin/rwc -p "$XDG_CONFIG_HOME/${signalWindowClassName}"/config.json \
            | ${pkgs.xe}/bin/xe -s 'rm -f "$XDG_CONFIG_HOME/${signalWindowClassName}"/config.json' &

        e=0
        (exec -a ${getExeName signalPackage} ${getExe signalPackage} "$@") || e=$?
        kill $(jobs -p)
        exit "$e"
      '')

      signalPackage
    ];
  };

  signalName = getExeName signalPackage;
  signalPath = "${signal}/bin/${signalName}";
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

  services.dunst.settings.zz-signal = {
    desktop_entry = "signal-desktop*";

    # Signal blue
    background = "#3a76f0";
    foreground = "#ffffff";
  };

  systemd.user.services.signal = {
    Unit = {
      Description = signalDescription;
      PartOf = [ "graphical-session.target" ];
      After = [ "graphical-session-pre.target" "tray.target" ];
      Requires = [ "tray.target" ];

      StartLimitIntervalSec = 1;
      StartLimitBurst = 1;
      StartLimitAction = "none";
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStart = "${signalPath} " + lib.cli.toGNUCommandLineShell { } {
        start-in-tray = true;
      };

      Restart = "on-abnormal";
    };
  };

  services.sxhkd.keybindings."super + s" = pkgs.writeShellScript "signal" ''
    ${pkgs.jumpapp}/bin/jumpapp \
        -c ${lib.escapeShellArg signalWindowClassName} \
        -i ${lib.escapeShellArg signalName} \
        -f ${pkgs.writeShellScript "start-or-switch" ''
            if ! ${pkgs.systemd}/bin/systemctl --user is-active -q signal.service; then
                ${pkgs.systemd}/bin/systemctl --user start signal.service && sleep 2
            fi
            ${config.systemd.user.services.signal.Service.ExecStart}
        ''}  '';

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
