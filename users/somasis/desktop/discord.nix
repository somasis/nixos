{ config
, pkgs
, lib
, inputs
, ...
}:
let
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

  camelCaseToSnakeCase = x:
    if lib.toLower x == x then
      x
    else
      lib.replaceStrings
        (lib.upperChars ++ lib.lowerChars)
        ((map (c: "_${c}") lib.upperChars) ++ lib.upperChars)
        x
  ;

  discord = pkgs.discord-canary.override {
    withOpenASAR = true;
  };
  discordDescription = discord.meta.description;
  discordProgram = "${discord}/bin/${discord.meta.mainProgram}";
  # discord = pkgs.discord.override {
  #   withOpenASAR = true;
  # };
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

  # home.persistence."/cache${config.home.homeDirectory}".directories = [
  #   "var/cache/powercord"
  # ];

  xdg.configFile."discordcanary/settings.json".text = (lib.generators.toJSON { }
    # Convert all the attributes to SNAKE_CASE in the generated JSON
    (lib.mapAttrs'
      (name: value: { inherit value; name = camelCaseToSnakeCase name; })
      {
        dangerousEnableDevtoolsOnlyEnableIfYouKnowWhatYoureDoing = true;
        skipHostUpdate = true;

        openasar = {
          setup = true;
          cmdPreset = "balanced";
          themeSync = true;
          quickstart = true;

          css = (lib.fileContents (pkgs.concatTextFile {
            name = "discord-css";
            files = [
              "${inputs.repluggedThemeCustom}/custom.css"
              "${inputs.repluggedThemeIrc}/irc.css"
            ];
          }));
        };
      }
    )
  );

  services.mpd-discord-rpc = {
    enable = config.services.mpd.enable;
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

    zz-discord-david = {
      appname = "discord";
      summary = "david";
      background = "#ffffff";
      foreground = "#000000";
    };

    zz-discord-phidica = {
      appname = "discord";
      summary = "Phidica*";
      background = "#aa8ed6";
      foreground = "#ffffff";
    };
  };

  services.sxhkd.keybindings."super + d" = builtins.toString (
    pkgs.writeShellScript "discord" ''
      if ! ${config.home.homeDirectory}/bin/raise -V '^(.+ - Discord|Discord)$';then
          if ${pkgs.systemd}/bin/systemctl --user is-active -q discord.service; then
              exec ${discordProgram} >/dev/null 2>&1
          else
              ${pkgs.systemd}/bin/systemctl --user start discord.service \
                  && sleep 2 \
                  && exec ${discordProgram} >/dev/null 2>&1
          fi
      fi
    ''
  );

  systemd.user.services.discord = {
    Unit = {
      Description = discordDescription;
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStart = "${discordProgram} --start-minimized";
      Restart = "on-failure";

      StandardError = "null";

      # It seems this is required because otherwise Discord moans about options.json being read-only
      # in the journal every time I run `discord` to open the already-running client.
      StandardOutput = "null";
    };
  };
}
