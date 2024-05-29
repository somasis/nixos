{ pkgs, config, ... }:
let
  wallpaperctl = pkgs.writeShellApplication {
    name = "wallpaperctl";

    runtimeInputs = [ pkgs.coreutils pkgs.hsetroot ];

    excludeShellChecks = [ "SC2059" "SC1091" ];

    text = ''
      usage() {
          [[ "$#" -eq 0 ]] || printf "$@" >&2
          cat >&2 <<EOF
      usage: ''${0##*/} set <hsetroot arguments>
             ''${0##*/} restore

      EOF
          hsetroot -help >&2
          [[ "$#" -eq 0 ]] || exit 1
          exit 69
      }

      : "''${XDG_CONFIG_HOME:=$HOME/.config}"
      mkdir -p "$XDG_CONFIG_HOME/wallpaper"

      [[ "$#" -gt 0 ]] || usage

      mode=''${1:-'--help'}
      shift

      case "$mode" in
          --help) usage ;;
          set)
              [[ "$#" -gt 1 ]] || usage

              hsetroot_args=( "$@" )

              printf '$ hsetroot %s\n' "''${hsetroot_args[*]@Q}" >&2

              if hsetroot "''${hsetroot_args[@]}"; then
                  printf '%s' "''${hsetroot_args[*]@A}" > "$XDG_CONFIG_HOME"/wallpaper/args
              else
                  usage 'error: hsetroot exited unsuccessfully (error code: %i)\n' "$?"
              fi
              ;;
          restore)
              if ! [[ -s "$XDG_CONFIG_HOME"/wallpaper/args ]]; then
                  usage 'error: no arguments have been set yet\n'
              fi

              . "$XDG_CONFIG_HOME"/wallpaper/args

              printf '$ hsetroot %s\n' "''${hsetroot_args[*]@Q}" >&2
              if ! hsetroot "''${hsetroot_args[@]}"; then
                  usage 'error: hsetroot exited unsuccessfully (error code: %i)\n' "$?"
              fi
              ;;
          *)
              usage 'unknown argument -- %s\n' "$mode"
              ;;
      esac
    '';
  };
in
{
  home.packages = [ wallpaperctl ];

  persist.directories = [{
    method = "symlink";
    directory = config.lib.somasis.xdgConfigDir "wallpaper";
  }];

  systemd.user.services.wallpaper = {
    Unit.Description = "Set wallpaper";
    Service.Type = "oneshot";
    Service.ExecStart = "${wallpaperctl}/bin/wallpaperctl restore";
    Service.Restart = "no";

    Unit.After = [ "picom.service" ];
    Install.WantedBy = [ "graphical-session.target" ];
    Unit.PartOf = [ "graphical-session.target" ];
  };

  programs.autorandr.hooks.postswitch.wallpaper = ''
    ${pkgs.systemd}/bin/systemctl --user start wallpaper.service
  '';
}
