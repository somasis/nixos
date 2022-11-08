{ config, pkgs, ... }:
let
  dates = (pkgs.writeShellApplication {
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
  });
in
{
  xdg.configFile = {
    "dates/_".source = "${pkgs.tzdata}/share/zoneinfo/America/New_York";
    "dates/violet".source = "${pkgs.tzdata}/share/zoneinfo/Australia/Adelaide";
    "dates/zeyla".source = "${pkgs.tzdata}/share/zoneinfo/America/Los_Angeles";
  };

  home.packages = [ dates ];

  systemd.user.services.stw-dates = {
    Unit = {
      Description = "Show other timezones on desktop";
      PartOf = [ "stw.target" ];
      StartLimitInterval = 0;
    };
    Install.WantedBy = [ "stw.target" ];

    Service = {
      Type = "simple";
      ExecStart =
        let
          stw-dates = ''
            ${dates}/bin/dates -L -f "%-10s%s\n" +"%Y-%m-%d %I:%M %p"
          '';
        in
        ''
          ${pkgs.stw}/bin/stw \
              -F "monospace:style=heavy:size=10" \
              -b "${config.xresources.properties."*color4"}" \
              -f "${config.xresources.properties."*darkForeground"}" \
              -A .15 \
              -x -24 -y 72 \
              -B 12 \
              -p 60 \
              ${pkgs.writeShellScript "dates" stw-dates}
        '';
    };
  };
}

