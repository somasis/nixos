{ config, pkgs, ... }:
{
  imports = [
    ../music/play.nix
  ];

  xdg.userDirs.music = "${config.home.homeDirectory}/audio/library";

  home.persistence."/persist${config.home.homeDirectory}".directories = [ "audio" ];

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
      musicDirectory = config.xdg.userDirs.music;
    };
  };
}
