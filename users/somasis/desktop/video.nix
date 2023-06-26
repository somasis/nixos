{ config
, lib
, pkgs
, ...
}:
let
  inherit (config.lib.somasis) commaList;
  pathList = lib.concatStringsSep ":";
in
{
  xdg.userDirs.videos = "${config.home.homeDirectory}/video";

  persist.directories = [{ directory = "video"; method = "symlink"; }];
  cache.directories = [{ directory = "var/cache/mpv"; method = "symlink"; }];

  programs.mpv = {
    enable = true;

    config = {
      hwdec = "auto-safe";

      # Use yt-dlp's format preference.
      ytdl = true;
      ytdl-format = "ytdl";

      alang = commaList [ "jpn" "tok" "en" ];
      slang = commaList [ "en-US" "en" "tok" "es" ];

      sub-file-paths = pathList [ "sub" "Sub" "subs" "Subs" "subtitle" "Subtitle" "subtitles" "Subtitles" ];
      sub-auto = "fuzzy";
      sub-font = "monospace";
      sub-filter-regex-append = "opensubtitles\.org";

      cover-art-auto = "fuzzy";
      audio-display = false;

      image-display-duration = "inf";

      screenshot-format = "png";
      screenshot-template = "%tY-%tm-%tdT%tH:%tM:%tSZ %F %wH:%wM:%wf";
      screenshot-tag-colorspace = true;

      osd-font = "monospace";
      osd-font-size = 48;

      osd-on-seek = "msg-bar";

      osd-fractions = true;

      osd-margin-x = 24;
      osd-margin-y = 24;

      # Watch later preferences
      watch-later-directory = "${config.xdg.cacheHome}/mpv/watch-later";
      watch-later-options-remove = commaList [ "volume" "mute" ];
      save-position-on-quit = true;
      resume-playback-check-mtime = true;

      osc = false; # required for thumbnail
    };

    scriptOpts = {
      thumbnail = {
        osc = false;
        network = true;
      };

      osc = {
        windowcontrols = false;
        unicodeminus = true;
        hidetimeout = 1000;
        deadzonesize = 0;
        scalewindowed = 1.5;
        vidscale = false;
      };

      ytdl_hook.ytdl_path = "${config.programs.yt-dlp.package}/bin/yt-dlp";

      # <https://github.com/po5/mpv_sponsorblock/issues/31>
      sponsorblock = {
        local_database = false;
        server_address = "https://sponsor.ajay.app";
      };
    };

    package = pkgs.wrapMpv pkgs.mpv-unwrapped {
      # Use TZ=UTC for `mpv` so that screenshot-template always uses UTC time.
      extraMakeWrapperArgs = [ "--set" "TZ" "UTC" ];

      # We can't use programs.mpv.scripts because of this being set.
      scripts = [
        pkgs.mpvScripts.autoload
        pkgs.mpvScripts.mpris
        pkgs.mpvScripts.sponsorblock
        pkgs.mpvScripts.thumbnail

        # Conflicts with mpvScripts.thumbnail
        # pkgs.mpvScripts.youtube-quality
      ];
    };
  };

  xdg.mimeApps.defaultApplications."video/*" = "mpv.desktop";

  programs.yt-dlp = {
    enable = true;

    settings = {
      # Use bestvideo (but only >=1080p and >=30fps) and
      # bestaudio (from whichever stream has it)
      format = "bestvideo[height<=?1080][fps<=?30]+bestaudio/best";

      audio-multistreams = true;

      # Embed video metadata as much as possible
      embed-subs = true;
      # write-auto-subs = true;
      sub-langs = commaList [
        "en-US"
        "en.*"
        "tok"
        "es-en.*"
        "es-MX"
        "es.*"
      ];

      embed-chapters = true;

      embed-info-json = true;
      embed-metadata = true;
      embed-thumbnail = true;

      concurrent-fragments = 4;

      # Use cookies from qutebrowser if available
      cookies-from-browser = lib.mkIf config.programs.qutebrowser.enable
        "chromium:${config.xdg.dataHome}/qutebrowser/webengine";
      mark-watched = true;
    };
  };

  home.packages = [
    pkgs.catt
    pkgs.pulseaudio-dlna
  ];

  home.shellAliases.ytaudio = "yt-dlp --format bestaudio --extract-audio --audio-format wav";
}
