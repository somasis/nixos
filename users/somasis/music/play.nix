{ nixosConfig
, lib
, pkgs
, config
, ...
}:
let
  # INI is shell-expanded as a heredoc, so be careful with special characters
  mpdscribbleConf = lib.generators.toINIWithGlobalSection { } {
    globalSection = {
      log = "-";
      host = config.services.mpd.network.listenAddress;
      port = builtins.toString config.services.mpd.network.port;
      verbose = 2;
    };

    sections = {
      "last.fm" = {
        journal = "${config.xdg.cacheHome}/mpdscribble/last.fm.journal";
        url = "https://post.audioscrobbler.com/";

        username = "kyliesomasis";
        password = "$(pass www/last.fm/kyliesomasis | tr -d '\n' | md5sum - | cut -d' ' -f1)";
      };

      "listenbrainz" = {
        journal = "${config.xdg.cacheHome}/mpdscribble/listenbrainz.journal";
        url = "http://proxy.listenbrainz.org";

        username = "Somasis";
        password = "$(pass ${nixosConfig.networking.fqdnOrHostName}/mpdscribble/listenbrainz.org)";
      };
    };
  };

  xdgRuntimeDir = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}";

  pass-mpdscribble = pkgs.writeShellApplication {
    name = "pass-mpdscribble";
    runtimeInputs = [
      config.programs.password-store.package
    ];

    text = ''
      cat <<EOF
      ${mpdscribbleConf}
      EOF
    '';
  };

  mpdscribble = pkgs.symlinkJoin {
    name = "mpdscribble";
    paths = [ pkgs.mpdscribble pass-mpdscribble ];
    buildInputs = [ pkgs.makeWrapper ];
    postBuild = ''
      wrapProgram $out/bin/mpdscribble \
          --add-flags '--conf <(pass-mpdscribble)'
    '';
  };
in
{
  xdg.userDirs.music = "${config.home.homeDirectory}/audio/library";

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
        metadata_to_use "${lib.concatStringsSep "," tags}"

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

  home.persistence = {
    "/cache${config.home.homeDirectory}".directories = [{ directory = "var/cache/mpdscribble"; method = "symlink"; }];
    "/persist${config.home.homeDirectory}".directories = [{ directory = "share/mpd"; method = "symlink"; }];
  };

  home.sessionVariables = {
    MPD_HOST = config.services.mpd.network.listenAddress;
    MPD_PORT = config.services.mpd.network.port;
  };

  home.packages = [ mpdscribble ];

  systemd.user.services.mpdscribble = {
    Unit = {
      Description = pkgs.mpdscribble.meta.description;
      PartOf = [ "default.target" ];
      After = [ "mpd.service" ];
    };
    Install.WantedBy = [ "default.target" "mpd.service" ];

    Service = {
      Type = "simple";
      ExecStart = [ "${mpdscribble}/bin/mpdscribble -D" ];
    };
  };

  services.mpdris2 = {
    inherit (config.services.mpd) enable;
    mpd = {
      inherit (config.services.mpd) musicDirectory;
      host = config.services.mpd.network.listenAddress;
    };
  };

  services.sxhkd.keybindings =
    let
      mpc-toggle = pkgs.writeShellScript "mpc-toggle" ''
        c=$(${pkgs.mpc-cli}/bin/mpc playlist | wc -l)
        [ "$c" -gt 0 ] || ${pkgs.mpc-cli}/bin/mpc add /
        ${pkgs.mpc-cli}/bin/mpc toggle
      '';
    in
    {
      # Music: {play/pause, stop, previous track, next track}
      "XF86AudioPlay" = "${mpc-toggle}";
      "XF86AudioStop" = "${pkgs.mpc-cli}/bin/mpc stop";
      "XF86AudioPrev" = "${pkgs.mpc-cli}/bin/mpc cdprev";
      "XF86AudioNext" = "${pkgs.mpc-cli}/bin/mpc next";

      # Music: toggle {consume, random} mode
      "super + XF86Audio{Prev,Play}" = "${pkgs.mpc-cli}/bin/mpc {consume,random}";
    };
}
