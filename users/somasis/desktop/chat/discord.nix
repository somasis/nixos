{ config
, pkgs
, lib
, inputs
, ...
}:
let
  # inherit (lib)
  #   camelCaseToSnakeCase
  #   programName
  #   programPath
  #   ;

  camelCaseToSnakeCase = x:
    if lib.toLower x == x then
      x
    else
      lib.replaceStrings
        (lib.upperChars ++ lib.lowerChars)
        ((map (c: "_${c}") lib.upperChars) ++ lib.upperChars)
        x
  ;

  programName = p: p.meta.metaProgram or p.pname or p.name;
  programPath = p: "${lib.getBin p}/bin/${programName p}";

  # TODO Go back to using Replugged once <https://github.com/replugged-org/replugged/issues/205> is resolved
  # discord = inputs.replugged.lib.makeDiscordPlugged {
  #   inherit pkgs;

  #   extraElectronArgs = "--disable-smooth-scrolling";
  #   withOpenAsar = true;

  #   plugins = {
  #     inherit (inputs)
  #       repluggedPluginBetterCodeblocks
  #       repluggedPluginBotInfo
  #       repluggedPluginCanaryLinks
  #       repluggedPluginChannelTyping
  #       repluggedPluginClickableEdits
  #       repluggedPluginCutecord
  #       repluggedPluginEmojiUtility
  #       repluggedPluginPersistSettings
  #       repluggedPluginSitelenPona
  #       repluggedPluginThemeToggler
  #       repluggedPluginTimestampSender
  #       repluggedPluginTokiPona
  #       repluggedPluginWordFilter
  #       ;
  #   };
  #   themes = {
  #     inherit (inputs)
  #       repluggedThemeCustom
  #       repluggedThemeIrc
  #       ;
  #   };
  # };

  # discord = pkgs.discord-canary;
  discord = pkgs.discord-canary.override { withOpenASAR = true; };
  discordDescription = discord.meta.description;
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

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "etc/discordcanary"
    # "etc/powercord"
  ];

  # home.persistence."/cache${config.home.homeDirectory}".directories = [ "var/cache/powercord" ];

  # Convert all the attributes to SNAKE_CASE in the generated JSON
  xdg.configFile."discordcanary/settings.json".text = lib.generators.toJSON { }
    (lib.mapAttrs'
      (name: value: { inherit value; name = camelCaseToSnakeCase name; })
      {
        dangerousEnableDevtoolsOnlyEnableIfYouKnowWhatYoureDoing = true;

        # The nixpkgs Discord package messes with settings.json if it doesn't have
        # SKIP_HOST_UPDATE set in it already.
        skipHostUpdate = true;

        openasar = {
          setup = true;
          cmdPreset = "balanced";
          themeSync = true;
          quickstart = true;

          css = lib.fileContents (pkgs.runCommandLocal "discord-css" { } ''
            ${pkgs.coreutils}/bin/cat \
                "${inputs.repluggedThemeCustom}/custom.css" \
                "${inputs.repluggedThemeIrc}/irc.css" \
                | ${pkgs.minify}/bin/minify --type css > "$out"
          '');
        };
      }
    );

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

  services.dunst.settings = {
    zz-discord = {
      appname = "discord.*";

      # Discord blue
      background = "#6654ec";
      foreground = "#ffffff";
    };

    zz-discord-cassie = {
      appname = "discord";
      summary = "jan Kasi";
      background = "#7596ff";
      foreground = "#ffffff";
    };

    zz-discord-jes = {
      appname = "discord";
      summary = "jan Jes";
      background = "#ae82e9";
      foreground = "#ffffff";
    };

    zz-discord-zeyla = {
      appname = "discord";
      summary = "jan Seja";
      background = "#df7422";
      foreground = "#ffffff";
    };

    zz-discord-phidica = {
      appname = "discord";
      summary = "Phidica*";
      background = "#aa8ed6";
      foreground = "#ffffff";
    };
  };

  services.sxhkd.keybindings."super + d" = builtins.toString (pkgs.writeShellScript "discord" ''
    exec ${programPath discord} 2>/dev/null

    ${config.home.homeDirectory}/bin/raise -cr '^(discord|browser-window)$' && exit || :

    if ${pkgs.systemd}/bin/systemctl --user is-active -q discord.service; then
        exec ${programPath discord} >/dev/null 2>&1
    else
        ${pkgs.systemd}/bin/systemctl --user start discord.service \
            && sleep 2 \
            && exec ${programPath discord} >/dev/null 2>&1
    fi

  '');

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
      ExecStart = "${programPath discord} " + lib.concatStringsSep " " (map (x: "--${x}") [
        "start-minimized"

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

      # It seems this is required because otherwise Discord moans about options.json being read-only
      # in the journal every time I run `discord` to open the already-running client.
      # As does OpenASAR, about settings.json.
      StandardError = "null";
      StandardOutput = "null";
    };
  };

  services.xsuspender.rules.discord = {
    matchWmClassGroupContains = "discord";
    downclockOnBattery = 0;
    suspendDelay = 300;
    resumeEvery = 10;
    resumeFor = 5;

    suspendSubtreePattern = ".";

    # Only suspend if discord isn't currently open, and no applications
    # are playing on pulseaudio
    execSuspend = builtins.toString (pkgs.writeShellScript "suspend" ''
      ! ${pkgs.xdotool}/bin/xdotool search \
          --limit 1 \
          --onlyvisible \
          --classname \
          '^discord$' \
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
