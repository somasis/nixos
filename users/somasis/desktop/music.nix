{ config
, pkgs
, ...
}:
{
  imports = [
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

  services.mpdris2 = {
    enable = config.services.mopidy.enable;
    mpd = {
      host = config.services.mopidy.settings.mpd.hostname;
      musicDirectory = config.services.mopidy.settings.file.media_dirs;
    };
  };
}
