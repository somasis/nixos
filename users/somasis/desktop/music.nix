{ config
, pkgs
, ...
}:
{
  imports = [
    ../music
    ../music/manage
    ../music/play.nix
  ];

  xdg.userDirs.music = "${config.home.homeDirectory}/audio/library";

  home.persistence."/persist${config.home.homeDirectory}".directories = [{ directory = "audio"; method = "symlink"; }];

  home.packages = [
    # pkgs.mpd
    # pkgs.mpdscribble
    pkgs.mpc-cli
    pkgs.cantata
  ];
}
