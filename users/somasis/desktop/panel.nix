{ config
, pkgs
, ...
}: {
  home.packages = [
    # panel
    pkgs.lemonbar-xft
    pkgs.bspwm
    pkgs.procps

    # panel-bspwm
    pkgs.bspwm

    # panel-title
    pkgs.xtitle
    pkgs.bspwm
    pkgs.xdotool

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
    Unit.Description = "lemonbar(1) based panel";
    Install.WantedBy = [ "root-windows.target" ];
    Unit.PartOf = [ "root-windows.target" ];
    Service.Type = "simple";
    Service.ExecStart = "${config.home.homeDirectory}/bin/panel";
    Service.ExecStartPost = "${pkgs.bspwm}/bin/bspc config -m primary top_padding 48";
    Service.ExecStopPost = "${pkgs.bspwm}/bin/bspc config -m primary top_padding 0";
    Unit.StartLimitInterval = 0;
    Service.Restart = "on-failure";
  };
}
