{ config
, pkgs
, nixosConfig
, inputs
, ...
}:
let
  # wineasio = pkgs.callPackage ../../pkgs/wineasio { };
  # flstudio = pkgs.callPackage ../../../pkgs/flstudio {
  #   mkWindowsApp = inputs.erosanix.lib.${nixosConfig.nixpkgs.system}.mkWindowsApp;
  #   wine = pkgs.wineWowPackages.stableFull;
  # };
in
{
  home.packages = [
    pkgs.winetricks
    pkgs.wineWowPackages.stagingFull
    pkgs.wineasio
  ];

  # Disable Wine's fixme messages.
  home.sessionVariables.WINEDEBUG = "fixme-all";

  xsession.windowManager.bspwm.rules."fl.exe:*:FL Studio 20".state = "tiled";

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "etc/wine"
    "share/wine"

    # "etc/mkWindowsApp"
    # "share/flstudio"
  ];
}
