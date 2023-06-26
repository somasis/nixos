{ config
, pkgs
, lib
, ...
}:
let
  transmission = pkgs.wrapCommand {
    package = pkgs.transmission;

    wrappers = [{
      command = "/bin/transmission-remote";

      beforeCommand = [
        ''
          entry=www/whatbox.ca/somasis

          case "$-" in
              *x*)
                  set +x
                  TR_AUTH="$(${config.programs.password-store.package}/bin/pass meta "$entry" username):$(pass "$entry")"
                  set -x
                  ;;
              *)
                  TR_AUTH="$(${config.programs.password-store.package}/bin/pass meta "$entry" username):$(pass "$entry")"
                  ;;
          esac
          export TR_AUTH
        ''
      ];

      prependFlags = "--authenv";
    }];
  };

  tpull = pkgs.writeShellApplication {
    name = "tpull";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.libnotify
      pkgs.nq
      pkgs.rsync
      transmission
    ];

    text = ''
      # tpull \
      #     -h "http://%{hostname}:%{port}%{rpc-url-path}" \
      #     -a "%{username}:%{password}" \
      #     -H seedbox.nsa.gov \
      #     -d ~/mess/current/incoming \
      #     %{id}[ ]

      usage() {
          cat >&2 <<EOF
      usage: ''${0##*/} [-a USER:PASS] [-d DEST] [-h HOST] [-H USER@HOST] IDS...
      EOF
          exit 69
      }

      export NQDIR="''${XDG_CACHE_HOME:-''${HOME}/.cache}/nq/tpull"
      mkdir -p "''${NQDIR}"

      [[ $# -gt 0 ]] || exec fq

      dest=./
      mode=download
      transmission_auth=
      transmission_host=localhost
      while getopts :Da:d:h:H: arg >/dev/null 2>&1; do
          case "''${arg}" in
              d)
                  dest="''${OPTARG}"
                  ;;
              D)
                  # NOTE: only meant for script-internal use
                  # $ tpull -D HOST:PATH DEST NAME
                  # NAME is the torrent name, DEST being the destination, HOST:PATH being the path
                  # to the torrent data files.
                  mode=rsync
                  ;;
              a)
                  transmission_auth="''${OPTARG}"
                  ;;
              h)
                  transmission_host="''${OPTARG}"
                  ;;
              H)
                  ssh_host="''${OPTARG}"
                  ;;
              *)
                  usage
                  ;;
          esac
      done
      shift $((OPTIND - 1))

      : "''${ssh_host:=''${transmission_host}}"

      case "''${mode}" in
          rsync)
              if rsync -ruvs --delete-delay  --exclude "*.part" "$1" "$2"; then
                  exec \
                      notify-send \
                          -a "tpull" \
                          -i transmission-remote-gtk \
                          "tpull" "'$3' finished downloading to '$2'."
              else
                  exec \
                      notify-send \
                          -a "tpull" \
                          -i transmission-remote-gtk \
                          "tpull" "'$3' failed to download."
              fi
              ;;
      esac

      while [[ $# -gt 0 ]]; do
          details=$(
              transmission-remote ''${transmission_auth:+-n "''${transmission_auth}"} \
                  "''${transmission_host}" \
                  -t "$1" -i
          )

          location=$(printf '%s' "''${details}" | grep -E '^\s+Location:' | cut -c 13-)
          name=$(printf '%s' "''${details}" | grep -E '^\s+Name:' | cut -c 9-)

          if [[ -z "''${location}" ]] || [[ -z "''${name}" ]]; then
              continue
          fi

          path="''${location}/''${name}"

          nq -c "$0" -D "''${ssh_host}:''${path}" "''${dest}" "''${name}"

          amt=$(fq -nq | wc -l)
          notify-send -a "tpull" -i transmission-remote-gtk \
              "tpull" "''${amt} download(s) enqueued. Run \`tpull\` to see progress."
          shift
      done
    '';
  };

  topen = pkgs.writeShellApplication {
    name = "topen";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
      transmission
      pkgs.xdg-utils
    ];

    text = ''
      usage() {
          cat >&2 <<EOF
      usage: ''${0##*/} [-d LOCAL] [-D STRIP] IDS...
      EOF
          exit 69
      }

      local_dir=./
      strip_from_remote_dir=
      while getopts :d:D: arg >/dev/null 2>&1; do
          case "$arg" in
              d) local_dir="$OPTARG" ;;
              D) strip_from_remote_dir="$OPTARG" ;;
              *) usage ;;
          esac
      done
      shift $((OPTIND - 1))

      while [[ $# -gt 0 ]]; do
          details=$(transmission-remote -t "$1" -i)

          location=$(<<<"$details" grep -E '^\s+Location:' | cut -c 13-)
          name=$(<<<"$details" grep -E '^\s+Name:' | cut -c 9-)

          [[ -n "$strip_from_remote_dir" ]] && location=$(sed "$strip_from_remote_dir" <<< "$location")

          if [[ -z "$location" ]] || [[ -z "$name" ]]; then
              continue
          fi

          systemctl -q --user start "$(systemd-escape --path "$local_dir" --suffix mount)" || :

          xdg-open "$local_dir/$location/$name"

          shift
      done
    '';
  };

  configFile = pkgs.writeText "transmission-remote-gtk-config" (lib.generators.toJSON { } {
    # appearance
    show-notebook = false;
    show-state-selector = true;
    filter-dirs = true;
    directories-first = true;
    filter-trackers = true;

    # notifications
    add-notify = true;
    complete-notify = true;

    # adding torrents
    add-options-dialog = true;
    start-paused = false;
    delete-local-torrent = true;

    profiles = [
      rec {
        profile-name = "genesis.whatbox.ca";

        auto-connect = true;
        hostname = "localhost";
        rpc-url-path = "/transmission/rpc";
        port = 9091;

        ssl = false;
        timeout = 60;
        retries = 3;

        style = 0;

        update-active-only = true;
        update-interval = 2;
        min-update-interval = 60;
        session-update-interval = 300;
        activeonly-fullsync-enabled = true;
        activeonly-fullsync-every = 10;

        # Not config.home.homeDirectory because it refers to the path on the remote.
        last-add-destination = "/home/somasis/files/audio/library/source/torrent";

        exec-commands =
          let
            tpull' = ''${tpull}/bin/tpull -H "%{profile-name}"'';
            topen' = ''${topen}/bin/topen -D "s|^${config.home.homeDirectory}||" -d ${config.home.homeDirectory}/mnt/sftp/%{profile-name}'';
          in
          [
            {
              cmd = "${topen'} %{id}[ ]";
              label = "Open _directory";
            }
            {
              cmd = "xdg-open %{comment}";
              label = "Open in _Redacted";
            }
            {
              cmd = "${tpull'} -d ${config.home.homeDirectory}/mnt/sftp/spinoza.7596ff.com/audio/library/source/torrent %{id}[ ]";
              label = "Download to @_spinoza/audio/library/source/torrent";
            }
            {
              cmd = "${tpull'} -d ${config.home.homeDirectory}/mess/current/incoming %{id}[ ]";
              label = "Download to ~/mess/current/_incoming";
            }
            # {
            #   cmd = "terminal beet-sync";
            #   label = "_Sync and Import...";
            # }
          ];

        # Paths are local to remote Transmission daemon
        destinations = [
          { dir = "/home/somasis/files/audio/library/source/torrent"; label = "audio/source"; }
          { dir = "/home/somasis/files/audio/misc"; label = "audio/misc"; }
          { dir = "/home/somasis/files/video/film"; label = "video/film"; }
          { dir = "/home/somasis/files/video/tv"; label = "video/tv"; }
          { dir = "/home/somasis/files/misc"; label = "misc"; }
        ];
      }
    ];

    tree-views = {
      TrgFilesTreeView = {
        columns = [ "name" "size" "progress" "wanted" "priority" ];
        sort-col = -2;
        sort-type = 0;
      };
      TrgFilesTreeView-dialog = {
        columns = [ "name" "size" "progress" "wanted" "priority" ];
        sort-col = -2;
        sort-type = 0;
      };
      TrgPeersTreeView = {
        columns = [ "ip" "host" "down-speed" "up-speed" "progress" "flags" "client" ];
        sort-col = -2;
        sort-type = 0;
      };
      TrgPeersTreeView-dialog = {
        columns = [ "ip" "host" "down-speed" "up-speed" "progress" "flags" "client" ];
        sort-col = 1;
        sort-type = 0;
      };
      TrgTorrentTreeView = {
        columns = [ "name" "size" "done" "eta" "uploaded" "ratio" "added" ];
        sort-col = 22;
        sort-type = 1;
      };
      TrgTrackersTreeView = {
        columns = [ "tier" "announce-url" "last-announce-peer-count" "seeder-count" "leecher-count" "last-announce-time" "last-result" "scrape-url" ];
        sort-col = -2;
        sort-type = 0;
      };
      TrgTrackersTreeView-dialog = {
        columns = [ "tier" "announce-url" "last-announce-peer-count" "seeder-count" "leecher-count" "last-announce-time" "last-result" "scrape-url" ];
        sort-col = -2;
        sort-type = 0;
      };
    };
  });

in
{
  somasis.tunnels.tunnels.transmission = {
    location = 9091;
    remoteLocation = 17994;

    remote = "somasis@genesis.whatbox.ca";
  };

  home.packages = [
    transmission

    (pkgs.symlinkJoin {
      name = "transmission-remote-gtk-with-pass";

      paths = [
        (pkgs.writeShellScriptBin "transmission-remote-gtk" ''
          set -eu
          set -o pipefail

          mkdir -m 700 -p "''${XDG_CONFIG_HOME:=$HOME/.config}"/transmission-remote-gtk
          rm -f "$XDG_CONFIG_HOME"/transmission-remote-gtk/config.json
          mkfifo "$XDG_CONFIG_HOME"/transmission-remote-gtk/config.json

          (
              config=
              profile="genesis.whatbox.ca"
              entry="www/whatbox.ca/somasis"

              ${config.programs.password-store.package}/bin/pass "$entry" \
                  | ${config.programs.jq.package}/bin/jq -R \
                        --arg profile "$profile" \
                        --arg entry "$entry" \
                        '
                          {
                            profiles: [
                              {
                                "profile-name": $profile,
                                "username": ($entry | split("/")[-1]),
                                "password": .
                              }
                            ]
                          }
                        ' \
                  | ${config.programs.jq.package}/bin/jq -s '
                      .[1].profiles[] as $profile
                        | $profile."profile-name" as $wantedProfile
                        | (
                          .[0]
                            | .profiles
                            |= map(
                              select(."profile-name" == $wantedProfile)
                                + $profile
                            )
                          )
                      ' \
                      ${configFile} \
                      -
          ) > "$XDG_CONFIG_HOME"/transmission-remote-gtk/config.json &

          ${pkgs.rwc}/bin/rwc -p "$XDG_CONFIG_HOME"/transmission-remote-gtk/config.json \
              | ${pkgs.xe}/bin/xe -s 'rm -f "$XDG_CONFIG_HOME"/transmission-remote-gtk/config.json' &

          e=0
          (exec -a transmission-remote-gtk ${pkgs.transmission-remote-gtk}/bin/transmission-remote-gtk "$@") || e=$?
          kill $(jobs -p)
          exit "$e"
        '')
        pkgs.transmission-remote-gtk
      ];
    })

    tpull
    topen
  ];

  xdg.mimeApps.defaultApplications = {
    "application/x-bittorrent" = "io.github.TransmissionRemoteGtk.desktop";
    "x-scheme-handler/magnet" = "io.github.TransmissionRemoteGtk.desktop";
  };
}
