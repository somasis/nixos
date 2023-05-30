{ config
, nixosConfig
, lib
, pkgs
, ...
}:
let
  xdgRuntimeDir = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}";

  pass-mpdscribble = pkgs.writeShellApplication {
    name = "pass-mpdscribble";
    runtimeInputs = [ config.programs.password-store.package ];

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

  # INI is shell-expanded as a heredoc, so be careful with special characters
  mpdscribbleConf = lib.generators.toINIWithGlobalSection { } {
    globalSection = {
      log = "-";
      host = config.services.mpd.network.listenAddress;
      port = builtins.toString config.services.mpd.network.port;
      verbose = 1;
    };

    sections."last.fm" = {
      journal = "${config.xdg.cacheHome}/mpdscribble/last.fm.journal";
      url = "https://post.audioscrobbler.com/";

      username = "kyliesomasis";
      password = "$(pass www/last.fm/kyliesomasis | tr -d '\n' | md5sum - | cut -d' ' -f1)";
    };
  };

  envtag = pkgs.writeShellScriptBin "envtag" ''
    ${pkgs.ffmpeg-full}/bin/ffprobe -loglevel -32 \
        -of json \
        -select_streams a \
        -show_format \
        -show_entries stream_tags \
        -i "$1" \
        | ${config.programs.jq.package}/bin/jq -Sr '
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
        '
  '';

  cantata = pkgs.cantata.override {
    # just be a music player, no file operations
    withTaglib = false;
    withReplaygain = false;
    withMtp = false;
    withOnlineServices = false;
    withDevices = false;
  };

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
            lib.concatStringsSep '', '' v
          else
            builtins.toString v
        ;
      in
      "${k}=${v'}"
    ;
  };

  cantataConf = pkgs.writeText "cantata-config"
    (mkCantata {
      # TODO this in setting particular should be functionalized, this is annoying
      CustomActions =
        let
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

          cantata-musicbrainz-open = pkgs.writeShellScript "cantata-musicbrainz-open" ''i
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
        in
        {
          # %f file list, %d directory list, else list of files is appended to command
          "0_cmd" = "${cantata-delete-cover-art} %d";
          "0_name" = "Delete cover art";
          "1_cmd" = "${cantata-beets-open} %f";
          "1_name" = "beets: open in library";
          "2_cmd" = "${cantata-musicbrainz-open} albumartist %f";
          "2_name" = "MusicBrainz: album artist";
          "3_cmd" = "${cantata-musicbrainz-open} artist %f";
          "3_name" = "MusicBrainz: artist";
          "4_cmd" = "${cantata-musicbrainz-open} recording %f";
          "4_name" = "MusicBrainz: recording";
          "5_cmd" = "${cantata-musicbrainz-open} releasegroup %f";
          "5_name" = "MusicBrainz: release group";
          "6_cmd" = "${cantata-musicbrainz-open} releasetrack %f";
          "6_name" = "MusicBrainz: release track";
          "7_cmd" = "${cantata-musicbrainz-open} release %f";
          "7_name" = "MusicBrainz: release";
          "8_cmd" = "${cantata-musicbrainz-open} work %f";
          "8_name" = "MusicBrainz: work";
          "9_cmd" = "${cantata-search-youtube} %f";
          "9_name" = "YouTube: search for track";

          count = 8;
        };

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
  imports = [ ../music/manage ];

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

  services.listenbrainz-mpd = {
    enable = true;
    settings = {
      submission.token_file = "${xdgRuntimeDir}/listenbrainz-mpd.secret";
      submission.cache_file = "${config.xdg.cacheHome}/listenbrainz-mpd/cache.sqlite3";
      mpd.address = "${config.services.mpd.network.listenAddress}:${builtins.toString config.services.mpd.network.port}";
    };
  };

  systemd.user = {
    services.listenbrainz-mpd = {
      Unit.After = [ "mpd.service" ];
      Install.WantedBy = [ "mpd.service" ];

      Service.Environment = [
        "ENTRY=${nixosConfig.networking.fqdnOrHostName}/listenbrainz-mpd"
        "PATH=${lib.getBin config.programs.password-store.package}/bin"
      ];
      Service.ExecStartPre = builtins.toString (pkgs.writeShellScript "listenbrainz-mpd-secret" ''
        : ''${XDG_RUNTIME_DIR:?}
        umask 0077
        exec pass "$ENTRY" > "$XDG_RUNTIME_DIR/listenbrainz-mpd.secret"
      '');
      Service.ExecStopPre = [ "${pkgs.coreutils}/bin/rm -f %t/listenbrainz-mpd.secret" ];
    };

    services.mpdscribble = {
      Unit = {
        Description = pkgs.mpdscribble.meta.description;
        PartOf = [ "default.target" ];
        After = [ "mpd.service" ];
      };
      Install.WantedBy = [ "mpd.service" ];

      Service = {
        Type = "simple";
        ExecStart = [ "${mpdscribble}/bin/mpdscribble -D" ];
      };
    };
  };

  services.mpdris2 = {
    inherit (config.services.mpd) enable;
    mpd = {
      inherit (config.services.mpd) musicDirectory;
      host = config.services.mpd.network.listenAddress;
    };
  };

  services.mpris-proxy.enable = true;

  services.sxhkd.keybindings =
    let
      mpc-toggle = pkgs.writeShellScript "mpc-toggle" ''
        c=$(${pkgs.mpc-cli}/bin/mpc playlist | wc -l)
        [ "$c" -gt 0 ] || ${pkgs.mpc-cli}/bin/mpc add /
        ${pkgs.mpc-cli}/bin/mpc "$@" toggle
      '';
    in
    {
      "XF86AudioPlay" = "${mpc-toggle} -q";
      "shift + XF86AudioPlay" = "${pkgs.mpc-cli}/bin/mpc -q stop";

      "XF86AudioPrev" = "${pkgs.mpc-cli}/bin/mpc -q cdprev";
      "XF86AudioNext" = "${pkgs.mpc-cli}/bin/mpc -q next";

      "shift + XF86AudioPrev" = "${pkgs.mpc-cli}/bin/mpc -q consume";
      "shift + XF86AudioNext" = "${pkgs.mpc-cli}/bin/mpc -q random";
    };

  persist.directories = [
    { method = "bindfs"; directory = "audio"; }
    { method = "symlink"; directory = "share/mpd"; }
    { method = "symlink"; directory = "etc/audacity"; }
  ];

  cache.directories = [
    { method = "symlink"; directory = "share/cantata"; }
    { method = "symlink"; directory = "var/cache/cantata"; }
    { method = "symlink"; directory = "var/cache/listenbrainz-mpd"; }
    { method = "symlink"; directory = "var/cache/mpdscribble"; }
  ];

  home.packages = [
    envtag

    pkgs.audacity

    pkgs.mpc-cli

    mpdscribble

    (pkgs.symlinkJoin rec {
      name = "cantata-with-pass";

      runtimeInputs = [ config.programs.password-store.package pkgs.coreutils ];

      paths = [
        # Can't use a FIFO for the configuration- cantata seems to do something
        # funky at program start that causes it to need an additional write after
        # being closed for the first time; and after that, it does more r/w...
        (pkgs.writeShellScriptBin "cantata" ''
          export PATH="${lib.makeBinPath runtimeInputs}:$PATH"

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
          (exec -a cantata ${cantata}/bin/cantata -n "$@"); e=$?
          rm -f "$XDG_CONFIG_HOME/cantata/cantata.conf"
          exit "$e"
        '')

        cantata
      ];
    })
  ];
}
