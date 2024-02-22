{ config
, pkgs
, lib
, inputs
, ...
}:
let
  inherit (config.xsession.windowManager) bspwm;
  bspc = "${bspwm.package}/bin/bspc";
in
{
  # services.panel = {
  #   enable = true;

  #   debug = true;

  #   colors = {
  #     background = config.theme.colors.background;
  #     foreground = config.theme.colors.foreground;

  #     accent = config.theme.colors.accent;
  #     black = config.theme.colors.black;
  #     red = config.theme.colors.red;
  #     green = config.theme.colors.green;
  #     yellow = config.theme.colors.yellow;
  #     blue = config.theme.colors.blue;
  #     magenta = config.theme.colors.magenta;
  #     cyan = config.theme.colors.cyan;
  #     white = config.theme.colors.white;

  #     brightBlack = config.theme.colors.brightBlack;
  #     brightRed = config.theme.colors.brightRed;
  #     brightGreen = config.theme.colors.brightGreen;
  #     brightYellow = config.theme.colors.brightYellow;
  #     brightBlue = config.theme.colors.brightBlue;
  #     brightMagenta = config.theme.colors.brightMagenta;
  #     brightCyan = config.theme.colors.brightCyan;
  #     brightWhite = config.theme.colors.brightWhite;
  #   };

  #   fonts = {
  #     default = "monospace:size=10";
  #     bold = "monospace:size=10:style=bold";
  #     light = "monospace:size=10:style=light";
  #     heavy = "monospace:size=10:style=heavy";
  #     emoji = "emoji:size=10";
  #   };

  #   lemonbarPackage = pkgs.lemonbar-xft.overrideAttrs (
  #     let
  #       inherit (inputs.lemonbar) lastModifiedDate;
  #       year = builtins.substring 0 4 lastModifiedDate;
  #       month = builtins.substring 4 2 lastModifiedDate;
  #       day = builtins.substring 6 2 lastModifiedDate;
  #     in
  #     prev:
  #     {
  #       version = "unstable-${year}-${month}-${day}";
  #       src = inputs.lemonbar;
  #     }
  #   );

  #   modules = with lib.hm; {
  #     left = {
  #       bspwm = entryBefore [ "title" ] {
  #         name = "bspwm";
  #         command = pkgs.writeShellApplication {
  #           name = "panel-bspwm";

  #           runtimeInputs = [ config.programs.bspwm.package ];

  #           text = ./modules/bspwm.bash;
  #         };

  #         runtimeInputs = [ config.programs.bspwm.package ];
  #       };

  #       title = entryAfter [ "bspwm" ] {
  #         name = "title";
  #         command = pkgs.writeShellApplication {
  #           name = "panel-title";

  #           runtimeInputs = [
  #             config.programs.bspwn.package
  #             pkgs.coreutils
  #             pkgs.xtitle
  #             pkgs.xdotool
  #             pkgs.xorg.xprop
  #             pkgs.gnused
  #             pkgs.gawk
  #           ];

  #           text = ./modules/title.bash;
  #         };

  #         runtimeInputs = [ config.programs.bspwm.package ];
  #       };

  #       right = {
  #         # anki = entryBefore [ "feeds" "mail" "network" "power" "dates" ] {
  #         #   name = "anki";

  #         #   command = pkgs.writeShellApplication {
  #         #     name = "panel-anki";

  #         #     runtimeInputs = [
  #         #       pkgs.apy
  #         #       pkgs.gnugrep
  #         #       pkgs.coreutils
  #         #       pkgs.jumpapp
  #         #       pkgs.rwc
  #         #       pkgs.procps
  #         #     ];

  #         #     text = ./modules/anki.bash;
  #         #   };
  #         #
  #         #   runtimeInputs = [ pkgs.jumpapp ];
  #         # };

  #         music = entryBefore [ "feeds" "mail" "network" "power" "dates" ] {
  #           name = "music";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-music";

  #             runtimeInputs = [
  #               pkgs.mpc
  #               pkgs.systemd-wait
  #               pkgs.ellipsis
  #               pkgs.pastel
  #             ];

  #             text = ./modules/music.bash;
  #           };
  #         };

  #         feeds = entryBefore [ "mail" ] {
  #           name = "feeds";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-feeds";

  #             runtimeInputs = [
  #               pkgs.newsboat
  #               pkgs.procps
  #               pkgs.jumpapp
  #               pkgs.rwc
  #             ];

  #             text = ./modules/feeds.bash;
  #           };
  #         };

  #         mail = entryBefore [ "network" "power" "dates" ] {
  #           name = "mail";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-mail";

  #             runtimeInputs = [
  #               pkgs.mblaze
  #               pkgs.coreutils
  #               pkgs.jumpapp
  #               pkgs.gnused
  #               pkgs.rwc
  #             ];

  #             text = ./modules/mail.bash;
  #           };
  #         };

  #         network = entryBefore [ "rfkill" "power" ] {
  #           name = "network";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-network";

  #             runtimeInputs = [
  #               pkgs.networkmanager
  #               pkgs.gnused
  #             ];

  #             text = ./modules/network.bash;
  #           };
  #         };

  #         rfkill = entryAfter [ "network" ] {
  #           name = "rfkill";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-rfkill";

  #             runtimeInputs = [
  #               pkgs.rfkill
  #               pkgs.gnugrep
  #             ];

  #             text = ./modules/rfkill.bash;
  #           };
  #         };

  #         pulse = entryBefore [ "power" ] {
  #           name = "pulse";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-pulse";

  #             runtimeInputs = [
  #               pkgs.ponymix
  #               pkgs.pulseaudio
  #               pkgs.coreutils
  #               pkgs.pastel
  #             ];

  #             text = ./modules/pulse.bash;
  #           };
  #         };

  #         power = entryBefore [ "events" "dates" ] {
  #           name = "power";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-power";

  #             runtimeInputs = [
  #               pkgs.coreutils
  #               pkgs.upower
  #               pkgs.jc
  #               pkgs.jq
  #             ];

  #             text = ./modules/power.bash;
  #           };
  #         };

  #         events = entryBetween [ "power" ] [ "dates" ] {
  #           name = "events";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-events";

  #             runtimeInputs = [
  #               pkgs.khal
  #               pkgs.gnused
  #               pkgs.coreutils
  #               pkgs.gnugrep
  #               pkgs.ellipsis
  #               pkgs.snooze
  #             ];

  #             text = ./modules/events.bash;
  #           };
  #         };

  #         dates = entryAfter [ "events" ] {
  #           name = "dates";
  #           command = pkgs.writeShellApplication {
  #             name = "panel-dates";

  #             runtimeInputs = [
  #               pkgs.coreutils
  #               pkgs.dateutils
  #               pkgs.gnused
  #               pkgs.pastel
  #               pkgs.snooze
  #             ];

  #             text = ./modules/dates.bash;
  #           };

  #           runtimeInputs = [
  #             pkgs.brillo
  #             pkgs.systemctl
  #           ];
  #         };
  #       };
  #     };
  #   };
  # };

  home.packages = [
    # panel
    (pkgs.lemonbar-xft.overrideAttrs (prev: {
      pname = "lemonbar-xft";
      version = config.lib.somasis.flakeModifiedDateToVersion inputs.lemonbar;
      src = inputs.lemonbar;
    }))

    pkgs.procps
    pkgs.xdotool

    # panel-title
    pkgs.xtitle
    pkgs.xorg.xprop

    # panel-music
    pkgs.mpc-cli

    # panel-events
    pkgs.khal
    pkgs.pastel

    # panel-anki
    pkgs.rwc
    pkgs.procps
    # pkgs.apy
    pkgs.anki-bin

    # panel-articles
    pkgs.newsboat
    pkgs.procps
    pkgs.rwc

    # panel-mail
    # pkgs.mblaze
    pkgs.rwc

    # panel-clock
    pkgs.dateutils
    pkgs.pastel
    pkgs.snooze

    # panel-power
    pkgs.pastel
    pkgs.brillo
    pkgs.upower
    pkgs.jc

    # panel-pulse
    pkgs.ponymix
    pkgs.pulseaudio
    pkgs.pavucontrol

    # panel-sctd
    pkgs.systemd-wait

    # panel-tray
    # (pkgs.stalonetray.overrideAttrs (oldAttrs: finalAttrs: {
    #   version = "unstable-2023-08-31";

    #   src = pkgs.fetchFromGitHub {
    #     owner = "kolbusa";
    #     repo = "stalonetray";
    #     rev = "96e615af9728f2b60cc4f596f4675c8e61ef34b0";
    #     hash = "sha256-y8G7/xEOklG5pq3YhdTcxRIKAqFgFMamk3uo4ZA1WxU=";
    #   };
    # }))
    pkgs.stalonetray
    pkgs.snixembed
    pkgs.xorg.xwininfo
  ];

  programs.autorandr.hooks = {
    # preswitch.panel = "${pkgs.systemd}/bin/systemctl --user stop panel.service";
    # postswitch.panel = "${pkgs.systemd}/bin/systemctl --user start panel.service";
    postswitch.panel = builtins.toString (pkgs.writeShellScript "restart-panel" ''
      ${pkgs.systemd}/bin/systemctl --user is-active -q panel.service >/dev/null 2>&1 \
          && ${pkgs.systemd}/bin/systemctl --user restart panel.service
    '');
    postswitch.snixembed = builtins.toString (pkgs.writeShellScript "restart-snixembed" ''
      ${pkgs.systemd}/bin/systemctl --user is-active -q snixembed.service >/dev/null 2>&1 \
          && ${pkgs.systemd}/bin/systemctl --user restart snixembed.service
    '');
  };

  systemd.user.services = {
    panel = {
      Unit = {
        Description = "lemonbar(1) based panel";
        PartOf = [ "graphical-session-post.target" "tray.target" ];
        After = [ "window-manager.target" ];
        Wants = [ "window-manager.target" "tray.target" ];
        StartLimitInterval = 0;
      };
      Install.WantedBy = [ "graphical-session-post.target" "tray.target" ];

      Service = {
        Type = "notify";
        NotifyAccess = "all";

        ExecStart = [ "${config.home.homeDirectory}/bin/panel" ];
        ExecStartPost = [
          "${bspc} config top_padding ${builtins.toString bspwm.settings.top_padding}"
          # "${bspc} config border_width ${builtins.toString bspwm.settings.border_width}"
          "${bspc} config window_gap ${builtins.toString bspwm.settings.window_gap}"
        ];
        ExecStopPost = [
          "${bspc} config top_padding 0"
          # "${bspc} config border_width ${builtins.toString bspwm.settings.border_width}"
          "${bspc} config window_gap 0"
        ];

        Restart = "on-success";
        ExitType = "cgroup";
      };
    };

    snixembed = {
      Unit = {
        Description = pkgs.snixembed.meta.description;
        PartOf = [ "graphical-session.target" ];
        After = [ "panel.service" ];
      };
      Install.WantedBy = [ "graphical-session.target" "tray.target" ];

      Service = {
        # `--fork` means it'll fork *only* once ready.
        Type = "forking";
        ExecStart = [ "${pkgs.snixembed}/bin/snixembed --fork" ];
      };
    };
  };
}
