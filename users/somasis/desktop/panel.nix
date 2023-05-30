{ config
, pkgs
, inputs
, ...
}:
let
  inherit (config.xsession.windowManager) bspwm;
  bspc = "${bspwm.package}/bin/bspc";
in
{
  home.packages = [
    # panel
    (pkgs.lemonbar-xft.overrideAttrs (
      let
        year = builtins.substring 0 4 inputs.lemonbar.lastModifiedDate;
        month = builtins.substring 4 2 inputs.lemonbar.lastModifiedDate;
        day = builtins.substring 6 2 inputs.lemonbar.lastModifiedDate;
      in
      prev:
      {
        pname = "lemonbar-xft";
        version = "unstable-${year}-${month}-${day}";
        src = inputs.lemonbar;
      }
    ))

    pkgs.procps

    # panel-title
    pkgs.xtitle
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
        PartOf = [ "graphical-session.target" "tray.target" ];
        StartLimitInterval = 0;
      };
      Install.WantedBy = [ "graphical-session.target" "tray.target" ];

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
