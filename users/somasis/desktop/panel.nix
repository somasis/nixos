{ config
, pkgs
, ...
}:
let
  inherit (config.xsession.windowManager) bspwm;
  bspc = "${bspwm.package}/bin/bspc";
in
{
  home.packages = [
    # panel
    (pkgs.lemonbar-xft.overrideAttrs (prev: {
      patches = [
        (pkgs.fetchpatch {
          url = "https://github.com/somasis/lemonbar-xft/commit/2f1243f8d401ad48e55e7ea294362be1e75b31c8.patch";
          hash = "sha256-qXEolq1Y5FaCIVHlacIsJY7/fcJrnZgklgOguXdiTlM=";
        })
      ];
    }))

    pkgs.procps

    # panel-title
    pkgs.xtitle
    pkgs.xdotool

    # panel-music
    pkgs.mpc-cli

    # panel-events
    # TODO pkgs.khal
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
  ];

  programs.autorandr.hooks = {
    preswitch."panel" = "${pkgs.systemd}/bin/systemctl --user stop panel.service";
    postswitch."panel" = "${pkgs.systemd}/bin/systemctl --user start panel.service";
  };

  systemd.user.services.panel = {
    Unit = {
      Description = "lemonbar(1) based panel";
      PartOf = [ "chrome.target" ];
    };
    Install.WantedBy = [ "chrome.target" ];

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

    Unit.StartLimitInterval = 0;
  };
}
