{ config
, pkgs
, ...
}:
# let
#   wineasio = pkgs.callPackage ../../pkgs/wineasio { };
# in
{
  home.packages = [
    # Necessary for FL Studio
    pkgs.wineWowPackages.stableFull
    # pkgs.wineWowPackages.waylandFull
    pkgs.winetricks
    # wineasio
  ];

  # Disable Wine's fixme messages.
  home.sessionVariables.WINEDEBUG = "fixme-all";

  xsession.windowManager.bspwm.rules."fl.exe:*:FL Studio 20".state = "tiled";

  # TODO: wineasio doesn't work :(
  # home.sessionVariables."WINEDLLPATH" = "${config.home.homeDirectory}/var/cache/wine/wine64";
  # home.file."var/cache/wine/wine32/wineasio.dll".source = "${wineasio}/lib/wine/i386-windows/wineasio.dll";
  # home.file."var/cache/wine/wine32/wineasio.dll.so".source = "${wineasio}/lib/wine/i386-unix/wineasio.dll.so";
  # home.file."var/cache/wine/wine64/wineasio.dll".source = "${wineasio}/lib/wine/x86_64-windows/wineasio.dll";
  # home.file."var/cache/wine/wine64/wineasio.dll.so".source = "${wineasio}/lib/wine/x86_64-unix/wineasio.dll.so";

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    "etc/wine"
    "share/wine"
  ];
}
