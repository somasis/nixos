{ config
, lib
, pkgs
, ...
}: {
  xdg.userDirs.videos = "${config.home.homeDirectory}/video";

  persist.directories = [{ directory = "video"; method = "symlink"; }];
  cache.directories = [{ directory = "var/cache/mpv"; method = "symlink"; }];

  programs.mpv =
    let
      pathList = lib.concatStringsSep ":";
      commaList = lib.concatStringsSep ",";
    in
    {
      enable = true;

      config = {
        hwdec = "auto-safe";

        # Use yt-dlp's format preference.
        ytdl-format = "ytdl";

        alang = commaList [ "jpn" "en" ];
        slang = commaList [ "en" "en-US" "en-GB" ];

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

        save-position-on-quit = true;
        watch-later-directory = "${config.xdg.cacheHome}/mpv/watch_later";
        resume-playback-check-mtime = true;
        watch-later-options-remove = commaList [ "volume" "mute" ];

        # mpvScripts.thumbnail
        # thumbnail_network = true;
      };

      scriptOpts = {
        # thumbnail.osc = false;

        # https://github.com/po5/mpv_sponsorblock/issues/31
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
          pkgs.mpvScripts.mpris
          pkgs.mpvScripts.sponsorblock
          # pkgs.mpvScripts.thumbnail

          # Conflicts with mpvScripts.thumbnail
          pkgs.mpvScripts.youtube-quality
        ];
      };
    };

  xdg.mimeApps.defaultApplications."video/*" = "mpv.desktop";

  programs.yt-dlp = {
    enable = true;

    settings = {
      format = "bestvideo[height<=?1080][fps<=?30]+bestaudio/best";
      trim-filenames = 48;
      # audio-multistreams = true;
    };
  };
}
