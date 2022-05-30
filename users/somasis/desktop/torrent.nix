{ config
, pkgs
, lib
, ...
}:
let
  configFile = pkgs.writeText "transmission-remote-gtk-config" (lib.generators.toJSON { } {
    profiles = [
      rec {
        profile-name = "genesis.whatbox.ca";

        auto-connect = true;
        hostname = "localhost";
        rpc-url-path = "/transmission/rpc";
        port = 17994;

        ssl = false;
        timeout = 60;
        retries = 3;

        update-active-only = true;
        update-interval = 2;
        min-update-interval = 60;
        session-update-interval = 300;
        activeonly-fullsync-enabled = true;
        activeonly-fullsync-every = 10;

        # appearance
        style = 0;
        show-notebook = false;
        show-state-selector = true;
        filter-dirs = true;
        directories-first = true;
        filter-trackers = true;

        # notifications
        add-notify = false;
        complete-notify = true;

        # adding torrents
        add-options-dialog = true;
        start-paused = false;
        delete-local-torrent = true;

        exec-commands =
          let
            args = ''-h "http://%{hostname}:%{port}%{rpc-url-path}" -a "%{username}:%{password}" -H "%{profile-name}"'';
            tp = ''${tpull}/bin/tpull ${args}'';
            to = ''${topen}/bin/topen ${args}'';
          in
          [
            {
              cmd = ''
                ${to} -d ${config.home.homeDirectory}/mnt/ssh/%{profile-name} -D "s|^${config.home.homeDirectory}||" %{id}[ ]
              '';
              label = "Open _directory";
            }
            {
              cmd = "xdg-open %{comment}";
              label = "Open in _Redacted";
            }
            {
              cmd = ''
                ${tp} -d ${config.home.homeDirectory}/mnt/ssh/spinoza.7596ff.com/audio/library/source/torrent %{id}[ ]
              '';
              label = "Download to @_spinoza/audio/library/source/torrent";
            }
            {
              cmd = ''
                ${tp} -d ${config.home.homeDirectory}/mess/current/incoming %{id}[ ]
              '';
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

  # HACK: Workaround transmission-remote-gtk not being able to run commands to
  #       obtain the authentication information by generating a configuration file.
  pass-transmission-remote-gtk = (pkgs.writeShellApplication {
    name = "pass-transmission-remote-gtk";
    runtimeInputs = [
      config.programs.jq.package
      config.programs.password-store.package
      pkgs.coreutils
      pkgs.moreutils
    ];

    text = ''
      set -eu
      set -o pipefail

      umask 0077

      : "''${XDG_CONFIG_HOME:=$HOME/.config}"
      : "''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}"

      runtime="$XDG_RUNTIME_DIR"/pass-transmission-remote-gtk
      [ -d "$runtime" ] || mkdir -m 700 "$runtime"

      rm -f "$runtime"/config.json
      cat ${configFile} >"$runtime"/config.json

      while [ $# -ge 2 ]; do
          profile="$1"; shift
          entry="$1"; shift

          pass "$entry" \
              | jq -R '
                  {
                      profiles: [
                          {
                              "profile-name": $profile,
                              username: ($entry | split("/")[-1]),
                              password: .
                          }
                      ]
                  }' \
                  --arg profile "$profile" \
                  --arg entry "$entry" \
              | jq -s '
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
                  "$runtime"/config.json \
                  - \
                  > "$runtime"/config.json.tmp

          mv "$runtime"/config.json.tmp "$runtime"/config.json
      done

      [ -d "$XDG_CONFIG_HOME"/transmission-remote-gtk ] \
          || mkdir -m 700 "$XDG_CONFIG_HOME"/transmission-remote-gtk

      chmod u-w "$runtime"/config.json

      ln -sf "$runtime"/config.json "$XDG_CONFIG_HOME"/transmission-remote-gtk/config.json
    '';
  });

  tpull = (pkgs.writeShellApplication {
    name = "tpull";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.libnotify
      pkgs.nq
      pkgs.rsync
      pkgs.transmission
    ];

    text = ''
      # tpull \
      #     -h "http://%{hostname}:%{port}%{rpc-url-path}" \
      #     -a "%{username}:%{password}" \
      #     -H seedbox.nsa.gov \
      #     -d ~/mess/current/incoming \
      #     %{id}[ ]

      set -eu
      set -o pipefail

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
  });

  topen = (pkgs.writeShellApplication {
    name = "topen";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.gnugrep
      pkgs.gnused
      pkgs.transmission
      pkgs.xdg-utils
    ];

    text = ''
      # topen \
      #     -h "http://%{hostname}:%{port}%{rpc-url-path}" \
      #     -a "%{username}:%{password}" \
      #     -H seedbox.nsa.gov \
      #     -d /mnt/seedbox/files/completed \
      #     %{id}[ ]

      set -eu
      set -o pipefail

      usage() {
          cat >&2 <<EOF
      usage: ''${0##*/} [-a USER:PASS] [-d LOCAL] [-D STRIP] [-h HOST] IDS...
      EOF
          exit 69
      }

      local_dir=./
      strip_from_remote_dir=
      transmission_auth=
      transmission_host=localhost
      while getopts :d:D:a:h: arg >/dev/null 2>&1; do
          case "''${arg}" in
              d)
                  local_dir="''${OPTARG}"
                  ;;
              D)
                  strip_from_remote_dir="''${OPTARG}"
                  ;;
              a)
                  transmission_auth="''${OPTARG}"
                  ;;
              h)
                  transmission_host="''${OPTARG}"
                  ;;
              *)
                  usage
                  ;;
          esac
      done
      shift $((OPTIND - 1))

      while [[ $# -gt 0 ]]; do
          details=$(
              TR_AUTH="''${transmission_auth}" \
                  transmission-remote ''${transmission_auth:+-n "''${transmission_auth}"} \
                      "''${transmission_host}" \
                      -t "$1" -i
          )

          location=$(printf '%s' "''${details}" | grep -E '^\s+Location:' | cut -c 13-)
          name=$(printf '%s' "''${details}" | grep -E '^\s+Name:' | cut -c 9-)

          if [[ -n "''${strip_from_remote_dir}" ]]; then
              location=$(printf '%s' "''${location}" | sed "''${strip_from_remote_dir}")
          fi

          if [[ -z "''${location}" ]] || [[ -z "''${name}" ]]; then
              continue
          fi

          xdg-open "''${local_dir}/''${location}/''${name}"

          shift
      done
    '';
  });
in
{
  home.packages = [
    pkgs.transmission
    pkgs.transmission-remote-gtk

    pass-transmission-remote-gtk

    tpull
    topen
  ];

  xdg.mimeApps.defaultApplications = {
    "application/x-bittorrent" = "io.github.TransmissionRemoteGtk.desktop";
    "x-scheme-handler/magnet" = "io.github.TransmissionRemoteGtk.desktop";
  };

  systemd.user.services."pass-transmission-remote-gtk" = {
    Unit = {
      Description = "Authenticate `transmission-remote-gtk` using `pass`";
      PartOf = [ "default.target" ];
    };
    Install.WantedBy = [ "default.target" ];

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = [
        "${pass-transmission-remote-gtk}/bin/pass-transmission-remote-gtk genesis.whatbox.ca www/whatbox.ca/somasis"
      ];
      ExecStop = [
        "${pkgs.coreutils}/bin/rm -rf %t/pass-transmission-remote-gtk"
      ];
    };
  };
}

