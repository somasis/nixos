{ config, ... }:
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
      hash = "sha256-bFUadSJ8eV3y9I9udQsDukLk6kKKW610zn4aIYxhZ5w=";
    };

    buildInputs = with pkgs.python3Packages; [ setuptools ];
    propagatedBuildInputs = with pkgs.python3Packages; [
      bencoder
      pyyaml
      requests
    ];

    meta = with pkgs.lib;      {
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
    package = (pkgs.beets.override {
      pluginOverrides = {
        # check = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.check ]; };
        barcode = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.barcode ]; };
        originquery = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.originquery ]; };
      };
    });

    settings = rec {
      library = "${config.programs.beets.settings.directory}/beets.db";
      directory = "${musicLossless}";

      include = "${xdgRuntimeDir}/pass-beets/beets.yml";

      sort_case_insensitive = false;

      plugins = [
        # "check"
        # "web"
        "barcode"
        "originquery"

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
        # auto = true;

        copy_album_art = true;
        embed = false;
        album_art_maxwidth = "1024";
        quiet = true;

        format = "opus";
        formats = {
          opus.command = "ffmpeg -i $source -y -vn -acodec libopus -ab 96k -ar 48000 $dest";
          opus.extension = "opus";
        };
      };

      originquery = {
        origin_file = "origin.yaml";
        tag_patterns = {
          media = ''$.Media'';
          year = ''$."Edition year"'';
          label = ''$."Record label"'';
          catalognum = ''$."Catalog number"'';
          albumdisambig = ''$.Edition'';
        };
      };

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
        ExecStop = [ "${pkgs.coreutils}/bin/rm -rf %t/pass-beets" ];

        StandardOutput = "file:${xdgRuntimeDir}/pass-beets/beets.yaml";
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
