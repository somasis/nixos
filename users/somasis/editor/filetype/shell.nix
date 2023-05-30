{ config
, lib
, pkgs
, ...
}:
let
  inherit (config.lib.somasis) commaList;

  shellcheckfmt = pkgs.writeShellApplication {
    name = "shellcheckfmt";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.diffutils
      pkgs.shellcheck
    ];

    text = ''
      d=$(mktemp -d)

      for f; do
          if [ "$f" = '-' ]; then
              cat "$f" >"$d"/input
              f="$d"/input
          fi

          # for when shellcheck finds issues, but can't auto-fix any of them.
          shellcheck -f diff -x -a "$f" >/dev/null 2>&1 || e=$?

          # (there's a colon in the next line because otherwise it thinks this is a directive!
          #:shellcheck(1) says...
          # > RETURN VALUES
          # >        ShellCheck uses the following exit codes:
          # >
          # >        - 0: All files successfully scanned with no issues.
          # >
          # >        - 1: All files successfully scanned with some issues.
          # >
          # >        - 2: Some files could not be processed (e.g.  file not found).
          if [ "''${e:-0}" -gt 1 ]; then
              cat "$f"
              continue
          fi

          mkfifo "$d"/diff
          shellcheck -f diff -x -a "$f" >"$d"/diff &
          patch -p1 -s -i "$d"/diff -o - "$f" &
          wait
          rm -f "$d"/diff "$d"/input
      done
      rm -rf "$d"
    '';
  };

  format = pkgs.writeShellApplication {
    name = "shformat";

    runtimeInputs = [
      pkgs.coreutils
      pkgs.shfmt
      shellcheckfmt
    ];

    text = ''
      trap 'rm -f "$err" "$orig" "$new"' EXIT

      err=$(mktemp)
      orig=$(mktemp)
      new=$(mktemp)
      cat > "$orig"

      { shellcheckfmt "$orig" 2>>"$err" || cat "$orig"; } | shfmt - >"$new" 2>>"$err"

      if [ "$(wc -c < "$new")" -eq 0 ]; then
          cat "$orig"
          cat "$err" >&2
          exit 1
      else
          cat "$new"
      fi
    '';
  };

  lint = pkgs.writeShellApplication {
    name = "shlint";

    runtimeInputs = [
      pkgs.checkbashisms
      pkgs.shellcheck
    ];

    text = ''
      : "''${SHLINT_SHELL:=sh}"

      (
          set +e
          checkbashisms -l "$@" 2>/dev/null
          e=$?
          [[ "$e" -ne 4 ]] || exit "$e" # exit 4 == "No bashisms were detected in a bash script."
          exit 0
      ) &

      shellcheck ''${SHLINT_SHELL:+-s "$SHLINT_SHELL"} -f gcc -x "$@" &
      wait
    '';
  };
in
{
  programs.kakoune.config.hooks = [
    # Set the filetype of buffers bash uses for editing commands.
    {
      name = "WinCreate";
      option = ".*/bash-fc\.[^\/]+";
      commands = ''
        set-option window filetype sh
        set-option window formatcmd "${format}/bin/shformat"
        set-option window lintcmd "SHLINT_SHELL=bash ${lint}/bin/shlint"
        format-buffer
      '';
    }

    {
      name = "WinSetOption";
      option = "filetype=sh";
      commands = ''
        set-option window formatcmd "${format}/bin/shformat"
        set-option window lintcmd "${lint}/bin/shlint"
      '';
    }
  ];

  xdg.configFile."shellcheckrc".text =
    # Don't use `enable = "all"`; it enables warnings about using Bashisms
    # in bash scripts, which is annoying and unhelpful.
    ''
      enable=${commaList [
        "avoid-nullary-conditions"
        "check-extra-masked-returns"
        "check-set-e-suppressed"
        "deprecate-which"
        "quote-safe-variables"
        "require-double-brackets"
        "require-variable-braces"
      ]}
    ''
  ;

  home.packages = [
    pkgs.checkbashisms
    pkgs.shellcheck
    pkgs.shfmt
    shellcheckfmt
    format
    lint
  ];
}
