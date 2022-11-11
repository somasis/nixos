{ nixosConfig, config, pkgs, ... }:
let
  xdgRuntimeDir = "/run/user/${toString nixosConfig.users.users.${config.home.username}.uid}";

  pass-mopidy-subidy = (pkgs.writeShellApplication {
    name = "pass-mopidy-subidy";
    runtimeInputs = [
      config.programs.password-store.package
      pkgs.coreutils
    ];

    text = ''
      set -eu
      set -o pipefail

      umask 0077

      : "''${XDG_CONFIG_HOME:=$HOME/.config}"
      : "''${XDG_RUNTIME_DIR:=/run/user/$(id -un)}"

      pass "$1" >/dev/null 2>&1 || exit 1

      cat > "$XDG_RUNTIME_DIR"/pass-mopidy-subidy.ini <<EOF
      [subidy]
      password = $(pass "$1")
      EOF
    '';
  });
in
{
  services.mopidy = {
    enable = true;
    extensionPackages = [
      # pkgs.mopidy-beets
      # pkgs.mopidy-scrobbler
      # pkgs.mopidy-somafm

      # pkgs.mopidy-iris

      # pkgs.mopidy-local
      pkgs.mopidy-mpd
      pkgs.mopidy-subidy
    ];

    settings = {
      core.restore_state = true;

      file = {
        enabled = true;
        media_dirs = config.xdg.userDirs.music;
        # album_art_files = [ "cover" ]

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

      http.enabled = true;

      # iris = {
      #   enabled = true;
      #   country = "us";
      #   locale = "en_US";
      # };

      # https://github.com/mopidy/mopidy-mpd#configuration
      mpd = {
        enabled = true;
        hostname = "unix:${xdgRuntimeDir}/mopidy-mpd.sock";
        command_blacklist = [ ];
      };

      subidy = {
        enabled = true;
        url = "https://airsonic.7596ff.com";
        username = "somasis";
      };

      # beets = {
      #   hostname = "127.0.0.1";
      #   port = 8337;
      # };
    };

    extraConfigFiles = [ "${xdgRuntimeDir}/pass-mopidy-subidy.ini" ];
  };

  systemd.user.services."pass-mopidy-subidy" = {
    Unit = {
      Description = "Authenticate `mopidy-subidy` using `pass`";
      PartOf = [ "default.target" ];

      Before = [ "mopidy.service" ];

      After = [ "gpg-agent.service" ];
    };
    Install.WantedBy = [ "default.target" "mopidy.service" ];

    Service = {
      Type = "oneshot";
      RemainAfterExit = true;

      ExecStart = [ "${pass-mopidy-subidy}/bin/pass-mopidy-subidy spinoza.7596ff.com/airsonic/somasis" ];
      ExecStop = [ "${pkgs.coreutils}/bin/rm -f %t/pass-mopidy-subidy.ini" ];
    };
  };
}
