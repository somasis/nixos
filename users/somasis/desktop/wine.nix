{ config
, pkgs
, nixosConfig
, ...
}:
{
  home.packages = [
    pkgs.winetricks
    pkgs.wineWowPackages.stagingFull
    pkgs.wineasio
  ];

  # Disable Wine's fixme messages.
  home.sessionVariables.WINEDEBUG = "fixme-all";

  xsession.windowManager.bspwm.rules."fl64.exe:*:FL Studio 21".state = "tiled";

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "etc/wine"
    { directory = "share/wine"; method = "symlink"; }
  ];
}
