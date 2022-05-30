{ pkgs, ... }: {
  programs.gamemode = {
    enable = true;

    settings.general = {
      renice = "19";
      inhibit_screensaver = "0";
    };
  };

  programs.steam.enable = true;
  environment.systemPackages = [ pkgs.protonup ];
}
