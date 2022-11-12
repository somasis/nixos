{ pkgs
, lib
, config
, nixosConfig
, ...
}:
let
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

      fail() {
          [[ "$1" -ne 0 ]] && printf 'pass-beets: "failed"\n' > "$XDG_RUNTIME_DIR/pass-beets.yaml"
      }

      trap 'fail $?' EXIT

      output=$(pass www/acoustid.org | jq -Rc '{ acoustid: { apikey: . } }')
      output+=$(
          pass www/musicbrainz.org/Somasis \
              | jq -Rc --arg user Somasis '{ musicbrainz: { user: $user, pass: . } }'
      )

      output=$(jq -sc 'add' <<<"$output")
      output=$(yq -y <<<"$output")

      cat > "$XDG_RUNTIME_DIR/pass-beets.yaml" <<EOF
      $output
      EOF
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
      homepage = "https://github.com/spinfast319/gazelle-origin";
      license = licenses.unfree; # TODO <https://github.com/x1ppy/beets-originquery/issues/3>
      maintainers = with maintainers; [ somasis ];
    };
  });

  beets-barcode = (pkgs.callPackage
    ({ lib, fetchFromGitHub, beets, python3Packages }:
      python3Packages.buildPythonApplication rec {
        pname = "beets-barcode";
        version = "unstable-2019-01-24";

        src = fetchFromGitHub {
          repo = pname;
          owner = "8h2a";
          rev = "ad18cace04873157a96c34a48e714874825db724";
          hash = "sha256-US34U8j+OefMXFSn91MW32FA2fAZLMcABbHW9R4EuU0=";
        };

        propagatedBuildInputs = with python3Packages; [
          pillow
          pyzbar
        ];

        nativeBuildInputs = [ beets ];

        meta = with lib; {
          description = "Use barcodes for album tagging";
          homepage = "https://github.com/8h2a/beets-barcode";
          license = licenses.mit;
          maintainers = with maintainers; [ somasis ];
        };
      })
    { beets = pkgs.beetsPackages.beets-minimal; }
  );

  beets-fetchartist = (pkgs.callPackage
    ({ lib, fetchFromGitHub, beets, python3Packages }:
      python3Packages.buildPythonApplication rec {
        pname = "beets-fetchartist";
        version = "unstable-2020-07-03";

        format = "other";

        src = fetchFromGitHub {
          repo = pname;
          owner = "dkanada";
          rev = "6ab1920d2ae217bf1c814cdeab220e6d09251aac";
          hash = "sha256-jPm4S02VOYuUgA3wSHX/gdhWIZXZ1k+yLnbui5J/VuU=";
        };

        propagatedBuildInputs = with python3Packages; [
          pylast
          requests
        ];

        nativeBuildInputs = [ beets ];

        installPhase = ''
          beetsplug=$(toPythonPath "$out")/beetsplug
          mkdir -p $beetsplug
          cp -r $src/beetsplug/* $beetsplug/
        '';

        meta = with lib; {
          description = "Artist images for beets";
          homepage = "https://github.com/dkanada/beets-fetchartist";
          maintainers = with maintainers; [ somasis ];
          license = licenses.mit;
        };
      })
    { }
  );

  beets-originquery = (pkgs.callPackage
    ({ lib, fetchFromGitHub, beets, python3Packages }:
      python3Packages.buildPythonApplication rec {
        pname = "beets-originquery";
        version = "1.0.2";

        src = fetchFromGitHub {
          repo = pname;
          owner = "x1ppy";
          rev = version;
          hash = "sha256-32S8Ik6rzw6kx69o9G/v7rVsVzGA1qv5pHegYDmTW68=";
        };

        propagatedBuildInputs = with python3Packages; [
          confuse
          jsonpath_rw
          pyyaml
        ];

        nativeBuildInputs = [ beets ];

        meta = with lib; {
          description = "Integrates origin.txt metadata into beets' MusicBrainz queries";
          homepage = "https://github.com/x1ppy/beets-originquery";
          maintainers = with maintainers; [ somasis ];
          license = licenses.unfree; # <https://github.com/x1ppy/beets-originquery/issues/3>
        };
      })
    { beets = pkgs.beetsPackages.beets-minimal; });

  library = {
    source = "${config.xdg.userDirs.music}/source";
    lossless = "${config.xdg.userDirs.music}/lossless";
    lossy = "${config.xdg.userDirs.music}/lossy";
  };
in
{
  _module.args = { inherit library; };

  imports = [
    # ./extrafiles.nix
    # ./originquery.nix
    ./convert.nix
    ./ripping.nix
    ./tagging.nix
  ];

  home.packages = [
    (pkgs.writeShellScriptBin "gazelle-origin" ''
      export ORIGIN_TRACKER="RED"
      export RED_API_KEY=$(pass ${nixosConfig.networking.fqdn}/gazelle-origin/redacted.ch)
      ${gazelle-origin}/bin/gazelle-origin "$@"
    '')
    pass-beets
  ];

  programs.beets = {
    enable = true;
    package = (pkgs.beets.override {
      pluginOverrides = {
        barcode = { enable = true; propagatedBuildInputs = [ beets-barcode ]; };
        extrafiles = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.extrafiles ]; };
        fetchartist = { enable = true; propagatedBuildInputs = [ beets-fetchartist ]; };
        originquery = { enable = true; propagatedBuildInputs = [ beets-originquery ]; };
      };
    });

    settings = {
      include = [ "${xdgRuntimeDir}/pass-beets.yaml" ];

      directory = "${library.lossless}";
      library = "${library.lossless}/beets.db";

      # Default `beet list` options
      sort_case_insensitive = false;
      sort_item = "artist+ date+ album+ disc+ track+";
      sort_album = "artist+ date+ album+ disc+ track+";
      format_item = "$added\t$artist\t$album\t$title%if{$date,\t$date}";
      format_album = "$added\t$albumartist\t$album%if{$date,\t$date}";

      plugins = (lib.optional config.services.mopidy.enable "mpdupdate");
    }
    // lib.optionalAttrs config.services.mopidy.enable { mpd.host = config.services.mopidy.settings.mpd.hostname; };
  };

  programs.bash = {
    shellAliases."beet-import-all" = "beet import --flat --timid ${lib.escapeShellArg library.source}/*/*";

    initExtra = ''
      beet() (
          local e=0
          trap ":" INT
          command beet "$@"; e=$?
          trap - INT
          return $e
      )
    '';
  };

  systemd.user.services.pass-beets = {
    Unit = {
      Description = "Authenticate `beets` using `pass`";
      After = [ "gpg-agent.service" ];
      PartOf = [ "default.target" ];
    };
    Install.WantedBy = [ "default.target" ];

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = [ "${pass-beets}/bin/pass-beets" ];
      ExecStop = [ "${pkgs.coreutils}/bin/rm -f %t/pass-beets.yaml" ];
    };
  };
}