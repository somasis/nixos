{ pkgs
, lib
, osConfig
, ...
}: {
  home.shellAliases = rec {
    # LC_COLLATE=C sorts uppercase before lowercase.
    ls = "LC_COLLATE=C ls --hyperlink=auto --group-directories-first --dereference-command-line-symlink-to-dir --color -AFlh -b";
    vi = "$EDITOR";

    ip = "ip --color=auto";

    # Quick ssh aliases
    "ascii.town" = "ssh play@ascii.town";
    "2048" = "ssh -t play@ascii.town 2048";
    "snake" = "ssh -t play@ascii.town snake";

    bc = "bc -q";
    diff = "diff --color";

    g = "find -L ./ -type f \! -path '*/.*/*' -print0 | xe -0 -N0 grep -n";

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

    number = "nl -b a -d '' -f n -w 1";

    doas = lib.optionalString osConfig.security.sudo.enable "sudo";
  };

  home.packages = [
    pkgs.nocolor
    pkgs.table
    (pkgs.writeShellScriptBin "pe" ''
      ${pkgs.xe}/bin/xe -LL -j0 "$@" | sort -snk1 | cut -d' ' -f2-
    '')

    (pkgs.wrapCommand {
      package = pkgs.comma;
      wrappers = [{
        prependFlags = lib.escapeShellArgs [
          "--picker"
          (pkgs.writeShellScript "comma-picker" ''
            exec dmenu -p "," -S 2>/dev/null
          '')
        ];
      }];
    })

    (pkgs.writeShellScriptBin ",m" ''
      usage() {
          cat >&2 <<EOF
      usage: ,m [section] name
      EOF
          exit 69
      }

      pick() {
          dmenu -p ",m" -S -n "$@"
      }

      if [[ "$#" -eq 2 ]]; then
          output=$(nix-locate --minimal --top-level --regex '/share/man/man'"$1"'/'"$2"."$1" | pick)
      elif [[ "$#" -eq 1 ]]; then
          output=$(nix-locate --minimal --top-level --regex '/share/man/man.*'/"$1" | pick)
      else
          usage
      fi

      MANPATH="$output''${MANPATH:+:$MANPATH}" man "$@"
    '')

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
  '';
}
