{ config
, pkgs
, lib
, nixosConfig
, ...
}:
let
  inherit (lib)
    concatStringsSep
    mapAttrs'
    nameValuePair
    replaceStrings
    ;

  inherit (config.lib.somasis)
    camelCaseToKebabCase
    programName
    programPath
    ;

  signal = pkgs.signal-desktop-beta;
  signalWindowName = "Signal Beta";

  signalDescription = signal.meta.description;

  signal' = pkgs.symlinkJoin {
    name = "signal-desktop-with-pass";
    paths = [
      (pkgs.writeShellScriptBin (programName signal) ''
        set -eu
        set -o pipefail

        entry="${nixosConfig.networking.fqdnOrHostName}/signal-desktop"

        mkdir -m 700 -p "''${XDG_CONFIG_HOME:=$HOME/.config}/${signalWindowName}"
        rm -f "$XDG_CONFIG_HOME/${signalWindowName}"/config.json
        mkfifo "$XDG_CONFIG_HOME/${signalWindowName}"/config.json

        ${config.programs.password-store.package}/bin/pass "$entry" \
            | ${config.programs.jq.package}/bin/jq -R '{
                key: .,
                mediaPermissions: true,
                mediaCameraPermissions: true
            }' \
            > "$XDG_CONFIG_HOME/${signalWindowName}"/config.json &

        ${pkgs.rwc}/bin/rwc -p "$XDG_CONFIG_HOME/${signalWindowName}"/config.json \
            | ${pkgs.xe}/bin/xe -s 'rm -f "$XDG_CONFIG_HOME/${signalWindowName}"/config.json' &

        e=0
        (exec -a ${programName signal} ${programPath signal} "$@") || e=$?
        kill $(jobs -p)
        exit "$e"
      '')

      signal
    ];
  };

  signalPath = "${signal'}/bin/${programName signal}";
in
{
  home.packages = [ signal ];

  persist.directories = [ "etc/${signalWindowName}" ];

  xdg.configFile."${signalWindowName}/ephemeral.json".text = lib.generators.toJSON { }
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
    appname = "signal-desktop.*";

    # Signal blue
    background = "#3a76f0";
    foreground = "#ffffff";
  };

  services.sxhkd.keybindings."super + s" = builtins.toString (pkgs.writeShellScript "signal" ''
    if ! ${pkgs.jumpapp}/bin/jumpapp -c ${lib.escapeShellArg signalWindowName} -f ${lib.escapeShellArg (programName signal)} 2>/dev/null; then
        if ${pkgs.systemd}/bin/systemctl --user is-active -q signal.service; then
            exec ${signalPath} >/dev/null 2>&1
        else
            ${pkgs.systemd}/bin/systemctl --user start signal.service \
                && sleep 2 \
                && exec ${signalPath} >/dev/null 2>&1
        fi
    fi
  '');

  systemd.user.services.signal = {
    Unit = {
      Description = signalDescription;
      PartOf = [ "graphical-session.target" ];

      StartLimitIntervalSec = 1;
      StartLimitBurst = 1;
      StartLimitAction = "none";
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStart = "${signalPath} " + concatStringsSep " " (map (x: "--${x}") [
        "start-in-tray"

        # Force GPU-utilizing acceleration
        # <https://wiki.archlinux.org/title/Chromium#Force_GPU_acceleration>
        "ignore-gpu-blocklist"
        "enable-gpu-rasterization"
        "enable-zero-copy"

        # Enable hardware video acceleration
        # <https://wiki.archlinux.org/title/Chromium#Hardware_video_acceleration>
        "enable-features=VaapiVideoDecoder"
        "enable-accelerated-mjpeg-decode"
        "enable-accelerated-video-decode"
      ]);

      Restart = "on-abnormal";
    };
  };

  services.xsuspender.rules.signal = {
    matchWmClassGroupContains = "signal-desktop";
    downclockOnBattery = 0;
    suspendDelay = 300;
    resumeEvery = 10;
    resumeFor = 5;

    suspendSubtreePattern = ".";

    # Only suspend if signal isn't currently open, and no applications
    # are playing on pulseaudio
    execSuspend = builtins.toString (pkgs.writeShellScript "suspend" ''
      ! ${pkgs.xdotool}/bin/xdotool search \
          --limit 1 \
          --onlyvisible \
          --classname \
          '^signal-desktop$' \
          >/dev/null \
          && test "$(
              ${pkgs.ponymix}/bin/ponymix \
                  --short \
                  --sink-input \
                  list \
                  | wc -l
              )" \
              -eq 0
      e=$?
      ${pkgs.libnotify}/bin/notify-send -a xsuspender xsuspender "suspending $WM_NAME ($PID, $WID)"
      exit $e
    '');
  };
}
