{ config
, nixosConfig
, lib
, pkgs
, ...
}:
let
  cantataConf = pkgs.writeText "cantata-config" (lib.generators.toINI
    {
      mkKeyValue = key: value:
        let
          value' =
            if builtins.isList value && value == [ ] then
              "@Invalid()"
            else if builtins.isBool value then
              lib.boolToString value
            else if builtins.isList value then
              lib.concatStringsSep '', '' value
            else
              builtins.toString value
          ;
        in
        "${key}=${value'}"
      ;
    }
    {
      # # TODO this in setting particular should be functionalized, this is annoying
      # CustomActions = {
      #   # %f file list, %d directory list, else list of files is appended to command
      #   count = 1;
      #   0_name = "Open lossless";
      #   0_cmd = "${beet-show-lossless} %d";
      # };

      General.version = pkgs.cantata.version; # necessary to avoid the first-start dialog

      General.page = "PlayQueuePage"; # Default the starting page to play queue
      General.contextSlimPage = "song"; # Default the track info to lyrics + song info

      # Collection
      Connection.host = config.services.mpd.network.listenAddress;
      Connection.dir = config.services.mpd.musicDirectory;

      Connection.allowLocalStreaming = true; # Local file playback: "via-in-built HTTP server"
      Connection.autoUpdate = false; # "Server detects changes automatically"

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
      General.playQueueView = "grouped"; # style: "grouped albums"
      General.playQueueStartClosed = false; # "initially collapse albums"
      General.playQueueAutoExpand = true; # "automatically expand current album"
      General.playQueueScroll = true; # "scroll to current track"
      General.playQueueConfirmClear = false; # "prompt before clearing"
      General.playQueueSearch = true; # "separate action (and shortcut) for play queue search"

      General.playQueueBackground = 1; # background image: "current album cover"
      General.playQueueBackgroundBlur = 20;
      General.playQueueBackgroundOpacity = 20;

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

  cantata = pkgs.cantata.override {
    withTaglib = false;
    withReplaygain = false;
    withMtp = false;
    withOnlineServices = false;
    withDevices = false;
  };
in
{
  imports = [
    ../music/manage
    ../music/play.nix
  ];

  home.persistence = {
    "/persist${config.home.homeDirectory}".directories = [{ directory = "audio"; method = "symlink"; }];
    "/cache${config.home.homeDirectory}".directories = [
      "share/cantata"
      "var/cache/cantata"
    ];
  };

  home.packages = [
    pkgs.mpc-cli

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
          sessionKey=$(pass ${nixosConfig.networking.fqdn}/cantata/last.fm)
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
