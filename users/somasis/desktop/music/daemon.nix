{ config
, lib
, pkgs
, ...
}:
let
  inherit (config.lib.somasis) commaList;
in
{
  services.mpd = {
    enable = true;

    musicDirectory = "${config.xdg.userDirs.music}/lossy";
    playlistDirectory = "${config.xdg.userDirs.music}/playlists";

    extraConfig =
      let
        tags = [
          "title"
          "track"
          "album"
          "albumartist"
          "artist"
          "performer"
          "composer"
          "date"
          "genre"
          "label"
          "disc"
          "musicbrainz_artistid"
          "musicbrainz_albumid"
          "musicbrainz_albumartistid"
          "musicbrainz_trackid"
          "musicbrainz_releasetrackid"
          "musicbrainz_workid"
        ];
      in
      ''
        metadata_to_use "${commaList tags}"

        auto_update "yes"
        auto_update_depth "1"

        audio_output {
          type "pulse"
          name "PulseAudio"
          format "48000:24:2"
          replay_gain_handler "mixer"
        }
      '';
  };

  services.mpdris2 = {
    inherit (config.services.mpd) enable;
    mpd = {
      inherit (config.services.mpd) musicDirectory;
      host = config.services.mpd.network.listenAddress;
    };
  };

  services.mpris-proxy.enable = true;

  home.packages = [ pkgs.mpc-cli ];

  persist.directories = [{ method = "symlink"; directory = "share/mpd"; }];
}
