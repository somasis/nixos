{ nixosConfig, config, pkgs, ... }:
let
  xdgRuntimeDir = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}";
in
{
  services.mopidy = {
    enable = true;
    extensionPackages = [
      pkgs.mopidy-mpd
      pkgs.mopidy-scrobbler
      pkgs.mopidy-somafm
      # pkgs.mopidy-beets
      pkgs.mopidy-iris
    ];

    settings = {
      core.restore_state = true;

      iris.enabled = true;

      file = {
        media_dirs = [ config.xdg.userDirs.music ];
        excluded_file_extensions = [
          ".html"
          ".zip"
          ".jpg"
          ".jpeg"
          ".png"
          ".tiff"
          ".tif"
          ".gif"
          ".cue"
          ".log"
        ];
      };

      # https://github.com/mopidy/mopidy-mpd#configuration
      mpd = {
        enabled = true;
        hostname = "unix:${xdgRuntimeDir}/mopidy-mpd.sock";
      };

      # beets = {
      #   hostname = "127.0.0.1";
      #   port = 8337;
      # };
    };
  };
}
