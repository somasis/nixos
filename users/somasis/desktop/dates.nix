{ config, pkgs, ... }:
let
  dates = pkgs.writeShellApplication {
    name = "dates";

    runtimeInputs = [ pkgs.coreutils ];

    text = ''
      : "''${XDG_CONFIG_HOME:=''${HOME}/.config}"

      format='%-19s %s\n'
      date_format=
      show_local=true

      usage() {
          cat >&2 <<EOF
      usage: ''${0##*/} [-L] [-f FORMAT] [+DATE_FORMAT] [NAMES...]
      EOF
          exit 69
      }

      mkdir -p "''${XDG_CONFIG_HOME}"/dates
      cd "''${XDG_CONFIG_HOME}"/dates || exit $?

      while getopts :Lf: arg >/dev/null 2>&1; do
          case "''${arg}" in
              L) show_local=false ;;
              f) format="''${OPTARG}" ;;
              ?) usage ;;
          esac
      done
      shift $((OPTIND - 1))

      case "''${1:-}" in
          +*)
              date_format="''${1}"
              shift
              ;;
      esac

      [[ "$#" -gt 0 ]] || set -- *

      while [[ $# -gt 0 ]]; do
          name="''${1}"

          if [[ "$1" = _ ]]; then
              if [[ "''${show_local}" = true ]]; then
                  name=local
              else
                  shift
                  continue
              fi
          elif [[ -f /etc/zoneinfo/"''${1}" ]]; then
              TZ="''${1}"
          elif [[ -e "''${1}" ]]; then
              TZ=:"$(readlink -f "''${1}")"
          else
              printf 'error: timezone "%s" does not exist\n' "''${name}" >&2
              exit 1
          fi
          export TZ

          # Don't yell about us using ''${variables} in printf's format, it's meant to be user-customized.
          # shellcheck disable=SC2059,SC2312
          printf "''${format}" "''${name}" "$(date ''${date_format:+"''${date_format}"})"
          shift
      done
    '';
  };
in
{
  xdg.configFile."dates/_".source = "${pkgs.tzdata}/share/zoneinfo/America/New_York";

  home.packages = [ dates ];

  somasis.chrome.stw.widgets = [
    {
      command = ''
        ${dates}/bin/dates -L -f "%-10s%s\n" +"%Y-%m-%d %I:%M %p"
      '';

      text.font = "monospace:style=heavy:size=10";
      window.color = config.xresources.properties."*color4";
      text.color = config.xresources.properties."*darkForeground";
      window.opacity = 0.15;
      window.position.x = -24;
      window.position.y = 72;
      window.padding = 12;
      update = 60;
    }
  ];
}

