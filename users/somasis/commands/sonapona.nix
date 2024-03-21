{ config
, pkgs
, ...
}: {
  home.packages = [
    pkgs.comic-mono
    pkgs.sonapona
  ];

  persist.directories = [{
    method = "symlink";
    directory = config.lib.somasis.xdgDataDir "sonapona";
  }];

  services.stw.widgets.sonapona = {
    text = {
      font = "Comic Mono:style=bold:size=10";
      color = config.theme.colors.darkForeground;
    };

    window = {
      color = config.theme.colors.darkBackground;
      opacity = 0.25;

      position = {
        x = -24;
        y = -24;
      };

      padding = 12;
    };

    update = 60;

    command = "sonapona";
  };

  # sometimes stw can fail?
  systemd.user.services.stw-sonapona.Service.Restart = "on-failure";
}
