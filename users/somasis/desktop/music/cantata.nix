{ config
, nixosConfig
, lib
, pkgs
, ...
}:
let
  inherit (config.lib.somasis) commaList;

  envtag =
    let
      formatJSON = pkgs.writeJqScript "format-ffprobe-json"
        {
          sort-keys = true;
          raw-output = true;
        }
        ''
          .format.tags
              + {
                  "format": .format.format_name,
                  "filename": .format.filename,
                  "size": (.format.size | tonumber),
                  "duration": (.format.duration | tonumber),
                  "bit_rate": (.format.bit_rate | tonumber)
              }
              + (.streams | map(.tags) | add)
              | with_entries(
                  .key |= (ascii_downcase | gsub(" "; "_"))
                      | (.value | (tonumber? // .)) as $value
                      | .value = $value
              )
              | keys[] as $k
              | ("export " + ("\($k)=\(."\($k)")" | @sh))
        '';
    in
    pkgs.writeShellScriptBin "envtag" ''
      ${pkgs.ffmpeg-full}/bin/ffprobe -loglevel -32 \
          -of json \
          -select_streams a \
          -show_format \
          -show_entries stream_tags \
          -i "$1" \
          | ${formatJSON}
    '';

  cantata = pkgs.cantata.override {
    # just be a music player, no file operations
    withTaglib = false;
    withReplaygain = false;
    withMtp = false;
    withOnlineServices = false;
    withDevices = false;
  };

  cantata-delete-cover-art = pkgs.writeShellScript "cantata-delete-cover-art" ''
    ${pkgs.findutils}/bin/find "$@" -name 'cover.*' -delete
    ${pkgs.coreutils}/bin/rm -rf "''${XDG_CACHE_HOME:=$HOME/.cache}/cantata/covers-scaled"
  '';

  cantata-beets-open = pkgs.writeShellScript "cantata-beets-open" ''
    set -eu -o pipefail
    export PATH=${lib.makeBinPath [ envtag config.programs.beets.package pkgs.openssh pkgs.s6-portable-utils pkgs.xdg-utils pkgs.xe ]}:"$PATH"

    {
        eval "$(envtag "$1")"

        for a in \
            beet list -f '$path' -a \
                "mb_albumartistid:$musicbrainz_albumartistid" \
                "mb_albumid:$musicbrainz_albumid"; do
                printf '%s ' "$(s6-quote -d "'" -- "$a")"
        done
        printf '\n'
    } \
        | ssh spinoza sh -l - \
        | xe -N1 xdg-open
  '';

  cantata-musicbrainz-open = pkgs.writeShellScript "cantata-musicbrainz-open" ''
    set -eu -o pipefail
    export PATH=${lib.makeBinPath [ envtag pkgs.xdg-utils pkgs.xe ]}:"$PATH"

    tag_type="$1"
    url="$1"
    case "$1" in
        albumartist) url=artist; set -- "$1" "$2" ;;
        recording) tag_type=track ;;
        release) tag_type=album; set -- "$1" "$2" ;;
        releasegroup) url=release-group; set -- "$1" "$2" ;;
        releasetrack) url=track ;;
    esac

    shift

    urls=()

    for f; do
        eval "$(envtag "$f")"
        eval "id=\"\$musicbrainz_''${tag_type}id\""

        urls+=( "https://musicbrainz.org/$url/$id" )
    done

    printf '%s\0' "''${urls[@]}" | xe -0 -N1 xdg-open
  '';

  cantata-search-youtube = pkgs.writeShellScript "cantata-search-youtube" ''
    set -eu -o pipefail
    export PATH=${lib.makeBinPath [ envtag config.programs.jq.package pkgs.xdg-utils ]}:"$PATH"

    eval "$(envtag "$1")"
    url=$(
        jq -n '
            ("\(env.artist_credit // env.artist) \(env.title)") as $query
                | "https://www.youtube.com/results?search_query=\($query | @uri)"
        '
    )
    xdg-open "$url"
  '';

  # TODO There ought to be a JSON <-> QSettings converter
  # It seems like it ought to be doable with PySide...
  # <https://doc.qt.io/qtforpython-5/PySide2/QtCore/QSettings.html>
  # <https://doc.qt.io/qtforpython-5/PySide2/QtCore/QJsonDocument.html>
  # <https://doc.qt.io/qtforpython-5/PySide2/QtCore/QJsonValue.html>
  mkCantata = lib.generators.toINI {
    mkKeyValue = k: v:
      let
        v' =
          if builtins.isList v && v == [ ] then
            "@Invalid()"
          else if builtins.isBool v then
            lib.boolToString v
          else if builtins.isList v then
            lib.concatStringsSep ", " v
          else
            builtins.toString v
        ;
      in
      "${k}=${v'}"
    ;
  };

  mkCantataActions = actions:
    let
      actions' = lib.foldr
        (prev: final: prev // final)
        { }
        (lib.imap0 (i: v: { "${toString i}_cmd" = v.command; "${toString i}_name" = v.name; }) actions);
      count = builtins.length (lib.mapAttrsToList (n: v: n.cmd) actions');
    in
    actions' // { inherit count; }
  ;

  cantataConf = pkgs.writeText "cantata-config" (mkCantata {
    CustomActions = mkCantataActions [
      # %f file list, %d directory list, else list of files is appended to command
      {
        name = "Delete cover art";
        command = "${cantata-delete-cover-art} %d";
      }
      {
        name = "beets: open in library";
        command = "${cantata-beets-open} %f";
      }
      {
        name = "MusicBrainz: album artist";
        command = "${cantata-musicbrainz-open} albumartist %f";
      }
      {
        name = "MusicBrainz: artist";
        command = "${cantata-musicbrainz-open} artist %f";
      }
      {
        name = "MusicBrainz: recording";
        command = "${cantata-musicbrainz-open} recording %f";
      }
      {
        name = "MusicBrainz: release group";
        command = "${cantata-musicbrainz-open} releasegroup %f";
      }
      {
        name = "MusicBrainz: release track";
        command = "${cantata-musicbrainz-open} releasetrack %f";
      }
      {
        name = "MusicBrainz: release";
        command = "${cantata-musicbrainz-open} release %f";
      }
      {
        name = "MusicBrainz: work";
        command = "${cantata-musicbrainz-open} work %f";
      }
      {
        name = "YouTube: search for track";
        command = "${cantata-search-youtube} %f";
      }
    ];

    General.version = cantata.version; # necessary to avoid the first-start dialog

    General.page = "PlayQueuePage"; # Default the starting page to play queue
    General.contextSlimPage = "song"; # Default the track info to lyrics + song info

    # Collection
    Connection.host = config.services.mpd.network.listenAddress;
    Connection.port = config.services.mpd.network.port;
    Connection.dir = config.services.mpd.musicDirectory;

    Connection.allowLocalStreaming = true; # Local file playback: "via-in-built HTTP server"
    Connection.autoUpdate = true; # "Server detects changes automatically"

    # Playback
    General.stopFadeDuration = 1000; # "Fadeout on stop"
    General.stopOnExit = false; # "Stop playback on exit"
    General.inhibitSuspend = true; # "Inhibit suspend whilst playing"
    Connection.replayGain = "auto"; # Use track ReplayGain during shuffle, album when in order; Playback > output
    Connection.applyReplayGain = true; # "Apply setting on connect"
    General.volumeStep = 5;

    # Interface > Sidebar
    General.hiddenPages = null;
    General.sidebar = 290; # function of style, position, and "Only show icons, no text"
    General.splitterAutoHide = false;
    General.responsiveSidebar = true; # "Automatically change style when insufficient space"

    # Interface > Play Queue
    General.playQueueView = "table"; # style: "grouped albums" ("grouped"/"table")
    General.playQueueStartClosed = false; # "initially collapse albums"
    General.playQueueAutoExpand = true; # "automatically expand current album"
    General.playQueueScroll = true; # "scroll to current track"
    General.playQueueConfirmClear = false; # "prompt before clearing"
    General.playQueueSearch = true; # "separate action (and shortcut) for play queue search"

    General.playQueueBackground = 0; # background image: "current album cover"
    # General.playQueueBackgroundBlur = 20;
    # General.playQueueBackgroundOpacity = 20;

    # Interface > Toolbar
    General.showStopButton = true;
    General.showCoverWidget = true; # "Show cover of current track"
    General.showTechnicalInfo = true;
    General.showRatingWidget = false; # TODO find a way to synchronize my ratings with beets over the network; "Show track rating"

    # Interface > External
    General.mpris = false; # mpris is managed by mpdris2; "Enable MPRIS D-BUS interface"
    General.showPopups = false; # "Show popup messages when changing tracks"

    # Interface > Tweaks
    General.ignorePrefixes = null; # "artist & album sorting"
    General.composerGenres = null; # "composer support"
    General.singleTracksFolders = null;

    General.cueSupport = "ignore"; # CUE files: "do not list"
    LibraryPage.librarySort = "year"; # Year tag: "use 'year' tag to display & sort"

    # Interface > Covers
    General.fetchCovers = false; # "fetch missing covers"
    General.storeCoversInMpdDir = false; # "save downloaded covers into music folder"
    General.coverFilename = "";

    # Interface > General
    General.showDeleteAction = false; # Discourage file operations; it's all handled by beets
    General.forceSingleClick = false; # "enforce single-click activation of items"
    General.infoTooltips = true; # "Show song information tooltips"

    # Info > Wikipedia Languages
    General.wikipediaLangs = [ "en:en" "simple:simple" "es:es" "ja:ja" ];

    # Info > Lyrics Providers
    General.lyricProviders = null; # Don't fetch lyrics, use the local ones

    # Info > Other
    General.contextBackdrop = 1; # background image: "artist image"
    General.contextBackdropBlur = 20;
    General.contextBackdropOpacity = 20;

    General.contextSwitchTime = 0; # "automatically switch to view after..."

    General.storeLyricsInMpdDir = false; # "save downloaded lyrics into music folder"
    General.contextDarkBackground = true; # "dark background"
    General.contextAlwaysCollapsed = false; # "always collapse into a single pane"
    General.wikipediaIntroOnly = true; # "only show basic wikipedia text"

    General.showMenubar = false;

    Scrobbling.enable = false; # Scrobbling is handled by mpdscribble
    Scrobbling.loveEnabled = true;
    Scrobbling.scrobbler = "Last.fm";
    Scrobbling.userName = "kyliesomasis";

    "Shortcuts-cantata" = {
      rating1 = null;
      rating2 = null;
      rating3 = null;
      rating4 = null;
      rating5 = null;
      showfolderstab = "Alt+3";
      showlibrarytab = "Alt+2";
      showmenubar = "F1";
      showonlinetab = "Alt+5";
      showplayliststab = "Alt+4";
      showplayqueue = "Alt+1";
      showsearchtab = "Alt+6";
      showsonginfo = "Alt+7";
    };

    # Not visible from the main preferences window
    General.contextAutoScroll = false; # info > track > "Scroll lyrics"
    AlbumView.fullWidthCover = true; # info > album > "Full width cover"

    LibraryPage.grouping = "album";
    LibraryPage.albumSort = "yraral"; # Sort the library by year, artist, and then album
    LibraryPage."album\\viewMode" = "icontop"; # use grid for album view

    DevicesPage.viewMode = "simpletree";
    DynamicPlaylistsPage.viewMode = "list";
    MpdBrowsePage.viewMode = "simpletree";
    PodcastWidget.viewMode = "detailedtree";
    SearchPage.searchCategory = "any";
    SearchPage.viewMode = "list";
    SmartPlaylistsPage.viewMode = "list";
    StoredPlaylistsPage.viewMode = "detailedtree";
    StreamsBrowsePage.viewMode = "list";
    localbrowsehome.viewMode = "simpletree";
    localbrowseroot.viewMode = "simpletree";
  });
in
{
  persist.directories = [{ method = "symlink"; directory = "etc/audacity"; }];

  cache.directories = [
    { method = "symlink"; directory = "share/cantata"; }
    { method = "symlink"; directory = "var/cache/cantata"; }
  ];

  home.packages = [
    envtag

    pkgs.audacity

    (pkgs.symlinkJoin rec {
      name = "cantata-with-pass";

      runtimeInputs = [ config.programs.password-store.package pkgs.coreutils ];

      paths = [
        # Can't use a FIFO for the configuration- cantata seems to do something
        # funky at program start that causes it to need an additional write after
        # being closed for the first time; and after that, it does more r/w...
        (pkgs.writeShellScriptBin "cantata" ''
            export
            PATH="${lib.makeBinPath runtimeInputs}:$PATH"

          : "''${XDG_CONFIG_HOME:=$HOME/.config}"
          : "''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}"

          set -eu
          set -o pipefail

          mkdir -m 700 -p "$XDG_CONFIG_HOME/cantata" "$XDG_RUNTIME_DIR/cantata"
          touch "$XDG_RUNTIME_DIR/cantata/cantata.conf"
          chmod 700 "$XDG_RUNTIME_DIR/cantata/cantata.conf"

          cat ${cantataConf} - > "$XDG_RUNTIME_DIR"/cantata/cantata.conf <<EOF
          [Scrobbling]
          sessionKey=$(pass ${nixosConfig.networking.fqdnOrHostName}/cantata/last.fm)
          EOF

          ln -sf "$XDG_RUNTIME_DIR/cantata/cantata.conf" "$XDG_CONFIG_HOME/cantata/cantata.conf"

          # -n: don't allow fetching things over the network
          e=0
          (${pkgs.jumpapp}/bin/jumpapp -f -n -i cantata ${cantata}/bin/cantata -n "$@");
          e = $?
            rm - f "$XDG_CONFIG_HOME/cantata/cantata.conf"
            exit "$e"
        '')

        cantata
      ];
    })
  ];
}


