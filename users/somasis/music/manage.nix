{ pkgs
, lib
, config
, nixosConfig
, ...
}:
let
  musicSource = "${config.home.homeDirectory}/audio/library/source";
  musicLossless = "${config.home.homeDirectory}/audio/library/lossless";
  musicLossy = "${config.home.homeDirectory}/audio/library/lossy";

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
      trap 'echo' EXIT

      set -eu
      set -o pipefail

      umask 0077

      : "''${XDG_CONFIG_HOME:=$HOME/.config}"

      json=$(pass www/acoustid.org | jq -Rc '{ acoustid: { apikey: . } }')
      json+=$(
          pass www/musicbrainz.org/Somasis \
              | jq -Rc --arg user Somasis '{ musicbrainz: { user: $user, pass: . } }'
      )
      json+=$(
          pass spinoza.7596ff.com/airsonic/somasis \
              | jq -Rc --arg user somasis '{ subsonic: { user: $user, pass: . } }'
      )

      json=$(jq -sc 'add' <<<"$json")

      yq -y <<<"$json"
    '';
  });

  bencoder = (pkgs.python3Packages.buildPythonPackage rec {
    pname = "bencoder";
    version = "0.2.0";

    src = pkgs.python3Packages.fetchPypi {
      inherit pname version;
      hash = "sha256-rENvM/3X51stkFdJHSq+77VjHvsTyBNAPbCtsRq1L8I=";
    };

    buildInputs = with pkgs.python3Packages; [ setuptools ];

    meta = with pkgs.lib; {
      description = "A simple bencode decoder/encoder library in pure Python";
      homepage = "https://github.com/utdemir/${pname}";
      license = licenses.gpl2;
      maintainers = with maintainers; [ somasis ];
    };
  });

  gazelle-origin = (pkgs.python3Packages.buildPythonApplication rec {
    pname = "gazelle-origin";
    version = "3.0.0";

    src = pkgs.fetchFromGitHub {
      repo = pname;

      # owner = "x1ppy";
      # rev = "4bfffa575ace819b02d576e9f0b79d20335c03c5";
      # hash = "sha256-2FazeqwpRHVuvb5IuFUAvxh7541/xg965kw8dzCsRCI=";

      # Use the spinfast319 fork, since it seems that upstream is inactive
      owner = "spinfast319";
      rev = version;
      hash = "sha256-+yMKnfG2f+A1/MxSBFLaHfpCgI2m968iXqt+2QanM/c=";
    };

    buildInputs = with pkgs.python3Packages; [ setuptools ];
    propagatedBuildInputs = with pkgs.python3Packages; [
      bencoder
      pyyaml
      requests
    ];

    meta = with pkgs.lib; {
      description = "Gazelle origin.yaml generator";
      homepage = "https://github.com/spinfast319/${pname}";
      license = licenses.unfree; # TODO <https://github.com/x1ppy/beets-originquery/issues/3>
      maintainers = with maintainers; [ somasis ];
    };
  });
in
{
  home.packages = [
    (pkgs.writeShellScriptBin "gazelle-origin" ''
      ${gazelle-origin}/bin/gazelle-origin --env /dev/stdin "$@" <<EOF
      export ORIGIN_TRACKER="RED"
      export RED_API_KEY=$(pass ${nixosConfig.networking.fqdn}/gazelle-origin/redacted.ch)
      EOF
    '')

    pass-beets
  ];

  programs.beets = {
    enable = true;
    # package = (pkgs.beets.override {
    #   pluginOverrides = {
    #     # TODO: submit to nixpkgs
    #     # barcode = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.barcode ]; };
    #     # originquery = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.originquery ]; };
    #   };
    # });

    settings = rec {
      include = "${xdgRuntimeDir}/pass-beets.yaml";

      directory = "${musicLossless}";
      library = "${directory}/beets.db";

      sort_case_insensitive = false;

      plugins = [
        # "check"

        # TODO: submit to nixpkgs
        # "barcode"
        # "originquery"

        # acousticbrainz/acoustid: apikey comes from `pass-beets`
        "absubmit"
        "acousticbrainz"
        "chroma"

        # mbsubmit/mbsync: musicbrainz user/password comes from `pass-beets`
        "mbsubmit"
        "mbsync"

        "badfiles"
        "fromfilename"
        "lastgenre"
        "lyrics"
        "replaygain"
        "types"
      ]
      ++ lib.optional nixosConfig.services.airsonic.enable "subsonicupdate"
      ++ lib.optional config.services.mopidy.enable "mpdupdate"
      ;

      badfiles.check_on_import = true;

      replaygain.backend = "ffmpeg";

      musicbrainz = {
        genres = true;
        extra_tags = [ "year" "catalognum" "country" "media" "label" ];
      };

      types = {
        rating = "float";
        sample = "bool";
      };

      convert = {
        # auto = true;

        copy_album_art = true;
        embed = false;
        album_art_maxwidth = "1024";

        dest = "${musicLossy}";
        format = "opus";
        formats.opus = {
          command = "${pkgs.ffmpeg-full}/bin/ffmpeg -i $source -y -vn -acodec libopus -ab 96k -ar 48000 $dest";
          extension = "opus";
        };
      };

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
        default = "$albumartist - $album%if{$original_year, ($original_year)}/$track - $artist - $title";
        "singleton:true" = "_single/$artist/$title";
        "comp:true" = "_compilation/$albumartist - $title/$track - $artist - $title";
        "albumtype:soundtrack" = "_soundtracks/$albumartist - $album%if{$original_year, ($original_year)}/$track - $artist - $title";

        "sample:true" = "_samples/$albumartist - $album%if{$original_year, ($original_year)}/$track - $artist - $title";
      };
    }
    // lib.optionalAttrs nixosConfig.services.airsonic.enable { subsonic.url = nixosConfig.services.airsonic.virtualHost; }
    // lib.optionalAttrs config.services.mopidy.enable { mpd.host = config.services.mopidy.settings.mpd.hostname; }
    ;
  };

  systemd.user = {
    services.pass-beets = {
      Unit = {
        Description = "Authenticate `beets` using `pass`";
        PartOf = [ "default.target" ];
      };
      Install.WantedBy = [ "default.target" ];

      Service = {
        Type = "oneshot";
        RemainAfterExit = true;

        ExecStart = [ "${pass-beets}/bin/pass-beets" ];
        ExecStop = [ "${pkgs.coreutils}/bin/rm -f %t/pass-beets.conf" ];

        StandardOutput = "file:%t/pass-beets.yaml";
      };
    };
  } // (lib.optionalAttrs (builtins.elem "web" config.programs.beets.settings.plugins) {
    services.beets-web = {
      Unit = {
        Description = "beets' web interface";
        PartOf = [ "default.target" ];
      };
      Install.WantedBy = [ "default.target" ];

      Service = {
        Type = "simple";
        ExecStart = "${config.programs.beets.package}/bin/beet web";
      };
    };
  });
}
