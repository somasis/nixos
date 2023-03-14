{ config
, lib
, pkgs
, ...
}: {
  xdg.userDirs.videos = "${config.home.homeDirectory}/video";

  home.persistence."/persist${config.home.homeDirectory}".directories = [
    { directory = "video"; method = "symlink"; }
  ];

  programs.mpv = {
    enable = true;

    config =
      let
        pathList = lib.concatStringsSep ":";
        commaList = lib.concatStringsSep ",";
      in
      {
        hwdec = "auto-safe";

        # Use yt-dlp's format preference.
        ytdl-format = "ytdl";

        script-opts = commaList [
          # "thumbnail-osc=false"

          # https://github.com/po5/mpv_sponsorblock/issues/31
          "sponsorblock-local_database=no"
          "sponsorblock-server_address=https://sponsor.ajay.app"
        ];

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

        osd-font = "monospace";
        osd-font-size = 48;

        osd-on-seek = "msg-bar";

        osd-fractions = true;

        osd-margin-x = 24;
        osd-margin-y = 24;

        # mpvScripts.thumbnail
        # thumbnail_network = true;
      };

    # Use TZ=UTC for `mpv` so that screenshot-template always uses UTC time.
    # We can't use programs.mpv.scripts because of this being set.
    package = pkgs.wrapMpv pkgs.mpv-unwrapped {
      extraMakeWrapperArgs = [ "--set" "TZ" "UTC" ];

      scripts = [
        pkgs.mpvScripts.mpris
        pkgs.mpvScripts.sponsorblock
        # pkgs.mpvScripts.thumbnail

        # Conflicts with mpvScripts.thumbnail
        # pkgs.mpvScripts.youtube-quality
      ];
    };
  };

  xdg.mimeApps.defaultApplications."video/*" = "mpv.desktop";

  programs.yt-dlp = {
    enable = true;

    settings = {
      format = "bestvideo[height<=?1080][fps<=?30]+bestaudio/best";
      trim-filenames = 48;
      audio-multistreams = true;
    };
  };
}
