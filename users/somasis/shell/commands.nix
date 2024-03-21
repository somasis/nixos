{ config
, pkgs
, lib
, osConfig
, ...
}:
let
  commaPicker = lib.optionalString (config.programs.dmenu.enable or config.programs.skim.enable) (pkgs.writeShellScript "comma-picker" ''
    if [ -t 0 ]; then
        ${lib.optionalString config.programs.dmenu.enable "exec dmenu -p ',' -S 2>/dev/null"}
    else
        ${lib.optionalString config.programs.skim.enable "exec sk -p ', ' --no-sort 2>/dev/null"}
    fi
  '');
in
{
  home.shellAliases = rec {
    # LC_COLLATE=C sorts uppercase before lowercase.
    ls = "LC_COLLATE=C ls --hyperlink=auto --group-directories-first --dereference-command-line-symlink-to-dir --time-style=iso --color -AFlh";
    vi = "$EDITOR";

    ip = "ip --color=auto";

    # Quick ssh aliases
    "ascii.town" = "ssh play@ascii.town";
    "2048" = "ssh -t play@ascii.town 2048";
    "snake" = "ssh -t play@ascii.town snake";

    bc = "bc -q";

    xz = "xz -T0 -9 -e";
    zstd = "zstd -T0 -19";
    gzip = "pigz -p $(( $(nproc) / 2 )) -9";

    sys = "systemctl -l --legend=false";
    user = "systemctl --user";
    journal = "journalctl -e";
    syslog = "${journal} -b 0";
    userlog = "${syslog} --user";
    bus = "busctl --verbose -j";

    wget = "curl -q -Lf# -Z --no-clobber --remote-name-all --remote-header-name --remove-on-error --retry 20 --retry-delay 10";

    since = "datediff -f '%Yy %mm %ww %dd %0Hh %0Mm %0Ss'";

    doas = lib.optionalString osConfig.security.sudo.enable "sudo";

    which = "{ alias; declare -f; } | which --read-functions --read-alias";
  };

  home.packages = [
    pkgs.nocolor

    (pkgs.writeShellScriptBin "execurl" ''
      fetch_directory=$(${pkgs.coreutils}/bin/mktemp -d)

      fetch() {
          local file

          printf '%s\n' "$1" >&2
          file=$(
              ${pkgs.curl}/bin/curl \
                  -g \
                  -Lfs# \
                  --output-dir "$fetch_directory" \
                  --remote-header-name \
                  --remote-name-all \
                  --remove-on-error \
                  -w '%{filename_effective}\n' \
                  "$1"
          )

          printf '%s\n' "$file"
      }

      error_code=0
      arguments=()

      for argument; do
          if ${pkgs.trurl}/bin/trurl --no-guess-scheme --verify --url "$argument" >/dev/null 2>&1; then
              arguments+=( "$(fetch "$argument")" )
          else
              arguments+=( "$argument" )
          fi
      done

      "''${arguments[@]}" || error_code=$?
      ${pkgs.coreutils}/bin/rm -rf "$fetch_directory"
      exit "$error_code"
    '')

    (pkgs.writeShellScriptBin "pe" ''
      ${lib.getExe pkgs.xe} -LL -j0 "$@" | sort -snk1 | cut -d' ' -f2-
    '')

    (if commaPicker != "" then
      (pkgs.wrapCommand {
        package = pkgs.comma;
        wrappers = [{ command = "/bin/,"; setEnvironmentDefault.COMMA_PICKER = commaPicker; }];
      })
    else
      pkgs.comma
    )

    (pkgs.writeShellScriptBin "edo" ''
      # <https://stackoverflow.com/questions/2683279/how-to-detect-if-a-script-is-being-sourced/14706745#14706745
      _edo_is_sourced=0
      if [ -n "$ZSH_VERSION" ]; then
          case "$ZSH_EVAL_CONTEXT" in *':file') _edo_is_sourced=1 ;; esac
      elif [ -n "$KSH_VERSION" ]; then
          test \
              "$(cd -- "$(dirname -- "$0")" && pwd -P)/$(basename -- "$0")" \
              != "$(cd -- "$(dirname -- "''${.sh.file}")" && pwd -P)/$(basename -- "''${.sh.file}")" ] \
              && _edo_is_sourced=1
      elif [ -n "$BASH_VERSION" ]; then
          ( return 0 2>/dev/null ) && _edo_is_sourced=1
      else
          # All other shells: examine $0 for known shell binary filenames.
          # Detects `sh` and `dash`; add additional shell filenames as needed.
          case "''${0##*/}" in sh|-sh|dash|-dash) _edo_is_sourced=1;; esac
      fi

      edo() {
          _edo_string="$"
          for _edo_arg; do
              _edo_string+=" ''${_edo_arg//\'/\'\\\'\'}"
          done

          printf '%s\n' "$_edo_string" >&2 || :
          "$@"
      }

      if [ "$_edo_is_sourced" -eq 0 ]; then
          edo "$@"
      fi
    '')
  ];

  programs.bash.initExtra = ''
    . edo

    # ... | peek [COMMAND...] | ...
    peek() {
        if [[ "$#" -eq 0 ]]; then
            tee /dev/stderr
        else
            tee >("$@" >&2)
        fi
    }

    # Spawn a new terminal, detached from the current one, inheriting environment and working directory.
    newt() (
        nohup terminal "$@" >/dev/null 2>&1 &
    )

    man() {
          local man_args=( "$@" )

          local COMMA_NIXPKGS_FLAKE COMMA_PICKER
          : "''${COMMA_NIXPKGS_FLAKE:=nixpkgs}"
          ${lib.toShellVar "COMMA_PICKER" commaPicker}

          local MANPATH="$MANPATH"
          local old_MANPATH="$MANPATH"

          local man_sections man_section new_man_path
          mapfile -t man_sections < <(
              IFS=:

              if [[ "''${MANPATH:0:1}" == : ]]; then
                  local MANPATH=( ''${MANPATH:1} )
              else
                  local MANPATH=( ''${MANPATH} )
              fi
              unset IFS

              find -L \
                  "''${MANPATH[@]}" \
                  -mindepth 1 \
                  -type d \
                  -name 'man*' \
                  -printf '%f\n' \
                  | cut -c4- \
                  | sort -ud
          )

          MANPATH="$old_MANPATH"

          if command man -w "''${man_args[@]}" >/dev/null 2>&1; then
              command man "''${man_args[@]}"
          else
              local regex
              while [[ "$#" -ge 1 ]]; do
                  for man_section in "''${man_sections[@]}"; do
                      if [[ "$1" == "$man_section" ]] && [[ "$#" -ge 2 ]]; then
                          regex='/share/man/man'"$man_section"'/'"$2"'\.'"$man_section"
                          shift
                          break
                      else
                          regex='/share/man/man.*'/"$1"'\.'
                          break
                      fi
                  done
                  shift

                  new_man_path=$(nix-locate --minimal --at-root --regex "$regex" 2>/dev/null | grep -v '^(')
                  [[ -n "$new_man_path" ]] || continue

                  new_man_path=$(eval "$COMMA_PICKER" <<< "$new_man_path")
                  new_man_path=$(nix build --no-link --print-out-paths "$COMMA_NIXPKGS_FLAKE"#"$new_man_path")
                  new_man_path="$new_man_path/share/man"

                  case "$MANPATH" in
                      :*) MANPATH="$new_man_path$MANPATH" ;;
                      "") MANPATH="$new_man_path:" ;;
                      *)  MANPATH="$new_man_path:$MANPATH" ;;
                  esac
              done

              MANPATH="$MANPATH" command man "''${man_args[@]}"
          fi
    }
  '';
}
