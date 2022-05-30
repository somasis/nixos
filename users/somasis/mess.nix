# mess - Set up `mess` integration.
{ config, pkgs, ... }:
let
  mess = pkgs.writeShellScriptBin "mess" ''
    usage() {
        printf 'usage: %s [-s]\n' "''${0##*/}" >&2
        exit 69
    }

    print_sh() {
        cat <<'EOF'
    mess() {
        if [ $# -eq 0 ]; then
            cd "$(command mess)" && return
        else
            command mess "$@"
        fi
    }
    EOF
        exit 0
    }

    MESSDIR=''${MESSDIR:-~/mess}

    while getopts :s arg >/dev/null 2>&1; do
        case "''${arg}" in
            s)
                print_sh
                ;;
            ?)
                printf "unknown argument -- %s\n" "''${OPTARG}"
                usage
                ;;
        esac
    done

    # Avoid weeks 00 and 53 in the week number, make it more like natural language.
    week=$(date +%W)
    case "''${week}" in 00) week=01 ;; 53) week=52 ;; esac

    current=$(date +%Y/"''${week}")

    if ! [ -d "''${MESSDIR}/''${current}" ]; then
        mkdir -p "''${MESSDIR}/''${current}"
        mkdir -p "''${MESSDIR}/''${current}/incoming" "''${MESSDIR}/''${current}/src"
        printf "Created messdir '%s'.\n" "''${current}" >&2
    fi

    [ "$(readlink -f "''${MESSDIR}/current")" = "''${MESSDIR}/''${current}" ] \
        || {
             rm -f "''${MESSDIR}"/current
             ln -sf "''${current}" "''${MESSDIR}/current"
        }

    printf '%s\n' "''${MESSDIR}/current"
  '';
in
{
  home.packages = [ mess ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "mess" ];

  xdg.userDirs = {
    desktop = "${config.home.homeDirectory}/mess/current";
    download = "${config.home.homeDirectory}/mess/current/incoming";
  };

  systemd.user.timers.mess = {
    Unit.Description = "Manage ~/mess at the top of every hour and at boot";
    Timer = {
      OnCalendar = "hourly";
      OnClockChange = true;
      OnStartupSec = 0;
      AccuracySec = "1h";
      Persistent = true;
    };
    Install.WantedBy = [ "timers.target" ];
  };

  systemd.user.services.mess = {
    Unit.Description = "Maintain ~/mess directory hierarchy";
    Service.Type = "oneshot";
    Service.ExecStart = "mess";
    Service.StandardOutput = "null";
    Install.WantedBy = [ "default.target" ];
  };

  programs.bash.initExtra = ''
    eval "$(mess -s)"

    mkdir -p ~/mess/current/src >/dev/null 2>&1

    src() {
        CDPATH="$HOME/mess/current/src:$HOME/src:$HOME/src/nix:$HOME/src/discord" cd "''${@:-}"
    }

    CDPATH="''${CDPATH:+$CDPATH:}$HOME/mess:$HOME/mess/current"
  '';
}
