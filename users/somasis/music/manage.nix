{ config, ... }:
let
  musicSource = "${config.home.homeDirectory}/audio/source";
  musicLossless = "${config.home.homeDirectory}/audio/lossless";
  musicLossy = "${config.home.homeDirectory}/audio/lossy";

  xdgRuntimeDir = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}";

  pass-beets = (pkgs.writeShellApplication {
    name = "pass-beets";
    runtimeInputs = [
      config.programs.jq.package
      config.programs.password-store.package
      pkgs.coreutils
      pkgs.yq
    ];

    text = ''
      set -eu
      set -o pipefail

      umask 0077

      : "''${XDG_CONFIG_HOME:=$HOME/.config}"
      : "''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}"
      runtime="''${XDG_RUNTIME_DIR}/pass-beets"

      [ -d "$runtime" ] || mkdir -m 700 "$runtime"
      pass www/acoustid.org \
          | jq -R "{ acoustid: { apikey: . }" \
          | yq -y > "$runtime"/acoustid.yml

      pass www/musicbrainz.org/Somasis \
          | jq -R \
              --arg user "Somasis" \
              '{ user: $user, pass: . }' \
          | yq -y > "$runtime"/musicbrainz.yml

      yq -y \
          -n \
          --arg runtime "$runtime" \
          '{ include: [
              "\($runtime)/acoustid.yml",
              "\($runtime)/musicbrainz.yml"
          }' \
          >> "$runtime"/beets.yml
    '';
  });
in
{
  home.packages = [
    pass-beets
  ];

  programs.beets = {
    enable = true;
    # package =
    #   (pkgs.beets.override {
    #     pluginOverrides = {
    #       # originquery = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.originquery ]; };
    #       # check = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.check ]; };
    #       barcode = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.barcode ]; };
    #     };
    #   });

    settings = rec {
      library = "${config.programs.beets.settings.directory}/beets.db";
      directory = "${musicLossless}";

      include = "${xdgRuntimeDir}/pass-beets/beets.yml";

      sort_case_insensitive = false;

      plugins = [
        # "barcode"
        # "check"
        # "originquery"
        # "web"

        # acousticbrainz/acoustid: apikey comes from `pass-beets`
        "acousticbrainz"
        "absubmit"
        "chroma"

        # mbsubmit/mbsync: musicbrainz user/password comes from `pass-beets`
        "mbsubmit"
        "mbsync"

        "badfiles"
        "fromfilename"
        "lastgenre"
        "lyrics"
        "replaygain"
      ]
      ++ lib.optional config.services.mopidy.enable "mpdupdate"
      ;

      badfiles.check_on_import = true;

      replaygain.backend = "ffmpeg";

      musicbrainz = {
        genres = true;
        extra_tags = [ "year" "catalognum" "country" "media" "label" ];
      };

      convert = {


        # originquery = {
        #   origin_file = "origin.yaml";
        #   tag_patterns = {
        #     media = ''$.Media'';
        #     year = ''$."Edition year"'';
        #     label = ''$."Record label"'';
        #     catalognum = ''$."Catalog number"'';
        #     albumdisambig = ''$.Edition'';
        #   };
        # };

        import = {
          # Search
          languages = [ "tok" "en" "jp" ];

          # Interactive mode
          bell = true;
          detail = true;
          timid = true;

          # File manipulation
          write = true;
          copy = true;
          move = false;

          incremental = true;
          resume = false;
        };

        match = {
          # distance_weights.barcode = 1.0;

          max_rec = {
            missing_tracks = "medium";
            unmatched_tracks = "medium";
            tracks = "medium";
          };
        };

        paths = {
          # _$albumtype/
          default = "$albumartist - $album%if{$original_year, ($original_year)}/$track - $artist - $title";
          "singleton:true" = "_single/$artist/$title";
          "comp:true" = "_compilation/$albumartist - $title/$track - $artist - $title";
          "albumtype:soundtrack" = "_soundtracks/$albumartist - $album%if{$original_year, ($original_year)}/$track - $artist - $title";
        };
      }
      // lib.optionalAttrs config.services.mopidy.enable { mpd.host = config.services.mopidy.settings.mpd.hostname; }
      ;
    };

    systemd.user.services."pass-beets" = {
      Unit = {
        Description = "Authenticate `beets` using `pass`";
        PartOf = [ "default.target" ];
      };
      Install.WantedBy = [ "default.target" ];

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = [ "${pass-beets}/bin/pass-beets" ];
        ExecStop = [ "${pkgs.coreutils}/bin/rm -rf %t/pass-beets" ];
      };
    };

    # systemd.user.services.beets-web = {
    #   Unit.Description = "beets' web interface";
    #   Install.WantedBy = [ "default.target" ];
    #   Unit.PartOf = [ "default.target" ];
    #   Service.Type = "simple";
    #   Service.ExecStart = "${config.programs.beets.package}/bin/beet web";
    # };
  }
