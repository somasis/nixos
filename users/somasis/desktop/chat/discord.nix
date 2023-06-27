{ config
, pkgs
, lib
, inputs
, ...
}:
let
  inherit (config.lib.somasis)
    camelCaseToScreamingSnakeCase
    programName
    programPath
    ;

  discord = pkgs.armcord;
  discordWindowClassName = "ArmCord";
  discordDescription = discord.meta.description;
  discordName = programName discord;
  discordPath = "${discord}/bin/${discordName}";
in
{
  home.packages = [
    discord

    pkgs.discordchatexporter-cli

    # Used for developing discord-tokipona.
    pkgs.bc
    pkgs.gnugrep
    pkgs.gnumake
    pkgs.gnused
    pkgs.jq
    pkgs.rwc
    pkgs.xe
  ];

  persist.directories = [ "etc/${discordWindowClassName}" ];

  xdg.configFile = {
    "ArmCord/storage/settings.json".text = lib.generators.toJSON { } {
      doneSetup = true;

      channel = "canary";

      armcordCSP = true;
      mods = "vencord";
      inviteWebsocket = true;
      spellcheck = true;

      skipSplash = true;
      startMinimized = true;
      windowStyle = "native";
      mobileMode = false;

      minimizeToTray = true;
      trayIcon = "dsc-tray";

      performanceMode = "battery";

      useLegacyCapturer = true;
    };

    "ArmCord/storage/lang.json".text = lib.generators.toJSON { } {
      lang = "en-US";
    };
  };

  systemd.user.services.discord = {
    Unit = {
      Description = discordDescription;
      PartOf = [ "graphical-session.target" ];

      StartLimitIntervalSec = 1;
      StartLimitBurst = 1;
      StartLimitAction = "none";
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";

      ExecStart = "${programPath discord} " + lib.cli.toGNUCommandLineShell { } {
        start-minimized = true;
      };

      Restart = "on-abnormal";
    };
  };

  services.mpd-discord-rpc = {
    inherit (config.services.mpd) enable;

    settings = {
      hosts = [ "${config.services.mpd.network.listenAddress}:${builtins.toString config.services.mpd.network.port}" ];
      format = {
        details = "$title";
        state = "$artist - $title ($album)";
      };
    };
  };

  systemd.user.services.mpd-discord-rpc.Unit.BindsTo =
    [ "discord.service" ]
    ++ lib.optional config.services.mpd.enable "mpd.service"
  ;

  services.dunst.settings = {
    zz-discord = {
      desktop_entry = discordWindowClassName;

      # Discord blue
      background = "#6654ec";
      foreground = "#ffffff";
    };

    zz-discord-cassie = {
      desktop_entry = discordWindowClassName;
      summary = "jan Kasi";
      background = "#7596ff";
      foreground = "#ffffff";
    };

    zz-discord-jes = {
      desktop_entry = discordWindowClassName;
      summary = "jan Jes";
      background = "#ae82e9";
      foreground = "#ffffff";
    };

    zz-discord-zeyla = {
      desktop_entry = discordWindowClassName;
      summary = "jan Seja";
      background = "#df7422";
      foreground = "#ffffff";
    };

    zz-discord-phidica = {
      desktop_entry = discordWindowClassName;
      summary = "Phidica*";
      background = "#aa8ed6";
      foreground = "#ffffff";
    };
  };

  services.sxhkd.keybindings."super + d" = pkgs.writeShellScript "discord" ''
    ${pkgs.jumpapp}/bin/jumpapp \
        -c ${lib.escapeShellArg discordWindowClassName} \
        -i ${lib.escapeShellArg (programName discord)} \
        -f ${pkgs.writeShellScript "start-or-switch" ''
            if ! ${pkgs.systemd}/bin/systemctl --user is-active -q discord.service >/dev/null 2>&1; then
                ${pkgs.systemd}/bin/systemctl --user start discord.service && sleep 2
            fi
            exec ${lib.escapeShellArg (programName discord)} >/dev/null 2>&1
        ''} \
        >/dev/null
  '';

  # services.xsuspender.rules.discord = {
  #   matchWmClassGroupContains = "discord";
  #   downclockOnBattery = 0;
  #   suspendDelay = 300;
  #   resumeEvery = 10;
  #   resumeFor = 5;

  #   suspendSubtreePattern = ".";

  #   # Only suspend if discord isn't currently open, and no applications
  #   # are playing on pulseaudio
  #   execSuspend = builtins.toString (pkgs.writeShellScript "suspend" ''
  #     ! ${pkgs.xdotool}/bin/xdotool search \
  #         --limit 1 \
  #         --onlyvisible \
  #         --classname \
  #         '^discord$' \
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
