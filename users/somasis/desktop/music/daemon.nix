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
        auto_update_depth "3"

        audio_output {
            type "pulse"
            name "PulseAudio"
        }
      '';
  };

  # Copied from mpd's distributed systemd service.
  systemd.user.services.mpd.Service = {
    LimitRTPRIO = 40;
    LimitRTTIME = "infinity";
    LimitMEMLOCK = "64M";

    ProtectSystem = true;

    NoNewPrivileges = true;
    ProtectKernelTunables = true;
    ProtectControlGroups = true;
    RestrictAddressFamilies = [ "AF_INET" "AF_INET6" "AF_UNIX" "AF_NETLINK" ];
    RestrictNamespaces = true;
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

  persist.directories = [{ method = "symlink"; directory = config.lib.somasis.xdgDataDir "mpd"; }];
}
