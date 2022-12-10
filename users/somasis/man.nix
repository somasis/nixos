{ config
, pkgs
, ...
}: {
  home.packages = [
    pkgs.man-pages
    pkgs.man-pages-posix
    pkgs.stdman

    pkgs.execline-man-pages
    pkgs.s6-man-pages
    pkgs.s6-networking-man-pages
    pkgs.s6-portable-utils-man-pages
  ];

  # TODO Submit a proper fix for using mandoc as the man provider to home-manager upstream
  programs.man.package = pkgs.mandoc;
  home.sessionVariables = {
    MANPATH = ":${config.home.profileDirectory}/share/man";
    MANWIDTH = 80;
  };
}
