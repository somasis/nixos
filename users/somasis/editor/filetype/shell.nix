{ pkgs, ... }:
let
  shellcheckfmt = pkgs.writeShellApplication {
    name = "shellcheckfmt";
    runtimeInputs = [
      pkgs.shellcheck
      pkgs.coreutils
      pkgs.diffutils
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
          if [ ''${e:-0} -gt 1 ]; then
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
      pkgs.coreutils
      pkgs.shellcheck
    ];

    text = ''
      (
          (
              set +e
              checkbashisms -l "$@" 2>/dev/null
              e=$?
              [[ "$e" -ne 4 ]] || exit "$e" # exit 4 == "No bashisms were detected in a bash script."
              exit 0
          ) &

          shellcheck -f gcc -x "$@" &
          wait
      ) | sort
    '';
  };
in
{
  programs.kakoune.config.hooks = [
    {
      name = "WinSetOption";
      option = "filetype=sh";
      commands = ''
        set-option window formatcmd "${format}/bin/shformat"
        set-option window lintcmd "${lint}/bin/shlint"
      '';
    }
  ];

  home.file.".shellcheckrc".text = ''
    enable=all
    disable=SC2249
  '';

  home.packages = [
    pkgs.checkbashisms
    pkgs.shellcheck
    pkgs.shfmt
    shellcheckfmt
    format
    lint
  ];
}