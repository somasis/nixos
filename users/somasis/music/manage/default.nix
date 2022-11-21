{ pkgs
, lib
, config
, nixosConfig
, ...
}:
let
  music = {
    source = "${config.xdg.userDirs.music}/source";
    lossless = "${config.xdg.userDirs.music}/lossless";
    lossy = "${config.xdg.userDirs.music}/lossy";
  };

  bandcamp-collection-downloader = (pkgs.callPackage
    ({ lib, stdenvNoCC, fetchurl, jre, makeWrapper }:
      stdenvNoCC.mkDerivation rec {
        pname = "bandcamp-collection-downloader";
        version = "2021-12-05";

        src = fetchurl {
          url = "https://framagit.org/Ezwen/bandcamp-collection-downloader/-/jobs/1515933/artifacts/raw/build/libs/bandcamp-collection-downloader.jar";
          hash = "sha256-nmnPu+E6KgQpwH66Cli0gbDU4PzQQXEscXPyYYkkJC4=";
        };
        dontUnpack = true;

        nativeBuildInputs = [ makeWrapper ];

        # src = fetchFromGitLab {
        #   domain = "framagit.org";
        #   owner = "Ezwen";
        #   rev = "v${version}";
        #   hash = "sha256-uvfpTFt92mp4msm06Y/1Ynwx6+DiE+bR8O2dntTzj9I=";
        # };

        jar = "${placeholder "out"}/lib/bandcamp-collection-downloader/bandcamp-collection-downloader.jar";

        buildPhase = ''
          install -D -m 0755 $src $jar
        '';

        installPhase = ''
          makeWrapper ${jre}/bin/java $out/bin/bandcamp-collection-downloader \
              --argv0 bandcamp-collection-downloader \
              --add-flags "-jar $jar" \
        '';

        meta = with lib; {
          description = "Tool for automatically downloading releases purchased with a Bandcamp account";
          homepage = "https://framagit.org/Ezwen/bandcamp-collection-downloader";
          license = licenses.agpl3;
          maintainers = with maintainers; [ somasis ];
        };
      })
    { });

  pass-beets = (pkgs.writeShellApplication {
    name = "pass-beets";
    runtimeInputs = [
      config.programs.jq.package
      config.programs.password-store.package
      pkgs.yq
    ];

    text = ''
      fail() {
          [[ "$1" -ne 0 ]] && printf 'pass-beets: "failed"\n'
      }

      trap 'fail $?' ERR

      output=$(pass www/acoustid.org | jq -Rc '{ acoustid: { apikey: . } }')
      output+=$(
          pass www/musicbrainz.org/Somasis \
              | jq -Rc --arg user Somasis '{ musicbrainz: { user: $user, pass: . } }'
      )

      jq -sc 'add' <<<"$output" | yq -y
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

  beetcamp = (pkgs.callPackage
    ({ lib, fetchFromGitHub, beets, python3Packages }:
      python3Packages.buildPythonApplication rec {
        pname = "beetcamp";
        version = "0.16.0";

        format = "pyproject";

        src = fetchFromGitHub {
          repo = pname;
          owner = "snejus";
          rev = version;
          hash = "sha256-AX5Z6MODr28dWF9NrT394F+fmW5btRBQvb0E8WmDa70=";
        };

        propagatedBuildInputs = with python3Packages; [
          cached-property
          ordered-set
          poetry-core
          pycountry
          python-dateutil
          requests
        ];

        # checkInputs = with python3Packages; [
        #   pytest
        #   pytest-cov
        #   pytest-randomly
        #   pytest-clarify
        #   pytest-lazy-fixture
        #   rich
        # ];

        # doCheck = true;

        nativeBuildInputs = [ beets ];

        meta = with lib; {
          description = "Use Bandcamp as a autotagger source for beets";
          homepage = "https://github.com/snejus/beetcamp";
          maintainers = with maintainers; [ somasis ];
          license = licenses.gpl2;
        };
      })
    { beets = pkgs.beetsPackages.beets-minimal; });

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
    { beets = pkgs.beetsPackages.beets-minimal; });

  beets-noimport = (pkgs.callPackage
    ({ lib, fetchFromGitLab, beets, python3Packages }:
      python3Packages.buildPythonApplication rec {
        pname = "beets-noimport";
        version = "0.1.0b5";

        src = fetchFromGitLab {
          repo = pname;
          owner = "tiago.dias";
          rev = "v${version}";
          hash = "sha256-7N7LiOdDZD/JIEwx7Dfl58bxk4NEOmUe6jziS8EHNcQ=";
        };

        nativeBuildInputs = [ beets ];

        meta = with lib; {
          description = ''Add directories to the incremental import "do not import" list'';
          homepage = "https://gitlab.com/tiago.dias/beets-noimport";
          maintainers = with maintainers; [ somasis ];
          license = licenses.mit;
        };
      })
    { beets = pkgs.beetsPackages.beets-minimal; });

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

  beets = (pkgs.beets.override {
    pluginOverrides = {
      # beetcamp = { enable = true; propagatedBuildInputs = [ beetcamp ]; };
      extrafiles = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.extrafiles ]; };
      fetchartist = { enable = true; propagatedBuildInputs = [ beets-fetchartist ]; };
      noimport = { enable = true; propagatedBuildInputs = [ beets-noimport ]; };
      originquery = { enable = true; propagatedBuildInputs = [ beets-originquery ]; };
    };
  });
in
{
  _module.args = { inherit music; };

  imports = [
    ./convert.nix
    ./extrafiles.nix
    ./ripping.nix
    ./tagging.nix
  ];

  home.packages = [
    bandcamp-collection-downloader

    (pkgs.symlinkJoin {
      name = "gazelle-origin-final";

      buildInputs = [ pkgs.makeWrapper ];
      paths = [ gazelle-origin ];

      postBuild = ''
        wrapProgram $out/bin/gazelle-origin \
            --set-default "ORIGIN_TRACKER" "RED" \
            --run ': "''${RED_API_KEY:=$(${config.programs.password-store.package}/bin/pass ${nixosConfig.networking.fqdn}/gazelle-origin/redacted.ch)}"' \
            --run 'export RED_API_KEY'
      '';
    })

    pass-beets
  ];

  systemd.user.tmpfiles.rules = [
    "L+ ${music.source} - - - - ${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com/audio/library/source"
    "L+ ${music.lossless} - - - - ${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com/audio/library/lossless"
  ];

  programs.beets = {
    enable = true;
    package =
      (beets.overrideAttrs (oldAttrs: rec {
        # Provide a wrapper for the actual `beet` program, so that we can perform some
        # pre-command-initialization actions.
        # <https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages>
        runtimeInputs = oldAttrs.runtimeInputs or [ ] ++ [
          pass-beets
          pkgs.coreutils
          pkgs.systemd
        ];

        postInstall = oldAttrs.postInstall + ''
          mv $out/bin/beet $out/bin/.beet-wrapped

          touch $out/bin/beet
          chmod +x $out/bin/beet

          cat > $out/bin/beet <<'EOF'
          #! ${pkgs.runtimeShell}
          set -eu
          set -o pipefail

          ${lib.toShellVar "PATH" (lib.makeBinPath runtimeInputs)}":${placeholder "out"}:$PATH"

          # Mount any required mount units
          ${lib.toShellVar "directory" config.programs.beets.settings.directory}
          directory=$(readlink -m "$directory")
          directory_escaped=$(systemd-escape -p "$directory")

          user_mount_units=$(systemctl --user --plain --full --all --no-legend list-units -t mount | cut -d' ' -f1)

          # Work through the parts of the escaped path and find the longest
          # unit name prefix match.
          # 1. Split apart the escaped path
          # 2. Accumulate parts for each run of the `for` loop
          # 3. Read in the list of user mount units
          # The longest matching one will be the final line.
          unit=$(
              directory_acc=
              IFS=-
              for directory_part in $directory_escaped; do
                  directory_acc="''${directory_acc:+$directory_acc-}$directory_part"

                  while IFS="" read -r unit; do
                      case "$unit" in
                          "$directory_acc"*.mount) printf '%s\n' "$unit"; break ;;
                      esac
                  done <<< "$user_mount_units"
              done | tail -n1
          )

          [[ -n "$unit" ]] && systemctl --user start "$unit"

          e=0
          trap : INT

          # Feed pass-beets info via a FIFO so it never hits the disk.
          (exec -a beet ${placeholder "out"}/bin/.beet-wrapped -c <(pass-beets) "$@") || e=$?

          trap - INT
          exit $?
          EOF
        '';
      })
      );

    settings =
      let inherit music;
      in {
        directory = "${music.lossless}";
        library = "${music.lossless}/beets.db";

        # Default `beet list` options
        sort_case_insensitive = false;
        sort_item = "artist+ date+ album+ disc+ track+";
        sort_album = "artist+ date+ album+ disc+ track+";

        plugins = [ "noimport" ]
          ++ lib.optional config.services.mopidy.enable "mpdupdate";
      }
      // lib.optionalAttrs config.services.mopidy.enable { mpd.host = config.services.mopidy.settings.mpd.hostname; }
    ;
  };

  programs.bash.shellAliases."beet-import-all" = "beet import --flat --timid ${lib.escapeShellArg music.source}/*/*";
  programs.qutebrowser.searchEngines."!beets" = "https://beets.readthedocs.io/en/${config.programs.beets.package.src.rev}/search.html?q={}";
}
