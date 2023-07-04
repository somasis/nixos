{ pkgs
, lib
, config
, osConfig
, ...
}:
let
  bandcamp-collection-downloader = pkgs.callPackage
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

        jar = "${placeholder "out"}/lib/bandcamp-collection-downloader.jar";

        buildPhase = ''
          install -D -m 0755 $src $jar
        '';

        installPhase = ''
          makeWrapper ${jre}/bin/java $out/bin/bandcamp-collection-downloader \
              --argv0 bandcamp-collection-downloader \
              --add-flags "-jar $jar"
        '';

        meta = with lib; {
          description = "Tool for automatically downloading releases purchased with a Bandcamp account";
          homepage = "https://framagit.org/Ezwen/bandcamp-collection-downloader";
          license = licenses.agpl3;
          maintainers = with maintainers; [ somasis ];
        };
      })
    { };

  pass-beets = pkgs.writeShellApplication {
    name = "pass-beets";
    runtimeInputs = [
      config.programs.jq.package
      config.programs.password-store.package
      pkgs.yq-go
    ];

    text = ''
      fail() {
          [[ "$1" -ne 0 ]] && printf 'pass-beets: "failed"\n' && exit 0
      }

      trap 'fail $?' ERR

      output=$(
          pass ${osConfig.networking.fqdnOrHostName}/beets/acoustid \
              | jq -Rc '{ acoustid: { apikey: . } }'
      )
      output+=$(
          pass ${osConfig.networking.fqdnOrHostName}/beets/musicbrainz \
              | jq -Rc \
                  --arg user Somasis \
                  '{ musicbrainz: { user: $user, pass: . } }'
      )
      output+=$(
          pass ${osConfig.networking.fqdnOrHostName}/beets/google \
              | jq -Rc '{ lyrics: { google_API_key: . } }'
      )

      jq -sc 'add' <<<"$output" | yq --input-format json --output-format yaml
    '';
  };

  beets-noimport = pkgs.callPackage
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
    { beets = pkgs.beetsPackages.beets-minimal; };

  # FIXME: broken plugins
  # beetcamp = (pkgs.callPackage
  #   ({ lib, fetchFromGitHub, beets, python3Packages }:
  #     python3Packages.buildPythonApplication rec {
  #       pname = "beetcamp";
  #       version = "0.16.0";

  #       format = "pyproject";

  #       src = fetchFromGitHub {
  #         repo = pname;
  #         owner = "snejus";
  #         rev = version;
  #         hash = "sha256-AX5Z6MODr28dWF9NrT394F+fmW5btRBQvb0E8WmDa70=";
  #       };

  #       propagatedBuildInputs = with python3Packages; [
  #         cached-property
  #         ordered-set
  #         poetry-core
  #         pycountry
  #         python-dateutil
  #         requests
  #       ];

  #       # checkInputs = with python3Packages; [
  #       #   pytest
  #       #   pytest-cov
  #       #   pytest-randomly
  #       #   pytest-clarify
  #       #   pytest-lazy-fixture
  #       #   rich
  #       # ];

  #       # doCheck = true;

  #       nativeBuildInputs = [ beets ];

  #       meta = with lib; {
  #         description = "Use Bandcamp as a autotagger source for beets";
  #         homepage = "https://github.com/snejus/beetcamp";
  #         maintainers = with maintainers; [ somasis ];
  #         license = licenses.gpl2;
  #       };
  #     })
  #   { beets = pkgs.beetsPackages.beets-minimal; });

  # beets-fetchartist = (pkgs.callPackage
  #   ({ lib, fetchFromGitHub, beets, python3Packages }:
  #     python3Packages.buildPythonApplication rec {
  #       pname = "beets-fetchartist";
  #       version = "unstable-2020-07-03";

  #       format = "other";

  #       src = fetchFromGitHub {
  #         repo = pname;
  #         owner = "dkanada";
  #         rev = "6ab1920d2ae217bf1c814cdeab220e6d09251aac";
  #         hash = "sha256-jPm4S02VOYuUgA3wSHX/gdhWIZXZ1k+yLnbui5J/VuU=";
  #       };

  #       propagatedBuildInputs = with python3Packages; [
  #         pylast
  #         requests
  #       ];

  #       nativeBuildInputs = [ beets ];

  #       installPhase = ''
  #         beetsplug=$(toPythonPath "$out")/beetsplug
  #         mkdir -p $beetsplug
  #         cp -r $src/beetsplug/* $beetsplug/
  #       '';

  #       meta = with lib; {
  #         description = "Artist images for beets";
  #         homepage = "https://github.com/dkanada/beets-fetchartist";
  #         maintainers = with maintainers; [ somasis ];
  #         license = licenses.mit;
  #       };
  #     })
  #   { beets = pkgs.beetsPackages.beets-minimal; });

  # TODO Wait for merge https://github.com/NixOS/nixpkgs/pull/203544
  originquery = pkgs.callPackage
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

        nativeBuildInputs = [ beets ];

        propagatedBuildInputs = with python3Packages; [
          confuse
          jsonpath_rw
          pyyaml
        ];

        meta = with lib; {
          description = "Integrate origin metadata (origin.txt) into beets MusicBrainz queries";
          homepage = "https://github.com/x1ppy/beets-originquery";
          maintainers = with maintainers; [ somasis ];
          license = licenses.unfree; # <https://github.com/x1ppy/beets-originquery/issues/3>
          inherit (beets.meta) platforms;
        };
      }
    )
    { beets = pkgs.beetsPackages.beets-minimal; }
  ;

  beets = pkgs.beets.override {
    pluginOverrides = {
      # beetcamp = { enable = true; propagatedBuildInputs = [ beetcamp ]; };
      # fetchartist = { enable = true; propagatedBuildInputs = [ beets-fetchartist ]; };
      alternatives = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.alternatives ]; };
      extrafiles = { enable = true; propagatedBuildInputs = [ pkgs.beetsPackages.extrafiles ]; };
      noimport = { enable = true; propagatedBuildInputs = [ beets-noimport ]; };
      originquery = {
        enable = true;
        propagatedBuildInputs = [
          # pkgs.beetsPackages.originquery
          originquery
        ];
      };
    };
  };

  notServer = osConfig.networking.fqdnOrHostName != "spinoza.7596ff.com";
in
{
  imports = [
    ./convert.nix
    ./extrafiles.nix
    ./ripping.nix
    ./tagging.nix
  ];

  xdg.userDirs.music = "${config.home.homeDirectory}/audio/library";

  home.file = lib.optionalAttrs notServer {
    "audio/library/source".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com_raid/somasis/audio/library/source";
    "audio/library/lossless".source = config.lib.file.mkOutOfStoreSymlink "${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com_raid/somasis/audio/library/lossless";
  };

  home.packages = [
    bandcamp-collection-downloader

    # (pkgs.symlinkJoin {
    #   name = "gazelle-origin-final";

    #   buildInputs = [ pkgs.makeWrapper ];
    #   paths = [ pkgs.gazelle-origin ];

    #   postBuild = ''
    #     wrapProgram $out/bin/gazelle-origin \
    #         --set-default "ORIGIN_TRACKER" "RED" \
    #         --run ': "''${RED_API_KEY:=$(${config.programs.password-store.package}/bin/pass ${osConfig.networking.fqdnOrHostName}/gazelle-origin/redacted.ch)}"' \
    #         --run 'export RED_API_KEY'
    #   '';
    # })

    pass-beets
  ];

  programs.beets = {
    enable = true;
    package = pkgs.symlinkJoin {
      name = "beets-final";

      paths = [
        # Provide a wrapper for the actual `beet` program, so that we can perform some
        # pre-command-initialization actions.
        # <https://nixos.wiki/wiki/Nix_Cookbook#Wrapping_packages>
        (pkgs.writeShellScriptBin "beet" ''
          #! ${pkgs.runtimeShell}
          set -eu
          set -o pipefail

          ${lib.toShellVar "PATH" (lib.makeBinPath [ pkgs.coreutils pkgs.utillinux pkgs.systemd ])}":${placeholder "out"}:$PATH"
          directory=$(readlink -m ${lib.escapeShellArg config.programs.beets.settings.directory})
          BEETS_LOCK="$directory/beets.lock"

          # Mount any required mount units
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

          # Maintain a cross-device lock, so that we don't conflict if the directory is
          # over a network device of some sort (sshfs)
          [[ -e "$BEETS_LOCK" ]] && printf 'Lock "%s" is currently held, sleeping until free...\n' "$BEETS_LOCK" >&2
          while [[ -e "$BEETS_LOCK" ]]; do
              sleep 5
          done
          touch "$BEETS_LOCK"

          # Trap Ctrl-C, since it seems really problematic for database health
          e=0
          trap : INT
          trap 'rm -f "$BEETS_LOCK"' EXIT

          # Feed pass-beets info via a FIFO so it never hits the disk.
          ${beets}/bin/beet -c <(pass-beets) "$@" || e=$?

          trap - INT
          exit $?
          EOF
        '')

        pass-beets

        beets.man
        beets.doc
        beets
      ];
    };

    settings = {
      directory = "${config.xdg.userDirs.music}/lossless";
      library = "${config.xdg.userDirs.music}/lossless/beets.db";

      # Default `beet list` options
      sort_case_insensitive = false;
      sort_item = "artist+ date+ album+ disc+ track+";
      sort_album = "artist+ date+ album+ disc+ track+";

      plugins = [ "noimport" ]
        ++ lib.optional config.services.mpd.enable "mpdupdate";
    }
    // lib.optionalAttrs config.services.mpd.enable {
      mpd = {
        host = config.services.mpd.network.listenAddress;
        inherit (config.services.mpd.network) port;
      };
    }
    ;
  };

  home.shellAliases."beet-import-all" = "beet import --flat --timid ${lib.escapeShellArg config.xdg.userDirs.music}/source/*/*";
  programs.qutebrowser.searchEngines."!beets" = "file:///${beets.doc}/share/doc/beets-${beets.version}/html/search.html?q={}";
}
