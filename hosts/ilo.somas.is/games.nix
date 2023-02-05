{ pkgs, ... }: {
  programs.gamemode = {
    enable = true;

    settings.general = {
      renice = "19";
      inhibit_screensaver = "0";
    };
  };

  # TODO programs.steam.enable = false;
  environment.systemPackages = [ pkgs.protonup ];
}
