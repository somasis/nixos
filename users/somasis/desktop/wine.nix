{ config
, pkgs
, osConfig
, ...
}: {
  home.packages = [
    pkgs.winetricks
    pkgs.wineWowPackages.stagingFull
    pkgs.wineasio
  ];

  # Disable Wine's fixme messages.
  home.sessionVariables.WINEDEBUG = "fixme-all";

  xsession.windowManager.bspwm.rules."fl64.exe:*:FL Studio 21".state = "tiled";

  persist.directories = [
    "etc/wine"
    { method = "symlink"; directory = "share/wine"; }
  ];
}
