{ config, pkgs, ... }: {
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "video" ];
  xdg.userDirs.videos = "${config.home.homeDirectory}/video";

  programs.mpv = {
    enable = true;

    config = {
      hwdec = "auto-safe";

      # Use yt-dlp's format preference.
      ytdl-format = "ytdl";

      script-opts = ""
        # + "thumbnail-osc=false,"

        # https://github.com/po5/mpv_sponsorblock/issues/31
        + "sponsorblock-local_database=no,"
        + "sponsorblock-server_address=https://sponsor.ajay.app"
      ;


      # mpvScripts.thumbnail
      # thumbnail_network = true;
    };

    scripts = [
      pkgs.mpvScripts.mpris
      pkgs.mpvScripts.sponsorblock
      # pkgs.mpvScripts.thumbnail

      # Conflicts with mpvScripts.thumbnail
      # pkgs.mpvScripts.youtube-quality
    ];
  };

  xdg.mimeApps.defaultApplications."video/*" = "mpv.desktop";

  programs.yt-dlp = {
    enable = true;

    settings = {
      format = "bestvideo[height<=?1080][fps<=?30]+bestaudio/best";
    };
  };
}
