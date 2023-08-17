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

  #   colors = let xres = config.xresources.properties; in {
  #     background = xres."*background";
  #     foreground = xres."*foreground";

  #     accent = xres."*colorAccent";
  #     black = xres."*color0";
  #     red = xres."*color1";
  #     green = xres."*color2";
  #     yellow = xres."*color3";
  #     blue = xres."*color4";
  #     magenta = xres."*color5";
  #     cyan = xres."*color6";
  #     white = xres."*color7";

  #     brightBlack = xres."*color8";
  #     brightRed = xres."*color9";
  #     brightGreen = xres."*color10";
  #     brightYellow = xres."*color11";
  #     brightBlue = xres."*color12";
  #     brightMagenta = xres."*color13";
  #     brightCyan = xres."*color14";
  #     brightWhite = xres."*color15";
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
    pkgs.anki

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
    pkgs.stalonetray
    pkgs.snixembed
    pkgs.xorg.xwininfo
  ];

  programs.autorandr.hooks = {
    preswitch.panel = "${pkgs.systemd}/bin/systemctl --user stop panel.service";
    postswitch.panel = "${pkgs.systemd}/bin/systemctl --user start panel.service";
  };

  systemd.user.services = {
    panel = {
      Unit = {
        Description = "lemonbar(1) based panel";
        PartOf = [ "graphical-session.target" "graphical-session-post.target" "tray.target" ];
        After = [ "picom.service" ];
        StartLimitInterval = 0;
      };
      Install.WantedBy = [ "graphical-session.target" "graphical-session-post.target" "tray.target" ];

      Service = {
        Type = "simple";
        ExecStart = [ "${config.home.homeDirectory}/bin/panel" ];
        ExecStartPost = [
          "${bspc} config top_padding ${builtins.toString bspwm.settings.top_padding}"
          "${bspc} config border_width ${builtins.toString bspwm.settings.border_width}"
          "${bspc} config window_gap ${builtins.toString bspwm.settings.window_gap}"
        ];
        ExecStopPost = [
          "${bspc} config top_padding 0"
          "${bspc} config border_width 0"
          "${bspc} config window_gap 0"
        ];

        Restart = "on-success";
      };
    };

    snixembed = {
      Unit = {
        Description = pkgs.snixembed.meta.description;
        PartOf = [ "tray.target" ];
        After = [ "panel.service" ];
      };
      Install.WantedBy = [ "tray.target" ];

      Service = {
        Type = "simple";
        ExecStart = [ "${pkgs.snixembed}/bin/snixembed" ];
      };
    };
  };
}
