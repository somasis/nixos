{ pkgs, config, ... }:
let
  wallpaperctl =
    pkgs.writeShellApplication {
      name = "wallpaperctl";

      runtimeInputs = [
        pkgs.hsetroot
        pkgs.s6-portable-utils
        pkgs.systemd
      ];

      text = ''
        usage() {
            cat >&2 <<EOF
        usage: ''${0##*/} set [hsetroot arguments]
               ''${0##*/} restore

        EOF
            hsetroot -help >&2
            exit 69
        }

        cfg="''${XDG_CONFIG_HOME:-$HOME/.config}/wallpaper"
        mkdir -p "$cfg"

        [ "$#" -gt 0 ] || usage

        mode="''${1}"
        shift

        case "$mode" in
            set)
                [ "$#" -gt 1 ] || usage

                args=
                for a; do
                    a=$(s6-quote -d \' -u -- "$a")
                    args="''${args:+$args }'$a'"
                done

                printf '+ hsetroot %s\n' "$args" >&2
                if hsetroot "$@"; then
                    printf '%s\n' "$args" > "$cfg"/args
                else
                    exec hsetroot -help >&2
                fi
                ;;
            restore)
                if ! [ -s "$cfg"/args ]; then
                    printf 'error: no arguments set\n' >&2
                    exit 127
                fi

                args=$(cat "$cfg"/args)
                eval "set -- $args"

                printf '+ hsetroot %s\n' "$args" >&2
                if hsetroot "$@"; then
                    exit
                else
                    exec hsetroot -help >&2
                fi
                ;;
            *)
                usage
                ;;
        esac
      '';
    };
in
{
  home.packages = [ wallpaperctl ];
  home.persistence."/persist${config.home.homeDirectory}".directories = [ "etc/wallpaper" ];

  systemd.user.services.wallpaper = {
    Unit.Description = "Set wallpaper";
    Service.Type = "oneshot";
    Service.ExecStart = "${wallpaperctl}/bin/wallpaperctl restore";
    Service.Restart = "no";

    Unit.After = [ "picom.service" ];
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.PartOf = [ "graphical-session.target" ];
  };

  programs.autorandr.hooks.postswitch."wallpaper" = "${pkgs.systemd}/bin/systemctl --user start wallpaper.service";
}
