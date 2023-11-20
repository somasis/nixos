{ config
, pkgs
, lib
, inputs
, osConfig
, ...
}:
let
  inherit (config.lib.somasis)
    camelCaseToScreamingSnakeCase
    getExeName
    ;

  discord = pkgs.discord.override {
    withVencord = true;
    # withOpenASAR = true;
  };

  # discord = pkgs.armcord;

  discordWindowClassName = "discord";
  # discordWindowClassName = "ArmCord";
  discordDescription = discord.meta.description;
  discordName = getExeName discord;
  discordPath = "${discord}/bin/${discordName}";

  makeCssFontList = list: lib.pipe list [
    (map (font: ''"${font}"''))
    (lib.concatStringsSep ",")
  ];

  makeCssFontFamily = familyName: fontList: ''
    @font-face {
        font-family: "${familyName}";
        src: ${lib.pipe fontList [
          (map (font: "local(\"${font}\")"))
          (lib.concatStringsSep ",")
        ]};
    }
  '';

  discord-css = pkgs.concatText "discord-css" [
    (pkgs.writeText "system-fonts.css" ''
      ${makeCssFontFamily "system-ui" osConfig.fonts.fontconfig.defaultFonts.sansSerif}
      ${makeCssFontFamily "-apple-system" osConfig.fonts.fontconfig.defaultFonts.sansSerif}
      ${makeCssFontFamily "BlinkMacSystemFont" osConfig.fonts.fontconfig.defaultFonts.sansSerif}
      ${makeCssFontFamily "emoji" osConfig.fonts.fontconfig.defaultFonts.emoji}
      ${makeCssFontFamily "sans-serif" osConfig.fonts.fontconfig.defaultFonts.sansSerif}
      ${makeCssFontFamily "serif" osConfig.fonts.fontconfig.defaultFonts.serif}
      ${makeCssFontFamily "monospace" osConfig.fonts.fontconfig.defaultFonts.monospace}
      ${makeCssFontFamily "ui-sans-serif" osConfig.fonts.fontconfig.defaultFonts.sansSerif}
      ${makeCssFontFamily "ui-serif" osConfig.fonts.fontconfig.defaultFonts.serif}
      ${makeCssFontFamily "ui-monospace" osConfig.fonts.fontconfig.defaultFonts.monospace}
    '')
    (inputs.discordThemeCustom + "/custom.css")
    (inputs.discordThemeIrc + "/irc.css")
  ];

  discord-theme = pkgs.runCommandLocal "discord-theme"
    {
      theme = discord-css;
      manifest = (pkgs.formats.json { }).generate "discord-theme-manifest.json" {
        name = "theme";
        author = config.home.username;
        theme = "theme.css";
      };
    } ''
    mkdir -p "$out"
    ln -s "$manifest" "$out"/manifest.json
    ln -s "$theme"    "$out"/theme.css
  '';
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

  persist = {
    directories = [ "etc/${discordWindowClassName}" ];
    files = [ "etc/Vencord/settings.json" ];
  };

  xdg.configFile = {
    "${discordWindowClassName}/settings.json".text = lib.generators.toJSON { } {
      openasar = {
        setup = true;
        quickstart = true;
      };

      SKIP_HOST_UPDATE = true;
      DANGEROUS_ENABLE_DEVTOOLS_ONLY_ENABLE_IF_YOU_KNOW_WHAT_YOURE_DOING = true;
      trayBalloonShown = true;

      # css = lib.fileContents discord-css;
    };

    # "${discordWindowClassName}/storage/settings.json".text = lib.generators.toJSON { } {
    #   doneSetup = true;
    #   multiInstance = false;

    #   alternativePaste = false;
    #   disableAutogain = false;

    #   channel = "canary";
    #   automaticPatches = true;

    #   armcordCSP = true;
    #   mods = "vencord";
    #   inviteWebsocket = true;
    #   spellcheck = true;

    #   skipSplash = true;
    #   startMinimized = true;
    #   minimizeToTray = true;
    #   windowStyle = "native";
    #   mobileMode = false;

    #   tray = true;
    #   trayIcon = "dsc-tray";
    #   dynamicIcon = false;

    #   performanceMode = "battery";

    #   useLegacyCapturer = true;
    # };

    # "${discordWindowClassName}/storage/lang.json".text = lib.generators.toJSON { } {
    #   lang = "en-US";
    # };

    # "${discordWindowClassName}/themes/theme".source = discord-theme;
    # "Vencord/themes/somasis".source = discord-theme;
    "Vencord/settings/quickCss.css".source = discord-css;
  };

  systemd.user.services.discord = {
    Unit = {
      Description = discordDescription;
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

      ExecStart = "${discordPath} " + lib.cli.toGNUCommandLineShell { } {
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
        state = "$artist - $album ($date)";
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
        -i ${lib.escapeShellArg discordName} \
        -f ${pkgs.writeShellScript "start-or-switch" ''
            if ! ${pkgs.systemd}/bin/systemctl --user is-active -q discord.service >/dev/null 2>&1; then
                ${pkgs.systemd}/bin/systemctl --user start discord.service && sleep 2
            fi
            exec ${config.systemd.user.services.discord.Service.ExecStart} >/dev/null 2>&1
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
