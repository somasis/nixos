{ config
, lib
, pkgs
, ...
}:
{
  home.packages = [
    (pkgs.wrapCommand {
      name = "zoom-us";

      package = pkgs.zoom-us;
      wrappers = [{
        command = "/bin/zoom";
        setEnvironment.XDG_SESSION_TYPE = "X11";
      }];
    })
  ];

  persist = {
    directories = [ ".zoom" ];
    files = [ "etc/zoomus.conf" ];
  };
  cache.files = [ "etc/zoom.conf" ];

  xsession.windowManager.bspwm.rules = {
    "zoom:*:zoom_linux_float_message_reminder" = {
      layer = "above";
      sticky = true;
    };
  };

  # systemd.user.services.zoom = {
  #   Unit = {
  #     Description = pkgs.zoom-us.meta.description;
  #     PartOf = [ "graphical-session.target" ];
  #     After = [ "graphical-session-pre.target" "tray.target" ];
  #     Requires = [ "tray.target" ];
  #   };
  #   Install.WantedBy = [ "graphical-session.target" ];


  #   Service = {
  #     Type = "simple";
  #     # NotifyAccess = "all";

  #     ExitType = "cgroup";
  #     ExecStart = lib.getExe pkgs.zoom-us;
  #     # ExecStartPost = pkgs.writeShellScript "zoom-start-post" ''
  #     #   set -o pipefail
  #     #   set -x

  #     #   ${config.xsession.windowManager.bspwm.package}/bin/bspc rule -a 'zoom' -o follow=off hidden=on

  #     #   ${pkgs.xtitle}/bin/xtitle -s -f '%u\n' \
  #     #       | while IFS=$'\t' read -r node; do
  #     #           class=$(${pkgs.xdotool}/bin/xdotool getwindowclassname "$node")
  #     #           title=$(${pkgs.xtitle}/bin/xtitle "$node")

  #     #           case "''${class,,}:''${title,,}" in
  #     #               'zoom:zoom - '*)
  #     #                   ${config.xsession.windowManager.bspwm.package}/bin/bspc node "$node" -c
  #     #                   exit
  #     #                   # exec ${pkgs.systemd}/bin/systemd-notify --ready
  #     #                   ;;
  #     #           esac
  #     #       done
  #     # '';

  #     Restart = "on-abnormal";
  #   };
  # };

  # xdg.configHome."etc/zoomus.conf".source = pkgs.generators.toINI {} {
  #   General = {
  #     ScaleFactor = 1.5;
  #     autoPlayGif = false;
  #     autoScale = false;
  #     captureHDCamera = true;
}
