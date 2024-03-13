{ lib
, pkgs
, config
, osConfig
, ...
}:
let
  inherit (config.lib.file) mkOutOfStoreSymlink;
  inherit (config.lib.somasis) xdgConfigDir xdgDataDir;

  # Get Wine used by system (or specified by user)
  wine =
    let default = pkgs.wine; in
    lib.lists.findFirst
      (pkg:
        (lib.hasPrefix "wine" (lib.getName pkg))
        # && (lib.hasPrefix "wine" (lib.getExe pkg))
        && (lib.hasAttr "homepage" pkg.meta)
        && (pkg.meta.homepage == (default.meta.homepage or null))
      )
      default
      (config.home.packages ++ (osConfig.environment.systemPackages or [ ]))
  ;
in
{
  home = {
    packages = [
      # pkgs.winetricks
      # pkgs.wineWowPackages.stableFull
      # pkgs.wineWow64Packages.stableFull
      # pkgs.wineasio

      (pkgs.wineprefix.override { inherit wine; })
    ];

    # Disable all of Wine's fixme messages.
    sessionVariables.WINEDEBUG = "fixme-all";

    # Integrate default wineprefix into wineprefix setup
    file.".wine".source = mkOutOfStoreSymlink "${config.xdg.configHome}/wineprefixes/default";
  };

  xdg.configFile = {
    "wineprefixes/init".source = pkgs.writeShellScript "wineprefix-init" ''
      : "''${TMPDIR:=/tmp}"

      ido() {
          # shellcheck disable=SC2015
          printf '$ %s\n' "$*" >&2 || :
          "$@"
      }

      reg() {
          : "''${1:?no operator provided}"

          # Disable all confirmation messages
          case "$1" in
              add|copy|delete) set -- "$@" /f ;;
              export) set -- "$@" /y ;;
          esac

          wine reg "$@" >/dev/null
      }

      reg_query() {
          PATH=${lib.makeBinPath [ pkgs.gnused ]}"''${PATH:+:$PATH}"

          local query
          if query=$(reg query "$@" 2>/dev/null); then
               sed '3 { s/^    //; s/.*    //; s/.*    //; s/\r$//; !d; q; }; d' <<< "$query"
          else
               return 1
          fi
      }

      reg_sync() {
          local path="''${1:?no path provided}"; shift
          local key data

          local reg_add_args=( "$path" )

          while [[ "$#" -gt 0 ]]; do
              case "$1" in
                  /v)
                      reg_add_args+=( "$1" "$2" )
                      key="$2"
                      shift
                      ;;
                  /d)
                      reg_add_args+=( "$1" "$2" )
                      data="$2"
                      shift
                      ;;
                  *) reg_add_args+=( "$1" ) ;;
              esac
              shift
          done

          : "''${key:?no key provided}"

          local current_data
          if current_data=$(reg_query "$path" /v "$key") && [[ "$current_data" == "''${data:-}" ]]; then
              return
          else
              reg add "''${reg_add_args[@]}"
          fi
      }

      {
          # Set Wine DPI automatically based off of current display settings

          PATH=${lib.makeBinPath [ pkgs.xorg.xrdb ]}"''${PATH:+:$PATH}"

          dpi=$(xrdb -get Xft.dpi 2>/dev/null || echo 96)
          dpi=$(printf '0x%X' "$dpi")

          reg_sync \
              'HKEY_LOCAL_MACHINE\System\CurrentControlSet\Hardware Profiles\Current\Software\Fonts' \
              /v 'LogPixels' /t REG_DWORD /d "$dpi"
      }

      {
          # Disable win64 warnings from winetricks
          touch "$WINEPREFIX/no_win64_warnings"
          export WINE=wine
          export WINE64=wine
          export WINE_MULTI=wine
      }

      {
          # Disable managing XDG file associations
          reg_sync 'HKEY_CURRENT_USER\Software\Wine\FileOpenAssociations' /v Enable /d N
      }

      # {
      #     # Create free font associations
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Arial'           /v 'Liberation Sans'
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Arial Narrow'    /v 'Liberation Sans Narrow'
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Comic Sans MS'   /v 'Comic Relief'
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Courier New'     /v 'Liberation Mono'
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Georgia'         /v 'Gelasio'
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Helvetica'       /v 'Liberation Sans'
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Times New Roman' /v 'Liberation Serif'
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Calibri'         /v 'Carlito'
      #     reg_sync 'HKEY_CURRENT_USER\Software\Wine\Fonts\Cambria'         /v 'Caladea'
      # }

      {
          # Ensure Wine's C:\Users\<user>\Temp directory is on $TMPDIR
          # <https://wiki.archlinux.org/title/Wine#Temp_directory_on_tmpfs>
          : "''${TMPDIR:=/tmp}"

          for temp in "$WINEPREFIX/drive_c/users/$USER/Temp" "$WINEPREFIX/drive_c/windows/temp"; do
              if ! [[ -L "$temp" ]]; then
                  rm -rf "$temp"
                  ln -s "$TMPDIR" "$temp"
              fi
          done
      }

      # {
      #     # Add device symlinks
      #     ln -sf -n / "$WINEPREFIX"/dosdevices/z:
      # }
    '';

    # "wineprefixes/music.init".source = pkgs.writeShellScript "wineprefixes-init-music" ''
    # '';
  };

  persist.directories = [
    # { method = "symlink"; directory = xdgConfigDir "wineprefixes"; }
    (xdgConfigDir "wineprefixes")
    { method = "symlink"; directory = xdgDataDir "wineprefixes"; }
  ];
}
