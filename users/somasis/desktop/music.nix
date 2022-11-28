{ config
, pkgs
, music
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

  systemd.user.tmpfiles.rules = [
    "L+ ${music.source} - - - - ${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com/audio/library/source"
    "L+ ${music.lossless} - - - - ${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com/audio/library/lossless"
  ];

  home.packages = [
    # pkgs.mpd
    # pkgs.mpdscribble
    pkgs.mpc-cli
    pkgs.cantata
  ];
}
