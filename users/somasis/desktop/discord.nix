{ config
, pkgs
, inputs
, ...
}:
let
  discord = inputs.replugged.lib.makeDiscordPlugged {
    inherit pkgs;

    extraElectronArgs = "--disable-smooth-scrolling";

    # discord = pkgs.discord-canary.override {
    #   withOpenASAR = true;
    # };

    plugins = {
      inherit (inputs)
        repluggedPluginBetterCodeblocks
        repluggedPluginBotInfo
        repluggedPluginCanaryLinks
        repluggedPluginChannelTyping
        repluggedPluginClickableEdits
        repluggedPluginCutecord
        repluggedPluginEmojiUtility
        repluggedPluginPersistSettings
        repluggedPluginSitelenPona
        repluggedPluginThemeToggler
        repluggedPluginTimestampSender
        repluggedPluginTokiPona
        repluggedPluginWordFilter
        ;
    };

    themes = {
      inherit (inputs)
        repluggedThemeCustom
        repluggedThemeIrc
        ;
    };
  };
in
{
  home.packages = [
    discord

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
    "etc/discord"
    "etc/powercord"
  ];

  home.persistence."/cache${config.home.homeDirectory}".directories = [
    "var/cache/powercord"
  ];

  services.mpd-discord-rpc = {
    enable = config.services.mpdris2.enable;
    settings = {
      hosts = [ config.services.mopidy.settings.mpd.hostname ];
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

  services.sxhkd.keybindings."super + d" = "${
    pkgs.writeShellScript "discord" ''
      if ! ${config.home.homeDirectory}/bin/raise -V '^(.+ - Discord|Discord)$';then
          if ${pkgs.systemd}/bin/systemctl --user is-active -q discord.service; then
              exec ${discord}/bin/discord >/dev/null 2>&1
          else
              ${pkgs.systemd}/bin/systemctl --user start discord.service \
                  && sleep 2 \
                  && exec ${discord}/bin/discord >/dev/null 2>&1
          fi
      fi
    ''
  }";

  systemd.user.services.discord = {
    Unit = {
      Description = "Discord instant messaging client";
      PartOf = [ "graphical-session.target" ];
    };
    Install.WantedBy = [ "graphical-session.target" ];

    Service = {
      Type = "simple";
      ExecStart = "${discord}/bin/discord --start-minimized";
      Restart = "on-failure";
      StandardError = "null";
    };
  };

}
