{ config
, pkgs
, ...
}: {
  home.packages = [
    # panel
    pkgs.lemonbar-xft
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
    pkgs.rwc
    pkgs.inotify-tools
    pkgs.pastel
    pkgs.brillo

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

    Service =
      let
        bspc = "${config.xsession.windowManager.bspwm.package}/bin/bspc";
        settings = config.xsession.windowManager.bspwm.settings;
      in
      {
        Type = "simple";
        ExecStart = [ "${config.home.homeDirectory}/bin/panel" ];
        ExecStartPost = [
          "${bspc} config top_padding ${builtins.toString settings.top_padding}"
          "${bspc} config border_width ${builtins.toString settings.border_width}"
          "${bspc} config window_gap ${builtins.toString settings.window_gap}"
        ];
        ExecStopPost = [
          "${bspc} config top_padding 0"
          "${bspc} config border_width 0"
          "${bspc} config window_gap 0"
        ];

        Restart = "on-failure";
      };

    Unit.StartLimitInterval = 0;
  };
}
