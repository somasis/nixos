{ config
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

  # xdg.configHome."etc/zoomus.conf".source = pkgs.generators.toINI {} {
  #   General = {
  #     ScaleFactor = 1.5;
  #     autoPlayGif = false;
  #     autoScale = false;
  #     captureHDCamera = true;
}
