{ config
, pkgs
, ...
}:
{
  imports = [
    ../music/manage
    ../music/play.nix
  ];

  home.persistence."/persist${config.home.homeDirectory}".directories = [{ directory = "audio"; method = "symlink"; }];

  home.packages = [
    # pkgs.mpd
    # pkgs.mpdscribble
    pkgs.mpc-cli
    pkgs.cantata
  ];
}
