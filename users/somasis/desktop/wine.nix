{ config
, pkgs
, osConfig
, ...
}: {
  home.packages = [
    pkgs.winetricks
    pkgs.wineWowPackages.stable
    # pkgs.wineasio
  ];

  # Disable Wine's fixme messages.
  home.sessionVariables.WINEDEBUG = "fixme-all";

  xsession.windowManager.bspwm.rules."fl64.exe".state = "tiled";

  persist.directories = [
    "etc/wineprefixes"
    { method = "symlink"; directory = config.lib.somasis.xdgDataDir "wineprefixes"; }
  ];
}
