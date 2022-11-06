# mess - Set up `mess` integration.
{ config, pkgs, ... }:
let
  mess = pkgs.writeShellApplication {
    name = "mess";

    runtimeInputs = [ pkgs.coreutils ];

    text = ''
      set -eu
      set -o pipefail

      usage() {
          printf 'usage: %s\n' "''${0##*/}" >&2
          exit 69
      }

      : "''${MESSDIR:=$HOME/mess}"

      [ "$#" -gt 0 ] && usage

      # Avoid weeks 00 and 53 in the week number, make it more like natural language.
      week=$(date +%W)
      case "''${week}" in 00) week=01 ;; 53) week=52 ;; esac

      current=$(date +%Y/"''${week}")

      if ! [ -d "''${MESSDIR}/''${current}" ]; then
          mkdir -p "''${MESSDIR}/''${current}"
          printf "Created mess '%s'.\n" "''${current}" >&2
      fi

      if ! [ "$(readlink -f "''${MESSDIR}/current")" = "''${MESSDIR}/''${current}" ]; then
          rm -f "''${MESSDIR}"/current
          ln -sf "''${current}" "''${MESSDIR}/current"
      fi

      printf '%s\n' "''${MESSDIR}/current"
    '';
  };
in
{
  home.packages = [ mess ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "mess" ];

  xdg.userDirs = {
    desktop = "${config.home.homeDirectory}/mess/current";
    download = "${config.home.homeDirectory}/mess/current/incoming";
  };

  systemd.user = {
    services.mess = {
      Unit.Description = "Maintain ~/mess directory hierarchy";

      Service = {
        Type = "oneshot";
        ExecStart = "mess";
        ExecStartPost = [
          ''${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/mess/current/incoming"''
          ''${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/mess/current/src"''
          ''${pkgs.coreutils}/bin/mkdir -p "${config.home.homeDirectory}/mess/current/screenshots"''
        ];

        StandardOutput = "null";
      };

      Install.WantedBy = [ "default.target" ];
    };

    timers.mess = {
      Unit.Description = "Manage ~/mess at the top of every hour and at boot";

      Timer = {
        OnCalendar = "hourly";
        OnClockChange = true;
        OnStartupSec = 0;
        Persistent = true;
      };

      Install.WantedBy = [ "timers.target" ];
    };
  };

  programs.bash.initExtra = ''
    mess() {
        if [ "$#" -eq 0 ]; then
            cd "$(command mess)"
        else
            command mess "$@"
        fi
    }

    src() {
        CDPATH="$HOME/mess/current/src:$HOME/src:$HOME/src/nix:$HOME/src/discord" cd "''${@:-}"
    }

    CDPATH="''${CDPATH:+$CDPATH:}$HOME/mess:$HOME/mess/current"
  '';
}
